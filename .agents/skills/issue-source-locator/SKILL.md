---
name: issue-source-locator
description: Analyze a GitHub issue to determine which files in the Flutter monorepo (or external package repositories) could be the source of the bug.
---

# GitHub Issue Source Locator Workflow

You must strictly follow this workflow when asked to analyze a GitHub issue and locate potential source files.

## Step 1: Ingest Issue Metadata
1. Use the `github` MCP server tool `issue_read` (or equivalent GitHub fetch tool) to retrieve the title, description, and comments of the specified issue (e.g., `flutter/flutter#12345`).
2. If the issue number is provided without a repository prefix, default to `flutter/flutter`.

## Step 2: Repository & Scope Triage
Examine the issue content to determine if the problem belongs to the unified Flutter monorepo or an external repository.
- **External Packages/Plugins**: If the issue specifically identifies a package maintained in `flutter/packages` (e.g., `camera`, `shared_preferences`, `url_launcher`, `path_provider`), state clearly in your report:
  > "**Note: This issue pertains to an external package repository (`flutter/packages`). Candidate files reside outside the core monorepo.**"
- **Monorepo Core**: If the issue pertains to framework widgets, `flutter_tools`, `dart:ui`, engine C++ code, web engine, or devicelab, proceed to codebase mapping.

## Step 3: Codebase Entity Extraction & Search
Analyze stack traces, error logs, and reproduction code for specific identifiers:
1. **Stack Traces**: Extract file paths (e.g., `package:flutter/src/widgets/framework.dart`) or C++ symbols.
2. **API / Widget Names**: Extract class names, methods, or properties mentioned in reproduction steps (e.g., `SliverPersistentHeader`, `AndroidView`).
3. **Tool Commands**: If `flutter build` or `flutter run` failed, identify the relevant `flutter_tools` command class.

Use `code_search` or `find_by_name` to locate the exact absolute paths of these entities in `~/src/flutter`.

## Step 4: Candidate Selection & Output Summary
Compile your findings into a structured Markdown report containing:

### 1. Issue Summary
- **Title & Number**: (e.g., `flutter/flutter#12345 - App crashes on startup`)
- **Core Problem**: Concise 2-3 sentence summary of the bug.

### 2. Repository Classification
- Specify whether the issue is scoped to the **Unified Monorepo (`flutter/flutter`)** or an **External Repository (`flutter/packages`)**.

### 3. Candidate Source Files
Provide a prioritized list of absolute file paths in `~/src/flutter` that are most likely responsible for the bug. Format each entry as:
- `[file basename](file:///absolute/path/to/file)`: 1-2 sentence justification explaining why this file is implicated (e.g., "Contains the `performLayout` method where the null pointer exception was thrown").

### 4. Verification Plan
Suggest which testing skill (e.g., `flutter-framework-tester`, `flutter-engine-tester`, `flutter-test-orchestrator`) should be used to verify a fix once changes are made to the candidate files.
