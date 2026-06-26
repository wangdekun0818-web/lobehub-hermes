#!/usr/bin/env bash
# 启动 LobeHub 早报投递 HTTP API
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
AMR="${ROOT}/ai-morning-report"
ENV_FILE="${HOME}/.hermes/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

export LOBEHUB_DELIVER_API_HOST="${LOBEHUB_DELIVER_API_HOST:-127.0.0.1}"
export LOBEHUB_DELIVER_API_PORT="${LOBEHUB_DELIVER_API_PORT:-8765}"
export LOBEHUB_BASE_URL="${LOBEHUB_BASE_URL:-http://127.0.0.1:3010}"
export LOBEHUB_SESSION_ID="${LOBEHUB_SESSION_ID:-inbox}"
export LOBEHUB_TOPIC_ID="${LOBEHUB_TOPIC_ID:-NHODLDqg}"
export PATH="${HOME}/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:${PATH}"
export AGENT_BROWSER_PROFILE="${AGENT_BROWSER_PROFILE:-${HOME}/.hermes/lobehub-browser-profile}"
mkdir -p "${AGENT_BROWSER_PROFILE}"

echo "==> LobeHub Deliver API"
echo "    http://${LOBEHUB_DELIVER_API_HOST}:${LOBEHUB_DELIVER_API_PORT}"
echo "    topic: ${LOBEHUB_BASE_URL}/chat?session=${LOBEHUB_SESSION_ID}&topic=${LOBEHUB_TOPIC_ID}"
echo ""
exec python3 "${AMR}/lobehub-deliver-api.py"
