// console.dart
//
// Contains the primary API for dart_console, exposed through the `Console`
// class.

import 'dart:io';
import 'dart:math';

import 'ansi.dart';
import 'enums.dart';

import 'ffi/termlib.dart';
import 'ffi/win/termlib-win.dart';
import 'key.dart';

/// A screen position, measured in rows and columns from the top-left origin
/// of the screen. Coordinates are zero-based, and converted as necessary
/// for the underlying system representation (e.g. one-based for VT-style
/// displays).
class Coordinate {
  final int row;
  final int col;

  const Coordinate(this.row, this.col);
}

/// The ScrollbackBuffer class is a utility for handling multi-line user
/// input in readline(). It doesn't support history editing a la bash,
/// but it should handle the most common use cases.
class ScrollbackBuffer {
  final lineList = <String>[];
  int? lineIndex;
  String? currentLineBuffer;
  bool recordBlanks;

  // called by Console.scolling()
  ScrollbackBuffer({required this.recordBlanks});

  /// Add a new line to the scrollback buffer. This would normally happen
  /// when the user finishes typing/editing the line and taps the 'enter'
  /// key.
  void add(String buffer) {
    // don't add blank line to scrollback history if !recordBlanks
    if (buffer == '' && !recordBlanks) {
      return;
    }
    lineList.add(buffer);
    lineIndex = lineList.length;
    currentLineBuffer = null;
  }

  /// Scroll 'up' -- Replace the user-input buffer with the contents of the
  /// previous line. ScrollbackBuffer tracks which lines are the 'current'
  /// and 'previous' lines. The up() method stores the current line buffer
  /// so that the contents will not be lost in the event the user starts
  /// typing/editing the line and then wants to review a previous line.
  String up(String buffer) {
    // Handle the case of the user tapping 'up' before there is a
    // scrollback buffer to scroll through.
    if (lineIndex == null) {
      return buffer;
    } else {
      // Only store the current line buffer once while scrolling up
      currentLineBuffer ??= buffer;
      lineIndex = lineIndex! - 1;
      lineIndex = lineIndex! < 0 ? 0 : lineIndex;
      return lineList[lineIndex!];
    }
  }

  /// Scroll 'down' -- Replace the user-input buffer with the contents of
  /// the next line. The final 'next line' is the original contents of the
  /// line buffer.
  String? down() {
    // Handle the case of the user tapping 'down' before there is a
    // scrollback buffer to scroll through.
    if (lineIndex == null) {
      return null;
    } else {
      lineIndex = lineIndex! + 1;
      lineIndex = lineIndex! > lineList.length ? lineList.length : lineIndex;
      if (lineIndex == lineList.length) {
        // Once the user scrolls to the bottom, reset the current line
        // buffer so that up() can store it again: The user might have
        // edited it between down() and up().
        final temp = currentLineBuffer;
        currentLineBuffer = null;
        return temp;
      } else {
        return lineList[lineIndex!];
      }
    }
  }
}

/// A representation of the current console window.
///
/// Use the [Console] to get information about the current window and to read
/// and write to it.
///
/// A comprehensive set of demos of using the Console class can be found in the
/// `examples/` subdirectory.
class Console {
  // We cache these values so we don't have to keep retrieving them. The
  // downside is that the class isn't dynamically responsive to a resized
  // console, but that's not unusual for console applications anyway.
  int _windowWidth = 0;
  int _windowHeight = 0;

  bool _isRawMode = false;

  final _termlib = TermLib();

  // Declare the type explicitly: Initializing the _scrollbackBuffer
  // in the constructor means that we can no longer infer the type
  // here.
  final ScrollbackBuffer? _scrollbackBuffer;

  // Declaring the named constructor means that Dart no longer
  // supplies the default constructor. Besides, we need to set
  // _scrollbackBuffer to null for the regular console to work as
  // before.
  Console() : _scrollbackBuffer = null;

  // Create a named constructor specifically for scrolling consoles
  // Use `Console.scrolling(recordBlanks: false)` to omit blank lines
  // from console history
  Console.scrolling({bool recordBlanks = true})
      : _scrollbackBuffer = ScrollbackBuffer(recordBlanks: recordBlanks);

