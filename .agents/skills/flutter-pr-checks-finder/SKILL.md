---
name: flutter-pr-checks-finder
description: Find failing checks on a Flutter PR and locate the corresponding LUCI log URLs.
---

# Flutter PR Checks Finder

## Prerequisites

- `gh` (GitHub CLI) must be installed and authenticated. If not in your PATH, check common locations like `/opt/homebrew/bin/gh` on macOS or `C:\Program Files\GitHub CLI\gh.exe` on Windows.
- Access to `curl` or similar tool to fetch raw logs from LUCI.

## Workflow

### 1. Find Failing Checks

You can use the `gh` CLI if it's installed and authenticated, or use direct HTTP requests to the GitHub API as a fallback.

#### Option A: Using `gh` CLI (Preferred)
Run the following command to list checks:
```bash
gh pr checks <PR_NUMBER>
```

#### Option B: Using GitHub API via HTTP
If `gh` is not available, you can use `read_url_content` or a similar method to interact with the public GitHub API:
1. **Find the PR SHA**:
   Make an HTTP request to: `https://api.github.com/repos/flutter/flutter/pulls/<PR_NUMBER>`
   Extract the `head.sha` field.
2. **List Check Runs**:
   Make an HTTP request to: `https://api.github.com/repos/flutter/flutter/commits/<PR_SHA>/check-runs`
   Parse the JSON response. **CRITICAL**: You must handle pagination to avoid missing failures! Check the `total_count` field. If it is greater than the number of items in the `check_runs` array (typically capped at 100 or what you set with `per_page`), make additional HTTP requests by appending `?per_page=100&page=<N>` to the URL for each subsequent page until all check runs are fetched. Identify all checks that have failed (i.e., where `conclusion` is `failure`).

Identify all checks that have failed.

### 2. Retrieve Failure Logs

For each failing check:
1.  **Find the Log URL**:
    - Look for the target URL or link associated with the check.
    - The `flutter-dashboard` link typically appears as "View more details on flutter-dashboard" at the bottom of the check view on GitHub.
    - Alternatively, you can reconstruct the link to the LUCI page based on the name of the failing check and the build number if available.
      Example LUCI URL structure: `https://ci.chromium.org/ui/p/flutter/builders/try/<Builder Name>/<Build Number>/overview`
2.  **Build Raw Log URL**:
    - **Manual**: Reconstruct the raw log URL by appending `?format=raw` to the log URL or by following the pattern: `https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/<Build ID>/+/u/<Step Name>/stdout?format=raw`

3.  **Fetch Raw Logs**:
    - Use `curl` or similar tool to fetch the content of the raw log URL.
    - **CRITICAL**: You must use the raw log URL to avoid HTML formatting and truncated output. **Do NOT rely solely on the check summary in the GitHub API, as it may be truncated or lack full context.**


### Builder to Step Name Mapping

> [!NOTE]
> Step names can be very specific and hard to guess. This section documents patterns to help find them.

#### Recipes & Tools

*   **`flutter_drone` Recipe**
    *   **Description:** Originates from the [cocoon][] or [recipes][] repository. It is typically used for running sharded framework tests and lints (like `analyze`, `test_general`) as specified in [.ci.yaml (root)][ci-yaml-root].
    *   **Pattern:** `run test.dart for <shard> shard and subshard <subshard>`
    *   **URL Transformation:** Spaces are replaced by underscores.
    *   **Default:** If `subshard` is not specified, it defaults to `None`.
    *   **Example:** For `Linux analyze` (shard: `analyze`, no subshard), the URL step name is `run_test.dart_for_analyze_shard_and_subshard_None`.

*   **`builder.py` & Related Recipes**
    *   **Description:** Found in the `flutter/engine` repository (or recipes repository) and used to execute builds and tests according to target JSON configurations in the [builders folder][builders-folder] directory.
    *   **Pattern:** Typically the task name specified in the JSON configuration, often prefixed with `test: `.
    *   **URL Transformation:** Spaces are replaced by underscores.
    *   **Gotcha:** If the test name already starts with `test: ` in the JSON file, the recipe might still add the prefix again (e.g., `test:_test:_Check_formatting`).

*   **`tester.py`**
    *   **Description:** A common helper script in the engine's CI recipes used to execute tests.
    *   **Pattern:** `Run <shard> tests` or `Run <shard> <subshard> tests`.
    *   **URL Transformation:** Spaces are replaced by underscores.

#### Locating Exact Names in Engine

If guessing fails, find the exact test and task names in the engine configuration:
1.  Look up the builder in [.ci.yaml (engine)][ci-yaml-engine] to find its `config_name` property.
2.  Locate the corresponding JSON file in the [builders folder][builders-folder] directory.
3.  Read the JSON file to find the `tests` array and the specific `tasks` listed within them.

#### Fallback

If `read_url_content` fails with 404 on guessed step names, you may need to find the step name from the LUCI overview page or other sources.

[cocoon]: https://github.com/flutter/cocoon
[recipes]: https://github.com/flutter/recipes
[ci-yaml-root]: ../../../.ci.yaml
[ci-yaml-engine]: ../../../engine/src/flutter/.ci.yaml
[builders-folder]: ../../../engine/src/flutter/ci/builders/
