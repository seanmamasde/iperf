# syntax=docker/dockerfile:1
#
# Build:  docker buildx build --platform linux/arm/v5 -t iperf3-armv5:latest .
# Server: docker run --rm -p 5201:5201 iperf3-armv5:latest -s
# Client: docker run --rm iperf3-armv5:latest -c <server-ip>
# DNS unavailable in scratch — use IP addresses only.

FROM --platform=$BUILDPLATFORM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc-arm-linux-gnueabi \
        libc6-dev-armel-cross \
        make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .

RUN ./configure \
        --host=arm-linux-gnueabi \
        CC=arm-linux-gnueabi-gcc \
        --enable-static \
        --disable-shared \
        --without-openssl \
        --without-sctp \
        CFLAGS="-Os" \
        LDFLAGS="--static" \
    && make -j"$(nproc)" \
    && arm-linux-gnueabi-strip src/iperf3

RUN mkdir -p /scratch-tmp

FROM scratch

LABEL org.opencontainers.image.source="https://github.com/seanmamasde/iperf"
LABEL org.opencontainers.image.description="iperf3 for armv5te (armel)"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"

COPY --from=builder /build/src/iperf3 /iperf3
COPY --from=builder /scratch-tmp /tmp

ENTRYPOINT ["/iperf3"]
EXPOSE 5201