  /// Enables or disables raw mode.
  ///
  /// There are a series of flags applied to a UNIX-like terminal that together
  /// constitute 'raw mode'. These flags turn off echoing of character input,
  /// processing of input signals like Ctrl+C, and output processing, as well as
  /// buffering of input until a full line is entered.
  ///
  /// Raw mode is useful for console applications like text editors, which
  /// perform their own input and output processing, as well as for reading a
  /// single key from the input.
  ///
  /// In general, you should not need to enable or disable raw mode explicitly;
  /// you should call the [readKey] command, which takes care of handling raw
  /// mode for you.
  ///
  /// If you use raw mode, you should disable it before your program returns, to
  /// avoid the console being left in a state unsuitable for interactive input.
  ///
  /// When raw mode is enabled, the newline command (`\n`) does not also perform
  /// a carriage return (`\r`). You can use the [newLine] property or the
  /// [writeLine] function instead of explicitly using `\n` to ensure the
  /// correct results.
  ///
  set rawMode(bool value) {
    _isRawMode = value;
    if (value) {
      _termlib.enableRawMode();
    } else {
      _termlib.disableRawMode();
    }
  }

  /// Returns whether the terminal is in raw mode.
  ///
  /// There are a series of flags applied to a UNIX-like terminal that together
  /// constitute 'raw mode'. These flags turn off echoing of character input,
  /// processing of input signals like Ctrl+C, and output processing, as well as
  /// buffering of input until a full line is entered.
  bool get rawMode => _isRawMode;

  /// Clears the entire screen
  void clearScreen() {
    if (Platform.isWindows) {
      final winTermlib = _termlib as TermLibWindows;
      winTermlib.clearScreen();
    } else {
      stdout.write(ansiEraseInDisplayAll + ansiResetCursorPosition);
    }
  }

  /// Erases all the characters in the current line.
  void eraseLine() => stdout.write(ansiEraseInLineAll);

  /// Erases the current line from the cursor to the end of the line.
  void eraseCursorToEnd() => stdout.write(ansiEraseCursorToEnd);

  /// Returns the width of the current console window in characters.
  ///
  /// This command attempts to use the ioctl() system call to retrieve the
  /// window width, and if that fails uses ANSI escape codes to identify its
  /// location by walking off the edge of the screen and seeing what the
  /// terminal clipped the cursor to.
  ///
  /// If unable to retrieve a valid width from either method, the method
  /// throws an [Exception].
  int get windowWidth {
    if (_windowWidth == 0) {
      // try using ioctl() to give us the screen size
      final width = _termlib.getWindowWidth();
      if (width != -1) {
        _windowWidth = width;
      } else {
        // otherwise, fall back to the approach of setting the cursor to beyond
        // the edge of the screen and then reading back its actual position
        final originalCursor = cursorPosition;
        stdout.write(ansiMoveCursorToScreenEdge);
        final newCursor = cursorPosition;
        cursorPosition = originalCursor;

        if (newCursor != null) {
          _windowWidth = newCursor.col;
        } else {
          // we've run out of options; terminal is unsupported
          throw Exception("Couldn't retrieve window width");
        }
      }
    }

    return _windowWidth;
  }

  /// Returns the height of the current console window in characters.
  ///
  /// This command attempts to use the ioctl() system call to retrieve the
  /// window height, and if that fails uses ANSI escape codes to identify its
  /// location by walking off the edge of the screen and seeing what the
  /// terminal clipped the cursor to.
  ///
  /// If unable to retrieve a valid height from either method, the method
  /// throws an [Exception].
  int get windowHeight {
    if (_windowHeight == 0) {
      // try using ioctl() to give us the screen size
      final height = _termlib.getWindowHeight();
      if (height != -1) {
        _windowHeight = height;
      } else {
        // otherwise, fall back to the approach of setting the cursor to beyond
        // the edge of the screen and then reading back its actual position
        final originalCursor = cursorPosition;
        stdout.write(ansiMoveCursorToScreenEdge);
        final newCursor = cursorPosition;
        cursorPosition = originalCursor;

        if (newCursor != null) {
          _windowHeight = newCursor.row;
        } else {
          // we've run out of options; terminal is unsupported
          throw Exception("Couldn't retrieve window height");
        }
      }
    }

    return _windowHeight;
  }

