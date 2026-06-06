#!/usr/bin/env python3
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


JSON_STDOUT_EVENTS = {"Stop", "SubagentStop"}


def string_or_none(value):
    if value is None:
        return None
    return str(value)


def main():
    raw_input = sys.stdin.read()
    try:
        payload = json.loads(raw_input) if raw_input.strip() else {}
    except json.JSONDecodeError:
        payload = {}

    event_name = (
        payload.get("hook_event_name")
        or payload.get("hookEventName")
        or os.environ.get("CODEX_HOOK_EVENT_NAME")
        or "Unknown"
    )

    # Deliberately omit prompt, tool input, and assistant text fields.
    event = {
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "hookEventName": str(event_name),
        "sessionId": string_or_none(payload.get("session_id") or payload.get("sessionId")),
        "turnId": string_or_none(payload.get("turn_id") or payload.get("turnId")),
        "toolName": string_or_none(payload.get("tool_name") or payload.get("toolName")),
        "source": "codex-hook",
    }

    app_support = Path.home() / "Library" / "Application Support" / "PixelAgent"
    app_support.mkdir(parents=True, exist_ok=True)
    with (app_support / "events.jsonl").open("a", encoding="utf-8") as event_log:
        event_log.write(json.dumps(event, separators=(",", ":")) + "\n")

    if str(event_name) in JSON_STDOUT_EVENTS:
        sys.stdout.write(json.dumps({"continue": True}, separators=(",", ":")))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
