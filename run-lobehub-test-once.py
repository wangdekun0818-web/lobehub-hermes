#!/usr/bin/env python3
"""Paste morning-report test prompt into LobeHub and wait for INTL_TEST_OK."""
import json
import subprocess
import sys
import time
from pathlib import Path

SESSION = "lobehub-run"
PROMPT_FILE = Path(__file__).resolve().parent / ".lobehub-test-prompt.txt"
OUT_FILE = Path(__file__).resolve().parent / "tmp-lobehub-run-result.txt"


def ab(*args: str) -> str:
    r = subprocess.run(
        ["agent-browser", "--session-name", SESSION, *args],
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        raise RuntimeError(f"agent-browser {' '.join(args)} failed:\n{r.stderr or r.stdout}")
    return r.stdout


def main() -> int:
    prompt = PROMPT_FILE.read_text(encoding="utf-8").strip()
    ab("open", "http://127.0.0.1:3010/chat?session=inbox")
    ab("wait", "--load", "networkidle")
    time.sleep(2)

    snap = ab("snapshot", "-i")
    input_ref = None
    for line in snap.splitlines():
        if "contenteditable" in line and "[ref=" in line:
            input_ref = "@" + line.split("[ref=")[1].split("]")[0]
            break
    if not input_ref:
        for line in snap.splitlines():
            if "输入聊天内容" in line and "[ref=" in line:
                input_ref = "@" + line.split("[ref=")[1].split("]")[0]
                break
    if not input_ref:
        input_ref = "@e40"  # LobeHub contenteditable fallback

    ab("click", input_ref)
    ab("keyboard", "inserttext", prompt)
    time.sleep(0.5)
    ab("press", "Enter")

    deadline = time.time() + 120
    body = ""
    while time.time() < deadline:
        time.sleep(4)
        body = ab("get", "text", "body")
        if "INTL_TEST_OK" in body:
            break
        if "model_not_allowed" in body or "白名单" in body:
            raise RuntimeError("model not allowed — switch to gpt-5.4/gpt-5.5 in UI")

    OUT_FILE.write_text(body, encoding="utf-8")
    ok = "INTL_TEST_OK" in body
    # extract assistant block after last user prompt marker
    marker = "不要追问，直接写稿"
    idx = body.rfind(marker)
    excerpt = body[idx:] if idx >= 0 else body[-4000:]
    print(json.dumps({"ok": ok, "excerpt_len": len(excerpt), "out": str(OUT_FILE)}, ensure_ascii=False))
    if ok:
        start = excerpt.find("国际动态")
        if start < 0:
            start = excerpt.find("发生了什么")
        print("\n--- AI 回复摘录 ---\n")
        print(excerpt[start : start + 2500] if start >= 0 else excerpt[-2500:])
        print("\nINTL_TEST_OK")
    else:
        print("TIMEOUT: no INTL_TEST_OK in 120s", file=sys.stderr)
        print(body[-1500:], file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