  /// Hides the cursor.
  ///
  /// If you hide the cursor, you should take care to return the cursor to
  /// a visible status at the end of the program, even if it throws an
  /// exception, by calling the [showCursor] method.
  void hideCursor() => stdout.write(ansiHideCursor);

  /// Shows the cursor.
  void showCursor() => stdout.write(ansiShowCursor);

  /// Moves the cursor one position to the left.
  void cursorLeft() => stdout.write(ansiCursorLeft);

  /// Moves the cursor one position to the right.
  void cursorRight() => stdout.write(ansiCursorRight);

  /// Moves the cursor one position up.
  void cursorUp() => stdout.write(ansiCursorUp);

  /// Moves the cursor one position down.
  void cursorDown() => stdout.write(ansiCursorDown);

  /// Moves the cursor to the top left corner of the screen.
  void resetCursorPosition() => stdout.write(ansiCursorPosition(1, 1));

  /// Returns the current cursor position as a coordinate.
  ///
  /// Warning: Linux and macOS terminals report their cursor position by
  /// posting an escape sequence to stdin in response to a request. However,
  /// if there is lots of other keyboard input at the same time, some
  /// terminals may interleave that input in the response. There is no
  /// easy way around this; the recommendation is therefore to use this call
  /// before reading keyboard input, to get an original offset, and then
  /// track the local cursor independently based on keyboard input.
  ///
  ///
  Coordinate? get cursorPosition {
    rawMode = true;
    stdout.write(ansiDeviceStatusReportCursorPosition);
    // returns a Cursor Position Report result in the form <ESC>[24;80R
    // which we have to parse apart, unfortunately
    var result = '';
    var i = 0;

    // avoid infinite loop if we're getting a bad result
    while (i < 16) {
      // ignore: use_string_buffers
      result += String.fromCharCode(stdin.readByteSync());
      if (result.endsWith('R')) break;
      i++;
    }
    rawMode = false;

    if (result[0] != '\x1b') {
      print(' result: $result  result.length: ${result.length}');
      return null;
    }

    result = result.substring(2, result.length - 1);
    final coords = result.split(';');

    if (coords.length != 2) {
      print(' coords.length: ${coords.length}');
      return null;
    }
    if ((int.tryParse(coords[0]) != null) &&
        (int.tryParse(coords[1]) != null)) {
      return Coordinate(int.parse(coords[0]) - 1, int.parse(coords[1]) - 1);
    } else {
      print(' coords[0]: ${coords[0]}   coords[1]: ${coords[1]}');
      return null;
    }
  }

  /// Sets the cursor to a specific coordinate.
  ///
  /// Coordinates are measured from the top left of the screen, and are
  /// zero-based.
  set cursorPosition(Coordinate? cursor) {
    if (cursor != null) {
      if (Platform.isWindows) {
        final winTermlib = _termlib as TermLibWindows;
        winTermlib.setCursorPosition(cursor.col, cursor.row);
      } else {
        stdout.write(ansiCursorPosition(cursor.row + 1, cursor.col + 1));
      }
    }
  }

  /// Sets the console foreground color to a named ANSI color.
  ///
  /// There are 16 named ANSI colors, as defined in the [ConsoleColor]
  /// enumeration. Depending on the console theme and background color,
  /// some colors may not offer a legible contrast against the background.
  void setForegroundColor(ConsoleColor foreground) {
    stdout.write(ansiSetColor(ansiForegroundColors[foreground]!));
  }

  /// Sets the console background color to a named ANSI color.
  ///
  /// There are 16 named ANSI colors, as defined in the [ConsoleColor]
  /// enumeration. Depending on the console theme and background color,
  /// some colors may not offer a legible contrast against the background.
  void setBackgroundColor(ConsoleColor background) {
    stdout.write(ansiSetColor(ansiBackgroundColors[background]!));
  }

