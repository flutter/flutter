---
name: pr-chain-manager
description: >
  Manage and automate stacked PR chains and branch rebasing in the flutter/flutter repository.
  Specifically enforces consistency for the 'android-embedder-migration-v10/*' branch slug,
  validates topological alignment, cascades downstream rebases when an upstream branch changes,
  and updates GitHub PR base references.

  When to use:
  - When committing changes to any branch in a stacked PR chain.
  - When downstream branches need to be rebased onto their parent branch in the chain.
  - When inspecting the alignment, commit count, and sync status of the branch chain.
  - When pushing chained branches to origin or updating GitHub PR base targets.

  When not to use:
  - Do not use for standalone single-branch PRs unrelated to stacked migration chains.
---

# PR Chain Manager Skill

This skill provides an automated workflow and CLI tooling to manage stacked pull request chains in the `flutter/flutter` repository under the canonical branch slug:
`android-embedder-migration-v10/*`

## Architecture and Slug Convention

Each branch in the chain represents an incremental, independently reviewable PR:
1. `upstream/master` (Root Base)
2. `android-embedder-migration-v10/0.0-llm-configuration` (PR #1: LLM skills, ADRs, and chain manager)
3. `android-embedder-migration-v10/1.0-embedder-c-api-extensions` (PR #2: C-API extensions in `embedder.h`)
4. `android-embedder-migration-v10/2.0-gn-firewall-modularization` (PR #3: Partitioning `:flutter_embedder_native_src`)
5. `android-embedder-migration-v10/2.1-surface-control` (PR #4: `AndroidSurfaceControl` & HCPP)
6. `android-embedder-migration-v10/3.0-c-api-cutover` (PR #5: `FlutterEmbedderNative` JNI cutover)
7. `android-embedder-migration-v10/4.0-legacy-purge` (PR #6: Removal of legacy `AndroidShellHolder`)

## Automated CLI Tool

The skill is powered by the native Dart CLI script:
[pr_chain.dart](file:///usr/local/google/home/boetger/src/flutter/.agents/skills/pr-chain-manager/scripts/pr_chain.dart)

To run the tool:
```bash
PATH="/usr/local/google/home/boetger/src/flutter/bin:/usr/local/google/home/boetger/src/depot_tools:$PATH" \
  dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart <command> [options]
```

### Core Commands

### 1. View Chain Status
Check all branches, commit hashes, parent linkages, and alignment status:
```bash
dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart status
```

### 2. Verify Chain Integrity
Run an automated verification asserting that every branch $N$ is an ancestor descendant of branch $N-1$:
```bash
dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart verify
```

### 3. Cascading Downstream Rebase
When you add commits, amend commits, or rebase any branch in the chain, all downstream branches become detached from the new commit history.
Run `rebase` to automatically cascade rebases onto the updated parent across the entire remaining chain:
```bash
# Cascade rebase automatically starting from the first misaligned branch:
dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart rebase

# Or specify a starting branch:
dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart rebase --from=1.0-embedder-c-api-extensions
```

#### Handling Conflicts During Cascading Rebase
If Git encounters a conflict:
1. The tool halts and prints the conflicting files.
2. Resolve conflicts in the working tree.
3. Stage resolved files:
   ```bash
   git add <resolved-files>
   ```
4. Continue the rebase:
   ```bash
   git rebase --continue
   ```
5. Resume the cascading script to rebase the remaining downstream branches:
   ```bash
   dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart rebase
   ```

### 4. Push Updated Chain
Push all branches in the chain to your remote fork (`origin`) safely using `--force-with-lease`:
```bash
dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart push
```

### 5. Synchronize GitHub PR Base Branches
Ensure each GitHub PR has its target base branch configured to its immediate predecessor in the chain:
```bash
dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart sync-gh
```

## Creating the Next Branch in the Chain

To spawn the next milestone in the chain:
```bash
# Ensure current branch is up to date:
git checkout android-embedder-migration-v10/0.0-llm-configuration

# Create next branch based on current branch HEAD:
git checkout -b android-embedder-migration-v10/1.0-embedder-c-api-extensions

# Verify chain:
dart .agents/skills/pr-chain-manager/scripts/pr_chain.dart status
```
