# syntax=docker/dockerfile:1.7

ARG TARGETOS=linux
ARG TARGETARCH=amd64

FROM alpine:3.21 AS downloader

ARG VERSION=v1.0.12
ARG TARGETOS=linux
ARG TARGETARCH=amd64

RUN apk add --no-cache ca-certificates wget

RUN set -eux; \
    case "${TARGETOS}/${TARGETARCH}" in \
      linux/amd64|linux/arm64) ;; \
      *) echo "unsupported target: ${TARGETOS}/${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    asset="afile-${TARGETOS}-${TARGETARCH}.gz"; \
    base="https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/${VERSION}"; \
    mkdir /download; cd /download; \
    wget -O "$asset" "${base}/${asset}"; \
    wget -O checksums.txt "${base}/checksums.txt"; \
    awk -v asset="$asset" '$2 == asset { print }' checksums.txt > selected.txt; \
    test -s selected.txt; sha256sum -c selected.txt; \
    gzip -dc "$asset" > /afile; \
    chmod 0755 /afile


FROM alpine:3.21

RUN apk add --no-cache ca-certificates tzdata wget \
    && addgroup -S app \
    && adduser -S -G app -h /app app

WORKDIR /app

ENV PORT=9000 \
    GIN_MODE=release \
    TZ=Asia/Shanghai \
    FILE_BROWSER_ROOT=/app/storage

COPY --from=downloader /afile /app/afile

RUN mkdir -p /app/data /app/storage \
    && chown -R app:app /app

USER app

EXPOSE 9000

VOLUME ["/app/data", "/app/storage"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD wget -qO- "http://127.0.0.1:${PORT}/" >/dev/null || exit 1

ENTRYPOINT ["/app/afile"]
