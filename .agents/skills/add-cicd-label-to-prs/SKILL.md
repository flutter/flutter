---
name: add-cicd-label-to-prs
description: >
  Automatically checks the current user's open pull requests and applies the 'CICD'
  label if it is not already present. Make sure to use this skill whenever the
  user wants to label, tag, or organize their own pull requests with 'CICD', check
  which of their pull requests are missing the 'CICD' label, or set up a task to
  periodically run a label update on their PRs.
---

# Add CI/CD Label to PRs

A skill to check the authenticated user's open pull requests and add the `CICD` label to them if it is missing.

## Prerequisites
- GitHub CLI (`gh`) must be installed and authenticated.

## Steps

1. **Retrieve Current User**:
   Get the username of the current user:
   ```bash
   gh api user --jq .login
   ```

2. **List Open Pull Requests**:
   Find all open pull requests authored by the current user:
   ```bash
   gh pr list --author "@me" --state open --json number,title,labels
   ```

3. **Check and Apply Label**:
   For each pull request:
   - Check the `labels` list returned in the JSON.
   - If a label named `CICD` (case-insensitive or exact match) is NOT already present in the list:
     - Apply the label:
       ```bash
       gh pr edit <pr_number> --add-label "CICD"
       ```
     - Log/print a message stating that the label was successfully added to PR #<pr_number>.
   - If the `CICD` label is already present, skip it and print a message saying that the label is already present.

4. **Verify Completion**:
   Confirm that all open PRs have been checked and labeled where necessary.

## Automated Execution (Self-Execution Setup)
If the user wants this task to run automatically on a recurring basis, invoke the `schedule` tool with the following parameters:

```json
{
  "CronExpression": "*/10 9-17 * * 1-5",
  "Prompt": "Use the 'add-cicd-label-to-prs' skill to look at all of my open pull requests, and add the label 'CICD' to any that do not already have it."
}
```

Alternatively, output this slash command for the user to execute:
```text
/schedule cron="*/10 9-17 * * 1-5" prompt="Use the 'add-cicd-label-to-prs' skill to look at all of my open pull requests, and add the label 'CICD' to any that do not already have it."
```
