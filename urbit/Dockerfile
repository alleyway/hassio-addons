# syntax=docker/dockerfile:1

# Official Urbit runtime. Published for linux/amd64 only.
# v5.0-697fc95 is the image currently tagged "edge" (2026-11-18).
# Bump this pin to move the ship to a newer Vere. Do not downgrade a booted pier.
FROM tloncorp/vere:v5.0-697fc95

ARG BUILD_ARCH
ARG BUILD_VERSION

# jq reads the add-on options. The Vere image already has bash and curl.
RUN apk add --no-cache jq \
    && if [ -n "${BUILD_ARCH:-}" ] && [ "${BUILD_ARCH}" != "amd64" ]; then \
         echo "tloncorp/vere is published for linux/amd64 only (got ${BUILD_ARCH})" >&2; \
         exit 1; \
       fi

# Replaces the image entrypoint (/bin/start_urbit). run.sh execs that
# entrypoint after staging a pier, keyfile, or comet.
COPY rootfs/ /
RUN chmod 755 /run.sh /code-watcher.sh

ENTRYPOINT ["/run.sh"]

LABEL \
    io.hass.name="Urbit" \
    io.hass.description="Run an Urbit ship with the official Vere runtime" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="Alleyway <alleywayapps@gmail.com>" \
    org.opencontainers.image.title="Urbit" \
    org.opencontainers.image.description="Run an Urbit ship with the official Vere runtime" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.url="https://github.com/alleyway/hassio-addons/tree/main/urbit" \
    org.opencontainers.image.source="https://github.com/alleyway/hassio-addons" \
    org.opencontainers.image.documentation="https://github.com/alleyway/hassio-addons/blob/main/urbit/DOCS.md"
