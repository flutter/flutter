# Experimental Branches

[flutter.dev/to/experimental-branches](https://flutter.dev/to/experimental-branches)

Cocoon has _experimental_ support for so-called _experimental_ branches in the
`flutter/flutter` repository.

An experimental branch might be used to test newer versions of an operating
system, or make system-wide flag changes that are not yet in the state where
they can land on `master`, but are too cumbersome to use something like `led`
for due to how many steps are required.

> WARNING: These branches are not officially supported, and if broken, are only
> considered a **P2** (best effort) to fix.

## Creating an experimental branch

Any branch on `flutter/flutter` that is not:

- `master`
- a release candidate, i.e. matches `/flutter-\d+\.\d+-candidate\.\d+/`
- and supports PRs (i.e. excluding `stable` or `beta`, or similar)

... is an _experimental_ branch.

To create an experimental branch, fork an existing branch (i.e. `master`), and
update both `//.ci.yaml` and `//engine/src/flutter/.ci.yaml` so that the root
`enabled_targets: [ ... ]` includes your branch title, and (recommended) remove
targets not applicable to your experiment.

For an example, see <https://github.com/flutter/flutter/pull/168860>.

> NOTE: _New_ targets are not supported, that is, target names must exist already
> at tip-of-tree in the `master` branch.

## Testing and Submitting PRs

PRs made against an experimental branch will work _similar_ to the `master`
channel:

- If needed, the engine is built
- Tests are run against the newly or previously built engine

Submitting a PR works _similar_ to a release-candidate branch in that no merge
queue is used.

Once a PR is submitted, it will show up on the Dashboard at a specific URL:

`https://flutter-dashboard.appspot.com/#/build?repo=flutter&branch=<BRANCH_NAME>`.

The engine is then built and uploaded to GCS, and every test is automatically
marked as skipped.

_Manually_, tests can be scheduled against a sucessfully built engine. Either
click the individual test, and hit "re-run", or, for supported branches, use the
"Run all tasks" feature to schedule every task for the commit to be run
asynchronously (typically a few minutes, though may take longer when postsubmit
queues are under load):

![Example](https://github.com/user-attachments/assets/077094b6-5f7e-4e1b-952c-2a3d1abf6f8f)
