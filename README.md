Foodcoops.net deployment demo
=============================

You need to create a certificate for your setup before you can start. For testing purpose only you can add it via `COPY` in `haproxy/Dockerfile` or you mount it via an volume in the `docker-compose.yml`. Check out the comments the files (also see [section below](#Generating_test_certificates)).

To get it running you need to provide the private information via environment variables to `docker-compose`. Here is an example to build and start the project:

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
  foodsoft bundle exec rake db:setup db:seed:small.en
```


## Generating test certificates

To get started, you might want to generate test certificates.

```shell
cd haproxy
openssl genrsa -out cert.key 2048
openssl req -new -key cert.key -out cert.csr
# for "Common Name" specify e.g. localhost
openssl x509 -req -days 3650 -in cert.csr -signkey cert.key -out cert.crt
cat cert.key cert.crt >certificate.pem
```

Uncomment the line in `haproxy/Dockerfile` that copies this, and (re-)run `docker-compose build`.

Now you're ready to run `docker-compose up` for the first time.
