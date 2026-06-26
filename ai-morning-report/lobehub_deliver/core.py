"""Deliver morning report markdown into a LobeHub chat topic."""

from __future__ import annotations

import json
import os
import random
import shutil
import string
import subprocess
import time
from datetime import datetime
from pathlib import Path
from typing import Any

DEFAULT_BASE = os.getenv("LOBEHUB_BASE_URL", "http://127.0.0.1:3010").rstrip("/")
DEFAULT_SESSION = os.getenv("LOBEHUB_SESSION_ID", "inbox")
DEFAULT_TOPIC = os.getenv("LOBEHUB_TOPIC_ID", "NHODLDqg")
DEFAULT_MODEL = os.getenv("LOBEHUB_DELIVER_MODEL", "gpt-5.4")
DEFAULT_PROVIDER = os.getenv("LOBEHUB_DELIVER_PROVIDER", "openai")
BROWSER_SESSION = os.getenv("LOBEHUB_BROWSER_SESSION", "lobehub-deliver")
BROWSER_PROFILE = os.getenv(
    "AGENT_BROWSER_PROFILE",
    str(Path.home() / ".hermes" / "lobehub-browser-profile"),
)
BROWSER_TIMEOUT = int(os.getenv("LOBEHUB_BROWSER_TIMEOUT", "120"))


def _memory_dir() -> Path:
    override = os.getenv("AI_MORNING_REPORT_MEMORY_DIR", "").strip()
    if override:
        return Path(override).expanduser().resolve()
    return Path.home() / ".hermes" / "workspace" / "ai-morning-report" / "memory"


def _report_path(date_str: str) -> Path:
    return _memory_dir() / f"{date_str}.md"


def _gen_id(length: int = 8) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(random.choice(alphabet) for _ in range(length))


def _chat_url(session_id: str, topic_id: str) -> str:
    return f"{DEFAULT_BASE}/chat?session={session_id}&topic={topic_id}"


def _build_indexeddb_js(
    *,
    session_id: str,
    topic_id: str,
    topic_title: str,
    user_text: str,
    report_text: str,
    model: str,
    provider: str,
) -> str:
    now = int(time.time() * 1000)
    user_msg_id = _gen_id()
    asst_msg_id = _gen_id()
    payload = {
        "sessionId": session_id,
        "topicId": topic_id,
        "topicTitle": topic_title,
        "userText": user_text,
        "reportText": report_text,
        "model": model,
        "provider": provider,
        "now": now,
        "userMsgId": user_msg_id,
        "asstMsgId": asst_msg_id,
    }
    data = json.dumps(payload, ensure_ascii=False)
    return f"""(() => {{
  const p = {data};
  return new Promise((resolve, reject) => {{
    const req = indexedDB.open('LOBE_CHAT_DB');
    req.onerror = () => reject('indexedDB open failed');
    req.onsuccess = () => {{
      const db = req.result;
      const topic = {{
        id: p.topicId,
        title: p.topicTitle,
        favorite: 0,
        sessionId: p.sessionId,
        createdAt: p.now,
        updatedAt: p.now,
      }};
      const userMsg = {{
        id: p.userMsgId,
        role: 'user',
        content: p.userText,
        files: [],
        sessionId: p.sessionId,
        topicId: p.topicId,
        createdAt: p.now,
        updatedAt: p.now,
      }};
      const asstMsg = {{
        id: p.asstMsgId,
        role: 'assistant',
        content: p.reportText,
        fromModel: p.model,
        fromProvider: p.provider,
        parentId: p.userMsgId,
        sessionId: p.sessionId,
        topicId: p.topicId,
        createdAt: p.now + 1,
        updatedAt: p.now + 1,
      }};
      const tx = db.transaction(['messages', 'topics'], 'readwrite');
      tx.objectStore('topics').put(topic);
      tx.objectStore('messages').put(userMsg);
      tx.objectStore('messages').put(asstMsg);
      tx.oncomplete = () => {{
        resolve(JSON.stringify({{ ok: true, topicId: p.topicId, userMsgId: p.userMsgId, asstMsgId: p.asstMsgId }}));
      }};
      tx.onerror = () => reject('indexedDB write failed');
    }};
  }});
}})()"""


def _agent_browser_bin() -> str:
    override = os.getenv("AGENT_BROWSER_BIN", "").strip()
    if override:
        return override
    for candidate in (
        Path.home() / ".npm-global/bin/agent-browser",
        Path("/opt/homebrew/bin/agent-browser"),
        Path("/usr/local/bin/agent-browser"),
    ):
        if candidate.is_file():
            return str(candidate)
    found = shutil.which("agent-browser")
    if found:
        return found
    raise FileNotFoundError(
        "agent-browser not found; npm i -g agent-browser or set AGENT_BROWSER_BIN"
    )


