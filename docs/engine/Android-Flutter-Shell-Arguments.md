# Cross-platform Flags
## Flags that can be set from the command line:
| Flag     | Description |
| -------- | ----------- |
| `--trace-startup` | Measures startup time on a device. The results should be in the logs. Automatically switches to an endless trace buffer when set. |
| `--start-paused` | Launches app and pauses all Dart code execution until a debugger is connected and it is resumed. |
| `--vm-service-port` | Specifies a custom Dart VM Service port. |

## Flags that must be set in the manifest:
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