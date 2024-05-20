Code obfuscation hides function and class names in your compiled Dart code, making it difficult for an attacker to reverse engineer your proprietary app. This can be enabled with the `--obfuscate` option, which is required to be paired with  `--split-debug-info` to generate a symbol map.


<i>As of flutter 1.16.2, the information below is out of date. Only use this if you're on an earlier version of Flutter. If you are using Flutter 1.16.2 or later, please refer to [Obfuscating Dart code](https://flutter.dev/docs/deployment/obfuscate) on flutter.dev.</i>

## Android

Add the following line to `<ProjectRoot>/android/gradle.properties`:

```
extra-gen-snapshot-options=--obfuscate
```
For information on obfuscating the Android host, see [Enabling Proguard](https://flutter.dev/android-release/#enabling-proguard) in [Preparing an Android App for Release](https://flutter.dev/android-release/#minify-and-obfuscate).

## iOS

### Step 1 - Modify the "build aot" call

Add the following flag to the `build aot` call in the `<FlutterRoot>/packages/flutter_tools/bin/xcode_backend.sh` file:

```
${extra_gen_snapshot_options_or_none}
```

Define this flag as follows:

```
local extra_gen_snapshot_options_or_none=""
if [[ -n "$EXTRA_GEN_SNAPSHOT_OPTIONS" ]]; then
  extra_gen_snapshot_options_or_none="--extra-gen-snapshot-options=$EXTRA_GEN_SNAPSHOT_OPTIONS"
fi
```

### Step 2 - Modify the release config

In `<ProjectRoot>/ios/Flutter/Release.xcconfig`, add the following line:

```
EXTRA_GEN_SNAPSHOT_OPTIONS=--obfuscate
```
