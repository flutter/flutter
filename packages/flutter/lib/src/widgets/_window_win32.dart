// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Do not import this file in production applications or packages published
// to pub.dev. Flutter will make breaking changes to this file, even in patch
// versions.
//
// All APIs in this file must be private or must:
//
// 1. Have the `@internal` attribute.
// 2. Throw an `UnsupportedError` if `isWindowingEnabled`
//    is `false.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:ui' show Display, FlutterView;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '_window.dart';
import 'binding.dart';

/// A Win32 window handle.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
typedef HWND = ffi.Pointer<ffi.Void>;

const int _WM_SIZE = 0x0005;
const int _WM_ACTIVATE = 0x0006;
const int _WM_CLOSE = 0x0010;

const int _SW_RESTORE = 9;
const int _SW_MAXIMIZE = 3;
const int _SW_MINIMIZE = 6;

/// Abstract handler class for Windows messages.
///
/// Implementations of this class should register with
/// [WindowingOwnerWin32.addMessageHandler] to begin receiving messages.
/// When finished handling messages, implementations should deregister
/// themselves with [WindowingOwnerWin32.removeMessageHandler].
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowingOwnerWin32], the class that manages these handlers.
@internal
abstract class WindowsMessageHandler {
  /// Handles a window message.
  ///
  /// Returned value, if not null will be returned to the system as LRESULT
  /// and will stop all other handlers from being called.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
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
/// If [Platform.isWindows] is false, then the constructor will throw an
/// [UnsupportedError].
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowingOwner], the abstract class that manages native windows.
@internal
class WindowingOwnerWin32 extends WindowingOwner {
  /// Creates a new [WindowingOwnerWin32] instance.
  ///
  /// If [Platform.isWindows] is false, then this constructor will throw an
  /// [UnsupportedError]
  ///
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [WindowingOwner], the abstract class that manages native windows.
  @internal
  WindowingOwnerWin32()
    : win32PlatformInterface = _NativeWin32PlatformInterface(),
      platformDispatcher = PlatformDispatcher.instance,
      allocator = _CallocAllocator._() {
    if (!Platform.isWindows) {
      throw UnsupportedError('Only available on the Win32 platform');
    }

    final ffi.Pointer<WindowingInitRequest> request = allocator<WindowingInitRequest>()
      ..ref.onMessage =
          ffi.NativeCallable<ffi.Void Function(ffi.Pointer<WindowsMessage>)>.isolateLocal(
            _onMessage,
          ).nativeFunction;
    win32PlatformInterface.initialize(platformDispatcher.engineId!, request);
    allocator.free(request);
  }

  /// Creates a new [WindowingOwnerWin32] instance for testing purposes.
  ///
  /// This constructor will not throw when we are not on the win32 platform.
  ///
  /// This constructor takes a [win32PlatformInterface], which is most likely
  /// a mock interface in addition to a custom [platformDispatcher] so that
  /// [PlatformDispatcher.engineId] can successfully be mocked.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @visibleForTesting
  WindowingOwnerWin32.test({
    required this.win32PlatformInterface,
    required this.platformDispatcher,
    required this.allocator,
  }) {
    final ffi.Pointer<WindowingInitRequest> request = allocator<WindowingInitRequest>()
      ..ref.onMessage =
          ffi.NativeCallable<ffi.Void Function(ffi.Pointer<WindowsMessage>)>.isolateLocal(
            _onMessage,
          ).nativeFunction;
    win32PlatformInterface.initialize(platformDispatcher.engineId!, request);
    allocator.free(request);
  }

  final List<WindowsMessageHandler> _messageHandlers = <WindowsMessageHandler>[];

  /// Provides access to the native win32 backend.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final Win32PlatformInterface win32PlatformInterface;

  /// The [PlatformDispatcher].
  ///
  /// This will differ from [PlatformDispatcher.instance] during testing.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final PlatformDispatcher platformDispatcher;

