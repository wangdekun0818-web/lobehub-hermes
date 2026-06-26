#!/usr/bin/env bash
# 创建 GitHub 仓库并推送（需先 gh auth login）
set -euo pipefail
cd "$(dirname "$0")"

GH="${GH_BIN:-/opt/homebrew/bin/gh}"

echo "==> 检查 GitHub 登录"
if ! "$GH" auth status >/dev/null 2>&1; then
  echo "请先登录 GitHub："
  echo "  $GH auth login -h github.com -p ssh -w"
  exit 1
fi

echo "==> 创建远程仓库（若已存在则跳过）"
if ! "$GH" repo view wangdekun0818-web/lobehub-hermes >/dev/null 2>&1; then
  "$GH" repo create lobehub-hermes \
    --public \
    --source=. \
    --remote=origin \
    --description "LobeHub AI morning report pipeline and deliver HTTP API"
else
  git remote remove origin 2>/dev/null || true
  git remote add origin git@github.com:wangdekun0818-web/lobehub-hermes.git
fi

BRANCH="$(git branch --show-current)"
echo "==> 推送分支: ${BRANCH}"
git push -u origin "${BRANCH}"

echo ""
echo "✓ 已推送: https://github.com/wangdekun0818-web/lobehub-hermes"
