# Cross-platform Flags
## Flags that can be set from the command line:
| Flag     | Description |
| -------- | ----------- |
| `--trace-startup` | Measures startup time on a device. The results should be in the logs. Automatically switches to an endless trace buffer when set. |
| `--start-paused` | Launches app and pauses all Dart code execution until a debugger is connected and it is resumed. |
| `--vm-service-port` | Specifies a custom Dart VM Service port. |
| `--disable-service-auth-codes` | Disable the requirement for authentication codes for communicating with the VM service. |
| `--endless-trace-buffer` | Enable an endless trace buffer so that old events can be viewed. |
| `--use-test-fonts` | Will make font resolution default to the Ahem test font on all platforms. Only available on the desktop test shells. |
| `--enable-dart-profiling` | Enable Dart profiling. Profiling information can be viewed from Dart / Flutter DevTools. |
| `--profile-startup` | Make the profiler discard new samples once the profiler sample buffer is full. When this flag is not set, the profiler sample buffer is used as a ring buffer, meaning that once it is full, new samples start overwriting the oldest ones. This switch is only meaningful when set in conjunction with --enable-dart-profiling. |
| `--enable-software-rendering` | Enable rendering using the Skia software backend. This is useful when testing Flutter on emulators. By default, Flutter will attempt to either use OpenGL, Metal, or Vulkan. |
| `--skia-deterministic-rendering` | Skips the call to SkGraphics::Init(), thus avoiding swapping out some Skia function pointers based on available CPU features. This is used to obtain 100% deterministic behavior in Skia rendering. |
| `--trace-skia` | Trace Skia calls. This is useful when debugging the GPU thread. By default, Skia tracing is not enabled to reduce the number of traced events. |
| `--trace-skia-allowlist=<value>` | Filters out all Skia trace event categories except those that are specified in this comma separated list. |
| `--trace-systrace` | Trace to the system tracer (instead of the timeline) on platforms where such a tracer is available. Currently only supported on Android and Fuchsia. |
| `--trace-to-file=<value>` | Write the timeline trace to a file at the specified path. The file will be in Perfetto's proto format; it will be possible to load the file into Perfetto's trace viewer. |
| `--profile-microtasks` | Enable collection of information about each microtask. Information about completed microtasks will be written to the "Microtask" timeline stream. Information about queued microtasks will be accessible from Dart / Flutter DevTools. |
| `--enable-impeller=true` or `--enable-impeller=false` | Enable the Impeller renderer on supported platforms. Ignored if Impeller is not supported on the platform. |
| `--enable-vulkan-validation` | Enable loading Vulkan validation layers. The layers must be available to the application and loadable. On non-Vulkan backends, this flag does nothing. |
| `--dump-skp-on-shader-compilation` | Automatically dump the skp that triggers new shader compilations. This is useful for writing custom ShaderWarmUp to reduce jank. By default, this is not enabled to reduce the overhead. |
| `--cache-sksl` | Only cache the shader in SkSL instead of binary or GLSL. This should only be used during development phases. The generated SkSLs can later be used in the release build for shader precompilation at launch in order to eliminate the shader-compile jank. |
| `--purge-persistent-cache` | Remove all existing persistent cache. This is mainly for debugging purposes such as reproducing the shader compilation jank. |
| `--verbose-logging` | By default, only errors are logged. This flag enables logging at all severity levels. This is NOT a per shell flag and affects log levels for all shells in the process. |
| `--dart-flags=<value>` | Flags passed directly to the Dart VM without being interpreted by the Flutter shell. |

# TODO(camsim99): Note that all command line args could be settable in manifest (at least those deleted from FlutterShellArgs). Please audit and figure out what makes sense. I can use other platforms as guidance.
## Flags that can be set in the manifest:
| Flag     | Description |
| -------- | ----------- |



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