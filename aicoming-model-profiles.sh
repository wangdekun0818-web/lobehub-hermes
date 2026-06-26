#!/usr/bin/env bash
# AIComing 模型路由配置（LobeHub OPENAI_MODEL_LIST）
# 用法: source aicoming-model-profiles.sh && aicoming_model_list_for_profile full

# LobeHub 内置 OpenAI 模型（不在 AIComing 白名单）— 必须显式屏蔽
# 否则重置后「随便聊聊」会回退到 gpt-5-nano / gpt-5-mini
# shellcheck disable=SC2034
AICOMING_MODEL_LIST_BLOCK="-gpt-5-nano,-gpt-5-mini,-gpt-5,-gpt-5-chat-latest,-gpt-5-pro,-gpt-5-codex,-gpt-5.1,-gpt-5.1-chat-latest,-gpt-5.1-codex,-gpt-5.1-codex-mini,-gpt-5.2-pro,-gpt-5.2-chat-latest,-gpt-4o,-gpt-4o-mini,-gpt-4o-2024-11-20,-gpt-4-turbo,-gpt-4,-gpt-3.5-turbo,-o1,-o1-mini,-o1-preview,-o3-mini,-o4-mini"

# 白名单模型（gpt-5.4 放第一位，作为默认推荐）
# shellcheck disable=SC2034
AICOMING_MODEL_LIST_FULL="-all,${AICOMING_MODEL_LIST_BLOCK},+gpt-5.4=GPT-5.4 (AIComing),+gpt-5.5=GPT-5.5 (AIComing),+gpt-5.4-mini=GPT-5.4 Mini,+gpt-5.2=GPT-5.2,+gpt-5.3-codex=GPT-5.3 Codex,+claude-opus-4-8=Claude Opus 4.8,+claude-opus-4-7=Claude Opus 4.7,+claude-sonnet-4-6=Claude Sonnet 4.6,+claude-haiku-4-5-20251001=Claude Haiku 4.5,+gemini-3.1-pro-preview=Gemini 3.1 Pro,+gemini-3.5-flash=Gemini 3.5 Flash,+gemini-2.5-pro=Gemini 2.5 Pro,+gemini-2.5-flash=Gemini 2.5 Flash,+deepseek-v4-pro=DeepSeek V4 Pro,+deepseek-v4-flash=DeepSeek V4 Flash,+kimi-k2.6=Kimi K2.6,+kimi-k2.5=Kimi K2.5,+glm-5-turbo=GLM-5 Turbo,+glm-5.1=GLM-5.1,+qwen3.6-27b=Qwen 3.6 27B,+minimax-m2.5=MiniMax M2.5,+hunyuan-turbo=混元 Turbo"

# shellcheck disable=SC2034
AICOMING_MODEL_LIST_ROLLBACK="-all,${AICOMING_MODEL_LIST_BLOCK},+gpt-5.4=GPT-5.4 (AIComing),+gpt-5.5=GPT-5.5 (AIComing),+gpt-5.4-mini=GPT-5.4 Mini,+gpt-5.2=GPT-5.2,+claude-sonnet-4-6=Claude Sonnet 4.6,+claude-haiku-4-5-20251001=Claude Haiku 4.5,+gemini-3.5-flash=Gemini 3.5 Flash,+deepseek-v4-flash=DeepSeek V4 Flash"

# shellcheck disable=SC2034
AICOMING_DEFAULT_AGENT_FULL="model=gpt-5.4;provider=openai"
# shellcheck disable=SC2034
AICOMING_DEFAULT_AGENT_ROLLBACK="model=gpt-5.4;provider=openai"
# shellcheck disable=SC2034
AICOMING_SYSTEM_AGENT_FULL="default=openai/gpt-5.4"
# shellcheck disable=SC2034
AICOMING_SYSTEM_AGENT_ROLLBACK="default=openai/gpt-5.4"

aicoming_model_list_for_profile() {
  local profile="${1:-full}"
  case "$profile" in
    full) printf '%s' "$AICOMING_MODEL_LIST_FULL" ;;
    rollback) printf '%s' "$AICOMING_MODEL_LIST_ROLLBACK" ;;
    *)
      echo "未知 profile: $profile（可用: full, rollback）" >&2
      return 1
      ;;
  esac
}

aicoming_default_agent_for_profile() {
  local profile="${1:-full}"
  case "$profile" in
    full) printf '%s' "$AICOMING_DEFAULT_AGENT_FULL" ;;
    rollback) printf '%s' "$AICOMING_DEFAULT_AGENT_ROLLBACK" ;;
    *)
      echo "未知 profile: $profile（可用: full, rollback）" >&2
      return 1
      ;;
  esac
}

aicoming_system_agent_for_profile() {
  local profile="${1:-full}"
  case "$profile" in
    full) printf '%s' "$AICOMING_SYSTEM_AGENT_FULL" ;;
    rollback) printf '%s' "$AICOMING_SYSTEM_AGENT_ROLLBACK" ;;
    *)
      echo "未知 profile: $profile（可用: full, rollback）" >&2
      return 1
      ;;
  esac
}

aicoming_model_count_for_profile() {
  local list
  list="$(aicoming_model_list_for_profile "${1:-full}")"
  awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /^\+/) c++} END{print c+0}' <<<"$list"
}
