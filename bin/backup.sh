#!/bin/bash

# terminate script as soon as any command fails
set -e

if [[ -z "$EXPIRE_IN" ]]; then
  echo "Missing EXPIRE_IN variable which must be set to the amount of days the backup will expire"
  exit 1
fi

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

#install aws-cli
echo "downloading aws cli"
curl --progress-bar -o /tmp/awscli-bundle.zip https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
unzip -qq -d /tmp /tmp/awscli-bundle.zip
chmod +x /tmp/awscli-bundle/install
/tmp/awscli-bundle/install -i /tmp/aws

echo "creating a new backup"
/app/vendor/heroku-toolbelt/bin/heroku pg:backups capture $DATABASE --app $APP
BACKUP_URL=`/app/vendor/heroku-toolbelt/bin/heroku pg:backups public-url --app $APP | cat`
BACKUP_FILE_NAME=`echo $BACKUP_URL | awk -F "/" '{print $5}' | sed -e 's/%3A/:/g'`

echo "downloading backup"
curl --progress-bar -o /tmp/$BACKUP_FILE_NAME $BACKUP_URL
gzip /tmp/$BACKUP_FILE_NAME

EXPIRATION=$(date -d "$BACKUP_FILE_NAME $EXPIRE_IN days" +"%Y-%m-%dT%H:%M:%SZ")
echo "uploading backup, it'll expire at: $EXPIRATION"

/tmp/aws/bin/aws s3 cp /tmp/$BACKUP_FILE_NAME.gz s3://$S3_BUCKET_PATH/$APP/$DATABASE/$BACKUP_FILE_NAME.gz --expires $EXPIRATION
echo "backup $BACKUP_FILE_NAME complete"

# cleaning up
rm -rf /tmp/aws*
rm -rf /tmp/$BACKUP_FILE_NAME*
