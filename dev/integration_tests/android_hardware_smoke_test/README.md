# Android Hardware Smoke Test

An integration and compatibility smoke test suite designed to verify visual rendering correctness on Android hardware.

## 1. Overview & Purpose
The primary objective of the `android_hardware_smoke_test` is to provide a **fully self-contained Android instrumented test suite**.

This allows Android hardware manufacturers (OEMs) to run visual regression, performance, and GPU compatibility tests on a precompiled APK directly on their target devices. **The test execution requires no Flutter SDK, Dart CLI commands, or host-side orchestration.** Feedback is reported directly in standard native Android JUnit test reports.

---

## 2. Structural Differences: `android_hardware_smoke_test` vs. `android_engine_test`

While both suites verify rendering correctness, they are architected differently to support different workflows:

| Dimension | `android_engine_test` | `android_hardware_smoke_test` |
| :--- | :--- | :--- |
| **Verification Location** | **Host-Only** (CI PC) | **Dual-Mode**: On-Device (OEM) & On-Host (CI) |
| **Golden Comparison** | Host-side only against Skia Gold. | **OEM Mode**: In-App pixel comparison against bundled assets.<br>**CI Mode**: Host-side comparisons against repository files. |
| **Device Role** | Passive target rendering static views. | Active participant executing on-device JUnit orchestration. |
| **Target Audience** | Core Engine Contributors & CI Shards. | Android Hardware Manufacturers (OEMs) & CI Shards. |

---

## 3. Dual-Mode Architecture

```
                        ┌──────────────────────────────────────┐
                        │           Test Initiation            │
                        └──────────────────┬───────────────────┘
                                           │
                  ┌────────────────────────┴────────────────────────┐
                  ▼                                                 ▼
       [ Mode A: Instrumented ]                            [ Mode B: Driver ]
    (OEM / Self-Contained Testing)                       (CI / Host-Driven Testing)
                  │                                                 │
                  ▼                                                 ▼
        native Android JUnit                              flutter drive host script
  (FlutterActivityTest / AndroidJUnit4)             (test_driver/driver_test.dart)
                  │                                                 │
                  ▼                                                 ▼
        Native Java Test sends                            Host driver script connects,
     testName over Message Channel                       and requests testName via
                  │                                      driver.requestData()
                  ▼                                                 │
     App renders target state &                                     ▼
   performs local on-device golden                       App renders target state and
   comparison against bundled assets                     returns image bytes over channel
                  │                                                 │
                  ▼                                                 ▼
     App replies status back to                          Host driver script decodes
      Java; JUnit reports result                         image bytes and asserts match
```

### Mode A: Instrumented Mode (OEM / Standalone)
* **Orchestration**: Runs purely on the device under Android `AndroidJUnit4` runner.
* **Execution**: Java JUnit code (`FlutterActivityTest.java`) launches the main activity and sends the test payload over a JSON message channel. The app (`lib/main.dart`) renders the widget, performs a local pixel-by-pixel on-device comparison against baseline images bundled within the APK assets, and replies with the status to the Java runner to pass or fail the JUnit assertion.

### Mode B: Driver Mode (CI / Host-Driven)
* **Orchestration**: Orchestrated by the host PC using `flutter drive`.
* **Execution**: The host script (`test_driver/driver_test.dart`) commands the target app (`integration_test/integration_test_wrapper.dart`) to transition states. The app captures the repaint boundary, base64-encodes it, and streams the bytes back to the host over a WebSocket channel. The host driver decodes the bytes and asserts visual matches against local repository baselines on the host filesystem.

---

## 4. How to Run the Tests

Unlock your connected Android device or emulator and ensure it is active before executing any of these commands.

### A. Mode B: Running via Host Driver (CI / Host-Driven)

This mode is used to execute visual assertions locally on your PC or in CI pipelines, and to manage the local golden baselines.

* **Command to run the driver test suite**:
  ```sh
  # Execute from the android_hardware_smoke_test root directory
  flutter drive -v \
    --driver=test_driver/driver_test.dart \
    --target=integration_test/integration_test_wrapper.dart \
    --no-dds
  ```

* **Command to capture/update reference golden baselines**:
  Running with `UPDATE_GOLDENS=1` writes or overwrites the local PNG baselines under `integration_test/goldens/` on the host:
  ```sh
  UPDATE_GOLDENS=1 flutter drive -v \
    --driver=test_driver/driver_test.dart \
    --target=integration_test/integration_test_wrapper.dart \
    --no-dds
  ```

---

### B. Mode A: Running Instrumented Tests (OEM / Self-Contained)

> [!IMPORTANT]
> **Asset Bundling Precondition**:
> Because instrumented tests run completely standalone on the device, they compare pixels against baseline images bundled as read-only assets inside the APK. You **must** first generate the local baselines under `integration_test/goldens/` using the **Driver Mode (with `UPDATE_GOLDENS=1`)** before compiling and building the instrumented APK.

* **Command to compile and run the native JUnit suite**:
  ```sh
  # Execute from the 'android' subdirectory
  cd android
  ./gradlew :app:connectedDebugAndroidTest \
    -Pandroid.testInstrumentationRunnerArguments.class=com.example.android_hardware_smoke_test.FlutterActivityTest \
    -s
  ```

> [!NOTE]
> **Automated HTML Screenshot Embedding (`embedTestResultImages`)**:
> When running the Gradle command above, a custom Kotlin DSL task named **`embedTestResultImages`** executes automatically once the tests finish. 
> 
> It performs the following actions seamlessly:
> 1. Prevents Gradle from auto-uninstalling the APKs prematurely (via a `gradle.properties` injection).
> 2. Queries the device sandbox cache to discover all rendered `.png` files dynamically.
> 3. Streams the raw binary images directly onto the host PC using zero-copy ADB piping.
> 4. Dynamically parses the generated HTML reports and injects Alternative `<img>` elements right next to the test outcome table cells.
> 5. Executes a manual `adb uninstall` cleanup to leave the target device perfectly clean.
> 
> Once finished, open `app/build/reports/androidTests/connected/debug/index.html` to view the interactive report with all rendering result snapshots embedded natively!

---

### C. Manual Command-Line Debugging (Without Gradle Orchestration)

If you prefer to bypass Gradle entirely for custom debugging, you can manually build, install, and run the instrumentation using raw `adb` shell calls:

1. **Build and Install the packages manually**:
   ```sh
   # Run from the 'android' subdirectory
   cd android
   ./gradlew installDebug installDebugAndroidTest
   ```

2. **Manually launch the native Android instrumentation test**:
   ```sh
   adb shell am instrument -w \
     -e class com.example.android_hardware_smoke_test.FlutterActivityTest \
     com.example.android_hardware_smoke_test.test/androidx.test.runner.AndroidJUnitRunner
   ```

3. **Manually pull the generated snapshot off the device's sandbox**:
   Since the app remains installed during raw `adb` runs, you can copy the rendering result files manually:
   ```sh
   adb shell "run-as com.example.android_hardware_smoke_test cat cache/results/fooTest.png" \
     > integration_test/results/fooTest.png
   ```

---

### D. Running the CI Shard Locally

Since the test suite is registered inside the central repository test orchestrator (`dev/bots/test.dart`), you can execute the full CI runner pipeline locally using standard dev-bot scripts:

```sh
# Run from the root of the Flutter repository
SHARD=android_hardware_smoke_tests bin/cache/dart-sdk/bin/dart dev/bots/test.dart
```