def _browser_env() -> dict[str, str]:
    env = os.environ.copy()
    env["PATH"] = f"{Path.home() / '.npm-global' / 'bin'}:/opt/homebrew/bin:/usr/local/bin:{env.get('PATH', '')}"
    if BROWSER_PROFILE:
        env["AGENT_BROWSER_PROFILE"] = BROWSER_PROFILE
    return env


def _agent_browser(*args: str, timeout: int | None = None) -> str:
    cmd = [_agent_browser_bin(), "--session-name", BROWSER_SESSION, *args]
    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        check=False,
        timeout=timeout or BROWSER_TIMEOUT,
        env=_browser_env(),
    )
    if proc.returncode != 0:
        raise RuntimeError(f"agent-browser {' '.join(args)}:\n{proc.stderr or proc.stdout}")
    return proc.stdout.strip()


def _reset_browser_session() -> None:
    """Best-effort cleanup before an agent-browser deliver run."""
    try:
        subprocess.run(
            [_agent_browser_bin(), "close", "--all"],
            capture_output=True,
            text=True,
            check=False,
            timeout=15,
            env=_browser_env(),
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    Path(BROWSER_PROFILE).expanduser().mkdir(parents=True, exist_ok=True)


def _deliver_via_playwright(url: str, js: str, *, reload: bool) -> str:
    from playwright.sync_api import sync_playwright

    profile = Path(BROWSER_PROFILE).expanduser()
    profile.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as playwright:
        context = playwright.chromium.launch_persistent_context(
            user_data_dir=str(profile),
            headless=True,
            viewport={"width": 1280, "height": 900},
        )
        try:
            page = context.pages[0] if context.pages else context.new_page()
            page.goto(url, wait_until="networkidle", timeout=90_000)
            page.wait_for_timeout(1500)
            result_raw = page.evaluate(js)
            if reload:
                page.reload(wait_until="networkidle", timeout=90_000)
                page.wait_for_timeout(1000)
        finally:
            context.close()

    if isinstance(result_raw, str):
        return result_raw
    return json.dumps(result_raw, ensure_ascii=False)


def deliver(
    *,
    content: str,
    session_id: str = DEFAULT_SESSION,
    topic_id: str = DEFAULT_TOPIC,
    topic_title: str | None = None,
    user_text: str | None = None,
    model: str = DEFAULT_MODEL,
    provider: str = DEFAULT_PROVIDER,
    reload: bool = True,
) -> dict[str, Any]:
    if not content.strip():
        raise ValueError("content is empty")

    title = topic_title or f"AI 情报日报"
    prompt = user_text or "请发布今日 AI 情报日报。"
    url = _chat_url(session_id, topic_id)
    js = _build_indexeddb_js(
        session_id=session_id,
        topic_id=topic_id,
        topic_title=title,
        user_text=prompt,
        report_text=content,
        model=model,
        provider=provider,
    )

    backend = os.getenv("LOBEHUB_DELIVER_BACKEND", "playwright").strip().lower()

    if backend == "agent-browser":
        _reset_browser_session()
        _agent_browser("open", url)
        _agent_browser("wait", "--load", "networkidle", timeout=90)
        time.sleep(1.5)
        result_raw = _agent_browser("eval", js)
        if reload:
            _agent_browser("eval", "location.reload()")
            time.sleep(1)
    else:
        result_raw = _deliver_via_playwright(url, js, reload=reload)

    try:
        result = json.loads(result_raw)
    except json.JSONDecodeError:
        result = {"ok": True, "raw": result_raw}

    return {
        "ok": bool(result.get("ok", True)),
        "backend": backend if backend == "agent-browser" else "indexeddb+playwright",
        "url": url,
        "session_id": session_id,
        "topic_id": topic_id,
        "topic_title": title,
        "content_chars": len(content),
        "inject": result,
    }


def deliver_report(
    date_str: str | None = None,
    *,
    report_path: Path | None = None,
    session_id: str = DEFAULT_SESSION,
    topic_id: str = DEFAULT_TOPIC,
    user_text: str | None = None,
    **kwargs: Any,
) -> dict[str, Any]:
    if date_str is None:
        date_str = datetime.now().astimezone().strftime("%Y-%m-%d")
    path = report_path or _report_path(date_str)
    if not path.is_file():
        raise FileNotFoundError(f"Report not found: {path}")

    content = path.read_text(encoding="utf-8")
    title = f"AI 情报日报 {date_str}"
    prompt = user_text or f"请发布今日 AI 情报日报（{date_str}）。"
    result = deliver(
        content=content,
        session_id=session_id,
        topic_id=topic_id,
        topic_title=title,
        user_text=prompt,
        **kwargs,
    )
    result["date"] = date_str
    result["report_path"] = str(path)
    return result
