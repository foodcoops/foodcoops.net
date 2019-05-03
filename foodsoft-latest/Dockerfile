FROM foodcoops/foodsoft:latest

USER root

# update Crowdin in-context translations
RUN if [ ! `which unzip` ]; then \
      apt-get update && apt-get install --no-install-recommends -y unzip && \
      rm -Rf /var/lib/apt/lists/* /var/cache/apt/*; \
    fi
RUN tmpdir=`mktemp -d` && \
    wget -O /tmp/crowdin.zip https://crowdin.com/backend/download/project/foodsoft/ach.zip && \
    unzip -q -d "$tmpdir" /tmp/crowdin.zip && \
    tar -C "$tmpdir" -c -f - . | tar -x --strip-components=2 --no-overwrite-dir -f - && \
    rm -Rf /tmp/crowdin.zip "$tmpdir"

# add Crowdin Javascript for dummy language
COPY pre-head.html.haml /tmp/
RUN awk '$0 ~ "^\\s*= yield\\(:head\\)" && c == 0 {c = 1; system("cat /tmp/pre-head.html.haml") }; {print} ' \
     app/views/layouts/_header.html.haml >/tmp/a && mv /tmp/a app/views/layouts/_header.html.haml && \
     rm -f /tmp/pre-head.html.haml

COPY docker-entrypoint2.sh ./

USER nobody
COPY app_config.yml ./config

ENTRYPOINT ["./docker-entrypoint2.sh"]
CMD ["./proc-start", "web"]
