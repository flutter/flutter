---
name: flutter-web-tester
description: Compiles and runs Web Engine unit tests using 'felt'.
---

# Flutter Web Tester Workflow

You must strictly follow this workflow to run web engine tests.

## Step 1: Execute
* **Action:** Run the test script: `dart .agents/skills/flutter-web-tester/scripts/test_web.dart [options] [test_file]`
* **Arguments:**
  - `[test_file]`: Optional path to a specific test file, e.g., `test/engine/util_test.dart`.
  - `--compiler`: Filter by compiler (`dart2js` or `dart2wasm`).
  - `--browser`: Filter by browser (`chrome`, `firefox`, etc.).

## Step 2: Verification & Error Handling
After execution, verify the test output.
* If the script succeeds, print "**Web engine tests passed successfully!**" and then **STOP**.
* If the script fails, provide the user with the exact error output and **STOP**.
