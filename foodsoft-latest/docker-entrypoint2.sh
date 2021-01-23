#!/bin/sh
set -e

# run migrations, since we're running cutting-edge
# an error will occur because the schema can't be written, but that's fine
if [ -z "$FOODSOFT_LATEST_SKIP_MIGRATION" ]; then
  bundle exec rake db:migrate
fi

if [ -x ./docker-entrypoint.sh ]; then
  exec ./docker-entrypoint.sh "$@"
else
  exec "$@"
fi
