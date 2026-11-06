# Capturing Flutter startup traces on Android with Perfetto

This doc shows how to record a cold-start trace of a Flutter Android app with [Perfetto](https://perfetto.dev/). You don't need any Flutter flags or code changes to get Flutter's events into the trace. You just need to start recording before the app launches and tell Perfetto which app to trace.

## 1. What to capture

Please send both of the following, each recorded as a cold start on a physical device (not an emulator):

1. **Release build: 2–3 cold-start traces.** These give real startup numbers and show the Android/Java side accurately. They include Flutter engine events, Dart `Timeline` events, and `android.os.Trace` events.
2. **Profile build (`flutter build apk --profile`): 1–2 cold-start traces.** These show what's happening in the Dart/Flutter part of startup. Profile builds are debuggable on Android, so Java/Kotlin code runs slower than in release, but the Dart-side timings are representative. For this build, add the following to `main()` before `runApp()`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

if (kProfileMode) {
  debugProfileBuildsEnabled = true;     // per-widget build slices
  debugProfileLayoutsEnabled = true;    // per-RenderObject layout slices
  debugProfilePaintsEnabled = true;     // per-RenderObject paint slices
  debugProfilePlatformChannels = true;  // "Platform Channel send <channel>#<method>" slices
}
```

For both builds, we'd also strongly recommend adding trace markers around your app's major startup phases, such as `main()` setup, dependency injection or service initialization, config or remote-flag loading, and the first route ([see section 3](#3-add-your-own-trace-events)). Perfetto only shows Dart work that emits trace events, so without these markers your app's own startup code shows up as unlabeled time on the main thread.

## 2. Record a cold-start trace

Save the following as `trace_startup.sh`, replace `com.example.app` with your application ID, and run it once per trace, passing a file name, for example `bash trace_startup.sh release1.perfetto-trace`. The script downloads Perfetto's `record_android_trace` helper and starts recording before cold-starting the app. Afterwards it checks that Flutter's events were captured.

```bash
#!/usr/bin/env bash
PKG=com.example.app   # replace with your application ID
OUT="${1:-startup_$(date +%H%M%S).perfetto-trace}"

curl -sO https://raw.githubusercontent.com/google/perfetto/main/tools/record_android_trace
chmod +x record_android_trace
ACTIVITY=$(adb shell cmd package resolve-activity --brief \
  -a android.intent.action.MAIN -c android.intent.category.LAUNCHER $PKG | tail -n 1 | tr -d '\r')
[[ "$ACTIVITY" == */* ]] || { echo "ERROR: no launcher activity found for $PKG. Check the package name and that the app is installed."; exit 1; }

adb shell am force-stop $PKG   # make sure this is a cold start
adb logcat -c                  # so the check below only sees this run

# Start recording in the background, give it a few seconds to start, then cold-start the app.
./record_android_trace -n -o "$OUT" -t 20s -b 64mb -a $PKG \
  sched freq idle am wm gfx view dalvik binder_driver res disk &
sleep 5
adb shell am start -W -n "$ACTIVITY" | grep -E "Status|TotalTime|Error"
wait   # for the capture to finish and the trace file to be pulled

adb logcat -d | grep -q "ATrace was enabled at startup" \
  && echo "OK: Flutter events were captured in $OUT." \
  || echo "WARNING: Flutter events are missing. Re-run with a longer sleep."
```

Notes:

- `-a <package>` is required. Without it, neither Flutter's events nor `android.os.Trace` events are recorded.
- Recording has to start before the app process launches, which is why the script waits a few seconds before launching the app. If Flutter sees that tracing is active when it starts up, it sends its engine and Dart events to the system trace automatically. The check at the end confirms this happened.
- If you see the warning, or the trace has Android events but no Flutter ones (for example, no `Shell::*` or `Animator::*` slices), the app started before tracing was active. Increase the `sleep 5` and re-run. If release builds always warn but profile builds don't, make sure the app is profileable: `<profileable android:shell="true"/>` inside `<application>` in `AndroidManifest.xml`.
- The script prints `TotalTime`, the launch time in milliseconds. Please send it along with the trace.
- You can also record from https://ui.perfetto.dev under "Record new trace". Add your package under "Atrace apps", start recording, then launch the app.

## 3. Add your own trace events

**Dart** (`import 'dart:developer';`, works in both profile and release builds):

```dart
// Synchronous work: creates a slice on the calling thread.
Timeline.timeSync('loadConfig', () => loadConfig());

// Async work: creates a slice on its own track that spans the awaits.
final task = TimelineTask()..start('initServices');
try {
  await initServices();
} finally {
  task.finish();
}
```

Don't pass an `async` closure to `Timeline.timeSync`, because the slice ends at the first `await`. Use `TimelineTask` for async work.

**Java/Kotlin:** use `android.os.Trace.beginSection()` / `endSection()` for the current thread, and `beginAsyncSection()` / `endAsyncSection()` for work that spans threads. To mark when the first Flutter frame is shown, override `FlutterActivity.onFlutterUiDisplayed()`, call `super.onFlutterUiDisplayed()`, and emit a section there.

**Platform channels in a release build:** `debugProfilePlatformChannels` only works in profile builds. In release, the only option is the `kProfilePlatformChannels` constant in `packages/flutter/lib/src/services/platform_channel.dart`. Using it means editing your local Flutter SDK checkout, setting it to `true`, rebuilding, and reverting afterwards. This is only worth doing if the release trace points to platform-channel traffic.

## 4. What to send us

- All `.perfetto-trace` files, labelled as release or profile.
- The `TotalTime` printed by each run of the script.
- The output of `flutter --version`, plus the device model and Android version.
- What you consider "startup complete" (for example, the first Flutter frame, or the home screen with data loaded).
