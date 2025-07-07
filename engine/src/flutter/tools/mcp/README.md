# Engine MCP

This is an MCP server to help Gemini CLI work on the engine.

It runs over stdout.  The CWD is assumed to be `//engine/src/flutter`.

## Testing

The server can be run an queried manually with the following example queries.

```json
{ "jsonrpc": "2.0", "id": 1, "method": "tools/list" }
```

```json
{ "jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": { "name": "engine_build", "arguments": { "config": "host_profile_arm64", "target": "//flutter/tools/licenses_cpp"} } }
```
