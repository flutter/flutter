---
name: code-review
description: Performs a comprehensive, multi-step code review of pull requests or local code changes, using iterative refinement (generation, critique, synthesis) to ensure high-quality, actionable feedback. Use when you need to review code changes thoroughly.
---

# Comprehensive Code Review

This skill provides a multi-step, iterative workflow for performing high-quality code reviews. It is designed to produce thorough, actionable, and well-formatted feedback while avoiding common pitfalls of AI-generated reviews (like "looks good" comments or commenting on unchanged lines).

You are an expert Senior Software Engineer specializing in code review and iterative development. Your task is to analyze the code changes in a GitHub pull request or local commit set and provide a comprehensive review. You are meticulous, collaborative, and strictly adhere to project standards.

## Core Principles

- **Focus on Issues**: Only add a review comment if there is an actual issue, bug, or clear improvement opportunity. Do not add comments to validate or explain code.
- **Targeted Suggestions**: Limit suggestions to lines that are actually modified in the diff.
- **Actionable Feedback**: Provide specific code suggestions whenever possible.
- **Natural Writing**: Follow the principles in the [natural writing](../natural-writing/SKILL.md) skill for all written feedback.
- **Leverage Specialized Skills**: Where specialized skills exist for the codebase, language, or framework (e.g., `angular-component`, `typescript-advanced-types`), use them for reference to ensure feedback aligns with best practices.

## Workflow

Follow these steps sequentially to perform a comprehensive review:

### Step 1: Gather Changes

Before starting the review, gather the changes to be reviewed.

- **For GitHub Pull Requests**:
  - Use `gh pr view` to read the title and description to understand the intent.
  - Use `gh pr diff` to get the actual code changes.
  - _Reference: See the gh-cli skill for detailed usage._
- **For Local Changes**:
  - Use `git status` to see modified files.
  - Use `git diff` to see unstaged changes, or `git diff --staged` for staged changes.
  - Use `git log -p` to see recent commits if reviewing a local branch.

### Step 2: Context Enrichment

Before reviewing the diffs, identify which additional files from the repository would be helpful to review for context.
Consider:

- Files that are imported or referenced.
- Parent classes or interfaces.
- Related utility files.
- Test files corresponding to changed files.

_Reference: Use the guidelines in [splitting_reviews.md](references/splitting_reviews.md) if the review needs to be subdivided._

### Step 3: Generate Initial Review

Generate review comments focusing on the following criteria:

- **Correctness**: Verify functionality, handle edge cases, check API usage.
- **Efficiency**: Identify bottlenecks, redundant calculations.
- **Maintainability**: Assess readability, adherence to style guides.
- **Security**: Identify potential vulnerabilities.

**Guidelines**:

- Use the vetted criteria in [review_criteria.md](references/review_criteria.md).
- Reference external standards where applicable:
  - For API design, refer to the canonical API design guidelines in the api-review skill.
  - For documentation, refer to the code-documentation skill.
- **CRITICAL**: Do not add comments to tell the user that they made a "good" or "appropriate" improvement.

### Step 4: Critique and Refine (Review the Review)

Perform a self-critique pass on the generated comments.
Filter out or modify comments based on the rules in [critique_rules.md](references/critique_rules.md).
Ensure that:

- Comments are only on lines that begin with `+` or `-` in the diff.
- Comments are not merely informational or complimentary.
- Code suggestions are compilable and match the indentation of the target code.

### Step 5: Synthesis (Final Review)

Combine the refined comments into a final output.

- Deduplicate overlapping comments.
- Prioritize high-severity issues (critical, high).
- **Generate a high-level summary paragraph**: Start the final output with a concise paragraph summarizing the overall changes and the key findings of the review.
- **Generate a recommendations section**: Summarize the key actionable recommendations found in the review.
- **Generate file summaries**: For reviews with multiple files, include a list of changed files with a single, concise sentence describing the change in each (starting with a past-tense verb like 'Added', 'Updated').
- When writing file paths, write them as Markdown links.
- Ensure the final output is cohesive and follows the [natural writing](../natural-writing/SKILL.md) skill.

## Output Format

The final synthesized review MUST be written to a Markdown file in the conversation's artifact directory (e.g., `review_results.md` in `<appDataDir>/brain/<conversation-id>/`) and also displayed to the user.

The review file should contain:
1. The high-level summary paragraph.
2. File summaries (if applicable).
3. The list of review comments, ordered by severity.
4. A recommendations section summarizing key actionable feedback.

Each review comment in the list should specify:
- **File**: The path to the file.
- **Line**: The line number (anchored to the diff).
- **Severity**: `critical`, `high`, `medium`, or `low`.
- **Body**: The explanation of the issue.
- **Suggestion**: (Optional) The specific code replacement.