  /// The [Allocator] used for allocating native memory in this owner.
  ///
  /// This can be overridden via the [WindowingOwnerWin32.test] constructor.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  final ffi.Allocator allocator;

  @internal
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
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [WindowsMessageHandler], the interface for message handlers.
  ///  * [WindowingOwnerWin32.removeMessageHandler], to remove message handlers.
  @internal
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
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [WindowsMessageHandler], the interface for message handlers.
  ///  * [WindowingOwnerWin32.addMessageHandler], to register message handlers.
  @internal
  void removeMessageHandler(WindowsMessageHandler handler) {
    _messageHandlers.remove(handler);
  }

  void _onMessage(ffi.Pointer<WindowsMessage> message) {
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

  @internal
  @override
  bool hasTopLevelWindows() {
    return win32PlatformInterface.hasTopLevelWindows(platformDispatcher.engineId!);
  }
}

/// Implementation of [RegularWindowController] for the Windows platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [RegularWindowController], the base class for regular windows.
class RegularWindowControllerWin32 extends RegularWindowController
    implements WindowsMessageHandler {
  /// Creates a new regular window controller for Win32.
  ///
  /// When this constructor completes the native window has been created and
  /// has a view associated with it.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [RegularWindowController], the base class for regular windows.
  @internal
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
    final ffi.Pointer<WindowCreationRequest> request = owner.allocator<WindowCreationRequest>()
      ..ref.preferredSize.from(preferredSize)
      ..ref.preferredConstraints.from(preferredConstraints)
      ..ref.title = (title ?? 'Regular window').toNativeUtf16(allocator: _owner.allocator);
    final int viewId = _owner.win32PlatformInterface.createWindow(
      _owner.platformDispatcher.engineId!,
      request,
    );
    owner.allocator.free(request);
    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    rootView = flutterView;
  }

  final WindowingOwnerWin32 _owner;
  final RegularWindowControllerDelegate _delegate;
  bool _destroyed = false;

  @override
  @internal
  Size get contentSize {
    _ensureNotDestroyed();
    final ActualContentSize size = _owner.win32PlatformInterface.getWindowContentSize(
      getWindowHandle(),
    );
    final Size result = Size(size.width, size.height);
    return result;
  }

  @override
  @internal
  String get title {
    _ensureNotDestroyed();
    final int length = _owner.win32PlatformInterface.getWindowTextLength(getWindowHandle());
    if (length == 0) {
      return '';
    }

    final ffi.Pointer<ffi.Uint16> data = _owner.allocator<ffi.Uint16>(length + 1);
    try {
      final ffi.Pointer<_Utf16> buffer = data.cast<_Utf16>();
      _owner.win32PlatformInterface.getWindowText(getWindowHandle(), buffer, length + 1);
      return buffer.toDartString();
    } finally {
      _owner.allocator.free(data);
    }
  }

  @override
  @internal
  bool get isActivated {
    _ensureNotDestroyed();
    return _owner.win32PlatformInterface.getForegroundWindow() == getWindowHandle();
  }

  @override
  @internal
  bool get isMaximized {
    _ensureNotDestroyed();
    return _owner.win32PlatformInterface.isZoomed(getWindowHandle()) != 0;
  }

  @override
  @internal
  bool get isMinimized {
    _ensureNotDestroyed();
    return _owner.win32PlatformInterface.isIconic(getWindowHandle()) != 0;
  }

  @override
  @internal
  bool get isFullscreen {
    _ensureNotDestroyed();
    return _owner.win32PlatformInterface.getFullscreen(getWindowHandle());
  }

