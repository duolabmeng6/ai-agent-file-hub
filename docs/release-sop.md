# AgentFileHub 发版与官网同步 SOP

本文档记录 `duolabmeng6/ll-filebrowser` 发版时如何同步 `duolabmeng6/ai-agent-file-hub` 的 Release、Docker 镜像、官网资料、版本文件和 Codex 安装技能。

## 目标

一次 tag 发版必须同时完成：

- 当前源码仓库 Release 生成多平台二进制产物。
- `duolabmeng6/ai-agent-file-hub` Release 使用同一个 tag，并上传同名二进制产物。
- Docker Hub 镜像 `duolabmeng/agent_file_hub` 使用同一个 tag 构建和推送。
- 官网仓库资料随 tag 同步：`readme.md`、`docs/index.html`、`docs/version.json`、`docs/install.sh`、`run.sh`、`docker-compose.yaml`、`.env.example`、公开 Skill 和本 SOP。
- GitHub Pages 在官网仓库 `main` 更新后自动部署。

## 版本来源

唯一版本源是 `web/app/package.json` 的 `version` 字段。

发版 tag 必须等于：

```text
v<web/app/package.json version>
```

示例：`web/app/package.json` 为 `1.0.1` 时，tag 必须是 `v1.0.1`。

## 需要的 Secrets

在 `duolabmeng6/ll-filebrowser` 仓库的 GitHub Actions Secrets 中配置：

| Secret | 用途 |
| --- | --- |
| `FILE_HUB_TOKEN` | 写入 `duolabmeng6/ai-agent-file-hub` Release、文件和 push |
| `DOCKERHUB_USERNAME` | 登录 Docker Hub |
| `DOCKERHUB_TOKEN` | 推送 `duolabmeng/agent_file_hub` 镜像 |

`FILE_HUB_TOKEN` 至少需要目标仓库 `duolabmeng6/ai-agent-file-hub` 的 contents 写权限，能创建/编辑 Release、上传 assets、提交并推送 `main`。

## 发版前检查

在产品仓库执行：

```bash
cd /Users/ll/Desktop/2026/ll-filebrowser
npm run typecheck --prefix web/app
npm run build --prefix web/app
go test ./...
```

如果只修改发版、官网或文档流程，也至少执行：

```bash
git diff --check
ruby -e 'require "yaml"; YAML.load_file(".github/workflows/release.yml"); puts "workflow yaml ok"'
python3 -m json.tool /Users/ll/Desktop/2026/ai-agent-file-hub/docs/version.json >/dev/null
```

## 发版步骤

1. 更新 `web/app/package.json` 的 `version`。
2. 确认 `readme.md`、`.agents/skills/agent-file-hub/SKILL.md` 和官网资料源已经更新。
3. 提交产品仓库变更。
4. 创建并推送 tag：

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

5. GitHub Actions 自动执行 `.github/workflows/release.yml`。

## 自动同步链路

Release workflow 执行顺序：

1. 校验 tag 与 `web/app/package.json` 版本一致。
2. 构建前端并嵌入 Go 二进制。
3. 构建 `agent_file_hub-*` 多平台产物。
4. 发布当前源码仓库 Release。
5. 发布 `duolabmeng6/ai-agent-file-hub` 同 tag Release。
6. 构建并推送 Docker Hub 镜像。
7. 写入 `duolabmeng6/ai-agent-file-hub` Release Notes。
8. 调用 `scripts/sync-file-hub-release-docs.sh` 同步官网资料。
9. 如果官网仓库有 diff，则提交并 push 到 `main`。
10. 官网仓库 Pages workflow 自动部署 `docs/`。

同步脚本：

```bash
scripts/sync-file-hub-release-docs.sh /path/to/ai-agent-file-hub
```

脚本会更新：

- `readme.md`
- `docs/index.html`
- `docs/version.json`
- `docs/install.sh`
- `docs/skills/agent-file-hub/SKILL.md`
- `docs/release-sop.md`
- `run.sh`
- `docker-compose.yaml`
- `.env.example`
- `Dockerfile`

## 官网资料约定

官网仓库是发布和分发仓库，产品仓库是源头。

