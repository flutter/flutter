The package includes a number of examples in the `example` subdirectory, which
demonstrate various aspects of invoking Windows APIs, including:

- Invoking C-style APIs, including creating structs and memory management
- Building classic (Win32) desktop UI
- Using callback functions with Win32 APIs
- Invoking COM classes (both `IUnknown` and `IDispatch` interface types)
- Accessing the Windows Runtime APIs
- Integrating Windows code with Flutter

Other examples of packages that use Win32 can be found on pub.dev, at the
following location:
[https://pub.dev/packages?q=dependency%3Awin32](https://pub.dev/packages?q=dependency%3Awin32).

## Windows system APIs (kernel32)

| Example               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `credentials.dart`    | Adds a credential to the store and retrieves it           |
| `dump.dart`           | Use debugger libraries to print DLL exported functions    |
| `dynamic_load.dart`   | Demonstrate loading a DLL and calling it at runtime       |
| `filever.dart`        | Getting file version information from the file resource   |
| `manifest\`           | Demonstrates the use of app manifests for compiled apps   |
| `modules.dart`        | Enumerates all loaded modules on the current system       |
| `pipe.dart`           | Shows use of named pipes for interprocess communication   |
| `registry.dart`       | Demonstrates querying the registry for values             |
| `vt.dart`             | Shows virtual terminal sequences                          |
| `wsl.dart`            | Retrieve information from a WSL instance through APIs     |

## Accessing local hardware and devices

| Example               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `bluetooth.dart`      | Demonstrate enumerating Bluetooth devices                 |
| `bluetoothle.dart`    | Enumerate Bluetooth LE (Low Energy) devices               |
| `devices.dart`        | Uses volume management APIs to list all disk devices      |
| `diskinfo.dart`       | Use `DeviceIoControl()` for direct device operations      |
| `gamepad.dart`        | Show which gamepads are connected                         |
| `midi.dart`           | Demonstrates MIDI playback using MCI commands             |
| `monitor.dart`        | Uses DDC and monitor-config API to get monitor caps       |
| `play_sound.dart`     | Plays a WAV file through the Windows `PlaySound` API      |
| `printer_list.dart`   | Enumerate available printers on the Windows system        |
| `printer_raw.dart`    | Sends RAW data directly to a Windows Printer              |
| `serial.dart`         | Demonstrates serial port management                       |
| `setupapi.dart`       | Show using setup APIs to retrieve device interfaces       |
| `speech.dart`         | Use Windows speech engine for text-to-speech              |
| `sysinfo.dart`        | Examples of getting device information from native C APIs |
| `wasapi.dart`         | Demonstrates sound generation with WASAPI library         |

## Windows shell manipulation (shell32)

| Example               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `knownfolder.dart`    | Retrieves known folders from the current user profile     |
| `magnifier.dart`      | Provides a magnifier window using the Magnification API   |
| `recycle_bin.dart`    | Queries the recycle bin and adds an item to it            |
| `screenshot.dart`     | Takes a screenshot of the current desktop                 |
| `shortcut.dart`       | Demonstrates creating a Windows shell link                |
| `wallpaper.dart`      | Shows what wallpaper and background color are set         |

## Win32-style UI development (user32, gdi32, commdlg32)

| Example               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `hello.dart`          | Basic Petzoldian "hello world" Win32 app                  |
| `msgbox.dart`         | Demonstrates a MessageBox from the console                |
| `commdlg.dart`        | Demonstrates using the color chooser common dialog box    |
| `customwin.dart`      | Displays a non-rectangular window                         |
| `dialog.dart`         | Create a custom dialog box in code                        |
| `customtitlebar.dart` | Demonstrates creation of owner-draw title bar region      |
| `dialogshow.dart`     | Creates a common item dialog (file picker) using COM      |
| `notepad\`            | Lightweight replica of the Windows notepad applet         |
| `paint.dart`          | Demonstrates simple GDI drawing and min/max window sizing |
| `scroll.dart`         | Example of horizontal and vertical scrolling text window  |
| `sendinput.dart`      | Sends keyboard and mouse input to another window          |
| `snake.dart`          | Snake game using various GDI features                     |
| `taskdialog.dart`     | Demonstrates using modern task dialog boxes               |
| `tetris\main.dart`    | Port of an open-source Tetris game to Dart                |
| `window.dart`         | Enumerates open windows and basic window manipulation     |

## COM and Windows Runtime APIs

| Example               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `calendar.dart`       | Gets information about the calendar from a WinRT API      |
| `com_context.dart`    | Shows interaction of Dart isolates and COM apartments     |
| `com_demo.dart`       | Demonstrates COM object reference counting                |
| `geolocation.dart`    | Retrieve geolocation coordinates via WinRT APIs           |
| `guid.dart`           | Creates a globally unique identifier (GUID)               |
| `idispatch.dart`      | Demonstrates calling a method using `IDispatch`           |
| `winmd.dart`          | Interrogate Windows Runtime types                         |
| `winrt_picker.dart`   | Demonstrates picking a file through a WinRT API           |
| `wmi_perf.dart`       | Uses WMI to retrieve performance counters                 |
| `wmi_wql.dart`        | Uses WMI to retrieve information using WQL                |

## Flutter

| Example               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `explorer\`           | Example Flutter app that uses Win32 file picker APIs      |
