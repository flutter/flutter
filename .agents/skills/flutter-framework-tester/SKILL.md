---
name: flutter-framework-tester
description: Runs Dart unit and widget tests for the Flutter framework, flutter_tools, and standalone packages using 'flutter test'.
---

# Flutter Framework Tester Workflow

You must strictly follow this workflow to run framework and package tests.

## Step 1: Execute
* **Action:** Run the test script: `dart .agents/skills/flutter-framework-tester/scripts/test_framework.dart [options] <target>`
* **Arguments:**
  - `<target>`: A test file or directory, e.g., `packages/flutter/test/foundation`.
  - `--local-engine`: Optional flag to run tests against a locally built engine.

## Step 2: Verification & Error Handling
After execution, verify the test output.
* If the script succeeds, print "**Framework tests passed successfully!**" and then **STOP**.
* If the script fails, provide the user with the exact error output and **STOP**.