| 内容 | 源头 | 官网位置 |
| --- | --- | --- |
| 产品介绍 | `ll-filebrowser/readme.md` | `ai-agent-file-hub/readme.md` |
| 用户安装 Skill | `.agents/skills/agent-file-hub/SKILL.md` | `docs/skills/agent-file-hub/SKILL.md` |
| 发版 SOP | `docs/release-sop.md` | `docs/release-sop.md` |
| 当前版本 | tag / `web/app/package.json` | `docs/version.json`、官网页面、安装脚本、Docker 配置 |

官网页面上的版本号、Release 链接、二进制下载链接、Docker 标签和页脚版本都必须随 tag 更新。`docs/version.json` 同时作为应用内检查更新和 `install.sh` 默认版本解析的 manifest。

## AI Agent 安装技能发版规则

`agent-file-hub` skill 面向最终用户安装 AgentFileHub 应用。

源文件：

```text
/Users/ll/Desktop/2026/ll-filebrowser/.agents/skills/agent-file-hub/SKILL.md
```

公开地址：

```text
https://my.rongyiapi.com/ai-agent-file-hub/skills/agent-file-hub/SKILL.md
```

发给智能体的一句话：

```text
请帮我安装 AgentFileHub，安装技能: https://my.rongyiapi.com/ai-agent-file-hub/skills/agent-file-hub/SKILL.md
```

官网只展示这一句话和 Skill 文件地址。详细安装命令、环境判断、Docker Compose、直接运行和排障流程保留在 `SKILL.md`。

## 发版后验收

检查 Release：

```bash
gh release view v1.0.1 --repo duolabmeng6/ll-filebrowser
gh release view v1.0.1 --repo duolabmeng6/ai-agent-file-hub
```

检查官网：

```bash
curl -fsSL https://my.rongyiapi.com/ai-agent-file-hub/version.json | python3 -m json.tool
curl -fsSL https://my.rongyiapi.com/ai-agent-file-hub/skills/agent-file-hub/SKILL.md | sed -n '1,20p'
curl -fsSL https://my.rongyiapi.com/ai-agent-file-hub/install.sh | sed -n '1,40p'
```

检查 Docker：

```bash
docker pull duolabmeng/agent_file_hub:v1.0.1
docker pull duolabmeng/agent_file_hub:latest
```

检查页面：

- 官网首页显示当前版本。
- 下载链接指向当前 tag。
- 智能安装技能区块显示一句话安装入口和公开 Skill 地址。
- GitHub 图标跳转到 `https://github.com/duolabmeng6/ai-agent-file-hub`。

## 失败恢复

Release 上传失败：

- 修复 token 或 workflow 后重新运行同一个 tag workflow。
- workflow 使用 `gh release upload --clobber` 覆盖同名资产。

官网资料未同步：

```bash
TAG_NAME=v1.0.1 \
FILE_HUB_REPOSITORY=duolabmeng6/ai-agent-file-hub \
SOURCE_REPOSITORY=duolabmeng6/ll-filebrowser \
scripts/sync-file-hub-release-docs.sh /Users/ll/Desktop/2026/ai-agent-file-hub
```

确认 diff 后在官网仓库提交并 push：

```bash
cd /Users/ll/Desktop/2026/ai-agent-file-hub
git add readme.md docs/index.html docs/version.json docs/install.sh docs/skills/agent-file-hub/SKILL.md docs/release-sop.md run.sh docker-compose.yaml .env.example Dockerfile
git commit -m "docs: 同步 v1.0.1 官网资料"
git push
```

Docker 镜像失败：

- 检查 `DOCKERHUB_USERNAME` 和 `DOCKERHUB_TOKEN`。
- 重新运行 workflow。
- Dockerfile 必须从 `duolabmeng6/ai-agent-file-hub` 当前 tag Release 下载 Linux 二进制。

Pages 未部署：

- 检查 `duolabmeng6/ai-agent-file-hub` 的 `.github/workflows/pages.yml`。
- 确认官网仓库 `main` 已收到 `docs/**` 更新。
- 手动触发 Pages workflow。
