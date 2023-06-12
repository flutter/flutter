// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Demonstrates using hooks.

// Installs a low-level keyboard hook that changes every 'A' keypress to 'B'.
// Also adds a window that shows keystrokes entered.

// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart';

const LLKHF_INJECTED = 0x00000010;
const VK_A = 0x41;
const VK_B = 0x42;

const szTop = "Message        Key          Char       Scan Ext ALT Prev Tran";
const szUnd = "_______        ___          ____       ____ ___ ___ ____ ____";
final pszTop = TEXT(szTop);
final pszUnd = TEXT(szUnd);

const messages = <String>[
  'WM_KEYDOWN',
  'WM_KEYUP',
  'WM_CHAR',
  'WM_DEADCHAR',
  'WM_SYSKEYDOWN',
  'WM_SYSKEYUP',
  'WM_SYSCHAR',
  'WM_SYSDEADCHAR'
];

int /* HHOOK */ keyHook = 0;

final Pointer<RECT> rectScroll = calloc<RECT>();
int hdc = 0;
int cxClient = 0;
int cyClient = 0;
int cxClientMax = 0;
int cyClientMax = 0;
int cLinesMax = 0;
int cLines = 0;
int cxChar = 0;
int cyChar = 0;

class Message {
  final int uMsg;
  final int wParam;
  final int lParam;

  const Message(this.uMsg, this.wParam, this.lParam);
}

final List<Message> msgArr = <Message>[];
final className = TEXT('Keyboard Hook WndClass');
final windowCaption = TEXT('Keyboard message viewer');

int lowlevelKeyboardHookProc(int code, int wParam, int lParam) {
  if (code == HC_ACTION) {
    // Windows controls this memory; don't deallocate it.
    final kbs = Pointer<KBDLLHOOKSTRUCT>.fromAddress(lParam);

    if ((kbs.ref.flags & LLKHF_INJECTED) == 0) {
      final input = calloc<INPUT>();
      input.ref.type = INPUT_KEYBOARD;
      input.ref.ki.dwFlags = (wParam == WM_KEYDOWN) ? 0 : KEYEVENTF_KEYUP;

      // Demonstrate that we're successfully intercepting codes
      if (wParam == WM_KEYUP && kbs.ref.vkCode > 0 && kbs.ref.vkCode < 128) {
        stdout.write(String.fromCharCode(kbs.ref.vkCode));
      }

      // Swap 'A' with 'B' in output
      input.ref.ki.wVk = kbs.ref.vkCode == VK_A ? VK_B : kbs.ref.vkCode;
      SendInput(1, input, sizeOf<INPUT>());
      free(input);
      return -1;
    }
  }
  return CallNextHookEx(keyHook, code, wParam, lParam);
}