  @override
  @internal
  void setSize(Size? size) {
    _ensureNotDestroyed();
    final ffi.Pointer<WindowSizeRequest> request = _owner.allocator<WindowSizeRequest>();
    request.ref.hasSize = size != null;
    request.ref.width = size?.width ?? 0;
    request.ref.height = size?.height ?? 0;
    _owner.win32PlatformInterface.setWindowContentSize(getWindowHandle(), request);
    _owner.allocator.free(request);
  }

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    _ensureNotDestroyed();
    final ffi.Pointer<WindowConstraintsRequest> request = _owner
        .allocator<WindowConstraintsRequest>();
    request.ref.from(constraints);
    _owner.win32PlatformInterface.setWindowConstraints(getWindowHandle(), request);
    _owner.allocator.free(request);

    notifyListeners();
  }

  @override
  @internal
  void setTitle(String title) {
    _ensureNotDestroyed();
    final ffi.Pointer<_Utf16> titlePointer = title.toNativeUtf16(allocator: _owner.allocator);
    _owner.win32PlatformInterface.setWindowTitle(getWindowHandle(), titlePointer);
    _owner.allocator.free(titlePointer);

    notifyListeners();
  }

  @override
  @internal
  void activate() {
    _ensureNotDestroyed();
    _owner.win32PlatformInterface.showWindow(getWindowHandle(), _SW_RESTORE);
  }

  @override
  @internal
  void setMaximized(bool maximized) {
    _ensureNotDestroyed();
    if (maximized) {
      _owner.win32PlatformInterface.showWindow(getWindowHandle(), _SW_MAXIMIZE);
    } else {
      _owner.win32PlatformInterface.showWindow(getWindowHandle(), _SW_RESTORE);
    }
  }

  @override
  @internal
  void setMinimized(bool minimized) {
    _ensureNotDestroyed();
    if (minimized) {
      _owner.win32PlatformInterface.showWindow(getWindowHandle(), _SW_MINIMIZE);
    } else {
      _owner.win32PlatformInterface.showWindow(getWindowHandle(), _SW_RESTORE);
    }
  }

  @override
  @internal
  void setFullscreen(bool fullscreen, {Display? display}) {
    final ffi.Pointer<WindowFullscreenRequest> request = _owner
        .allocator<WindowFullscreenRequest>();
    request.ref.hasDisplayId = false;
    request.ref.displayId = display?.id ?? 0;
    request.ref.fullscreen = fullscreen;
    _owner.win32PlatformInterface.setFullscreen(getWindowHandle(), request);
    _owner.allocator.free(request);
  }

  /// Returns HWND pointer to the top level window.
  @internal
  HWND getWindowHandle() {
    _ensureNotDestroyed();
    return _owner.win32PlatformInterface.getWindowHandle(
      _owner.platformDispatcher.engineId!,
      rootView.viewId,
    );
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
    _owner.win32PlatformInterface.destroyWindow(getWindowHandle());
    _destroyed = true;
    _delegate.onWindowDestroyed();
    _owner.removeMessageHandler(this);
  }

  @override
  @internal
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
    } else if (message == _WM_SIZE || message == _WM_ACTIVATE) {
      notifyListeners();
    }
    return null;
  }
}

/// Abstract class that wraps native access to the win32 API.
///
/// Used by [WindowingOwnerWin32].
///
/// Overriding this is only useful for testing purposes.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowingOwnerWin32], the user of this interface.
@visibleForTesting
@internal
abstract class Win32PlatformInterface {
  /// Checks if the engine specified by [engineId] has any top level
  /// windows created on it.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  bool hasTopLevelWindows(int engineId);

  /// Initialize the window subsystem for the provided engine.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void initialize(int engineId, ffi.Pointer<WindowingInitRequest> request);

  /// Create a regular window on the provided engine.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  int createWindow(int engineId, ffi.Pointer<WindowCreationRequest> request);

  /// Retrieve the window handle associated with the provided engine and view ids.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  HWND getWindowHandle(int engineId, int viewId);

  /// Destroy a window given its window handle.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void destroyWindow(HWND windowHandle);

  /// Retrieve the current content size of a window given its handle.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  ActualContentSize getWindowContentSize(HWND windowHandle);

  /// Set the title of a window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void setWindowTitle(HWND windowHandle, ffi.Pointer<_Utf16> title);

