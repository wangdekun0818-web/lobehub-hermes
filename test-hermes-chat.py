#!/usr/bin/env python3
"""Quick end-to-end test: LobeHub proxy path -> Hermes -> model reply."""
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

hermes_env = Path.home() / ".hermes" / ".env"
if not hermes_env.exists():
    sys.exit("missing ~/.hermes/.env")

for line in hermes_env.read_text().splitlines():
    if line.startswith("API_SERVER_KEY="):
        key = line.split("=", 1)[1].strip()
        break
else:
    sys.exit("missing API_SERVER_KEY")

payload = json.dumps(
    {
        "model": "gpt-5.5",
        "messages": [{"role": "user", "content": "只回复一个词：已接通"}],
        "max_tokens": 20,
    }
).encode()

req = urllib.request.Request(
    "http://127.0.0.1:8642/v1/chat/completions",
    data=payload,
    headers={
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = json.loads(resp.read().decode())
    content = data["choices"][0]["message"]["content"]
    print("Hermes chat OK:", content[:200])
except urllib.error.HTTPError as e:
    print("HTTP", e.code, e.read().decode()[:500], file=sys.stderr)
    sys.exit(1)
