---
name: agent-file-hub
description: Use when a user wants to install, deploy, start, update, or troubleshoot AgentFileHub. Guides Codex through choosing an installation method, checking prerequisites, installing AgentFileHub, configuring runtime settings, starting the service, and verifying that the app is accessible.
---

# AgentFileHub Installer

Use this skill when the user invokes `$agent-file-hub`, shares this public Skill URL, or asks an AI agent such as OpenClaw, Claude, or Codex to install, deploy, start, update, uninstall, or troubleshoot AgentFileHub.

If the user says only "请帮我安装 AgentFileHub，安装技能: https://my.rongyiapi.com/ai-agent-file-hub/skills/agent-file-hub/SKILL.md", treat that sentence as full authorization to read this skill, inspect the local environment, choose the best install mode, install AgentFileHub, start it, and verify access.

Default recommendation: use Docker Compose for servers and long-running deployments. Use direct release binaries when Docker is unavailable or the user wants a quick local trial.

## Default Targets

- Product: AgentFileHub / AI智能体文件中枢
- Repository: `https://github.com/duolabmeng6/ai-agent-file-hub`
- Releases: `https://github.com/duolabmeng6/ai-agent-file-hub/releases`
- Docker image: `duolabmeng/agent_file_hub`
- Public installer: `https://my.rongyiapi.com/ai-agent-file-hub/install.sh`
- Public skill: `https://my.rongyiapi.com/ai-agent-file-hub/skills/agent-file-hub/SKILL.md`
- Release SOP: `https://my.rongyiapi.com/ai-agent-file-hub/release-sop.md`
- Default external port: `18787`
- Docker container port: `9000`
- Docker install directory: `~/agent-file-hub`
- Docker storage directory: `~/agent-file-hub/storage`
- Direct-run storage directory: `./storage`
- User skill install path: `~/.agents/skills/agent-file-hub/SKILL.md`

First browser access should open the setup page if no admin account exists. Ask the user to create the administrator account in the browser unless they intentionally set `FILE_BROWSER_AUTH_PASSWORD` before first start.

## Start Workflow

1. Detect the environment:
   ```bash
   uname -s
   uname -m
   command -v docker || true
   docker compose version || true
   command -v git || true
   ```
   On Windows, use PowerShell equivalents and prefer release download over shell scripts unless WSL or Docker Desktop is available.

2. Check port availability before starting:
   ```bash
   lsof -nP -iTCP:18787 -sTCP:LISTEN || true
   ```
   If occupied, either stop the existing service after user approval or choose another `HOST_PORT`.

3. Choose install mode:
   - Server, Linux VM, NAS, or long-running deployment: Docker Compose.
   - Local macOS/Linux trial without Docker: release binary.
   - Windows desktop: release `.exe`.
   - Developer machine modifying source: source build.

4. Install, start, verify, then tell the user the access URL.

## Docker Compose Install

Recommended for servers and long-running use.

```bash
u=https://my.rongyiapi.com
p=/ai-agent-file-hub/install.sh
curl -fsSL "$u$p" -o install.sh
bash install.sh
```

Custom port or version:

```bash
AGENT_FILE_HUB_VERSION=v1.0.0 HOST_PORT=18787 bash install.sh
```

After install:

```bash
cd ~/agent-file-hub
docker compose ps
docker compose logs --tail=80 agent-file-hub
curl -I http://127.0.0.1:18787/
```

Update:

```bash
cd ~/agent-file-hub
docker compose pull
docker compose up -d
```

Restart and stop:

```bash
cd ~/agent-file-hub
docker compose restart
docker compose down
```

Uninstall while keeping data:

```bash
cd ~/agent-file-hub
docker compose down
```

Remove data only after explicit user approval:

```bash
docker volume rm agent_file_hub_data agent_file_hub_storage
```

## Direct Release Install

Use release binaries when Docker is unavailable.

Linux x64:

```bash
curl -L -o agent_file_hub https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/v1.0.0/agent_file_hub-linux-amd64
chmod +x agent_file_hub
PORT=18787 FILE_BROWSER_ROOT=./storage ./agent_file_hub
```

