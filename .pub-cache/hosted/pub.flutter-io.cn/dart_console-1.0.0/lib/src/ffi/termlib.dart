// termlib.dart
//
// Platform-independent library for interrogating and manipulating the console.
//
// This class provides raw wrappers for the underlying terminal system calls
// that are not available through ANSI mode control sequences, and is not
// designed to be called directly. Package consumers should normally use the
// `Console` class to call these methods.

import 'dart:io';

import 'unix/termlib-unix.dart';
import 'win/termlib-win.dart';

abstract class TermLib {
  int getWindowHeight();
  int getWindowWidth();

  void enableRawMode();
  void disableRawMode();

  factory TermLib() {
    if (Platform.isWindows) {
      return TermLibWindows();
    } else {}
    return TermLibUnix();
  }
}
