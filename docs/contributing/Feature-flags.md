# Using feature flags

[flutter.dev/to/feature-flags](https://flutter.dev/to/feature-flags)

The Flutter tool (`flutter`) supports the concept of _feature flags_, or boolean
flags that can inform, change, allow, or deny access to behavior, either in the
tool itself, or in the framework (`package:flutter`, and related).

---

Table of Contents

- [Overview](#overview)
  - [Why feature flags](#why-feature-flags)
- [Adding a flag](#adding-a-flag)
  - [Allowing flags to be enabled](#allowing-flags-to-be-enabled)
  - [Enabling a flag by default](#enabling-a-flag-by-default)
  - [Removing a flag](#removing-a-flag)
  - [Precedence](#precedence)
- [Using a flag to drive behavior](#using-a-flag-to-drive-behavior)
  - [Tool](#tool)
  - [Framework](#framework)
  - [Tests](#tests)
- [Limitations](#limitations)

## Overview

For example, [enabling the use of Swift Package Manager][enable-spm]:

```sh
flutter config --enable-swift-package-manager
```

Feature flags can be configured globally (for an entire _machine_), locally
(for a particular _app_), per-test, and be automatically enabled for different
release channels (`master`, versus `beta`, versus `stable`), giving multiple
consistent options for developing.

_See also, [Flutter pubspec options > Fields > Config][pubspec-config]._

[enable-spm]: https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers
[pubspec-config]: https://docs.flutter.dev/tools/pubspec#config

### Why feature flags

Feature flags allow conditionally, consistently, and conveniently changing
behavior.

For example:

- **Gradual rollouts** to introduce new features to a small subset of users.

- **A/B Testing** to easily test or compare different implementations.

- **Kill Switches** to quickly disable problematic features without large code
  changes.

- **Allow experimental access** to features not ready for broad or unguarded
  use.

  We do not consider it a breaking change to modify or remove experimental flags
  across releases, or to make changes guarded by experimental flags. APIs that
  are guarded by flags are subject to chage at any time.

## Adding a flag

Flags are managed in [`packages/flutter_tools/lib/src/features.dart`][flag-path].

[flag-path]: ../../packages/flutter_tools/lib/src/features.dart

The following steps are required:

1. Add a new top-level `const Feature`:

   ```dart
   const Feature unicornEmojis = Feature(
     name: 'add unicorn emojis in lots of fun places',
   );
   ```

   Additional parameters are required to make the flag configurable outside of
   a [unit test](#tests).

   To allow `flutter config`, or in `pubspec.yaml`'s `config: ...` section,
   include `configSetting`:

   ```dart
   const Feature unicornEmojis = Feature(
     name: 'add unicorn emojis in lots of fun places',
     configSetting: 'enable-unicorn-emojis',
   );
   ```

   To allow usage of the flag in the Flutter framework, include `runtimeId`:

   ```dart
   const Feature unicornEmojis = Feature(
     name: 'add unicorn emojis in lots of fun places',
     runtimeId: 'enable-unicorn-emojis',
   );
   ```

   To allow an environment variable, include `environmentOverride`:

   ```dart
   const Feature unicornEmojis = Feature(
     name: 'add unicorn emojis in lots of fun places',
     environmentOverride: 'FLUTTER_UNICORN_EMOJIS',
   );
   ```

1. Add a new field to `abstract class FeatureFlags`:

   ```dart
   abstract class FeatureFlags {
     /// Whether to add unicorm emojis in lots of fun places.
     bool get isUnicornEmojisEnabled;
   }
   ```

1. Implement the same getter in [`FlutterFeatureFlagsIsEnabled`][]:

   ```dart
   mixin FlutterFeatureFlagsIsEnabled implements FeatureFlags {
     @override
     bool get isUnicornEmojisEnabled => isEnabled(unicornEmojis);
   }
   ```

   [`FlutterFeatureFlagsIsEnabled`]: ../../packages/flutter_tools/lib/src/flutter_features.dart

1. Add a new entry in `FeatureFlags.allFeatures`:

   ```dart
   List<Feature> get allFeatures => const <Feature>[
     // ...
     unicornEmojis,
   ];
   ```

1. Create a [G3Fix][] to update google3's [`Google3Features`][]:

   [G3Fix]: http://go/g3fix
   [`Google3Features`]: http://go/flutter-google3features

    1. Add a new field to `Google3Features` :

       ```dart
       class Google3Features extends FeatureFlags {
         @override
         bool get isUnicornEmojisEnabled => true;
       }
       ```

    2. Add a new entry to `Google3Features.allFeatures`:

       ```dart
       List<Feature> get allFeatures => const <Feature>[
         // ...
         unicornEmojis,
       ];
       ```

### Allowing flags to be enabled

By default, after [adding a flag](#adding-a-flag), the flag is considered
_disabled_, and _cannot_ be enabled outside of our own [unit tests](#tests).
This allows iterating locally with the code without having to support users or
field issues related to the flag.

After some time, you may want to allow the flag to be enabled.

Using the options `master`, `beta` or `stable`, you can make the flag
configurable in those channels. For example, to make the flag available to be
enabled (but still off by default) on the `master` channel:

```dart
const Feature unicornEmojis = Feature(
  name: 'add unicorn emojis in lots of fun places',
  configSetting: 'enable-unicorn-emojis',
  master: FeatureChannelSetting(available: true),
);
```

Or to make it available on all channels:

```dart
const Feature unicornEmojis = Feature(
  name: 'add unicorn emojis in lots of fun places',
  configSetting: 'enable-unicorn-emojis',
  master: FeatureChannelSetting(available: true),
  beta: FeatureChannelSetting(available: true),
  stable: FeatureChannelSetting(available: true),
);
```

### Enabling a flag by default

Once a flag is ready to be enabled by default, once again it can be configured
on a per-channel basis.

For example, enabled on `master` by default, but disabled by default elsewhere:

```dart
const Feature unicornEmojis = Feature(
  name: 'add unicorn emojis in lots of fun places',
  configSetting: 'enable-unicorn-emojis',
  master: FeatureChannelSetting(available: true, enabledByDefault: true),
  beta: FeatureChannelSetting(available: true),
  stable: FeatureChannelSetting(available: true),
);
```

Once the flag is ready to be enabled in every environment:

```dart
const Feature unicornEmojis = Feature.fullyEnabled(
  name: 'add unicorn emojis in lots of fun places',
  configSetting: 'enable-unicorn-emojis',
);
```

### Removing a flag

After a flag is no longer useful (perhaps the experiment has concluded, the
flag has been enabled successfully for 1+ stable releases), _most_[^1] flags
should be removed so that the older behavior (or lack of a feature) can be
refactored and removed from the codebase, and there is less of a possibility of
conflicting flags.

To remove a flag, follow the opposite steps of
[adding a flag](#adding-a-flag).

You may need to remove references to the (disabled) flag from unit or
integration tests as well.

[^1]: Some flags might have a longer or indefinite lifespan, but this is rare.

### Precedence

Users have several options to configure flags. Assuming the following feature:

```dart
const Feature unicornEmojis = Feature(
  name: 'add unicorn emojis in lots of fun places',
  configSetting: 'enable-unicorn-emojis',
  environmentOverride: 'FLUTTER_ENABLE_UNICORN_EMOJIS',
);
```

Flutter uses the following precendence order:

1. The app's `pubspec.yaml` file:

   ```yaml
   flutter:
     config:
       enable-unicorn-emojis: true
   ```

2. The tool's global configuration:

   ```sh
   flutter config --enable-unicorn-emojis
   ```

3. Environment variables:

   ```sh
   FLUTTER_ENABLE_UNICORN_EMOJIS=true flutter some-command
   ```

If none of these are set, Flutter falls back to the feature's
default value for the current release channel.

## Using a flag to drive behavior

Once you have a flag, you can use it to conditionally enable something or
provide a different execution branch.

### Tool

In the `flutter` tool, feature flags. flags can be accessed either by adding
(and providing) an explicit `FeatureFlags` parameter (**recommended**):

```dart
class WebDevices extends PollingDeviceDiscovery {
  // While it could be injected from the global scope (see below), this larger
  // feature (and tests of it) are made more explicit by directly taking a
  // reference to a `FeatureFlags` instance.
  WebDevices({required FeatureFlags featureFlags}) : _featureFlags = featureFlags;

  final FeatureFlags _featureFlags;

  @override
  Future<List<Device>> pollingGetDevices({Duration? timeout}) async {
    if (!_featureFlags.isWebEnabled) {
      return <Device>[];
    }
    /* ... omitted for brevity ... */
  }
}
```

Or by injecting the currently set flags using the `globals` pattern:

```dart
// Relative path depends on location in the tool.
import '../src/features.dart';

class CreateCommand extends FlutterCommand with CreateBase {
  Future<int> _generateMethodChannelPlugin() async {
    /* ... omitted for brevity ... */
    final List<String> templates = <String>['plugin', 'plugin_shared'];
    if ((isIos || isMacos) && featureFlags.isSwiftPackageManagerEnabled) {
      templates.add('plugin_swift_package_manager');
    }
    /* ... omitted for brevity ... */
  }
}
```

### Framework

In the framework, feature flags can be accessed by importing
`src/foundation/_features.dart`:

```dart
import 'package:flutter/src/foundation/_features.dart';

final class SensitiveContent extends StatelessWidget {
  SensitiveContent() {
    if (!debugEnabledFeatureFlags.contains('enable-sensitive-content')) {
      throw UnsupportedError('Sensitive content is an experimental feature and not yet available.');
    }
  }
}
```

Note that feature flag usage in the framework runtime is very new, and is likely
to evolve over time.

Feature flags are not designed to help tree shaking. For example, you
cannot conditionally import Dart code depending on the enabled feature flags.
Tree shaking might not remove code that is feature flagged off.

### Tests

#### Integration tests

For integration tests representing _packages_ where a flag is enabled, prefer
using the [`config:`][pubspec-config] property in `pubspec.yaml`:

```yaml
flutter:
  config:
    enable-unicorn-emojis: true
```

You may see legacy cases where the flag is enabled or disabled globally using
`flutter config`.

#### Tool unit tests

For unit tests where the code directly takes a `FeatureFlags` instance:

```dart
final WindowsWorkflow windowsWorkflow = WindowsWorkflow(
  platform: windows,
  featureFlags: TestFeatureFlags(isWindowsEnabled: true),
);
/* ... omitted for brevity ... */
```

Or, for larger test suites, or code that uses the global `featureFlags` getter:

```dart
testUsingContext('prints unicorns when enabled', () async {
  // You'd write a real test, this is just an example.
  expect(featureFlags.isUnicornEmojisEnabled, true);
}, overrides: <Type, Generator>{
  FeatureFlags: () => TestFeatureFlags(isUnicornEmojisEnabled: true),
});
```

#### Framework unit tests

Feature flags can be enabled by importing `src/foundation/_features.dart`:

```dart
test('sensitive content should fail if the flag is disabled', () {
  final Set<String> originalFeatureFlags = {...debugEnabledFeatureFlags};
  addTearDown(() {
    debugEnabledFeatureFlags.clear();
    debugEnabledFeatureFlags.addAll(originalFeatureFlags);
  });

  debugEnabledFeatureFlags.remove('enable-sensitive-content');
  expect(() => SensitiveContent(), throwsUnsupportedError);
});
```

Note that feature flag usage in the framework runtime is very new, and is likely
to evolve over time.

# Limitations

The Flutter engine and embedders cannot use Flutter's feature flags directly.

If an embedder needs feature flags, you can instead use the project's platform-specific configuration.

On Android, use `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application ...>
    <meta-data
      android:name="io.flutter.embedding.android.EnableUnicornEmojis"
      android:value="true" />
  </application>
</manifest>
```

On iOS and macOS, use `Info.plist`:

```xml
...
<plist version="1.0">
<dict>
  <key>FLTEnableUnicornEmojis</key>
  <true />
</dict>
</plist>
```

See Impeller and UI thread merging for prior art.

> [!IMPORTANT]
> If possible, prefer to use Flutter feature flags instead of platform-specific configuration files.
> Flutter feature flags are easier for Flutter app developers.
