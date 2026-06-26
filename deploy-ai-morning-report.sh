#!/usr/bin/env bash
# 将 OpenClaw 早报规范部署到 LobeHub 云端 Agent「拾光人」（6 段流水线）
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
AMR="${DIR}/ai-morning-report"
AGENT_URL="https://app.lobehub.com/agent/agt_aA2TWAEo3grI/tpc_6bMGaY4IUCTX"
PROFILE_URL="https://app.lobehub.com/agent/agt_aA2TWAEo3grI/profile"
TASK_URL="https://app.lobehub.com/agent/agt_aA2TWAEo3grI/task/T-1"
INSTRUCTIONS_FILE="${DIR}/agent-instructions-ai-morning-report.txt"

echo "==> 生成 6 段定时任务 prompt"
python3 "${AMR}/build-scheduled-tasks.py"

MERGE_FILE="${AMR}/scheduled-tasks/merge-task.txt"
TODAY="$(TZ=Asia/Shanghai date +%Y-%m-%d)"

echo ""
echo "=============================================="
echo " LobeHub 云端 · AI 情报早报（6 段流水线）"
echo " Agent: 拾光人 (agt_aA2TWAEo3grI)"
echo " 合稿发送: 每天 08:00 Asia/Shanghai"
echo "=============================================="
echo ""
echo "【步骤 1】系统指令 → ${PROFILE_URL}"
echo "  文件: agent-instructions-ai-morning-report.txt"
echo ""
echo "【步骤 2】模型 gpt-5.5 + 启用联网搜索/网页浏览"
echo ""
echo "【步骤 3】创建 6 个定时任务（见 README-ai-morning-report.md 时间表）"
echo "  任务正文: ${AMR}/scheduled-tasks/*-task.txt"
echo ""
echo "【步骤 4】先「立即运行」采集任务，再测合稿"
echo ""

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$MERGE_FILE"
  echo "✓ 合稿任务 prompt 已复制到剪贴板（${TODAY}）"
fi

open "$TASK_URL" 2>/dev/null || open "$AGENT_URL" 2>/dev/null || true
