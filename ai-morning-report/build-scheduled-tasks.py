#!/usr/bin/env python3
"""Build LobeHub scheduled-task prompt files from stage prompts + constants."""

from __future__ import annotations

import sys
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parent
PROMPTS_LOCAL = ROOT / "prompts"
PROMPTS_HERMES = Path.home() / "Projects/librechat-hermes/ai-morning-report/prompts"
OUT = ROOT / "scheduled-tasks"

STAGES = {
    "collect": ("stage1-collect.txt", "06:00"),
    "intl": ("stage2-intl.txt", "07:00"),
    "domestic": ("stage2-domestic.txt", "07:02"),
    "tables": ("stage2-tables.txt", "07:04"),
    "insights": ("stage2-insights.txt", "07:06"),
    "merge": ("stage3-merge-lobehub.txt", "08:00"),
}

SHARED = PROMPTS_HERMES / "shared-spec.txt"
if not SHARED.exists():
    SHARED = PROMPTS_LOCAL / "shared-spec.txt"
TRIGGER = """执行今日 AI 情报日报 · {stage_name}。日期：{date}（Asia/Shanghai）。

严格按下方规范执行，不得省略章节、不得降级为简版 bullet。
**成稿只输出在本 LobeHub 对话**，不投递飞书。禁止反问、禁止要求用户上传文件。
LobeHub 无文件工具时，用 `---素材槽位N---` / `---分段:国际---` 等在回复中分段记录，供后续任务 read。

"""


def load(stage: str) -> str:
    fname, _ = STAGES[stage]
    path = PROMPTS_LOCAL / fname
    if not path.exists():
        path = PROMPTS_HERMES / fname
    if not path.exists():
        raise FileNotFoundError(path)
    text = path.read_text(encoding="utf-8")
    if "@include shared-spec" in text:
        text = text.replace("@include shared-spec", SHARED.read_text(encoding="utf-8"))
    return text.replace("memory/", "---LOBEHUB_MEMORY_PREFIX---/")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    today = datetime.now(ZoneInfo("Asia/Shanghai")).strftime("%Y-%m-%d")
    names = {
        "collect": "AI早报-1采集",
        "intl": "AI早报-2A国际",
        "domestic": "AI早报-2B国内",
        "tables": "AI早报-2C表格",
        "insights": "AI早报-2D洞察",
        "merge": "AI早报-3合稿",
    }
    for stage, (fname, time) in STAGES.items():
        body = load(stage).replace("YYYY-MM-DD", today).replace("{date}", today)
        body = body.replace("---LOBEHUB_MEMORY_PREFIX---", f"memory/{today}")
        header = TRIGGER.format(stage_name=names[stage], date=today)
        out_path = OUT / f"{stage}-task.txt"
        out_path.write_text(header + body + "\n", encoding="utf-8")
        print(f"  {names[stage]} @ {time} → {out_path.name}")
    print(f"Generated {len(STAGES)} task files in {OUT}")


if __name__ == "__main__":
    main()
