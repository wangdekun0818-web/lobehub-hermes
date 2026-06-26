"""AI 情报早报 · 权威规范常量（与 ~/.openclaw/cron 同步）。"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Tuple

TIMEZONE = "Asia/Shanghai"

# LobeHub UI 定时任务（Asia/Shanghai）；合稿发送 08:00
LOBEBUB_SCHEDULE = [
    {"name": "AI早报-1采集", "time": "06:00", "stage": "collect"},
    {"name": "AI早报-2A国际", "time": "07:00", "stage": "intl"},
    {"name": "AI早报-2B国内", "time": "07:02", "stage": "domestic"},
    {"name": "AI早报-2C表格", "time": "07:04", "stage": "tables"},
    {"name": "AI早报-2D洞察", "time": "07:06", "stage": "insights"},
    {"name": "AI早报-3合稿", "time": "08:00", "stage": "merge"},
]

SECTION_COUNTS: Dict[str, int] = {
    "intl": 10,
    "domestic": 10,
    "capital": 5,
    "tools": 8,
    "events": 8,
    "insights": 6,
    "data_board": 8,
    "concept": 1,
}

WORD_LIMITS: Dict[str, int] = {
    "intl_item_min": 220,
    "domestic_item_min": 220,
    "insight_item_min": 350,
    "track_judgment_min": 120,
    "tool_recommend_min": 120,
    "action_advice_min": 120,
    "table_highlight_min": 40,
    "concept_min": 150,
    "concept_max": 250,
}

TABLE_TEMPLATES: Dict[str, Dict] = {
    "capital": {
        "title": "💰 资本风向",
        "columns": ["公司/项目", "金额", "轮次", "投资方", "亮点", "来源"],
        "rows": 5,
    },
    "tools": {
        "title": "🛠️ 开发者工具",
        "columns": ["项目", "Star", "类型", "亮点", "来源"],
        "rows": 8,
    },
    "events": {
        "title": "📅 活动推荐",
        "columns": ["活动", "时间", "地点", "报名截止", "亮点", "来源"],
        "rows": 8,
    },
    "data_board": {
        "title": "📊 今日数据板",
        "columns": ["指标", "数据", "来源"],
        "rows": 8,
    },
}

@dataclass(frozen=True)
class SourceGroup:
    key: str
    title: str
    entries: Tuple[str, ...]


FIXED_SOURCES: Tuple[SourceGroup, ...] = (
    SourceGroup("A", "国际新闻 / 深度", (
        "TechCrunch AI: https://techcrunch.com/category/artificial-intelligence/",
        "VentureBeat AI: https://venturebeat.com/category/ai/",
        "The Verge AI: https://www.theverge.com/ai-artificial-intelligence",
        "MIT Technology Review AI: https://www.technologyreview.com/topic/artificial-intelligence/",
        "SemiAnalysis: https://www.semianalysis.com/",
        "Artificial Analysis: https://artificialanalysis.ai/",
    )),
    SourceGroup("B", "研究 / 模型 / 开源", (
        "Hugging Face Daily Papers: https://huggingface.co/papers",
        "GitHub Trending: https://github.com/trending",
        "OSS Insight AI: https://ossinsight.io/trending/ai",
        "Product Hunt AI: https://www.producthunt.com/topics/artificial-intelligence",
        "Hacker News: https://news.ycombinator.com/",
    )),
    SourceGroup("C", "X / Twitter（近 48h）", (
        "@OpenAI @AnthropicAI @GoogleDeepMind @nvidia @MetaAI @karpathy @ylecun @swyx @emollick @simonw @OpenClaw @cursor_ai @LangChainAI",
    )),
    SourceGroup("D", "YouTube（近 7 天）", (
        "AI Explained, Latent Space, Two Minute Papers, NVIDIA, Microsoft Research, Matthew Berman, Fireship",
    )),
    SourceGroup("E", "国内媒体", (
        "36氪 AI、量子位、机器之心、新智元、极客公园、晚点、甲子光年、InfoQ 中文、AI 科技评论",
    )),
    SourceGroup("F", "公众号", (
        "极客公园、DataWhale、量子位、机器之心、新智元、歸藏、刘小排、花叔、卡兹克、赛博禅心、Founder Park 等",
    )),
    SourceGroup("G", "国内内容平台", (
        "B站 / 知乎 / 小红书 AI 热度",
    )),
    SourceGroup("H", "融资 / 活动", (
        "IT桔子、Luma、Devpost",
    )),
)

SLOTS: Tuple[Tuple[int, str], ...] = (
    (1, "TechCrunch AI 或 VentureBeat AI"),
    (2, "The Verge AI 或 MIT Technology Review AI"),
    (3, "SemiAnalysis 或 Artificial Analysis"),
    (4, "GitHub Trending + OSS Insight AI"),
    (5, "Hugging Face papers 或 trending models"),
    (6, "Product Hunt AI 或 Hacker News"),
    (7, "X 固定账号近 48h"),
    (8, "YouTube 固定频道近 7 天"),
    (9, "量子位 或 机器之心"),
    (10, "36氪 或 晚点 LatePost"),
    (11, "极客公园 或 新智元"),
    (12, "甲子光年 或 InfoQ 中文"),
    (13, "公众号轮询（周一歸藏…周日 Founder Park）"),
    (14, "B站/知乎/小红书轮换"),
    (15, "Luma AI 活动"),
    (16, "Devpost AI hackathon"),
    (17, "IT桔子 AI 融资"),
    (18, "36氪融资 或 TechCrunch funding"),
)

MAX_SEARCHES_PER_RUN = 18
AGENT_NAME = "拾光人"
AGENT_ID = "agt_aA2TWAEo3grI"