  /// Sets the foreground to one of 256 extended ANSI colors.
  ///
  /// See https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit for
  /// the full set of colors. You may also run `examples/demo.dart` for this
  /// package, which provides a sample of each color in this list.
  void setForegroundExtendedColor(int colorValue) {
    assert(colorValue >= 0 && colorValue <= 0xFF,
        'Color must be a value between 0 and 255.');

    stdout.write(ansiSetExtendedForegroundColor(colorValue));
  }

  /// Sets the background to one of 256 extended ANSI colors.
  ///
  /// See https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit for
  /// the full set of colors. You may also run `examples/demo.dart` for this
  /// package, which provides a sample of each color in this list.
  void setBackgroundExtendedColor(int colorValue) {
    assert(colorValue >= 0 && colorValue <= 0xFF,
        'Color must be a value between 0 and 255.');

    stdout.write(ansiSetExtendedBackgroundColor(colorValue));
  }

  /// Sets the text style.
  ///
  /// Note that not all styles may be supported by all terminals.
  void setTextStyle(
      {bool bold = false,
      bool underscore = false,
      bool blink = false,
      bool inverted = false}) {
    stdout.write(ansiSetTextStyles(
        bold: bold, underscore: underscore, blink: blink, inverted: inverted));
  }

  /// Resets all color attributes and text styles to the default terminal
  /// setting.
  void resetColorAttributes() => stdout.write(ansiResetColor);

  /// Writes the text to the console.
  void write(String text) => stdout.write(text);

  /// Returns the current newline string.
  String get newLine => _isRawMode ? '\r\n' : '\n';

  /// Writes an error message to the console, with newline automatically
  /// appended.
  void writeErrorLine(String text) {
    stderr.write(text);

    // Even if we're in raw mode, we write '\n', since raw mode only applies
    // to stdout
    stderr.write('\n');
  }

  /// Writes a line to the console, optionally with alignment provided by the
  /// [TextAlignment] enumeration.
  ///
  /// If no parameters are supplied, the command simply writes a new line
  /// to the console. By default, text is left aligned.
  ///
  /// Text alignment operates based off the current window width, and pads
  /// the remaining characters with a space character.
  void writeLine([String? text, TextAlignment alignment = TextAlignment.left]) {
    var alignedText = text;

    if (text != null) {
      switch (alignment) {
        case TextAlignment.center:
          final padding = ((windowWidth - text.length) / 2).round();
          alignedText =
              text.padLeft(text.length + padding).padRight(windowWidth);
          break;
        case TextAlignment.right:
          alignedText = text.padLeft(windowWidth);
          break;
        default:
      }
      stdout.write(alignedText);
    }
    stdout.write(newLine);
  }

