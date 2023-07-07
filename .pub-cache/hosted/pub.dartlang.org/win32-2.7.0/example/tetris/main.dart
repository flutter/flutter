// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'drawengine.dart';
import 'game.dart';

const PX_PER_BLOCK = 25; // Cell size in pixels
const SCREEN_WIDTH = 10; // Level width in cells
const SCREEN_HEIGHT = 20; // Level height in cells
const GAME_SPEED = 33; // Update the game every GAME_SPEED ms (= 1000/fps)
const TIMER_ID = 1;

final hInstance = GetModuleHandle(nullptr);
late Game game;
late DrawEngine de;

void main() {
  final szAppName = TEXT('Tetris');

  final wc = calloc<WNDCLASS>()
    ..ref.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC
    ..ref.lpfnWndProc = Pointer.fromFunction<WindowProc>(mainWindowProc, 0)
    ..ref.hInstance = hInstance
    ..ref.hIcon = LoadIcon(NULL, IDI_APPLICATION)
    ..ref.hCursor = LoadCursor(NULL, IDC_ARROW)
    ..ref.hbrBackground = GetStockObject(BLACK_BRUSH)
    ..ref.lpszClassName = szAppName;
  RegisterClass(wc);

  final hWnd = CreateWindowEx(
      0, // Optional window styles.
      szAppName, // Window class
      szAppName, // Window text
      WS_MINIMIZEBOX | WS_SYSMENU, // Window style

      // Size and position
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      SCREEN_WIDTH * PX_PER_BLOCK + 156,
      SCREEN_HEIGHT * PX_PER_BLOCK + 25,
      NULL, // Parent window
      NULL, // Menu
      hInstance, // Instance handle
      nullptr // Additional application data
      );

  if (hWnd == 0) {
    stderr.writeln('CreateWindowEx failed with error: ${GetLastError()}');
    exit(-1);
  }

  ShowWindow(hWnd, SW_SHOWNORMAL);
  UpdateWindow(hWnd);

  // Run the message loop.

  final msg = calloc<MSG>();
  while (GetMessage(msg, NULL, 0, 0) != 0) {
    TranslateMessage(msg);
    DispatchMessage(msg);
  }
}

int mainWindowProc(int hwnd, int uMsg, int wParam, int lParam) {
  int hdc;
  var result = 0;

  final ps = calloc<PAINTSTRUCT>();

  switch (uMsg) {
    case WM_CREATE:
      hdc = GetDC(hwnd);

      de = DrawEngine(hdc, hwnd, PX_PER_BLOCK);
      game = Game(de);
      SetTimer(hwnd, TIMER_ID, GAME_SPEED, nullptr);

      ReleaseDC(hwnd, hdc);
      break;

    case WM_KEYDOWN:
      game.keyPress(wParam);
      break;

    case WM_TIMER:
      game.timerUpdate();
      break;

    case WM_KILLFOCUS:
      KillTimer(hwnd, TIMER_ID);
      game.pauseGame();
      break;

    case WM_SETFOCUS:
      SetTimer(hwnd, TIMER_ID, GAME_SPEED, nullptr);
      break;

    case WM_PAINT:
      hdc = BeginPaint(hwnd, ps);
      game.repaint();
      EndPaint(hwnd, ps);
      break;

    case WM_DESTROY:
      KillTimer(hwnd, TIMER_ID);
      PostQuitMessage(0);
      break;

    default:
      result = DefWindowProc(hwnd, uMsg, wParam, lParam);
  }

  free(ps);

  return result;
}
