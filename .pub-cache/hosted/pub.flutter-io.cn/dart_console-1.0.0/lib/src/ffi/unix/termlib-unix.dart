// termlib-unix.dart
//
// glibc-dependent library for interrogating and manipulating the console.
//
// This class provides raw wrappers for the underlying terminal system calls
// that are not available through ANSI mode control sequences, and is not
// designed to be called directly. Package consumers should normally use the
// `Console` class to call these methods.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../termlib.dart';
import 'ioctl.dart';
import 'termios.dart';
import 'unistd.dart';

class TermLibUnix implements TermLib {
  late final DynamicLibrary _stdlib;

  late final Pointer<TermIOS> _origTermIOSPointer;

  late final ioctlDart ioctl;
  late final tcgetattrDart tcgetattr;
  late final tcsetattrDart tcsetattr;

  @override
  int getWindowHeight() {
    final winSizePointer = calloc<WinSize>();
    final result = ioctl(STDOUT_FILENO, TIOCGWINSZ, winSizePointer.cast());
    if (result == -1) return -1;

    final winSize = winSizePointer.ref;
    if (winSize.ws_row == 0) {
      return -1;
    } else {
      final result = winSize.ws_row;
      calloc.free(winSizePointer);
      return result;
    }
  }

  @override
  int getWindowWidth() {
    final winSizePointer = calloc<WinSize>();
    final result = ioctl(STDOUT_FILENO, TIOCGWINSZ, winSizePointer.cast());
    if (result == -1) return -1;

    final winSize = winSizePointer.ref;
    if (winSize.ws_col == 0) {
      return -1;
    } else {
      final result = winSize.ws_col;
      calloc.free(winSizePointer);
      return result;
    }
  }

  @override
  void enableRawMode() {
    final _origTermIOS = _origTermIOSPointer.ref;

    final newTermIOSPointer = calloc<TermIOS>();
    final newTermIOS = newTermIOSPointer.ref;

    newTermIOS.c_iflag =
        _origTermIOS.c_iflag & ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    newTermIOS.c_oflag = _origTermIOS.c_oflag & ~OPOST;
    newTermIOS.c_cflag = _origTermIOS.c_cflag | CS8;
    newTermIOS.c_lflag =
        _origTermIOS.c_lflag & ~(ECHO | ICANON | IEXTEN | ISIG);
    newTermIOS.c_cc0 = _origTermIOS.c_cc0;
    newTermIOS.c_cc1 = _origTermIOS.c_cc1;
    newTermIOS.c_cc2 = _origTermIOS.c_cc2;
    newTermIOS.c_cc3 = _origTermIOS.c_cc3;
    newTermIOS.c_cc4 = _origTermIOS.c_cc4;
    newTermIOS.c_cc5 = _origTermIOS.c_cc5;
    newTermIOS.c_cc6 = _origTermIOS.c_cc6;
    newTermIOS.c_cc7 = _origTermIOS.c_cc7;
    newTermIOS.c_cc8 = _origTermIOS.c_cc8;
    newTermIOS.c_cc9 = _origTermIOS.c_cc9;
    newTermIOS.c_cc10 = _origTermIOS.c_cc10;
    newTermIOS.c_cc11 = _origTermIOS.c_cc11;
    newTermIOS.c_cc12 = _origTermIOS.c_cc12;
    newTermIOS.c_cc13 = _origTermIOS.c_cc13;
    newTermIOS.c_cc14 = _origTermIOS.c_cc14;
    newTermIOS.c_cc15 = _origTermIOS.c_cc15;
    newTermIOS.c_cc16 = 0; // VMIN -- return each byte, or 0 for timeout
    newTermIOS.c_cc17 = 1; // VTIME -- 100ms timeout (unit is 1/10s)
    newTermIOS.c_cc18 = _origTermIOS.c_cc18;
    newTermIOS.c_cc19 = _origTermIOS.c_cc19;
    newTermIOS.c_ispeed = _origTermIOS.c_ispeed;
    newTermIOS.c_oflag = _origTermIOS.c_ospeed;

    tcsetattr(STDIN_FILENO, TCSAFLUSH, newTermIOSPointer);

    calloc.free(newTermIOSPointer);
  }

  @override
  void disableRawMode() {
    if (nullptr == _origTermIOSPointer.cast()) return;
    tcsetattr(STDIN_FILENO, TCSAFLUSH, _origTermIOSPointer);
  }

  TermLibUnix() {
    _stdlib = Platform.isMacOS
        ? DynamicLibrary.open('/usr/lib/libSystem.dylib')
        : DynamicLibrary.open('libc.so.6');

    ioctl = _stdlib.lookupFunction<ioctlNative, ioctlDart>('ioctl');
    tcgetattr =
        _stdlib.lookupFunction<tcgetattrNative, tcgetattrDart>('tcgetattr');
    tcsetattr =
        _stdlib.lookupFunction<tcsetattrNative, tcsetattrDart>('tcsetattr');

    // store console mode settings so we can return them again as necessary
    _origTermIOSPointer = calloc<TermIOS>();
    tcgetattr(STDIN_FILENO, _origTermIOSPointer);
  }
}
