# Labeling PRs

Across the Flutter organization, the [labeler](https://github.com/actions/labeler) GitHub action is used per repo.

For repos that already use it, only `.github/labeler.yml` needs to be edited. For bringing up new repos, `.github/workflows/labeler.yml` should be copied from an existing repo into the new repo.

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