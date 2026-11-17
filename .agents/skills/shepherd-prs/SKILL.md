---
name: shepherd-prs
description: >
  Automate shepherding, checking status, retriggering failed flutter-dashboard presubmit jobs, updating branches, and landing open PRs or approved third-party contributor PRs in the flutter/flutter repository.

  When to use:
  - When you need to check the status of open PRs or shepherded third-party PRs.
  - When you need to inspect or retrigger failed flutter-dashboard (Cocoon) presubmit checks.
  - When you need to update stale branches or apply the 'autosubmit' label to land approved PRs.

  When not to use:
  - Do not use for PRs that are not approved (unless they are your own and you want to check status or retrigger failed checks).
  - Do not use for repositories other than flutter/flutter.
---

# Shepherding Pull Requests Skill (`flutter/flutter`)

This skill defines the canonical runbook for shepherding pull requests in the `flutter/flutter` repository using native GitHub CLI (`gh`) commands and `[dashboard_presubmit.dart](scripts/dashboard_presubmit.dart)`.

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
   * The Flutter `autosubmit` bot automatically strips the `autosubmit` label whenever any blocking CI check fails.
   * Verify that all status checks are passing (`SUCCESS`/`pass`), ignoring jobs marked `"Neutral"` on `flutter-dashboard` (suppressed flakes).
   * If any blocking check is flaky, failing, or pending a retry:
     1. Do **NOT** apply the `autosubmit` label immediately.
     2. Inspect and retrigger the failed job via `flutter-dashboard` following Section 4 (or inform the user and provide the `flutter-dashboard` presubmit URL if unauthenticated).
     3. Only apply the `autosubmit` label after all retried checks complete successfully:
        ```bash
        gh pr edit <number> --repo flutter/flutter --add-label autosubmit
        ```

## 3. Third-Party Contributor PRs (2-Reviewer Requirement)

* Pull requests authored by third-party contributors (`CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, `NONE`) require **two explicit approvals** from Flutter team members (`MEMBER` or `OWNER`) before the `autosubmit` bot will merge them.
* If only one team member has approved a third-party PR and the `autosubmit` label is applied, the `autosubmit` bot will remove the label.
* *Action*: Strictly verify via `gh pr view <number> --repo flutter/flutter --json reviews` that at least **2 team member approvals** are present before adding `autosubmit` so the bot doesn't remove it again. If only 1 approval exists, remind the user to request a second reviewer before applying the label.

## 4. Inspecting & Retriggering Failed `flutter-dashboard` Checks

* **Never use raw LUCI Buildbucket `Retry Build` links (`https://cr-buildbucket.appspot.com/build/<build_id>`) or GitHub REST `rerequest` calls**:
  * Raw Buildbucket retries omit `PresubmitUserData` and do **not** reset Cocoon's unified `Presubmit` / `Dashboard Checks` check-run in Firestore.
  * GitHub's REST `POST .../check-runs/<id>/rerequest` on `Dashboard Checks` is ignored by Cocoon.
  * Always inspect and retrigger failed presubmit jobs through `flutter-dashboard` (`flutter/cocoon`) using `[dashboard_presubmit.dart](scripts/dashboard_presubmit.dart)`.
* **Step 1: Inspect Presubmit Guard Status, Suppressed Flakes & `.ci.yaml` Safety**:
  ```bash
  ./bin/dart .agents/skills/shepherd-prs/scripts/dashboard_presubmit.dart status --pr <number> --details
  ```
  * Jobs with status `"Neutral"` are **suppressed flakes** on `flutter-dashboard`; they do not block `Dashboard Checks` and must **not** be rerun.
  * **`.ci.yaml` Stale-Branch Gotcha**: In `flutter/cocoon` (`RerunFailedJob` / `RerunAllFailedJobs`), Cocoon commits `attempt_number: N + 1` (`status: "New"`) to Firestore *before* calling `CiYamlFetcher.getCiYamlByCommit` against tip-of-tree `master`. If `ci.yaml validation` failed or `master` removed/renamed a builder in `.ci.yaml` since the PR's merge-base, rerunning permanently orphans the attempt in `"New"`. `[dashboard_presubmit.dart](scripts/dashboard_presubmit.dart)` checks both automatically and exits with code `2` when you must update the PR branch (`master` merge) instead of rerunning.
* **Step 2: Retrigger Failed Jobs via CLI (`rerun`)**:
  * Retrigger a single failed builder or all failed builders:
    ```bash
    ./bin/dart .agents/skills/shepherd-prs/scripts/dashboard_presubmit.dart rerun --pr <number> --builder "<job_name>"
    ./bin/dart .agents/skills/shepherd-prs/scripts/dashboard_presubmit.dart rerun --pr <number> --all-failed
    ```
  * **One-Time Authentication Bootstrap (`login`)**: Cocoon's `/api/rerun-failed-job` and `/api/rerun-all-failed-jobs` endpoints (`presubmitAuthProvider` in `flutter/cocoon`) require `X-Flutter-IdToken` (a Firebase JWT for `flutter-dashboard` from either an `@google.com` Google Sign-In or a GitHub OAuth `flutter-dashboard` session with `flutter/flutter` write access; classic `ghp_` PATs from `gh auth token` are rejected).
    * Contributors with `@google.com` `gcloud` access can cache a refreshable token (`0600` at `~/.config/flutter_dashboard/credentials.json`) once via:
      ```bash
      gcloud auth login
      ./bin/dart .agents/skills/shepherd-prs/scripts/dashboard_presubmit.dart login
      ```
    * Contributors authenticated via GitHub OAuth on `flutter-dashboard` can supply `FLUTTER_DASHBOARD_ID_TOKEN` or cache their session refresh token via `FLUTTER_DASHBOARD_REFRESH_TOKEN=<token> ./bin/dart .agents/skills/shepherd-prs/scripts/dashboard_presubmit.dart login` (prefer environment variables over CLI flags so tokens do not appear in process arguments).
* **Step 3: Unauthenticated Browser Fallback**:
  * If CLI credentials are not configured (exit code `3`) or the user does not have `@google.com` `gcloud` access, print the `flutter-dashboard` presubmit URL so the user can retrigger failed jobs in their browser (or click **Re-run failed tests** on the GitHub `Dashboard Checks` check-run page):
    `https://flutter-dashboard.appspot.com/#/presubmit?repo=flutter&sha=<commit_sha>`
* **Step 4: Persistent Failures**:
  * If a job fails again after retriggering, inspect the failure logs (`status --pr <number> --details` or `flutter-pr-checks-finder`) and summarize the root cause for the user rather than retrying repeatedly.

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
