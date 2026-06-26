# LobeHub · AI 情报早报（对话页展示）

将 OpenClaw 深度早报规范部署到 LobeHub，**成稿直接显示在对话页**，不发飞书。

## 本地一键配置

```bash
bash ~/Projects/lobehub-hermes/setup-lobehub-local-morning-report.sh
```

脚本会：生成 6 段任务 prompt、复制系统指令到剪贴板、打开 `http://127.0.0.1:3010`。

**手动 3 步：** 新建助手「AI情报早报」→ 粘贴系统指令 → 模型 gpt-5.5。

## 云端 Agent（拾光人）

## 一键部署

```bash
bash ~/Projects/lobehub-hermes/deploy-ai-morning-report.sh
```

脚本会：

1. 生成 6 个定时任务 prompt（`ai-morning-report/scheduled-tasks/`）
2. 打开 LobeHub 任务页，并将**合稿任务** prompt 复制到剪贴板

## 规范固化（代码层）

| 文件 | 内容 |
|------|------|
| `ai-morning-report/constants.py` | 固定源 A–H、18 槽位、条数、表格模板 |
| `ai-morning-report/validate.py` | 成稿条数校验 |
| `ai-morning-report/prompts/` | 阶段 prompt（与 Hermes / OpenClaw 同步） |
| `ai-morning-report/build-scheduled-tasks.py` | 生成 LobeHub 任务正文 |

条数：国际 10 · 国内 10 · 资本 5 · 工具 8 · 活动 8 · 洞察 6 · 数据板 8 · 概念 1。

## UI 配置

### 1. 系统指令

档案页：https://app.lobehub.com/agent/agt_aA2TWAEo3grI/profile

粘贴 `agent-instructions-ai-morning-report.txt` 全文。

### 2. 模型与工具

- 模型：`gpt-5.5`（AIComing 或 Hermes `http://127.0.0.1:8642/v1`）
- 工具：**联网搜索**、**网页浏览**

### 3. 定时任务（6 个，Asia/Shanghai）

| 名称 | 时间 | 任务内容文件 |
|------|------|--------------|
| AI早报-1采集 | 06:00 | `scheduled-tasks/collect-task.txt` |
| AI早报-2A国际 | 07:00 | `scheduled-tasks/intl-task.txt` |
| AI早报-2B国内 | 07:02 | `scheduled-tasks/domestic-task.txt` |
| AI早报-2C表格 | 07:04 | `scheduled-tasks/tables-task.txt` |
| AI早报-2D洞察 | 07:06 | `scheduled-tasks/insights-task.txt` |
| AI早报-3合稿 | **08:00** | `scheduled-tasks/merge-task.txt` |

> LobeHub 定时任务**无跨任务上下文**。每段任务正文必须自包含；无文件工具时用 `---素材槽位N---` 分段。

重新生成任务正文：

```bash
python3 ~/Projects/lobehub-hermes/ai-morning-report/build-scheduled-tasks.py
```

### 4. 测试

在 LobeHub 对「AI早报-1采集」点**立即运行**，再依次测试 2A–合稿，或只测合稿（需前序分段已在对话/记忆中）。

校验成稿：

```bash
python3 ~/Projects/lobehub-hermes/ai-morning-report/validate.py report.md
```

## 与 Hermes 的差异

| 项目 | Hermes | LobeHub |
|------|--------|---------|
| 调度 | `~/.hermes/cron/jobs.json` | UI 6 个定时任务 / HTTP API |
| 08:00 展示 | 飞书群 / LibreChat | **本 Agent 对话页**（不发飞书） |
| 素材存储 | `~/.hermes/workspace/ai-morning-report/memory/` | 本话题内 `---分段:xxx---` 标记 |

Hermes 侧启用：`bash ~/Projects/librechat-hermes/ai-morning-report/setup-ai-morning-report.sh`

## 投递 API（推荐）

成稿生成后，通过 HTTP 接口把**完整 Markdown 正文**写入 LobeHub 聊天页（默认话题 `NHODLDqg`）。

### 1. 启动 API

```bash
bash ~/Projects/lobehub-hermes/start-lobehub-deliver-api.sh
```

默认监听 `http://127.0.0.1:8765`。环境变量见 `ai-morning-report/.env.example`。

### 2. 投递今日早报

```bash
curl -X POST http://127.0.0.1:8765/v1/deliver/morning-report \
  -H 'Content-Type: application/json' \
  -d '{"date":"2026-06-26"}'
```

或指定话题 / 直接传正文：

```bash
curl -X POST http://127.0.0.1:8765/v1/deliver/morning-report \
  -H 'Content-Type: application/json' \
  -d '{
    "session_id": "inbox",
    "topic_id": "NHODLDqg",
    "content": "# AI 情报日报 | 2026-06-26\n\n..."
  }'
```

### 3. Hermes 成稿后自动投递

```bash
bash ~/Projects/lobehub-hermes/ai-morning-report/call-lobehub-deliver-api.sh 2026-06-26
```

### 接口一览

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/health` | 健康检查 |
| POST | `/v1/deliver/morning-report` | 投递早报（`date` 或 `content`） |
| POST | `/v1/deliver/message` | 投递任意 Markdown 消息 |

> 本地 LobeHub 使用浏览器 IndexedDB 存储；API 通过 `agent-browser` 写入目标话题后刷新页面即可看到消息。

## 权威源

`~/.openclaw/cron/ai-morning-report-prompt.txt` 及 `README-ai-morning-report-pipeline.md`
