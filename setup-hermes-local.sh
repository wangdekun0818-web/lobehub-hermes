#!/usr/bin/env bash
# 本地 LobeHub (3010) → Hermes 8642 → AIComing gpt-5.5
# 解决浏览器直连 aicoming.top 被 Cloudflare 403 的问题
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
HERMES_ENV="${HOME}/.hermes/.env"
OUT_ENV="$ROOT/.env"

[[ -f "$HERMES_ENV" ]] || { echo "缺少 $HERMES_ENV"; exit 1; }
# shellcheck disable=SC1090
source "$HERMES_ENV"

: "${API_SERVER_KEY:?请在 ~/.hermes/.env 配置 API_SERVER_KEY}"

# 确保 Hermes 网关在跑
if ! curl -fsS --max-time 2 http://127.0.0.1:8642/health >/dev/null 2>&1; then
  echo "==> 启动 Hermes 网关"
  bash "${HOME}/.hermes/start-hermes-gateway.sh"
fi
curl -fsS --max-time 5 http://127.0.0.1:8642/health >/dev/null

cat > "$OUT_ENV" <<EOF
# LobeHub → 本机 Hermes 8642（容器内走 host.docker.internal）
ENABLED_OPENAI=1
OPENAI_API_KEY=${API_SERVER_KEY}
OPENAI_PROXY_URL=http://host.docker.internal:8642/v1
OPENAI_MODEL_LIST=-all,+gpt-5.5=GPT-5.5 (Hermes)
EOF

echo "已写入 $OUT_ENV"
echo "  服务端代理: http://host.docker.internal:8642/v1"
echo "  浏览器 UI 代理: http://127.0.0.1:8642/v1"
echo "  API Key: Hermes API_SERVER_KEY（非 AIComing sk-）"
echo ""

export DOCKER_HOST="${DOCKER_HOST:-unix://${HOME}/.colima/default/docker.sock}"
export DOCKER_CONFIG="${DOCKER_CONFIG:-/tmp/docker-nocreds}"
mkdir -p "$DOCKER_CONFIG"
[[ -f "$DOCKER_CONFIG/config.json" ]] || printf '%s\n' '{"auths":{}}' > "$DOCKER_CONFIG/config.json"

cd "$ROOT"
docker-compose up -d --force-recreate

echo ""
echo "=============================================="
echo " LobeHub · 经 Hermes 本地网关（避免 CF 403）"
echo "=============================================="
echo ""
echo "【UI 必须这样配】http://127.0.0.1:3010/settings?active=llm → OpenAI"
echo "  · API Key：Hermes API_SERVER_KEY（见 ~/.hermes/.env，不是 sk- 开头）"
echo "  · API 代理：http://127.0.0.1:8642/v1"
echo "  · 客户端请求模式：开（浏览器可访问 localhost）"
echo "  · 勿填 aicoming.top / api.aicoming.top（会 403）"
echo ""
echo "复制 Hermes Key："
echo "  grep API_SERVER_KEY ~/.hermes/.env"
echo ""

if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$API_SERVER_KEY" | pbcopy
  echo "✓ API_SERVER_KEY 已复制到剪贴板"
fi

open "http://127.0.0.1:3010/settings?active=llm" 2>/dev/null || true