  /// Set the content size of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void setWindowContentSize(HWND windowHandle, ffi.Pointer<WindowSizeRequest> size);

  /// Set the constraints of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void setWindowConstraints(HWND windowHandle, ffi.Pointer<WindowConstraintsRequest> constraints);

  /// Show the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void showWindow(HWND windowHandle, int command);

  /// Check if the window is minimized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  int isIconic(HWND windowHandle);

  /// Check if the window is maximized.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  int isZoomed(HWND windowHandle);

  /// Request that the window change its fullscreen status.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void setFullscreen(HWND windowHandle, ffi.Pointer<WindowFullscreenRequest> request);

  /// Retrieve the fullscreen status of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  bool getFullscreen(HWND windowHandle);

  /// Retrieve the text length of the title of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  int getWindowTextLength(HWND windowHandle);

  /// Retrieve the title of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  int getWindowText(HWND windowHandle, ffi.Pointer<_Utf16> lpString, int maxLength);

  /// Retrieve the currently focused window handle.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  HWND getForegroundWindow();
}

class _NativeWin32PlatformInterface extends Win32PlatformInterface {
  @override
  bool hasTopLevelWindows(int engineId) {
    return _hasTopLevelWindows(engineId);
  }

  @override
  void initialize(int engineId, ffi.Pointer<WindowingInitRequest> request) {
    _initializeWindowing(engineId, request);
  }

  @override
  int createWindow(int engineId, ffi.Pointer<WindowCreationRequest> request) {
    return _createWindow(engineId, request);
  }

  @override
  HWND getWindowHandle(int engineId, int viewId) {
    return _getWindowHandle(engineId, viewId);
  }

  @override
  void destroyWindow(HWND windowHandle) {
    _destroyWindow(windowHandle);
  }

  @override
  ActualContentSize getWindowContentSize(HWND windowHandle) {
    return _getWindowContentSize(windowHandle);
  }

  @override
  void setWindowTitle(HWND windowHandle, ffi.Pointer<_Utf16> title) {
    _setWindowTitle(windowHandle, title);
  }

  @override
  void setWindowContentSize(HWND windowHandle, ffi.Pointer<WindowSizeRequest> size) {
    _setWindowContentSize(windowHandle, size);
  }

  @override
  void setWindowConstraints(HWND windowHandle, ffi.Pointer<WindowConstraintsRequest> constraints) {
    _setWindowConstraints(windowHandle, constraints);
  }

  @override
  void showWindow(HWND windowHandle, int command) {
    _showWindow(windowHandle, command);
  }

  @override
  int isIconic(HWND windowHandle) {
    return _isIconic(windowHandle);
  }

  @override
  int isZoomed(HWND windowHandle) {
    return _isZoomed(windowHandle);
  }

  @override
  void setFullscreen(HWND windowHandle, ffi.Pointer<WindowFullscreenRequest> request) {
    _setFullscreen(windowHandle, request);
  }

  @override
  bool getFullscreen(HWND windowHandle) {
    return _getFullscreen(windowHandle);
  }

  @override
  int getWindowTextLength(HWND windowHandle) {
    return _getWindowTextLength(windowHandle);
  }

  @override
  int getWindowText(HWND windowHandle, ffi.Pointer<_Utf16> lpString, int maxLength) {
    return _getWindowText(windowHandle, lpString, maxLength);
  }

  @override
  HWND getForegroundWindow() {
    return _getForegroundWindow();
  }

  @ffi.Native<ffi.Bool Function(ffi.Int64)>(
    symbol: 'InternalFlutterWindows_WindowManager_HasTopLevelWindows',
  )
  external static bool _hasTopLevelWindows(int engineId);

  @ffi.Native<ffi.Void Function(ffi.Int64, ffi.Pointer<WindowingInitRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_Initialize',
  )
  external static void _initializeWindowing(
    int engineId,
    ffi.Pointer<WindowingInitRequest> request,
  );

