set -e

if [[ $# -ne 5 ]] ; then
	echo "usage: $0 <HEROKU_APP_NAME> <AWS_ACCESS_KEY> <AWS_SECRET_KEY> <DEFAULT_REGION> <S3_BUCKET>"
	exit 1
fi

APP=$1
ACCESS_KEY=$2
SECRET=$3
DEFAULT_REGION=$4
BUCKET=$5

heroku config:add AWS_ACCESS_KEY_ID=$ACCESS_KEY -a $APP
heroku config:add AWS_DEFAULT_REGION=$DEFAULT_REGION -a $APP
heroku config:add AWS_SECRET_ACCESS_KEY=$SECRET -a $APP
heroku config:add S3_BUCKET_PATH=$BUCKET -a $APP
