#!/usr/bin/env bash
set -e

# TODO: check that bash is used, and check that this script has not been sourced
scripts_dir=$(dirname "$0")/..
foodcoopsnet_working_dir=$(realpath "$scripts_dir/..")
cd "$foodcoopsnet_working_dir"

./scripts/initial-setup.d/a-check-requirements.sh

if [ -f .env ]; then
    echo "skipping autoconfig because the .env file exists"
else
    touch env.tmp.txt

    chmod 600 env.tmp.txt

    docker run --rm \
        -v "$(pwd)/env.erb":/TEMPLATE.erb \
        foodcoops/foodsoft:4.7 erb /TEMPLATE.erb > env.tmp.txt

    mv env.tmp.txt .env

    echo "autoconfig created a .env file"
fi
