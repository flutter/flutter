---
name: running-engine-tests
description: Instructions for running tests in engine/src/flutter.
---

## Step 1: Intent Classification (Preprocessing)
Before executing any tool or test, you must determine the appropriate safety constraints.
* **Action:** Use the `.agents/skills/classifying-run-test-intent` skill to classify the user’s intent and set your execution protocol (Read-Only vs. Write/Repair).

## Step 2: Documentation Review
Before execution, you must read the official documentation to determine the correct syntax and environment requirements.
* **Action:** Review `docs/engine/testing/Testing-the-engine.md`.
* **Action:** Review `engine/src/flutter/testing/ios_scenario_app/README.md`.

## Step 3: Mandatory User Interactions
You must pause and collect the following information from the user before executing the test:
1. **Build Variant:** You must ask the user to specify a build variant. Use `et help` to provide them with a list of available config variants to pick from.
2. **Rebuild Preference:** You must ask the user if they want you to rebuild the engine.

## Step 4: Environment & Tool Setup (`et`)
Prepare the tools required for building and testing.
* **Binary Location:** `engine/src/flutter/bin/et`
* **Documentation:** `engine/src/flutter/tools/engine_tool/README.md`
* **Action:** Use `engine/src/build/find_depot_tools.py` to find `depot_tools`.
* **Troubleshooting (Third-Party Dependency Error):** If you encounter an error regarding a third_party dependency, you must instruct the user to run `gclient sync -D` in the root directory. **Constraint:** The user must complete this action themselves because you run in a sandbox.

## Step 5: Test Execution
Once Step 3 is resolved, formulate and execute your commands in accordance with the protocol established in Step 1.
* **Build Command (if requested/necessary):** Use the `et` tool (e.g. `et build --config <variant>`)