  @ffi.Native<ffi.Int64 Function(ffi.Int64, ffi.Pointer<WindowCreationRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_CreateRegularWindow',
  )
  external static int _createWindow(int engineId, ffi.Pointer<WindowCreationRequest> request);

  @ffi.Native<HWND Function(ffi.Int64, ffi.Int64)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle',
  )
  external static HWND _getWindowHandle(int engineId, int viewId);

  @ffi.Native<ffi.Void Function(HWND)>(symbol: 'DestroyWindow')
  external static void _destroyWindow(HWND windowHandle);

  @ffi.Native<ActualContentSize Function(HWND)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetWindowContentSize',
  )
  external static ActualContentSize _getWindowContentSize(HWND windowHandle);

  @ffi.Native<ffi.Void Function(HWND, ffi.Pointer<_Utf16>)>(symbol: 'SetWindowTextW')
  external static void _setWindowTitle(HWND windowHandle, ffi.Pointer<_Utf16> title);

  @ffi.Native<ffi.Void Function(HWND, ffi.Pointer<WindowSizeRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetWindowSize',
  )
  external static void _setWindowContentSize(
    HWND windowHandle,
    ffi.Pointer<WindowSizeRequest> size,
  );

  @ffi.Native<ffi.Void Function(HWND, ffi.Pointer<WindowConstraintsRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetWindowConstraints',
  )
  external static void _setWindowConstraints(
    HWND windowHandle,
    ffi.Pointer<WindowConstraintsRequest> constraints,
  );

  @ffi.Native<ffi.Void Function(HWND, ffi.Int32)>(symbol: 'ShowWindow')
  external static void _showWindow(HWND windowHandle, int command);

  @ffi.Native<ffi.Int32 Function(HWND)>(symbol: 'IsIconic')
  external static int _isIconic(HWND windowHandle);

  @ffi.Native<ffi.Int32 Function(HWND)>(symbol: 'IsZoomed')
  external static int _isZoomed(HWND windowHandle);

  @ffi.Native<ffi.Void Function(HWND, ffi.Pointer<WindowFullscreenRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetFullscreen',
  )
  external static void _setFullscreen(
    HWND windowHandle,
    ffi.Pointer<WindowFullscreenRequest> request,
  );

  @ffi.Native<ffi.Bool Function(HWND)>(symbol: 'InternalFlutterWindows_WindowManager_GetFullscreen')
  external static bool _getFullscreen(HWND windowHandle);

  @ffi.Native<ffi.Int32 Function(HWND)>(symbol: 'GetWindowTextLengthW')
  external static int _getWindowTextLength(HWND windowHandle);

  @ffi.Native<ffi.Int32 Function(HWND, ffi.Pointer<_Utf16>, ffi.Int32)>(symbol: 'GetWindowTextW')
  external static int _getWindowText(
    HWND windowHandle,
    ffi.Pointer<_Utf16> lpString,
    int maxLength,
  );

  @ffi.Native<HWND Function()>(symbol: 'GetForegroundWindow')
  external static HWND _getForegroundWindow();
}

/// Payload for the creation method used by [Win32PlatformInterface.createWindow].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowCreationRequest extends ffi.Struct {
  external WindowSizeRequest preferredSize;
  external WindowConstraintsRequest preferredConstraints;
  external ffi.Pointer<_Utf16> title;
}

/// Payload for the initialization request for the windowing subsystem used
/// by the constructor for [WindowingOwnerWin32].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowingInitRequest extends ffi.Struct {
  external ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<WindowsMessage>)>>
  onMessage;
}

/// Payload for the size of a window used by [WindowCreationRequest] and
/// [Win32PlatformInterface.setWindowContentSize].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowSizeRequest extends ffi.Struct {
  @ffi.Bool()
  external bool hasSize;

  @ffi.Double()
  external double width;

  @ffi.Double()
  external double height;

  void from(Size? size) {
    hasSize = size != null;
    width = size?.width ?? 0;
    height = size?.height ?? 0;
  }
}

