Several of our dependencies are automatically rolled (updated) by bots.

## Clang to Engine

We use an auto-roller for Clang on [Linux](https://autoroll.skia.org/r/clang-linux-flutter-engine) and [macOS](https://autoroll.skia.org/r/clang-mac-flutter-engine) (Windows is pending availability of a Windows Clang package from the Fuchsia infra team). In case of build failures or other errors, ping the #hackers-engine channel on [Discord](../contributing/Chat.md).

These rollers may fail if Clang catches a new compilation warning or error that it previously did not, or if a test relies on undefined behavior that has now changed in the new revision of Clang. It is best to resolve such issues ASAP to let the rollers continue and avoid a pile up of issues to resolve.

The rollers work by updating a [CIPD](https://chrome-infra-packages.appspot.com/p/fuchsia/third_party/clang/) package version in the DEPS file. You can map from a CIPD version to a git revision by checking in CIPD.

## Fuchsia SDK to Engine

We use an auto-roller for the Fuchsia SDK on [Linux](https://autoroll.skia.org/r/fuchsia-linux-sdk-flutter-engine) and [macOS](https://autoroll.skia.org/r/fuchsia-mac-sdk-flutter-engine) (Windows is pending availability of a Windows Fuchsia SDK package from the Fuchsia infra team). In case of build failures or other errors, ping the #hackers-engine channel on [Discord](../contributing/Chat.md).

These rollers may fail if the Fuchsia SDK contains a breaking change. It is best to resolve such issues ASAP to let the rollers continue and avoid a pile up of issues to resolve.

The rollers work by updating a [CIPD](https://chrome-infra-packages.appspot.com/p/fuchsia/sdk/core) package version in the DEPS file. You can map from a CIPD version to a JIRI snapshot or a git revision by checking in CIPD.

## Skia to Engine

We use an auto-roller for Skia rolls. It's status can be viewed at <https://skia-flutter-roll.skia.org/>. In case of  build failures or other errors, ping the Flutter-Skia chat channel. In case you get no response, you can log in with an @google.com account and pause the roller (or ask someone with an @google.com account to do so). Please specify a descriptive reason and file a bug to re-enable the rollers as soon as possible.

The bot updates the `skia_revision` line of <https://github.com/flutter/engine/blob/main/DEPS>.

Skia also uses an auto-roller for Fuchsia; see <https://autoroll-internal.skia.org/r/fuchsia-autoroll>.

## Engine to Framework

The engine is automatically rolled to the framework. It is configured by <https://skia.googlesource.com/skia-autoroll-internal-config.git/+/main/skia-infra-public/flutter-engine-flutter.cfg>.

The bot updates <https://github.com/flutter/flutter/blob/main/bin/internal/engine.version> to point to the latest revision of the engine *whose artifacts built successfully*, as determined by looking at the [Engine Console](https://ci.chromium.org/p/flutter/g/engine/console).


### Making a breaking change

Our [breaking change policy](../contributing/Tree-hygiene.md#handling-breaking-changes) disallows making changes to the engine that require changes to the framework. If you find the need to do this, you should instead make a soft-breaking change which you can land in multiple phases, as described in that process.

### Doing a manual roll

To roll the engine manually in the case you have a breaking change exemption, you'll need to land the change to `engine.version` manually in the same PR to the framework as the one where you fix the framework to work with the new API.

When you change the `engine.version` file locally, you should delete `$FLUTTER_ROOT/bin/cache` and then run `flutter precache` to ensure that all your local artifacts and snapshots are updated. You can then run tests and be sure that they are running against the latest version of the assets you need.

You may find it helpful to use the [`$ENGINE_ROOT/src/flutter/tools/engine_roll_pr_desc.sh`](https://github.com/flutter/engine/blob/main/tools/engine_roll_pr_desc.sh) to create a PR description. Doing this helps us track down what commits have rolled in more quickly, and properly link to other commits and pull requests for commenting and tracking.

For example, to generate a description from hash deadbeef to beefdead:

```bash
$ ./tools/engine_roll_pr_desc.sh deadbeef..beefdead
```

_See also: [Debugging the engine](../engine/Debugging-the-engine.md), which includes instructions on bisecting a roll failure._


## Dart to Engine

The Dart SDK is automatically rolled into the engine on a regular basis, following the steps laid out at the [Rolling Dart](Rolling-Dart.md) page. Since this process is a bit more involved, this autoroller does not use the Skia infrastructure and has a custom dashboard hosted at [go/dart-sdk-roller-dashboard](http://go/dart-sdk-roller-dashboard) (**note: this is likely only accessible from a machine on the Google network**). Using the dashboard, the autoroller can be paused, rolls can be triggered and cancelled, and rolls to a particular revision can be done.

If there are any issues with this process or the autoroller dashboard, contact bkonyi@ or a member of the Dart VM team.

## Flutter Pub Roller

The bot account [flutter-pub-roller-bot](https://github.com/flutter-pub-roller-bot) runs the script at
https://github.com/flutter/flutter/blob/main/dev/conductor/bin/packages_autoroller on post-submit of
every framework commit to keep the pub dependencies in the [framework](https://github.com/flutter/flutter)
up to date.