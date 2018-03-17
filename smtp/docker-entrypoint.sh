#!/bin/sh
set -e

/usr/sbin/postconf -e "mydomain=${DOMAIN}"
/usr/sbin/postconf -e "myhostname=${HOSTNAME}"

rm -f /var/run/rsyslogd.pid

if [ -n "$POSTFIX_RELOAD_FILE" ]; then
	echo "Watching $POSTFIX_RELOAD_FILE for reload requests"
	[ -e "$POSTFIX_RELOAD_FILE" ] || touch "$POSTFIX_RELOAD_FILE"
	inotifyd "/reload-postfix.sh" "$POSTFIX_RELOAD_FILE:ec" &
fi

exec "$@"
