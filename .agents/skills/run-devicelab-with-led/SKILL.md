---
name: run-devicelab-with-led
description: Run DeviceLab tests for Flutter framework or engine PRs using LUCI's `led` CLI tool. Use when asked to run, launch, try, or deflake a post-submit or devicelab test against a PR using `led`.
---

<!--
Host assumptions:
    Installed and on path:
        * led (from depot_tools)
        * git
        * gh
    Had authentication setup:
        * led
        * gh
        * gcert / glogin (SSO auth required for recipes repository git operations)
-->

# Running DeviceLab Tests with `led`

This skill guides running post-submit and DeviceLab tests for Flutter Framework or Engine pull requests (PRs) using LUCI's `led` CLI tool. For additional context, see [docs/infra/Running-Devicelab-Tests-For-PR.md](../../../docs/infra/Running-Devicelab-Tests-For-PR.md).

## Prerequisites

1. **`led` tool**: Must be installed (via `depot_tools`) and available in your `PATH`. Verify via `led auth-info`.
2. **SSO authentication**: Verify valid SSO / LOAS credentials via `gcertstatus` or `glogin status`. If expired, instruct the user to run `glogin` or `gcert`.
3. **`recipes` repository**: All `led` commands that modify recipe bundles must be executed from a local checkout of the Flutter [`recipes`](https://flutter.googlesource.com/recipes) repository (`git clone https://flutter.googlesource.com/recipes`).

## Workflow

### 1. Gather Inputs based on PR Type

#### Framework PRs (`flutter/flutter`)
Collect the following required arguments:
* **`PR_NUMBER`**: The pull request number (e.g., `123456`).
* **`PRESUBMIT_TEST`**: The exact name of the LUCI staging builder to run (e.g., `Windows_mokey hot_mode_dev_cycle_win__benchmark` or `Mac_ios microbenchmarks_ios`).

#### Engine PRs (`flutter/engine`)
Engine PR build artifacts are keyed by *commit hash*, not content hash.
1. Ensure the engine PR has finished building engine artifacts (e.g. `Mac mac_ios_engine` and `Mac mac_host_engine`). Check [.ci.yaml](../../../.ci.yaml) or engine/src/flutter/.ci.yaml for artifact targets.
2. Collect the following required arguments:
   * **`PR_NUMBER`**: The pull request number (e.g., `123456`).
   * **`COMMIT_HASH`**: The latest commit hash of the engine PR build.
   * **`PRESUBMIT_TEST`**: The exact test builder name (e.g., `Windows_mokey hot_mode_dev_cycle_win__benchmark`).

### 2. Execute `led` Pipeline

Navigate to your local checkout of the `recipes` repository and run the command pipeline corresponding to the PR type:

#### Framework PR Command

```bash
led get-builder 'luci.flutter.staging:PRESUBMIT_TEST' \
  | led edit -pa git_ref='refs/pull/PR_NUMBER/head' \
  | led edit -pa git_url='https://github.com/flutter/flutter' \
  | led edit-recipe-bundle \
  | led launch
```

#### Engine PR Command

```bash
led get-builder 'luci.flutter.staging:PRESUBMIT_TEST' \
  | led edit -pa git_ref='refs/pull/PR_NUMBER/head' \
  | led edit -pa git_url='https://github.com/flutter/flutter' \
  | led edit-pa flutter_prebuilt_engine_version='COMMIT_HASH' \
  | led edit-pa flutter_realm='flutter_archives_v2' \
  | led edit-recipe-bundle \
  | led launch
```

### 3. Report Launched Task Details

`led launch` outputs details about the launched build, including Swarming / LUCI task links. Provide the resulting URL to the user so they can track execution progress and examine logs.

## Examples

### Example 1: Framework PR
- **User Prompt**: "Run the devicelab test `Windows_mokey hot_mode_dev_cycle_win__benchmark` for framework PR 12345 with led."
- **Action**: Run from the local `recipes/` directory:
  ```bash
  led get-builder 'luci.flutter.staging:Windows_mokey hot_mode_dev_cycle_win__benchmark' \
    | led edit -pa git_ref='refs/pull/12345/head' \
    | led edit -pa git_url='https://github.com/flutter/flutter' \
    | led edit-recipe-bundle \
    | led launch
  ```

### Example 2: Engine PR
- **User Prompt**: "Launch `Mac_ios framework_tests_kmp` with led for engine PR 67890 using commit hash `abc123456def`."
- **Action**: Run from the local `recipes/` directory:
  ```bash
  led get-builder 'luci.flutter.staging:Mac_ios framework_tests_kmp' \
    | led edit -pa git_ref='refs/pull/67890/head' \
    | led edit -pa git_url='https://github.com/flutter/flutter' \
    | led edit-pa flutter_prebuilt_engine_version='abc123456def' \
    | led edit-pa flutter_realm='flutter_archives_v2' \
    | led edit-recipe-bundle \
    | led launch
  ```
