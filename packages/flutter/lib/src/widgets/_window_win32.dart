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
//    is `false`.
//
// See: https://github.com/flutter/flutter/issues/30701.

import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Display, FlutterView;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../foundation/_features.dart';
import '_window.dart';
import '_window_positioner.dart';
import 'binding.dart';

/// A Win32 window handle.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
typedef HWND = ffi.Pointer<ffi.Void>;

const int _WM_DESTROY = 0x0002;
const int _WM_SIZE = 0x0005;
const int _WM_ACTIVATE = 0x0006;
const int _WM_CLOSE = 0x0010;

const int _SW_RESTORE = 9;
const int _SW_MAXIMIZE = 3;
const int _SW_MINIMIZE = 6;

const String _kWindowingDisabledErrorMessage = '''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

/// Abstract handler class for Windows messages.
///
/// Implementations of this class should register with
/// [WindowingOwnerWin32.addMessageHandler] to begin receiving messages.
/// When finished handling messages, implementations should deregister
/// themselves with [WindowingOwnerWin32.removeMessageHandler].
abstract class _WindowsMessageHandler {
  /// Handles a window message.
  ///
  /// Returned value, if not null will be returned to the system as LRESULT
  /// and will stop all other handlers from being called. See
  /// https://learn.microsoft.com/en-us/windows/win32/api/winuser/nc-winuser-wndproc
  /// for more information.
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
  WindowingOwnerWin32() : allocator = _CallocAllocator() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    if (!Platform.isWindows) {
      throw UnsupportedError('Only available on the Win32 platform');
    }

    assert(
      WidgetsBinding.instance.platformDispatcher.engineId != null,
      'WindowingOwnerWin32 must be created after the engine has been initialized.',
    );

    _Win32PlatformInterface.initializeWindowing(
      allocator,
      WidgetsBinding.instance.platformDispatcher.engineId!,
      _onMessage,
    );
  }

  final List<_WindowsMessageHandler> _messageHandlers = <_WindowsMessageHandler>[];

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

  @internal
  @override
  DialogWindowController createDialogWindowController({
    required DialogWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    BaseWindowController? parent,
    String? title,
  }) {
    return DialogWindowControllerWin32(
      owner: this,
      delegate: delegate,
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      title: title,
      parent: parent,
    );
  }

  @internal
  @override
  TooltipWindowController createTooltipWindowController({
    required TooltipWindowControllerDelegate delegate,
    required BoxConstraints preferredConstraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) {
    throw UnimplementedError('Tooltip windows are not yet implemented on Windows.');
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
  /// [WindowingOwnerWin32._removeMessageHandler].
  void _addMessageHandler(_WindowsMessageHandler handler) {
    if (_messageHandlers.contains(handler)) {
      return;
    }

    _messageHandlers.add(handler);
  }

  /// Unregister a [WindowsMessageHandler].
  ///
  /// If the handler has not been registered, this method has no effect.
  void _removeMessageHandler(_WindowsMessageHandler handler) {
    _messageHandlers.remove(handler);
  }

  void _onMessage(ffi.Pointer<_WindowsMessage> message) {
    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == message.ref.viewId,
    );

    final int handlesLength = _messageHandlers.length;
    for (final _WindowsMessageHandler handler in _messageHandlers) {
      assert(
        _messageHandlers.length == handlesLength,
        'Message handler list changed while processing message: $message',
      );
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
}

class _RegularWindowMesageHandler implements _WindowsMessageHandler {
  _RegularWindowMesageHandler({required this.controller});

  final RegularWindowControllerWin32 controller;

  @override
  int? handleWindowsMessage(
    FlutterView view,
    HWND windowHandle,
    int message,
    int wParam,
    int lParam,
  ) {
    return controller._handleWindowsMessage(view, windowHandle, message, wParam, lParam);
  }
}

/// Implementation of [RegularWindowController] for the Windows platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [RegularWindowController], the base class for regular windows.
class RegularWindowControllerWin32 extends RegularWindowController {
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
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _handler = _RegularWindowMesageHandler(controller: this);
    owner._addMessageHandler(_handler);
    final int viewId = _Win32PlatformInterface.createRegularWindow(
      _owner.allocator,
      WidgetsBinding.instance.platformDispatcher.engineId!,
      preferredSize,
      preferredConstraints,
      title,
    );
    if (viewId < 0) {
      throw Exception('Windows failed to create a regular window with a valid view id.');
    }

    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    rootView = flutterView;
  }

  final WindowingOwnerWin32 _owner;
  final RegularWindowControllerDelegate _delegate;
  late final _RegularWindowMesageHandler _handler;
  bool _destroyed = false;

  @override
  @internal
  Size get contentSize {
    _ensureNotDestroyed();
    final _ActualContentSize size = _Win32PlatformInterface.getWindowContentSize(getWindowHandle());
    final result = Size(size.width, size.height);
    return result;
  }

  @override
  @internal
  String get title {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.getWindowTitle(_owner.allocator, getWindowHandle());
  }

  @override
  @internal
  bool get isActivated {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.getForegroundWindow() == getWindowHandle();
  }

  @override
  @internal
  bool get isMaximized {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.isZoomed(getWindowHandle()) != 0;
  }

  @override
  @internal
  bool get isMinimized {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.isIconic(getWindowHandle()) != 0;
  }

  @override
  @internal
  bool get isFullscreen {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.getFullscreen(getWindowHandle());
  }

  @override
  @internal
  void setSize(Size? size) {
    _ensureNotDestroyed();
    _Win32PlatformInterface.setWindowContentSize(_owner.allocator, getWindowHandle(), size);
  }

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    _ensureNotDestroyed();
    _Win32PlatformInterface.setWindowConstraints(_owner.allocator, getWindowHandle(), constraints);
    notifyListeners();
  }

  @override
  @internal
  void setTitle(String title) {
    _ensureNotDestroyed();
    _Win32PlatformInterface.setWindowTitle(_owner.allocator, getWindowHandle(), title);
    notifyListeners();
  }

  @override
  @internal
  void activate() {
    _ensureNotDestroyed();
    _Win32PlatformInterface.showWindow(getWindowHandle(), _SW_RESTORE);
  }

  @override
  @internal
  void setMaximized(bool maximized) {
    _ensureNotDestroyed();
    if (maximized) {
      _Win32PlatformInterface.showWindow(getWindowHandle(), _SW_MAXIMIZE);
    } else {
      _Win32PlatformInterface.showWindow(getWindowHandle(), _SW_RESTORE);
    }
  }

  @override
  @internal
  void setMinimized(bool minimized) {
    _ensureNotDestroyed();
    if (minimized) {
      _Win32PlatformInterface.showWindow(getWindowHandle(), _SW_MINIMIZE);
    } else {
      _Win32PlatformInterface.showWindow(getWindowHandle(), _SW_RESTORE);
    }
  }

  @override
  @internal
  void setFullscreen(bool fullscreen, {Display? display}) {
    _Win32PlatformInterface.setFullscreen(
      _owner.allocator,
      getWindowHandle(),
      fullscreen,
      display: display,
    );
  }

  /// Returns HWND pointer to the top level window.
  @internal
  HWND getWindowHandle() {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.getWindowHandle(
      WidgetsBinding.instance.platformDispatcher.engineId!,
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
    _Win32PlatformInterface.destroyWindow(getWindowHandle());
    _destroyed = true;
  }

  int? _handleWindowsMessage(
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
    } else if (message == _WM_DESTROY) {
      _destroyed = true;
      _owner._removeMessageHandler(_handler);
      _delegate.onWindowDestroyed();
      return 0;
    } else if (message == _WM_SIZE || message == _WM_ACTIVATE) {
      notifyListeners();
    }
    return null;
  }
}

class _DialogWindowMesageHandler implements _WindowsMessageHandler {
  _DialogWindowMesageHandler({required this.controller});

  final DialogWindowControllerWin32 controller;

  @override
  int? handleWindowsMessage(
    FlutterView view,
    HWND windowHandle,
    int message,
    int wParam,
    int lParam,
  ) {
    return controller._handleWindowsMessage(view, windowHandle, message, wParam, lParam);
  }
}

/// Implementation of [DialogWindowController] for the Windows platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [DialogWindowController], the base class for dialog windows.
class DialogWindowControllerWin32 extends DialogWindowController {
  /// Creates a new dialog window controller for Win32.
  ///
  /// When this constructor completes the native window has been created and
  /// has a view associated with it.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [DialogWindowController], the base class for dialog windows.
  @internal
  DialogWindowControllerWin32({
    required WindowingOwnerWin32 owner,
    required DialogWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    BaseWindowController? parent,
  }) : _owner = owner,
       _delegate = delegate,
       _parent = parent,
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _handler = _DialogWindowMesageHandler(controller: this);
    owner._addMessageHandler(_handler);
    final int viewId = _Win32PlatformInterface.createDialogWindow(
      _owner.allocator,
      WidgetsBinding.instance.platformDispatcher.engineId!,
      preferredSize,
      preferredConstraints,
      title,
      parent != null
          ? _Win32PlatformInterface.getWindowHandle(
              WidgetsBinding.instance.platformDispatcher.engineId!,
              parent.rootView.viewId,
            )
          : null,
    );
    if (viewId < 0) {
      throw Exception('Windows failed to create a dialog window with a valid view id.');
    }

    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    rootView = flutterView;
  }

  final WindowingOwnerWin32 _owner;
  final DialogWindowControllerDelegate _delegate;
  final BaseWindowController? _parent;
  late final _DialogWindowMesageHandler _handler;
  bool _destroyed = false;

  @override
  @internal
  Size get contentSize {
    _ensureNotDestroyed();
    final _ActualContentSize size = _Win32PlatformInterface.getWindowContentSize(getWindowHandle());
    final result = Size(size.width, size.height);
    return result;
  }

  @override
  @internal
  String get title {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.getWindowTitle(_owner.allocator, getWindowHandle());
  }

  @override
  @internal
  bool get isActivated {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.getForegroundWindow() == getWindowHandle();
  }

  @override
  @internal
  bool get isMinimized {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.isIconic(getWindowHandle()) != 0;
  }

  @override
  @internal
  void setSize(Size? size) {
    _ensureNotDestroyed();
    _Win32PlatformInterface.setWindowContentSize(_owner.allocator, getWindowHandle(), size);
    // Note that we do not notify the listener when setting the size,
    // as that will happen when the WM_SIZE message is received in
    // _handleWindowsMessage.
  }

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    _ensureNotDestroyed();
    _Win32PlatformInterface.setWindowConstraints(_owner.allocator, getWindowHandle(), constraints);
    notifyListeners();
  }

  @override
  @internal
  void setTitle(String title) {
    _ensureNotDestroyed();
    _Win32PlatformInterface.setWindowTitle(_owner.allocator, getWindowHandle(), title);
    notifyListeners();
  }

  @override
  @internal
  void activate() {
    _ensureNotDestroyed();
    _Win32PlatformInterface.showWindow(getWindowHandle(), _SW_RESTORE);
  }

  @override
  @internal
  void setMinimized(bool minimized) {
    if (parent != null) {
      return;
    }

    _ensureNotDestroyed();
    if (minimized) {
      _Win32PlatformInterface.showWindow(getWindowHandle(), _SW_MINIMIZE);
    } else {
      _Win32PlatformInterface.showWindow(getWindowHandle(), _SW_RESTORE);
    }
  }

  @override
  @internal
  BaseWindowController? get parent => _parent;

  /// Returns HWND pointer to the top level window.
  @internal
  HWND getWindowHandle() {
    _ensureNotDestroyed();
    return _Win32PlatformInterface.getWindowHandle(
      WidgetsBinding.instance.platformDispatcher.engineId!,
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
    _Win32PlatformInterface.destroyWindow(getWindowHandle());
  }

  int? _handleWindowsMessage(
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
    } else if (message == _WM_DESTROY) {
      _destroyed = true;
      _owner._removeMessageHandler(_handler);
      _delegate.onWindowDestroyed();
      return 0;
    } else if (message == _WM_SIZE || message == _WM_ACTIVATE) {
      notifyListeners();
    }
    return null;
  }
}

class _Win32PlatformInterface {
  static void initializeWindowing(
    ffi.Allocator allocator,
    int engineId,
    void Function(ffi.Pointer<_WindowsMessage>) onMessage,
  ) {
    final ffi.Pointer<_WindowingInitRequest> request = allocator<_WindowingInitRequest>();
    try {
      request.ref.onMessage =
          ffi.NativeCallable<ffi.Void Function(ffi.Pointer<_WindowsMessage>)>.isolateLocal(
            onMessage,
          ).nativeFunction;
      _initializeWindowing(engineId, request);
    } finally {
      allocator.free(request);
    }
  }

  @ffi.Native<ffi.Void Function(ffi.Int64, ffi.Pointer<_WindowingInitRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_Initialize',
  )
  external static void _initializeWindowing(
    int engineId,
    ffi.Pointer<_WindowingInitRequest> request,
  );

  static int createRegularWindow(
    ffi.Allocator allocator,
    int engineId,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  ) {
    final ffi.Pointer<_RegularWindowCreationRequest> request =
        allocator<_RegularWindowCreationRequest>();
    try {
      request.ref.preferredSize.from(preferredSize);
      request.ref.preferredConstraints.from(preferredConstraints);
      request.ref.title = (title ?? 'Regular window').toNativeUtf16(allocator: allocator);
      return _createRegularWindow(engineId, request);
    } finally {
      allocator.free(request);
    }
  }

  @ffi.Native<ffi.Int64 Function(ffi.Int64, ffi.Pointer<_RegularWindowCreationRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_CreateRegularWindow',
  )
  external static int _createRegularWindow(
    int engineId,
    ffi.Pointer<_RegularWindowCreationRequest> request,
  );

  static int createDialogWindow(
    ffi.Allocator allocator,
    int engineId,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    HWND? parent,
  ) {
    final ffi.Pointer<_DialogWindowCreationRequest> request =
        allocator<_DialogWindowCreationRequest>();
    try {
      request.ref.preferredSize.from(preferredSize);
      request.ref.preferredConstraints.from(preferredConstraints);
      request.ref.title = (title ?? 'Dialog window').toNativeUtf16(allocator: allocator);
      request.ref.parentOrNull = parent ?? ffi.Pointer<ffi.Void>.fromAddress(0);
      return _createDialogWindow(engineId, request);
    } finally {
      allocator.free(request);
    }
  }

  @ffi.Native<ffi.Int64 Function(ffi.Int64, ffi.Pointer<_DialogWindowCreationRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_CreateDialogWindow',
  )
  external static int _createDialogWindow(
    int engineId,
    ffi.Pointer<_DialogWindowCreationRequest> request,
  );

  @ffi.Native<HWND Function(ffi.Int64, ffi.Int64)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetTopLevelWindowHandle',
  )
  external static HWND getWindowHandle(int engineId, int viewId);

  @ffi.Native<ffi.Void Function(HWND)>(symbol: 'DestroyWindow')
  external static void destroyWindow(HWND windowHandle);

  @ffi.Native<_ActualContentSize Function(HWND)>(
    symbol: 'InternalFlutterWindows_WindowManager_GetWindowContentSize',
  )
  external static _ActualContentSize getWindowContentSize(HWND windowHandle);

  static void setWindowTitle(ffi.Allocator allocator, HWND windowHandle, String title) {
    final ffi.Pointer<_Utf16> titlePointer = title.toNativeUtf16(allocator: allocator);
    try {
      _setWindowTitle(windowHandle, titlePointer);
    } finally {
      allocator.free(titlePointer);
    }
  }

  @ffi.Native<ffi.Void Function(HWND, ffi.Pointer<_Utf16>)>(symbol: 'SetWindowTextW')
  external static void _setWindowTitle(HWND windowHandle, ffi.Pointer<_Utf16> title);

  static void setWindowContentSize(ffi.Allocator allocator, HWND windowHandle, Size? size) {
    final ffi.Pointer<_WindowSizeRequest> request = allocator<_WindowSizeRequest>();
    try {
      request.ref.from(size);
      _setWindowContentSize(windowHandle, request);
    } finally {
      allocator.free(request);
    }
  }

  @ffi.Native<ffi.Void Function(HWND, ffi.Pointer<_WindowSizeRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetWindowSize',
  )
  external static void _setWindowContentSize(
    HWND windowHandle,
    ffi.Pointer<_WindowSizeRequest> size,
  );

  static void setWindowConstraints(
    ffi.Allocator allocator,
    HWND windowHandle,
    BoxConstraints? constraints,
  ) {
    final ffi.Pointer<_WindowConstraintsRequest> request = allocator<_WindowConstraintsRequest>();
    try {
      request.ref.from(constraints);
      _setWindowConstraints(windowHandle, request);
    } finally {
      allocator.free(request);
    }
  }

  @ffi.Native<ffi.Void Function(HWND, ffi.Pointer<_WindowConstraintsRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetWindowConstraints',
  )
  external static void _setWindowConstraints(
    HWND windowHandle,
    ffi.Pointer<_WindowConstraintsRequest> constraints,
  );

  @ffi.Native<ffi.Void Function(HWND, ffi.Int32)>(symbol: 'ShowWindow')
  external static void showWindow(HWND windowHandle, int command);

  @ffi.Native<ffi.Int32 Function(HWND)>(symbol: 'IsIconic')
  external static int isIconic(HWND windowHandle);

  @ffi.Native<ffi.Int32 Function(HWND)>(symbol: 'IsZoomed')
  external static int isZoomed(HWND windowHandle);

  static void setFullscreen(
    ffi.Allocator allocator,
    HWND windowHandle,
    bool fullscreen, {
    Display? display,
  }) {
    final ffi.Pointer<_WindowFullscreenRequest> request = allocator<_WindowFullscreenRequest>();
    try {
      request.ref.fullscreen = fullscreen;
      request.ref.hasDisplayId = display != null;
      request.ref.displayId = display?.id ?? 0;
      _setFullscreen(windowHandle, request);
    } finally {
      allocator.free(request);
    }
  }

  @ffi.Native<ffi.Void Function(HWND, ffi.Pointer<_WindowFullscreenRequest>)>(
    symbol: 'InternalFlutterWindows_WindowManager_SetFullscreen',
  )
  external static void _setFullscreen(
    HWND windowHandle,
    ffi.Pointer<_WindowFullscreenRequest> request,
  );

  @ffi.Native<ffi.Bool Function(HWND)>(symbol: 'InternalFlutterWindows_WindowManager_GetFullscreen')
  external static bool getFullscreen(HWND windowHandle);

  @ffi.Native<ffi.Int32 Function(HWND)>(symbol: 'GetWindowTextLengthW')
  external static int _getWindowTextLength(HWND windowHandle);

  @ffi.Native<ffi.Int32 Function(HWND, ffi.Pointer<_Utf16>, ffi.Int32)>(symbol: 'GetWindowTextW')
  external static int _getWindowText(
    HWND windowHandle,
    ffi.Pointer<_Utf16> lpString,
    int maxLength,
  );

  static String getWindowTitle(ffi.Allocator allocator, HWND windowHandle) {
    final int length = _getWindowTextLength(windowHandle);
    if (length == 0) {
      return '';
    }

    final ffi.Pointer<ffi.Uint16> data = allocator<ffi.Uint16>(length + 1);
    try {
      final ffi.Pointer<_Utf16> buffer = data.cast<_Utf16>();
      _getWindowText(windowHandle, buffer, length + 1);
      return buffer.toDartString();
    } finally {
      allocator.free(data);
    }
  }

  @ffi.Native<HWND Function()>(symbol: 'GetForegroundWindow')
  external static HWND getForegroundWindow();
}

/// Payload for the creation method used by [_Win32PlatformInterface.createRegularWindow].
final class _RegularWindowCreationRequest extends ffi.Struct {
  external _WindowSizeRequest preferredSize;
  external _WindowConstraintsRequest preferredConstraints;
  external ffi.Pointer<_Utf16> title;
}

/// Payload for the creation method used by [_Win32PlatformInterface.createDialogWindow].
final class _DialogWindowCreationRequest extends ffi.Struct {
  external _WindowSizeRequest preferredSize;
  external _WindowConstraintsRequest preferredConstraints;
  external ffi.Pointer<_Utf16> title;
  external HWND parentOrNull;
}

/// Payload for the initialization request for the windowing subsystem used
/// by the constructor for [WindowingOwnerWin32].
final class _WindowingInitRequest extends ffi.Struct {
  external ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<_WindowsMessage>)>>
  onMessage;
}

/// Payload for the size of a window used by [_RegularWindowCreationRequest] and
/// [_Win32PlatformInterface.setWindowContentSize].
final class _WindowSizeRequest extends ffi.Struct {
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

/// Payload for the constraints of a window used by [_RegularWindowCreationRequest] and
/// [_Win32PlatformInterface.setWindowConstraints].
final class _WindowConstraintsRequest extends ffi.Struct {
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

/// A message received for all toplevel windows, used by [_WindowingInitRequest].
final class _WindowsMessage extends ffi.Struct {
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
/// [_Win32PlatformInterface.getWindowContentSize].
final class _ActualContentSize extends ffi.Struct {
  @ffi.Double()
  external double width;

  @ffi.Double()
  external double height;
}

/// Payload for the [_Win32PlatformInterface.setFullscreen] request.
final class _WindowFullscreenRequest extends ffi.Struct {
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
  /// but not including the first NUL character.
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
    final buffer = StringBuffer();
    var i = 0;
    while (true) {
      final int char = (codeUnits + i).value;
      if (char == 0) {
        return buffer.toString();
      }
      buffer.writeCharCode(char);
      i++;
    }
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
    final List<int> units = codeUnits;
    final ffi.Pointer<ffi.Uint16> result = allocator<ffi.Uint16>(units.length + 1);
    final Uint16List nativeString = result.asTypedList(units.length + 1);
    nativeString.setRange(0, units.length, units);
    nativeString[units.length] = 0;
    return result.cast();
  }
}

typedef _WinCoTaskMemAllocNative = ffi.Pointer<ffi.NativeType> Function(ffi.Size);
typedef _WinCoTaskMemAlloc = ffi.Pointer<ffi.NativeType> Function(int);
typedef _WinCoTaskMemFreeNative = ffi.Void Function(ffi.Pointer<ffi.NativeType>);
typedef _WinCoTaskMemFree = void Function(ffi.Pointer<ffi.NativeType>);

final class _CallocAllocator implements ffi.Allocator {
  _CallocAllocator() {
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
  // ignore: always_specify_types
  void _fillMemory(ffi.Pointer destination, int length, int fill) {
    final ffi.Pointer<ffi.Uint8> ptr = destination.cast<ffi.Uint8>();
    for (var i = 0; i < length; i++) {
      ptr[i] = fill;
    }
  }

  /// Fills a block of memory with zeros.
  // ignore: always_specify_types
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
  // ignore: always_specify_types
  void free(ffi.Pointer pointer) {
    _winCoTaskMemFree(pointer);
  }

  /// Returns a pointer to a native free function.
  ffi.Pointer<ffi.NativeFinalizerFunction> get nativeFree => _winCoTaskMemFreePointer;
}
