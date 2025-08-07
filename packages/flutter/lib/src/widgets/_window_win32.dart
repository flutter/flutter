// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:ui' show Display, FlutterView;
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '_window.dart';
import 'binding.dart';

/// A Windows window handle.
typedef HWND = Pointer<Void>;

const int _WM_SIZE = 0x0005;
const int _WM_CLOSE = 0x0010;

const int _SW_RESTORE = 9;
const int _SW_MAXIMIZE = 3;
const int _SW_MINIMIZE = 6;

/// Abstract handler class for Windows messages.
///
/// Implementations of this class should register with
/// [WindowingOwnerWin32.addMessageHandler] to begin receiving messages.
/// When finished handling messages, implementations should deregister
/// themselves with [WindowingOwnerWIn32.removeMessageHandler].
///
/// See also:
///
///  * [WindowingOwnerWin32], the class that manages these handlers.
abstract class WindowsMessageHandler {
  /// Handles a window message. Returned value, if not null will be
  /// returned to the system as LRESULT and will stop all other
  /// handlers from being called.
  int? handleWindowsMessage(
    FlutterView view,
    HWND windowHandle,
    int message,
    int wParam,
    int lParam,
  );
}

/// [WindowingOwner] implementation for Windows.
///
///  If [Platform.isWindows] is false, then the constructor will throw an
/// [UnsupportedError].
///
/// See also:
///
///  * [WindowingOwner], the abstract class that manages native windows.
class WindowingOwnerWin32 extends WindowingOwner {
  /// Creates a new [WindowingOwnerWin32] instance.
  ///
  /// If [Platform.isWindows] is false, then this constructor will throw an
  /// [UnsupportedError].
  WindowingOwnerWin32() {
    if (!Platform.isWindows) {
      UnsupportedError('Only available on the Win32 platform');
    }

    final Pointer<_WindowingInitRequest> request = ffi.calloc<_WindowingInitRequest>()
      ..ref.onMessage = NativeCallable<Void Function(Pointer<_WindowsMessage>)>.isolateLocal(
        _onMessage,
      ).nativeFunction;
    _initializeWindowing(PlatformDispatcher.instance.engineId!, request);
    ffi.calloc.free(request);
  }

  final List<WindowsMessageHandler> _messageHandlers = <WindowsMessageHandler>[];

  @override
  RegularWindowController createRegularWindowController({
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    required RegularWindowControllerDelegate delegate,
  }) {
    return RegularWindowControllerWin32(
      owner: this,
      delegate: delegate,
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      title: title,
    );
  }

  /// Register a new [WindowsMessageHandler].
  ///
  /// The handler will be triggered for unhandled messages for all top level
  /// windows.
  ///
  /// Adding a handler multiple times has no effect.
  ///
  /// Handlers are called in the order that they are added.
  ///
  /// Callers must remove their message handlers using
  /// [WindowingOwnerWin32.removeMessageHandler].
  ///
  /// See also:
  ///
  ///  * [WindowsMessageHandler], the interface for message handlers.
  ///  * [WindowingOwnerWin32.removeMessageHandler], to remove message handlers.
  void addMessageHandler(WindowsMessageHandler handler) {
    if (_messageHandlers.contains(handler)) {
      return;
    }

    _messageHandlers.add(handler);
  }

  /// Unregister a [WindowsMessageHandler].
  ///
  /// If the handler has not been registered, this method has no effect.
  ///
  /// See also:
  ///
  ///  * [WindowsMessageHandler], the interface for message handlers.
  ///  * [WindowingOwnerWin32.addMessageHandler], to register message handlers.
  void removeMessageHandler(WindowsMessageHandler handler) {
    _messageHandlers.remove(handler);
  }

  void _onMessage(Pointer<_WindowsMessage> message) {
    final List<WindowsMessageHandler> handlers = List<WindowsMessageHandler>.from(_messageHandlers);
    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == message.ref.viewId,
    );
    for (final WindowsMessageHandler handler in handlers) {
      final int? result = handler.handleWindowsMessage(
        flutterView,
        message.ref.windowHandle,
        message.ref.message,
        message.ref.wParam,
        message.ref.lParam,
      );
      if (result != null) {
        message.ref.handled = true;
        message.ref.lResult = result;
        return;
      }
    }
  }

  @override
  bool hasTopLevelWindows() {
    return _hasTopLevelWindows(PlatformDispatcher.instance.engineId!);
  }

  @Native<Bool Function(Int64)>(symbol: 'InternalFlutterWindows_WindowManager_HasTopLevelWindows')
  external static bool _hasTopLevelWindows(int engineId);

  @Native<Void Function(Int64, Pointer<_WindowingInitRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_Initialize',
  )
  external static void _initializeWindowing(int engineId, Pointer<_WindowingInitRequest> request);
}

