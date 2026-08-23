---
trigger: always_on
---

Before declaring a task done:
1. Address all lints, warnings, and errors introduced or present in the modified
   files. Run `dart analyze --fatal-infos <files>` or use the MCP server.
2. Run `dart format` on the modified files. Run `dart format <files>` or use the
   MCP server.
