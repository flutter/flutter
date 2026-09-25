---
name: issue-test-resolver
description: Ingest candidate source files identified by issue-source-locator and resolve the precise test targets and execution skills required to verify them.
---

# Issue Test Resolver Workflow

You must strictly follow this workflow to resolve candidate source files to their corresponding test targets.

## Step 1: Ingest Candidate Files
Obtain the list of candidate source files identified for a GitHub issue (e.g., from the output of `issue-source-locator`).

## Step 2: Execute Resolution Script
* **Action:** Run the resolver script: `dart .agents/skills/issue-test-resolver/scripts/resolve_test_targets.dart --files=<file1,file2>`
* **Arguments:** Pass a comma-separated list of candidate source file paths relative to the monorepo root.

## Step 3: Present Output Report
The script will generate a comprehensive Markdown report mapping each candidate file to its exact test file, test type, execution skill, and CLI command.
Present this report cleanly to the user or routing agent.
