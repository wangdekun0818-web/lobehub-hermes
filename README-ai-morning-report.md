# LobeHub 云端 · AI 早报部署

将 OpenClaw 约定的深度早报规范部署到 LobeHub Agent「拾光人」。

**Agent 地址：** https://app.lobehub.com/agent/agt_aA2TWAEo3grI/tpc_6bMGaY4IUCTX

## 一键部署

```bash
bash ~/Projects/lobehub-hermes/deploy-ai-morning-report.sh
```

脚本会打开 Agent 页面，并将完整定时任务 Prompt 复制到剪贴板。

## 文件说明

| 文件 | 用途 |
|------|------|
| `ai-morning-report-prompt.txt` | 完整早报规范（18 槽位、两阶段、深度写作） |
| `agent-instructions-ai-morning-report.txt` | Agent 系统指令（短版角色 + 工作流） |
| `scheduled-task-trigger.txt` | 定时任务触发语前缀 |
| `deploy-ai-morning-report.sh` | 部署指引 + 剪贴板复制 |

## UI 配置清单

### 1. 系统指令

粘贴 `agent-instructions-ai-morning-report.txt` 全文。

档案页：https://app.lobehub.com/agent/agt_aA2TWAEo3grI/profile

### 2. 模型

- 模型：`gpt-5.5`
- 若用 AIComing 直连：参考 `setup-aicoming-cloud.sh`
- 若用本地 Hermes：客户端请求模式 → `http://127.0.0.1:8642/v1`

### 3. 工具

启用联网搜索、网页浏览（对应 OpenClaw 的 web_search / web_fetch）。

### 4. 定时任务

| 字段 | 值 |
|------|-----|
| 名称 | AI 情报日报 |
| 频率 | 每天 |
| 时间 | 08:30 |
| 时区 | Asia/Shanghai |
| 任务内容 | `scheduled-task-trigger.txt` + `ai-morning-report-prompt.txt` 合并全文 |

> LobeHub 定时任务**无对话上下文**，任务内容必须自包含完整规范。

### 5. 测试

保存定时任务后，点「立即运行」，确认产出含：
- 国际 10 + 国内 10 条深度动态
- 资本/工具/活动表格 + 机会洞察 6 条 + 数据板 8 行
- 「今日一个概念」

## 与 OpenClaw 的差异

| 项目 | OpenClaw | LobeHub |
|------|----------|---------|
| 调度 | cron `30 8 * * *` | UI 定时任务 |
| 投递 | 飞书自动 announce | 需在 LobeHub 内查看或手动转发 |
| 素材文件 | `memory/YYYY-MM-DD-素材.md` | 无文件工具时用 `---素材槽位N---` 分段 |
| 模型 | `aicoming/gpt-5.5` | `gpt-5.5` |

## 规范源

权威 prompt 与 OpenClaw 同步：`~/.openclaw/cron/ai-morning-report-prompt.txt`
