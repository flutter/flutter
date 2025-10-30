# Setting Flutter Android engine flags

You can set flags for the Flutter engine on Android in two different ways:

- From the command line when launching an app with the Flutter tool
- Via `AndroidManifest.xml` metadata (static, per-build configuration)

All flags available on Android can be set via the command line, but only some
can be set via manifest metada. See `src/flutter/shell/common/switches.cc` for
the list of all supported flags. See
`src/flutter/shell/platform/android/io/flutter/embedding/engine/`
`FlutterShellArgs.java` for the list of flags that can be set via
manifest metadata.

## When to use manifest vs command line

- Use the manifest when you want a fixed, reproducible baseline of engine flags
    for your app across all launches. This is ideal for CI and for enforcing a
    consistent config for your team.
- Use the manifest when you want to vary flags by build mode or product flavor
    via manifest merging. For example, place metadata in
    `src/debug/AndroidManifest.xml`, `src/profile/AndroidManifest.xml`, and
    `src/release/AndroidManifest.xml` (or per-flavor manifests) to tailor flags
    per variant.

See below for details on using each method.

## How to set engine flags from the command line

When you run a standalone Flutter app with the Flutter tool, many engine flags
can be passed directly and are forwarded to the Android engine. Examples:

```bash
flutter run -d android \
    --trace-startup \
    --enable-software-rendering \
    --dart-flags="--enable-asserts"
```

Notes:

- Flags that take values use the `--flag=value` form (with `=`). The Flutter
    tool forwards them in that form to the Android embedding.
- If you wish to statically set flags for your application, setting them via
    the manifest is recommended and modifying the embedding to allow that is
    encouraged.

Note: If a flag is specified both on the command line and in the manifest,
the command-line value takes precedence at runtime.

## How to set engine flags in the manifest

All manifest metadata keys must be prefixed with the package name
`io.flutter.embedding.android` and are suffixed with the metadata name for the
related command line flag as determined in
`src/flutter/shell/platform/android/io/flutter/embedding/engine/`
`FlutterShellArgs.java`. For example, the `--impeller-lazy-shader-`
`mode=` command line flag corresponds to the metadata key
`io.flutter.embedding.android.ImpellerLazyShaderMode`.

For flags that take values, set the numeric or string value (without the
leading `--flag=` prefix). For boolean flags, use `android:value="true"` to
enable; omit or set `false` to disable.

Note: Manifest-provided values are overridden by command-line flags if both
are present.

### Examples

Set the `--old-gen-heap-size=` flag to 322 MB:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp">
    <application ...>
        <meta-data
            android:name="io.flutter.embedding.android.OldGenHeapSize"
            android:value="322" />
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

### Release-mode restrictions

- Some flags are not allowed in release mode. The Android embedding enforces
    this policy (see `FlutterShellArgs`, which marks allowed flags
    with `allowedInRelease`). If a disallowed flag is set in release, it will
    be ignored or rejected.
- If you need different behavior in release vs debug/profile, configure it via
    variant-specific manifests or product flavors.

## How to set engine flags dynamically

As of November 2025, setting Flutter shell arguments via an Android `Intent` is
no longer supported. If you need per-launch or runtime-controlled flags in an
add-to-app integration, you may do so programatically before engine
initialization.

To do that, supply engine arguments at process start by calling
`FlutterLoader.ensureInitializationComplete(Context, String[])` before any
`FlutterEngine` is created. This works well in add-to-app apps (call from your
`Application` or the earliest entry point you control). For example:

Kotlin:

```kotlin
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(this)
        val args = arrayOf(
                "--trace-startup",
                "--old-gen-heap-size=256",
                "--enable-software-rendering"
        )
        loader.ensureInitializationComplete(this, args)
    }
}
```

Notes:

- Call this exactly once and before creating any `FlutterEngine`,
    `FlutterEngineGroup`, `FlutterActivity`, or `FlutterFragment`.
- Flags are process-wide for the engine. Changing them later requires a fresh
    process.
