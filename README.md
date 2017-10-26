Foodcoops.net deployment
========================

This is the production setup of the future [foodcoops.net](https://foodcoops.github.io/global-foodsoft-platform/).
If you want to run it for yourself, see [setup](#setup), or if you'd like to modify the configuration,
please proceed to [common tasks](#common-tasks).


## Setup

To get it running yourself, you need to provide the private information via environment variables to
`docker-compose`. Here is an example to build and start the project:

```shell
export FOODSOFT_DB_PASSWORD=secret_fs
export FOODSOFT_SECRET_KEY_BASE=1234567890abcdefghijklmnoprstuvwxyz
export SHAREDLISTS_DB_PASSWORD=sharedlists
export SHAREDLISTS_SECRET_KEY_BASE=abcdefghijklmnopqrstuvwxyz1234567890
export MYSQL_ROOT_PASSWORD=mysql
export HOSTNAME=app.foodcoops.test
export DOMAIN=foodcoops.test

docker-compose build --pull
docker-compose up -d
```

You can also store the variables in `.env` instead.

### Initial database setup

On first time run, you'll need to setup the database. Start and connect to it as root:

```shell
docker-compose up -d mariadb redis
docker inspect foodcoopsnet_mariadb_1 | grep '"IPAddress"'
# "IPAddress": "172.20.0.2",
mysql -h 172.20.0.2 -u root -p
```

Then run the following SQL commands:

```sql
-- this database isn't really used, but needs to be present for startup
CREATE DATABASE foodsoft CHARACTER SET utf8 COLLATE utf8mb4_unicode_520_ci;
GRANT ALL ON foodsoft.* TO foodsoft@'%' IDENTIFIED BY 'secret_fs';

-- this is the database for the demo site
CREATE DATABASE fs_demo CHARACTER SET utf8 COLLATE utf8mb4_unicode_520_ci;
GRANT ALL ON fs_demo.* TO foodsoft@'%';

-- setup sharedlists database
CREATE DATABASE sharedlists CHARACTER SET utf8 COLLATE utf8mb4_unicode_520_ci;
GRANT ALL ON sharedlists.* TO sharedlists@'%' IDENTIFIED BY 'secret_sl';
GRANT SELECT ON sharedlists.* TO foodsoft@'%';
```

Subsequently you need to populate the databases:

```shell
docker-compose run --rm foodsoft bundle exec rake db:setup
docker-compose run --rm sharedlists bundle exec rake db:setup
```

Finally setup the demo database. Somehow `multicoops:run_single` doesn't seem
to work with `db`-setup tasks, so we need to do this differently right now.

```shell
docker-compose run --rm \
  -e 'DATABASE_URL=mysql2://foodsoft:${FOODSOFT_DB_PASSWORD}@mariadb/fs_demo?encoding=utf8' \
  foodsoft bundle exec rake db:schema:load db:seed:small.en
```

### SSL certificates

By default, a dummy SSL certificate will be generated (for `localhost`). This is useful for
development, and to bootstrap easily.

For production, you need proper SSL certificates. These are provided by
[letsencrypt](https://letsencrypt.org). Set `HOSTNAME` and make sure the DNS is setup correctly.
Then set `CERTBOT_ENABLED=1`, which signifies the certbot instance to obtain real certificates.


### Deployment

Deployment happens by pushing to a git repository on the server, which rebuilds the docker
images and runs them when needed.
For more information, see [issue #5](https://github.com/foodcoops/foodcoops.net/issues/5#issuecomment-337367496)).

To setup the git repository for the first time, please see [`setup-git.sh`](setup-git.sh).
Make sure to run it as the (newly created) `git` user. Afterwards, set all relevant environment
variables in `~git/foodcoops.net/.env`, and add the public SSH keys from all operations team
members to the account's `~/.ssh/authorized_keys`.

Finally, setup a daily cronjob for security updates from base images. Put an executable file in
`/etc/cron.daily/foodcoops.net`:

```sh
#!/bin/sh
su git <<-EOF
  cd $HOME/foodcoops.net &&
  docker-compose build --pull &&
  docker-compose up -d
EOF
```

## Common tasks

### Deploying

When you've made a change to this repository, you'll likely want to deploy it to production.
First push the changes to the [Github repository](https://github.com/foodcoops/foodcoops.net),
then push them to the deployment repository.

If you do this for the first time (substituting `${HOSTNAME}`), you need to add the remote:

```shell
git remote add production git@${HOSTNAME}:foodcoops.net.git
git fetch
```

Then after committing your changes, you can do

```shell
git push production master
```

Note that you can only push to the `master` branch, and that you need to wait until the
_build_ step is done. If that is interrupted or fails, the changes will _not_ be pushed
(restarting containers is done also when you interrupt the process).

### Adding a new foodcoop

What do we need to know?

* Foodcoop identifier, will become part of the url. If the identifier is `my-foodcoop`, then
  their url will be `http://${HOSTNAME}/my-foodcoop`.
* Foodcoop name (so that we can recognize it better).
* Name and address of two contact persons within the food cooperative (we keep it in a private document).

Make sure to have this information before adding it to our configuration.

1. Add a new section to [`foodsoft/app_config.yml`](foodsoft/app_config.yml). You could copy the
   `demo` instance. Make sure that each foodcoop has a unique identifier, and doesn't contain
   any 'weird' characters. You may set the _name_ as well. The database should be lowercase alphabet,
   prefixed with `fs_` (in this example that is `fs_myfoodcoop`). Make sure to set it in the configuration.

2. Commit the changes, push and [deploy](#deploying).

3. Create the database. [Open](#initial-database-setup) a MySQL shell, and run:
   ```sql
   CREATE DATABASE fs_myfoodcoop CHARACTER SET utf8 COLLATE utf8mb4_unicode_520_ci;
   GRANT ALL ON fs_myfoodcoop.* TO foodsoft@'%';
   ```

4. Initialize the database (substituting `${FOODSOFT_DB_PASSWORD}`):
   ```shell
   docker-compose run --rm \
     -e 'DATABASE_URL=mysql2://foodsoft:${FOODSOFT_DB_PASSWORD}@mariadb/fs_myfoodcoop?encoding=utf8' \
     foodsoft bundle exec rake db:setup
   ```

5. Immediately login with `admin` / `secret` and change the password.

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
- Add to relevant mailing lists (nabble ops, private ops and support)
- Add user account to server (probably, see [issue #8](https://github.com/foodcoops/foodcoops.net/issues/8))
- Add SSH key to user account
- Add SSH key to git account
- (maybe more, pending #8)

### Troubleshooting
