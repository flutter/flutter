The package includes a number of examples in the `example` subdirectory. These
examples use the Win32 API for all UI display and (unless mentioned) do not
require Flutter.

| Example               | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `hello.dart`          | Basic Petzoldian "hello world" Win32 app                  |
| `bluetooth.dart`      | Demonstrate enumerating Bluetooth devices                 |
| `bluetoothle.dart`    | Enumerate Bluetooth LE (Low Energy) devices               |
| `calendar.dart`       | Gets information about the calendar from a WinRT API      |
| `commdlg.dart`        | Demonstrates using the color chooser common dialog box    |
| `credentials.dart`    | Adds a credential to the store and retrieves it           |
| `customtitlebar.dart` | Demonstrates creation of owner-draw title bar region      |
| `customwin.dart`      | Displays a non-rectangular window                         |
| `devices.dart`        | Uses volume management APIs to list all disk devices      |
| `dialog.dart`         | Create a custom dialog box in code                        |
| `dialogshow.dart`     | Creates a common item dialog (file picker) using COM      |
| `diskinfo.dart`       | Use `DeviceIoControl()` for direct device operations      |
| `dump.dart`           | Use debugger libraries to print DLL exported functions    |
| `dynamic_load.dart`   | Demonstrate loading a DLL and calling it at runtime       |
| `explorer\`           | Example Flutter app that uses Win32 file picker APIs      |
| `filever.dart`        | Getting file version information from the file resource   |
| `gamepad.dart`        | Show which gamepads are connected                         |
| `guid.dart`           | Creates a globally unique identifier (GUID)               |
| `idispatch.dart`      | Demonstrates calling a method using `IDispatch`           |
| `knownfolder.dart`    | Retrieves known folders from the current user profile     |
| `magnifier.dart`      | Provides a magnifier window using the Magnification API   |
| `manifest\`           | Demonstrates the use of app manifests for compiled apps   |
| `midi.dart`           | Demonstrates MIDI playback using MCI commands             |
| `modules.dart`        | Enumerates all loaded modules on the current system       |
| `monitor.dart`        | Uses DDC and monitor-config API to get monitor caps       |
| `msgbox.dart`         | Demonstrates a MessageBox from the console                |
| `notepad\`            | Lightweight replica of the Windows notepad applet         |
| `paint.dart`          | Demonstrates simple GDI drawing and min/max window sizing |
| `pipe.dart`           | Shows use of named pipes for interprocess communication   |
| `play_sound.dart`     | Plays a WAV file through the Windows `PlaySound` API      |
| `printer_list.dart`   | Enumerate available printers on the Windows system        |
| `printer_raw.dart`    | Sends RAW data directly to a Windows Printer              |
| `registry.dart`       | Demonstrates querying the registry for values             |
| `screenshot.dart`     | Takes a screenshot of the current desktop                 |
| `scroll.dart`         | Example of horizontal and vertical scrolling text window  |
| `sendinput.dart`      | Sends keyboard and mouse input to another window          |
| `serial.dart`         | Demonstrates serial port management                       |
| `setupapi.dart`       | Show using setup APIs to retrieve device interfaces       |
| `shortcut.dart`       | Demonstrates creating a Windows shell link                |
| `snake.dart`          | Snake game using various GDI features                     |
| `speech.dart`         | Use Windows speech engine for text-to-speech              |
| `sysinfo.dart`        | Examples of getting device information from native C APIs |
| `taskdialog.dart`     | Demonstrates using modern task dialog boxes               |
| `tetris\main.dart`    | Port of an open-source Tetris game to Dart                |
| `vt.dart`             | Shows virtual terminal sequences                          |
| `wallpaper.dart`      | Shows what wallpaper and background color are set         |
| `wasapi.dart`         | Demonstrates sound generation with WASAPI library         |
| `window.dart`         | Enumerates open windows and basic window manipulation     |
| `winmd.dart`          | Interrogate Windows Runtime types                         |
| `wmi_perf.dart`       | Uses WMI to retrieve performance counters                 |
| `wmi_wql.dart`        | Uses WMI to retrieve information using WQL                |
| `wsl.dart`            | Retrieve information from a WSL instance through APIs     |
