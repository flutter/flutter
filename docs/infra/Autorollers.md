# Autorollers

Several of our dependencies are automatically rolled (updated) by bots.

<img src="https://media1.tenor.com/m/8WV-qfNTVRMAAAAd/autobots-rollout-cat.gif" height="200" />

## Clang

We use an auto-roller for Clang <https://autoroll.skia.org/r/clang-flutter>.

These rollers may fail if Clang catches a new compilation warning or error that it previously did not, or if a test relies on undefined behavior that has now changed in the new revision of Clang. It is best to resolve such issues ASAP to let the rollers continue and avoid a pile up of issues to resolve.

The rollers work by updating a [CIPD](https://chrome-infra-packages.appspot.com/p/fuchsia/third_party/clang/) package version in the [DEPS](../../DEPS) file. You can map from a CIPD version to a git revision by checking in CIPD.

## Fuchsia SDK

We use an auto-roller for the Fuchsia SDK on [Linux](https://autoroll.skia.org/r/fuchsia-linux-sdk-flutter)
These rollers may fail if the Fuchsia SDK contains a breaking change. It is best to resolve such issues ASAP to let the rollers continue and avoid a pile up of issues to resolve.

The rollers work by updating a [CIPD](https://chrome-infra-packages.appspot.com/p/fuchsia/sdk/core) package version in the DEPS file. You can map from a CIPD version to a JIRI snapshot or a git revision by checking in CIPD.

## Skia

We use an auto-roller for Skia rolls. It's status can be viewed at <https://skia-flutter-roll.skia.org/>. In case of build failures or other errors, ping the Flutter-Skia chat channel. In case you get no response, you can log in with an `@google.com` account and pause the roller (or ask someone with an `@google.com` account to do so). Please specify a descriptive reason and file a bug to re-enable the rollers as soon as possible.

The bot updates the `skia_revision` line of [`DEPS`](../../DEPS).

## Dart

The Dart SDK is automatically rolled by <https://autoroll.skia.org/r/dart-sdk-flutter>.

If there are any issues with this process or the autoroller dashboard, contact bkonyi@ or a member of the Dart VM team.

## Flutter Pub Roller

The bot account [flutter-pub-roller-bot](https://github.com/flutter-pub-roller-bot) runs the script at
[`packages_autoroller`](../../dev/packages_autoroller) on post-submit of every
framework commit to keep the pub dependencies in the [framework](https://github.com/flutter/flutter)
up to date.
