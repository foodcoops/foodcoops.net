#!/bin/sh
#
# Run HAProxy with soft reload on certificate files changes
#
UPDATED_FILE=/certs/updated
HAPROXY_PID_FILE=/run/haproxy.pid
UPTODATE_FILE=/tmp/uptodate

haproxy_pid() {
  cat ${HAPROXY_PID_FILE} 2>/dev/null
}

# wait for updated file to be there (or we have no certificates anyway)
if [ ! -e ${UPDATED_FILE} ]; then
  echo "WARNING: no certificate update file found, waiting for it to appear (by acme)"
  while [ ! -e ${UPDATED_FILE} ]; do sleep 3; done
fi

# watch for certificate updates to reload
inotifyd /trigger.sh ${UPDATED_FILE}:ec &

while true; do
  touch ${UPTODATE_FILE}

  haproxy -sf `haproxy_pid` -p ${HAPROXY_PID_FILE} -D -f /usr/local/etc/haproxy/haproxy.cfg $@
  # exit immidiately in case of any errors
  if [[ $? != 0 ]]; then exit $?; fi

  # wait until trigger file is gone
  inotifyd - ${UPTODATE_FILE} >/dev/null

  # avoid race
  sleep 1
done
