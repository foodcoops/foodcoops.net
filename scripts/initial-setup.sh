#!/usr/bin/env bash
set -e

# TODO: check that bash is used, and check that this script has not been sourced
scripts_dir=$(dirname "$0")
foodcoopsnet_working_dir=$(realpath "$scripts_dir/..")
cd "$foodcoopsnet_working_dir"

./scripts/initial-setup.d/a-check-requirements.sh

./scripts/initial-setup.d/b-autoconfig.sh

./scripts/initial-setup.d/c-prepare-images.sh

./scripts/initial-setup.d/d-setup-database.sh

docker-compose up -d
