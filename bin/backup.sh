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

if [[ -z "$S3_BUCKET_PATH" && -z "$GLACIER_VAULT" ]]; then
  echo "Either S3_BUCKET_PATH or GLACIER_VAULT must be set to the S3 Bucket or Glaicer Vault where you would like to store your database backups"
  exit 1
fi

#install aws-cli
curl https://s3.amazonaws.com/aws-cli/awscli-bundle.zip -o awscli-bundle.zip
unzip awscli-bundle.zip
chmod +x ./awscli-bundle/install
./awscli-bundle/install -i /tmp/aws

BACKUP_FILE_NAME="$(date +"%Y-%m-%d-%H-%M")-$APP-$DATABASE.dump"

heroku pg:backups capture $DATABASE --app $APP
curl -o $BACKUP_FILE_NAME `heroku pg:backups:url --app $APP`
FINAL_FILE_NAME=$BACKUP_FILE_NAME

if [[ -z "$NOGZIP" ]]; then
  gzip $BACKUP_FILE_NAME
  FINAL_FILE_NAME=$BACKUP_FILE_NAME.gz
fi

if [[ "$S3_BUCKET_PATH" ]]; then
  /tmp/aws/bin/aws s3 cp $FINAL_FILE_NAME s3://$S3_BUCKET_PATH/$APP/$DATABASE/$FINAL_FILE_NAME
elif [[ "$GLACIER_VAULT" ]]; then
  /tmp/aws/bin/aws glacier upload-archive --account-id - --vault-name $GLACIER_VAULT --archive-description $BACKUP_FILE_NAME --body $FINAL_FILE_NAME
fi

echo "backup $FINAL_FILE_NAME complete"
