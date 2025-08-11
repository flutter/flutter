// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' hide Size;
import 'dart:io';
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/foundation/_features.dart';
import 'package:flutter/src/widgets/_window.dart';

import 'package:flutter/src/widgets/_window_win32.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Win32 window test', () {
    setUp(() {
      isWindowingEnabled = true;
    });

    group('Platform.isWindows is false', () {
      setUp(() {
        Platform.isWindows = false;
      });

      test('WindowingOwnerWin32 constructor throws when not on windows', () {
        expect(() => WindowingOwnerWin32(), throwsUnsupportedError);
      });
    });

    testWidgets('WindowingOwner32 constructor initializes', (WidgetTester tester) async {
      bool isInitialized = false;
      WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onInitialize: (WindowingInitRequest request) => isInitialized = true,
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      expect(isInitialized, true);
    });

    testWidgets('WindowingOwner32 can create a regular window', (WidgetTester tester) async {
      bool hasCreated = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onCreateWindow: (int engineId, WindowCreationRequest request) {
            expect(engineId, tester.platformDispatcher.engineId);
            expect(request.preferredSize.hasSize, true);
            expect(request.preferredSize.width, 400);
            expect(request.preferredSize.height, 300);

            expect(request.preferredConstraints.hasConstraints, true);
            expect(request.preferredConstraints.minWidth, 100);
            expect(request.preferredConstraints.minHeight, 101);
            expect(request.preferredConstraints.maxWidth, 500);
            expect(request.preferredConstraints.maxHeight, 501);
            hasCreated = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      owner.createRegularWindowController(
        preferredSize: const Size(400, 300),
        preferredConstraints: const BoxConstraints(
          minWidth: 100,
          minHeight: 101,
          maxWidth: 500,
          maxHeight: 501,
        ),
        delegate: RegularWindowControllerDelegate(),
      );

      expect(hasCreated, true);
    });

    testWidgets('Sending WM_SIZE to WindowingOwner32 notifies listeners', (
      WidgetTester tester,
    ) async {
      const int WM_SIZE = 0x0005;
      late void Function(Pointer<WindowsMessage>) messageFunc;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onInitialize: (WindowingInitRequest request) {
            messageFunc = request.onMessage.asFunction();
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      bool listenerTriggered = false;
      controller.addListener(() => listenerTriggered = true);
      final Pointer<WindowsMessage> message = ffi.calloc<WindowsMessage>();
      message.ref.viewId = 0;
      message.ref.message = WM_SIZE;
      messageFunc(message);

      expect(listenerTriggered, true);
    });

    testWidgets('Sending WM_ACTIVATE to WindowingOwner32 notifies listeners', (
      WidgetTester tester,
    ) async {
      const int WM_ACTIVATE = 0x0006;
      late void Function(Pointer<WindowsMessage>) messageFunc;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onInitialize: (WindowingInitRequest request) {
            messageFunc = request.onMessage.asFunction();
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      bool listenerTriggered = false;
      controller.addListener(() => listenerTriggered = true);
      final Pointer<WindowsMessage> message = ffi.calloc<WindowsMessage>();
      message.ref.viewId = 0;
      message.ref.message = WM_ACTIVATE;
      messageFunc(message);

      expect(listenerTriggered, true);
    });

    testWidgets('Sending WM_CLOSE message to WindowingOwner32 results in window being destroyed', (
      WidgetTester tester,
    ) async {
      const int WM_CLOSE = 0x0010;
      bool hasDestroyed = false;
      late void Function(Pointer<WindowsMessage>) messageFunc;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onInitialize: (WindowingInitRequest request) {
            messageFunc = request.onMessage.asFunction();
          },
          onDestroyWindow: (HWND hwnd) {
            hasDestroyed = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      owner.createRegularWindowController(delegate: RegularWindowControllerDelegate());

      final Pointer<WindowsMessage> message = ffi.calloc<WindowsMessage>();
      message.ref.viewId = 0;
      message.ref.message = WM_CLOSE;
      messageFunc(message);

      expect(hasDestroyed, true);
    });

    testWidgets('WindowingOwner32 can destroy a regular window', (WidgetTester tester) async {
      bool hasDestroyed = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onDestroyWindow: (HWND hwnd) {
            hasDestroyed = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.destroy();
      expect(hasDestroyed, true);
    });

    testWidgets('WindowingOwner32 can get content size', (WidgetTester tester) async {
      bool hasGottenContentSize = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onGetContentSize: (HWND hwnd) {
            hasGottenContentSize = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.contentSize;
      expect(hasGottenContentSize, true);
    });

    testWidgets('WindowingOwner32 can set title', (WidgetTester tester) async {
      bool hasSetTitle = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onSetTitle: (HWND hwnd, Pointer<ffi.Utf16> title) {
            hasSetTitle = true;
            expect(title.toDartString(), 'Hello world');
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.setTitle('Hello world');
      expect(hasSetTitle, true);
    });

    testWidgets('WindowingOwner32 can set content size', (WidgetTester tester) async {
      bool hasSetSize = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onSetContentSize: (HWND hwnd, WindowSizeRequest request) {
            hasSetSize = true;
            expect(request.hasSize, true);
            expect(request.width, 800);
            expect(request.height, 600);
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.setSize(const Size(800, 600));
      expect(hasSetSize, true);
    });

    testWidgets('WindowingOwner32 can set constraints', (WidgetTester tester) async {
      bool hasSetConstraints = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onSetConstraints: (HWND hwnd, WindowConstraintsRequest request) {
            hasSetConstraints = true;
            expect(request.hasConstraints, true);
            expect(request.minWidth, 100);
            expect(request.minHeight, 101);
            expect(request.maxWidth, 500);
            expect(request.maxHeight, 501);
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.setConstraints(
        const BoxConstraints(minWidth: 100, minHeight: 101, maxWidth: 500, maxHeight: 501),
      );
      expect(hasSetConstraints, true);
    });

    testWidgets('WindowingOwner32 can activate', (WidgetTester tester) async {
      bool hasShown = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onShowWindow: (HWND hwnd, int sw) {
            hasShown = true;
            expect(sw, 9); // SW_RESTORE
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.activate();
      expect(hasShown, true);
    });

    testWidgets('WindowingOwner32 can maximize', (WidgetTester tester) async {
      bool hasMaximized = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onShowWindow: (HWND hwnd, int sw) {
            hasMaximized = true;
            expect(sw, 3); // SW_MAXIMIZE
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.setMaximized(true);
      expect(hasMaximized, true);
    });

    testWidgets('WindowingOwner32 can unmaximize', (WidgetTester tester) async {
      bool hasUnmaximized = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onShowWindow: (HWND hwnd, int sw) {
            hasUnmaximized = true;
            expect(sw, 9); // SW_RESTORE
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.setMaximized(false);
      expect(hasUnmaximized, true);
    });

    testWidgets('WindowingOwner32 can minimize', (WidgetTester tester) async {
      bool hasMinimized = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onShowWindow: (HWND hwnd, int sw) {
            hasMinimized = true;
            expect(sw, 6); // SW_MINIMIZE
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.setMinimized(true);
      expect(hasMinimized, true);
    });

    testWidgets('WindowingOwner32 can unmaximize', (WidgetTester tester) async {
      bool hasUnminimized = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onShowWindow: (HWND hwnd, int sw) {
            hasUnminimized = true;
            expect(sw, 9); // SW_RESTORE
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.setMinimized(false);
      expect(hasUnminimized, true);
    });

    testWidgets('WindowingOwner32 can set fullscreen', (WidgetTester tester) async {
      bool hasFullscreen = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onSetFullscreen: (HWND hwnd, WindowFullscreenRequest request) {
            hasFullscreen = true;
            expect(request.fullscreen, true);
            expect(request.hasDisplayId, false);
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.setFullscreen(true);
      expect(hasFullscreen, true);
    });

    testWidgets('WindowingOwner32 can get isMinimized', (WidgetTester tester) async {
      bool hasCalledIsMinimized = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onIsIconic: (HWND hwnd) {
            hasCalledIsMinimized = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.isMinimized;
      expect(hasCalledIsMinimized, true);
    });

    testWidgets('WindowingOwner32 can get isMaximized', (WidgetTester tester) async {
      bool hasCalledIsMaximized = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onIsZoomed: (HWND hwnd) {
            hasCalledIsMaximized = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.isMaximized;
      expect(hasCalledIsMaximized, true);
    });

    testWidgets('WindowingOwner32 can get isFullscreen', (WidgetTester tester) async {
      bool hasCalledIsFullscreen = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onGetFullscreen: (HWND hwnd) {
            hasCalledIsFullscreen = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.isFullscreen;
      expect(hasCalledIsFullscreen, true);
    });

    testWidgets('WindowingOwner32 can get title', (WidgetTester tester) async {
      bool hasCalledTextLengthGetter = false;
      bool hasCalledTextGetter = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onGetWindowTextLength: (HWND hwnd) {
            hasCalledTextLengthGetter = true;
          },
          onGetWindowText: (HWND hwnd, Pointer<ffi.Utf16> title, int length) {
            hasCalledTextGetter = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.title;
      expect(hasCalledTextLengthGetter, true);
      expect(hasCalledTextGetter, true);
    });

    testWidgets('WindowingOwner32 can get isActivated', (WidgetTester tester) async {
      bool hasCalledIsActivated = false;
      final WindowingOwnerWin32 owner = WindowingOwnerWin32.test(
        win32PlatformInterface: _MockWin32PlatformInterface(
          onGetForegroundWindow: () {
            hasCalledIsActivated = true;
          },
        ),
        platformDispatcher: tester.platformDispatcher,
      );

      final RegularWindowController controller = owner.createRegularWindowController(
        delegate: RegularWindowControllerDelegate(),
      );

      controller.isActivated;
      expect(hasCalledIsActivated, true);
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

  final int viewId = 0;
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
    return 10;
  }

  @override
  int getWindowText(HWND windowHandle, Pointer<ffi.Utf16> lpString, int maxLength) {
    onGetWindowText?.call(windowHandle, lpString, maxLength);
    return 10;
  }

  @override
  HWND getForegroundWindow() {
    onGetForegroundWindow?.call();
    return hwnd;
  }
}
