# Setting Flutter Android engine flags

You can set flags for the Flutter engine on Android in two different ways:

- From the command line when launching an app with the Flutter tool
- Via `AndroidManifest.xml` metadata (static, per-build configuration)

All flags available on Android can be set via the command line **and** via
manifest metadata. See `src/flutter/shell/common/switches.cc` for
the list of all supported flags, and see
`src/flutter/shell/platform/android/io/flutter/embedding/engine/`
`FlutterShellArgs.java` for the list of flags that can be set for the
Android shell.

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

Use the command line when:

- You want to quickly experiment with a flag for a single run of your app.
- You need to override a flag that is already set in the manifest temporarily for debugging
  or testing purposes.

**Note: If a flag is specified both on the command line and in the manifest,
the command-line value takes precedence at runtime.**

See below for details on using each method.

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

## How to set engine flags in the manifest

All manifest metadata keys must be prefixed with the package name
`io.flutter.embedding.android` and are suffixed with the metadata name for the
related command line flag as determined in
`src/flutter/shell/platform/android/io/flutter/embedding/engine/`
`FlutterShellArgs.java`. For example, the `--impeller-lazy-shader-mode=`
command line flag corresponds to the metadata key
`io.flutter.embedding.android.ImpellerLazyShaderInitialization`.

For flags that take values, set the numeric, string, or boolean value (without
the leading `--flag=` prefix).

### Examples

Set the `--old-gen-heap-size=` flag to 322 MB:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp">
    <application ...>
        <meta-data
            android:name="io.flutter.embedding.android.OldGenHeapSize"
            android:value="322"/>
            ...
    </application>
</manifest>
```

Set the `--enable-flutter-gpu` flag:

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableFlutterGPU"
/>
```

## Release-mode restrictions

- Some flags are not allowed in release mode. The Android embedding enforces
    this policy (see `src/flutter/shell/platform/android/io/flutter/
    embedding/engine/FlutterShellArgs`, which marks allowed flags
    with `allowedInRelease`). If a disallowed flag is set in release, it will
    be ignored.
- If you need different behavior in release vs debug/profile mode, configure it
    via variant-specific manifests or product flavors.

## How to set engine flags dynamically

As of the writing of this document, setting Flutter shell arguments via an
Android `Intent` is no longer supported. If you need per-launch or
runtime-controlled flags in an add-to-app integration, you may do so
programatically before engine initialization.

To do that, supply engine arguments directly to a `FlutterEngine` with the
desired flags from the earliest point you can control in your
application. For example, if you are writing an add-to-app app that launches
a `FlutterActivity` or `FlutterFragment`, then you can cache a
`FlutterEngine` that is initialized with your desired
engine flags:

```kotlin
// Your native Android application
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Initialize the Flutter engine with desired flags
        val args = arrayOf(
            "--trace-startup",
            "--old-gen-heap-size=256",
            "--enable-software-rendering"
        )
        val flutterEngine = FlutterEngine(this, args)

        // Start executing Dart code in the FlutterEngine
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartEntrypoint.createDefault()
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

For a normal Flutter Android app, you can create and initialize a `FlutterEngine`
with your desired flags the same as in the example above, then override
`provideFlutterEngine` in your app's `FlutterActivity` to provide the
configured `FlutterEngine`. For example:

```kotlin
// Your Flutter Android application
class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()

        val args = arrayOf(
            "--trace-startup",
            "--old-gen-heap-size=256",
            "--enable-software-rendering"
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
class MainActivity: FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache
            .getInstance()
            .get(MyApplication.MY_ENGINE_ID)
    }
}
```
