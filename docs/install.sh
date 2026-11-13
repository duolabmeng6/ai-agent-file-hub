#!/usr/bin/env sh
set -eu

PUBLIC_BASE_URL="${AGENT_FILE_HUB_PUBLIC_BASE_URL:-https://my.rongyiapi.com/ai-agent-file-hub}"
MANIFEST_URL="${AGENT_FILE_HUB_MANIFEST_URL:-${PUBLIC_BASE_URL}/version.json}"
COMPOSE_URL="${AGENT_FILE_HUB_COMPOSE_URL:-${PUBLIC_BASE_URL}/docker-compose.yaml}"
VERSION="${AGENT_FILE_HUB_VERSION:-}"
MODE="${1:-${AGENT_FILE_HUB_MODE:-auto}}"
INSTALL_DIR_OVERRIDE="${AGENT_FILE_HUB_HOME:-}"
APP_NAME="afile"

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

  if [ -z "$INSTALL_DIR_OVERRIDE" ] && [ "$(id -u)" -ne 0 ]; then
    echo "Docker installation writes to /opt/stacks/agent-file-hub; run the installer with sudo." >&2
    exit 1
  fi

  INSTALL_DIR="${INSTALL_DIR_OVERRIDE:-/opt/stacks/agent-file-hub}"
  mkdir -p "$INSTALL_DIR/data" "$INSTALL_DIR/storage"
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

  docker compose pull
  docker compose up -d

  echo
  echo "Agent File Hub Docker deployment is ready."
  echo "Install dir: $INSTALL_DIR"
  echo "URL: http://127.0.0.1:18787"
}

install_direct() {
  INSTALL_DIR="${INSTALL_DIR_OVERRIDE:-$HOME/agent-file-hub}"
  platform="$(detect_asset_platform)"
  asset="${APP_NAME}-${platform}.gz"
  release_base="https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/${VERSION}"
  asset_url="${release_base}/${asset}"
  mkdir -p "$INSTALL_DIR/storage" "$INSTALL_DIR/data"
  staging="$(mktemp -d "$INSTALL_DIR/.afile-install.XXXXXX")"
  trap 'rm -rf "$staging"' EXIT
  trap 'exit 1' HUP INT TERM
  download_file "$asset_url" "$staging/$asset"
  download_file "${release_base}/checksums.txt" "$staging/checksums.txt"
  expected="$(awk -v asset="$asset" '$2 == asset { print $1 }' "$staging/checksums.txt")"
  if [ "${#expected}" -ne 64 ]; then echo "Invalid checksum for $asset" >&2; exit 1; fi
  if command_exists sha256sum; then
    actual="$(sha256sum "$staging/$asset" | awk '{print $1}')"
  elif command_exists shasum; then
    actual="$(shasum -a 256 "$staging/$asset" | awk '{print $1}')"
  else
    echo "sha256sum or shasum is required" >&2; exit 1
  fi
  if [ "$actual" != "$expected" ]; then echo "SHA-256 mismatch for $asset" >&2; exit 1; fi
  gzip -dc "$staging/$asset" > "$staging/afile"
  test -s "$staging/afile"
  chmod +x "$staging/afile"
  if [ -f "$INSTALL_DIR/$APP_NAME" ]; then
    cp "$INSTALL_DIR/$APP_NAME" "$INSTALL_DIR/$APP_NAME.previous"
  fi
  mv "$staging/afile" "$INSTALL_DIR/$APP_NAME"

  cat > "$INSTALL_DIR/run-local.sh" <<'EOF'
#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
PORT="${PORT:-18787}"
FILE_BROWSER_ROOT="${FILE_BROWSER_ROOT:-$PWD/storage}"
export PORT FILE_BROWSER_ROOT
exec ./afile "$@"
EOF
  chmod +x "$INSTALL_DIR/run-local.sh"

  echo
  echo "Agent File Hub binary is ready."
  echo "Version: $VERSION"
  echo "Install dir: $INSTALL_DIR"
  echo "Run: $INSTALL_DIR/run-local.sh"
  echo "CLI: $INSTALL_DIR/afile"
}

if [ "$MODE" = "auto" ]; then
  if command_exists docker && docker compose version >/dev/null 2>&1; then
    MODE="docker"
  else
    MODE="direct"
  fi
fi

case "$MODE" in
  direct|binary|local)
    if [ -z "$VERSION" ]; then
      VERSION="$(latest_version)"
    fi
    VERSION="$(normalize_version "$VERSION")"
    if [ -z "$VERSION" ]; then
      echo "Cannot resolve latest Agent File Hub version from $MANIFEST_URL" >&2
      exit 1
    fi
    ;;
esac

case "$MODE" in
  docker|compose) install_docker ;;
  direct|binary|local) install_direct ;;
  *) echo "Unsupported AGENT_FILE_HUB_MODE: $MODE" >&2; exit 1 ;;
esac
