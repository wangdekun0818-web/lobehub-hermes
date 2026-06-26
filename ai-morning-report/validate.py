"""Validate AI morning report markdown against spec constants."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import List

from constants import SECTION_COUNTS, TABLE_TEMPLATES, WORD_LIMITS


@dataclass
class ValidationResult:
    ok: bool
    errors: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)

    def summary(self) -> str:
        lines = []
        if self.ok:
            lines.append("VALIDATION: OK")
        else:
            lines.append("VALIDATION: FAIL")
            for e in self.errors:
                lines.append(f"  - {e}")
        for w in self.warnings:
            lines.append(f"  ⚠ {w}")
        return "\n".join(lines)


def _section(text: str, heading: str) -> str:
    pattern = rf"##\s*{re.escape(heading)}[^\n]*\n(.*?)(?=\n##\s|\Z)"
    m = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
    return m.group(1) if m else ""


def _count_numbered_items(section: str) -> int:
    return len(re.findall(r"^\*\*\d+\.", section, re.MULTILINE))


def _count_table_rows(section: str, min_cols: int = 2) -> int:
    rows = 0
    in_table = False
    for line in section.splitlines():
        if line.strip().startswith("|") and "---" not in line:
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) >= min_cols and not all(set(c) <= {"-", " "} for c in cells):
                if in_table:
                    rows += 1
                else:
                    in_table = True
                    continue
        elif in_table and not line.strip().startswith("|"):
            break
    return rows


def _chinese_chars(s: str) -> int:
    return len(re.findall(r"[\u4e00-\u9fff]", s))


def _items_from_section(section: str) -> List[str]:
    parts = re.split(r"(?=^\*\*\d+\.)", section, flags=re.MULTILINE)
    return [p.strip() for p in parts if p.strip().startswith("**")]


def validate_report(text: str, *, strict_words: bool = False) -> ValidationResult:
    result = ValidationResult(ok=True)

    intl = _section(text, "🌍 国际动态")
    domestic = _section(text, "🇨🇳 国内动态")
    capital = _section(text, "💰 资本风向")
    tools = _section(text, "🛠️ 开发者工具")
    events = _section(text, "📅 活动推荐")
    insights = _section(text, "🎯 机会洞察")
    data_board = _section(text, "📊 今日数据板")
    concept = _section(text, "📖 今日一个概念")

    checks = [
        ("国际动态", _count_numbered_items(intl), SECTION_COUNTS["intl"]),
        ("国内动态", _count_numbered_items(domestic), SECTION_COUNTS["domestic"]),
        ("资本风向表格", _count_table_rows(capital), SECTION_COUNTS["capital"]),
        ("开发者工具表格", _count_table_rows(tools), SECTION_COUNTS["tools"]),
        ("活动推荐表格", _count_table_rows(events), SECTION_COUNTS["events"]),
        ("机会洞察", _count_numbered_items(insights), SECTION_COUNTS["insights"]),
        ("今日数据板", _count_table_rows(data_board), SECTION_COUNTS["data_board"]),
    ]

    for label, got, need in checks:
        if got < need:
            result.ok = False
            result.errors.append(f"缺 {label}：需要 {need}，实际 {got}")

    if not concept.strip():
        result.ok = False
        result.errors.append("缺「今日一个概念」章节")
    else:
        cc = _chinese_chars(concept)
        if cc < WORD_LIMITS["concept_min"]:
            result.warnings.append(f"今日一个概念偏短：{cc} 字（建议 ≥{WORD_LIMITS['concept_min']}）")

    for label, section, min_words in (
        ("国际动态条目", intl, WORD_LIMITS["intl_item_min"]),
        ("国内动态条目", domestic, WORD_LIMITS["domestic_item_min"]),
        ("机会洞察条目", insights, WORD_LIMITS["insight_item_min"]),
    ):
        for item in _items_from_section(section):
            wc = _chinese_chars(item)
            if strict_words and wc < min_words:
                result.ok = False
                result.errors.append(f"{label}字数不足：{wc} < {min_words}")
            elif wc < min_words:
                result.warnings.append(f"{label}可能偏短：{wc} 字")

    for key in ("capital", "tools", "events"):
        tpl = TABLE_TEMPLATES[key]
        sec = _section(text, tpl["title"])
        for follow in tpl.get("followups", ()):
            if follow not in sec:
                result.warnings.append(f"{tpl['title']} 缺少「{follow}」小节")

    if "读数说明" not in data_board:
        result.warnings.append("今日数据板缺少「读数说明」")

    return result


if __name__ == "__main__":
    import argparse
    import sys
    from pathlib import Path

    p = argparse.ArgumentParser(description="Validate AI morning report markdown")
    p.add_argument("file", type=Path)
    p.add_argument("--strict-words", action="store_true")
    args = p.parse_args()
    content = args.file.read_text(encoding="utf-8")
    vr = validate_report(content, strict_words=args.strict_words)
    print(vr.summary())
    sys.exit(0 if vr.ok else 1)
