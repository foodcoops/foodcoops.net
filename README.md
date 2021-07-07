Foodcoops.net deployment
========================

This is the production setup of the future [foodcoops.net](https://foodcoops.github.io/global-foodsoft-platform/).
If you want to run it for yourself, see [setup](#setup), or if you'd like to modify the configuration,
please proceed to [common tasks](#common-tasks).


## Setup

To get it running yourself, you need to provide the private information via environment variables to
`docker-compose`. Here is an example to build and start the project:

```shell
export DOMAIN=foodcoops.test
export FOODSOFT_DB_PASSWORD=secret_fs
export FOODSOFT_SECRET_KEY_BASE=1234567890abcdefghijklmnoprstuvwxyz
export FOODSOFT_LATEST_DB_PASSWORD=secret_fsl
export FOODSOFT_LATEST_SECRET_KEY_BASE=67890abcdefghijklmnoprstuvwxyz12345
export MYSQL_ROOT_PASSWORD=mysql
export SHAREDLISTS_DB_PASSWORD=sharedlists
export SHAREDLISTS_SECRET_KEY_BASE=abcdefghijklmnopqrstuvwxyz1234567890
# remove the following line on production when ready
export CERTBOT_DISABLED=1

docker-compose build --pull
docker-compose pull
docker-compose up -d
```

You can also store the variables in `.env` instead.

### Initial database setup

On first time run, you'll need to setup the database. Start and connect to it as root:

```shell
docker-compose up -d mariadb redis
docker exec -it foodcoopsnet_mariadb_1 mysql -u root -p
```

Then run the following SQL commands:

```sql
CREATE DATABASE foodsoft_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
GRANT ALL ON foodsoft.* TO foodsoft@'%' IDENTIFIED BY 'secret_fs';

CREATE DATABASE foodsoft_latest CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
GRANT ALL ON foodsoft_latest.* TO foodsoft_latest@'%' IDENTIFIED BY 'secret_fsl';

-- setup sharedlists database
CREATE DATABASE sharedlists CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
GRANT ALL ON sharedlists.* TO sharedlists@'%' IDENTIFIED BY 'secret_sl';
```

Subsequently you need to populate the databases:

```shell
docker-compose run --rm foodsoft bundle exec rake db:setup
docker-compose run --rm sharedlists bundle exec rake db:setup
```

Then you can grant permissions to sharedlists tables (using `mysql` as before):

```sql
GRANT SELECT ON sharedlists.suppliers TO foodsoft@'%';
GRANT SELECT ON sharedlists.articles TO foodsoft@'%';
GRANT SELECT ON sharedlists.suppliers TO foodsoft_latest@'%';
GRANT SELECT ON sharedlists.articles TO foodsoft_latest@'%';
```

Finally setup the demo database. Since we specify the database via environment
variables `multicoops:run_single` doesn't work with `db`-setup tasks, so we
need to do this differently right now.

```shell
docker-compose run --rm \
  -e 'DATABASE_URL=mysql2://foodsoft:${FOODSOFT_DB_PASSWORD}@mariadb/foodsoft_demo?encoding=utf8mb4' \
  foodsoft bundle exec rake db:schema:load db:seed:small.en

docker-compose run --rm --entrypoint=/bin/bash \
  -e 'DATABASE_URL=mysql2://foodsoft_latest:${FOODSOFT_LATEST_DB_PASSWORD}@mariadb/foodsoft_latest?encoding=utf8mb4' \
  foodsoft_latest bundle exec rake db:drop db:create db:schema:load db:seed:small.en
```

### SSL certificates

By default, a dummy SSL certificate will be generated (for `localhost`). This is useful for
development, and to bootstrap easily.

For production, you need proper SSL certificates. These are provided by
[letsencrypt](https://letsencrypt.org). Set `DOMAIN` and make sure the DNS is setup correctly.
Then remove `CERTBOT_DISABLED=1` from the environment and restart the certbot instance.

### Deployment

Deployment happens by running a script on the server, which pulls the latest changes from
the remote repository, rebuilds the docker images and runs them when needed.

You need to clone the repository and configure it for group access:

```sh
git clone --config core.sharedRepository=true https://github.com/foodcoops/foodcoops.net
chgrp -R docker foodcoops.net
chmod -R g+sw foodcoops.net
```

Finally, setup a daily cronjob to ensure security updates for the docker images:

```sh
echo `readlink -f deploy.sh` > /etc/cron.daily/deploy.sh
chmod u+x /etc/cron.daily/deploy.sh
```

## Common tasks

* [Deploying](#deploying)
* [Upgrading Foodsoft](#upgrading-foodsoft)
* [Adding a new foodcoop](#adding-a-new-foodcoop)
* [Giving a foodcoop its own subdomain](#giving-a-foodcoop-its-own-subdomain)
* [Adding a member to the operations team](#adding-a-member-to-the-operations-team)
* [Increase LVM partition size](#increase-lvm-partition-size)
* [Recreating the latest demo database](#recreating-the-latest-demo-database)
* [Troubleshooting](#troubleshooting)


### Deploying

When you've made a change to this repository, you'll likely want to deploy it to production.
First push the changes to the [Github repository](https://github.com/foodcoops/foodcoops.net),
then run the following command on the server:
```shell
cd /var/git/foodcoops.net
sudo -u deploy ./deploy.sh
```

### Upgrading Foodsoft

**Note:** this section has not been tested yet!

To update Foodsoft to a new version:

* Update version in number in [`foodsoft/Dockerfile`](foodsoft/Dockerfile)
* Look at the [changelog](https://github.com/foodcoops/foodsoft/blob/master/CHANGELOG.md) to see if anything is required for migrating, and prepare it.
* [Deploy](#deploying)
* Without delay, run database migrations and restart the foodsoft images.

```shell
cd /home/deploy/foodcoops.net
docker-compose run --rm foodsoft bundle exec rake multicoops:run TASK=db:migrate
docker-compose restart foodsoft foodsoft_worker foodsoft_smtp
```

### Adding a new foodcoop

What do we need to know?

* Foodcoop identifier, will become part of the url. If the identifier is `myfoodcoop`, then
  their url will be `https://app.${DOMAIN}/myfoodcoop`.
* Foodcoop name (so that we can recognize it better).
* Name and address of two contact persons within the food cooperative (we keep it in a private document).

Make sure to have this information before adding it to our configuration.

1. Add a new section to [`foodsoft/app_config.yml`](foodsoft/app_config.yml). You could copy the
   `demo` instance. Make sure that each foodcoop has a unique identifier, and doesn't contain
   any 'weird' characters. You may set the _name_ as well. The database should be lowercase alphabet,
   prefixed with `foodsoft_` (in this example that is `foodsoft_myfoodcoop`). Make sure to set it in
   the configuration.

2. Commit the changes, push and [deploy](#deploying).

3. Create the database. [Open](#initial-database-setup) a MySQL shell, and run:
   ```sql
   CREATE DATABASE foodsoft_myfoodcoop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
   ```

4. Initialize the database (substituting `${FOODSOFT_DB_PASSWORD}` and `foodsoft_myfoodcoop`):
   ```shell
   cd /var/git/foodcoops.net
   docker-compose run --rm \
     -e 'DATABASE_URL=mysql2://foodsoft:${FOODSOFT_DB_PASSWORD}@mariadb/foodsoft_myfoodcoop?encoding=utf8mb4' \
     foodsoft bundle exec rake db:setup
   ```

5. Immediately login with `admin` / `secret` and change the user details and password. The `admin`
   user should become the user account of the first contact person, so use their email address
   here: We do not want to encourage an unused `admin` account.

6. You may want to pre-set some configuration if you know a bit more about the foodcoop. It's always
   helpful for new foodcoops to have a setup that already reflects their intended use a bit.

7. Mail the foodcoop contact persons with the url and admin account details, along with what they'd
   need to get started. I hope we'll get some more documentation and an email template for this.

   Please also communicate that this platform is run by volunteers from participating food cooperatives
   and depends on donations.

### Giving a foodcoop its own subdomain

### Adding a member to the operations team

(please expand this section)

- Add to Github [operations team](https://github.com/orgs/foodcoops/teams/operations)
- Add to relevant mailing lists (nabble [ops group](http://foodsoft.51229.x6.nabble.com/template/NamlServlet.jtp?macro=manage_users_and_groups&group=Ops+global), [ops list](http://foodsoft.51229.x6.nabble.com/foodsoft-global-ops-f1394.html), systemausfall announce and support)
- Add user account to server with garbage password (see [issue #8](https://github.com/foodcoops/foodcoops.net/issues/8))
- Add user to the servers `docker` group
- Obtain user's SSH key and verify it from a Github gist, Keybase or a video call.
- Add SSH key to user account
- (maybe more, pending #8)

### Increase LVM partition size

1. Increase LV size by, say, 2 GB
   ```shell
   lvextend --size +2G /dev/CHANGEME-vg/CHANGEME
   ```

2. Stop services (just to be sure)
   ```shell
   su deploy
   cd /var/git/foodcoops.net
   docker-compose down
   exit
   ```

3. Perform online resize of the filesystem
   ```shell
   resize2fs /dev/mapper/CHANGEME
   ```

4. Restart services
   ```shell
   su deploy
   cd /var/git/foodcoops.net
   docker-compose up -d
   ```

### Recreating the latest demo database

It can sometimes be useful to reset demo instance with a new database, seeded from `small.en`.
For the latest version of Foodsoft, it may even be necessary when somehow an erroneous migration
was committed. In that case, you'll need to bypass the automatic migration by providing a different
entry-point:

```shell
cd /var/git/foodcoops.net
docker-compose run --rm --entrypoint ./docker-entrypoint.sh \
  -e RAILS_ENV=production -e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
  foodsoft_latest bundle exec rake db:drop db:create db:schema:load db:seed:small.en
```

### List the date of latest activity per instance

```shell
cd /var/git/foodcoops.net
docker-compose exec foodsoft bundle exec rails r 'FoodsoftConfig.foodcoops.each{|s| FoodsoftConfig.select_foodcoop(s) ; puts "#{User.maximum(:last_activity).rfc3339} #{s}"}'
```

### Troubleshooting
