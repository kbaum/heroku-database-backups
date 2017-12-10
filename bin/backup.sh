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

# to be able to upload into S3 bucket under a different AWS account you first
# need to run the "assume-role" request to get temporary AWS credentials, then
# save them to env; more on http://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html
if [[ -v "$AWS_ROLE_ARN" ]]; then
    /tmp/aws/bin/aws sts assume-role --role-arn $AWS_ROLE_ARN --role-session-name "pgbackups-archive" > session.json
    export AWS_ACCESS_KEY_ID=$(grep AccessKeyId session.json | cut -d '"' -f4)
    export AWS_SECRET_ACCESS_KEY=$(grep SecretAccessKey session.json | cut -d '"' -f4)
    export AWS_SESSION_TOKEN=$(grep SessionToken session.json | cut -d '"' -f4)
fi

/tmp/aws/bin/aws s3 cp $FINAL_FILE_NAME s3://$S3_BUCKET_PATH/$APP/$DATABASE/$FINAL_FILE_NAME

echo "backup $FINAL_FILE_NAME complete"