int mainWindowProc(int hWnd, int uMsg, int wParam, int lParam) {
  switch (uMsg) {
    case WM_CREATE:
    case WM_DISPLAYCHANGE:
      final textMetrics = calloc<TEXTMETRIC>();

      // Get maximum size of client area
      cxClientMax = GetSystemMetrics(SM_CXMAXIMIZED);
      cyClientMax = GetSystemMetrics(SM_CYMAXIMIZED);

      hdc = GetDC(hWnd);

      SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));
      GetTextMetrics(hdc, textMetrics);
      cxChar = textMetrics.ref.tmAveCharWidth;
      cyChar = textMetrics.ref.tmHeight;
      cLinesMax = cyClientMax ~/ cyChar;
      cLines = 0;

      ReleaseDC(hWnd, hdc);
      free(textMetrics);
      continue resize;

    resize:
    case WM_SIZE:
      if (uMsg == WM_SIZE) {
        cxClient = LOWORD(lParam);
        cyClient = HIWORD(lParam);
      }

      // Calculate scroll rectangle
      rectScroll.ref.left = 0;
      rectScroll.ref.right = cxClient;
      rectScroll.ref.top = cyChar;
      rectScroll.ref.bottom = cyChar * (cyClient ~/ cyChar);

      InvalidateRect(hWnd, nullptr, TRUE);
      return 0;

    case WM_KEYDOWN:
    case WM_KEYUP:
    case WM_CHAR:
    case WM_DEADCHAR:
    case WM_SYSKEYDOWN:
    case WM_SYSKEYUP:
    case WM_SYSCHAR:
    case WM_SYSDEADCHAR:
      msgArr.add(Message(uMsg, wParam, lParam));
      cLines = min(cLines + 1, cLinesMax);

      // Scroll up
      ScrollWindow(hWnd, 0, -cyChar, rectScroll, rectScroll);
      InvalidateRect(hWnd, nullptr, TRUE);

      break;

    case WM_PAINT:
      final ps = calloc<PAINTSTRUCT>();
      final hdc = BeginPaint(hWnd, ps);

      SelectObject(hdc, GetStockObject(SYSTEM_FIXED_FONT));
      SetBkMode(hdc, TRANSPARENT);
      TextOut(hdc, 0, 0, pszTop, szTop.length);
      TextOut(hdc, 0, 0, pszUnd, szUnd.length);

      var index = 0;
      for (final msg in msgArr) {
        final iType = msg.uMsg == WM_CHAR ||
            msg.uMsg == WM_SYSCHAR ||
            msg.uMsg == WM_DEADCHAR ||
            msg.uMsg == WM_SYSDEADCHAR;

        final pszKeyName = wsalloc(256);
        GetKeyNameText(msg.lParam, pszKeyName, 256);
        final keyName = pszKeyName.toDartString();
        free(pszKeyName);

        final szBuffer = '${messages[msg.uMsg - WM_KEYDOWN].padRight(15)}'
            '${msg.wParam.toString().padRight(3)}'
            '${!iType ? keyName.padRight(3) : '   '}'
            '${String.fromCharCode(msg.wParam).padRight(6)} '
            '${LOWORD(msg.lParam).toHexString(8).substring(2)} '
            '${(HIWORD(msg.lParam) & 0xFF).toHexString(8).substring(2)}      '
            '${msg.lParam & 0x01000000 == 0x01000000 ? 'Yes' : 'No '}  '
            '${msg.lParam & 0x02000000 == 0x02000000 ? 'Yes' : 'No '}   '
            '${msg.lParam & 0x04000000 == 0x04000000 ? 'Down' : 'Up  '}  '
            '${msg.lParam & 0x08000000 == 0x08000000 ? 'Up  ' : 'Down'} ';
        final pszBuffer = szBuffer.toNativeUtf16();
        TextOut(hdc, 0, ((cyClient ~/ cyChar) - 1 - index++) * cyChar,
            pszBuffer, szBuffer.length);
        free(pszBuffer);
      }

      EndPaint(hWnd, ps);

      free(ps);

      return 0;

    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;
  }
  return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

void main() => initApp(winMain);

void winMain(int hInstance, List<String> args, int nShowCmd) {
  keyHook = SetWindowsHookEx(WH_KEYBOARD_LL,
      Pointer.fromFunction<CallWndProc>(lowlevelKeyboardHookProc, 0), NULL, 0);

  final wc = calloc<WNDCLASS>()
    ..ref.style = CS_HREDRAW | CS_VREDRAW
    ..ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(mainWindowProc, 0)
    ..ref.hInstance = hInstance
    ..ref.lpszClassName = className
    ..ref.hIcon = LoadIcon(NULL, IDI_APPLICATION)
    ..ref.hCursor = LoadCursor(NULL, IDC_ARROW)
    ..ref.hbrBackground = GetStockObject(WHITE_BRUSH);
  RegisterClass(wc);

  final hWnd = CreateWindow(
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

  ShowWindow(hWnd, nShowCmd);
  UpdateWindow(hWnd);

  final msg = calloc<MSG>();
  while (GetMessage(msg, NULL, 0, 0) != 0) {
    TranslateMessage(msg);
    DispatchMessage(msg);
  }
}
