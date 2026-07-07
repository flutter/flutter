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

This skill allows you to automate shepherding actions on approved PRs using the [shepherd.dart](scripts/shepherd.dart) script. For details on how the tool works, see the [README.md](scripts/README.md).

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

### 2. Pre-Autosubmit Verification (Flaky or Failing Checks)
* The Flutter `autosubmit` bot automatically strips the `autosubmit` label from a PR whenever any CI check fails.
* **CRITICAL RULE**: Before applying or re-applying the `autosubmit` label, always verify that all status checks are 100% passing (`SUCCESS`/`pass`).
* If a check is flaky or currently failing/pending a retry:
  1. Do **NOT** apply `autosubmit` immediately.
  2. Inform the user of the failing check and instruct them to retry it first.
  3. Only re-apply `autosubmit` after the retried check completes successfully.

### 3. Third-Party Contributor PRs (2-Reviewer Requirement)
* Pull requests authored by third-party contributors (`CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `NONE`) require **two explicit approvals** from Flutter team members (`MEMBER` or `OWNER`) before the `autosubmit` bot will merge them.
* If only one team member has approved a third-party PR and `autosubmit` is applied, the `autosubmit` bot will remove the label.
* *Action*: When a third-party contributor PR has passing CI checks, verify that **2 team member approvals** are present. If only 1 approval exists, remind the user to request a second reviewer before applying `autosubmit`.

### 4. Failed Checks & Manual LUCI Re-runs
* Due to GitHub App permission policies, third-party check runs (such as LUCI checks created by `flutter-dashboard`) cannot be re-run via the GitHub API.
* *Action*:
  1. Print the exact LUCI Buildbucket link (e.g., `https://cr-buildbucket.appspot.com/build/<build_id>`) for the failing check.
  2. Instruct the user to open the URL and click **Retry Build** on the LUCI page.
  3. If a check continues to fail after manual retries, inspect the failure logs (`gh pr view <number> --repo flutter/flutter` or `flutter-pr-checks-finder`) and summarize the failure for the user.

### 5. Target Branch Correction & Merge Conflicts
* **Dismissed Reviews Warning**: Changing the target branch of a PR often causes GitHub to automatically dismiss existing approvals.
  - *Action*: Inform the user that changing the target branch cleared existing approvals and they need to re-approve the PR on GitHub.
* **Merge Conflicts**: If a PR has conflicts (`WARNING: PR has merge conflicts`), notify the user so the author can resolve them.

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
