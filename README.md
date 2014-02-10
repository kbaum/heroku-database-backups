Simple heroku app which a script for capturing heroku database backups and copying to your s3 bucket.


## Installation


First create a project on heroku with the [heroku-buildpack-multi](https://github.com/ddollar/heroku-buildpack-multi).

```
heroku create my-database-backups --buildpack https://github.com/ddollar/heroku-buildpack-multi
```

Next push this project to your heroku projects git repository.

```
git remote add heroku git@heroku.com:my-database-backups.git
git push heroku master
```

Now we need to set some environment variables in order to get the heroku cli working properly using the [heroku-buildpack-toolbet](We are using the https://github.com/gregburek/heroku-buildpack-toolbelt.git).

```
heroku config:add HEROKU_TOOLBELT_API_EMAIL=your-email@gmail.com -a my-database-backups
heroku config:add HEROKU_TOOLBELT_API_PASSWORD=`heroku auth:token` -a my-database-backups
```

Next we need to add the amazon key and secret.

```
heroku config:add AWS_ACCESS_KEY_ID=123456 -a my-database-backups
heroku config:add AWS_DEFAULT_REGION=us-east-1 -a my-database-backups
heroku config:add AWS_SECRET_ACCESS_KEY=132345verybigsecret -a my-database-backups
```

And we'll need to also set the bucket and path where we would like to store our database b backups:

```
heroku config:add S3_BUCKET_PATH=my-db-backup-bucket/backups/ -a my-database-backups
```  

Finally, we need to add heroku scheduler and call database.sh on a regular interval with the appropriate database and vts app.

```
heroku addons:add scheduler -a my-database-backups
```

Now open it up, in your browser with:

```
heroku addons:open scheduler -a kbaums-database-backups
```

And add the following command to run as often as you like:

```
APP=your-app DATABASE=HEROKU_POSTGRESQL_NAVY_URL /app/bin/backup.sh
```

In the above command, APP is the name of your app within heroku.  DATABASE is the name of the database you would like to capture and backup.  In our setup, DATABASE actually points to a follower database to avoid any impact to our users.  Both of these environment variables can also be set within your heroku config rather than passing into the script invocation.


