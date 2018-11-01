#!/bin/bash

# Usage: sqlite_backup.sh <sqlite dbs>...
#   1. Creates a backup of of each of the SQlite databases
#      provided.
#   2. Gzips the backed up database.
#   3. Uploads the gzipped backup to a Backblaze bucket.

DATE=`date +"%Y%m%d"`
for DB_FILE in "$@"
do
  BACK_FILE="$DB_FILE.$DATE"
  echo "Backing up $DB_FILE..."
  sqlite3 $DB_FILE ".backup $BACK_FILE" &
done

wait

for DB_FILE in "$@"
do
  BACK_FILE="$DB_FILE.$DATE"
  GZIP_FILE="$BACK_FILE.gz"
  BACKBLAZE_FILE="$(basename $DB_FILE)/$(basename $GZIP_FILE)"
  echo "Vacuuming $BACK_FILE..."
  sqlite3 $DB_FILE "vacuum;"
  echo "Compressing $BACK_FILE..."
  gzip -9 $BACK_FILE
  echo "Backing up to Backblaze as $BACKBLAZE_FILE..."
  b2 upload-file james-db-backup $GZIP_FILE $BACKBLAZE_FILE > /dev/null
  rm $GZIP_FILE
done
