import '../../../parser.dart';
import '../../context/context.dart';
import '../../context/result.dart';

/// Returns a parser that detects newlines platform independently.
Parser<String> newline([String message = 'newline expected']) =>
    NewlineParser(message);

/// A parser that consumes newlines platform independently.
class NewlineParser extends Parser<String> {
  NewlineParser(this.message);

  final String message;

  @override
  Result<String> parseOn(Context context) {
    final buffer = context.buffer;
    final position = context.position;
    if (position < buffer.length) {
      switch (buffer.codeUnitAt(position)) {
        case 10:
          // Unix and Unix-like systems (Linux, macOS, FreeBSD, AIX, Xenix, etc.),
          // Multics, BeOS, Amiga, RISC OS.
          return context.success('\n', position + 1);
        case 13:
          if (position + 1 < buffer.length &&
              buffer.codeUnitAt(position + 1) == 10) {
            // Microsoft Windows, DOS (MS-DOS, PC DOS, etc.), Atari TOS, DEC
            // TOPS-10, RT-11, CP/M, MP/M, OS/2, Symbian OS, Palm OS, Amstrad
            // CPC, and most other early non-Unix and non-IBM operating systems.
            return context.success('\r\n', position + 2);
          } else {
            // Commodore 8-bit machines (C64, C128), Acorn BBC, ZX Spectrum,
            // TRS-80, Apple II series, Oberon, the classic Mac OS, MIT Lisp
            // Machine and OS-9
            return context.success('\r', position + 1);
          }
      }
    }
    return context.failure(message);
  }

  @override
  int fastParseOn(String buffer, int position) {
    if (position < buffer.length) {
      switch (buffer.codeUnitAt(position)) {
        case 10:
          return position + 1;
        case 13:
          return position + 1 < buffer.length &&
                  buffer.codeUnitAt(position + 1) == 10
              ? position + 2
              : position + 1;
      }
    }
    return -1;
  }

  @override
  NewlineParser copy() => NewlineParser(message);
}
