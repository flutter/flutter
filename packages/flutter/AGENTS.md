# Flutter Framework Rules

## Layer Dependency Rules

* `material` (`package:flutter/material.dart` or `src/material/`) can only be used in `material` code and tests (`packages/flutter/lib/src/material/` and `packages/flutter/test/material/`).
* `cupertino` (`package:flutter/cupertino.dart` or `src/cupertino/`) can only be used in `cupertino` code and tests (`packages/flutter/lib/src/cupertino/` and `packages/flutter/test/cupertino/`).
