---
name: writing-tests
description: Writes tests for modified code. Use when a user asks to add, generate, write, create, or update tests.
---

## Step 1: Determine Scope (Mandatory Interaction)
Before generating any tests, you must pause and ask the user which changes they want to test:
* Committed
* Staged
* Unstaged
* All
* Other (please specify)

## Step 2: Analyze Changes
Once the user defines the scope:
* **Action:** Use the appropriate `git diff` command based on the user's response in Step 1 to review the modified code.

## Step 3: Conditional Documentation Review
Determine the location of the changes and read the corresponding documentation before writing tests:
* **Engine (`engine/src/flutter/...`):** Review [docs/engine/testing/Testing-the-engine.md](/docs/engine/testing/Testing-the-engine.md).
* **Framework (`packages/flutter/...`):** Review [docs/contributing/testing/Running-and-writing-tests.md](/docs/contributing/testing/Running-and-writing-tests.md).
* **Tool (`packages/flutter_tools/...`):** Review [flutter_tools/README.md](/flutter_tools/README.md).
* **Integration/Devicelab:** If specifically asked to make an integration or devicelab test, review [docs/infra/How-to-add-a-new-integration-test-to-Framework-CI.md](/docs/infra/How-to-add-a-new-integration-test-to-Framework-CI.md) and [dev/devicelab/README.md](/dev/devicelab/README.md).

## Step 4: Write Tests
Update or create new test files to cover the identified changes.

**Strict Constraints:**
* **Scope Limit:** You must ONLY edit test files. Changes to non-test file should be approved by user.
* **Dependencies:** You must only use existing dependencies. Do not import any new dependencies or packages.
* **Style:** You must adhere to the Flutter style guide: [`docs/contributing/Style-guide-for-Flutter-repo.md`](/docs/contributing/Style-guide-for-Flutter-repo.md).

## Step 5: Verification
You must verify that any new or modified tests pass.
* **Action:** Execute the tests using the companion skill [running-tests](/.agents/skills/running-tests/SKILL.md).
* **Troubleshooting:** If tests fail, diagnose and fix the tests within the strict constraints of Step 4, then re-verify.
