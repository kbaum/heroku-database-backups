Simple Heroku app with a bash script for capturing Heroku database backups and copying to your S3 Bucket or Glacier Vault.  Deploy this as a separate app within Heroku and schedule the script to backup your production databases which exist within another Heroku project.


## Installation

### Create a Heroku Project

First, clone this project, then change directory into the newly created directory:

```
git clone https://github.com/kbaum/heroku-database-backups.git
cd heroku-database-backups
```

Create a project on Heroku to handle the backups.

```
heroku create my-database-backups
```

### Clone this project

Make a clone of this project.

```
git clone https://github.com/kbaum/heroku-database-backups.git
```

### Push to Heroku

Next push this project to your Heroku projects git repository.

```
heroku git:remote -a my-database-backups
git push heroku master
```

### Add the Buildpack

Add the required heroku-buildpack-cli:

```
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-cli -a  my-database-backups
```

### Set Heroku environment variables

Now we need to set some environment variables in order to get the Heroku cli working properly using the [heroku-buildpack-cli](https://github.com/heroku/heroku-buildpack-cli).

```
heroku config:add HEROKU_API_KEY=`heroku auth:token` -a my-database-backups
```

### Set AWS environment variables

Next we need to add the Amazon key and secret.
This creates a token that will quietly expire in one year. To create a long-lived authorization token instead, do this:

```
heroku config:add HEROKU_API_KEY=`heroku authorizations:create -S -d my-database-backups` -a my-database-backups
```

Next we need to add the amazon key and secret from the IAM user that you are using:

```
heroku config:add AWS_ACCESS_KEY_ID=123456 -a my-database-backups
heroku config:add AWS_DEFAULT_REGION=us-east-1 -a my-database-backups
heroku config:add AWS_SECRET_ACCESS_KEY=132345verybigsecret -a my-database-backups
```

And we'll need to also set the S3 Bucket or Glacier Vault where we would like to store our database backups. *Pick only one*.

#### S3 Bucket

```
heroku config:add S3_BUCKET_PATH=my-db-backup-bucket/backups -a my-database-backups
```
Be careful when setting the S3_BUCKET_PATH to leave off a trailing forward slash.  Amazon console s3 browser will not be able to locate your file if your directory has "//" (S3 does not really have directories.).

#### Glacier Vault

```
heroku config:add GLACIER_VAULT=my-db-backup-vault -a my-database-backups
```

The archive will have a description containing the date, app, and database.

### Schedule the Backups

Finally, we need to add Heroku scheduler and call [backup.sh](https://github.com/kbaum/heroku-database-backups/blob/master/bin/backup.sh) on a regular interval with the appropriate database and app.

```
heroku addons:create scheduler -a my-database-backups
```

Now open it up, in your browser with:

```
heroku addons:open scheduler -a my-database-backups
```

And add the following command to run as often as you like:

```
APP=your-app DATABASE=HEROKU_POSTGRESQL_NAVY_URL /app/bin/backup.sh
```

In the above command, APP is the name of your app within Heroku that contains the database.  DATABASE is the name of the database you would like to capture and backup.  In our setup, DATABASE actually points to a follower database to avoid any impact to our users.  Both of these environment variables can also be set within your Heroku config rather than passing into the script invocation.

### Test it

To ensure everything is configured correctly, get a shell to your project and execute the command as the scheduler would.

```
heroku run bash -a my-database-backups
$ APP=your-app DATABASE=HEROKU_POSTGRESQL_NAVY_URL /app/bin/backup.sh
... a lot of debugging info...
backup 2018-08-21-01-23-your-app-HEROKU_POSTGRESQL_NAVY_URL.dump.gz complete
```
