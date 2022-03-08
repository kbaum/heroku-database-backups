Simple heroku app with a bash script for capturing heroku database backups and copying to your GCP GS bucket.  Deploy this as a separate app within heroku and schedule the script to backup your production databases which exist within another heroku project.

Uses `gsutil` to copy database backups to GCP Google Storage.

## Installation


First, clone this project, then change directory into the newly created directory:

```
git clone https://github.com/kluein/heroku-database-backups-gstorage.git
cd heroku-database-backups-gstorage
```

Create a project on heroku.

```
heroku create <app-name>
```
Add the heroku-buildpack-cli:

```
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-cli -a <app-name>
```

Next push this project to your heroku projects git repository.

```
heroku git:remote -a <app-name>
git push heroku master
```

Now we need to set some environment variables in order to get the heroku cli working properly using the [heroku-buildpack-cli](https://github.com/heroku/heroku-buildpack-cli).

```
heroku config:add HEROKU_API_KEY=`heroku auth:token` -a <app-name>
```

This creates a token that will quietly expire in one year. To create a long-lived authorization token instead, do this:

```
heroku config:add HEROKU_API_KEY=`heroku authorizations:create -S -d <description>` -a <app-name>
```

Next we will need to download a Service Account Key and set an environment variable that `gsutil` will use for authentication when uploading the backup.

```
heroku config:add GOOLE_APPLICATION_CREDENTIALS=$(cat /path/to/service-account-key.json) -a <app-name>
```

And we'll need to also set the bucket and path where we would like to store our database backups:

```
heroku config:add GS_BUCKET_NAME=<gs_bucket_name>/backups -a <app-name>
```

Finally, we need to add heroku scheduler and call [backup.sh](https://github.com/kbaum/heroku-database-backups/blob/master/bin/backup.sh) on a regular interval with the appropriate database and app.

```
heroku addons:create scheduler -a <app-name>
```

Now open it up, in your browser with:

```
heroku addons:open scheduler -a <app-name>
```

And add the following command to run as often as you like:

```
APP=your-app DATABASE=HEROKU_POSTGRESQL_NAVY_URL /app/bin/backup.sh
```

In the above command, APP is the name of your app within heroku that contains the database.  DATABASE is the name of the database you would like to capture and backup.  In our setup, DATABASE actually points to a follower database to avoid any impact to our users.  Both of these environment variables can also be set within your heroku config rather than passing into the script invocation.

### Optional

You can add a `HEARTBEAT_URL` to the script so a request gets sent every time a backup is made. All you have to do is add the variable value like:

```
heroku config:add HEARTBEAT_URL=https://hearbeat.url -a <app-name>
```

If you are using [heroku's scheduled backups](https://devcenter.heroku.com/articles/heroku-postgres-backups#scheduling-backups) you might only want to archive the latest
backup to GS for long-term storage. Set the `ONLY_CAPTURE_TO_GS` variable when running the command:

```
ONLY_CAPTURE_TO_GS=true APP=your-app DATABASE=HEROKU_POSTGRESQL_NAVY_URL /app/bin/backup.sh
```

#### Tip

The default timezone is `UTC`. To use your [preferred timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) in the filename timestamp, set the `TZ` variable when calling the command:

```
TZ=America/Los_Angeles APP=your-app DATABASE=HEROKU_POSTGRESQL_NAVY_URL /app/bin/backup.sh
```
