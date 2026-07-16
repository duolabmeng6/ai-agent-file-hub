#!/usr/bin/env sh
set -eu

PUBLIC_BASE_URL="${AGENT_FILE_HUB_PUBLIC_BASE_URL:-https://my.rongyiapi.com/ai-agent-file-hub}"
MANIFEST_URL="${AGENT_FILE_HUB_MANIFEST_URL:-${PUBLIC_BASE_URL}/version.json}"
COMPOSE_URL="${AGENT_FILE_HUB_COMPOSE_URL:-${PUBLIC_BASE_URL}/docker-compose.yaml}"
VERSION="${AGENT_FILE_HUB_VERSION:-}"
MODE="${AGENT_FILE_HUB_MODE:-auto}"
HOST_PORT="${HOST_PORT:-18787}"
INSTALL_DIR="${AGENT_FILE_HUB_HOME:-$HOME/agent-file-hub}"
APP_NAME="agent_file_hub"
CLI_APP_NAME="afile"

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

fetch_url() {
  url="$1"
  if command_exists curl; then
    curl -fsSL "$url"
    return
  fi
  if command_exists wget; then
    wget -qO- "$url"
    return
  fi
  echo "curl or wget is required to read $url" >&2
  exit 1
}

download_file() {
  url="$1"
  target="$2"
  if command_exists curl; then
    curl -fL "$url" -o "$target"
    return
  fi
  if command_exists wget; then
    wget -O "$target" "$url"
    return
  fi
  echo "curl or wget is required to download $url" >&2
  exit 1
}

set_env_value() {
  file="$1"
  key="$2"
  value="$3"
  tmp_file="${file}.tmp.$$"

  if [ -f "$file" ]; then
    awk -v key="$key" -v value="$value" '
      BEGIN { found = 0 }
      index($0, key "=") == 1 {
        if (!found) {
          print key "=" value
          found = 1
        }
        next
      }
      { print }
      END {
        if (!found) print key "=" value
      }
    ' "$file" > "$tmp_file"
  else
    printf '%s=%s\n' "$key" "$value" > "$tmp_file"
  fi

  mv "$tmp_file" "$file"
}

latest_version() {
  fetch_url "$MANIFEST_URL" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
}

normalize_version() {
  raw="$1"
  case "$raw" in
    v*) printf '%s\n' "$raw" ;;
    "") printf '%s\n' "" ;;
    *) printf 'v%s\n' "$raw" ;;
  esac
}

detect_asset_platform() {
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  machine="$(uname -m)"
  case "$os" in
    linux) goos="linux" ;;
    darwin) goos="darwin" ;;
    *) echo "unsupported OS: $os" >&2; exit 1 ;;
  esac
  case "$machine" in
    x86_64|amd64) goarch="amd64" ;;
    arm64|aarch64) goarch="arm64" ;;
    *) echo "unsupported architecture: $machine" >&2; exit 1 ;;
  esac
  printf '%s-%s\n' "$goos" "$goarch"
}

install_docker() {
  if ! command_exists docker; then
    echo "Docker is required. Install Docker first: https://docs.docker.com/engine/install/" >&2
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "Docker Compose v2 is required. Install Docker Compose first: https://docs.docker.com/compose/install/" >&2
    exit 1
  fi

  data_group_id="$(id -g)"
  mkdir -p "$INSTALL_DIR/data" "$INSTALL_DIR/storage"
  chgrp "$data_group_id" "$INSTALL_DIR/data" "$INSTALL_DIR/storage"
  chmod 2770 "$INSTALL_DIR/data" "$INSTALL_DIR/storage"
  cd "$INSTALL_DIR"

  compose_tmp="$INSTALL_DIR/.docker-compose.yaml.$$"
  if download_file "$COMPOSE_URL" "$compose_tmp"; then
    if ! docker compose -f "$compose_tmp" config >/dev/null; then
      rm -f "$compose_tmp"
      echo "Invalid Docker Compose file downloaded from $COMPOSE_URL" >&2
      exit 1
    fi
    mv "$compose_tmp" "$INSTALL_DIR/docker-compose.yaml"
  else
    rm -f "$compose_tmp"
    echo "Cannot download Docker Compose file from $COMPOSE_URL" >&2
    exit 1
  fi

  set_env_value "$INSTALL_DIR/.env" AGENT_FILE_HUB_VERSION "$VERSION"
  set_env_value "$INSTALL_DIR/.env" HOST_PORT "$HOST_PORT"
  set_env_value "$INSTALL_DIR/.env" DATA_GROUP_ID "$data_group_id"

  docker compose pull
  docker compose up -d

  echo
  echo "Agent File Hub Docker deployment is ready."
  echo "Version: $VERSION"
  echo "Install dir: $INSTALL_DIR"
  echo "URL: http://127.0.0.1:${HOST_PORT}"
}

