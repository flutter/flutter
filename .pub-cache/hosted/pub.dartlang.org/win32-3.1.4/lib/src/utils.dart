// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helpful utilities

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'constants.dart';
import 'exceptions.dart';
import 'extensions/int_to_hexstring.dart';
import 'macros.dart';
import 'structs.g.dart';
import 'types.dart';
import 'win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import 'win32/kernel32.g.dart';
import 'win32/shell32.g.dart';
import 'win32/user32.g.dart';

/// Registers a traditional Win32 app process as supporting high-DPI.
///
/// Reduces blurriness but requires the app to provide necessary DPI awareness.
void registerHighDPISupport() {
  final result =
      SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  if (result == FALSE) {
    final debugMessage = 'WARNING: could not set DPI awareness'.toNativeUtf16();
    OutputDebugString(debugMessage);
    free(debugMessage);
  }
}

/// Sets up a WinMain function with all the relevant information.
///
/// Add the following line to your command line app:
/// ```dart
/// void main() => initApp(winMain);
/// ```
///
/// Now you can declare a winMain function as:
/// ```dart
/// void winMain(int hInstance, List<String> args, int nShowCmd) {
/// ...
/// }
/// ```
void initApp(Function winMain) {
  final nArgs = calloc<Int32>();
  final args = <String>[];
  final lpStartupInfo = calloc<STARTUPINFO>();

  // Parse command line args using Win32 functions, to reduce ceremony in the
  // app that uses this.
  final szArgList = CommandLineToArgv(GetCommandLine(), nArgs);
  for (var i = 0; i < nArgs.value; i++) {
    args.add(szArgList[i].toDartString());
  }
  LocalFree(szArgList.address);

  final hInstance = GetModuleHandle(nullptr);
  GetStartupInfo(lpStartupInfo);

  try {
    winMain(
        hInstance,
        args,
        lpStartupInfo.ref.dwFlags & STARTF_USESHOWWINDOW == STARTF_USESHOWWINDOW
            ? lpStartupInfo.ref.wShowWindow
            : SW_SHOWDEFAULT);
  } finally {
    free(nArgs);
    free(lpStartupInfo);
  }
}

/// Detects whether the Windows Runtime is available by attempting to open its
/// core library.
bool isWindowsRuntimeAvailable() {
  try {
    DynamicLibrary.open('api-ms-win-core-winrt-l1-1-0.dll');
    // ignore: avoid_catching_errors
  } on ArgumentError {
    return false;
  }

  return true;
}

/// For debugging, print the memory structure of a given struct.
void printStruct(Pointer struct, int sizeInBytes) {
  final words = <int>[];
  final ptr = struct.cast<Uint16>();
  for (var i = 0; i < sizeInBytes ~/ 2; i++) {
    words.add(ptr.elementAt(i).value);
  }
  print(words.map((word) => word.toHexString(16)).join(', '));
}

/// Converts a Dart string to a natively-allocated string.
///
/// The receiver is responsible for disposing its memory, typically by calling
/// [free] when it has been used.
LPWSTR TEXT(String string) => string.toNativeUtf16();

/// Takes a `HSTRING` (a WinRT String handle), and converts it to a Dart
/// `String`.
///
/// {@category winrt}
String convertFromHString(int hstring) =>
    WindowsGetStringRawBuffer(hstring, nullptr).toDartString();

/// Takes a Dart String and converts it to an `HSTRING` (a WinRT String),
/// returning an integer handle.
///
/// The caller is responsible for deleting the `HSTRING` when it is no longer
/// used, through a call to `WindowsDeleteString(HSTRING hstr)`, which
/// decrements the reference count of that string. If the reference count
/// reaches 0, the Windows Runtime deallocates the buffer.
///
/// {@category winrt}
int convertToHString(String string) {
  final hString = calloc<HSTRING>();
  final stringPtr = string.toNativeUtf16();
  // Create a HSTRING representing the object
  try {
    final hr = WindowsCreateString(stringPtr, string.length, hString);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    } else {
      return hString.value;
    }
  } finally {
    free(stringPtr);
  }
}

/// Allocates memory for a Unicode string and returns a pointer.
///
/// The parameter indicates how many characters should be allocated. The
/// receiver is responsible for disposing the memory allocated, typically by
/// calling [free] when it is no longer required.
LPWSTR wsalloc(int wChars) => calloc<WCHAR>(wChars).cast();

/// Frees allocated memory.
///
/// `calloc.free` and `malloc.free` do the same thing, so this works regardless
/// of whether memory was zero-allocated on creation or not.
void free(Pointer pointer) => calloc.free(pointer);
