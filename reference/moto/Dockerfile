FROM motoserver/moto@sha256:1e3802c95726373544967b428201c548f0247c15b00db2d96a5ba0a77d8643b8

USER root

RUN apk update && apk add --no-cache \
    aws-cli \
    bash

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=5s --timeout=5s --start-period=10s --retries=5 \
    CMD curl -sf http://localhost:5000/moto-api/data.json || exit 1

ENTRYPOINT ["/entrypoint.sh"]