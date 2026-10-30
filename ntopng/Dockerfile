# syntax=docker/dockerfile:1

# Home Assistant passes BUILD_ARCH / BUILD_VERSION to the build.
ARG BUILD_ARCH
ARG BUILD_VERSION=0.4.0

ARG NDPI_VERSION=5.0
ARG NTOP_VERSION=6.6
ARG NETFLOW2NG_VERSION=0.2.2

# ==============================================================================
# Build stage
# ==============================================================================
FROM debian:trixie AS builder

ARG NDPI_VERSION
ARG NTOP_VERSION
ARG NETFLOW2NG_VERSION
ARG JOBS=4

ENV DEBIAN_FRONTEND=noninteractive
ENV CMAKE_BUILD_PARALLEL_LEVEL=${JOBS}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        autoconf \
        autogen \
        automake \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        flex \
        git \
        golang-go \
        libcap-dev \
        libcurl4-openssl-dev \
        libexpat1-dev \
        libglib2.0-dev \
        libhiredis-dev \
        libjson-c-dev \
        libmaxminddb-dev \
        libnetfilter-conntrack-dev \
        libnetfilter-queue-dev \
        libpango1.0-dev \
        libpcap-dev \
        libradcli-dev \
        librrd-dev \
        libsnmp-dev \
        libsqlite3-dev \
        libssl-dev \
        libtool \
        libtool-bin \
        libxml2-dev \
        libzmq3-dev \
        pkg-config \
        zlib1g-dev \
        libzstd-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /tmp

# nDPI is statically linked into ntopng. ntopng looks for it in ../nDPI.
RUN git clone --depth 1 --branch "${NDPI_VERSION}" https://github.com/ntop/nDPI.git nDPI \
    && cd nDPI \
    && ./autogen.sh \
    && ./configure --with-only-libndpi \
    && make -j"${JOBS}"

# ntopng bundles its own Lua. The httpdocs/dist assets and clickhouse-cpp are
# required at build time; tests/e2e is not. The pinned httpdocs/dist submodule
# commit is no longer fetchable, so use the matching ntopng-dist tag instead.
RUN git clone --depth 1 --branch "${NTOP_VERSION}" https://github.com/ntop/ntopng.git ntopng \
    && cd ntopng \
    && git submodule update --init --recursive --depth 1 third-party/clickhouse-cpp \
    && git clone --depth 1 --branch "${NTOP_VERSION}" https://github.com/ntop/ntopng-dist.git httpdocs/dist \
    && sed -i '/^git submodule init$/d; /^git submodule update --remote$/d' autogen.sh \
    && ./autogen.sh \
    && ./configure \
    && make -j"${JOBS}" \
    && make install

# netflow2ng is written in Go and uses cgo (libzmq).
RUN git clone --depth 1 --branch "v${NETFLOW2NG_VERSION}" https://github.com/synfinatic/netflow2ng.git netflow2ng \
    && cd netflow2ng \
    && go build -trimpath -buildvcs=false -o /usr/local/bin/netflow2ng ./cmd/...

# ==============================================================================
# Runtime stage
# ==============================================================================
FROM ghcr.io/hassio-addons/debian-base:9.3.0

ARG BUILD_ARCH
ARG BUILD_VERSION

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# geoipupdate lives in contrib on Debian trixie.
RUN sed -i -e 's/ main/ main contrib/g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        geoipupdate \
        gir1.2-freedesktop \
        gir1.2-glib-2.0 \
        gir1.2-harfbuzz-0.0 \
        gir1.2-pango-1.0 \
        guile-3.0-libs \
        libcairo-gobject2 \
        libcairo-script-interpreter2 \
        libcurl4 \
        libexpat1 \
        libfl2 \
        libgc1 \
        libgirepository-1.0-1 \
        libglib2.0-bin \
        libgssrpc4 \
        libharfbuzz-gobject0 \
        libharfbuzz-icu0 \
        libhiredis1.1.0 \
        libice6 \
        libjson-c5 \
        libkadm5clnt-mit12 \
        libkadm5srv-mit12 \
        libkdb5-10 \
        libltdl7 \
        liblzo2-2 \
        libmaxminddb0 \
        libncurses6 \
        libnetfilter-conntrack3 \
        libnetfilter-queue1 \
        libnetsnmptrapd40 \
        libnfnetlink0 \
        libnats3.10 \
        libopts25 \
        libpangoxft-1.0-0 \
        libpcap0.8 \
        libpcre2-16-0 \
        libpcre2-32-0 \
        libpcre2-posix3 \
        libprotoc32t64 \
        libradcli4 \
        librdkafka1 \
        librrd8 \
        libsensors-config \
        libsensors5 \
        libsm6 \
        libsnmp-base \
        libsnmp40 \
        libsqlite3-0 \
        libssl3 \
        libxft2 \
        libzmq5 \
        libzstd1 \
        nginx \
        procps \
        redis-server \
        rrdtool \
        wget \
    && apt-get clean \
    && rm -rf \
        /tmp/* \
        /etc/nginx \
        /etc/GeoIP.conf \
        /var/cache/* \
        /var/log/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

COPY --from=builder /usr/local/bin/netflow2ng /usr/local/bin/netflow2ng
COPY --from=builder /usr/local/bin/ntopng /usr/local/bin/ntopng
COPY --from=builder /usr/local/share/ntopng /usr/local/share/ntopng

COPY rootfs /

RUN chmod 775 /etc

LABEL \
    io.hass.name="ntopng" \
    io.hass.description="The SoHo FOSS & FREE ntopng with netflow collector" \
    io.hass.type="addon" \
    io.hass.url="https://github.com/alleyway/hassio-addons/tree/main/ntopng" \
    maintainer="Dominik Strnad <litinoveweedle@gmail.com>" \
    org.opencontainers.image.title="ntopng" \
    org.opencontainers.image.description="The SoHo FOSS & FREE ntopng with netflow collector" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.url="https://github.com/alleyway/hassio-addons/tree/main/ntopng" \
    org.opencontainers.image.source="https://github.com/alleyway/hassio-addons" \
    org.opencontainers.image.documentation="https://github.com/alleyway/hassio-addons/blob/main/ntopng/DOCS.md"
