#!/usr/bin/env bash
# app.lobehub.com 对话模式 → Hermes (8642) → AIComing gpt-5.5
set -euo pipefail

HERMES_ENV="${HOME}/.hermes/.env"
[[ -f "$HERMES_ENV" ]] || { echo "缺少 $HERMES_ENV"; exit 1; }
# shellcheck disable=SC1090
source "$HERMES_ENV"

echo "=============================================="
echo " LobeHub 云端 · Hermes → AIComing 配置"
echo "=============================================="
echo ""
echo "Hermes 网关: http://127.0.0.1:8642/v1"
if curl -fsS --max-time 2 http://127.0.0.1:8642/health >/dev/null 2>&1; then
  echo "  状态: ✅ 运行中"
else
  echo "  状态: ❌ 未运行 — 先执行: bash ~/.hermes/start-hermes-gateway.sh"
fi
echo ""
echo "1. 打开: https://app.lobehub.com/settings/provider/openai"
echo ""
echo "2. OpenAI 提供商（二选一）："
echo ""
echo "   【推荐 A】经 Hermes（对话模式 + 客户端请求）："
echo "   · API Key：Hermes API_SERVER_KEY（已复制）"
echo "   · API 代理：http://127.0.0.1:8642/v1"
echo "   · 客户端请求模式：开"
echo ""
echo "   【备选 B】直连 AIComing（不要写 aicoming.top，会 404）："
echo "   · API Key：AICOMING_API_KEY"
echo "   · API 代理：https://api.aicoming.top/v1"
echo "   · 客户端请求模式：关"
echo ""
echo "   · 点「检查」→ 应成功"
echo ""
echo "3. 启用模型 gpt-5.5"
echo "4. 聊天：对话模式 + gpt-5.5（不要 Pro）"
echo ""
echo "链路: LobeHub 浏览器 → Hermes:8642 → AIComing gpt-5.5"
echo ""
echo "502 upstream provider error 修复:"
echo "  · custom_providers / model 须设 api_mode: chat_completions（AIComing 无 /v1/responses）"
echo "  · run_agent.py 已跳过对显式 api_mode 的 gpt-5.x 自动升级"
echo ""
echo "注意: 须在 Chrome/Safari 等本机浏览器里用 app.lobehub.com；"
echo "      Cursor 内置浏览器无法访问 localhost，连通性检查可能误报失败。"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$API_SERVER_KEY" | pbcopy
  echo "✓ API_SERVER_KEY 已复制到剪贴板"
fi

open "https://app.lobehub.com/settings/provider/openai" 2>/dev/null || true
