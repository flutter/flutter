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
1. **List Your Own Open PRs**:
   ```bash
   gh pr list --repo flutter/flutter --author <username> --state open --json number,title,url,mergeable,reviewDecision
   ```
2. **List Shepherded / Reviewed Third-Party PRs**:
   ```bash
   gh pr list --repo flutter/flutter --search "reviewed-by:<username> -author:<username> is:open" --json number,title,url,mergeable,reviewDecision
   ```
3. **Inspect Detailed PR Checks**:
   ```bash
   gh pr checks <number> --repo flutter/flutter
   ```
4. **Inspect Reviews, Labels, and Comments**:
   ```bash
   gh pr view <number> --repo flutter/flutter --json labels,reviewDecision,reviews,comments
   ```

## 2. Pre-Autosubmit Verification Rules

Before applying or re-applying the `autosubmit` label (`gh pr edit <number> --repo flutter/flutter --add-label autosubmit`), **always perform the following pre-flight verification checks** to ensure the `autosubmit` bot will not reject or strip the label:

1. **Check Previous `autosubmit` Removal History in Comments**:
   * Always check if the `autosubmit` label was previously removed by the `auto-submit` bot by checking PR comments:
     ```bash
     gh pr view <number> --repo flutter/flutter --json comments
     ```
   * Look for messages from `auto-submit` such as `"autosubmit label was removed..."`.
   * If the label was previously removed, identify the exact reason stated by the bot (e.g., failing CI checks, insufficient approvals, merge conflicts, or stale branch) and confirm that the underlying issue has been resolved before re-applying `autosubmit`.

2. **Verify Freshness of Base Commit (>7 Days Old)**:
   * Check whether the PR's base commit is stale (>7 days old).
   * If the base commit is more than **7 days old**, always instruct running or execute a branch update before attempting to add `autosubmit`:
     ```bash
     gh pr update-branch <number> --repo flutter/flutter
     ```
   * Do not apply `autosubmit` until the branch update is complete and CI checks on the updated branch succeed.

3. **Strictly Verify Required Reviewer Approvals**:
   * Strictly verify that third-party contributor PRs (`CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `NONE`) have at least **2 team member approvals** (`MEMBER` or `OWNER`) before adding `autosubmit` so the bot doesn't remove it again.
   * Check `reviews` in `gh pr view <number> --repo flutter/flutter --json reviews` to confirm the number of approvals from Flutter team members.

4. **Verify All Status Checks Are 100% Passing**:
   * The Flutter `autosubmit` bot automatically strips the `autosubmit` label whenever any CI check fails.
   * Verify that all status checks are passing (`SUCCESS`/`pass`).
   * If any check is flaky, failing, or pending a retry:
     1. Do **NOT** apply the `autosubmit` label immediately.
     2. Inform the user of the failing check and instruct them to retry it first.
     3. Only apply the `autosubmit` label after all retried checks complete successfully:
        ```bash
        gh pr edit <number> --repo flutter/flutter --add-label autosubmit
        ```

## 3. Third-Party Contributor PRs (2-Reviewer Requirement)

* Pull requests authored by third-party contributors (`CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `NONE`) require **two explicit approvals** from Flutter team members (`MEMBER` or `OWNER`) before the `autosubmit` bot will merge them.
* If only one team member has approved a third-party PR and the `autosubmit` label is applied, the `autosubmit` bot will remove the label.
* *Action*: Strictly verify via `gh pr view <number> --repo flutter/flutter --json reviews` that at least **2 team member approvals** are present before adding `autosubmit` so the bot doesn't remove it again. If only 1 approval exists, remind the user to request a second reviewer before applying the label.

## 4. Failed Checks & Manual LUCI Re-runs

* Due to GitHub App permission policies, third-party check runs (such as LUCI checks created by `flutter-dashboard`) cannot be re-run via the GitHub API.
* *Action*:
  1. Print the exact LUCI Buildbucket link (e.g., `https://cr-buildbucket.appspot.com/build/<build_id>`) for the failing check.
  2. Instruct the user to open the URL and click **Retry Build** on the LUCI page.
  3. If a check continues to fail after manual retries, inspect the failure logs (`gh pr view <number> --repo flutter/flutter` or `flutter-pr-checks-finder`) and summarize the failure for the user.

## 5. Stale Branch Updates, CICD Label & Token Scope

* If a PR branch is out of date with `master` (including when the base commit is >7 days old):
  * Always update the branch using `gh pr update-branch <number> --repo flutter/flutter` before attempting to add `autosubmit`.
* **Re-applying the `CICD` Label**:
  * After updating a branch with `gh pr update-branch` (or when shepherding a PR that has not run CI), the `CICD` label is often stripped or required to start the CI checks on the updated commit.
  * Always check if the `CICD` label is present after a branch update, and re-apply it if missing:
    ```bash
    gh pr edit <number> --repo flutter/flutter --add-label CICD
    ```
* **Stale Token Scope Error**: If updating fails due to workflow file permissions (`ERROR: ... lacks the "workflow" scope`), instruct the user to refresh their CLI scope:
  ```bash
  gh auth refresh -h github.com -s workflow
  ```

## 6. Target Branch Correction & Merge Conflicts

* **Dismissed Reviews Warning**: Changing the target branch of a PR often causes GitHub to automatically dismiss existing approvals. Alert the user if the target branch changed so they can re-approve on GitHub.
* **Merge Conflicts**: If a PR has conflicts (`MERGEABLE` is `CONFLICTING`), notify the user so the author can resolve them.
