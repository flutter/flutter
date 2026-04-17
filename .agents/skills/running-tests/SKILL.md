---
name: running-tests
description: Identifies and executes the appropriate tests for the codebase. Use when a user asks to run, execute, fix, verify, or debug tests.
---

## Step 1: Determine Intent
Check if the request is about *running* existing tests or *authoring* new tests.

## Step 2: Identify Test Category

Use the file path or test type to categorize the test.
  - `packages/flutter/test/` -> Framework Tests
  - `packages/flutter_tools/test/` -> Tool Tests
  - `dev/devicelab/`, `dev/benchmarks/` -> DeviceLab Tests
  - `engine/src/` -> Engine Tests
  - `dev/bots` -> Sharded Tests

## Step 3: Documentation Review
Before execution, you must read the official documentation to determine the correct syntax and environment requirements.
  - Framework Tests -> [docs/contributing/testing/Running-and-writing-tests.md](/docs/contributing/testing/Running-and-writing-tests.md)
  - Tool Tests -> [flutter_tools/README.md](/flutter_tools/README.md)
  - DeviceLab Tests -> [dev/devicelab/README.md](/dev/devicelab/README.md)
  - Engine Tests -> [docs/engine/testing/Testing-the-engine.md](/docs/engine/testing/Testing-the-engine.md)
  - Sharded Tests -> [dev/bots/test.dart (header)](/dev/bots/test.dart)


## Step 4: Environment & Tool Setup

### Engine Tests Only
You must pause and collect the following information from the user before executing the test:
1. **Build Variant:** You must ask the user to specify a build variant. Use `et help` to provide them with a list of available config variants to pick from.
2. **Rebuild Preference:** You must ask the user if they want you to rebuild the engine.
3. **Prepare the tools required for building and testing:**
   * **Binary Location:** `engine/src/flutter/bin/et`
   * **Documentation:** [engine/src/flutter/tools/engine_tool/README.md](/engine/src/flutter/tools/engine_tool/README.md)
   * **Action:** Use [engine/src/build/find_depot_tools.py](/engine/src/build/find_depot_tools.py) to find `depot_tools`.
   * **Troubleshooting (Third-Party Dependency Error):** If you encounter an error regarding a third_party dependency, you must instruct the user to run `gclient sync -D` in the root directory. **Constraint:** The user must complete this action themselves because you run in a sandbox.

## Step 5: Test Execution
Once you have reviewed the documentation, formulate your test command and execute it in accordance with the protocol established in Step 1.
