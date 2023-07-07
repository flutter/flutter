## Examples

The package includes a number of examples in the `example` subdirectory. These
examples use the Win32 API for all UI display and do not require Flutter.

| Example            | Description                                               |
| ------------------ | --------------------------------------------------------- |
| `hello.dart`       | Basic Petzoldian "hello world" Win32 app                  |
| `paint.dart`       | Demonstrates simple GDI drawing and min/max window sizing |
| `scroll.dart`      | Example of horizontal and vertical scrolling text window  |
| `console.dart`     | Shows usage of console APIs                               |
| `msgbox.dart`      | Demonstrates a MessageBox from the console                |
| `calendar.dart`    | Gets information about the calendar from a WinRT API      |
| `sendinput.dart`   | Sends keyboard and mouse input to another window          |
| `knownfolder.dart` | Retrieves known folders from the current user profile     |
| `window.dart`      | Enumerates open windows and basic window manipulation     |
| `monitor.dart`     | Uses DDC and monitor-config API to get monitor caps       |
| `wallpaper.dart`   | Shows what wallpaper and background color are set         |
| `guid.dart`        | Creates a globally unique identifier (GUID)               |
| `devices.dart`     | Uses volume management APIs to list all disk devices      |
| `modules.dart`     | Enumerates all loaded modules on the current system       |
| `snake.dart`       | Snake game using various GDI features                     |
| `dialogshow.dart`  | Creates a common item dialog (file picker) using COM      |
| `wmi.dart`         | Using WMI from COM to retrieve device/OS information      |
| `sysinfo.dart`     | Examples of getting device information from native C APIs |
| `manifest\`        | Demonstrates the use of app manifests for compiled apps   |
| `winmd.dart`       | Interrogate Windows Runtime types                         |
| `credentials.dart` | Adds a credential to the store and retrieves it           |
| `dynamic_load.dart`| Demonstrate loading a DLL and calling it at runtime       |
| `tetris\main.dart` | Port of an open-source Tetris game to Dart                |
| `notepad\notepad.dart` | Lightweight replica of the Windows notepad applet     |

### Flutter samples

The `explorer\` subdirectory contains an example of a simple Flutter app that
uses the volume management Win32 APIs to find the disk drives connected to your
computer and their volume IDs and attached paths.

## Acknowledgements

The Tetris example listed above is a fuller worked example of a reasonably
complete program that uses the Dart Win32 package. It is a port of a C version
of the game by Chang-Hung Liang. [More information...](tetris/README.md)

The [C implementation of the Snake game](https://github.com/davidejones/winsnake)
is by David Jones, and is ported with his permission.

The original C version of the Notepad example was originally authored by Charles
Petzold, and is kindly [licensed by him](https://www.charlespetzold.com/faq.html)
without restriction.
