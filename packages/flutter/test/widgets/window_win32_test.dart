// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/semantics.dart';
import 'package:flutter/src/foundation/binding.dart';

import 'package:flutter/src/widgets/_window_win32.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Win32 window test', () {
    group('Platform.isWindows is false', () {
      setUp(() {
        Platform.isWindows = false;
      });

      test('WindowingOwnerWin32 constructor throws when not on windows', () {
        expect(() => WindowingOwnerWin32(), throwsUnsupportedError);
      });
    });

    testWidgets('WindowingOwner32 constructor does NOT throw when on windows', (
      WidgetTester tester,
    ) async {
      WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(),
        platformDispatcher: tester.platformDispatcher,
      );
    });
  });
}

class _MockWin32PlatformInterface extends Win32PlatformInterface {
  _MockWin32PlatformInterface({
    this.onInitialize,
    this.onCreateWindow,
    this.onDestroyWindow,
    this.onGetContentSize,
    this.onSetTitle,
    this.onSetContentSize,
    this.onSetConstraints,
    this.onShowWindow,
    this.onIsIconic,
    this.onIsZoomed,
    this.onSetFullscreen,
    this.onGetFullscreen,
    this.onGetWindowTextLength,
    this.onGetWindowText,
    this.onGetForegroundWindow,
  });

  final int viewId = 1;
  final HWND hwnd = Pointer<Void>.fromAddress(0x8000);
  final bool _hasToplevelWindows = true;
  Pointer<ActualContentSize>? size;

  final void Function(WindowingInitRequest)? onInitialize;
  final void Function(int, WindowCreationRequest)? onCreateWindow;
  final void Function(HWND)? onDestroyWindow;
  final void Function(HWND)? onGetContentSize;
  final void Function(HWND, Pointer<ffi.Utf16>)? onSetTitle;
  final void Function(HWND, WindowSizeRequest)? onSetContentSize;
  final void Function(HWND, WindowConstraintsRequest)? onSetConstraints;
  final void Function(HWND, int)? onShowWindow;
  final void Function(HWND)? onIsIconic;
  final void Function(HWND)? onIsZoomed;
  final void Function(HWND, WindowFullscreenRequest)? onSetFullscreen;
  final void Function(HWND)? onGetFullscreen;
  final void Function(HWND)? onGetWindowTextLength;
  final void Function(HWND, Pointer<ffi.Utf16>, int)? onGetWindowText;
  final VoidCallback? onGetForegroundWindow;

  @override
  bool hasTopLevelWindows(int engineId) {
    return _hasToplevelWindows;
  }

  @override
  void initialize(int engineId, Pointer<WindowingInitRequest> request) {
    onInitialize?.call(request.ref);
  }

  @override
  int createWindow(int engineId, Pointer<WindowCreationRequest> request) {
    onCreateWindow?.call(engineId, request.ref);
    return viewId;
  }

  @override
  HWND getWindowHandle(int engineId, int viewId) {
    return hwnd;
  }

  @override
  void destroyWindow(HWND windowHandle) {
    onDestroyWindow?.call(windowHandle);
  }

  @override
  ActualContentSize getWindowContentSize(HWND windowHandle) {
    onGetContentSize?.call(windowHandle);
    size = ffi.calloc<ActualContentSize>();
    size!.ref.width = 800;
    size!.ref.height = 600;
    return size!.ref;
  }

  @override
  void setWindowTitle(HWND windowHandle, Pointer<ffi.Utf16> title) {
    onSetTitle?.call(windowHandle, title);
  }

  @override
  void setWindowContentSize(HWND windowHandle, Pointer<WindowSizeRequest> size) {
    onSetContentSize?.call(windowHandle, size.ref);
  }

  @override
  void setWindowConstraints(HWND windowHandle, Pointer<WindowConstraintsRequest> constraints) {
    onSetConstraints?.call(windowHandle, constraints.ref);
  }

  @override
  void showWindow(HWND windowHandle, int command) {
    onShowWindow?.call(windowHandle, command);
  }

  @override
  int isIconic(HWND windowHandle) {
    onIsIconic?.call(windowHandle);
    return 0;
  }

  @override
  int isZoomed(HWND windowHandle) {
    onIsZoomed?.call(windowHandle);
    return 0;
  }

  @override
  void setFullscreen(HWND windowHandle, Pointer<WindowFullscreenRequest> request) {
    onSetFullscreen?.call(windowHandle, request.ref);
  }

  @override
  bool getFullscreen(HWND windowHandle) {
    onGetFullscreen?.call(windowHandle);
    return false;
  }

  @override
  int getWindowTextLength(HWND windowHandle) {
    onGetWindowTextLength?.call(windowHandle);
    return 0;
  }

  @override
  int getWindowText(HWND windowHandle, Pointer<ffi.Utf16> lpString, int maxLength) {
    onGetWindowText?.call(windowHandle, lpString, maxLength);
    return 0;
  }

  @override
  HWND getForegroundWindow() {
    onGetForegroundWindow?.call();
    return hwnd;
  }
}
