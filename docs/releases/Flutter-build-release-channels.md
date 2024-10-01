## Flutter's channels

Flutter has the following channels, in increasing order of stability.

### `master` (aka `main`)

The current tip-of-tree, absolute latest cutting edge build. Usually functional, though sometimes we accidentally break things. We do not run the entirety of our testing before allowing patches to land on this branch. We do not
recommend using this branch unless [you are contributing to Flutter](../../CONTRIBUTING.md).

The API documentation for the most recent commit on `master` is staged at: <https://master-api.flutter.dev>

The Flutter team's plugins and packages are regularly tested against the `master` branch.

_We are planning to rename this channel to `main` soon; this work is tracked in [flutter#121564](https://github.com/flutter/flutter/issues/121564)._

### `beta`

The latest stable release. If you want to be using the latest and greatest, the `beta` branch is the right choice. That's the most recent version of Flutter that we have heavily tested. The beta branch has passed all our public testing, has been verified against test suites for Google products that use Flutter, and has been vetted against [contributed private test suites](https://github.com/flutter/tests).

We branch from `master` for a new beta release at the beginning of the month, usually the first Wednesday. This includes a branch for Dart, the engine and the framework. These branches are then "stabilized" for the next couple of weeks, meaning we accept [cherrypick](Flutter-Cherrypick-Process.md) requests for high impact issues. Once a quarter, the beta branch lives on to become the next stable branch, as detailed below.

On average it takes about two weeks for a fix to end up in the beta branch after it lands in our repository (in the `master` channel).

We do not host the API documentation for the current `beta` branch. The documentation for the `stable` branch at <https://api.flutter.dev> is usually correct, but may be missing new features. The documentation for the `master` branch at <https://master-api.flutter.dev> is likely to be more up to date but may mention features that are not yet on the `beta` branch.

### `stable`

Roughly speaking, every third `beta` is promoted to `stable`. This is essentially the same as the `beta` branch but with less frequent updates.

We recommend using this channel for new users and for production app releases.

In case of high severity, high impact or security issues, we may do a hotfix release for the `stable` channel just like we do for `beta`. This will follow the same [cherrypick](Flutter-Cherrypick-Process.md) process.

The `stable` version of Flutter is the one documented by our API documentation at: <https://api.flutter.dev>

The Flutter team's plugins and packages are continually tested against the latest `stable` branch.


## How to change channels

You can see which channel you're on with the following command:

```
$ flutter channel
Flutter channels:
* stable
  beta
  master
```

To switch channels, run `flutter channel [<channel-name>]`, and then run `flutter upgrade` to ensure you're on the latest.

## Will a particular bug fix be provided in a hotfix release?

Depending on the severity of the issue, it is possible.  Refer to the [cherrypick process](Flutter-Cherrypick-Process.md) for details.

If you really need a particular patch and it's a fix to the flutter/flutter repository, you should feel free to create a Flutter branch yourself on your development machine and cherry-pick the fix you want onto that branch. Flutter is distributed as a `git` repository and all of `git`'s tools are available to you. If you need a particular patch that's from the flutter/engine repository or one of our dependencies (e.g. Dart or Skia), you could build your own engine but it's probably easier to just wait until the next release. On average, the next `beta` release is about two weeks away.

## See also

* [Release process](Release-process.md), which describes the details for how we push builds from channel to channel.
* [Cherrypick process](Flutter-Cherrypick-Process.md), where we cover how to request an issue for cherrypicking.
* [Release notes](https://docs.flutter.dev/release/release-notes), where we document changes to each version of the stable channel.
