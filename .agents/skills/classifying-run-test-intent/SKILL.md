---
name: classifying-run-test-intent
description: Classifies user intent (Read-Only vs. Write/Repair) and sets the execution protocol for running tests. Use before executing any test command or whenever a user asks to run, verify, debug, write, or fix a test.
---

# Intent Classification Workflow

Before executing any test or test-related tool, you must follow this structured classification and execution protocol.

## Step 1: Classify User Intent

Analyze the user's prompt to determine their goal:

*   **Mode A (Read-Only / Run):** The user wants to verify existing behavior, check test health, or simply execute a test.
*   **Mode B (Write / Repair):** The user wants to update, write, add, or fix a test.

**Fallback/Default Rule:** If the user's intent is ambiguous, unclear, or you are unsure whether they want to modify a test, you must default to **Mode A (Read-Only / Run)**.

## Step 2: Execution Protocol

Apply the appropriate protocol based on the classification in Step 1.

### Protocol for Mode A (Read-Only / Run)
**Constraint:** Access the environment strictly in read-only mode. Your sole responsibility is to identify and run the requested test. Do not modify files.

**Troubleshooting & Error Handling:**
In the event of a test failure during Mode A, you must execute these exact steps in order:
1.  Display the exact command that was executed.
2.  Save the unaltered output of the test to a local file for the user.
3.  Provide a brief summary of the failure.
4.  **STOP:** Ask the user if they want suggestions or changes before taking any further action.

### Protocol for Mode B (Write / Repair)
**Action:** Ignore the constraints of Mode A. Proceed immediately to your standard development and debugging workflow to write or repair the test.