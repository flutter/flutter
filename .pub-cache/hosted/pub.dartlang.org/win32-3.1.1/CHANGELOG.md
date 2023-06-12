## 3.1.1

- Fix documentation bug (@timsneath)
- Add URI support to the WinRT generator (@halildurmus)

## 3.1.0

- Fixed memory leaks in COM and WinRT code when an exception is generated.
- Update to the latest Win32 metadata from Microsoft.
- [BREAKING CHANGE] The WinSock APIs now use upper cased naming for structs. For
  example, `hostent` is now `HOSTENT`. This will only affect you if you
  explicitly imported `win32/winsock2.dart`.
- [BREAKING CHANGE] TouchInputParameters is now upper-cased in the metadata.

## 3.0.1

- Improve projection of Map, Vector, and reference Windows Runtime types, with
  thanks as ever to Halil İbrahim Durmuş (@halildurmus).
- Add CryptoAPI functions (`CryptProtectData`, `CryptProtectMemory` etc.)
- Add pointer and touch APIs
- Fix WinRT FilePicker demo
- Add raw printer API example
- Remove console example `console.dart` (use
  <https://pub.dev/packages/dart_console> instead).

## 3.0.0

- This release includes an overhaul of the COM and WinRT API generation, as
  described below. Apps and packages that call traditional Win32 APIs should not
  require changes, but apps that use COM or the highly-experimental WinRT APIs
  should expect to make changes.
- [BREAKING CHANGE] WinRT APIs have been moved to a separate library. This
  provides isolation for apps that only use traditional APIs (Win32/COM) from
  the more experimental WinRT APIs. To use WinRT from your code, change your
  import statement to `import 'package:win32/winrt.dart';`. The WinRT library
  also exports all Win32 APIs, so you don't have to import both libraries.
- [BREAKING CHANGE] COM and Windows Runtime methods and properties are now
  camelCased, not TitleCased. This is inconvenient, but it avoids a whole class
  of name clashes and aligns COM and WinRT APIs more closely with Dart idioms.
  As the projections get smarter with more helpers, we think this is the right
  call for the future and worth a one-time tax to fix.
- [BREAKING CHANGE] You can now cast to a new COM interface without needing the
  IID for the target interface. Instead of:

```dart
  final modalWindow = IModalWindow(fileDialog.toInterface(IID_IModalWindow));
```

write:

```dart
  final modalWindow = IModalWindow.from(fileDialog);
```

- [BREAKING CHANGE] WinRT classes now support projection of `List`s and
  `String`s directly.
- [BREAKING CHANGE] The WinRT `fromPointer` method is now `fromRawPointer`.
- `GUIDFromString` now supports an optional custom allocator parameter.
- Added various APIs from iphlpapi.dll for tracking and renewing IP addresses.
- Added `DisableThreadLibraryCalls`, `FindStringOrdinal`, `GetConsoleCP`,
  `GetConsoleOutputCP`, `GetModuleHandleExW`, `GetNumberOfConsoleInputEvents`,
  `GetVolumeInformation`, `GetVolumeInformationByHandle`, `PeekConsoleInput`,
  `ReadConsoleInputW`, `SetErrorMode`, `SetThreadErrorMode`, `SizeofResource`
  APIs from kernel32.dll
- Added `GetClassFile` API from ole32.dll
- Added `SetupDiGetDeviceInstanceId`, `SetupDiGetDeviceRegistryPropertyW` APIs
  from setupapi.dll
- Added `GetAltTabInfoW`, `GetClassNameW`, `GetGUIThreadInfo` APIs from
  user32.dll
- Added various foundational WinRT types, including `IIterable`, `IIterator`,
  `IKeyValuePair`, `IMapView`, `IVector`, `IVectorView`, `IPropertyValue`,
  `IReference`, with tremendous thanks again to @halildurmus, who has driven
  much of the recent WinRT work.
- Major reworking of the WinRT generation code, thanks to @halildurmus.

## 2.7.0

- [BREAKING CHANGE] Major work on Windows Runtime APIs, with huge thanks to
  Halil İbrahim Durmuş (@halildurmus). Breaking changes are limited to WinRT
  APIs, which are now more idiomatic for Dart. Includes full implementation of
  System.Globalization.Calendar that is the new reference design for WinRT APIs.
- Restructure generation code into a separate package in tool\generator.
- Use super parameters introduced in Dart 2.17, with matching dependency
  upgrade.
- Tidy up examples to include consistent headers.
- All files now have lower case names (e.g. IUnknown.dart -> iunknown.dart)

## 2.6.1

- Improve pana compliance

## 2.6.0

- Add support for returning vectors from Windows Runtime APIs (#406, thanks to
  @halildurmus)
- Automatically convert Windows Runtime date properties to Dart DateTime
  equivalents (#418, thanks to @halildurmus)
- Add additional documentation on Windows Runtime APIs
- Update IDispatch sample to show how to supply parameters
- Add example for Windows Audio Session API (#422, thanks to @postacik)
- Fix an error with strings in structs (#425, thanks to @postacik)
- Update contributor documentation

## 2.5.2

- Add example for monitor EDID data (#393, thanks to @krjw-eyev)
- Expand Bluetooth example (#397, thanks to @Sunbreak)
- Fix a comment typo (#398, thanks to @gaddlord)
- Improve fidelity of WinRT Calendar class and more tests (#396, #404, #405,
  #412 thanks to @halildurmus)
- Add additional spell checker COM interfaces
- Add example for an owner-draw (custom) titlebar
- Add new Wbem WMI interfaces
- Add example of WMI high-performance counters
- Add new theming APIs
- Update to latest Windows metadata (with a couple of minor changes to signed
  ints in MOUSEDATA and send()).

## 2.5.1

- Add GetProcessTimes (#396, thanks to @halildurmus)
- Add device interface and device class GUIDs
- Add examples for Bluetooth LE and Setup APIs (#390, #392, thanks to @Sunbreak)
- Fix setup APIs to project HDEVINFO correctly

## 2.5.0

- [BREAKING CHANGE] Use new projection tooling for WinRT classes. WinRT APIs are
  still in development and should be considered experimental; expect volatility
  as the projection tools mature and map types like String and DateTime, as well
  as WinRT primitives such as IVectorView, onto their Dart equivalents. (This
  doesn't affect COM and Win32 APIs, which can largely be considered stable,
  with the exception of changes to the underlying metadata exposed by
  Microsoft.)
- Add setupapi APIs, which were not being successfully projected. (#383, with
  thanks to @Sunbreak.) Add test to prevent that happening again.
- Add additional setup APIs (#386, with further thanks to @Sunbreak).
- Remove `tools/` folder from published package to reduce download overhead.

## 2.4.4

- Fix broken doc links.

## 2.4.3

- Add Bluetooth LE APIs

## 2.4.2

- Add speech API (SAPI) support and sample
- Add Windows Audio Session API (WASAPI) support
- Automate more struct generation
- Apply more lints to source code
- Add GetUserName and update sysinfo example

## 2.4.1

- Fix import error for gamepad APIs
- Add gamepad example

## 2.4.0

- Added various inline functions, tidied up projection logic.

## 2.3.11

- Add gamepad APIs

## 2.3.10

- Add DPI_AWARENESS_CONTEXT enum values.

## 2.3.9

- Add a few minor constants and handle typedefs. Nothing to see here.

## 2.3.8

- Update package:ffi minimum version to 1.1.0, allowing use of arena
- Hide `Char` within generated structs.g.dart in prep for new FFI feature.

## 2.3.7

- Declare platform support using new `platforms:` declaration in pubspec.yaml
- Update minimum version to Dart 2.15.0 and use constructor tearoffs

## 2.3.6

- Add RegRenameKey.

## 2.3.5

- Add FileTimeToSystemTime and SystemTimeToFileTime.

## 2.3.4

- Added Windows Subsystem for Linux APIs (#342), with thanks to @ElMoribond.
  Add a new example that shows how to use them.
- Added SetEvent (#343) and CreateIcon (#344), with thanks to @untp.
- Add typedef for `HKEY`.
- Add more optional lints.
- Tweaked Explorer example.

## 2.3.3

- Added CreateThread, CreateRemoteThread, CreateRemoteThreadEx() per request
- Added GetMachineTypeAttributes and added logic for Windows 11.

## 2.3.2

- Added CreateDIBSection per request.
- Upgraded to latest published Windows metadata from Microsoft, which modifies
  the signature of some registry-related APIs from Int32 to Uint32 for better
  accuracy with the original API.
- Updated to the latest code generator, ported back from the v3 code.

## 2.3.1

- Use automatic code generator for most structs. This may be a breaking change
  if you use the Bluetooth APIs, since `BLUETOOTH_ADDRESS.rgBytes` is now an
  `Array<Uint8>` instead of a `List<int>`. This is more accurate, but will
  require minor code change.
- Add additional raw input constants

## 2.3.0

- Completely overhauled the metadata generation tooling (tools\projection
  directory). The code is much better structured, with each layer (type ->
  parameter -> method -> class) in its own `___Projection` class. Fixed a number
  of errors in the process, such as the assumption that all enums are of type
  `Uint32`.
- Rewrote several complex structs to use the new `Union` FFI type introduced in
  Dart 2.14 (and updated the minimum version accordingly). Code that uses the
  `INPUT` struct will need to be slightly modified, since the `mi`/`ki`/`hi`
  fields are now nested rather than provided as an extension property.
- Cleaned up some COM `Pointer` types to be more explicit.
- Add raw input APIs
- Add low-level keyboard hooks example

## 2.2.10

- Add Windows 11 rounded corner window support along with sample (check Flutter
  app in example\explorer)
- Add magnifier APIs and example

## 2.2.9

- Add some missing GDI functions

## 2.2.8

- Add Native Wifi APIs (#299)

## 2.2.7

- Added ResetEvent and complete `OVERLAPPED` struct (#295)
- Added more virtual memory functions (#297)

## 2.2.6

- Add some requested APIs thanks to contributions from @ilopX, in particular
  a new sample for enumerating locally installed printers.
- Added ExtractAssociatedIcon, with thanks to @halildurmus.

## 2.2.5

- Add more DWM APIs, including `DwmSetWindowAttribute`.

## 2.2.4

- Add various DWM and subclassing APIs

## 2.2.3

- Lazily evaluate `lookupFunction` FFI calls for improved performance.
- Add APIs for hooks and a few extra kernel32 APIs
- Add some more tests.

## 2.2.2

- Add Windows Spooler library support.

## 2.2.1

- Add initial support for the Windows Socket library (winsock2).

## 2.2.0

- Fixes convertToHString to return an int, since `HSTRING`s are handles. This is
  a breaking change for any apps that use WinRT APIs, but given the limited
  availability of WinRT classes that fall into this category, updating only the
  minor version.
- Add low-level Device IO and structured storage APIs and diskinfo.dart sample.

## 2.1.5

- Add smart card reader support.

## 2.1.4

- Add helper functions for COM along with extra documentation.

## 2.1.3

- Fix bug in shell COM APIs.
- Add examples for shortcut creation and named pipes.

## 2.1.2

- Add serial port comms APIs
- Add additional shell COM APIs

## 2.1.1

- Work around FFI regression in Dart master and dev builds.

## 2.1.0

- Upgrade to Dart 2.13, which supports packed structs and arrays in FFI. This
  enables support for more automated generation of structs, which in turn
  increases development velocity for this package.

- Other APIs included in this release include:
  - More complete Bluetooth support
  - MIDI support
  - High DPI support
  - `IDispatch` support
  - Many more core user32 APIs

## 2.0.5

- Add some debugging APIs to allow enumerating exported symbols, along with a
  sample (`dump.dart`).
- Free memory allocations in samples.
- Use latest version of Win32 metadata from winmd package, and generate most
  structs automatically using this metadata.
- Generate COM helper classes wherever metadata supports it, instead of
  requiring a manual decorator.
- Add about 20 new kernel32 APIs.

## 2.0.4

- Add network events, thanks to a contribution from @sunbreak.
- Update COM vtable generation, thanks to a contribution from @bonukai.
- Update to use the latest WinMD package.

## 2.0.3

- Add spellchecking COM APIs, thanks to a contribution from @bonukai.

## 2.0.2

- Adds named pipe APIs to support projects like TerminalStudio/pty.

## 2.0.1

- Adds a demo of custom window shapes.
- Removes Windows Metadata classes (now in the `winmd` package). This is a
  breaking change, but it's not anticipated to be a problem since these classes
  are only used for code generation.
- Update to latest WinMD package
- Add shell folder APIs
- Add registry key APIs

## 2.0.0

- Stable version w/ sound null safety.
- Update to ffi 1.0.0 and address breaking changes.
- 100+ new APIs in kernel32, user32, ole32, advapi32, shell32 and gdi32, as well
  as a series of COM interfaces.
- Rework API wrapper to use functions instead of properties
- New JSON-based metadata format for Win32 APIs that supports API sets and
  minimum versions, and more robust tooling for loading and saving metadata
- Migrated Windows Runtime APIs into core unmanaged metadata
- Add waveOut* APIs from winmm.dll (thanks @slightfoot)
- Make VARIANT more representative of the underlying type.
- Add DLGTEMPLATE and DLGITEMTEMPLATE structs with extension methods.
- Add more tests.
- Add dialog box example and supporting extension methods
- New shell tray notification example (thanks @ilopX)
- Better documentation of constants and callbacks

## 1.7.5

- WinMM: Add PlaySound (thanks @Hexer10)

## 1.7.4

- Add SysAllocString, SysFreeString, SysStringByteLen, SysStringLen,
  SHCreateItemFromParsingName
- Rename VARIANT_POINTER to VARIANT

## 1.7.3

- Expand Win32 API documentation.
- New APIs:
  - User32: ClipCursor, CopyIcon, DestroyIcon, DrawIcon, GetCursor,
    GetCursorPos, GetSystemMenu, SetMenuInfo, SetMenuItemInfo, ShowCursor

## 1.7.2

- Add Win32 API documentation and a couple of minor APIs.

## 1.7.1

- Add version information APIs and example.

## 1.7.0

- Changed how the C-style APIs are generated. This should result in far better
  code smarts in your editor, as well as major improvements to the
  auto-generated documentation.
- Added many new APIs, including GetCurrentProcess and GetModuleFileName

## 1.6.10

- New APIs
  - Shell: LockWorkstation, SHEmptyRecycleBin, SHGetDiskFreeSpaceEx,
    SHGetDriveMedia, SHQueryRecycleBin, InitCommonControlsEx, DrawStatusText
  - Add high-precision timing APIs: QueryPerformanceFrequency,
    QueryPerformanceCounter
  - User32: SetParent, CreateWindow macro, MonitorFromPoint, SetWindowsLongPtr
  - Kernel: Add SystemParametersInfo and related constants
  - Kernel: Add EnumProcessModulesEx (thanks @Hexer10)
- Samples
  - Add example of using app manifests to declare support for UAC permissions
    and Windows 10 opt-in behavior
- Windows Runtime metadata
  - Greatly expand WinMD utility to generate APIs directly from Windows Metadata
  - Autogenerate all Windows Runtime classes except ICalendar and
    IFileOpenPicker from metadata
- Code tidy up
  - Add more tests
  - Go through all the code with a stricter linter
  - Update README with screenshots and examples
  - Update Flutter Windows examples to the v4 template

## 1.6.9

- Add credential management APIs (thanks @hpoul)
- Add battery and power management APIs
- Overhaul HRESULTs and add more tests

## 1.6.8

- Add font enumeration example
- Experiment with hosting documentation on GitHub

## 1.6.7

- Add basic registry checks
- Add initial Bluetooth discovery support
- Add a system information sample
- Guard tests so that they work on Windows 7
- Add some shell APIs and more tests

## 1.6.6

- Add more process management APIs
- Add high level monitor configuration API

## 1.6.5

- Add a broader array of console APIs
- Add a wallpaper example

## 1.6.4

- Lots of documentation and linter cleanup

## 1.6.3

- Add TaskDialog and dynamic library loading APIs
- Add dynamic load and Windows Runtime metadata samples
- Fix an annoying bug with `WindowsDeleteString` usage
- Add more tests and restructure code
- More library-level documentation
- Add script for generating classes

## 1.6.2

- Clean up some of the generated documentation

## 1.6.1

- Lots of minor refactoring and tidy up
- Some early WinMD parsing
- Add many more unit tests

## 1.6.0

- Add WinRT examples, including Windows.Globalization.Calendar and
  Windows.Storage.Pickers.FileOpenPicker
- Add various process management and kernel APIs: CloseHandle, EnumProcesses,
  EnumProcessModules, GetModuleBaseName, GetModuleFileNameExt, OpenProcess,
  ReadProcessMemory and WriteProcessMemory.
- Add modules.dart sample
- Lots of refactoring and tidy up work.

## 1.5.1

- Add GetTempPath()

## 1.5.0

- Use automated Dart tool to generate all COM classes
- Add IFileDialogCustomize, IShellItem2, IShellItemArray, IShellItemFilter
- Fill out all the class methods
- Fix some embarrassing bugs

## 1.4.2

- Fix a few bugs
- Add support for desktop background management with IDesktopWallpaper

## 1.4.1

- Expand COM support to include IShellItemArray and various WMI classes

## 1.4.0

- Add COM support
- Add implementations for IOpenFileDialog, IFileDialog, IModalWindow,
 IShellItem, IUnknown
- Add common item dialog example

## 1.3.2

- Add Snake GDI example
- Add PeekMessage, MoveTo, VirtualAlloc/Free, StretchDibBits, Beep
- Tidy up code and test

## 1.3.1

- Add RegisterWindowMessage
- Fix bugs in ACCEL and FINDREPLACE structs
- Fix various bugs in Notepad example

## 1.3.0

- Add notepad example
- Add 20+ new APIs for common dialogs, message sending, accelerators,
  menus, fonts and GDI object manipulation
- Fix APIs to be 32-bit safe
- Fix some minor bugs

## 1.2.6

- Add window enumeration (FindWindowEx, EnumWindows, IsWindowVisible,
  GetWindowText, GetWindowTextLength) and example

## 1.2.5

- Added Flutter example
- Added common dialog example

## 1.2.4

- Added volume management APIs

## 1.2.3

- Add scrolling APIs and example
- Add 'new' known folder API
- Add some basic unit tests

## 1.2.2

- Add known folder plus GUID classes

## 1.2.1

- Added SendInput, Sleep and ShellExecute

## 1.2.0

- Implemented a good sample of GDI calls
- Added support for timers
- Added virtual keyboard constants
- Added a GDI paint sample
- Added a more comprehensive sample game (Tetris)

## 1.1.1

- Add class styles
- Match recommended package structure per pub.dev

## 1.1.0

- Added MessageBox and console APIs

## 1.0.0

- Initial version