  /// Reads a single key from the input, including a variety of control
  /// characters.
  ///
  /// Keys are represented by the [Key] class. Keys may be printable (if so,
  /// `Key.isControl` is `false`, and the `Key.char` property may be used to
  /// identify the key pressed. Non-printable keys have `Key.isControl` set
  /// to `true`, and if so the `Key.char` property is empty and instead the
  /// `Key.controlChar` property will be set to a value from the
  /// [ControlCharacter] enumeration that describes which key was pressed.
  ///
  /// Owing to the limitations of terminal key handling, certain keys may
  /// be represented by multiple control key sequences. An example showing
  /// basic key handling can be found in the `example/command_line.dart`
  /// file in the package source code.
  Key readKey() {
    Key key;
    int charCode;
    var codeUnit = 0;

    rawMode = true;
    while (codeUnit <= 0) {
      codeUnit = stdin.readByteSync();
    }

    if (codeUnit >= 0x01 && codeUnit <= 0x1a) {
      // Ctrl+A thru Ctrl+Z are mapped to the 1st-26th entries in the
      // enum, so it's easy to convert them across
      key = Key.control(ControlCharacter.values[codeUnit]);
    } else if (codeUnit == 0x1b) {
      // escape sequence (e.g. \x1b[A for up arrow)
      key = Key.control(ControlCharacter.escape);

      final escapeSequence = <String>[];

      charCode = stdin.readByteSync();
      if (charCode == -1) {
        rawMode = false;
        return key;
      }
      escapeSequence.add(String.fromCharCode(charCode));

      if (charCode == 127) {
        key = Key.control(ControlCharacter.wordBackspace);
      } else if (escapeSequence[0] == '[') {
        charCode = stdin.readByteSync();
        if (charCode == -1) {
          rawMode = false;
          return key;
        }
        escapeSequence.add(String.fromCharCode(charCode));

        switch (escapeSequence[1]) {
          case 'A':
            key.controlChar = ControlCharacter.arrowUp;
            break;
          case 'B':
            key.controlChar = ControlCharacter.arrowDown;
            break;
          case 'C':
            key.controlChar = ControlCharacter.arrowRight;
            break;
          case 'D':
            key.controlChar = ControlCharacter.arrowLeft;
            break;
          case 'H':
            key.controlChar = ControlCharacter.home;
            break;
          case 'F':
            key.controlChar = ControlCharacter.end;
            break;
          default:
            if (escapeSequence[1].codeUnits[0] > '0'.codeUnits[0] &&
                escapeSequence[1].codeUnits[0] < '9'.codeUnits[0]) {
              charCode = stdin.readByteSync();
              if (charCode == -1) {
                rawMode = false;
                return key;
              }
              escapeSequence.add(String.fromCharCode(charCode));
              if (escapeSequence[2] != '~') {
                key.controlChar = ControlCharacter.unknown;
              } else {
                switch (escapeSequence[1]) {
                  case '1':
                    key.controlChar = ControlCharacter.home;
                    break;
                  case '3':
                    key.controlChar = ControlCharacter.delete;
                    break;
                  case '4':
                    key.controlChar = ControlCharacter.end;
                    break;
                  case '5':
                    key.controlChar = ControlCharacter.pageUp;
                    break;
                  case '6':
                    key.controlChar = ControlCharacter.pageDown;
                    break;
                  case '7':
                    key.controlChar = ControlCharacter.home;
                    break;
                  case '8':
                    key.controlChar = ControlCharacter.end;
                    break;
                  default:
                    key.controlChar = ControlCharacter.unknown;
                }
              }
            } else {
              key.controlChar = ControlCharacter.unknown;
            }
        }
      } else if (escapeSequence[0] == 'O') {
        charCode = stdin.readByteSync();
        if (charCode == -1) {
          rawMode = false;
          return key;
        }
        escapeSequence.add(String.fromCharCode(charCode));
        assert(escapeSequence.length == 2);
        switch (escapeSequence[1]) {
          case 'H':
            key.controlChar = ControlCharacter.home;
            break;
          case 'F':
            key.controlChar = ControlCharacter.end;
            break;
          case 'P':
            key.controlChar = ControlCharacter.F1;
            break;
          case 'Q':
            key.controlChar = ControlCharacter.F2;
            break;
          case 'R':
            key.controlChar = ControlCharacter.F3;
            break;
          case 'S':
            key.controlChar = ControlCharacter.F4;
            break;
          default:
        }
      } else if (escapeSequence[0] == 'b') {
        key.controlChar = ControlCharacter.wordLeft;
      } else if (escapeSequence[0] == 'f') {
        key.controlChar = ControlCharacter.wordRight;
      } else {
        key.controlChar = ControlCharacter.unknown;
      }
    } else if (codeUnit == 0x7f) {
      key = Key.control(ControlCharacter.backspace);
    } else if (codeUnit == 0x00 || (codeUnit >= 0x1c && codeUnit <= 0x1f)) {
      key = Key.control(ControlCharacter.unknown);
    } else {
      // assume other characters are printable
      key = Key.printable(String.fromCharCode(codeUnit));
    }
    rawMode = false;
    return key;
  }

