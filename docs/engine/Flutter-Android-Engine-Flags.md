# Setting Flutter Android engine flags

You can set flags for the Flutter engine on Android in a few different ways:

- From the command line when launching an app with the Flutter tool
- Via `AndroidManifest.xml` metadata (static, per-build configuration)
- Via Android `Intent` extras (for debugging purposes in debug and profile modes)

Flags available on Android may be set via the command line, manifest metadata,
**and/or** `Intent` extras depending on the flag and build mode. See
`src/flutter/shell/platform/android/io/flutter/embedding/engine/flags/FlutterEngineFlags.java`
for the list of flags that can be set for the Android shell, and see
`src/flutter/shell/common/switch_defs.h` for the list of all supported flags.

For flags that can be set on the command line and via the manifest,
see below to determine which method to use.

## When to use manifest metadata versus the command line

Use the manifest when:

- You want a fixed, reproducible baseline of engine flags
    for your app across all launches. This is ideal for CI and for enforcing a
    consistent configuration for your app.
- You want to vary flags by build mode or product flavor
    via manifest merging. For example, place metadata in
    `src/debug/AndroidManifest.xml`, `src/profile/AndroidManifest.xml`, and
    `src/release/AndroidManifest.xml` (or per-flavor manifests) to tailor flags
    per variant.

