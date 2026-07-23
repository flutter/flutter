---
name: flutter-devicelab-tester
description: Runs DeviceLab integration tasks and end-to-end tests.
---

# Flutter DeviceLab Tester Workflow

You must strictly follow this workflow to run devicelab tests.

## Step 1: Execute
* **Action:** Run the test script: `dart .agents/skills/flutter-devicelab-tester/scripts/test_devicelab.dart [options] -t <task_name>`
* **Arguments:**
  - `-t <task_name>`: Name of the task, e.g., `complex_layout__start_up`.
  - `--local-engine`: Optional local engine architecture flag.

## Step 2: Verification & Error Handling
After execution, verify the test output.
* If the script succeeds, print "**DeviceLab tests passed successfully!**" and then **STOP**.
* If the script fails, provide the user with the exact error output and **STOP**.
