#!/usr/bin/env sh
set -eu

VERSION="${AGENT_FILE_HUB_VERSION:-v1.0.0}"
HOST_PORT="${HOST_PORT:-18787}"
INSTALL_DIR="${AGENT_FILE_HUB_HOME:-$HOME/agent-file-hub}"
IMAGE="duolabmeng/agent_file_hub:${VERSION}"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if ! command_exists docker; then
  echo "Docker is required. Install Docker first: https://docs.docker.com/engine/install/"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is required. Install Docker Compose first: https://docs.docker.com/compose/install/"
  exit 1
fi

mkdir -p "$INSTALL_DIR/storage"
cd "$INSTALL_DIR"

cat > docker-compose.yaml <<EOF
services:
  agent-file-hub:
    image: ${IMAGE}
    container_name: agent_file_hub
    restart: unless-stopped
    environment:
      PORT: 9000
      GIN_MODE: release
      TZ: \${TZ:-Asia/Shanghai}
      FILE_BROWSER_ROOT: /app/storage
      FILE_BROWSER_AUTH_USERNAME: \${FILE_BROWSER_AUTH_USERNAME:-admin}
      FILE_BROWSER_AUTH_PASSWORD: \${FILE_BROWSER_AUTH_PASSWORD:-}
    ports:
      - "${HOST_PORT}:9000"
    volumes:
      - agent_file_hub_data:/app/data
      - ./storage:/app/storage
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://127.0.0.1:9000/ >/dev/null || exit 1"]
      interval: 30s
      timeout: 5s
      start_period: 20s
      retries: 3

volumes:
  agent_file_hub_data:
EOF

docker compose pull
docker compose up -d

echo
echo "Agent File Hub is running."
echo "Install dir: $INSTALL_DIR"
echo "URL: http://127.0.0.1:${HOST_PORT}"
