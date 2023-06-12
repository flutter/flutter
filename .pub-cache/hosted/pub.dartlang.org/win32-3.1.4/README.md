![Dart/Win32](https://github.com/timsneath/win32/blob/main/doc/images/win32.png?raw=true)

A package that wraps some of the most common Win32 API calls using FFI to make
them accessible to Dart code without requiring a C compiler or the Windows SDK.

[![pub package](https://img.shields.io/pub/v/win32.svg)](https://pub.dev/packages/win32)
[![Language](https://img.shields.io/badge/language-Dart-blue.svg)](https://dart.dev)
![Build](https://github.com/timsneath/win32/workflows/Build/badge.svg)

In addition to exposing the APIs themselves, this package offers a variety of
instructive examples for more complex FFI usage scenarios.

By design, this package provides minimal modifications to the Win32 API to
support Dart idioms. The goal is to provide high familiarity to an existing
Windows developer. Other Dart packages may build on these primitives to provide
a friendly API for Dart and Flutter developers. A good example of that is
[filepicker_windows](https://pub.dev/packages/filepicker_windows), which offers
a common item dialog suitable for incorporation into an existing Flutter app.

## Usage

This package lets you write apps that use the Windows API directly from Dart, by
wrapping common Win32, COM and Windows Runtime APIs using Dart FFI.

You could use it to call a Win32 API like
[EnumFontFamiliesEx](https://docs.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-enumfontfamiliesexw)
to enumerate all locally-installed fonts:

![Fonts screenshot](https://github.com/timsneath/win32/blob/main/doc/images/fonts.png?raw=true)

or access system information that is not exposed directly by the Dart framework
libraries:

![System information screenshot](https://github.com/timsneath/win32/blob/main/doc/images/power.png?raw=true)

You could use it to build a Windows app with Flutter that relies on Win32 APIs:

![Disk explorer screenshot](https://github.com/timsneath/win32/blob/main/doc/images/disk_explorer.png?raw=true)

You could even use it to build a traditional Win32 app, written purely in Dart,
that could have come straight out of a classic Charles Petzold book on
programming Windows apps:

![Dart notepad screenshot](https://github.com/timsneath/win32/blob/main/doc/images/notepad.png?raw=true)

or even, perhaps, a fully-fledged game using GDI:

![Dart Tetris for Win32 screenshot](https://github.com/timsneath/win32/blob/main/doc/images/tetris.png?raw=true)

You might even build a package that depends upon it, like
[dart_console](https://pub.dev/packages/dart_console), which enables advanced
console manipulation:

![Dart console ANSI color demo screenshot](https://github.com/timsneath/win32/blob/main/doc/images/console.png?raw=true)

or [filepicker_windows](https://pub.dev/packages/filepicker_windows), which
provides a modern Windows file picker for Flutter:

![Windows file picker screenshot](https://github.com/timsneath/win32/blob/main/doc/images/filepicker.png?raw=true)

## Getting started

Many more samples can be found in the `example\` subdirectory, along with a test
suite in the `test\` subdirectory that shows other API calls.

A good starting point is `hello.dart`. This example demonstrates creating a
Win32 window and responding to common messages such as `WM_PAINT` through a
`WindowProc` callback function.

To run it, type:

```cmd
dart example\hello.dart
```

This should display a window with a text message.

This can be compiled into a standalone Win32 executable by running:

```cmd
dart compile exe example\hello.dart -o example\bin\hello.exe
```

For more information on working with the Win32 library from Dart, consult the
documentation, in particular the sections on [string
manipulation](https://pub.dev/documentation/win32/latest/win32/win32-library.html)
and [COM
objects](https://pub.dev/documentation/win32/latest/topics/com-topic.html).

## Examples

There are many examples included with this package that demonstrate calling
various Win32, COM and WinRT APIs. These can be found in the `example\` folder;
a short description of each example can be found [here](
https://pub.dev/packages/win32/example).

## Packages built on win32

There are a growing set of packages that build on the relatively low-level APIs
exposed by the Dart win32 package to provide more idiomatic class wrappers.
These packages typically don't require any knowledge of Windows programming
models or FFI, and are ideal for incorporation into Flutter apps for Windows.

Specifically, this includes:

- [dart_console](https://pub.dev/packages/dart_console): provides Dart libraries
  for building TUIs (terminal UIs) or console apps that use more than the
  stdin/stdout services provided by Dart itself.
- [device_info_plus_windows](https://pub.dev/packages/device_info_plus_windows):
  provides information about the characteristics of the current device.
- [filepicker_windows](https://pub.dev/packages/filepicker_windows): makes the
  Windows file open / save common dialog boxes available to Flutter and Dart
  apps.
- [path_provider_windows](https://pub.dev/packages/path_provider_windows):
  provides a way for Dart apps to find common Windows file locations (such as
  the documents directory).
- [win32_registry](https://pub.dev/packages/win32_registry): provides Dart
  classes for accessing and manipulating the Windows registry.
- [win32_runner](https://pub.dev/packages/win32_runner): provides an
  experimental shell (or runner) for hosting Flutter apps without needing a C++
  compiler to create the EXE.

## Requirements

This package assumes the [Dart 64-bit compiler](https://dart.dev/get-dart),
running on Windows. Many commands are tested on 32-bit Windows, but due to the
lack of a Dart compiler for 32-bit executables and the ever diminishing number
of machines running 32-bit OSes, this is inevitably a low priority. The package
is also tested on ARM architecture, running in x64 emulation mode.

## Features and bugs

The current package only projects a subset of the Win32 API, but new APIs will
be added based on user demand. I'm particularly interested in unblocking the
creation of new Dart packages for Windows. Please file feature requests and bugs
at the [issue tracker][tracker].

## Backwards compatibility

The library version tries to model semver, but you should not assume a strict
guarantee of no breaking changes between minor versions. That guarantee is not
possible to make, for several reasons:

- Several times, fixing a bug in the fidelity of the Win32 API has tightened the
  constraints over a parameter (for example, `Pointer` becomes
  `Pointer<INPUT>`). These changes should be signalled in the log.
- Adding new features may itself cause a breaking change. For example, if you
  declare a missing Windows constant in your own code that is then added, Dart
  will complain about the duplicate definition.

One solution is to pin to a specific version of Win32, or declare a more
tightly-bounded version dependency (e.g. `'>=1.7.0 <1.8.0'` rather than merely
`^1.7.0`). But the best approach is simply to test regularly with the latest
version of this package, and continue to move your minimum forward. As the
package matures, these issues should gradually fade away.

## Acknowledgements

The Tetris example listed above is a fuller worked example of a reasonably
complete program that uses the Dart Win32 package. It is a port of a C version
of the game by Chang-Hung Liang. [More information...](example/tetris/README.md)

The [C implementation of Snake](https://github.com/davidejones/winsnake) is by
David Jones, and is ported with his permission.

The original C version of the Notepad example was authored by Charles Petzold,
and is kindly [licensed by him](https://www.charlespetzold.com/faq.html) without
restriction.

The original C version of the [custom title bar
example](https://github.com/grassator/win32-window-custom-titlebar) is by
Dmitriy Kubyshkin and is licensed by him under the MIT License.

The summary Win32 API documentation comments are [licensed by Microsoft][] under
the [Creative Commons Attribution 4.0 International Public License][license].

[tracker]: https://github.com/timsneath/win32
[licensed by Microsoft]: https://github.com/MicrosoftDocs/win32/blob/7b49862e8d58cfad5d4e5e22104c9fca7fd6db2f/ThirdPartyNotices
[license]: https://github.com/MicrosoftDocs/win32/blob/7b49862e8d58cfad5d4e5e22104c9fca7fd6db2f/LICENSE
