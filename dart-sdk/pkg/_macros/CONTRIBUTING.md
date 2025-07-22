## Required steps when updating this package

When making any functional change in the `lib` directory of this package, the
following procedure **must** be followed.

### Update pubspec/changelog for each release.

Because this is an SDK vendored package, every change is treated as a release,
and must have a stable version number and CHANGELOG.md entry.

### Update and publish `package:macros`

Additionally, the pub package `macros`, which lives at `pkg/macros`, must have
a corresponding release on pub for each version of this package.

The version of the `_macros` dependency in its pubspec must be updated to match
the new version of this package, and the pubspec version and changelog should be
updated. The changelog should have the same information as the associated
versions of this package.

These changes to the `macros` package should be landed in the same CL as the
changes to this package, and it should be immediately published when the CL is
merged. These should be marked as pre-release versions (with the `-main.x`
suffix), and stable versions will only be published when the beta SDK has been
released (exact process is TBD, possibly could do it as a hotfix, or publish
from a branch).

It is possible that multiple breaking changes can land within the same major
version of this package, during the pre-release period. Version compatibility is
thus **not** guaranteed on the dev or main channels, only the beta and stable
channels.

### Bypassing presubmit checks

When making a non-functional change in the `lib` directory, use the
`--bypass-hooks` flag to bypass presubmit checks, as in
`git cl upload --bypass-hooks`.

## Special considerations for this package

This package should generally be treated like a `dart:` library, since only
exactly one version of it ships with any SDK. That has several implications.

### Must follow breaking change process

Any breaking change to this package should follow the same breaking change
process as any change to the `dart:` libraries.

In general any breaking change made here can result in users not being able to
get a version solve on the newest SDK, if their macro dependencies have not yet
updated to the latest version.
