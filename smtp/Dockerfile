FROM alpine:3.5

RUN apk add --no-cache postfix rsyslog

COPY rsyslog.conf /etc/
COPY main.cf /etc/postfix/

CMD rm -f /var/run/rsyslogd.pid && \
    /usr/sbin/postconf -e "mydomain=${DOMAIN}" && \
    /usr/sbin/postconf -e "myhostname=${HOSTNAME}" && \
    /usr/lib/postfix/master & \
    /usr/sbin/rsyslogd -n
