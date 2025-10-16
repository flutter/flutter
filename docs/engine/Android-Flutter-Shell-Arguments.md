# TODO(camsim99): Note that all command line args could be settable in manifest (at least those deleted from FlutterShellArgs). Please audit and figure out what makes sense. I can use other platforms as guidance.
## Flags that can be set in the manifest:
All flags but be prefixed with package name `io.flutter.embedding.android`, e.g. to specify the `OldGenHeapSize` flag with size 322w, you would place
the following in your manifest:
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

# TODO(camsim99): Rework this note.
> **Note:**
> As of [version/commit], setting Flutter shell arguments via Android Intents is no longer supported.
>
> For **per-launch dynamic configuration** of shell arguments (such as `--vm-service-port`), consider the following workarounds:
>
> - **Custom Loader:** Implement a custom Android Activity or Service that reads configuration (e.g., from an intent extra, config file, or other runtime source) and programmatically sets shell arguments before initializing the Flutter engine. This allows you to control arguments on a per-launch basis, even when launching Flutter components from native Android code.
> - **Multiple APKs:** Build and distribute separate APKs, each with different shell argument values set in the Android manifest. Use the appropriate APK for each scenario.
>
> For **static configuration** (the same arguments for all launches), continue to use the Android manifest.
>
> Per-launch dynamic configuration is no longer possible via Intents. If you require this flexibility, use a custom loader or multiple APKs as described