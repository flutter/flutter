---
name: updating-android-sdk
description: Upgrades Flutter's Android SDK dependency to a new Android API version (or preview/canary release) in packages.txt, verifies CIPD tag uniqueness, and packages/uploads the binaries using create_cipd_packages.sh across macOS, Linux, and Windows. Use whenever a user wants to pick up a new version of Android or upload Android SDK packages to CIPD.
---

# Updating Flutter Android SDK and CIPD Packages

This skill guides the agent step-by-step through configuring new Android SDK components in packages.txt, verifying tag uniqueness, and running the repository's automation script to upload cross-platform archives to Chrome Infrastructure Package Deployment (CIPD).

## Prerequisites & Permission Verification

Before modifying packages or triggering CIPD uploads, verify that the local environment and credentials are configured correctly:

1. **Verify Depot Tools**: Ensure `depot_tools` (which provides the `cipd` CLI) is available in the environment.
2. **Verify CIPD Writer Permissions**: The operation requires write access to the `flutter/android/sdk/all/` CIPD prefix. Verify access before proceeding:
   ```bash
   cipd acl-check flutter/android/sdk/all/ -writer
   ```
   If access is denied, request the user apply for the `flutter-cipd-writers` role and authenticate via `cipd auth-login`.

---

## Step 1: Configure Target SDK Packages (`packages.txt`)

The script `create_cipd_packages.sh` reads target SDK components and versions from `packages.txt`.

* **Location**: `engine/src/flutter/tools/android_sdk/packages.txt`
* **Format**: `<package_name>:<subdirectory_to_upload>` (delimited by `:` for multi-directory uploads)

### Querying Official Package Identifiers
Always query the local or remote Android SDK repository to confirm exact package identifiers:
```bash
sdkmanager --list --include_obsolete
```

> [!IMPORTANT]
> **Canary / Preview vs. Stable API Levels**
> When adopting a pre-release or Canary Android version (such as Android 37 / Cinnamon Bun), `sdkmanager` often publishes platform components under a `.0` suffix (e.g., `platforms;android-37.0`).
> Do **not** assume or enforce an integer API level string (`platforms;android-37`) if `sdkmanager` explicitly requires `platforms;android-37.0`. Using an incorrect package string will cause subsequent downloads to fail.

### Example `packages.txt` Update
To add Android 37 platform and build-tools:
```text
platforms;android-37.0,platforms;android-36,platforms;android-35,platforms;android-34:platforms
cmdline-tools;latest:cmdline-tools
build-tools;37.0.0,build-tools;36.1.0,build-tools;36.0.0,build-tools;35.0.0:build-tools
platform-tools:platform-tools
tools:tools
cmake;3.22.1:cmake
ndk;28.2.13676358:ndk
```

---

## Step 2: Verify Tag Uniqueness & Run Upload Script

> [!NOTE]
> **Standardizing CIPD Version Tags**
> Use clean version descriptors (e.g., `37v1`, `37v2`). Do **not** append legacy speculative suffixes such as `unmodified` now that `create_cipd_packages.sh` is the standardized upload pipeline.

CIPD tags and refs are immutable. Before executing the script, verify that your proposed version tag (e.g., `37v1`) has **not** already been registered:

```bash
cipd describe flutter/android/sdk/all/mac-arm64 -version version:<VERSION_TAG>
```

* **If the tag is unused**: The command returns exit code 1 with `Error: no such tag.`. You may proceed.
* **If the tag exists**: The command outputs the existing `Package:` and `Instance ID:`. You **must** choose a new, unique version tag.

Once uniqueness is confirmed, execute the script:

```bash
cd engine/src/flutter/tools/android_sdk
./create_cipd_packages.sh <VERSION_TAG> <PATH_TO_LOCAL_SDK>
```

### Script Execution Mechanics
1. **Clean Workspace**: The script creates a pristine temporary working directory (`mktemp -d`) to prevent cache reuse.
2. **Cross-Platform Bundles**: It leverages `REPO_OS_OVERRIDE` to fetch packages for `linux`, `macosx` (`amd64` and `arm64`), and `windows`.
3. **License Acceptance**: All required Android SDK licenses are automatically accepted and packaged inside the upload directory.
4. **CIPD Creation**: It calls `cipd create` to copy and tag packages under `flutter/android/sdk/all/<cipd_name>`.

---

## Step 3: Verify CIPD Upload & Tagging

Verify that the packages were successfully registered across all architecture targets before rolling Engine dependencies:

```bash
# macOS Apple Silicon (arm64)
cipd describe flutter/android/sdk/all/mac-arm64 -version version:<VERSION_TAG>

# macOS Intel (amd64)
cipd describe flutter/android/sdk/all/mac-amd64 -version version:<VERSION_TAG>

# Linux (amd64)
cipd describe flutter/android/sdk/all/linux-amd64 -version version:<VERSION_TAG>

# Windows (amd64)
cipd describe flutter/android/sdk/all/windows-amd64 -version version:<VERSION_TAG>
```

Ensure the output displays a valid **Instance ID** and confirms the requested tag is bound to the ref.

---

## Troubleshooting & Failure Mitigation

If any operation fails during package selection, authorization, or script execution, apply these precise remedies:

### 1. Permission Denied (`cipd acl-check` or `cipd create` fails)
* **Symptom**: `cipd acl-check` reports no roles, or uploading aborts with authorization errors.
* **Mitigation**: Direct the user to apply for the `flutter-cipd-writers` role (via MDB/Grants `8h/flutter-cipd-writers`). Once granted, run `cipd auth-login` to refresh local access credentials before retrying.

### 2. Package Resolution Failure (`sdkmanager` aborts during download)
* **Symptom**: `create_cipd_packages.sh` exits with `Warning: Failed to find package '<package_name>'`.
* **Mitigation**: Do not guess or enforce strict integer rules (e.g., `platforms;android-37`). Run `sdkmanager --list --include_obsolete` to inspect published remote tags, and correct the exact package string in `packages.txt` (such as keeping `.0` preview suffixes like `platforms;android-37.0`).

### 3. Interrupted Uploads & Tag Deprecation
* **Symptom**: A network interruption halts a multi-platform upload partway, or an incorrect package bundle was uploaded.
* **Mitigation**: CIPD uploads are final and cannot be overwritten. If a tag was partially uploaded or needs deprecation, direct the user to the internal LuCI Playbook guide for removing tags ([Removing Duplicated CIPD Tags](https://goto.google.com/flutter-luci-playbook#remove-duplicated-cipd-tags)). When retrying an upload after a failure, you **must** select a new, unique version tag (e.g., bumping `v1` to `v2`).

### 4. Missing Command-Line Tools
* **Symptom**: The script outputs `SDK directory does not contain cmdline-tools`.
* **Mitigation**: Ensure the path provided points to a valid Android SDK root containing `cmdline-tools/latest/bin/sdkmanager` (typically `~/Library/Android/sdk` on macOS).