/// Payload for the constraints of a window used by [WindowCreationRequest] and
/// [Win32PlatformInterface.setWindowConstraints].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowConstraintsRequest extends ffi.Struct {
  @ffi.Bool()
  external bool hasConstraints;

  @ffi.Double()
  external double minWidth;

  @ffi.Double()
  external double minHeight;

  @ffi.Double()
  external double maxWidth;

  @ffi.Double()
  external double maxHeight;

  void from(BoxConstraints? constraints) {
    hasConstraints = constraints != null;
    minWidth = constraints?.minWidth ?? 0;
    minHeight = constraints?.minHeight ?? 0;
    maxWidth = constraints?.maxWidth ?? double.maxFinite;
    maxHeight = constraints?.maxHeight ?? double.maxFinite;
  }
}

/// A message received for all toplevel windows, used by [WindowingInitRequest].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowsMessage extends ffi.Struct {
  @ffi.Int64()
  external int viewId;

  external HWND windowHandle;

  @ffi.Int32()
  external int message;

  @ffi.Int64()
  external int wParam;

  @ffi.Int64()
  external int lParam;

  @ffi.Int64()
  external int lResult;

  @ffi.Bool()
  external bool handled;
}

/// Holds the real size of a window as retrieved from
/// [Win32PlatformInterface.getWindowContentSize].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class ActualContentSize extends ffi.Struct {
  @ffi.Double()
  external double width;

  @ffi.Double()
  external double height;
}

/// Payload for the [Win32PlatformInterface.setFullscreen] request.
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowFullscreenRequest extends ffi.Struct {
  @ffi.Bool()
  external bool fullscreen;

  @ffi.Bool()
  external bool hasDisplayId;

  @ffi.Uint64()
  external int displayId;
}

/// The contents of a native zero-terminated array of UTF-16 code units.
///
/// The Utf16 type itself has no functionality, it's only intended to be used
/// through a `Pointer<Utf16>` representing the entire array. This pointer is
/// the equivalent of a char pointer (`const wchar_t*`) in C code. The
/// individual UTF-16 code units are stored in native byte order.
final class _Utf16 extends ffi.Opaque {}

/// Extension method for converting a`Pointer<Utf16>` to a [String].
extension _Utf16Pointer on ffi.Pointer<_Utf16> {
  /// The number of UTF-16 code units in this zero-terminated UTF-16 string.
  ///
  /// The UTF-16 code units of the strings are the non-zero code units up to
  /// the first zero code unit.
  int get length {
    _ensureNotNullptr('length');
    final ffi.Pointer<ffi.Uint16> codeUnits = cast<ffi.Uint16>();
    return _length(codeUnits);
  }

  /// Converts this UTF-16 encoded string to a Dart string.
  ///
  /// Decodes the UTF-16 code units of this zero-terminated code unit array as
  /// Unicode code points and creates a Dart string containing those code
  /// points.
  ///
  /// If [length] is provided, zero-termination is ignored and the result can
  /// contain NUL characters.
  ///
  /// If [length] is not provided, the returned string is the string up til
  /// but not including  the first NUL character.
  String toDartString({int? length}) {
    _ensureNotNullptr('toDartString');
    final ffi.Pointer<ffi.Uint16> codeUnits = cast<ffi.Uint16>();
    if (length == null) {
      return _toUnknownLengthString(codeUnits);
    } else {
      RangeError.checkNotNegative(length, 'length');
      return _toKnownLengthString(codeUnits, length);
    }
  }

  static String _toKnownLengthString(ffi.Pointer<ffi.Uint16> codeUnits, int length) =>
      String.fromCharCodes(codeUnits.asTypedList(length));

