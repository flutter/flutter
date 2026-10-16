---
name: dart-log-failure-parser
description: Parse failures from Dart and Flutter test logs.
---

# Dart Log Failure Parser

## Workflow

### 1. Analyze Raw Log Output

Analyze the raw log output for failure details. Do not skim the output; check the entire log. **The description of findings should include specific details for the failures (e.g., unformatted files, specific test names), not just the top-level command that failed.**

### 2. Look for Failure Patterns

#### Pattern A: Error Blocks (e.g., Linux Analyze)
Search for blocks starting with `╡ERROR #`.
Example:
```
╔═╡ERROR #1╞════════════════════════════════════════════════════════════════════
║ Command: bin/cache/dart-sdk/bin/dart --enable-asserts /b/s/w/ir/x/w/flutter/dev/bots/analyze_snippet_code.dart --verbose
║ Command exited with exit code 255 but expected zero exit code.
║ Working directory: /b/s/w/ir/x/w/flutter
╚═══════════════════════════════════════════════════════════════════════════════
```

#### Pattern B: Task Result JSON
Search for "Task result:" followed by a JSON object.
Example:
```json
Task result:
{
  "success": false,
  "reason": "Task failed: PathNotFoundException: Cannot open file..."
}
```

#### Pattern C: Failing Tests List
For general Dart tests, look for a list at the end of the log starting with "Failing tests:".
Example:
```
Failing tests:
  test/general.shard/cache_test.dart: FontSubset artifacts for all platforms on arm64 hosts
  test/general.shard/cache_test.dart: FontSubset artifacts on arm64 linux
```

#### Pattern D: Build Failures
For build failures (e.g., engine tests failing at compile time), look for the following indicators in the logs or API summaries:
- Lines starting with `FAILED:` (indicates a Ninja target failed).
- Compiler error messages (e.g., `error:`, `fatal error:`).
- Linker error messages (e.g., `undefined reference to`).
- Summary messages in the check-runs API output like `1 build failed: [<build_name>]`.
