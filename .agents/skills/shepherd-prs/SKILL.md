---
name: shepherd-prs
description: >
  Automate shepherding, updating, and landing both your own open PRs and approved third-party contributor PRs in the flutter/flutter repository.

  When to use:
  - When you need to check the status of your open PRs or approved third-party PRs.
  - When you need to update stale branches or apply the 'autosubmit' label to land approved PRs.

  When not to use:
  - Do not use for PRs that are not approved (unless they are your own and you want to check status).
  - Do not use for repositories other than flutter/flutter.
---

# Shepherding Pull Requests Skill

This skill allows you to automate shepherding actions on approved PRs using the [shepherd.dart](scripts/shepherd.dart) script. For details on how the tool works, see the [README.md](README.md).

## Workflow and Interaction Guidelines

When the user asks for the status of their open or approved PRs:
1. **Do NOT automatically execute shepherding actions** (e.g., do not run `shepherd.dart run --all` or `shepherd.dart run --pr <number>`) on the initial inquiry.
2. **First, retrieve the PR states** using the `list` command:
   ```bash
   dart .agents/skills/shepherd-prs/scripts/shepherd.dart list
   ```
3. **Present a clear summary** of the PRs, including their current status and recommended actions.
4. **Explicitly ask the user for confirmation** before executing any shepherding/running actions.
5. **Only proceed with executing actions** (e.g., `run --all` or `run --pr`) after receiving explicit approval from the user.

## Handling Execution Outputs & Edge Cases

When running the `run` command, inspect the returned JSON logs and handle specific results as follows:

### 1. Stale Branch Updates
* The tool automatically merges the default branch into the PR if it is behind by 50+ commits, or if it has a `ci.yaml validation` failure and is behind by at least 1 commit.
* **Stale Token Scope Error**: If the branch contains GitHub Actions workflow files, the update may fail with an HTTP 403 error due to a lack of `workflow` scope.
  - *Action*: If a log contains `ERROR: ... lacks the "workflow" scope`, do not try to rerun. Output a highly prominent note to the user asking them to refresh their CLI scope:
    `gh auth refresh -h github.com -s workflow`

### 2. Failed Checks & Manual Re-runs
* Due to GitHub App permission policies, third-party check runs (such as LUCI checks created by `flutter-dashboard`) cannot be re-run via the API.
* When a PR has failed checks, the tool will log a warning instructing you to ask the user to manually trigger the re-run via the GitHub web UI.
* *Action*:
  1. Print the warning and link the user to the PR on GitHub, asking them to click the "Re-run" button for the failed check.
  2. If the check run continues to fail after manual re-runs, inspect the failure logs using `gh pr view <number> --repo flutter/flutter` or through the checks details, and write a summary of the failure for the user.

### 3. Target Branch Correction
* **Dismissed Reviews Warning**: Changing the target branch of a PR often causes GitHub to automatically dismiss existing approvals.
  - *Action*: If the target branch was changed, the PR will disappear from the approved list. Output a clear note to the user informing them that the base was corrected, and they need to go to the PR page on GitHub to **re-approve the PR** so the automation can resume shepherding it.

### 4. Merge Conflicts
* The tool will log: `WARNING: PR has merge conflicts. Manual intervention required.`
  - *Action*: Inform the user about the conflict so they can ask the contributor to resolve it.

## Examples

- **User:** "What is the status of my approved and open PRs?"
- **Agent:**
  1. Identifies the read-only inquiry and runs `dart .agents/skills/shepherd-prs/scripts/shepherd.dart list`.
  2. Parses the JSON output to present a summary of all your own open PRs and approved third-party PRs, their CI checks, and recommended actions.
  3. Asks the user for confirmation before executing any shepherding actions.

- **User:** "Yes, please update the branch for PR #186254."
- **Agent:**
  1. Identifies the user's explicit confirmation and runs `dart .agents/skills/shepherd-prs/scripts/shepherd.dart run --pr 186254`.
  2. Logs the result of the branch update to the user.

- **User:** "Run shepherding on all my eligible PRs."
- **Agent:**
  1. Asks the user for confirmation: "I will run shepherding on all eligible approved PRs. Would you like me to proceed?"
  2. Upon receiving confirmation, runs `dart .agents/skills/shepherd-prs/scripts/shepherd.dart run --all` and reports the action logs.