Linux ARM64 asset:

```text
https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/v1.0.0/agent_file_hub-linux-arm64
```

macOS Apple Silicon:

```bash
curl -L -o agent_file_hub https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/v1.0.0/agent_file_hub-darwin-arm64
chmod +x agent_file_hub
PORT=18787 FILE_BROWSER_ROOT=./storage ./agent_file_hub
```

macOS Intel asset:

```text
https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/v1.0.0/agent_file_hub-darwin-amd64
```

Windows assets:

```text
https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/v1.0.0/agent_file_hub-windows-amd64.exe
https://github.com/duolabmeng6/ai-agent-file-hub/releases/download/v1.0.0/agent_file_hub-windows-arm64.exe
```

Direct-run data files are created under the process working directory by default. Keep the binary in a dedicated directory if the user wants predictable `data/`, `storage/`, and log paths.

## Source Build Install

Use only when the user has the source tree and wants to build locally.

```bash
git clone https://github.com/duolabmeng6/ai-agent-file-hub.git
cd ai-agent-file-hub
```

For the product source repository, build with the Go/Vue source project:

```bash
cd /Users/ll/Desktop/2026/ll-filebrowser
make build
PORT=18787 FILE_BROWSER_ROOT=./storage ./dist/ll-filebrowser
```

If dependencies or sibling repositories are missing, prefer release binaries or Docker.

## Runtime Configuration

Common environment variables:

```text
PORT=18787
FILE_BROWSER_ROOT=./storage
FILE_BROWSER_AUTH_USERNAME=admin
FILE_BROWSER_AUTH_PASSWORD=<set only when pre-seeding the first admin password>
FILE_BROWSER_AUTH_PATH=<optional auth.json path>
FILE_BROWSER_STORAGES_PATH=<optional storages.json path>
```

Docker installer maps `HOST_PORT` to container port `9000`, and sets `FILE_BROWSER_ROOT=/app/storage` inside the container.

## Verification Checklist

After start, verify in this order:

1. Process or container is running.
2. Port responds:
   ```bash
   curl -I http://127.0.0.1:18787/
   ```
3. Browser opens:
   ```text
   http://127.0.0.1:18787
   ```
4. If redirected to `/setup`, guide the user to create the admin account.
5. If redirected to `/login`, ask the user to sign in with the configured account.
6. Confirm the storage root can be browsed after login.

## Troubleshooting

Port occupied:

```bash
lsof -nP -iTCP:18787 -sTCP:LISTEN
```

Choose another port:

```bash
HOST_PORT=18788 bash install.sh
```

Docker missing:

- macOS/Windows: install Docker Desktop.
- Linux server: install Docker Engine and Docker Compose v2 from Docker official docs.

Container starts then exits:

```bash
cd ~/agent-file-hub
docker compose logs --tail=120 agent-file-hub
```

Access fails:

- Confirm the host port with `docker compose ps`.
- Check firewall or security group rules for server deployments.
- For remote servers, use `http://<server-ip>:18787`.

Admin account problem:

- First run with no password redirects to `/setup`.
- `FILE_BROWSER_AUTH_PASSWORD` only seeds the password when `auth.json` does not exist.
- To reset credentials, stop the service and inspect the configured `data/auth.json` path before changing files.

## Install This Skill

Install the public skill into the user skills directory:

```bash
mkdir -p ~/.agents/skills/agent-file-hub
curl -fsSL https://my.rongyiapi.com/ai-agent-file-hub/skills/agent-file-hub/SKILL.md -o ~/.agents/skills/agent-file-hub/SKILL.md
```

Then start a new Codex thread and send:

```text
$agent-file-hub
```

## Maintainer Release Notes

For maintainers preparing a new AgentFileHub release, follow the release SOP:

```text
/Users/ll/Desktop/2026/ll-filebrowser/docs/release-sop.md
```

The release workflow calls:

```bash
scripts/sync-file-hub-release-docs.sh <ai-agent-file-hub-repo>
```

That script keeps the public website, `version.json`, `install.sh`, Docker files, `readme.md`, public skill, and release SOP synchronized with the release tag.
