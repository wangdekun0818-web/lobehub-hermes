#!/usr/bin/env bash
# 在 LobeHub 指定话题触发 6.4 风格单次全量早报（对话展示）
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
AMR="${ROOT}/ai-morning-report"
PROMPT="${AMR}/prompts/stage-single-64-lobehub.txt"
LOBE_URL="${LOBEHUB_TOPIC_URL:-http://127.0.0.1:3010/chat?session=inbox&topic=NHODLDqg}"
TODAY="$(TZ=Asia/Shanghai date +%Y-%m-%d)"

# 替换日期占位
TMP="$(mktemp)"
sed "s/YYYY-MM-DD/${TODAY}/g; s/2026-06-26/${TODAY}/g" "$PROMPT" > "$TMP"

echo "==> LobeHub 6.4 早报 → ${LOBE_URL}"
python3 << PY
import subprocess, time, sys
from pathlib import Path

prompt = Path("${TMP}").read_text(encoding="utf-8").strip()
session = "lobehub-morning-64"
url = "${LOBE_URL}"

def ab(*args):
    r = subprocess.run(["agent-browser", "--session-name", session, *args], capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError(r.stderr or r.stdout)
    return r.stdout

ab("open", url)
ab("wait", "--load", "networkidle")
time.sleep(2)
snap = ab("snapshot", "-i")
ref = None
for line in snap.splitlines():
    if "contenteditable" in line and "[ref=" in line:
        ref = "@" + line.split("[ref=")[1].split("]")[0]
        break
if not ref:
    ref = "@e39"
ab("click", ref)
ab("keyboard", "inserttext", prompt)
time.sleep(0.5)
ab("press", "Enter")
print("✓ 已发送 6.4 早报 prompt，等待生成…")
print(f"  话题: {url}")
PY

rm -f "$TMP"
echo ""
echo "生成完成后回复末尾应含 MORNING_REPORT_OK"
echo "若已有 Hermes 成稿，可投递："
echo "  python3 ${AMR}/lobehub-deliver.py ${TODAY}"
