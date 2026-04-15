---
name: running-flutter-tool-tests
description: Instructions for running tests in packages/flutter_tools/test.
---

## Step 1: Intent Classification (Preprocessing)
Before executing any tool or test, you must determine the appropriate safety constraints.
* **Action:** Use the `.agents/skills/classifying-run-test-intent` skill to classify the user’s intent and set your execution protocol (Read-Only vs. Write/Repair).

## Step 2: Documentation Review
Before execution, you must read the official documentation to determine the correct syntax and environment requirements.
* **Action:** Review the guidelines in `flutter_tools/README.md`.

## Step 3: Test Execution
Once you have reviewed the documentation, formulate your test command and execute it in accordance with the protocol established in Step 1.