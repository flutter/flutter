// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic Petzoldian "hello world" Win32 app

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';

int mainWindowProc(int hWnd, int uMsg, int wParam, int lParam) {
  switch (uMsg) {
    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;

    case WM_PAINT:
      final ps = calloc<PAINTSTRUCT>();
      final hdc = BeginPaint(hWnd, ps);
      final rect = calloc<RECT>();
      final msg = TEXT('Hello, Dart!');

      GetClientRect(hWnd, rect);
      DrawText(hdc, msg, -1, rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
      EndPaint(hWnd, ps);

      free(ps);
      free(rect);
      free(msg);

      return 0;
  }
  return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

// An optional approach to launching a GUI app that lets you use a more
// traditional WinMain entry point, rather than having to manually retrieve the
// hInstance and nShowCmd parameters.
void main() => initApp(winMain);

void winMain(int hInstance, List<String> args, int nShowCmd) {
  // Register the window class.
  final className = TEXT('Sample Window Class');
  final wc = calloc<WNDCLASS>()
    ..ref.style = CS_HREDRAW | CS_VREDRAW
    ..ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(mainWindowProc, 0)
    ..ref.hInstance = hInstance
    ..ref.lpszClassName = className
    ..ref.hCursor = LoadCursor(NULL, IDC_ARROW)
    ..ref.hbrBackground = GetStockObject(WHITE_BRUSH);
  RegisterClass(wc);

  // Create the window.
  final windowCaption = TEXT('Dart Native Win32 window');
  final hWnd = CreateWindowEx(
      0, // Optional window styles.
      className, // Window class
      windowCaption, // Window caption
      WS_OVERLAPPEDWINDOW, // Window style

      // Size and position
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      NULL, // Parent window
      NULL, // Menu
      hInstance, // Instance handle
      nullptr // Additional application data
      );
  free(windowCaption);
  free(className);

  if (hWnd == 0) {
    final error = GetLastError();
    throw WindowsException(HRESULT_FROM_WIN32(error));
  }

  ShowWindow(hWnd, nShowCmd);
  UpdateWindow(hWnd);

  // Run the message loop.
  final msg = calloc<MSG>();
  while (GetMessage(msg, NULL, 0, 0) != 0) {
    TranslateMessage(msg);
    DispatchMessage(msg);
  }

  free(msg);
}
