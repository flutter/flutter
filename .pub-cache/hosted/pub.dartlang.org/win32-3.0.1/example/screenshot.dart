// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Capture a screenshot.
// Example comes from:
//   https://docs.microsoft.com/en-us/windows/win32/gdi/capturing-an-image

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';

final hInstance = GetModuleHandle(nullptr);

void captureImage(int hwnd) {
  final hdcScreen = GetDC(NULL);
  final hdcWindow = GetDC(hwnd);

  final hdcMemDC = CreateCompatibleDC(hdcWindow);
  final bmpScreen = calloc<BITMAP>();

  try {
    if (hdcMemDC == 0) {
      MessageBox(
          hwnd, TEXT('CreateCompatibleDC failed.'), TEXT('Failed'), MB_OK);
      return;
    }

    final rcClient = calloc<RECT>();
    GetClientRect(hwnd, rcClient);

    SetStretchBltMode(hdcWindow, HALFTONE);

    StretchBlt(
        hdcWindow,
        0,
        0,
        rcClient.ref.right,
        rcClient.ref.bottom,
        hdcScreen,
        0,
        0,
        GetSystemMetrics(SM_CXSCREEN),
        GetSystemMetrics(SM_CYSCREEN),
        SRCCOPY);

    final hbmScreen = CreateCompatibleBitmap(
        hdcWindow,
        rcClient.ref.right - rcClient.ref.left,
        rcClient.ref.bottom - rcClient.ref.top);

    SelectObject(hdcMemDC, hbmScreen);

    BitBlt(hdcMemDC, 0, 0, rcClient.ref.right - rcClient.ref.left,
        rcClient.ref.bottom - rcClient.ref.top, hdcWindow, 0, 0, SRCCOPY);

    GetObject(hbmScreen, sizeOf<BITMAP>(), bmpScreen);

    final bitmapFileHeader = calloc<BITMAPFILEHEADER>();
    final bitmapInfoHeader = calloc<BITMAPINFOHEADER>()
      ..ref.biSize = sizeOf<BITMAPINFOHEADER>()
      ..ref.biWidth = bmpScreen.ref.bmWidth
      ..ref.biHeight = bmpScreen.ref.bmHeight
      ..ref.biPlanes = 1
      ..ref.biBitCount = 32
      ..ref.biCompression = BI_RGB;

    final dwBmpSize =
        ((bmpScreen.ref.bmWidth * bitmapInfoHeader.ref.biBitCount + 31) /
                32 *
                4 *
                bmpScreen.ref.bmHeight)
            .toInt();

    final lpBitmap = calloc<Uint8>(dwBmpSize);

    GetDIBits(hdcWindow, hbmScreen, 0, bmpScreen.ref.bmHeight, lpBitmap,
        bitmapInfoHeader.cast(), DIB_RGB_COLORS);

    final hFile = CreateFile(TEXT('captureqwsz.bmp'), GENERIC_WRITE, 0, nullptr,
        CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

    final dwSizeOfDIB =
        dwBmpSize + sizeOf<BITMAPFILEHEADER>() + sizeOf<BITMAPINFOHEADER>();
    bitmapFileHeader.ref.bfOffBits =
        sizeOf<BITMAPFILEHEADER>() + sizeOf<BITMAPINFOHEADER>();

    bitmapFileHeader.ref.bfSize = dwSizeOfDIB;
    bitmapFileHeader.ref.bfType = 0x4D42; // BM

    final dwBytesWritten = calloc<DWORD>();
    WriteFile(hFile, bitmapFileHeader, sizeOf<BITMAPFILEHEADER>(),
        dwBytesWritten, nullptr);
    WriteFile(hFile, bitmapInfoHeader, sizeOf<BITMAPINFOHEADER>(),
        dwBytesWritten, nullptr);
    WriteFile(hFile, lpBitmap, dwBmpSize, dwBytesWritten, nullptr);

    CloseHandle(hFile);
  } finally {
    DeleteObject(hdcMemDC);
    ReleaseDC(NULL, hdcScreen);
    ReleaseDC(hwnd, hdcWindow);
  }
}

int mainWindowProc(int hWnd, int uMsg, int wParam, int lParam) {
  switch (uMsg) {
    case WM_COMMAND:
      final wmid = LOWORD(wParam);
      switch (wmid) {
        default:
          return DefWindowProc(hWnd, uMsg, wParam, lParam);
      }
    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;

    case WM_PAINT:
      final ps = calloc<PAINTSTRUCT>();
      BeginPaint(hWnd, ps);
      captureImage(hWnd);
      EndPaint(hWnd, ps);

      free(ps);
      return 0;
  }
  return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

void main() {
  // Register the window class.
  final className = TEXT('GDI Image Capture');

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
      WS_OVERLAPPEDWINDOW, // Window style

      // Size and position
      CW_USEDEFAULT,
      0,
      CW_USEDEFAULT,
      0,
      NULL, // Parent window
      NULL, // Menu
      hInstance, // Instance handle
      nullptr // Additional application data
      );

  if (hWnd == FALSE) {
    exit(-1);
  }

  ShowWindow(hWnd, SW_SHOWNORMAL);
  UpdateWindow(hWnd);

  // Run the message loop
  final msg = calloc<MSG>();
  while (GetMessage(msg, NULL, 0, 0) != FALSE) {
    TranslateMessage(msg);
    DispatchMessage(msg);
  }
}
