#!/usr/bin/env bash
set -e

# TODO: check that bash is used, and check that this script has not been sourced
scripts_dir=$(dirname "$0")/..
foodcoopsnet_working_dir=$(realpath "$scripts_dir/..")
cd "$foodcoopsnet_working_dir"

set +e
docker_version_info=$(docker --version)
docker_version_info_exit_status=$?
set -e
if [[ $docker_version_info_exit_status != 0 ]]; then
    >&2 echo "ERROR: Failed to query the docker version. The failing command was"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker --version"
    >&2 echo ""
    >&2 echo "You should verify your docker install and check your"
    >&2 echo "user's permissions."

    exit 1
elif [[ -z "$docker_version_info" ]]; then
    >&2 echo "ERROR: The version info of docker is empty. You may check yourself:"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker --version"
    >&2 echo ""
    >&2 echo "You should verify your docker install and check your"
    >&2 echo "user's permissions."
    >&2 echo ""
    >&2 echo "If docker is alright then this script may be broken."
    >&2 echo "Please let us know if you think so:"
    >&2 echo "https://github.com/foodcoops/foodcoops.net/issues."

    exit 1
fi
echo "$docker_version_info"

set +e
docker_compose_version_info=$(docker-compose --version)
docker_compose_version_info_exit_status=$?
set -e
if [[ $docker_compose_version_info_exit_status != 0 ]]; then
    >&2 echo "ERROR: Failed to query the docker-compose version. The failing command was"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker-compose --version"
    >&2 echo ""
    >&2 echo "You should verify your docker-compose install and check your"
    >&2 echo "user's permissions."

    exit 1
elif [[ -z "$docker_compose_version_info" ]]; then
    >&2 echo "ERROR: The version info of docker-compose is empty. You may check yourself:"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker-compose --version"
    >&2 echo ""
    >&2 echo "You should verify your docker-compose install and check your"
    >&2 echo "user's permissions."
    >&2 echo ""
    >&2 echo "If docker-compose is alright then this script may be broken."
    >&2 echo "Please let us know if you think so:"
    >&2 echo "https://github.com/foodcoops/foodcoops.net/issues."

    exit 1
fi
echo "$docker_compose_version_info"

set +e
existing_docker_compose_containers=$(docker-compose ps --quiet --all)
existing_docker_compose_containers_exit_status=$?
set -e
if [[ $existing_docker_compose_containers_exit_status != 0 ]]; then
    >&2 echo "ERROR: Failed to check for existing docker-compose containers. The failing command was"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker-compose ps --quiet --all"
    >&2 echo ""
    >&2 echo "You should verify your docker install and check you user's permissions."

    exit 1
elif [[ $existing_docker_compose_containers ]]; then
    >&2 echo "ERROR: There exist docker-compose containers. You may check yourself:"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker-compose ps --quiet --all"
    >&2 echo ""
    >&2 echo "Probably, the reason is one of the following:"
    >&2 echo ""
    >&2 echo "  1. You have already tried this setup, but the setup failed"
    >&2 echo "     half-way. (You would like to retry now)."
    >&2 echo ""
    >&2 echo "  2. You have already finished this setup, but you have"
    >&2 echo "     accidentally launched this script again."
    >&2 echo ""
    >&2 echo "This setup script cannot continue because it must not mess up"
    >&2 echo "your existing setup. If you are sure you would like to remove"
    >&2 echo "the existing containers then run the following command:"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker-compose down"
    >&2 echo ""
    >&2 echo "Note: This script has no built-in functionality to perform that"
    >&2 echo "operation for you."

    exit 1
fi

set +e
existing_database_volume=$(docker volume list --quiet --filter name=foodcoopsnet_mariadb)
existing_database_volume_exit_status=$?
set -e
if [[ $existing_database_volume_exit_status != 0 ]]; then
    >&2 echo "ERROR: Failed to check for existing database volume. The failing command was"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker volume list --quiet --filter name=foodcoopsnet_mariadb"
    >&2 echo ""
    >&2 echo "You should verify your docker install and check you user's permissions."

    exit 1
