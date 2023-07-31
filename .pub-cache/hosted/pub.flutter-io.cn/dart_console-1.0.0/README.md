A Dart library for building console applications.

[![pub package](https://img.shields.io/pub/v/dart_console.svg)](https://pub.dev/packages/dart_console)
[![Language](https://img.shields.io/badge/language-Dart-blue.svg)](https://dart.dev)

This library contains a variety of useful functions for console application
development, including:

- Reading the current window dimensions (height, width)
- Reading and setting the cursor location
- Setting foreground and background colors
- Manipulating the console into "raw mode", which allows more advanced
  keyboard input processing than the default `dart:io` library.
- Reading keys and control sequences from the keyboard
- Writing aligned text to the screen

The library has been used to implement a [Dart][dart] version of the
[Kilo][kilo] text editor; when compiled with Dart it results in a self-contained
`kilo` executable. The library is sufficient for a reasonably complete set of
usage, including `readline`-style CLI and basic text games.

The library assumes a terminal that recognizes and implements common ANSI escape
sequences. The package has been tested on macOS, Linux and [Windows
10][vt-win10]. Windows support is preliminary - the library is tested on the
[Windows Terminal][winterm] and `cmd`, but some functions will not work on older
versions of Windows that do not support ANSI escape sequences.

The library uses the [win32](https://pub.dev/packages/win32) package for
accessing the Win32 API through FFI. That package contains many examples of
using Dart FFI for more complex examples.

## Usage

A simple example for the `dart_console` package:

```dart
import 'package:dart_console/dart_console.dart';

main() {
  final console = Console();

  console.clearScreen();
  console.resetCursorPosition();

  console.writeLine(
    'Console size is ${console.windowWidth} cols and ${console.windowHeight} rows.',
    TextAlignment.center,
  );

  console.writeLine();

  return 0;
}
```

More comprehensive demos of the `Console` class are provided, as follows:

| Example | Description |
| ---- | ---- |
| `demo.dart` | Suite of test demos that showcase various capabilities |
| `main.dart` | Basic demo of how to get started with the `dart_console` |
| `keys.dart` | Demonstrates how `dart_console` processes control characters |
| `readline.dart` | Sample command-line interface / REPL |
| `kilo.dart` | Rudimentary text editor |
| `life.dart` | Game of Life |

## Acknowledgements

Special thanks to [Matt Sullivan (@mjohnsullivan)][@mjohnsullivan] and [Samir
Jindel (@sjindel-google)][@sjindel-google] for their help understanding the
vagaries of FFI in its early state.

Thanks to [@erf] for contributing the Game of Life example.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[kilo]: https://github.com/antirez/kilo
[dart]: https://dart.dev/get-dart
[dart2native]: https://dart.dev/tools/dart2native
[dart_kilo]: https://github.com/timsneath/dart_kilo
[vt-win10]: https://docs.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
[winterm]: https://www.microsoft.com/en-us/p/windows-terminal-preview/9n0dx20hk701
[FFI]: https://dart.dev/server/c-interop
[@mjohnsullivan]: https://github.com/mjohnsullivan
[@sjindel-google]: https://github.com/sjindel-google
[@erf]: https://github.com/erf
[tracker]: https://github.com/timsneath/dart_console/issues
