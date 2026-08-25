---
name: bump-dart
description: Bump the minimum Dart SDK version constraint across the flutter/flutter repository, update dependency checksums, and run verification.
---

# Bumping the Dart SDK Version Constraint

Use this skill when the user asks to bump, upgrade, or change the minimum Dart SDK version constraint in the Flutter repository.

## Important Rules

1. **Never Update Dependencies to 'any':** The skill must **never** change or update any dependency version constraint to `any` in order to resolve version conflicts.
2. **Pause and Ask on Issues:** If you run into any issues executing the task (e.g., version resolution failures, checksum mismatches, test failures, or analyzer errors), **do not** attempt to fix them by modifying other dependencies. Pause immediately, report the exact error details, and ask the user for instructions.
3. **Handle Language Feature Version Discrepancies:** If static analysis fails because a package uses language features from a newer SDK version than the requested target (e.g., `private-named-parameters` in `widget_preview_scaffold` requiring `3.12.0`), ask the user if that specific package should be targeted at the higher SDK version while the rest of the repository remains at the requested target.

## Step-by-Step Workflow

Follow these steps carefully to perform the bump, resolve dependencies, and verify the changes.

### Step 1: Pre-flight Checks
1. **Verify target version suffix:**
   Ensure the version constraint specified by the user includes the `-0` pre-release suffix (e.g., `^3.13.0-0` instead of `^3.13.0`).
   * **Why:** Standard caret constraints like `^3.13.0` exclude pre-release versions of that major/minor release. Since active development and CI run on pre-releases, omitting the `-0` suffix will cause package resolution to fail. If the user provided a version without `-0`, append it or ask the user for confirmation.
2. **Ensure SDK is already rolled:**
   The target Dart SDK version must already have rolled into the repository (e.g. the local Dart SDK from the Engine stamp is at least that version). Otherwise, package resolution and analysis will fail.

### Step 2: Update `pubspec.yaml` Files
Run the repository's Dart tool script to update matching `pubspec.yaml` files cross-platform:

```bash
dart dev/tools/bin/bump_version_constraints.dart <OLD_VERSION_CONSTRAINT> <NEW_VERSION_CONSTRAINT>
```
*Example:* `dart dev/tools/bin/bump_version_constraints.dart ^3.10.0-0 ^3.11.0-0`

* **Note:** The script only updates packages whose current SDK constraint matches `<OLD_VERSION_CONSTRAINT>`. If it encounters packages with deviating constraints (e.g. higher SDK versions like `^3.12.0` or custom ranges), it will leave them untouched and print a message flagging them to the user.

### Step 3: Update Dependency Checksums and Hashes
Flutter enforces dependency integrity via checksums. Run the `update-packages` tool to re-solve the package workspace, generate updated `pubspec.lock` files, and update the checksums:

```bash
flutter update-packages --force-upgrade --update-hashes
```

### Step 4: Run Static Analysis
Verify the new constraints solve correctly and do not introduce any analyzer errors, warnings, lints (infos), or deprecations.

Run static analysis:
```bash
flutter analyze --flutter-repo
```
* **Important:** Treat any non-zero exit code from `flutter analyze` as a failure. Do not ignore `info` (lint) or `warning` diagnostics, as the Flutter repository requires all analysis issues to be clean. Pay close attention to newly firing lints or deprecated lint rule warnings.

### Step 5: Report Status, Write Results File, and Prepare Pull Request
1. **Write Results File in Workspace Root:**
   Always write a detailed report of the bump execution to a file named `bump_results.md` in the workspace root (e.g., `<flutter_root>/bump_results.md`). The file must include:
   - Target SDK version and current Engine SDK version.
   - The exact bump command run.
   - Count/details of updated `pubspec.yaml` files.
   - List of skipped/flagged packages with their constraints.
   - Results of the `update-packages` and static analysis runs (highlighting any failures, warnings, or newly firing lints).
2. **Handle Failure/Success:**
   - If static analysis fails (even if it only contains `info` or `warning` diagnostics like `prefer_initializing_formals` or `deprecated_lint`), list the failures/warnings in `bump_results.md`, report them to the user, and ask for guidance (or proceed to fix them if instructed).
   - If static analysis passes, point the user to `bump_results.md` in the workspace root, show a summary of modified files (`git status`), and prompt the user to commit the changes and prepare a pull request.


