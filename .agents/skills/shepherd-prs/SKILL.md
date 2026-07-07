---
name: shepherd-prs
description: >
  Automate shepherding, checking status, updating branches, and landing open PRs or approved third-party contributor PRs in the flutter/flutter repository using the gh CLI.

  When to use:
  - When you need to check the status of open PRs or shepherded third-party PRs.
  - When you need to update stale branches or apply the 'autosubmit' label to land approved PRs.

  When not to use:
  - Do not use for PRs that are not approved (unless they are your own and you want to check status).
  - Do not use for repositories other than flutter/flutter.
---

# Shepherding Pull Requests Skill (`flutter/flutter`)

This skill defines the canonical runbook for shepherding pull requests in the `flutter/flutter` repository using native GitHub CLI (`gh`) commands.

## 1. Checking PR Status

When the user asks for the status of open or approved PRs:
1. **List Open PRs**:
   ```bash
   gh pr list --repo flutter/flutter --author <username> --state open --json number,title,url,mergeable,reviewDecision
   ```
2. **Inspect Detailed PR Checks**:
   ```bash
   gh pr checks <number> --repo flutter/flutter
   ```
3. **Inspect Reviews and Labels**:
   ```bash
   gh pr view <number> --repo flutter/flutter --json labels,reviewDecision,reviews
   ```

## 2. Pre-Autosubmit Verification (Flaky or Failing Checks)

* The Flutter `autosubmit` bot automatically strips the `autosubmit` label from a PR whenever any CI check fails.
* **CRITICAL RULE**: Before applying or re-applying the `autosubmit` label, always verify that all status checks are 100% passing (`SUCCESS`/`pass`).
* If a check is flaky or currently failing/pending a retry:
  1. Do **NOT** apply `autosubmit` immediately.
  2. Inform the user of the failing check and instruct them to retry it first.
  3. Only apply `autosubmit` after the retried check completes successfully:
     ```bash
     gh pr edit <number> --repo flutter/flutter --add-label autosubmit
     ```

## 3. Third-Party Contributor PRs (2-Reviewer Requirement)

* Pull requests authored by third-party contributors (`CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `NONE`) require **two explicit approvals** from Flutter team members (`MEMBER` or `OWNER`) before the `autosubmit` bot will merge them.
* If only one team member has approved a third-party PR and `autosubmit` is applied, the `autosubmit` bot will remove the label.
* *Action*: When a third-party contributor PR has passing CI checks, check `reviews` in `gh pr view` to verify that **2 team member approvals** are present. If only 1 approval exists, remind the user to request a second reviewer before applying `autosubmit`.

## 4. Failed Checks & Manual LUCI Re-runs

* Due to GitHub App permission policies, third-party check runs (such as LUCI checks created by `flutter-dashboard`) cannot be re-run via the GitHub API.
* *Action*:
  1. Print the exact LUCI Buildbucket link (e.g., `https://cr-buildbucket.appspot.com/build/<build_id>`) for the failing check.
  2. Instruct the user to open the URL and click **Retry Build** on the LUCI page.
  3. If a check continues to fail after manual retries, inspect the failure logs (`gh pr view <number> --repo flutter/flutter` or `flutter-pr-checks-finder`) and summarize the failure for the user.

## 5. Stale Branch Updates & Token Scope

* If a PR branch is out of date with `master`:
  * Use `gh pr update-branch <number> --repo flutter/flutter` or merge `upstream/master` locally.
* **Stale Token Scope Error**: If updating fails due to workflow file permissions (`ERROR: ... lacks the "workflow" scope`), instruct the user to refresh their CLI scope:
  ```bash
  gh auth refresh -h github.com -s workflow
  ```

## 6. Target Branch Correction & Merge Conflicts

* **Dismissed Reviews Warning**: Changing the target branch of a PR often causes GitHub to automatically dismiss existing approvals. Alert the user if the target branch changed so they can re-approve on GitHub.
* **Merge Conflicts**: If a PR has conflicts (`MERGEABLE` is `CONFLICTING`), notify the user so the author can resolve them.
