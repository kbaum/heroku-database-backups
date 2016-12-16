#!/bin/bash

# terminate script as soon as any command fails
set -e

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

DATABASE_NAME="$(/app/vendor/heroku-toolbelt/bin/heroku pg:info -a $APP | grep DATABASE_URL | awk '{split($0,a," "); print a[2]}')"

BACKUP_FILE_NAME="$(date +"%Y-%m-%d-%H-%M")-$APP-$DATABASE_NAME.dump"

/app/vendor/heroku-toolbelt/bin/heroku pg:backups capture $DATABASE --app $APP
curl -o $BACKUP_FILE_NAME `/app/vendor/heroku-toolbelt/bin/heroku pg:backups:url --app $APP`
gzip $BACKUP_FILE_NAME
aws s3 cp $BACKUP_FILE_NAME.gz s3://$S3_BUCKET_PATH/$APP/$DATABASE_NAME/$BACKUP_FILE_NAME.gz
echo "backup $BACKUP_FILE_NAME complete"

