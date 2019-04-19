FROM alpine:3.9

RUN apk add --no-cache postfix rsyslog ca-certificates && \
    update-ca-certificates

COPY rsyslog.conf /etc/
COPY main.cf /etc/postfix/
COPY docker-entrypoint.sh reload-postfix.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD /usr/libexec/postfix/master & \
    /usr/sbin/rsyslogd -n
