#!/usr/bin/env bash
set -euo pipefail

HERMES_ENV="${HOME}/.hermes/.env"
OUT_ENV="$(cd "$(dirname "$0")" && pwd)/.env"

if [[ ! -f "$HERMES_ENV" ]]; then
  echo "未找到 Hermes 配置: $HERMES_ENV" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$HERMES_ENV"

if [[ -z "${API_SERVER_KEY:-}" ]]; then
  echo "Hermes .env 中缺少 API_SERVER_KEY" >&2
  exit 1
fi

if [[ -z "${AICOMING_API_KEY:-}" ]]; then
  echo "Hermes .env 中缺少 AICOMING_API_KEY（Hermes 调用 GPT-5.5 所需）" >&2
  exit 1
fi

cat > "$OUT_ENV" <<EOF
# LobeHub → Hermes 网关（8642）；Hermes 内部用 AIComing gpt-5.5
OPENAI_API_KEY=${API_SERVER_KEY}
EOF

echo "已写入 $OUT_ENV"
echo "  LobeHub 密钥 = Hermes API_SERVER_KEY（连本地网关）"
echo "  实际模型 = gpt-5.5（Hermes 使用你的 AIComing 密钥）"
