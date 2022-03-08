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

if [[ -z "$GS_BUCKET_NAME" ]]; then
  echo "Missing GS_BUCKET_NAME variable which must be set to the bucket in google storage where you would like to store your database backups"
  exit 1
fi

# install gsutil
#  - this will already exist if we're running the script manually from a dyno more than once

gsutil_command="/tmp/gsutil/gsutil"

if [[ ! -f "${gsutil_command}" ]]; then
  echo "Downloading gsutil..."
  curl "https://storage.googleapis.com/pub/gsutil.zip" -o "gsutil.zip" 
  unzip -q gsutil.zip -d /tmp/gsutil
fi

# if the app has heroku pg:backup:schedules, we might just want to just archive the latest backup to GS 
# https://devcenter.heroku.com/articles/heroku-postgres-backups#scheduling-backups
#
# set ONLY_CAPTURE_TO_GS when calling to skip database capture

BACKUP_FILE_NAME="$(date +"%Y-%m-%d_%H-%M_%Z__")${APP}_${DATABASE}.dump"

if [[ -z "$ONLY_CAPTURE_TO_GS" ]]; then
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

${gsutil_command} cp $FINAL_FILE_NAME gs://$GS_BUCKET_PATH/$APP/$DATABASE/$FINAL_FILE_NAME

echo "backup $FINAL_FILE_NAME complete"

if [[ -n "$HEARTBEAT_URL" ]]; then
  echo "Sending a request to the specified HEARTBEAT_URL that the backup was created"
  curl $HEARTBEAT_URL
  echo "heartbeat complete"
fi
