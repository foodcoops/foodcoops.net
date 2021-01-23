#!/usr/bin/env bash
set -e

# TODO: check that bash is used, and check that this script has not been sourced
scripts_dir=$(dirname "$0")
foodcoopsnet_working_dir=$(realpath "$scripts_dir/..")
cd "$foodcoopsnet_working_dir"

if [ ! $# -eq 1 ]; then
  echo "error: requires exactly one argument: name of foodcoop"
  exit 1
fi

echo ${1}

if [[ ! ${1} =~ ^[a-z]+$ ]]; then
  echo "error: name of foodcoop must match ^[a-z]+$"
  exit 1
fi

name_of_foodcoop=$1

dbname=foodsoft_$name_of_foodcoop
dbparams="encoding=utf8mb4&collation=utf8mb4_unicode_520_ci"

docker-compose exec mariadb /root/bin/create-database.sh $dbname

source ./.env

if [ $name_of_foodcoop = latest ]; then
  docker-compose run --rm \
    -e "FOODSOFT_LATEST_SKIP_MIGRATION=1" \
    -e "DATABASE_URL=mysql2://foodsoft_latest:${FOODSOFT_LATEST_DB_PASSWORD}@mariadb/$dbname?$dbparams" \
    foodsoft_latest bundle exec rake db:schema:load db:seed:small.en
else
  docker-compose run --rm \
    -e "DATABASE_URL=mysql2://foodsoft:${FOODSOFT_DB_PASSWORD}@mariadb/$dbname?$dbparams" \
    foodsoft bundle exec rake db:schema:load db:seed:small.en
fi

echo "successfully initialized $dbname"
