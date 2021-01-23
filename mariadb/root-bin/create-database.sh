#!/usr/bin/env bash
set -e

if [ ! $# -eq 1 ]; then
  echo "error: requires exactly one argument: name of database"
  exit 1
fi

if [[ ! ${1} =~ ^[a-z_]+$ ]]; then
  echo "error: name of database must match ^[a-z_]+$"
  exit 1
fi

dbname=$1

$(dirname $0)/wait-for-database-server.sh

mysql --protocol TCP -uroot -p$MYSQL_ROOT_PASSWORD -e "
  CREATE DATABASE $dbname COLLATE utf8mb4_unicode_520_ci;
"
