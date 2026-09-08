---
name: run-devicelab-with-led
description: Run DeviceLab tests for Flutter PRs using LUCI's `led` CLI tool. Use when asked to run, launch, try, or deflake a post-submit or devicelab test against a PR using `led`.
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

This skill guides running post-submit and DeviceLab tests for pull requests (PRs) using LUCI's `led` CLI tool. For additional context, see [docs/infra/Running-Devicelab-Tests-For-PR.md](../../../docs/infra/Running-Devicelab-Tests-For-PR.md).

## Prerequisites

1. **`led` tool**: Must be installed (via `depot_tools`) and available in your `PATH`. Verify via `led auth-info`.
2. **SSO authentication**: Verify valid SSO / LOAS credentials via `gcertstatus` or `glogin status`. If expired, instruct the user to run `glogin` or `gcert`.
3. **`recipes` repository** (when including `led edit-recipe-bundle`): If testing local recipe changes or recipe-only PRs, commands containing `led edit-recipe-bundle` must be executed from the root of a local checkout of the Flutter [`recipes`](https://flutter.googlesource.com/recipes) repository (`git clone https://flutter.googlesource.com/recipes`).

## Workflow

### 1. Gather Inputs based on PR Type

Collect the following required arguments:
* **`PR_NUMBER`**: The pull request number (e.g., `123456`).
* **`PRESUBMIT_TEST`**: The exact name of the LUCI staging builder to run (e.g., `Windows_mokey hot_mode_dev_cycle_win__benchmark` or `Mac_ios microbenchmarks_ios`).

### 2. Execute `led` Pipeline

If you are using `led edit-recipe-bundle` to test local recipe modifications, navigate to the root of your local `recipes` repository checkout (`$CWD` is packaged by `led edit-recipe-bundle`). If only testing without recipe edits, `led edit-recipe-bundle` can either be run from a `recipes` checkout or omitted.

Run the command pipeline corresponding to the PR type:

#### Command

```bash
led get-builder 'luci.flutter.staging:PRESUBMIT_TEST' \
  | led edit -pa git_ref='refs/pull/PR_NUMBER/head' \
  | led edit -pa git_url='https://github.com/flutter/flutter' \
  | led edit-recipe-bundle \
  | led launch
```

### 3. Report Launched Task Details

`led launch` outputs details about the launched build, including Swarming / LUCI task links. Provide the resulting URL to the user so they can track execution progress and examine logs.

## Example

- **User Prompt**: "Run the devicelab test `Windows_mokey hot_mode_dev_cycle_win__benchmark` for framework PR 12345 with led."
- **Action**: Run the `led` command (navigate to local `recipes/` directory if using `led edit-recipe-bundle` for local recipe edits):
  ```bash
  led get-builder 'luci.flutter.staging:Windows_mokey hot_mode_dev_cycle_win__benchmark' \
    | led edit -pa git_ref='refs/pull/12345/head' \
    | led edit -pa git_url='https://github.com/flutter/flutter' \
    | led edit-recipe-bundle \
    | led launch
  ```
