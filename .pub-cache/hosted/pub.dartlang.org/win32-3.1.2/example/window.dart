// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Enumerates open windows and demonstrates basic window manipulation

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';

// Callback for each window found
int enumWindowsProc(int hWnd, int lParam) {
  // Don't enumerate windows unless they are marked as WS_VISIBLE
  if (IsWindowVisible(hWnd) == FALSE) return TRUE;

  final length = GetWindowTextLength(hWnd);
  if (length == 0) {
    return TRUE;
  }

  final buffer = wsalloc(length + 1);
  GetWindowText(hWnd, buffer, length + 1);
  print('hWnd $hWnd: ${buffer.toDartString()}');
  free(buffer);

  return TRUE;
}

/// List the window handle and text for all top-level desktop windows
/// in the current session.
void enumerateWindows() {
  final wndProc = Pointer.fromFunction<EnumWindowsProc>(enumWindowsProc, 0);

  EnumWindows(wndProc, 0);
}

/// Find the first open Notepad window and maximize it
void findNotepad() {
  final hwnd = FindWindowEx(0, 0, TEXT('Notepad'), nullptr);

  if (hwnd == 0) {
    print('No Notepad window found.');
  } else {
    ShowWindow(hwnd, SW_MAXIMIZE);
  }
}

void main() {
  enumerateWindows();
  findNotepad();
}
