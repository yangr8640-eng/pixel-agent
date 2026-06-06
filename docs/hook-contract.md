# Pixel Agent Hook Contract

Pixel Agent uses Codex command hooks as a status bridge. The hook script reads
Codex hook JSON from stdin and appends one sanitized JSON line to:

`~/Library/Application Support/PixelAgent/events.jsonl`

Stored fields:

- `timestamp`
- `hookEventName`
- `sessionId`
- `turnId`
- `toolName`
- `source`

The script intentionally drops `prompt`, `tool_input`, `last_assistant_message`,
and any other content-bearing fields. `Stop` and `SubagentStop` emit
`{"continue":true}` to stdout so lifecycle events that expect JSON output remain
valid no-op hooks.
