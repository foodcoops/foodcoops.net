#!/usr/bin/env bash
set -e

# TODO: check that bash is used, and check that this script has not been sourced
scripts_dir=$(dirname "$0")/..
foodcoopsnet_working_dir=$(realpath "$scripts_dir/..")
cd "$foodcoopsnet_working_dir"

./scripts/initial-setup.d/a-check-requirements.sh

docker-compose up -d redis

# if the database does not exist then ./mariadb/docker-entrypoint-initdb.d is executed on container startup
# https://github.com/docker-library/mariadb/blob/58bef417cbeea4eb6b15c46b6097c3cbb99beb32/10.3/docker-entrypoint.sh#L338
docker-compose up -d mariadb

docker-compose exec mariadb /root/bin/create-database.sh sharedlists
docker-compose run --rm sharedlists bundle exec rake db:schema:load db:seed

./scripts/create-and-init-foodcoop-database.sh demo
./scripts/create-and-init-foodcoop-database.sh latest

docker-compose down

echo "database is fine."
