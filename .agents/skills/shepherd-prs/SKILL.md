---
name: shepherd-prs
description: Skill to automate shepherding, updating, and landing approved Pull Requests in the flutter/flutter repository using the custom self-contained shepherd.dart script.
---

# Shepherding Approved Pull Requests Skill

This skill teaches you how to act as a co-pilot/agent to shepherd and land approved Pull Requests in the `flutter/flutter` repository using the custom, self-contained `shepherd.dart` tool.

---

## 1. Finding and Executing the Tool

The shepherding tool is a **fully self-contained, single-file Dart script** with **zero external dependencies**!
* **Script Location**: `<skill_path>/shepherd.dart` (where `<skill_path>` is the directory containing this `SKILL.md` file, e.g., `.agents/skills/shepherd_prs/` in a local workspace, or `~/.gemini/config/skills/shepherd_prs/` when installed globally).

### Prerequisites
* **GitHub CLI (`gh`)**: You must have the GitHub CLI installed and authenticated on your system.
* **Dart SDK**: You must have the Dart SDK installed to run the script.

No package initialization or `dart pub get` is required! You can run it directly:
```bash
dart <skill_path>/shepherd.dart <command> [options]
```

---

## 2. Reading PR State (The `list` Command)

To understand the current state of approved third-party PRs, run the list command. It outputs a structured JSON array of Pull Request objects by default:

```bash
dart <skill_path>/shepherd.dart list
```

### Parsing the JSON:
The command returns a JSON array of Pull Request objects. For each PR, inspect:
* `number` (int): The PR number.
* `title` (string): The title of the PR.
* `baseRefName` (string): The branch the PR is trying to merge into.
* `defaultBranchName` (string): The correct default branch of the repository (e.g. `master` in flutter/flutter).
* `isBehind` (bool): Whether the PR branch is behind the default branch.
* `behindByCommits` (int): Number of commits the PR is behind.
* `hasMergeConflicts` (bool): Whether there are active merge conflicts.
* `labels` (list of strings): Active labels (e.g. `CICD`, `autosubmit`).
* `checks` (object): Summary of CI checks.
* `nextRecommendedAction` (string): The evaluated next step (`changeBase`, `updateBranch`, `applyCicd`, `rerunChecks`, `applyAutosubmit`, or `none`).

---

## 3. Executing Shepherding (The `run` Command)

To execute shepherding actions, run the `run` subcommand. By default, it outputs a structured JSON object containing the execution timestamp, whether it was a dry-run, and an array of log strings.

### A. Run on a Specific PR (Recommended)
Targeting a single PR is the safest way to execute actions and track progress:
```bash
dart <skill_path>/shepherd.dart run --pr <pr_number>
```

### B. Run on All Eligible PRs
To process the entire queue in a single pass:
```bash
dart <skill_path>/shepherd.dart run --all
```

### C. Dry-Run Mode
To evaluate and log actions without executing them, append the `--dry-run` flag:
```bash
dart <skill_path>/shepherd.dart run --all --dry-run
```

---

## 4. Handling Execution Outputs & Edge Cases

When running the `run` command, inspect the returned JSON logs. Handle specific results as follows:

### 1. Merging / Stale Branch Updates (`UPDATE_BRANCH`)
* The tool will automatically merge the default branch into the PR if it is behind by 50+ commits, or if it has a `ci.yaml validation` failure and is behind by at least 1 commit.
* **Stale Token Scope Error**: If the branch contains GitHub Actions workflow files, the update may fail with an HTTP 403 error due to a lack of `workflow` scope.
  - *Action*: If a log contains `ERROR: ... lacks the "workflow" scope`, do not try to rerun. Output a highly prominent note to the user asking them to refresh their CLI scope:
    `gh auth refresh -h github.com -s workflow`

### 2. Failed Checks & Manual Re-runs (`RERUN_CHECKS`)
* Due to GitHub App permission policies, third-party check runs (such as LUCI checks created by `flutter-dashboard`) cannot be re-run via the API.
* When a PR has failed checks, the tool will log a warning instructing you to ask the user to manually trigger the re-run via the GitHub web UI.
* **Action**:
  1. Print the warning and link the user to the PR on GitHub, asking them to click the "Re-run" button for the failed check.
  2. If the check run continues to fail after manual re-runs, inspect the failure logs using `gh pr view <number> --repo flutter/flutter` or through the checks details, and write a summary of the failure for the user.

### 3. Target Branch Correction (`CHANGEBASE`)
* **Dismissed Reviews Warning**: Changing the target branch of a PR often causes GitHub to automatically dismiss existing approvals.
  - *Action*: If the target branch was changed, the PR will disappear from the approved list. Output a clear note to the user informing them that the base was corrected, and they need to go to the PR page on GitHub to **re-approve the PR** so the automation can resume shepherding it.

### 4. Merge Conflicts (`CONFLICTS`)
* The tool will log: `WARNING: PR has merge conflicts. Manual intervention required.`
  - *Action*: Inform the user about the conflict so they can ask the contributor to resolve it.

---

## 5. Workflow and Interaction Guidelines

When the user asks for the status of their pending third-party PR reviews:
1. **Do NOT automatically execute shepherding actions** (e.g., do not run `shepherd.dart run --all` or `shepherd.dart run --pr <number>`) on the initial inquiry.
2. **First, retrieve the PR states** using the list command: `dart <skill_path>/shepherd.dart list`.
3. **Present a clear summary** of the PRs, including their current status and recommended actions.
4. **Explicitly ask the user for confirmation** before executing any shepherding/running actions.
5. **Only proceed with executing actions** (e.g., `run --all` or `run --pr`) after receiving explicit approval from the user.

## Examples

- **User:** "What is the status of my approved PRs?"
- **Agent:**
  1. Identifies the read-only inquiry and runs `dart .agents/skills/shepherd-prs/shepherd.dart list`.
  2. Parses the JSON output to present a summary of all approved third-party PRs, their CI checks, and recommended actions.
  3. Asks the user for confirmation before executing any shepherding actions.

- **User:** "Yes, please update the branch for PR #186254."
- **Agent:**
  1. Identifies the user's explicit confirmation and runs `dart .agents/skills/shepherd-prs/shepherd.dart run --pr 186254`.
  2. Logs the result of the branch update to the user.

- **User:** "Run shepherding on all my eligible PRs."
- **Agent:**
  1. Asks the user for confirmation: "I will run shepherding on all eligible approved PRs. Would you like me to proceed?"
  2. Upon receiving confirmation, runs `dart .agents/skills/shepherd-prs/shepherd.dart run --all` and reports the action logs.
