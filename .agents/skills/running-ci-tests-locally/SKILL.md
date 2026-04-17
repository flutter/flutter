---
name: running-ci-test-locally
description: Identifies and runs Flutter tests from CI URLs. Use when a user provides a Chromium CI link (e.g., ci.chromium.org/ui/p/flutter/builders).
---

## Step 1: Extract Builder Name
Attempt to extract the builder name from the provided CI URL.
* **Constraint:** The name should be a substring of the path, located after `/p/flutter/builders/` and before the build number.
* **Example:** For `https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_ios%20large_image_changer_perf_ios/26484/overview`, the builder name is `Mac_ios large_image_changer_perf_ios`.

## Step 2: Locate Configuration
Determine where the test is defined:
* **Framework tests:** Defined in the root [.ci.yaml](/.ci.yaml).
* **Engine tests:** Defined in [engine/src/flutter/.ci.yaml](/engine/src/flutter/.ci.yaml) or have "Engine Drone" in the builder name.
    * If it is an "Engine Drone" test, visit the URL to find the ancestor test, which is listed under the Infra tab > Input Properties > config_name.
    * If it is a normal engine test, visit the URL to determine which specific sub-build failed.
* **Constraint:** Only determine the test from the listed steps. Do not analyze logs at this stage.

## Step 3: Locate path to test
For tests that use the following recipes, use the following paths to locate the test:
- `flutter/flutter_drone` -> `dev/bots/test.dart`
- `devicelab/devicelab_drone` -> `dev/devicelab/bin/tasks`
- `engine_v2/engine_v2` -> `engine/src/flutter/ci/builders`

## Step 4: Test Execution
Execute the tests using the companion skill [running-tests](/.agents/skills/running-tests/SKILL.md).
