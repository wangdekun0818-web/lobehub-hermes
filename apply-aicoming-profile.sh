#!/usr/bin/env bash
# 切换 LobeHub AIComing 模型路由并重建容器
# 用法: bash apply-aicoming-profile.sh [full|rollback]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROFILE="${1:-full}"
ENV_FILE="$ROOT/.env"
PROFILES="$ROOT/aicoming-model-profiles.sh"

# shellcheck disable=SC1091
source "$PROFILES"
MODEL_LIST="$(aicoming_model_list_for_profile "$PROFILE")"
DEFAULT_AGENT="$(aicoming_default_agent_for_profile "$PROFILE")"
SYSTEM_AGENT="$(aicoming_system_agent_for_profile "$PROFILE")"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "缺少 $ENV_FILE，请先运行 setup-aicoming-local.sh" >&2
  exit 1
fi

# 保留现有密钥与代理，只更新模型列表与 profile 标记
python3 - "$ENV_FILE" "$PROFILE" "$MODEL_LIST" "$DEFAULT_AGENT" "$SYSTEM_AGENT" <<'PY'
import re, sys
path, profile, model_list, default_agent, system_agent = sys.argv[1:6]
text = open(path, encoding="utf-8").read()
text = re.sub(r"^OPENAI_MODEL_LIST=.*$", f"OPENAI_MODEL_LIST={model_list}", text, flags=re.M)
if re.search(r"^DEFAULT_AGENT_CONFIG=", text, flags=re.M):
    text = re.sub(r"^DEFAULT_AGENT_CONFIG=.*$", f"DEFAULT_AGENT_CONFIG={default_agent}", text, flags=re.M)
else:
    text = text.rstrip() + f"\nDEFAULT_AGENT_CONFIG={default_agent}\n"
if re.search(r"^SYSTEM_AGENT=", text, flags=re.M):
    text = re.sub(r"^SYSTEM_AGENT=.*$", f"SYSTEM_AGENT={system_agent}", text, flags=re.M)
else:
    text = text.rstrip() + f"\nSYSTEM_AGENT={system_agent}\n"
if re.search(r"^AICOMING_MODEL_PROFILE=", text, flags=re.M):
    text = re.sub(r"^AICOMING_MODEL_PROFILE=.*$", f"AICOMING_MODEL_PROFILE={profile}", text, flags=re.M)
else:
    text = text.rstrip() + f"\nAICOMING_MODEL_PROFILE={profile}\n"
open(path, "w", encoding="utf-8").write(text)
PY

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
echo " LobeHub 模型路由已切换: $PROFILE"
echo "=============================================="
echo "  服务: http://127.0.0.1:3010"
echo "  默认模型: ${DEFAULT_AGENT}"
echo "  系统代理: ${SYSTEM_AGENT}"
echo ""
echo "  重置后若仍报 gpt-5-nano/mini："
echo "    聊天页顶部点模型 → 选 GPT-5.4 (AIComing) → 再发消息"
echo ""
echo "  切回全量: bash $ROOT/apply-aicoming-profile.sh full"
echo "  回滚档:   bash $ROOT/apply-aicoming-profile.sh rollback"
