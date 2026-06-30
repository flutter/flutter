# Shepherding Pull Requests Tool

The `shepherd.dart` tool is a self-contained Dart script designed to automate shepherding, updating, and landing both your own open Pull Requests and approved third-party contributor Pull Requests in the `flutter/flutter` repository.

## Location
* **Script**: [shepherd.dart](scripts/shepherd.dart)

## Prerequisites
* **GitHub CLI (`gh`)**: Must be installed and authenticated.
* **Dart SDK**: Must be installed.

No package initialization or `dart pub get` is required. You can run it directly:

```bash
dart scripts/shepherd.dart <command> [options]
```

---

## Commands

### 1. `list`
Lists approved, open third-party PRs and your own open PRs. Outputs a structured JSON array.
```bash
dart scripts/shepherd.dart list
```

#### JSON Output Fields:
* `number` (int): The PR number.
* `title` (string): The title of the PR.
* `author` (string): The GitHub username of the author.
* `isBehind` (bool): Whether the PR branch is behind the default branch.
* `behindByCommits` (int): Number of commits the PR is behind.
* `hasMergeConflicts` (bool): Whether there are active merge conflicts.
* `labels` (list of strings): Active labels (e.g., `CICD`, `autosubmit`).
* `checks` (object): Summary of CI checks (total, passed, failed, running).
* `nextRecommendedAction` (string): The evaluated next step (`changeBase`, `updateBranch`, `applyCicd`, `rerunChecks`, `applyAutosubmit`, or `none`).

---

### 2. `run`
Executes shepherding actions on eligible PRs.

* **Run on a specific PR**:
  ```bash
  dart scripts/shepherd.dart run --pr <pr_number>
  ```
* **Run on all eligible PRs**:
  ```bash
  dart scripts/shepherd.dart run --all
  ```
* **Dry-run mode** (evaluate and log actions without executing them):
  ```bash
  dart scripts/shepherd.dart run --all --dry-run
  ```