install_direct() {
  platform="$(detect_asset_platform)"
  asset_url="https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/${VERSION}/${APP_NAME}-${platform}"
  cli_asset_url="https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/${VERSION}/${CLI_APP_NAME}-${platform}"
  mkdir -p "$INSTALL_DIR/storage" "$INSTALL_DIR/data"
  tmp_file="$INSTALL_DIR/.${APP_NAME}.${VERSION}.$$"
  cli_tmp_file="$INSTALL_DIR/.${CLI_APP_NAME}.${VERSION}.$$"

  download_file "$asset_url" "$tmp_file"
  chmod +x "$tmp_file"
  cli_available=0
  if download_file "$cli_asset_url" "$cli_tmp_file"; then
    chmod +x "$cli_tmp_file"
    cli_available=1
  else
    rm -f "$cli_tmp_file"
    echo "CLI asset is not available for $VERSION; continuing without afile." >&2
  fi
  if [ -f "$INSTALL_DIR/$APP_NAME" ]; then
    cp "$INSTALL_DIR/$APP_NAME" "$INSTALL_DIR/$APP_NAME.previous" 2>/dev/null || true
  fi
  if [ "$cli_available" = "1" ] && [ -f "$INSTALL_DIR/$CLI_APP_NAME" ]; then
    cp "$INSTALL_DIR/$CLI_APP_NAME" "$INSTALL_DIR/$CLI_APP_NAME.previous" 2>/dev/null || true
  fi
  mv "$tmp_file" "$INSTALL_DIR/$APP_NAME"
  if [ "$cli_available" = "1" ]; then
    mv "$cli_tmp_file" "$INSTALL_DIR/$CLI_APP_NAME"
  fi

  cat > "$INSTALL_DIR/run-local.sh" <<'EOF'
#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
PORT="${PORT:-18787}"
FILE_BROWSER_ROOT="${FILE_BROWSER_ROOT:-$PWD/storage}"
export PORT FILE_BROWSER_ROOT
exec ./agent_file_hub "$@"
EOF
  chmod +x "$INSTALL_DIR/run-local.sh"

  echo
  echo "Agent File Hub binary is ready."
  echo "Version: $VERSION"
  echo "Install dir: $INSTALL_DIR"
  echo "Run: $INSTALL_DIR/run-local.sh"
  if [ "$cli_available" = "1" ]; then
    echo "CLI: $INSTALL_DIR/afile"
  fi
}

if [ -z "$VERSION" ]; then
  VERSION="$(latest_version)"
fi
VERSION="$(normalize_version "$VERSION")"
if [ -z "$VERSION" ]; then
  echo "Cannot resolve latest Agent File Hub version from $MANIFEST_URL" >&2
  exit 1
fi

if [ "$MODE" = "auto" ]; then
  if command_exists docker && docker compose version >/dev/null 2>&1; then
    MODE="docker"
  else
    MODE="direct"
  fi
fi

case "$MODE" in
  docker|compose) install_docker ;;
  direct|binary|local) install_direct ;;
  *) echo "Unsupported AGENT_FILE_HUB_MODE: $MODE" >&2; exit 1 ;;
esac
