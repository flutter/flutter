---
name: flutter-engine-builder
description: Builds the Flutter engine using the 'et' (Engine Tool) CLI. Use when engine source files are modified or before running tests against a local engine.
---

# Flutter Engine Builder Workflow

You must strictly follow this workflow to build the Flutter engine.

## Step 1: Execute
* **Action:** Run the build script: `dart .agents/skills/flutter-engine-builder/scripts/build_engine.dart`

## Step 2: Verification & Error Handling
After execution, verify the build output.
* If the script succeeds, print "**Flutter engine built successfully!**" and then **STOP**.
* If the script fails, provide the user with the exact error output and **STOP**.