  static String _toUnknownLengthString(ffi.Pointer<ffi.Uint16> codeUnits) {
    final StringBuffer buffer = StringBuffer();
    int i = 0;
    while (true) {
      final int char = (codeUnits + i).value;
      if (char == 0) {
        return buffer.toString();
      }
      buffer.writeCharCode(char);
      i++;
    }
  }

  static int _length(ffi.Pointer<ffi.Uint16> codeUnits) {
    int length = 0;
    while (codeUnits[length] != 0) {
      length++;
    }
    return length;
  }

  void _ensureNotNullptr(String operation) {
    if (this == ffi.nullptr) {
      throw UnsupportedError("Operation '$operation' not allowed on a 'nullptr'.");
    }
  }
}

/// Extension method for converting a [String] to a `Pointer<Utf16>`.
extension _StringUtf16Pointer on String {
  /// Creates a zero-terminated [Utf16] code-unit array from this String.
  ///
  /// If this [String] contains NUL characters, converting it back to a string
  /// using [Utf16Pointer.toDartString] will truncate the result if a length is
  /// not passed.
  ///
  /// Returns an [allocator]-allocated pointer to the result.
  ffi.Pointer<_Utf16> toNativeUtf16({required ffi.Allocator allocator}) {
    final units = codeUnits;
    final result = allocator<ffi.Uint16>(units.length + 1);
    final nativeString = result.asTypedList(units.length + 1);
    nativeString.setRange(0, units.length, units);
    nativeString[units.length] = 0;
    return result.cast();
  }
}

typedef _WinCoTaskMemAllocNative = ffi.Pointer Function(ffi.Size);
typedef _WinCoTaskMemAlloc = ffi.Pointer Function(int);
typedef _WinCoTaskMemFreeNative = ffi.Void Function(ffi.Pointer);
typedef _WinCoTaskMemFree = void Function(ffi.Pointer);

final class _CallocAllocator implements ffi.Allocator {
  _CallocAllocator._() {
    _ole32lib = ffi.DynamicLibrary.open('ole32.dll');
    _winCoTaskMemAlloc = _ole32lib.lookupFunction<_WinCoTaskMemAllocNative, _WinCoTaskMemAlloc>(
      'CoTaskMemAlloc',
    );
    _winCoTaskMemFreePointer = _ole32lib.lookup('CoTaskMemFree');
    _winCoTaskMemFree = _winCoTaskMemFreePointer.asFunction();
  }

  late final ffi.DynamicLibrary _ole32lib;
  late final _WinCoTaskMemAlloc _winCoTaskMemAlloc;
  late final ffi.Pointer<ffi.NativeFunction<_WinCoTaskMemFreeNative>> _winCoTaskMemFreePointer;
  late final _WinCoTaskMemFree _winCoTaskMemFree;

  /// Fills a block of memory with a specified value.
  void _fillMemory(ffi.Pointer destination, int length, int fill) {
    final ptr = destination.cast<ffi.Uint8>();
    for (int i = 0; i < length; i++) {
      ptr[i] = fill;
    }
  }

  /// Fills a block of memory with zeros.
  ///
  void _zeroMemory(ffi.Pointer destination, int length) => _fillMemory(destination, length, 0);

  /// Allocates [byteCount] bytes of zero-initialized of memory on the native
  /// heap.
  @override
  ffi.Pointer<T> allocate<T extends ffi.NativeType>(int byteCount, {int? alignment}) {
    ffi.Pointer<T> result;
    result = _winCoTaskMemAlloc(byteCount).cast();
    if (result.address == 0) {
      throw ArgumentError('Could not allocate $byteCount bytes.');
    }
    if (Platform.isWindows) {
      _zeroMemory(result, byteCount);
    }
    return result;
  }

  /// Releases memory allocated on the native heap.
  @override
  void free(ffi.Pointer pointer) {
    _winCoTaskMemFree(pointer);
  }

  /// Returns a pointer to a native free function.
  ffi.Pointer<ffi.NativeFinalizerFunction> get nativeFree => _winCoTaskMemFreePointer;
}
