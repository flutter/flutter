---
name: flutter-pr-failure-collector
description: Collect all the failures on a Flutter PR directly from LUCI, without utilizing a browser session.
---

# Flutter PR Failure Collector

## Prerequisites

- `gh` (GitHub CLI) must be installed and authenticated. If not in your PATH, check common locations like `/opt/homebrew/bin/gh`.
- Access to `curl` or similar tool to fetch raw logs from LUCI.

## Workflow

### 1. Find Failing Checks

You can use the `gh` CLI if it's installed and authenticated, or use direct HTTP requests to the GitHub API as a fallback.

#### Option A: Using `gh` CLI (Preferred)
Run the following command to list checks:
```bash
gh pr checks <PR_NUMBER>
```
Or if `gh` is not in PATH, use full path (e.g., `/opt/homebrew/bin/gh`).

#### Option B: Using GitHub API via HTTP
If `gh` is not available, you can use `read_url_content` or a similar method to interact with the public GitHub API:
1. **Find the PR SHA**:
   Make an HTTP request to: `https://api.github.com/repos/flutter/flutter/pulls/<PR_NUMBER>`
   Extract the `head.sha` field from the JSON response.
2. **List Check Runs**:
   Make an HTTP request to: `https://api.github.com/repos/flutter/flutter/commits/<PR_SHA>/check-runs`
   Parse the JSON response (handling pagination if necessary) to identify all checks that have failed (i.e., where `conclusion` is `failure`).

Identify all checks that have failed.
```
Identify all checks that have failed.

### 2. Retrieve Failure Logs

For each failing check:
1.  **Find the Log URL**:
    - Look for the target URL or link associated with the check.
    - The `flutter-dashboard` link typically appears as "View more details on flutter-dashboard" at the bottom of the check view on GitHub.
    - Alternatively, you can reconstruct the link to the LUCI page based on the name of the failing check and the build number if available.
      Example LUCI URL structure: `https://ci.chromium.org/ui/p/flutter/builders/try/<Builder Name>/<Build Number>/overview`
2.  **Fetch Raw Logs**:
    - Failure logs are typically found by clicking the `stdout` link on the LUCI page.
    - **CRITICAL**: You must use the raw log URL to avoid HTML formatting and truncated output. **Do NOT rely solely on the check summary in the GitHub API, as it may be truncated or lack full context.**
    - **TIP**: You can often access the raw logs directly by appending `?format=raw` to the log URL.
      Example: `https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/<Build ID>/+/u/<Step Name>/stdout?format=raw`
    - **NOTE**: Step names can be very specific and hard to guess.
        - For builders using the **`flutter_drone`** recipe (check `.ci.yaml`), the step name usually follows the pattern: `run test.dart for <shard> shard and subshard <subshard>`. In the raw log URL, spaces are replaced by underscores. If `subshard` is not specified, it defaults to `None`. Example: For `Linux analyze` (which has `shard: analyze` and no `subshard`), the URL step name becomes `run_test.dart_for_analyze_shard_and_subshard_None`.
        - To find the exact test and task names, check the configuration files in the engine directory:
          1. Look up the builder in `engine/src/flutter/.ci.yaml` to find its `config_name` property.
          2. Locate the corresponding JSON file in `engine/src/flutter/ci/builders/<config_name>.json`.
          3. Read the JSON file to find the `tests` array and the specific `tasks` listed within them.
        - In `builder.py` and related recipes, the step name for a task is typically the task name specified in that JSON configuration, often prefixed with `test: ` (e.g., `test: run suite chrome-dart2wasm-wimp-ui`). Note that if the test name already starts with `test: ` in the JSON file, the recipe might still add the prefix again, resulting in step names like `test: test: Check formatting` (and in URL: `test:_test:_Check_formatting`). In the URL, spaces are replaced by underscores.
        - In `tester.py`, the step name follows the pattern: `Run <shard> tests` or `Run <shard> <subshard> tests`. In the URL, spaces are replaced by underscores.
        - If `read_url_content` fails with 404 on guessed step names, you may need to find the step name from the LUCI overview page or other sources.
    - Use `read_url_content` or a similar method to fetch the content of the raw log URL.

### 3. Parse Failures

Analyze the raw log output for failure details. Do not skim the output; check the entire log. **The description of findings should include specific details for the failures (e.g., unformatted files, specific test names), not just the top-level command that failed.**

Look for the following patterns:

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

### 4. Document Findings

Create a summary of the failures. It is recommended to use a markdown table to report findings to the user.

The table should include:
- **Check Name**: The name of the failing bot/check.
- **Platform**: The platform the test was running on (e.g., Linux, Mac, arm64).
- **Failure Details**: A brief summary of the error or the failing tests.
- **Reproduction Command**: The command needed to reproduce the failure locally.
  - **Sanitize**: Remove builder-specific paths (e.g., `/b/s/w/ir/...`) and replace with generic paths or relative paths from the repository root.
  - **Scope**: If many tests in a file failed, provide a command that runs the entire file or a broader set of tests rather than listing a command for a single test with `--plain-name`.

