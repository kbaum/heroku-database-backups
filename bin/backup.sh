#!/bin/sh

BACKUP_FILE_NAME="backup.$(date +"%Y.%m.%d.%S.%N").dump"
curl -o $BACKUP_FILE_NAME `./vendor/heroku-toolbelt/bin/heroku pgbackups:url --app vts-eu` 
gzip $BACKUP_FILE_NAME
./vendor/awscli/bin/aws s3 cp $BACKUP_FILE_NAME.gz s3://vts-db-backups/pgbackups
echo "backup $BACKUP_FILE_NAME complete"

