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

# install aws-cli
#  - this will already exist if we're running the script manually from a dyno more than once

aws_command="/tmp/bin/aws"

if [[ ! -f "${aws_command}" ]]; then
  echo "aws cli v2..."
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  ./aws/install --bin-dir /tmp/bin --install-dir /tmp/aws
fi

# if the app has heroku pg:backup:schedules, we might just want to just archive the latest backup to S3
# https://devcenter.heroku.com/articles/heroku-postgres-backups#scheduling-backups
#
# set ONLY_CAPTURE_TO_S3 when calling to skip database capture

BACKUP_FILE_NAME="$(date +"%Y-%m-%d_%H-%M_%Z__")${APP}_${DATABASE}.dump"

if [[ -z "$ONLY_CAPTURE_TO_S3" ]]; then
  heroku pg:backups capture $DATABASE --app $APP
else
  BACKUP_FILE_NAME="archive__${BACKUP_FILE_NAME}"
  echo " --- Skipping database capture"
fi

curl -o $BACKUP_FILE_NAME `heroku pg:backups:url --app $APP`
FINAL_FILE_NAME=$BACKUP_FILE_NAME

if [[ -z "$NOGZIP" ]]; then
  gzip $BACKUP_FILE_NAME
  FINAL_FILE_NAME=$BACKUP_FILE_NAME.gz
fi

${aws_command} s3 cp $FINAL_FILE_NAME s3://$S3_BUCKET_PATH/$APP/$DATABASE/$FINAL_FILE_NAME

echo "backup $FINAL_FILE_NAME complete"

if [[ -n "$HEARTBEAT_URL" ]]; then
  echo "Sending a request to the specified HEARTBEAT_URL that the backup was created"
  curl $HEARTBEAT_URL
  echo "heartbeat complete"
fi