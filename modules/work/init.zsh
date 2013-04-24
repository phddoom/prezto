alias ssh='TERM=rxvt ssh'

function bypass(){
  sudo route del default
  sudo route add default gw 10.10.20.1
}

function mobi_get_pg_restore_file(){
  file="latest_mobi_pg_backup"

  echo "Pulling latest backup from robodev..."
  scp robodev:"/home/robodev/$file" .
}

function mobi_pg_restore(){
  file="latest_mobi_pg_backup"
  # the single argument is for which database to dump it (you'll want to change the default to match your config)
  if [ $# -lt 1 ]
    then
      db="mobi_development"
    else
      db=$2
  fi

  # Dump that shizz into psql
  # Change defaults as you need for your local system
  # Use the -U option to specifiy a different user
  # -c clears the tables before importing. If the tables don't exist, an error will output but importation will continue
  # -O ignores owner information
  # -s is scheme only
  echo "Dropping then recreating $db..."
  dropdb $db
  createdb $db
  echo "Creating List Files ..."
  sans_billing='.sans_billing'
  billing_shims='.billing_shims'
  /usr/bin/rm $sans_billing
  /usr/bin/rm $billing_shims
  pg_restore -l $file | grep -iPv "(bill_usages|call_details|inventory_snapshots|inventory_items|discrepancies|resolved_by_id|3397;|3306;|3302;)" > $sans_billing
  pg_restore -l $file | grep -iP "(bill_usages|call_details|inventory_snapshots|inventory_items|discrepancies|resolved_by_id|3397;|3306;|3302;)"  > $billing_shims
  echo "Restoring database $db..."
  #pg_restore -j 4 -O -x -d $db $file
  pg_restore -j 4 -O -x -L $sans_billing -d $db $file
  echo "Inserting Billing Shims"
  pg_restore -j 4 -O -x -s -L $billing_shims -d $db $file
  echo "Importation of $db complete"
  #echo "Restoring database mobi_test (scheme only + data in schema_migrations)"
  #pg_restore -s -O -d mobi_test $file
  #pg_restore -t schema_migrations -O -d mobi_test $file
  #echo "Importation of mobi_test complete"
}

function mobi_pg_load(){
  mobi_get_pg_restore_file
  mobi_pg_restore
}
