#!/usr/bin/env bash
# app.lobehub.com 配置 AIComing GPT-5.5（需已登录 LobeHub 账号）
set -euo pipefail

HERMES_ENV="${HOME}/.hermes/.env"
[[ -f "$HERMES_ENV" ]] || { echo "缺少 $HERMES_ENV"; exit 1; }
# shellcheck disable=SC1090
source "$HERMES_ENV"

BASE="${AICOMING_BASE_URL:-https://api.aicoming.top/v1}"

echo "=============================================="
echo " LobeHub 云端 · AIComing GPT-5.5 配置"
echo "=============================================="
echo ""
echo "1. 浏览器打开（需先登录 app.lobehub.com）："
echo "   https://app.lobehub.com/settings/provider/openai"
echo ""
echo "2. 在 OpenAI 提供商里填写："
echo "   · 启用 OpenAI：开"
echo "   · API Key：见下方（已复制到剪贴板，macOS）"
echo "   · API 代理 / Proxy URL：${BASE}"
echo "   · 客户端请求模式：关（AIComing 是公网 API，不需要）"
echo ""
echo "3. 自定义模型列表添加：gpt-5.5"
echo "   （或在模型列表里 +gpt-5.5）"
echo ""
echo "4. 聊天页顶部选模型：gpt-5.5（不要选「智能」等带积分的）"
echo ""
echo "----------------------------------------------"
echo "API Key（前8后4）：${AICOMING_API_KEY:0:8}...${AICOMING_API_KEY: -4}"
echo "Proxy URL：${BASE}"
echo "模型 ID：gpt-5.5"
echo "----------------------------------------------"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$AICOMING_API_KEY" | pbcopy
  echo "✓ API Key 已复制到剪贴板"
fi

open "https://app.lobehub.com/settings/provider/openai" 2>/dev/null || true
