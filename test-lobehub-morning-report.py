#!/usr/bin/env python3
"""在本地 LobeHub 发一条早报试跑消息（2A 国际，附 Hermes 素材）。"""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parent
ENV = ROOT / ".env"
TASK = ROOT / "ai-morning-report/scheduled-tasks/intl-task.txt"
MATERIAL = Path.home() / ".hermes/workspace/ai-morning-report/memory/2026-06-17-素材.md"
BASE = "http://127.0.0.1:3010"


def load_env() -> dict[str, str]:
    out: dict[str, str] = {}
    for line in ENV.read_text().splitlines():
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip()
    return out


def main() -> None:
    env = load_env()
    api_key = env.get("OPENAI_API_KEY", "")
    proxy = env.get("OPENAI_PROXY_URL", "https://api.aicoming.top/v1").rstrip("/")
    if not api_key:
        sys.exit("缺少 OPENAI_API_KEY（见 lobehub-hermes/.env）")

    today = datetime.now(ZoneInfo("Asia/Shanghai")).strftime("%Y-%m-%d")
    task_body = TASK.read_text(encoding="utf-8") if TASK.exists() else ""
    material = MATERIAL.read_text(encoding="utf-8") if MATERIAL.exists() else ""

    # 缩短试跑：只写 1 条国际动态（完整六段），验证 LobeHub 通路
    user_prompt = f"""【LobeHub 早报试跑 · 单条测试】日期 {today}

请基于下方素材，只输出 **1 条** 国际动态（完整六段：发生了什么/来龙去脉/怎么理解/产业影响/你可以怎么做/来源），末尾回复 `INTL_TEST_OK`。

---素材开始---
{material.strip() or "（无素材，写一条「未检索到」示范）"}
---素材结束---

规范参考（不必全文复述）：
{task_body[:1200]}
"""

    payload = {
        "messages": [{"role": "user", "content": user_prompt}],
        "model": "gpt-5.5",
        "provider": "openai",
        "stream": False,
        "apiKey": api_key,
        "endpoint": proxy,
    }

    req = urllib.request.Request(
        f"{BASE}/webapi/chat/openai",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            raw = resp.read().decode()
    except urllib.error.HTTPError as e:
        print("HTTP", e.code, e.read().decode()[:800], file=sys.stderr)
        sys.exit(1)

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        print(raw[:2000])
        return

    if isinstance(data, dict) and data.get("errorType"):
        print(json.dumps(data, ensure_ascii=False, indent=2)[:2000], file=sys.stderr)
        sys.exit(1)

    # LobeChat 返回格式因版本而异
    text = ""
    if isinstance(data, str):
        text = data
    elif "text" in data:
        text = data["text"]
    elif "content" in data:
        text = data["content"]
    elif "choices" in data:
        text = data["choices"][0]["message"]["content"]
    else:
        text = json.dumps(data, ensure_ascii=False)[:2000]

    print("=== LobeHub 试跑回复 ===")
    print(text[:4000])
    if "INTL_TEST_OK" in text or "来源" in text:
        print("\n✓ 试跑完成（请在 http://127.0.0.1:3010/chat 查看会话记录）")


if __name__ == "__main__":
    main()
