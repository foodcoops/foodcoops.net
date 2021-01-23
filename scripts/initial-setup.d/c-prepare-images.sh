#!/usr/bin/env bash
set -e

# TODO: check that bash is used, and check that this script has not been sourced
scripts_dir=$(dirname "$0")/..
foodcoopsnet_working_dir=$(realpath "$scripts_dir/..")
cd "$foodcoopsnet_working_dir"

./scripts/initial-setup.d/a-check-requirements.sh

# pulling too often can block your IP for a while, see https://docker.com/increase-rate-limits
if [ -z "$FOODSOFT_SUPPRESS_DOCKER_PULL" ]; then
    docker-compose build --pull
    docker-compose pull

    echo "images are fine"
else
    docker-compose build

    echo "local images are fine, but FOODSOFT_SUPPRESS_DOCKER_PULL was set"
fi
