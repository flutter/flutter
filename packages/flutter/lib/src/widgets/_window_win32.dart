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

import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:ui' show Display, FlutterView;
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '_window.dart';
import 'binding.dart';

/// A Win32 window handle.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
typedef HWND = Pointer<Void>;

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
///  If [Platform.isWindows] is false, then the constructor will throw an
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
      platformDispatcher = PlatformDispatcher.instance {
    if (!Platform.isWindows) {
      throw UnsupportedError('Only available on the Win32 platform');
    }

    final Pointer<WindowingInitRequest> request = ffi.calloc<WindowingInitRequest>()
      ..ref.onMessage = NativeCallable<Void Function(Pointer<WindowsMessage>)>.isolateLocal(
        _onMessage,
      ).nativeFunction;
    win32PlatformInterface.initialize(platformDispatcher.engineId!, request);
    ffi.calloc.free(request);
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
  }) {
    final Pointer<WindowingInitRequest> request = ffi.calloc<WindowingInitRequest>()
      ..ref.onMessage = NativeCallable<Void Function(Pointer<WindowsMessage>)>.isolateLocal(
        _onMessage,
      ).nativeFunction;
    win32PlatformInterface.initialize(platformDispatcher.engineId!, request);
    ffi.calloc.free(request);
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

  void _onMessage(Pointer<WindowsMessage> message) {
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
/// If [Platform.isWindows] is false, then the constructor will throw an
/// [UnsupportedError].
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
  /// If [Platform.isWindows] is false, then this constructor will throw an
  /// [UnsupportedError].
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
    final Pointer<WindowCreationRequest> request = ffi.calloc<WindowCreationRequest>()
      ..ref.preferredSize.from(preferredSize)
      ..ref.preferredConstraints.from(preferredConstraints)
      ..ref.title = (title ?? 'Regular window').toNativeUtf16();
    final int viewId = _owner.win32PlatformInterface.createWindow(
      _owner.platformDispatcher.engineId!,
      request,
    );
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

    final Pointer<Uint16> data = ffi.calloc<Uint16>(length + 1);
    try {
      final Pointer<ffi.Utf16> buffer = data.cast<ffi.Utf16>();
      _owner.win32PlatformInterface.getWindowText(getWindowHandle(), buffer, length + 1);
      return buffer.toDartString();
    } finally {
      ffi.calloc.free(data);
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
    final Pointer<WindowSizeRequest> request = ffi.calloc<WindowSizeRequest>();
    request.ref.hasSize = size != null;
    request.ref.width = size?.width ?? 0;
    request.ref.height = size?.height ?? 0;
    _owner.win32PlatformInterface.setWindowContentSize(getWindowHandle(), request);
    ffi.calloc.free(request);
  }

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    _ensureNotDestroyed();
    final Pointer<WindowConstraintsRequest> request = ffi.calloc<WindowConstraintsRequest>();
    request.ref.from(constraints);
    _owner.win32PlatformInterface.setWindowConstraints(getWindowHandle(), request);
    ffi.calloc.free(request);

    notifyListeners();
  }

  @override
  @internal
  void setTitle(String title) {
    _ensureNotDestroyed();
    final Pointer<ffi.Utf16> titlePointer = title.toNativeUtf16();
    _owner.win32PlatformInterface.setWindowTitle(getWindowHandle(), titlePointer);
    ffi.calloc.free(titlePointer);

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
    final Pointer<WindowFullscreenRequest> request = ffi.calloc<WindowFullscreenRequest>();
    request.ref.hasDisplayId = false;
    request.ref.displayId = display?.id ?? 0;
    request.ref.fullscreen = fullscreen;
    _owner.win32PlatformInterface.setFullscreen(getWindowHandle(), request);
    ffi.calloc.free(request);
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

/// Abstract class that wraps native access to the win32 API via FFI.
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
  void initialize(int engineId, Pointer<WindowingInitRequest> request);

  /// Create a regular window on the provided engine.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  int createWindow(int engineId, Pointer<WindowCreationRequest> request);

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
  void setWindowTitle(HWND windowHandle, Pointer<ffi.Utf16> title);

  /// Set the content size of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void setWindowContentSize(HWND windowHandle, Pointer<WindowSizeRequest> size);

  /// Set the constraints of the window.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @visibleForTesting
  @internal
  void setWindowConstraints(HWND windowHandle, Pointer<WindowConstraintsRequest> constraints);

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
  void setFullscreen(HWND windowHandle, Pointer<WindowFullscreenRequest> request);

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
  int getWindowText(HWND windowHandle, Pointer<ffi.Utf16> lpString, int maxLength);

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
  void initialize(int engineId, Pointer<WindowingInitRequest> request) {
    _initializeWindowing(engineId, request);
  }

  @override
  int createWindow(int engineId, Pointer<WindowCreationRequest> request) {
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
  void setWindowTitle(HWND windowHandle, Pointer<ffi.Utf16> title) {
    _setWindowTitle(windowHandle, title);
  }

  @override
  void setWindowContentSize(HWND windowHandle, Pointer<WindowSizeRequest> size) {
    _setWindowContentSize(windowHandle, size);
  }

  @override
  void setWindowConstraints(HWND windowHandle, Pointer<WindowConstraintsRequest> constraints) {
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
  void setFullscreen(HWND windowHandle, Pointer<WindowFullscreenRequest> request) {
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
  int getWindowText(HWND windowHandle, Pointer<ffi.Utf16> lpString, int maxLength) {
    return _getWindowText(windowHandle, lpString, maxLength);
  }

  @override
  HWND getForegroundWindow() {
    return _getForegroundWindow();
  }

  @Native<Bool Function(Int64)>(symbol: 'InternalFlutterWindows_WindowManager_HasTopLevelWindows')
  external static bool _hasTopLevelWindows(int engineId);

  @Native<Void Function(Int64, Pointer<WindowingInitRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_Initialize',
  )
  external static void _initializeWindowing(int engineId, Pointer<WindowingInitRequest> request);

  @Native<Int64 Function(Int64, Pointer<WindowCreationRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_CreateRegularWindow',
  )
  external static int _createWindow(int engineId, Pointer<WindowCreationRequest> request);

  @Native<HWND Function(Int64, Int64)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle',
  )
  external static HWND _getWindowHandle(int engineId, int viewId);

  @Native<Void Function(HWND)>(symbol: 'DestroyWindow')
  external static void _destroyWindow(HWND windowHandle);

  @Native<ActualContentSize Function(HWND)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetWindowContentSize',
  )
  external static ActualContentSize _getWindowContentSize(HWND windowHandle);

  @Native<Void Function(HWND, Pointer<ffi.Utf16>)>(symbol: 'SetWindowTextW')
  external static void _setWindowTitle(HWND windowHandle, Pointer<ffi.Utf16> title);

  @Native<Void Function(HWND, Pointer<WindowSizeRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetWindowSize',
  )
  external static void _setWindowContentSize(HWND windowHandle, Pointer<WindowSizeRequest> size);

  @Native<Void Function(HWND, Pointer<WindowConstraintsRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetWindowConstraints',
  )
  external static void _setWindowConstraints(
    HWND windowHandle,
    Pointer<WindowConstraintsRequest> constraints,
  );

  @Native<Void Function(HWND, Int32)>(symbol: 'ShowWindow')
  external static void _showWindow(HWND windowHandle, int command);

  @Native<Int32 Function(HWND)>(symbol: 'IsIconic')
  external static int _isIconic(HWND windowHandle);

  @Native<Int32 Function(HWND)>(symbol: 'IsZoomed')
  external static int _isZoomed(HWND windowHandle);

  @Native<Void Function(HWND, Pointer<WindowFullscreenRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetFullscreen',
  )
  external static void _setFullscreen(HWND windowHandle, Pointer<WindowFullscreenRequest> request);

  @Native<Bool Function(HWND)>(symbol: 'InternalFlutterWindows_WindowManager_GetFullscreen')
  external static bool _getFullscreen(HWND windowHandle);

  @Native<Int32 Function(HWND)>(symbol: 'GetWindowTextLengthW')
  external static int _getWindowTextLength(HWND windowHandle);

  @Native<Int32 Function(HWND, Pointer<ffi.Utf16>, Int32)>(symbol: 'GetWindowTextW')
  external static int _getWindowText(HWND windowHandle, Pointer<ffi.Utf16> lpString, int maxLength);

  @Native<HWND Function()>(symbol: 'GetForegroundWindow')
  external static HWND _getForegroundWindow();
}

/// Payload for the creation method used by [Win32PlatformInterface.createWindow].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowCreationRequest extends Struct {
  external WindowSizeRequest preferredSize;
  external WindowConstraintsRequest preferredConstraints;
  external Pointer<ffi.Utf16> title;
}

/// Payload for the initialization request for the windowing subsystem used
/// by the constructor for [WindowingOwnerWin32].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowingInitRequest extends Struct {
  external Pointer<NativeFunction<Void Function(Pointer<WindowsMessage>)>> onMessage;
}

/// Payload for the size of a window used by [WindowCreationRequest] and
/// [Win32PlatformInterface.setWindowContentSize].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowSizeRequest extends Struct {
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

/// Payload for the constraints of a window used by [WindowCreationRequest] and
/// [Win32PlatformInterface.setWindowConstraints].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowConstraintsRequest extends Struct {
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

/// A message received for all toplevel windows, used by [WindowingInitRequest].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowsMessage extends Struct {
  @Int64()
  external int viewId;

  external HWND windowHandle;

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

/// Holds the real size of a window as retrieved from
/// [Win32PlatformInterface.getWindowContentSize].
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class ActualContentSize extends Struct {
  @Double()
  external double width;

  @Double()
  external double height;
}

/// Payload for the [Win32PlatformInterface.setFullscreen] request.
///
/// {@macro flutter.widgets.windowing.experimental}
@visibleForTesting
@internal
final class WindowFullscreenRequest extends Struct {
  @Bool()
  external bool fullscreen;

  @Bool()
  external bool hasDisplayId;

  @Uint64()
  external int displayId;
}
