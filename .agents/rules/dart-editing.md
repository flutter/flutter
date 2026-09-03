---
trigger: always_on
---

Before declaring a task done:
1. Address all lints, warnings, and errors introduced or present in the modified
   files. Run `dart analyze --fatal-infos <files>` or use the MCP server.
2. Run `dart format` on the modified files. Run `dart format <files>` or use the
   MCP server.

## Layer Dependency Rules

* `material` (`package:flutter/material.dart` or `packages/flutter/lib/src/material/`) can only be used in `material` code and tests (`packages/flutter/lib/src/material/` and `packages/flutter/test/material/`).
* `cupertino` (`package:flutter/cupertino.dart` or `packages/flutter/lib/src/cupertino/`) can only be used in `cupertino` code and tests (`packages/flutter/lib/src/cupertino/` and `packages/flutter/test/cupertino/`).
