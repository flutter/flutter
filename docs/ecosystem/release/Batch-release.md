## Summary

In batch release, a GitHub Action workflow named [`TBD`](TBD) will run periodically (or manually) to scan through the files under `unreleased` folder and produce a PR against `release` branch (as opposed to `main` branch) with `changelog.md` changes and version bump in `pubspec.yaml` based on the result of parsing through these "unreleased files". Package owners are expected to review, approve, and merge this PR.

Once the PR is landed, two more workflow are trigerred:

### Release

The GitHub Action workflow named [“release”](https://github.com/flutter/packages/blob/main/.github/workflows/release.yml), will automatically publish a release based on the merged commit on `release` branch.

### Sync-back

TheGitHub Action workflow named [`TBD`](TBD), will create a PR to sync the release `branch` back to main `branch`.

## When to choose batch release

One can consider choosing this strategy if there is a lot of updates to the package, thus making release per commit infeasible.

## How to Opt in

In package root `ci_config.yaml`, set true to `batches` in `release` property.

```
release:
  batches: true
```


## Accepting Contribution

Besides following PR template checklist, as a reviewer, one must ensure the incoming PRs contain a new file in `unreleased/` folder. For exceptions, see the [Version and Changelog updates](https://github.com/flutter/flutter/blob/master/docs/ecosystem/contributing/README.md#version-and-changelog-updates) section.
