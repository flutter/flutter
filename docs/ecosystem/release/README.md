Any PR that changes a package's version (which should be most PRs) should be published
to pub.dev.

_See also: [Package migration to 1.0.0](../Package-migration-to-1.0.0.md)

## Automatic release

The packages in flutter/packages are automatically released with a GitHub Action workflow named [“release”](https://github.com/flutter/packages/blob/main/.github/workflows/release.yml). If a commit on master branch contains version updates to one or more packages, the “release” CI will publish the new versions to pub.dev and push the release tag to GitHub. The “release” CI passes if
1. the release process is successful, or
2. there are no version updates in the commit, or
3. the new versions have already been published.

If you are a Flutter team member at Google and you need access to the publisher account, please see b/191674407.

The “release” CI only runs on post-submit, and waits until all the other CI jobs have passed before starting. Like any other CI job, The “release” CI blocks future PRs if failed.

_Note: the “release” CI does not automatically publish the `flutter_plugin_tools` package._

### New packages

When a new package is released for the first time, it will be owned by the publisher account rather than the flutter.dev verified publisher. Someone with access (see above) needs to log into pub.dev with the publisher account and transfer the package to the verified publisher using the package's Admin tab.

### What if the “release” CI failed?

If it is a flake (for example, network issue), a Flutter team member can simply run the CI again. For more complicated cases, a Flutter team member can also manually release the packages, then re-run the CI to pass.

The most common source of failure of the `release` task is that another test failed; if that is due to flake, you will need to first re-run the failing test task, then once it's green re-run `release`.

## Manual release (only when necessary)

If something has gone wrong that prevents auto-publishing—most commonly, an out-of-band breakage that caused post-submit tests to fail for reasons unrelated to the PR that should have been published—a Flutter team member can publish manually. (An alternative to publishing manually is to revert and re-land the relevant PR; this is especially worth considering for PRs that affect many plugins.)

Some things to keep in mind before publishing the release:

- Is the post-submit CI for that commit green? Or if not (due to OOB breakage), is a subsequent post-submit green without having changed anything related to the plugin? Always check the post-submit CI before publishing.
- [Publishing is
  forever.](https://dart.dev/tools/pub/publishing#publishing-is-forever)
  Hopefully any bugs or breaking in changes in this PR have already been caught
  in PR review, but now's a second chance to revert before anything goes live.
- "Don't deploy on a Friday." Consider carefully whether or not it's worth
  immediately publishing an update before a stretch of time where you're going
  to be unavailable. There may be bugs with the release or questions about it
  from people that immediately adopt it, and uncovering and resolving those
  support issues will take more time if you're unavailable.

To release a package:
1. `git checkout <commit_hash_to_publish>`. This should be the commit of the
  PR you are publishing unless there's a very, **very** good reason you are using
  a different version.
1. Ensure that `git status` is clean, and that there are no extra files in
  your local repository (e.g., via `git clean -xfd`).
1. Use the [`publish` command from
  `flutter_plugin_tools`](https://github.com/flutter/packages/blob/main/script/tool/README.md).
  This command checks that you've done the step above, publishes the new version to pub.dev,
  and tags the commit in the format of `<package_name>-v<package_version>` then pushes
  it to the upstream repository.

### Fully manual backup option

If for some reason you can't use `flutter_plugin_tools` in step 3, you can publish manually:
  1. Push the package update to [pub.dev](https://pub.dev) using `dart pub publish`.
  2. Tag the commit with `git tag` in the format of `<package_name>-v<package_version>`
  3. Push the tag to the upstream master branch with `git push upstream <tagname>`.

## Recovering from a bad release

Sometimes, despite our best efforts, breakage is found only after a package is published. Unlike flutter/engine or flutter/flutter a breaking PR that has been published **cannot be directly reverted**, since that would revert to an earlier, also-already-published version, which cannot be published. To fix published breakage:
1. Land a fix as a new version. This can either be a revert with version and CHANGELOG updates, or a fix-forward, depending on the situation.
2. **Optional**: If the release was within the last seven days, anyone in the 'flutter.dev' publisher group can retract the bad version, using the Admin tab on the package's pub.dev page. This step is especially useful if the problem was related to a bad Flutter or Dart version constraint (i.e., the package relies on functionality from a new version of Flutter or Dart, but doesn't set that minimum), to ensure that package clients on that old version don't still resolve to the broken version even once a new version with the constraint fixed is released. It can also be useful an immediate-term step while the fixed version is being rolled out, to prevent more people from being broken while the fix is prepared.
    * If a package is retracted, this should if at all possible be in conjunction with releasing a fixed version, not instead, to make it easy for already-broken users to get to a fixed state.