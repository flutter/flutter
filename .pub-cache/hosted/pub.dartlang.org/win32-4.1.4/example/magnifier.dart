// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Implements a simple control that magnifies the screen, using the
// Magnification API.

// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';

// For simplicity, the sample uses a constant magnification factor
const MAGFACTOR = 2.0;
const RESTOREDWINDOWSTYLES =
    WS_SIZEBOX | WS_SYSMENU | WS_CLIPCHILDREN | WS_CAPTION | WS_MAXIMIZEBOX;

const timerInterval = 16;
final windowClassName = TEXT('MagnifierWindow');
final windowTitle = TEXT('Screen Magnifier Sample');

// Global variables
int hwndMag = 0;
int hwndHost = 0;
final magWindowRect = calloc<RECT>();
final hostWindowRect = calloc<RECT>();
bool isFullScreen = false;

void main() => initApp(winMain);

/// Entry point for the application
void winMain(int hInstance, List<String> args, int nCmdShow) {
  if (MagInitialize() == FALSE || !setupMagnifier(hInstance)) {
    return;
  }

  ShowWindow(hwndHost, nCmdShow);
  UpdateWindow(hwndHost);

  // Create a timer to update the control
  final timerId = SetTimer(hwndHost, 0, timerInterval,
      Pointer.fromFunction<TimerProc>(updateMagWindow));

  // Main message loop
  final msg = calloc<MSG>();
  while (GetMessage(msg, NULL, 0, 0) == TRUE) {
    TranslateMessage(msg);
    DispatchMessage(msg);
  }

  // Shut down
  KillTimer(NULL, timerId);
  MagUninitialize();

  free(msg);
}

/// Window procedure for the window that hosts the magnifier control
int hostWndProc(int hWnd, int message, int wParam, int lParam) {
  switch (message) {
    case WM_KEYDOWN:
      if (wParam == VK_ESCAPE) {
        if (isFullScreen) {
          goPartialScreen();
        }
      }
      break;

    case WM_SYSCOMMAND:
      if (GET_SC_WPARAM(wParam) == SC_MAXIMIZE) {
        goFullScreen();
      } else {
        return DefWindowProc(hWnd, message, wParam, lParam);
      }
      break;

    case WM_DESTROY:
      PostQuitMessage(0);
      break;

    case WM_SIZE:
      if (hwndMag != NULL) {
        GetClientRect(hWnd, magWindowRect);

        // Resize the control to fill the window.
        SetWindowPos(
            hwndMag,
            NULL,
            magWindowRect.ref.left,
            magWindowRect.ref.top,
            magWindowRect.ref.right,
            magWindowRect.ref.bottom,
            0);
      }
      break;

    default:
      return DefWindowProc(hWnd, message, wParam, lParam);
  }
  return 0;
}

/// Registers the window class for the window that contains the magnification
/// control.
int registerHostWindowClass(int hInstance) {
  final wcex = calloc<WNDCLASSEX>()
    ..ref.cbSize = sizeOf<WNDCLASSEX>()
    ..ref.style = CS_HREDRAW | CS_VREDRAW
    ..ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(hostWndProc, 0)
    ..ref.hInstance = hInstance
    ..ref.hCursor = LoadCursor(NULL, IDC_ARROW)
    ..ref.hbrBackground = COLOR_BTNFACE + 1
    ..ref.lpszClassName = windowClassName;

  return RegisterClassEx(wcex);
}

bool setupMagnifier(int hInst) {
  // Set bounds of host window according to screen size
  hostWindowRect
    ..ref.top = 0
    ..ref.bottom = GetSystemMetrics(SM_CYSCREEN) ~/ 4
    ..ref.left = 0
    ..ref.right = GetSystemMetrics(SM_CXSCREEN);

  // Create the host window
  registerHostWindowClass(hInst);
  hwndHost = CreateWindowEx(
      WS_EX_TOPMOST | WS_EX_LAYERED,
      windowClassName,
      windowTitle,
      RESTOREDWINDOWSTYLES,
      0,
      0,
      hostWindowRect.ref.right,
      hostWindowRect.ref.bottom,
      NULL,
      NULL,
      hInst,
      nullptr);

  if (hwndHost == FALSE) return false;

  // Make the window opaque
  SetLayeredWindowAttributes(hwndHost, 0, 255, LWA_ALPHA);

  // Create a magnifier control that fills the client area
  GetClientRect(hwndHost, magWindowRect);
  hwndMag = CreateWindow(
      TEXT('Magnifier'),
      TEXT('MagnifierWindow'),
      WS_CHILD | MS_SHOWMAGNIFIEDCURSOR | WS_VISIBLE,
      magWindowRect.ref.left,
      magWindowRect.ref.top,
      magWindowRect.ref.right,
      magWindowRect.ref.bottom,
      hwndHost,
      NULL,
      hInst,
      nullptr);

  if (hwndMag == FALSE) return false;

  final matrix = calloc<MAGTRANSFORM>();
  final magEffectInvert = calloc<MAGCOLOREFFECT>();

  try {
    // Set the magnification factor
    matrix
      ..ref.v[0] = MAGFACTOR
      ..ref.v[4] = MAGFACTOR
      ..ref.v[7] = 1.0;

    var ret = MagSetWindowTransform(hwndMag, matrix);
    if (ret == TRUE) {
      final transform = magEffectInvert.ref.transform;
      transform[0] = -1.0;
      transform[1] = 0.0;
      transform[2] = 0.0;
      transform[3] = 0.0;
      transform[4] = 0.0;
      transform[5] = 0.0;
      transform[6] = -1.0;
      transform[7] = 0.0;
      transform[8] = 0.0;
      transform[9] = 0.0;
      transform[10] = 0.0;
      transform[11] = 0.0;
      transform[12] = -1.0;
      transform[13] = 0.0;
      transform[14] = 0.0;
      transform[15] = 0.0;
      transform[16] = 0.0;
      transform[17] = 0.0;
      transform[18] = 1.0;
      transform[19] = 0.0;
      transform[20] = 1.0;
      transform[21] = 1.0;
      transform[22] = 1.0;
      transform[23] = 0.0;
      transform[24] = 1.0;
      ret = MagSetColorEffect(hwndMag, magEffectInvert);
    }
    return ret == TRUE;
  } finally {
    free(matrix);
    free(magEffectInvert);
  }
}

