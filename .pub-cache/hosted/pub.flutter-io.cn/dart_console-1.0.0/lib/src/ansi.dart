// ansi.dart
//
// Contains ANSI escape sequences used by dart_console. Other classes should
// use these constants rather than embedding raw control codes.
//
// For more information on commonly-accepted ANSI mode control sequences, read
// https://vt100.net/docs/vt100-ug/chapter3.html.

import 'enums.dart';

const ansiDeviceStatusReportCursorPosition = '\x1b[6n';
const ansiEraseInDisplayAll = '\x1b[2J';
const ansiEraseInLineAll = '\x1b[2K';
const ansiEraseCursorToEnd = '\x1b[K';

const ansiHideCursor = '\x1b[?25l';
const ansiShowCursor = '\x1b[?25h';

const ansiCursorLeft = '\x1b[D';
const ansiCursorRight = '\x1b[C';
const ansiCursorUp = '\x1b[A';
const ansiCursorDown = '\x1b[B';

const ansiResetCursorPosition = '\x1b[H';
const ansiMoveCursorToScreenEdge = '\x1b[999C\x1b[999B';
String ansiCursorPosition(int row, int col) => '\x1b[$row;${col}H';

const ansiResetColor = '\x1b[m';
String ansiSetColor(int color) => '\x1b[${color}m';
String ansiSetExtendedForegroundColor(int color) => '\x1b[38;5;${color}m';
String ansiSetExtendedBackgroundColor(int color) => '\x1b[48;5;${color}m';
String ansiSetTextStyles(
    {bool bold = false,
    bool underscore = false,
    bool blink = false,
    bool inverted = false}) {
  final styles = <int>[];
  if (bold) styles.add(1);
  if (underscore) styles.add(4);
  if (blink) styles.add(5);
  if (inverted) styles.add(7);
  return '\x1b[${styles.join(";")}m';
}

/// A list of ANSI/VT100 color codes for foreground colors.
const ansiForegroundColors = {
  ConsoleColor.black: 30,
  ConsoleColor.red: 31,
  ConsoleColor.green: 32,
  ConsoleColor.yellow: 33,
  ConsoleColor.blue: 34,
  ConsoleColor.magenta: 35,
  ConsoleColor.cyan: 36,
  ConsoleColor.white: 37,
  ConsoleColor.brightBlack: 90,
  ConsoleColor.brightRed: 91,
  ConsoleColor.brightGreen: 92,
  ConsoleColor.brightYellow: 93,
  ConsoleColor.brightBlue: 94,
  ConsoleColor.brightMagenta: 95,
  ConsoleColor.brightCyan: 96,
  ConsoleColor.brightWhite: 97
};

/// A list of ANSI/VT100 color codes for background colors.
const ansiBackgroundColors = {
  ConsoleColor.black: 40,
  ConsoleColor.red: 41,
  ConsoleColor.green: 42,
  ConsoleColor.yellow: 43,
  ConsoleColor.blue: 44,
  ConsoleColor.magenta: 45,
  ConsoleColor.cyan: 46,
  ConsoleColor.white: 47,
  ConsoleColor.brightBlack: 100,
  ConsoleColor.brightRed: 101,
  ConsoleColor.brightGreen: 102,
  ConsoleColor.brightYellow: 103,
  ConsoleColor.brightBlue: 104,
  ConsoleColor.brightMagenta: 105,
  ConsoleColor.brightCyan: 106,
  ConsoleColor.brightWhite: 107
};
