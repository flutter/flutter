---
name: flutter-engine-tester
description: Runs engine, platform embedding, and dart:ui unit tests using the 'et' (Engine Tool) CLI.
---

# Flutter Engine Tester Workflow

You must strictly follow this workflow to run engine tests.

## Step 1: Execute
* **Action:** Run the test script: `dart .agents/skills/flutter-engine-tester/scripts/test_engine.dart <target>`
* **Arguments:** Pass a GN target pattern such as `//flutter/fml/...` or `//flutter/shell/platform/android:robolectric_tests`.

## Step 2: Verification & Error Handling
After execution, verify the test output.
* If the script succeeds, print "**Engine tests passed successfully!**" and then **STOP**.
* If the script fails, provide the user with the exact error output and **STOP**.
