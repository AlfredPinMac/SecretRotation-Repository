FROM alpine:3.19

RUN apk add --no-cache bash curl openldap-clients gettext docker-cli

WORKDIR /rotation

COPY rotate-frontend.sh rotate-ldap.sh rotate-all.sh rotate-daemon.sh ./
RUN chmod +x *.sh

ENV ROTATION_INTERVAL_SECONDS=120
ENV LDAP_HOST=openldap
ENV LDAP_PORT=389
ENV LDAP_BASE_DN=dc=example,dc=com

CMD ["/bin/sh", "/rotation/rotate-daemon.sh"]
