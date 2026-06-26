#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# Colima / 非 Desktop 环境
export DOCKER_HOST="${DOCKER_HOST:-unix://${HOME}/.colima/default/docker.sock}"
# 避免 docker-credential-desktop 缺失导致 pull 失败
export DOCKER_CONFIG="${DOCKER_CONFIG:-/tmp/docker-nocred}"
mkdir -p "$DOCKER_CONFIG"
if [[ ! -f "$DOCKER_CONFIG/config.json" ]]; then
  printf '%s\n' '{"auths":{}}' > "$DOCKER_CONFIG/config.json"
fi

bash "$ROOT/setup-from-hermes.sh"

if ! curl -sf http://127.0.0.1:8642/health >/dev/null; then
  echo "Hermes 网关未运行，正在启动…"
  hermes gateway start || hermes gateway restart
  sleep 2
fi

if ! curl -sf http://127.0.0.1:8642/health >/dev/null; then
  echo "错误: Hermes 8642 仍不可用，请先执行: hermes gateway restart" >&2
  exit 1
fi

docker-compose up -d

echo ""
echo "LobeHub 已启动: http://127.0.0.1:3010"
echo "链路: LobeHub → Hermes (8642) → AIComing gpt-5.5"
echo "模型: 选 GPT-5.5 (Hermes/AIComing)"
echo "停止: docker-compose -f $ROOT/docker-compose.yml down"
