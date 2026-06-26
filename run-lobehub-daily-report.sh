#!/usr/bin/env python3
"""Run AI morning report in local LobeHub chat via agent-browser (display in conversation)."""
from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
AMR = ROOT / "ai-morning-report"
SESSION = "lobehub-morning"
LOBE_URL = "http://127.0.0.1:3010/chat?session=inbox"
STAGES = ["collect", "intl", "domestic", "tables", "insights", "merge"]
WAIT = {"collect": 180, "intl": 120, "domestic": 120, "tables": 120, "insights": 120, "merge": 180}


def ab(*args: str) -> str:
    r = subprocess.run(
        ["agent-browser", "--session-name", SESSION, *args],
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        raise RuntimeError(f"agent-browser {' '.join(args)}:\n{r.stderr or r.stdout}")
    return r.stdout


def send_prompt(text: str) -> None:
    ab("open", LOBE_URL)
    ab("wait", "--load", "networkidle")
    time.sleep(2)
    ab("eval", f"""(() => {{
      const el = document.querySelector('[contenteditable=\"true\"]');
      if (!el) return 'no-input';
      el.focus();
      el.innerText = {text!r};
      el.dispatchEvent(new InputEvent('input', {{ bubbles: true }}));
      return 'ok';
    }})()""")
    ab("press", "Enter")


def wait_done(marker: str, seconds: int) -> bool:
    deadline = time.time() + seconds
    while time.time() < deadline:
        time.sleep(8)
        body = ab("get", "text", "body")
        if marker in body:
            return True
    return False


def main() -> int:
    only = sys.argv[1:] if len(sys.argv) > 1 else STAGES
    print("LobeHub 早报流水线 → 对话展示（不发飞书）")
    print("请先在 LobeHub 选中助手「AI情报早报」，并保持本话题用于串联分段\n")

    markers = {
        "collect": "MATERIAL_OK",
        "intl": "INTL_OK",
        "domestic": "DOMESTIC_OK",
        "tables": "TABLES_OK",
        "insights": "INSIGHTS_OK",
        "merge": "MORNING_REPORT_OK",
    }

    for stage in only:
        task_file = AMR / "scheduled-tasks" / f"{stage}-task.txt"
        if not task_file.exists():
            print(f"skip missing {task_file}", file=sys.stderr)
            continue
        prompt = task_file.read_text(encoding="utf-8").strip()
        print(f"→ 发送 {stage} …")
        send_prompt(prompt)
        ok = wait_done(markers.get(stage, "OK"), WAIT.get(stage, 120))
        print(f"  {'✓' if ok else '⚠ 超时'} {stage} ({markers.get(stage)})")

    url = ab("get", "url").strip()
    print(f"\n完成。请在浏览器查看对话：{url}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
