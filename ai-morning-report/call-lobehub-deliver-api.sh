#!/usr/bin/env bash
# Hermes 成稿后调用 LobeHub 投递 API
set -euo pipefail
TODAY="${1:-$(TZ=Asia/Shanghai date +%Y-%m-%d)}"
API="${LOBEHUB_DELIVER_API_URL:-http://127.0.0.1:8765}"
KEY="${LOBEHUB_DELIVER_API_KEY:-}"

payload=$(python3 - <<PY
import json
print(json.dumps({"date": "${TODAY}"}, ensure_ascii=False))
PY
)

auth=()
if [[ -n "$KEY" ]]; then
  auth=(-H "Authorization: Bearer ${KEY}")
fi

curl -fsS -X POST "${API}/v1/deliver/morning-report" \
  -H "Content-Type: application/json" \
  "${auth[@]}" \
  -d "$payload"
