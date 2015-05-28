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
  echo "Missing S3_BUCKET_PATH variable which must be set to the directory in s3 where you would like to store your database backups"
  exit 1
fi

# install the aws-cli
curl https://s3.amazonaws.com/aws-cli/awscli-bundle.zip -o awscli-bundle.zip
unzip awscli-bundle.zip
chmod +x ./awscli-bundle/install
./awscli-bundle/install -i /tmp/aws

BACKUP_FILE_NAME="$(date +"%Y-%m-%d-%H-%M-%S")-$APP.dump"

# run the Heroku backup
/app/vendor/heroku-toolbelt/bin/heroku pg:backups capture $DATABASE --expire --app $APP
# copy the backup output file to our local disk
curl -o $BACKUP_FILE_NAME `/app/vendor/heroku-toolbelt/bin/heroku pg:backups public-url --app $APP`

# compress the backup file - adds the suffix ".gz"
gzip $BACKUP_FILE_NAME

# copy the compressed file to S3
/tmp/aws/bin/aws s3 cp $BACKUP_FILE_NAME.gz s3://$S3_BUCKET_PATH/$BACKUP_FILE_NAME.gz

# list the copied file on S3
/tmp/aws/bin/aws s3 ls s3://$S3_BUCKET_PATH/$BACKUP_FILE_NAME.gz

# ... and relax
echo "backup complete - $BACKUP_FILE_NAME"
