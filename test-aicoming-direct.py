#!/usr/bin/env python3
"""Test AIComing gpt-5.5 directly from ~/.hermes/.env"""
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

env = Path.home() / ".hermes" / ".env"
text = env.read_text()
key = re.search(r"^AICOMING_API_KEY=(.+)$", text, re.M)
base = re.search(r"^AICOMING_BASE_URL=(.+)$", text, re.M)
if not key or not base:
    sys.exit("missing AICOMING vars")

payload = json.dumps(
    {
        "model": "gpt-5.5",
        "messages": [{"role": "user", "content": "只回复ok"}],
        "max_tokens": 10,
    }
).encode()

req = urllib.request.Request(
    f"{base.group(1).strip().rstrip('/')}/chat/completions",
    data=payload,
    headers={
        "Authorization": f"Bearer {key.group(1).strip()}",
        "Content-Type": "application/json",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        body = resp.read().decode()
        print("HTTP", resp.status)
        print(body[:500])
except urllib.error.HTTPError as e:
    print("HTTP", e.code, e.read().decode()[:500], file=sys.stderr)
    sys.exit(1)
