## Summary

In Per-PR release, the GitHub Action workflow named [“release”](https://github.com/flutter/packages/blob/main/.github/workflows/release.yml), will automatically publish a release if a commit on master branch contains version updates the package, the “release” CI will publish the new versions to pub.dev and push the release tag to GitHub. The “release” CI passes if
1. the release process is successful, or
2. there are no version updates in the commit, or
3. the new versions have already been published.

## When to choose Per-PR release

One can consider choosing this strategy if there is not a lot of updates to the package, thus release won't be pushed as often, and they are ok with publishing update for every commit.

## How to Opt in

In package root `ci_config.yaml`, set false to `batches` in `release` property.

```
release:
  batches: false
```


## Accepting Contribution

Besides following PR template checklist, as a reviewer, one must ensure the incoming PRs contain a new entry in `CHANGELOG.md` and bump the version number in the `pubspec.yaml` file. For exceptions, see the [Version and Changelog updates](https://github.com/flutter/flutter/blob/master/docs/ecosystem/contributing/README.md#version-and-changelog-updates) section.
