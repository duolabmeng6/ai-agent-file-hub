# AI 智能体文件中枢

Agent File Hub 是人与 AI Agent 共用的文件工作台，一处管理文件、文档与项目知识。

## 开始使用

### 交给 Agent 安装

把下面这句话发给 Codex、Claude 或 OpenClaw，Agent 会检查系统环境，完成安装、启动并验证访问地址。

```text
请阅读下面的安装技能，帮我安装并启动 Agent File Hub：
https://my.rongyiapi.com/ai-agent-file-hub/skills/agent-file-hub/SKILL.md
```

### 服务器：Docker Compose

服务器已安装 Docker 和 Docker Compose 后，运行：

```sh
git clone https://github.com/duolabmeng6/ai-agent-file-hub.git
cd ai-agent-file-hub
docker compose up -d
```

访问 `http://服务器IP:18787`，跟随页面设置管理员账号。数据保存在 Docker 卷中。

更新服务：

```sh
docker compose pull
docker compose up -d
```

[查看 Compose 配置](https://github.com/duolabmeng6/ai-agent-file-hub/blob/main/docker-compose.yaml) · [afile 命令参考](https://my.rongyiapi.com/ai-agent-file-hub/afile.html) · [打开官网](https://my.rongyiapi.com/ai-agent-file-hub/)

## 产品能力

- 统一管理本地目录、对象存储、SFTP 和 Git 仓库。
- 用 Markdown 与目录保存文档、知识和项目记忆。
- 通过 MCP 与授权目录连接 Agent，把文档分享给团队。

版本：v1.0.13 · [源代码](https://github.com/duolabmeng6/ll-filebrowser)