See [below](#how-to-set-engine-flags-in-the-manifest) for how to set flags via the manifest.

Use the command line when:

- You want to quickly experiment with a flag for a single run of your app.
- You need to override a value or toggle flag that is already set in the manifest temporarily
  for debugging or testing purposes.

See [below](#how-to-set-engine-flags-from-the-command-line) for how to set flags via the command line.

Use Android `Intent` extras when:

- You want to pass flags during manual debugging or automated testing in debug and profile modes (e.g., via `adb shell am start` or programmatically from host Android code). Note that `Intent` flags are disabled in release mode for security reasons.

See [below](#how-to-set-engine-flags-via-android-intents) for how to set flags via `Intent`s.

**Note on precedence:**

- **Flags that take values or toggles** (e.g., `--enable-impeller=true|false` or `--trace-to-file=<path>`):
  Command-line values and `Intent` extras take precedence over the manifest value at runtime.
- **Presence-only boolean flags** (e.g., `--enable-software-rendering`, `--trace-startup`, `--verbose-logging`):
  These flags enable a feature if specified in the manifest, on the command line, or via `Intent` extras.
  They cannot be disabled from the command line or `Intent` extras if already enabled in the manifest.
  If you need them enabled only for specific builds, specify them in variant-specific manifests
  (e.g., `src/debug/AndroidManifest.xml`). Issue [#193354](https://github.com/flutter/flutter/issues/193354)
  tracks adding the ability to negate flags from the command line and `Intent` extras so manifest settings can be overridden.

## Release-mode restrictions

For security purposes, release builds impose several restrictions on how engine
flags can be delivered and which flags are permitted:

- **Intent flags are disabled in release mode:** For security purposes, the
  Android embedding ignores all engine flags passed via Android `Intent`
  extras in release builds. Setting engine flags via `Intent` is only
  supported in debug and profile modes. For more background on this security restriction
  and how to migrate, see [Restrict command-line flags on prebuilt Android release binaries](https://docs.flutter.dev/release/breaking-changes/restrict-command-line-flags-prebuilt-android-release-binaries).
- **Allowed flags in release mode:** Only specific security-reviewed flags are
  allowed in release mode. The Android embedding enforces this policy (see
  `src/flutter/shell/platform/android/io/flutter/embedding/engine/flags/FlutterEngineFlags.java`,
  which marks allowed flags with `allowedInRelease`). Disallowed flags specified
  in the manifest, on the command line, or dynamically in code in release mode will be ignored.
- **Prebuilt binary limitation (`--use-application-binary`):** In debug and profile modes,
  the Flutter tool delivers command-line flags at runtime via `Intent` extras. In release mode,
  command-line flags are injected into `AndroidManifest.xml` at build time. Consequently,
  **command-line flags cannot be passed when running a prebuilt release binary** (e.g.,
  `flutter run --release --use-application-binary=...`).


## How to set engine flags from the command line

When you run a standalone Flutter app with the Flutter tool, engine flags
can be passed directly and are forwarded to the Android engine. Examples:

```bash
flutter run --trace-startup \
    --enable-software-rendering \
    --dart-flags="--enable-asserts"
```

Notes:

- Flags that take values use the `--flag=value` form (with `=`). The Flutter
  tool forwards them in that form to the Android embedding.
- **Limitation with `--use-application-binary`:** Release builds rely on build-time
  manifest injection of command-line flags and ignore runtime `Intent` extras. Consequently,
  command-line flags cannot be passed when running a prebuilt release binary. See
  [Release-mode restrictions](#release-mode-restrictions) for details.

## How to set engine flags in the manifest

All manifest metadata keys must be prefixed with the package name
`io.flutter.embedding.android.` and are suffixed with the metadata name for the
related command-line flag as defined in
`src/flutter/shell/platform/android/io/flutter/embedding/engine/flags/FlutterEngineFlags.java`.
For example, the `--impeller-lazy-shader-mode=` command-line flag corresponds to the metadata key
`io.flutter.embedding.android.ImpellerLazyShaderInitialization`.

For flags that take values, set the numeric, string, or boolean value (without
the leading `--flag=` prefix). For those that do not take values, specify a
boolean value to indicate if the flag should be used or not.

### Examples

Set the `--trace-to-file=` flag to `some_file.txt`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp">
    <application ...>
        <meta-data
            android:name="io.flutter.embedding.android.TraceToFile"
            android:value="some_file.txt"/>
            ...
    </application>
</manifest>
```

Set the `--enable-flutter-gpu` flag:

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableFlutterGPU"
    android:value="true" />
```

For flags that take boolean values, you must explicitly set
`android:value="true"` to enable the flag. Omitting the value or
providing a non-boolean value (e.g., a typo like `"Fasle"`) will
default to `false` (disabled).

## How to set engine flags via Android Intents

During development, in debug and profile modes, engine flags can also be passed
directly to a `FlutterActivity` via Android `Intent` extras. This is useful for
quick debugging workflows, automated device tests, or when launching an activity
directly via `adb`:

```bash
adb shell am start -n com.example.myapp/.MainActivity \
    --ez trace-startup true \
    --es trace-to-file /data/local/tmp/trace.json
```

Or programmatically when launching an `Intent` from native Android code:

```kotlin
val intent = Intent(context, MainActivity::class.java).apply {
    putExtra("trace-startup", true)
    putExtra("enable-software-rendering", true)
}
startActivity(intent)
```

The `Intent` extra key corresponds to the command-line flag name without the leading `--`
(for example, `trace-startup`, `trace-to-file`, `enable-software-rendering`, `enable-impeller`,
or `dart-flags`). Both boolean flags and flags that take string/integer values are supported.

Notes:

- **Intent flags are disabled in release mode:** As described in
  [Release-mode restrictions](#release-mode-restrictions), the Android embedding
  ignores all engine flags passed via Android `Intent` extras in release builds.

### How to alternatively set engine flags dynamically

As stated above, setting Flutter shell arguments via an Android `Intent` is not
supported in release mode. If you need per-launch or runtime-controlled flags in an
add-to-app integration or custom activity, you can provide them programmatically
before engine initialization.

> [!NOTE]
> Even when setting flags dynamically in code, release builds enforce the same
> security policy: any flags not marked `allowedInRelease` in
> `FlutterEngineFlags.java` will be ignored by `FlutterLoader` (see
> [Release-mode restrictions](#release-mode-restrictions)).

### Option 1: Overriding `getFlutterEngineFlags` in `FlutterActivity` or `FlutterFragment`

If you subclass `FlutterActivity` or `FlutterFragment`, you can override
`getFlutterEngineFlags()` to supply custom flags directly without manually
managing the engine lifecycle:

```kotlin
class MyFlutterActivity : FlutterActivity() {
    override fun getFlutterEngineFlags(): List<String> {
        val flags = super.getFlutterEngineFlags().toMutableList()
        flags.add("--trace-startup")
        return flags
    }
}
```

For `FlutterFragment`, you can also configure flags using `NewEngineFragmentBuilder`:

```kotlin
val fragment = FlutterFragment.NewEngineFragmentBuilder()
    .flutterEngineFlags(listOf("--trace-startup"))
    .build<FlutterFragment>()
```

### Option 2: Pre-initializing and caching a `FlutterEngine`

If you need full control over the engine lifecycle (such as in an add-to-app host application),
supply engine arguments directly to a `FlutterEngine` constructor from the earliest point you can
control in your application:

```kotlin
// Your native Android application
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Initialize the Flutter engine with desired flags
        val args = arrayOf(
            "--trace-startup",
            "--enable-impeller=true"
        )
        val flutterEngine = FlutterEngine(this, args)

        // Start executing Dart code in the FlutterEngine
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // Store the engine in the cache for later use
        FlutterEngineCache.getInstance().put("my_engine_id", flutterEngine)
    }
}
```

Then, your `Activity` can launch a `FlutterActivity` or `FlutterFragment`
with that cached `FlutterEngine`:

```kotlin
// Start a FlutterActivity using the cached engine...
val intent = FlutterActivity.withCachedEngine("my_engine_id").build(this)
startActivity(intent)

// Or launch a FlutterFragment using the cached engine
val flutterFragment = FlutterFragment.withCachedEngine("my_engine_id").build()
supportFragmentManager
    .beginTransaction()
    .add(R.id.fragment_container, flutterFragment, TAG_FLUTTER_FRAGMENT)
    .commit()
```

Alternatively, for a standalone Flutter Android app, you can create and initialize a `FlutterEngine`
as above, and override `provideFlutterEngine` in your `FlutterActivity`:

```kotlin
// Your Flutter Android application
class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()

        val args = arrayOf(
            "--trace-startup",
            "--enable-impeller=true"
        )
        val flutterEngine = FlutterEngine(this, args)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache
            .getInstance()
            .put(MY_ENGINE_ID, flutterEngine)
    }
}

// Your Flutter Android Activity
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache
            .getInstance()
            .get(MyApplication.MY_ENGINE_ID)
    }
}
```