elif [[ $existing_database_volume ]]; then
    >&2 echo "ERROR: There exists a volume that probably contains a database. You may check yourself:"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker volume list"
    >&2 echo ""
    >&2 echo "Probably, the reason is one of the following:"
    >&2 echo ""
    >&2 echo "  1. You have already tried this setup, but the setup failed"
    >&2 echo "     half-way. (You would like to retry now)."
    >&2 echo ""
    >&2 echo "  2. You have already finished this setup, but you have"
    >&2 echo "     accidentally launched this script again."
    >&2 echo ""
    >&2 echo "This setup script cannot continue because it must not overwrite"
    >&2 echo "your existing database. If you are sure that you would like to"
    >&2 echo "ERASE ALL DATA from your foodsoft database then you can remove"
    >&2 echo "the volume that is listed by"
    >&2 echo ""
    >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
    >&2 echo "    docker volume list --filter name=foodcoopsnet_mariadb"
    >&2 echo ""
    >&2 echo ". After removing, you can launch this setup again. Make sure that"
    >&2 echo "you understand the consequences before deleting the volume: ALL"
    >&2 echo "YOUR FOODSOFT DATABASE WILL BE RESET TO ITS INITIAL STATE."
    >&2 echo ""
    >&2 echo "Note: This script has no built-in functionality to erase that"
    >&2 echo "volume for you."

    exit 1
fi

if [ -z "$FOODSOFT_SUPPRESS_PORT_USAGE_CHECK" ]; then
    for port in 25 80 443; do
        set +e
        port_usages=$(ss --listening --tcp --numeric --no-header "( sport = :$port or dport = :$port )")
        port_usage_check_exit_status=$?
        set -e
        if [[ $port_usage_check_exit_status != 0 ]]; then
            >&2 echo "ERROR: Port-usage check of port $port failed. The failing command was"
            >&2 echo ""
            >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
            >&2 echo "    ss --listening --tcp --numeric --no-header \"( sport = :$port or dport = :$port )\""
            >&2 echo ""
            >&2 echo "Alternatively, you may disable this check by setting FOODSOFT_SUPPRESS_PORT_USAGE_CHECK."

            exit 1
        elif [[ $port_usages ]]; then
            >&2 echo "ERROR: Port $port is in use. You may debug this situation with the following command:"
            >&2 echo ""
            >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
            >&2 echo "    sudo ss --listening --tcp --numeric --process \"( sport = :$port or dport = :$port )\""
            >&2 echo ""
            >&2 echo "Alternatively, you may disable this check by setting FOODSOFT_SUPPRESS_PORT_USAGE_CHECK."

            exit 1
        fi
    done
fi

if [ -f .env ]; then
    set +e
    env_file_permission=$(stat --format '%a' .env)
    env_file_permission_check_exit_status=$?
    set -e
    if [[ $env_file_permission_check_exit_status != 0 ]]; then
        >&2 echo "ERROR: file-permission check of .env file failed. The failing command was"
        >&2 echo ""
        >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
        >&2 echo "    stat --format '%a' .env"
        >&2 echo ""
        >&2 echo "This should not happen. Please let us know that this is an issue for you:"
        >&2 echo "https://github.com/foodcoops/foodcoops.net/issues."

        exit 1
    elif [ "$env_file_permission" != "600" ]; then
        >&2 echo "ERROR: file permissions of the .env file must be set to 600. You may debug this situation with the following command:"
        >&2 echo ""
        >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
        >&2 echo "    stat --format '%a' .env"
        >&2 echo ""
        >&2 echo "You should be able to change the file permissions with the following command:"
        >&2 echo ""
        >&2 echo "    cd \"$foodcoopsnet_working_dir\" &&"
        >&2 echo "    chmod 600 .env"
        >&2 echo ""
        >&2 echo "Note: This manual intervention should not be required if you follow the default autoconfiguration."

        exit 1
    fi
fi

echo "requirements are fine"
