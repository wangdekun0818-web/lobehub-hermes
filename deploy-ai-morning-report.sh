#!/usr/bin/env bash
# 将 OpenClaw 早报规范部署到 LobeHub 云端 Agent「拾光人」
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_URL="https://app.lobehub.com/agent/agt_aA2TWAEo3grI/tpc_6bMGaY4IUCTX"
PROFILE_URL="https://app.lobehub.com/agent/agt_aA2TWAEo3grI/profile"
PROMPT_FILE="$DIR/ai-morning-report-prompt.txt"
INSTRUCTIONS_FILE="$DIR/agent-instructions-ai-morning-report.txt"
TRIGGER_FILE="$DIR/scheduled-task-trigger.txt"
TODAY="$(TZ=Asia/Shanghai date +%Y-%m-%d)"

# 合并定时任务完整 prompt（触发语 + 正文规范）
TASK_PROMPT="$(cat "$TRIGGER_FILE" | sed "s/YYYY-MM-DD/$TODAY/g")
$(cat "$PROMPT_FILE")"

echo "=============================================="
echo " LobeHub 云端 · AI 早报部署"
echo " Agent: 拾光人 (agt_aA2TWAEo3grI)"
echo "=============================================="
echo ""
echo "【步骤 1】打开 Agent 页面（需已登录 app.lobehub.com）"
echo "  $AGENT_URL"
echo ""
echo "【步骤 2】打开助理档案页，粘贴系统指令"
echo "  $PROFILE_URL"
echo "  文件：agent-instructions-ai-morning-report.txt"
echo ""
echo "【步骤 3】Agent 设置 → 模型"
echo "  选择 gpt-5.5（AIComing 直连或 Hermes 8642 代理）"
echo ""
echo "【步骤 4】Agent 设置 → 工具 / 插件"
echo "  启用「联网搜索」「网页浏览」"
echo ""
echo "【步骤 5】左侧面板 → 定时任务 → 添加定时任务"
echo "  · 名称：AI 情报日报"
echo "  · 频率：每天"
echo "  · 时间：08:30"
echo "  · 时区：Asia/Shanghai"
echo "  · 任务内容：见下方「完整任务 Prompt」（已复制到剪贴板）"
echo "  · 最大执行次数：留空（不限）"
echo ""
echo "【步骤 6】保存后，点「立即运行」测试一次"
echo ""
echo "----------------------------------------------"
echo "文件位置："
echo "  系统指令  → $INSTRUCTIONS_FILE"
echo "  完整规范  → $PROMPT_FILE"
echo "  今日任务  → 已合并写入剪贴板"
echo "----------------------------------------------"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$TASK_PROMPT" | pbcopy
  echo "✓ 完整定时任务 Prompt 已复制到剪贴板（含今日日期 $TODAY）"
fi

if command -v pbcopy >/dev/null 2>&1; then
  echo ""
  read -r -p "是否复制「系统指令」到剪贴板？(y/N) " ans
  if [[ "${ans,,}" == "y" ]]; then
    pbcopy < "$INSTRUCTIONS_FILE"
    echo "✓ 系统指令已复制"
  fi
fi

open "$AGENT_URL" 2>/dev/null || true