  /// Reads a line of input, handling basic keyboard navigation commands.
  ///
  /// The Dart [stdin.readLineSync()] function reads a line from the input,
  /// however it does not handle cursor navigation (e.g. arrow keys, home and
  /// end keys), and has side-effects that may be unhelpful for certain console
  /// applications. For example, Ctrl+C is processed as the break character,
  /// which causes the application to immediately exit.
  ///
  /// The implementation does not currently allow for multi-line input. It
  /// is best suited for short text fields that are not longer than the width
  /// of the current screen.
  ///
  /// By default, readLine ignores break characters (e.g. Ctrl+C) and the Esc
  /// key, but if enabled, the function will exit and return a null string if
  /// those keys are pressed.
  ///
  /// A callback function may be supplied, as a peek-ahead for what is being
  /// entered. This is intended for scenarios like auto-complete, where the
  /// text field is coupled with some other content.
  String? readLine(
      {bool cancelOnBreak = false,
      bool cancelOnEscape = false,
      bool cancelOnEOF = false,
      Function(String text, Key lastPressed)? callback}) {
    var buffer = '';
    var index = 0; // cursor position relative to buffer, not screen

    final screenRow = cursorPosition!.row;
    final screenColOffset = cursorPosition!.col;

    final bufferMaxLength = windowWidth - screenColOffset - 3;

    while (true) {
      final key = readKey();

      if (key.isControl) {
        switch (key.controlChar) {
          case ControlCharacter.enter:
            if (_scrollbackBuffer != null) {
              _scrollbackBuffer!.add(buffer);
            }
            writeLine();
            return buffer;
          case ControlCharacter.ctrlC:
            if (cancelOnBreak) return null;
            break;
          case ControlCharacter.escape:
            if (cancelOnEscape) return null;
            break;
          case ControlCharacter.backspace:
          case ControlCharacter.ctrlH:
            if (index > 0) {
              buffer = buffer.substring(0, index - 1) + buffer.substring(index);
              index--;
            }
            break;
          case ControlCharacter.ctrlU:
            buffer = buffer.substring(index, buffer.length);
            index = 0;
            break;
          case ControlCharacter.delete:
          case ControlCharacter.ctrlD:
            if (index < buffer.length - 1) {
              buffer = buffer.substring(0, index) + buffer.substring(index + 1);
            } else if (cancelOnEOF) {
              return null;
            }
            break;
          case ControlCharacter.ctrlK:
            buffer = buffer.substring(0, index);
            break;
          case ControlCharacter.arrowLeft:
          case ControlCharacter.ctrlB:
            index = index > 0 ? index - 1 : index;
            break;
          case ControlCharacter.arrowUp:
            if (_scrollbackBuffer != null) {
              buffer = _scrollbackBuffer!.up(buffer);
              index = buffer.length;
            }
            break;
          case ControlCharacter.arrowDown:
            if (_scrollbackBuffer != null) {
              final temp = _scrollbackBuffer!.down();
              if (temp != null) {
                buffer = temp;
                index = buffer.length;
              }
            }
            break;
          case ControlCharacter.arrowRight:
          case ControlCharacter.ctrlF:
            index = index < buffer.length ? index + 1 : index;
            break;
          case ControlCharacter.wordLeft:
            if (index > 0) {
              final bufferLeftOfCursor = buffer.substring(0, index - 1);
              final lastSpace = bufferLeftOfCursor.lastIndexOf(' ');
              index = lastSpace != -1 ? lastSpace + 1 : 0;
            }
            break;
          case ControlCharacter.wordRight:
            if (index < buffer.length) {
              final bufferRightOfCursor = buffer.substring(index + 1);
              final nextSpace = bufferRightOfCursor.indexOf(' ');
              index = nextSpace != -1
                  ? min(index + nextSpace + 2, buffer.length)
                  : buffer.length;
            }
            break;
          case ControlCharacter.home:
          case ControlCharacter.ctrlA:
            index = 0;
            break;
          case ControlCharacter.end:
          case ControlCharacter.ctrlE:
            index = buffer.length;
            break;
          default:
            break;
        }
      } else {
        if (buffer.length < bufferMaxLength) {
          if (index == buffer.length) {
            buffer += key.char;
            index++;
          } else {
            buffer =
                buffer.substring(0, index) + key.char + buffer.substring(index);
            index++;
          }
        }
      }

      cursorPosition = Coordinate(screenRow, screenColOffset);
      eraseCursorToEnd();
      write(buffer); // allow for backspace condition
      cursorPosition = Coordinate(screenRow, screenColOffset + index);

      if (callback != null) callback(buffer, key);
    }
  }
}
