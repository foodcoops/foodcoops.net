#!/bin/sh
set -e

# run migrations, since we're running cutting-edge
# an error will occur because the schema can't be written, but that's fine
bundle exec rake db:migrate

if [ -x ./docker-entrypoint.sh ]; then
  exec ./docker-entrypoint.sh "$@"
else
  exec "$@"
fi
