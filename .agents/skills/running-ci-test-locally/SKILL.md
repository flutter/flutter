---
name: running-ci-test-locally
description: Identifies and runs Flutter tests from CI URLs or builder names. Use when a user provides a Chromium CI link (e.g., ci.chromium.org/ui/p/flutter/builders) or mentions specific Flutter test builders to investigate failures.
---

## Step 1: Intent Classification (Preprocessing)
Before extracting or executing any tests, you must determine the appropriate safety constraints.
* **Action:** Use the `.agents/skills/classifying-run-test-intent` skill to classify the user’s intent and set your execution protocol (Read-Only vs. Write/Repair).

## Step 2: Extract Builder Name
Attempt to extract the builder name from the provided CI URL.
* **Constraint:** The name should be a substring of the path, located after `/p/flutter/builders/` and before the build number.
* **Example:** For `https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_ios%20large_image_changer_perf_ios/26484/overview`, the builder name is `Mac_ios large_image_changer_perf_ios`.

## Step 3: Locate Configuration
Determine where the test is defined:
* **Framework tests:** Defined in the root `.ci.yaml`.
* **Engine tests:** Defined in `engine/src/flutter/.ci.yaml` or have "Engine Drone" in the builder name.
    * If it is an "Engine Drone" test, visit the URL to find the ancestor test, which is listed under the Infra tab > Input Properties > config_name.
    * If it is a normal engine test, visit the URL to determine which specific sub-build failed.
* **Constraint:** Only determine the test from the listed steps. Do not analyze logs at this stage.

## Step 4: Categorize and Determine Toolchain
Categorize the test using the path pattern to find the correct reference documentation for execution:
* **Engine (`engine/src/flutter/...`):** Review `docs/engine/testing/Testing-the-engine.md`.
* **Framework (`packages/flutter/test/...`):** Review `dev/bots/test.dart` (header) and `docs/contributing/testing/Running-and-writing-tests.md`.
* **Tool (`packages/flutter_tools/...`):** Review `flutter_tools/README.md`.
* **Device Lab (`dev/devicelab/...`):** Review `dev/devicelab/README.md`.

## Step 5: Test Execution
Once you have categorized the test and reviewed the appropriate documentation, formulate your test command and execute it in accordance with the safety and error-handling protocols established in Step 1.
