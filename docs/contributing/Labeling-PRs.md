# Labeling PRs

Across the Flutter organization, the [labeler](https://github.com/actions/labeler) GitHub action is used per repo.

For repos that already use it, only `.github/labeler.yml` needs to be edited.

For bringing up new repos, copy both `.github/workflows/labeler-trigger.yml` and `.github/workflows/labeler.yml` from an existing repo into the new repo, and update the `github.repository == '<org>/<repo>'` check in each to match the new repo. The labeler is split into two workflows so that it doesn't need `pull_request_target`: an unprivileged `pull_request` workflow records the PR number, and a privileged `workflow_run` workflow verifies that the `cla/google` check has passed (moving the PR to a draft state if it failed) before applying the labels. See [GitHub Action Workflows](../infra/GitHub-Action-Workflows.md#responding-to-pull-requests) for details.

## How to add new labels

```yaml
macos:
  # **/* recursively searches all subdirectories and files
  - shell/platform/darwin/macos/**/*

# For complex label names, it may need to be wrapped in quotes
'a: accessibility':
  - **/accessibility/*
```

## Verifying changes in presubmit

GitHub actions do not test changes in presubmit. To verify, copy your local change into a YAML linter to verify the file is not malformed.

Once landed, you can look at new workflow runs to see if the matches are being used.