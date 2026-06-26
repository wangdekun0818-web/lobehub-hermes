#!/usr/bin/env bash
# 本地 LobeHub (3010) → 直连 AIComing gpt-5.5（与 LibreChat 相同后端）
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
HERMES_ENV="${HOME}/.hermes/.env"
OUT_ENV="$ROOT/.env"
PROFILES="$ROOT/aicoming-model-profiles.sh"
PROFILE="${2:-full}"
AICOMING_KEY="${1:-}"

# shellcheck disable=SC1091
source "$PROFILES"
MODEL_LIST="$(aicoming_model_list_for_profile "$PROFILE")"
DEFAULT_AGENT="$(aicoming_default_agent_for_profile "$PROFILE")"
SYSTEM_AGENT="$(aicoming_system_agent_for_profile "$PROFILE")"

if [[ -z "$AICOMING_KEY" && -f "$HERMES_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$HERMES_ENV"
  AICOMING_KEY="${AICOMING_API_KEY:-}"
fi
: "${AICOMING_KEY:?用法: setup-aicoming-local.sh <AICOMING_API_KEY> 或在 ~/.hermes/.env 配置 AICOMING_API_KEY}"
BASE="${AICOMING_BASE_URL:-https://api.aicoming.top/v1}"

cat > "$OUT_ENV" <<EOF
# LobeHub 本地直连 AIComing（与 LibreChat custom endpoint 相同）
ENABLED_OPENAI=1
OPENAI_API_KEY=${AICOMING_KEY}
OPENAI_PROXY_URL=${BASE}
OPENAI_MODEL_LIST=${MODEL_LIST}
DEFAULT_AGENT_CONFIG=${DEFAULT_AGENT}
SYSTEM_AGENT=${SYSTEM_AGENT}
AICOMING_MODEL_PROFILE=${PROFILE}
EOF

echo "已写入 $OUT_ENV"
echo "  API Key: ${AICOMING_KEY:0:8}...${AICOMING_KEY: -4}"
echo "  Proxy URL: ${BASE}"
echo "  模型路由: ${PROFILE}（$(aicoming_model_count_for_profile "$PROFILE") 个模型）"
echo "  默认模型: ${DEFAULT_AGENT}"
echo "  系统代理: ${SYSTEM_AGENT}"
echo ""

export DOCKER_HOST="${DOCKER_HOST:-unix://${HOME}/.colima/default/docker.sock}"
export DOCKER_CONFIG="${DOCKER_CONFIG:-/tmp/docker-nocred}"
mkdir -p "$DOCKER_CONFIG"
if [[ ! -f "$DOCKER_CONFIG/config.json" ]]; then
  printf '%s\n' '{"auths":{}}' > "$DOCKER_CONFIG/config.json"
fi

cd "$ROOT"
docker-compose up -d --force-recreate

echo ""
echo "=============================================="
echo " 本地 LobeHub · AIComing GPT-5.5"
echo "=============================================="
echo ""
echo "服务: http://127.0.0.1:3010"
echo "聊天: http://127.0.0.1:3010/chat?session=inbox"
echo ""
echo "【服务端已注入】Docker 环境变量已指向 AIComing，一般无需再配 UI。"
echo ""
echo "若需在 UI 手动确认或覆盖，打开："
echo "  http://127.0.0.1:3010/settings/provider/openai"
echo ""
echo "  · 启用 OpenAI：开"
echo "  · API Key：AICOMING_API_KEY（见 ~/.hermes/.env）"
echo "  · API 代理：https://api.aicoming.top/v1  （必须是 api. 前缀，勿填 aicoming.top）"
echo "  · 客户端请求模式：关（开会导致浏览器直连被 Cloudflare 403）"
echo "  · 模型列表：profile=${PROFILE}（GPT-5.5 / GPT-5.4 等，见 aicoming-model-profiles.sh）"
echo ""
echo "  聊天页选 GPT-5.5 或 GPT-5.4；回滚: bash $ROOT/apply-aicoming-profile.sh rollback"
echo ""
echo "备选（经 Hermes 8642）：bash $ROOT/setup-from-hermes.sh && bash $ROOT/start-lobehub-hermes.sh"

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$AICOMING_KEY" | pbcopy
  echo "✓ API Key 已复制到剪贴板"
fi

open "http://127.0.0.1:3010/settings?active=llm" 2>/dev/null || true
