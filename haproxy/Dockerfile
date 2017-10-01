FROM haproxy:1.7-alpine

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY start.sh trigger.sh /

CMD ["/start.sh"]
