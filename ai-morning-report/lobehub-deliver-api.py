#!/usr/bin/env python3
"""HTTP API: deliver AI morning report into LobeHub chat page."""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

from lobehub_deliver.core import deliver, deliver_report  # noqa: E402

HOST = os.getenv("LOBEHUB_DELIVER_API_HOST", "127.0.0.1")
PORT = int(os.getenv("LOBEHUB_DELIVER_API_PORT", "8765"))
API_KEY = os.getenv("LOBEHUB_DELIVER_API_KEY", "").strip()


def _auth_ok(headers: dict[str, str]) -> bool:
    if not API_KEY:
        return True
    auth = headers.get("Authorization", "")
    if auth == f"Bearer {API_KEY}":
        return True
    return headers.get("X-Api-Key", "") == API_KEY


def _json_response(handler: BaseHTTPRequestHandler, status: int, payload: dict[str, Any]) -> None:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    handler.send_response(status)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


class Handler(BaseHTTPRequestHandler):
    server_version = "LobeHubDeliverAPI/1.0"

    def log_message(self, fmt: str, *args: Any) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path == "/health":
            _json_response(
                self,
                200,
                {
                    "ok": True,
                    "service": "lobehub-deliver-api",
                    "time": datetime.now().astimezone().isoformat(),
                },
            )
            return
        _json_response(self, 404, {"ok": False, "error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        headers = {k.lower(): v for k, v in self.headers.items()}
        if not _auth_ok(headers):
            _json_response(self, 401, {"ok": False, "error": "unauthorized"})
            return

        length = int(headers.get("content-length", "0") or "0")
        raw = self.rfile.read(length) if length else b"{}"
        try:
            body = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            _json_response(self, 400, {"ok": False, "error": "invalid json"})
            return

        try:
            if path == "/v1/deliver/morning-report":
                result = self._handle_morning_report(body)
                _json_response(self, 200, result)
                return
            if path == "/v1/deliver/message":
                result = self._handle_message(body)
                _json_response(self, 200, result)
                return
            _json_response(self, 404, {"ok": False, "error": "not found"})
        except FileNotFoundError as exc:
            _json_response(self, 404, {"ok": False, "error": str(exc)})
        except Exception as exc:  # noqa: BLE001
            _json_response(self, 500, {"ok": False, "error": str(exc)})

    def _handle_morning_report(self, body: dict[str, Any]) -> dict[str, Any]:
        date_str = body.get("date")
        if not date_str:
            date_str = datetime.now().astimezone().strftime("%Y-%m-%d")
        session_id = body.get("session_id") or os.getenv("LOBEHUB_SESSION_ID", "inbox")
        topic_id = body.get("topic_id") or os.getenv("LOBEHUB_TOPIC_ID", "NHODLDqg")
        user_text = body.get("user_text")
        report_path = body.get("report_path")

        if body.get("content"):
            result = deliver(
                content=str(body["content"]),
                session_id=session_id,
                topic_id=topic_id,
                topic_title=body.get("topic_title") or f"AI 情报日报 {date_str}",
                user_text=user_text,
                model=body.get("model") or os.getenv("LOBEHUB_DELIVER_MODEL", "gpt-5.4"),
                provider=body.get("provider") or os.getenv("LOBEHUB_DELIVER_PROVIDER", "openai"),
                reload=body.get("reload", True),
            )
            result["date"] = date_str
            return result

        return deliver_report(
            date_str,
            report_path=Path(report_path).expanduser() if report_path else None,
            session_id=session_id,
            topic_id=topic_id,
            user_text=user_text,
        )

    def _handle_message(self, body: dict[str, Any]) -> dict[str, Any]:
        content = str(body.get("content") or "").strip()
        if not content:
            raise ValueError("content is required")
        return deliver(
            content=content,
            session_id=body.get("session_id") or os.getenv("LOBEHUB_SESSION_ID", "inbox"),
            topic_id=body.get("topic_id") or os.getenv("LOBEHUB_TOPIC_ID", "NHODLDqg"),
            topic_title=body.get("topic_title") or "消息投递",
            user_text=body.get("user_text") or "请查看以下内容。",
            model=body.get("model") or os.getenv("LOBEHUB_DELIVER_MODEL", "gpt-5.4"),
            provider=body.get("provider") or os.getenv("LOBEHUB_DELIVER_PROVIDER", "openai"),
            reload=body.get("reload", True),
        )


def main() -> int:
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"LobeHub deliver API listening on http://{HOST}:{PORT}", flush=True)
    print("  GET  /health", flush=True)
    print("  POST /v1/deliver/morning-report", flush=True)
    print("  POST /v1/deliver/message", flush=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