/// Sets the source rectangle and updates the window. Called by a timer.
void updateMagWindow(int hwnd, int uMsg, Pointer<Uint32> idEvent, int dwTime) {
  final mousePoint = calloc<POINT>();
  final pSourceRect = calloc<RECT>();

  try {
    final sourceRect = pSourceRect.ref;
    GetCursorPos(mousePoint);

    final width =
        (magWindowRect.ref.right - magWindowRect.ref.left) ~/ MAGFACTOR;
    final height =
        (magWindowRect.ref.bottom - magWindowRect.ref.top) ~/ MAGFACTOR;

    sourceRect
      ..left = mousePoint.ref.x - width ~/ 2
      ..top = mousePoint.ref.y - height ~/ 2;

    // Don't scroll outside desktop area.
    if (sourceRect.left < 0) {
      sourceRect.left = 0;
    }
    if (sourceRect.left > GetSystemMetrics(SM_CXSCREEN) - width) {
      sourceRect.left = GetSystemMetrics(SM_CXSCREEN) - width;
    }
    sourceRect.right = sourceRect.left + width;

    if (sourceRect.top < 0) {
      sourceRect.top = 0;
    }
    if (sourceRect.top > GetSystemMetrics(SM_CYSCREEN) - height) {
      sourceRect.top = GetSystemMetrics(SM_CYSCREEN) - height;
    }
    sourceRect.bottom = sourceRect.top + height;

    // Set the source rectangle for the magnifier control.
    MagSetWindowSource(hwndMag, sourceRect);

    // Reclaim topmost status, to prevent unmagnified menus from remaining in
    // view.
    SetWindowPos(hwndHost, HWND_TOPMOST, 0, 0, 0, 0,
        SWP_NOACTIVATE | SWP_NOMOVE | SWP_NOSIZE);

    // Force redraw.
    InvalidateRect(hwndMag, nullptr, TRUE);
  } finally {
    free(mousePoint);
    free(pSourceRect);
  }
}

/// Makes the host window full-screen by placing non-client elements outside the
/// display.
void goFullScreen() {
  isFullScreen = true;

  // The window must be styled as layered for proper rendering.
  // It is styled as transparent so that it does not capture mouse clicks.
  SetWindowLongPtr(
      hwndHost, GWL_EXSTYLE, WS_EX_TOPMOST | WS_EX_LAYERED | WS_EX_TRANSPARENT);

  // Give the window a system menu so it can be closed on the taskbar.
  SetWindowLongPtr(hwndHost, GWL_STYLE, WS_CAPTION | WS_SYSMENU);

  // Calculate the span of the display area.
  final hDC = GetDC(NULL);
  var xSpan = GetSystemMetrics(SM_CXSCREEN);
  var ySpan = GetSystemMetrics(SM_CYSCREEN);
  ReleaseDC(NULL, hDC);

  // Calculate the size of system elements.
  final xBorder = GetSystemMetrics(SM_CXFRAME);
  final yCaption = GetSystemMetrics(SM_CYCAPTION);
  final yBorder = GetSystemMetrics(SM_CYFRAME);

  // Calculate the window origin and span for full-screen mode.
  final xOrigin = -xBorder;
  final yOrigin = -yBorder - yCaption;
  xSpan += 2 * xBorder;
  ySpan += 2 * yBorder + yCaption;

  SetWindowPos(hwndHost, HWND_TOPMOST, xOrigin, yOrigin, xSpan, ySpan,
      SWP_SHOWWINDOW | SWP_NOZORDER | SWP_NOACTIVATE);
}

/// Makes the host window resizable and focusable.
void goPartialScreen() {
  isFullScreen = false;

  SetWindowLongPtr(hwndHost, GWL_EXSTYLE, WS_EX_TOPMOST | WS_EX_LAYERED);
  SetWindowLongPtr(hwndHost, GWL_STYLE, RESTOREDWINDOWSTYLES);
  SetWindowPos(
      hwndHost,
      HWND_TOPMOST,
      hostWindowRect.ref.left,
      hostWindowRect.ref.top,
      hostWindowRect.ref.right,
      hostWindowRect.ref.bottom,
      SWP_SHOWWINDOW | SWP_NOZORDER | SWP_NOACTIVATE);
}
