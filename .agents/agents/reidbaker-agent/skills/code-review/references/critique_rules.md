# Rules for Reviewing Reviews

This reference document provides guidelines for reviewing and filtering generated code review comments (the "review the review" step). Use these rules to ensure that only high-quality, actionable comments are included in the final output.

## Filtering Guidelines

A comment should be **dropped** if it meets any of the following conditions:
- It is not on a line that was actually changed (lines starting with `+` or `-` in the diff).
- It is merely informational, explaining what the code does.
- It is complimentary (e.g., "Good job", "Nice fix").
- It tells the user to "check", "confirm", "verify", or "ensure" something without pointing to a specific issue.
- It is out of bounds for the line range allowed by the SCM API.

A comment should be **kept** or **modified** if:
- It identifies a real issue or bug.
- Its content can be made more concise or actionable.
- Its severity can be adjusted to better match the guidelines.

## Severity Guidelines (Reminders)

Ensure severity levels are applied consistently:

- **Refactoring hardcoded strings/numbers**: Generally `low` severity.
- **Log messages or enhancements**: Generally `low` severity.
- **Comments in Markdown files**: Usually `medium` or `low` severity.
- **Adding/expanding docstrings**: Usually `low` severity.
- **Suppressing warnings or TODOs**: Usually `low` severity.
- **Typos**: Usually `low` or `medium` severity.
- **Test files**: Comments on tests are usually `low` severity unless they point to a critical gap in coverage.

## Code Suggestion Quality

When reviewing code suggestions within comments, ensure:
- They are accurately anchored to the lines they intend to replace.
- They preserve the indentation and spacing of the original code.
- They are compilable or syntactically correct for the language.
- They are succinct and easy to understand.
