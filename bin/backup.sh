#!/bin/bash

if [[ -z "$APP" ]]; then
  echo "Missing APP variable which must be set to the name of your app where the db is located" 
  exit 1
fi

if [[ -z "$DATABASE" ]]; then
  echo "Missing DATABASE variable which must be set to the name of the DATABASE you would like to backup"
  exit 1
fi

if [[ -z "$S3_BUCKET_PATH" ]]; then
  echo "Missing S3_BUCKET_PATH variable which must be set the directory in s3 where you would like to store your database backups"
  exit 1
fi

BACKUP_FILE_NAME="$(date +"%Y-%m-%d-%S")-$APP-$DATABASE.dump"

/app/vendor/heroku-toolbelt/bin/heroku pgbackups:capture $DATABASE -e --app $APP
curl -o $BACKUP_FILE_NAME `./vendor/heroku-toolbelt/bin/heroku pgbackups:url --app $APP` 
gzip $BACKUP_FILE_NAME
/app/vendor/awscli/bin/aws s3 cp $BACKUP_FILE_NAME.gz s3://$S3_BUCKET_PATH/$BACKUP_FILE_NAME.gz
echo "backup $BACKUP_FILE_NAME complete"

