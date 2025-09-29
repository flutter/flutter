# Cross-platform Flags

# TODO(camsim99): Most of these documentation things to the files of flags themselves

# TODO(camsim99): note switches.whatever where you can get the whole vision
## Flags that can be set from the command line:
| Flag     | Description |
| -------- | ----------- |
| `--trace-startup` | Measures startup time and switches to an endless trace buffer. |
| `--start-paused` | Pauses Dart code execution at launch until a debugger is attached. |
| `--vm-service-port` | Sets a custom port for the Dart VM Service. |
| `--disable-service-auth-codes` | Disables authentication codes for VM service communication. |
| `--endless-trace-buffer` | Enables an endless trace buffer for timeline events. |
| `--use-test-fonts` | Uses the Ahem test font for font resolution on desktop test shells. |
| `--enable-dart-profiling` | Enables Dart profiling for use with DevTools. |
| `--profile-startup` | Discards new profiler samples once the buffer is full. |
| `--enable-software-rendering` | Uses Skia software backend for rendering. |
| `--skia-deterministic-rendering` | Ensures deterministic Skia rendering by skipping CPU feature swaps. |
| `--trace-skia` | Enables tracing of Skia GPU calls. |
| `--trace-skia-allowlist=<value>` | Only traces specified Skia event categories. |
| `--trace-systrace` | Traces to the system tracer on supported platforms. |
| `--trace-to-file=<value>` | Writes timeline trace to a file in Perfetto format. |
| `--profile-microtasks` | Collects and logs information about microtasks. |
| `--enable-impeller=true` or `--enable-impeller=false` | Enables or disables the Impeller renderer. |
| `--enable-vulkan-validation` | Loads Vulkan validation layers if available. |
| `--dump-skp-on-shader-compilation` | Dumps SKP files that trigger shader compilations. |
# TODO(camsim99): delete:
| `--cache-sksl` | Caches shaders in SkSL format during development. |
| `--purge-persistent-cache` | Removes all persistent cache files for debugging. |
| `--verbose-logging` | Enables logging at all severity levels. |
| `--dart-flags=<value>` | Passes flags directly to the Dart VM. |
| `--vm-snapshot-data=<path>` | Specifies the path to the VM snapshot data file. |
| `--isolate-snapshot-data=<path>` | Specifies the path to the isolate snapshot data file. |
| `--flutter-assets-dir=<path>` | Sets the directory containing Flutter assets. |
| `--automatically-register-plugins` | Enables automatic registration of plugins with the Flutter engine. |

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

# TODO(camsim99): refactor first table based on this ones order 
| Flag                              | Description                                                      | Can Set in Release Mode? |
|------------------------------------|------------------------------------------------------------------|--------------------------|
| `VMServicePort`                    | Sets the port for the Dart VM Service.                           | No                       | 
| `UseTestFonts`                     | Uses the Ahem test font for font resolution.                     | No                       |
| `EnableSoftwareRendering`          | Uses Skia software backend for rendering.                        | Yes                      |
| `SkiaDeterministicRendering`       | Ensures deterministic Skia rendering by skipping CPU feature swaps. | Yes                  |
| `AotSharedLibraryName`             | Specifies the path to the AOT shared library containing compiled Dart code. | Yes              |
| `SnapshotAssetPath`                | Sets the path to the directory containing snapshot assets.        | Yes                      |
| `VMSnapshotData`                   | Specifies the path to the VM snapshot data file.                 | Yes                      |
| `IsolateSnapshotData`              | Specifies the path to the isolate snapshot data file.            | Yes                      |
| `FlutterAssetsDir`                 | Sets the directory containing Flutter assets.                    | Yes                      |
| `AutomaticallyRegisterPlugins`     | Enables automatic registration of plugins with the Flutter engine. | Yes                   |
| `OldGenHeapSize`                   | Sets the old generation heap size for the Dart VM in megabytes.  | Yes                      |
| `EnableImpeller`                   | Enables or disables the Impeller renderer.                       | Yes                      |
| `EnableVulkanValidation`           | Enables Vulkan validation layers if available.                   | No                       |
| `ImpellerBackend`                  | Specifies the backend to use for Impeller rendering.             | Yes                      |
| `EnableOpenGLGPUTracing`           | Enables GPU tracing for OpenGL.                                  | No                       |
| `EnableVulkanGPUTracing`           | Enables GPU tracing for Vulkan.                                  | No                       |
| `DisableMergedPlatformUIThread`    | (Deprecated) Was used to disable merging of platform and UI threads. | Yes                  |
| `EnableSurfaceControl`             | Enables Android SurfaceControl for rendering.                    | Yes                      |
| `EnableFlutterGPU`                 | Enables the Flutter GPU backend.                                 | Yes                      |
| `ImpellerLazyShaderInitialization` | Enables lazy initialization of Impeller shaders.                 | Yes                      |
| `ImpellerAntialiasLines`           | Enables antialiasing for lines in Impeller.                      | Yes                      |
| `LeakVM`                           | Controls whether the Dart VM is left running after the last shell shuts down. | No               |


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