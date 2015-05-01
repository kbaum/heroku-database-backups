Simple heroku app with a bash script for capturing heroku database backups and copying to your s3 bucket.  Deploy this as a separate app within heroku and schedule the script to backup your production databases which exist within another heroku project.


## Installation


First create a project on heroku with the [heroku-buildpack-multi](https://github.com/ddollar/heroku-buildpack-multi).

```
heroku create my-database-backups --buildpack https://github.com/ddollar/heroku-buildpack-multi
```

If you have already created an app without  [heroku-buildpack-multi](https://github.com/ddollar/heroku-buildpack-multi), then do bellow steps, 

1. Add `BUILDPACK_URL` to heroku config of your app

    ```
    heroku config:add BUILDPACK_URL=https://github.com/ddollar/heroku-buildpack-multi.git -a my-database-backups
    ```

2. Add your project specific buildpacks to [.buildpack](.buildpack) file. You can find langauge specific build pack in here [HerokuBuildPacks](https://devcenter.heroku.com/articles/buildpacks)

    Sample python project [.buildpack](.buildpack) file contents will be like below,

        https://github.com/gregburek/heroku-buildpack-toolbelt.git
        https://github.com/heroku/heroku-buildpack-python

3. Add `awscli==1.7.25` to your `requirements.txt` file.

Next push this project to your heroku projects git repository.

```
git remote add heroku git@heroku.com:my-database-backups.git
git push heroku master
```

Now we need to set some environment variables in order to get the heroku cli working properly using the [heroku-buildpack-toolbet](We are using the https://github.com/gregburek/heroku-buildpack-toolbelt.git).

```
heroku config:add HEROKU_TOOLBELT_API_EMAIL=your-fake-email@gmail.com -a my-database-backups
heroku config:add HEROKU_TOOLBELT_API_PASSWORD=`heroku auth:token` -a my-database-backups
```

Next we need to add the amazon key and secret.

```
heroku config:add AWS_ACCESS_KEY_ID=123456 -a my-database-backups
heroku config:add AWS_DEFAULT_REGION=us-east-1 -a my-database-backups
heroku config:add AWS_SECRET_ACCESS_KEY=132345verybigsecret -a my-database-backups
```

And we'll need to also set the bucket and path where we would like to store our database backups:

```
heroku config:add S3_BUCKET_PATH=my-db-backup-bucket/backups -a my-database-backups
```  

> Be careful when setting the **S3_BUCKET_PATH** to leave off a trailing forward slash.  Amazon console s3 browser will not be able to locate your file if your directory has "//" (S3 does not really have directories.).

Finally, we need to add heroku scheduler and call [backup.sh](https://github.com/kbaum/heroku-database-backups/blob/master/bin/backup.sh) on a regular interval with the appropriate database and app.

```
heroku addons:add scheduler -a my-database-backups
```

Now open it up, in your browser with:

```
heroku addons:open scheduler -a my-database-backups
```

And add the following command to run as often as you like:

```
APP=your-app DATABASE=HEROKU_POSTGRESQL_NAVY_URL /app/bin/backup.sh
```

or

```
APP=your-app DATABASE=DATABASE_URL /app/bin/backup.sh 
```


In the above command, 
- `APP` is the name of your app within heroku that contains the database.  
- `DATABASE` is the name of the database you would like to capture and backup. You can use both format  `HEROKU_POSTGRESQL_NAVY_URL` or `DATABASE_URL`, script will find the actual name for the `DATABASE_URL` 

In our setup, `DATABASE` actually points to a follower database to avoid any impact to our users.  

Both of these environment variables can also be set within your heroku config rather than passing into the script invocation.

#### Sample Usage 

```
APP=my-production-app DATABASE=DATABASE_URL /app/bin/backup.sh 

APP=my-development-app DATABASE=DATABASE_URL /app/bin/backup.sh 
```


