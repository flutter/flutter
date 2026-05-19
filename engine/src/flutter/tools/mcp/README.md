# Engine MCP

This is an MCP server to help Gemini CLI work on the engine.

It runs over stdout. The CWD is assumed to be `//engine/src/flutter`. That
matches the CWD when executing Gemini CLI from that directory where it is set
up.

## Testing

The server can be run an queried manually with the following example queries.
Automated testing is a bit lacking until we can get it integrated with the
dart workspace.

```json
{ "jsonrpc": "2.0", "id": 1, "method": "tools/list" }
```

```json
{ "jsonrpc": "2.0", "id": 2, "method": "tools/call", "params": { "name": "engine_build", "arguments": { "config": "host_profile_arm64", "target": "//flutter/tools/licenses_cpp"} } }
```

You can test it through gemini too with the following:

```sh
cd //engine/src/flutter
gemini -p "what impellerc targets are there for host_debug_unopt_arm64?"
```
