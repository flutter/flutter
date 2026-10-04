---
name: upgrade-browser
description: Upgrade browser versions (Chrome or Firefox) in the Flutter Web Engine and/or Framework tests. Use when asked to roll or upgrade Chrome or Firefox to a newer version.
---

# Upgrade Browser

This skill automates the process of upgrading Chrome and Firefox versions in the Flutter Web Engine and the Framework tests.

## Workflow

### 1. Identify and Verify the New Version

Before updating any files, find and verify the existence of the version you want to use.

- **To find the latest stable version:**
  ```bash
  dart scripts/fetch_versions.dart latest <chrome|firefox>
  ```
- **To verify a specific version exists:**
  ```bash
  dart scripts/fetch_versions.dart verify <chrome|firefox> <version>
  ```
  This command will return `true` or `false`.

**Verification Rules:**
- **Enforced by default:** If the command returns `false`, do not proceed.
- **Optional if requested:** If the user explicitly asks to skip verification (e.g., "Upgrade to version X without verification"), you may skip this step.
- **Failed verification:** If verification fails but the user confirms they want to proceed anyway, you may continue.

### 2. Update Local Files

The user may request to upgrade one or both locations. They may also use different versions for each location.

#### Flutter Web Engine (`engine/src/flutter/lib/web_ui/dev/package_lock.yaml`)
Update the `version` field for `chrome` or `firefox`.

```yaml
chrome:
  version: 'NEW_VERSION'

firefox:
  version: 'NEW_VERSION'
```

#### Framework Tests (`.ci.yaml`)
Update all occurrences of `chrome_and_driver` with the new version.

```yaml
- {"dependency": "chrome_and_driver", "version": "version:NEW_VERSION"}
```

Use `replace` with `allow_multiple: true` to ensure all instances are updated. Note: Currently, only Chrome is managed this way in `.ci.yaml`.

### 3. CI Config Sync

After updating the browser versions, synchronize the CI configurations. This step updates `engine/src/flutter/ci/builders/linux_web_engine_test.json`.

**Only run this once.** To verify if it needs to run, check the modification time of the file:
```bash
ls -l engine/src/flutter/ci/builders/linux_web_engine_test.json
```

From `engine/src/flutter/lib/web_ui`, run:
```bash
dev/felt generate-builder-json
```

**Validation:** Confirm the file `engine/src/flutter/ci/builders/linux_web_engine_test.json` has a new timestamp after the command finishes.

### 4. Local Verification

Before uploading to CIPD, run tests locally to ensure no regressions. From `engine/src/flutter/lib/web_ui`, run:

```bash
dev/felt test
```
*Note: You can use `--browser <chrome|firefox>` to limit the scope.*

### 5. CIPD Upload (Package Roller)

This is the final step as it uploads binaries to CIPD and requires special, temporary permissions.

1. **Ask the user** if they have the necessary CIPD permissions (contact #hackers-infra on Discord if unsure).
2. If confirmed, from `engine/src/flutter/lib/web_ui`, run:
   ```bash
   dart dev/package_roller.dart
   ```
   *Note: Use `--dry-run` if the user wants to test first.*

## Examples

- **User:** "Upgrade Chrome and Firefox to the latest stable versions everywhere."
- **Agent:**
  1. Runs `dart scripts/fetch_versions.dart latest` to get the latest versions.
  2. Updates `engine/src/flutter/lib/web_ui/dev/package_lock.yaml` and `.ci.yaml`.
  3. Runs `dev/felt generate-builder-json` to sync CI configs.
  4. Suggests running local tests.
  5. Finally, asks about CIPD permissions.

- **User:** "Roll Chrome to version 135.0.0.0 everywhere. Skip verification."
- **Agent:**
  1. Skips `dart scripts/fetch_versions.dart verify` because the user requested it.
  2. Updates `package_lock.yaml` and `.ci.yaml` directly with `135.0.0.0`.
  3. Follows the rest of the workflow (Sync, Test, CIPD).

- **User:** "Update Firefox in the web engine to 130.0."
- **Agent:**
  1. Verifies version `130.0` for Firefox using `dart scripts/fetch_versions.dart verify firefox 130.0`.
  2. If verification fails, informs the user: "I was unable to verify Firefox version 130.0 through Mozilla's official release history. Are you sure this is the correct version number?"
  3. If user confirms or verification succeeds, updates `package_lock.yaml`.
  4. Follows the rest of the workflow (Sync, Test, CIPD).
