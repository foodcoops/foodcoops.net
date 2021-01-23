Foodcoops.net deployment
========================

This is the production setup of the future [foodcoops.net](https://foodcoops.github.io/global-foodsoft-platform/).
If you want to run it for yourself, see [setup](#setup), or if you'd like to modify the configuration,
please proceed to [common tasks](#common-tasks).


## Setup

Application data is stored in docker volumes, see `docker-compose.yml` for the current list. These volumes will
also contain your database, so handle them wisely and apply a backup strategy that suits your needs.

Configuration and passwords must be provided in a `.env` file. If the `.env` file does not exist then it is
automatically created by the setup script `./scripts/initial-setup.sh` from the `env.erb` file.

The following steps should get you started after a fresh docker and docker-compose install:

1. ensure that you have not yet initialized your database (see output of `docker volume ls`)
1. make sure that the ports 25, 80, and 443 are not yet occupied
1. run the all-in-one setup script `./scripts/initial-setup.sh`
1. browse to https://localhost/ (redirect from http://localhost/ should also work)
1. accept the self-signed certificate
1. login with admin/secret

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
then run `deploy.sh` on the server.

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
   `demo` instance. Make sure that each foodcoop has a unique identifier that matches `^[a-z]+$`.
   The database name should be prefixed with `foodsoft_` (in this example that is
   `foodsoft_myfoodcoop`). Make sure to set it in the configuration.

2. Commit the changes, push and [deploy](#deploying).

3. Create and initialize the database (substituting `myfoodcoop`):
   ```shell
   ./scripts/create-and-init-foodcoop-database.sh myfoodcoop
   ```

4. Ensure that the previous step ended with the message
   > successfully initialized foodsoft_myfoodcoop

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

### Troubleshooting
