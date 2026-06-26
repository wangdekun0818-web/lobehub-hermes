#!/usr/bin/env python3
"""Test direct AIComing gpt-5.5 via credentials in lobehub .env."""
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

env = Path(__file__).resolve().parent / ".env"
if not env.exists():
    sys.exit("run setup-from-hermes.sh first")

key = base = None
for line in env.read_text().splitlines():
    if line.startswith("OPENAI_API_KEY="):
        key = line.split("=", 1)[1].strip()
    elif line.startswith("OPENAI_PROXY_URL="):
        base = line.split("=", 1)[1].strip().rstrip("/")

if not key or not base:
    sys.exit("missing OPENAI_API_KEY or OPENAI_PROXY_URL in .env")

payload = json.dumps(
    {
        "model": "gpt-5.5",
        "messages": [{"role": "user", "content": "只回复：AIComing已接通"}],
        "max_tokens": 20,
    }
).encode()

req = urllib.request.Request(
    f"{base}/chat/completions",
    data=payload,
    headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=120) as resp:
        data = json.loads(resp.read().decode())
    print("AIComing OK:", data["choices"][0]["message"]["content"][:200])
except urllib.error.HTTPError as e:
    print("HTTP", e.code, e.read().decode()[:500], file=sys.stderr)
    sys.exit(1)
