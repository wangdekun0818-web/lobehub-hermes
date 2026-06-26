#!/usr/bin/env bash
# 本地 LobeHub：配置「AI情报早报」助手，成稿展示在对话页（不发飞书）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
AMR="${ROOT}/ai-morning-report"
INSTRUCTIONS="${ROOT}/agent-instructions-ai-morning-report.txt"
LOBE_URL="${LOBEHUB_URL:-http://127.0.0.1:3010/chat?session=inbox}"

echo "==> 生成 6 段定时任务 prompt（LobeHub 对话展示版）"
python3 "${AMR}/build-scheduled-tasks.py"

echo ""
echo "==> 本地 LobeHub 配置（3 步）"
echo ""
echo "1) 打开 LobeHub → 新建助手「AI情报早报」"
echo "   ${LOBE_URL}"
echo ""
echo "2) 系统指令：已复制 agent-instructions-ai-morning-report.txt 到剪贴板，粘贴到助手设置"
echo ""
echo "3) 模型 gpt-5.5；开启联网搜索/网页浏览（若有）"
echo ""
echo "试跑：在本助手对话里粘贴并发送："
echo "   ${AMR}/scheduled-tasks/merge-task.txt  全文"
echo "   （或先跑 collect → intl → … → merge，同一话题内）"
echo ""
echo "每日 08:00："
echo "  - 云端 LobeHub：在 Agent 任务页建 6 个定时任务（正文见 scheduled-tasks/）"
echo "  - 本地 Mac：  crontab 添加 → bash ${ROOT}/run-lobehub-daily-report.sh"
echo ""

if command -v pbcopy >/dev/null 2>&1 && [[ -f "$INSTRUCTIONS" ]]; then
  pbcopy < "$INSTRUCTIONS"
  echo "✓ 系统指令已复制到剪贴板"
fi

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "${AMR}/scheduled-tasks/merge-task.txt"
  echo "✓ 合稿任务 prompt 已复制到剪贴板（可立即粘贴试跑）"
fi

open "$LOBE_URL" 2>/dev/null || true
