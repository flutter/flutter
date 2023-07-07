// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates simple GDI drawing and min/max window sizing

import 'dart:ffi';
import 'dart:math' show min, max;

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

final abc = [
  'anteater',
  'bear',
  'cougar',
  'dingo',
  'elephant',
  'falcon',
  'gazelle',
  'hyena',
  'iguana',
  'jackal',
  'kangaroo',
  'llama',
  'moose',
  'newt',
  'octopus',
  'penguin',
  'quail',
  'rat',
  'squid',
  'tortoise',
  'urus',
  'vole',
  'walrus',
  'xylophone',
  'yak',
  'zebra',
  'This line contains words, but no character. Go figure.',
  ''
];

late int xClient; // width of client area
late int yClient; // height of client area
late int xClientMax; // maximum width of client area

late int xChar; // horizontal scrolling unit
late int yChar; // vertical scrolling unit
late int xUpper; // average width of uppercase letters

late int xPos; // current horizontal scrolling position
late int yPos; // current vertical scrolling position

int mainWindowProc(int hwnd, int uMsg, int wParam, int lParam) {
  switch (uMsg) {
    case WM_CREATE:
      // Get the handle to the client area's device context.
      final hdc = GetDC(hwnd);

      // Extract font dimensions from the text metrics.
      final tm = calloc<TEXTMETRIC>();
      GetTextMetrics(hdc, tm);
      xChar = tm.ref.tmAveCharWidth;
      xUpper = (tm.ref.tmPitchAndFamily & 1 == 1 ? 3 : 2) * xChar ~/ 2;
      yChar = tm.ref.tmHeight + tm.ref.tmExternalLeading;

      // Free the device context.
      ReleaseDC(hwnd, hdc);

      // Set an arbitrary maximum width for client area.
      // (xClientMax is the sum of the widths of 48 average
      // lowercase letters and 12 uppercase letters.)
      xClientMax = 48 * xChar + 12 * xUpper;

      free(tm);

      return 0;

    case WM_SIZE:

      // Retrieve the dimensions of the client area.
      yClient = HIWORD(lParam);
      xClient = LOWORD(lParam);

      // Set the vertical scrolling range and page size
      final si = calloc<SCROLLINFO>()
        ..ref.cbSize = sizeOf<SCROLLINFO>()
        ..ref.fMask = SIF_RANGE | SIF_PAGE
        ..ref.nMin = 0
        ..ref.nMax = abc.length - 1
        ..ref.nPage = yClient ~/ yChar;
      SetScrollInfo(hwnd, SB_VERT, si, TRUE);

      // Set the horizontal scrolling range and page size.
      si.ref.cbSize = sizeOf<SCROLLINFO>();
      si.ref.fMask = SIF_RANGE | SIF_PAGE;
      si.ref.nMin = 0;
      si.ref.nMax = 2 + xClientMax ~/ xChar;
      si.ref.nPage = xClient ~/ xChar;
      SetScrollInfo(hwnd, SB_HORZ, si, TRUE);

      free(si);

      return 0;

    case WM_HSCROLL:
      final si = calloc<SCROLLINFO>();

      // Get all the vertial scroll bar information.
      si.ref.cbSize = sizeOf<SCROLLINFO>();
      si.ref.fMask = SIF_ALL;

      // Save the position for comparison later on.
      GetScrollInfo(hwnd, SB_HORZ, si);
      xPos = si.ref.nPos;
      switch (LOWORD(wParam)) {
        // User clicked the left arrow.
        case SB_LINELEFT:
          si.ref.nPos -= 1;
          break;

        // User clicked the right arrow.
        case SB_LINERIGHT:
          si.ref.nPos += 1;
          break;

        // User clicked the scroll bar shaft left of the scroll box.
        case SB_PAGELEFT:
          si.ref.nPos -= si.ref.nPage;
          break;

        // User clicked the scroll bar shaft right of the scroll box.
        case SB_PAGERIGHT:
          si.ref.nPos += si.ref.nPage;
          break;

        // User dragged the scroll box.
        case SB_THUMBTRACK:
          si.ref.nPos = si.ref.nTrackPos;
          break;

        default:
          break;
      }

      // Set the position and then retrieve it.  Due to adjustments
      // by Windows it may not be the same as the value set.
      si.ref.fMask = SIF_POS;
      SetScrollInfo(hwnd, SB_HORZ, si, TRUE);
      GetScrollInfo(hwnd, SB_HORZ, si);

      // If the position has changed, scroll the window.
      if (si.ref.nPos != xPos) {
        ScrollWindow(hwnd, xChar * (xPos - si.ref.nPos), 0, nullptr, nullptr);
      }

      free(si);
      return 0;

    case WM_VSCROLL:
      final si = calloc<SCROLLINFO>();

      // Get all the vertial scroll bar information.
      si.ref.cbSize = sizeOf<SCROLLINFO>();
      si.ref.fMask = SIF_ALL;
      GetScrollInfo(hwnd, SB_VERT, si);

      // Save the position for comparison later on.
      yPos = si.ref.nPos;
      switch (LOWORD(wParam)) {
        // User clicked the HOME keyboard key.
        case SB_TOP:
          si.ref.nPos = si.ref.nMin;
          break;

        // User clicked the END keyboard key.
        case SB_BOTTOM:
          si.ref.nPos = si.ref.nMax;
          break;

        // User clicked the top arrow.
        case SB_LINEUP:
          si.ref.nPos -= 1;
          break;

        // User clicked the bottom arrow.
        case SB_LINEDOWN:
          si.ref.nPos += 1;
          break;

        // User clicked the scroll bar shaft above the scroll box.
        case SB_PAGEUP:
          si.ref.nPos -= si.ref.nPage;
          break;

        // User clicked the scroll bar shaft below the scroll box.
        case SB_PAGEDOWN:
          si.ref.nPos += si.ref.nPage;
          break;

        // User dragged the scroll box.
        case SB_THUMBTRACK:
          si.ref.nPos = si.ref.nTrackPos;
          break;

        default:
          break;
      }

      // Set the position and then retrieve it. Due to adjustments
      // by Windows it may not be the same as the value set.
      si.ref.fMask = SIF_POS;
      SetScrollInfo(hwnd, SB_VERT, si, TRUE);
      GetScrollInfo(hwnd, SB_VERT, si);

      // If the position has changed, scroll window and update it.
      if (si.ref.nPos != yPos) {
        ScrollWindow(hwnd, 0, yChar * (yPos - si.ref.nPos), nullptr, nullptr);
        UpdateWindow(hwnd);
      }

      free(si);
      return 0;

    case WM_PAINT:
      final ps = calloc<PAINTSTRUCT>();
      final si = calloc<SCROLLINFO>();

      // Prepare the window for painting.
      final hdc = BeginPaint(hwnd, ps);

      // Get vertical scroll bar position.
      si.ref.cbSize = sizeOf<SCROLLINFO>();
      si.ref.fMask = SIF_POS;
      GetScrollInfo(hwnd, SB_VERT, si);
      yPos = si.ref.nPos;

      // Get horizontal scroll bar position.
      GetScrollInfo(hwnd, SB_HORZ, si);
      xPos = si.ref.nPos;

      // Find painting limits.
      final firstLine = max(0, yPos + (ps.ref.rcPaint.top ~/ yChar));
      final lastLine =
          min(abc.length - 1, yPos + (ps.ref.rcPaint.bottom ~/ yChar));

      for (var i = firstLine; i <= lastLine; i++) {
        final x = xChar * (1 - xPos);
        final y = yChar * (i - yPos);

        // Write a line of text to the client area.
        TextOut(hdc, x, y, TEXT(abc[i]), abc[i].length);
      }

      // Indicate that painting is finished.
      EndPaint(hwnd, ps);
      free(ps);
      free(si);
      return 0;

    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;
  }

  return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

void main() => initApp(winMain);

void winMain(int hInstance, List<String> args, int nShowCmd) {
  // Register the window class.
  final className = TEXT('Scrollbar Sample');

  final wc = calloc<WNDCLASS>()
    ..ref.style = CS_HREDRAW | CS_VREDRAW
    ..ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(mainWindowProc, 0)
    ..ref.hInstance = hInstance
    ..ref.lpszClassName = className
    ..ref.hCursor = LoadCursor(NULL, IDC_ARROW)
    ..ref.hbrBackground = GetStockObject(WHITE_BRUSH);
  RegisterClass(wc);

  // Create the window.

  final hWnd = CreateWindowEx(
      0, // Optional window styles.
      className, // Window class
      className, // Window caption
      WS_OVERLAPPEDWINDOW | WS_VSCROLL | WS_HSCROLL, // Window style

      // Size and position
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      250,
      250,
      NULL, // Parent window
      NULL, // Menu
      hInstance, // Instance handle
      nullptr // Additional application data
      );

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
}
