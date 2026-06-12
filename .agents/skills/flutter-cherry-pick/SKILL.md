---
name: flutter-cherry-pick
description: Cherry-pick a merged PR from master to the stable or beta channel.
---

# Flutter Cherry-Pick Workflow

This skill automates the process of requesting a cherry-pick of a merged PR from the `master` branch to either the `stable` or `beta` channel.

## Quick Start

Trigger this skill by providing a merged PR number or URL and optionally the target channel:
* "Cherry pick PR 187045 to stable"
* "Request CP to beta for https://github.com/flutter/flutter/pull/186952"
* "CP PR 187045" (the agent will ask you to clarify the channel)

## Workflows

### Phase 1: Initialization and Channel Detection
1. **Identify Inputs:**
   - Original PR: `<ORIGINAL_PR>` (number or URL provided by the user).
   - Target Channel: `<CHANNEL>` (either `stable` or `beta`).
2. **Determine Channel:**
   - Parse the user's request for the target channel.
   - **GATING STEP:** If the target channel is not specified in the user's request, you **MUST STOP CALLING TOOLS AND ASK** the user: "Would you like to cherry-pick this to `stable` or `beta`?" and wait for their response before proceeding.
3. Verify you are in the root of the `flutter` repository.

### Phase 2: Run Cherry-Pick Orchestrator
1. Run the helper script to start the process:
   ```bash
   <DART_EXECUTABLE> .agents/skills/flutter-cherry-pick/scripts/flutter_cp.dart --pr <ORIGINAL_PR> --channel <CHANNEL> --action start
   ```
2. **Evaluate Script Output:**
   * **Exit Code 0 (Success):**
     - The output will end with `SUCCESS:AUTOMATED:<CP_PR>` or `SUCCESS:MANUAL:<CP_PR>`.
     - Extract the `<CP_PR>` number.
     - Proceed to **Phase 4: Fill Template**.
   * **Exit Code 2 (Conflicts):**
     - The cherry-pick encountered conflicts and the script checked out a local branch `cherry-pick-<ORIGINAL_PR>-to-<CHANNEL>`.
     - Proceed to **Phase 3: Conflict Resolution**.
   * **Exit Code 1 (Error):**
     - An unexpected error occurred. Report the failure to the user.

### Phase 3: Conflict Resolution
1. **Analyze Conflicts:**
   - Identify the conflicted files from the script output (or run `git status --porcelain` to see unmerged files).
2. **Attempt Auto-Resolution:**
   - For each conflicted file, view the contents (using `view_file`) and analyze the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
   - If the conflict is simple (e.g., import ordering, minor formatting, non-overlapping changes), resolve it using `replace_file_content` or `multi_replace_file_content`.
3. **User Fallback:**
   - If you cannot resolve the conflicts automatically:
     - Present the list of conflicted files to the user in the chat.
     - Ask the user to resolve them in their editor.
     - Stop calling tools and wait for the user to confirm resolution.
4. **Continue the Process:**
   - Once all conflicts are resolved (either by you or the user), run `git add <resolved-files>` to stage them.
   - Resume the orchestrator script:
     ```bash
     <DART_EXECUTABLE> .agents/skills/flutter-cherry-pick/scripts/flutter_cp.dart --pr <ORIGINAL_PR> --channel <CHANNEL> --action continue
     ```
   - The script will run `git cherry-pick --continue`, push, create the PR, and print `SUCCESS:MANUAL:<CP_PR>`.
   - Extract the `<CP_PR>` number and proceed to **Phase 4: Fill Template**.

### Phase 4: Fill Template and Apply
1. **Dynamically Retrieve Template:**
   - Read the local cherry-pick template:
     Use `view_file` on the local cherry-pick template (located at `../../../.github/PR_TEMPLATE/PULL_REQUEST_CP_TEMPLATE.md` relative to this skill)
   - If the file does not exist locally, fallback to fetching it via `read_url_content` from:
     `https://raw.githubusercontent.com/flutter/flutter/main/.github/PR_TEMPLATE/PULL_REQUEST_CP_TEMPLATE.md`
2. **Gather Context:**
   - Parse the original PR description for linked issues (e.g., "Fixes #187322", "Closes #123").
   - If found, fetch the issue details: `gh issue view <ISSUE_NUMBER> --json title,body`.
   - Fetch original PR details if needed.
3. **Draft the Template:**
   - Fill in the retrieved template fields using LLM reasoning based on the issue and original PR context.
   - Keep the Markdown structure of the template intact.
   - **CRITICAL:** Remove any instructional text or guidelines within the sections (e.g., "What is the impact...", "Explain this cherry pick...") when replacing them with your responses. Do NOT remove explanations around checkboxes or selection items (e.g., "What is the risk level...", "Are you confident...").
4. **Review with User (GATING STEP):**
   - Present the drafted template to the user in the chat and ask for approval or edits.
   - **YOU MUST STOP CALLING TOOLS AND WAIT** for the user's explicit approval in the chat before proceeding. Do not attempt to apply the template pre-emptively.
5. **Apply Template, Update Title, and Add Label:**
   - **Only proceed to this step after receiving explicit user approval in the chat.**
   - Ensure the PR title is formatted as `[<CHANNEL>] <ORIGINAL_PR_TITLE>`.
   - Ensure the `cp: review` label is added to the CP PR.
   - Once approved, update the CP PR description, title, and add the label:
     ```bash
     gh pr edit <CP_PR> --title "[<CHANNEL>] <ORIGINAL_PR_TITLE>" --body "<FINAL_TEMPLATE>" --add-label "cp: review"
     ```
     *(Note: If `gh pr edit` fails due to GraphQL deprecation errors, you can use the REST API via `gh api` to update the body and add the label).*
   - Provide the user with the link to the new cherry-pick PR.
