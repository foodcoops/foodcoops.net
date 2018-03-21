#!/bin/sh
set -e

/usr/sbin/postconf -e "mydomain=${DOMAIN}"
/usr/sbin/postconf -e "myhostname=${HOSTNAME}"

# figure out which certificate to use
CERT_FILE=/certs/${HOSTNAME}.pem
[ -r "$CERT_FILE" ] || CERT_FILE=/certs/dummy.pem
[ -r "$CERT_FILE" ] || CERT_FILE=
if [ "$CERT_FILE" ]; then
  /usr/sbin/postconf -e "smtpd_tls_cert_file=${CERT_FILE}"
else
  /usr/sbin/postconf -X smtpd_tls_cert_file
fi

# make sure rsyslogd can be started (in case container gets re-used)
rm -f /var/run/rsyslogd.pid

# reload on trigger
if [ -n "$POSTFIX_RELOAD_FILE" ]; then
	echo "Watching $POSTFIX_RELOAD_FILE for reload requests"
	[ -e "$POSTFIX_RELOAD_FILE" ] || touch "$POSTFIX_RELOAD_FILE"
	inotifyd "/reload-postfix.sh" "$POSTFIX_RELOAD_FILE:ec" &
fi

exec "$@"
