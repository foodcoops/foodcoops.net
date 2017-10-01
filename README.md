Foodcoops.net deployment demo
=============================

To get it running you need to provide the private information via environment variables to `docker-compose`. Here is an example to build and start the project:

```shell
export FOODSOFT_DB_PASSWORD=foodsoft
export FOODSOFT_SECRET_KEY_BASE=secret_fs
export SHAREDLISTS_DB_PASSWORD=sharedlists
export SHAREDLISTS_SECRET_KEY_BASE=secret_sl
export MYSQL_ROOT_PASSWORD=mysql

docker-compose build --pull
docker-compose up -d
```

## Initial database setup

On first time run, you'll need to setup the database. Start and connect to it as root:

```shell
docker-compose up -d mariadb redis
docker inspect foodcoopsnet_mariadb_1 | grep '"IPAddress"'
# "IPAddress": "172.20.0.2",
mysql -h 172.20.0.2 -u root -p
```

Then run the following SQL commands:

```sql
CREATE DATABASE foodsoft CHARACTER SET utf8 COLLATE utf8_bin;
GRANT ALL ON foodsoft.* TO foodsoft@'%' IDENTIFIED BY 'secret_fs';

CREATE DATABASE sharedlists CHARACTER SET utf8 COLLATE utf8_bin;
GRANT ALL ON sharedlists.* TO sharedlists@'%' IDENTIFIED BY 'secret_sl';
GRANT SELECT ON sharedlists.* TO foodsoft@'%';
```

Finally you need to populate the databases:

```shell
docker-compose run --rm foodsoft_web bundle exec rake db:setup
docker-compose run --rm sharedlists_web bundle exec rake db:setup
```


## SSL Certificates

_This section is a work in progress._

On first startup, a dummy SSL certificate is generated. This is required to get everything
going, and see if everything works. When all is ready, you can easily request a certificate
from [letsencrypt](https://letsencrypt.org/).

```shell
docker-compose run --rm acme --issue -d app.example.com --standalone --test \
  --reloadcmd 'cat $CERT_KEY_PATH $CERT_FULLCHAIN_PATH >/acme.sh/certs/bundle.pem && touch /acme.sh/updated'
```

Replace `app.example.com` with yours, and remove `--test` when you're confident it works.
This will _almost_ work (since the one-off instance doesn't get http requests forwarded).