/// Implementation of [RegularWindowController] for the Windows platform.
///
/// If [Platform.isWindows] is false, then the constructor will throw an
/// [UnsupportedError].
class RegularWindowControllerWin32 extends RegularWindowController
    implements WindowsMessageHandler {
  /// Creates a new regular window controller for Win32.
  ///
  /// If [Platform.isWindows] is false, then this constructor will throw an
  /// [UnsupportedError].
  ///
  /// When this constructor completes the native window has been created and
  /// has a view associated with it.
  RegularWindowControllerWin32({
    required WindowingOwnerWin32 owner,
    required RegularWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  }) : _owner = owner,
       _delegate = delegate,
       super.empty() {
    owner.addMessageHandler(this);
    final Pointer<_WindowCreationRequest> request = ffi.calloc<_WindowCreationRequest>()
      ..ref.preferredSize.from(preferredSize)
      ..ref.preferredConstraints.from(preferredConstraints)
      ..ref.title = (title ?? 'Regular window').toNativeUtf16();
    final int viewId = _createWindow(PlatformDispatcher.instance.engineId!, request);
    ffi.calloc.free(request);
    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    rootView = flutterView;
  }

  final WindowingOwnerWin32 _owner;
  final RegularWindowControllerDelegate _delegate;
  bool _destroyed = false;

  @override
  Size get contentSize {
    _ensureNotDestroyed();
    final _ActualWindowSize size = _getWindowContentSize(getWindowHandle());
    final Size result = Size(size.width, size.height);
    return result;
  }

  @override
  String get title {
    _ensureNotDestroyed();
    final int length = _getWindowTextLength(getWindowHandle());
    if (length == 0) {
      return '';
    }

    final Pointer<Uint16> data = ffi.calloc<Uint16>(length + 1);
    try {
      final Pointer<ffi.Utf16> buffer = data.cast<ffi.Utf16>();
      _getWindowText(getWindowHandle(), buffer, length + 1);
      return buffer.toDartString();
    } finally {
      ffi.calloc.free(data);
    }
  }

  @override
  bool get isActivated {
    _ensureNotDestroyed();
    return _getForegroundWindow() == getWindowHandle();
  }

  @override
  bool get isMaximized {
    _ensureNotDestroyed();
    return _isZoomed(getWindowHandle()) != 0;
  }

  @override
  bool get isMinimized {
    _ensureNotDestroyed();
    return _isIconic(getWindowHandle()) != 0;
  }

  @override
  bool get isFullscreen {
    _ensureNotDestroyed();
    return _getFullscreen(getWindowHandle());
  }

  @override
  void setSize(Size? size) {
    _ensureNotDestroyed();
    final Pointer<_WindowSizeRequest> request = ffi.calloc<_WindowSizeRequest>();
    request.ref.hasSize = size != null;
    request.ref.width = size?.width ?? 0;
    request.ref.height = size?.height ?? 0;
    _setWindowContentSize(getWindowHandle(), request);
    ffi.calloc.free(request);
  }

  @override
  void setConstraints(BoxConstraints constraints) {
    _ensureNotDestroyed();
    final Pointer<_WindowConstraints> request = ffi.calloc<_WindowConstraints>();
    request.ref.from(constraints);
    _setWindowConstraints(getWindowHandle(), request);
    ffi.calloc.free(request);
  }

  @override
  void setTitle(String title) {
    _ensureNotDestroyed();
    final Pointer<ffi.Utf16> titlePointer = title.toNativeUtf16();
    _setWindowTitle(getWindowHandle(), titlePointer);
    ffi.calloc.free(titlePointer);
  }

  @override
  void activate() {
    _ensureNotDestroyed();
    _showWindow(getWindowHandle(), _SW_RESTORE);
  }

  @override
  void setMaximized(bool maximized) {
    _ensureNotDestroyed();
    if (maximized) {
      _showWindow(getWindowHandle(), _SW_MAXIMIZE);
    } else {
      _showWindow(getWindowHandle(), _SW_RESTORE);
    }
  }

  @override
  void setMinimized(bool minimized) {
    _ensureNotDestroyed();
    if (minimized) {
      _showWindow(getWindowHandle(), _SW_MINIMIZE);
    } else {
      _showWindow(getWindowHandle(), _SW_RESTORE);
    }
  }

  @override
  void setFullscreen(bool fullscreen, {Display? display}) {
    final Pointer<_FullscreenRequest> request = ffi.calloc<_FullscreenRequest>();
    request.ref.hasDisplayId = false;
    request.ref.displayId = display?.id ?? 0;
    request.ref.fullscreen = fullscreen;
    _setFullscreen(getWindowHandle(), request);
    ffi.calloc.free(request);
  }

  /// Returns HWND pointer to the top level window.
  HWND getWindowHandle() {
    _ensureNotDestroyed();
    return _getWindowHandle(PlatformDispatcher.instance.engineId!, rootView.viewId);
  }

  void _ensureNotDestroyed() {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
  }

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyWindow(getWindowHandle());
    _destroyed = true;
    _delegate.onWindowDestroyed();
    _owner.removeMessageHandler(this);
  }

  @override
  int? handleWindowsMessage(
    FlutterView view,
    HWND windowHandle,
    int message,
    int wParam,
    int lParam,
  ) {
    if (view.viewId != rootView.viewId) {
      return null;
    }

    if (message == _WM_CLOSE) {
      _delegate.onWindowCloseRequested(this);
      return 0;
    } else if (message == _WM_SIZE) {
      // TODO: notify context of size change
    }
    return null;
  }

  @Native<Int64 Function(Int64, Pointer<_WindowCreationRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_CreateRegularWindow',
  )
  external static int _createWindow(int engineId, Pointer<_WindowCreationRequest> request);

  @Native<Pointer<Void> Function(Int64, Int64)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle',
  )
  external static Pointer<Void> _getWindowHandle(int engineId, int viewId);

  @Native<Void Function(Pointer<Void>)>(symbol: 'DestroyWindow')
  external static void _destroyWindow(Pointer<Void> windowHandle);

  @Native<_ActualWindowSize Function(Pointer<Void>)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetWindowContentSize',
  )
  external static _ActualWindowSize _getWindowContentSize(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>, Pointer<ffi.Utf16>, Int32)>(symbol: 'GetWindowTextW')
  external static void _getWindowTitle(
    Pointer<Void> windowHandle,
    Pointer<ffi.Utf16> title,
    int maxLength,
  );

  @Native<Void Function(Pointer<Void>, Pointer<ffi.Utf16>)>(symbol: 'SetWindowTextW')
  external static void _setWindowTitle(Pointer<Void> windowHandle, Pointer<ffi.Utf16> title);

  @Native<Void Function(Pointer<Void>, Pointer<_WindowSizeRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetWindowSize',
  )
  external static void _setWindowContentSize(
    Pointer<Void> windowHandle,
    Pointer<_WindowSizeRequest> size,
  );

  @Native<Void Function(Pointer<Void>, Pointer<_WindowConstraints>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetWindowConstraints',
  )
  external static void _setWindowConstraints(
    Pointer<Void> windowHandle,
    Pointer<_WindowConstraints> constraints,
  );

  @Native<Void Function(Pointer<Void>, Int32)>(symbol: 'ShowWindow')
  external static void _showWindow(Pointer<Void> windowHandle, int command);

  @Native<Int32 Function(Pointer<Void>)>(symbol: 'IsIconic')
  external static int _isIconic(Pointer<Void> windowHandle);

  @Native<Int32 Function(Pointer<Void>)>(symbol: 'IsZoomed')
  external static int _isZoomed(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>, Pointer<_FullscreenRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetFullscreen',
  )
  external static void _setFullscreen(
    Pointer<Void> windowHandle,
    Pointer<_FullscreenRequest> request,
  );

  @Native<Bool Function(Pointer<Void>)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetFullscreen',
  )
  external static bool _getFullscreen(Pointer<Void> windowHandle);

  @Native<Int32 Function(Pointer<Void>)>(symbol: 'GetWindowTextLengthW')
  external static int _getWindowTextLength(Pointer<Void> windowHandle);

  @Native<Int32 Function(Pointer<Void>, Pointer<ffi.Utf16>, Int32)>(symbol: 'GetWindowTextW')
  external static int _getWindowText(
    Pointer<Void> windowHandle,
    Pointer<ffi.Utf16> lpString,
    int maxLength,
  );

  @Native<Pointer<Void> Function()>(symbol: 'GetForegroundWindow')
  external static Pointer<Void> _getForegroundWindow();
}

