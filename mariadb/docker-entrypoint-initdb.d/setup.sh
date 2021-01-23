# no shebang and no executable bit because this is to be sourced
# https://github.com/docker-library/mariadb/blob/58bef417cbeea4eb6b15c46b6097c3cbb99beb32/10.3/docker-entrypoint.sh#L64

docker_process_sql <<< "
CREATE USER foodsoft IDENTIFIED BY '$FOODSOFT_DB_PASSWORD';

GRANT ALL ON \`foodsoft_%\`.* TO foodsoft;


CREATE USER foodsoft_latest IDENTIFIED BY '$FOODSOFT_LATEST_DB_PASSWORD';

GRANT ALL ON foodsoft_latest.* TO foodsoft_latest;


CREATE USER sharedlists IDENTIFIED BY '$SHAREDLISTS_DB_PASSWORD';

GRANT ALL ON sharedlists.* TO sharedlists;

GRANT CREATE, SELECT ON sharedlists.articles TO foodsoft;
GRANT CREATE, SELECT ON sharedlists.suppliers TO foodsoft;
-- we want read-only access, so let's revoke CREATE https://bugs.mysql.com/bug.php?id=80379
REVOKE CREATE ON sharedlists.articles FROM foodsoft;
REVOKE CREATE ON sharedlists.suppliers FROM foodsoft;

GRANT CREATE, SELECT ON sharedlists.articles TO foodsoft_latest;
GRANT CREATE, SELECT ON sharedlists.suppliers TO foodsoft_latest;
-- we want read-only access, so let's revoke CREATE https://bugs.mysql.com/bug.php?id=80379
REVOKE CREATE ON sharedlists.articles FROM foodsoft_latest;
REVOKE CREATE ON sharedlists.suppliers FROM foodsoft_latest;
"
