#!/usr/bin/env bash
# 修复 gpt-5-nano / gpt-5-mini 白名单报错
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "=============================================="
echo " 修复 gpt-5-nano / gpt-5-mini 白名单报错"
echo "=============================================="
echo ""
echo "原因：LobeHub 内置默认模型是 gpt-5-nano，重置后会回退到它，"
echo "      而你的 API Key 白名单只有 gpt-5.4 / gpt-5.5 等。"
echo ""
echo "【步骤 1】应用服务端配置（屏蔽 nano/mini）"
bash "$ROOT/apply-aicoming-profile.sh" full
echo ""
echo "【步骤 2】浏览器操作（必做，LobeHub 已知 bug）"
echo "  1. 打开 http://127.0.0.1:3010/chat?session=inbox"
echo "  2. 看顶部模型名 — 若是 gpt-5-nano 或 gpt-5-mini："
echo "     点击它 → 选「GPT-5.4 (AIComing)」"
echo "  3. 再发消息测试"
echo ""
echo "若仍不行：设置 → 数据存储 → 立即重置 → 重复步骤 2"
echo ""
open "http://127.0.0.1:3010/chat?session=inbox" 2>/dev/null || true
