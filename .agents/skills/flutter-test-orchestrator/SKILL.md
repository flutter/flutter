---
name: flutter-test-orchestrator
description: Orchestrates automated testing across the entire Flutter monorepo. Ingests modified files, determines affected components, builds the engine if required, and delegates to specialized testing skills.
---

# Flutter Test Orchestrator Workflow

You must strictly follow this workflow to orchestrate automated testing across the monorepo.

## Step 1: Execute
* **Action:** Run the orchestrator script: `dart .agents/skills/flutter-test-orchestrator/scripts/orchestrate.dart --files=<file1,file2>`
* **Arguments:** Pass a comma-separated list of modified files.

## Step 2: Verification & Error Handling
After execution, verify the test results.
* If the script succeeds, print "**All affected test suites passed successfully!**" and then **STOP**.
* If the script fails, provide the user with the exact error output and **STOP**.
