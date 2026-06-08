#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

VERSION="${AGENT_FILE_HUB_VERSION:-v1.0.0}"
HOST_PORT="${HOST_PORT:-9000}"
IMAGE="duolabmeng/agent_file_hub:${VERSION}"

if docker compose version >/dev/null 2>&1; then
  AGENT_FILE_HUB_VERSION="$VERSION" HOST_PORT="$HOST_PORT" docker compose up -d --build
  exit 0
fi

docker build --build-arg VERSION="$VERSION" -t "$IMAGE" .
docker rm -f agent_file_hub >/dev/null 2>&1 || true
docker run -d \
  --name agent_file_hub \
  --restart unless-stopped \
  -p "${HOST_PORT}:9000" \
  -e PORT=9000 \
  -e GIN_MODE=release \
  -e FILE_BROWSER_ROOT=/app/storage \
  -v agent_file_hub_data:/app/data \
  -v agent_file_hub_storage:/app/storage \
  "$IMAGE"