/// Request to initialize windowing system.
final class _WindowingInitRequest extends Struct {
  external Pointer<NativeFunction<Void Function(Pointer<_WindowsMessage>)>> onMessage;
}

final class _WindowSizeRequest extends Struct {
  @Bool()
  external bool hasSize;

  @Double()
  external double width;

  @Double()
  external double height;

  void from(Size? size) {
    hasSize = size != null;
    width = size?.width ?? 0;
    height = size?.height ?? 0;
  }
}

final class _WindowConstraints extends Struct {
  @Bool()
  external bool hasConstraints;

  @Double()
  external double minWidth;

  @Double()
  external double minHeight;

  @Double()
  external double maxWidth;

  @Double()
  external double maxHeight;

  void from(BoxConstraints? constraints) {
    hasConstraints = constraints != null;
    minWidth = constraints?.minWidth ?? 0;
    minHeight = constraints?.minHeight ?? 0;
    maxWidth = constraints?.maxWidth ?? double.maxFinite;
    maxHeight = constraints?.maxHeight ?? double.maxFinite;
  }
}

final class _WindowCreationRequest extends Struct {
  external _WindowSizeRequest preferredSize;
  external _WindowConstraints preferredConstraints;
  external Pointer<ffi.Utf16> title;
}

/// Windows message received for all top level windows (regardless whether
/// they are created using a windowing controller).
final class _WindowsMessage extends Struct {
  @Int64()
  external int viewId;

  external Pointer<Void> windowHandle;

  @Int32()
  external int message;

  @Int64()
  external int wParam;

  @Int64()
  external int lParam;

  @Int64()
  external int lResult;

  @Bool()
  external bool handled;
}

final class _ActualWindowSize extends Struct {
  @Double()
  external double width;

  @Double()
  external double height;
}

final class _FullscreenRequest extends Struct {
  @Bool()
  external bool fullscreen;

  @Bool()
  external bool hasDisplayId;

  @Uint64()
  external int displayId;
}
