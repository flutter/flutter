// ignore_for_file: public_member_api_docs, avoid_unused_constructor_parameters

import 'dart:ffi' hide Size;
import 'dart:ui' show FlutterView;
import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

abstract class WindowsMessageHandler {
  /// Handles a window message. Returned value, if not null will be
  /// returned to the system as LRESULT and will stop all other
  /// handlers from being called.
  int? handleWindowsMessage(
    FlutterView view,
    Pointer<Void> windowHandle,
    int message,
    int wParam,
    int lParam,
  );
}

class WindowingOwnerWin32 extends WindowingOwner {
  WindowingOwnerWin32() {
    final Pointer<_WindowingInitRequest> request =
        ffi.calloc<_WindowingInitRequest>()
          ..ref.onMessage =
              NativeCallable<Void Function(Pointer<_WindowsMessage>)>.isolateLocal(
                _onMessage,
              ).nativeFunction;
    _initializeWindowing(PlatformDispatcher.instance.engineId!, request);
    ffi.calloc.free(request);
  }

  @override
  RegularWindowController createRegularWindowController({
    required Size size,
    required RegularWindowControllerDelegate delegate,
    BoxConstraints? sizeConstraints,
  }) {
    return RegularWindowControllerWin32(
      owner: this,
      delegate: delegate,
      size: size,
      sizeConstraints: sizeConstraints,
    );
  }

  void addMessageHandler(WindowsMessageHandler handler) {
    _messageHandlers.add(handler);
  }

  void removeMessageHandler(WindowsMessageHandler handler) {
    _messageHandlers.remove(handler);
  }

  final List<WindowsMessageHandler> _messageHandlers = <WindowsMessageHandler>[];

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

  @Native<Bool Function(Int64)>(symbol: 'flutter_windowing_has_top_level_windows')
  external static bool _hasTopLevelWindows(int engineId);

  @Native<Void Function(Int64, Pointer<_WindowingInitRequest>)>(
    symbol: 'flutter_windowing_initialize',
  )
  external static void _initializeWindowing(int engineId, Pointer<_WindowingInitRequest> request);
}

class RegularWindowControllerWin32 extends RegularWindowController
    implements WindowsMessageHandler {
  RegularWindowControllerWin32({
    required WindowingOwnerWin32 owner,
    required RegularWindowControllerDelegate delegate,
    BoxConstraints? sizeConstraints,
    required Size size,
  }) : _owner = owner,
       _delegate = delegate,
       super.empty() {
    owner.addMessageHandler(this);
    final Pointer<_WindowCreationRequest> request =
        ffi.calloc<_WindowCreationRequest>()
          ..ref.width = size.width
          ..ref.height = size.height
          ..ref.minWidth = sizeConstraints?.minWidth ?? 0
          ..ref.minHeight = sizeConstraints?.minHeight ?? 0
          ..ref.maxWidth = sizeConstraints?.maxWidth ?? 0
          ..ref.maxHeight = sizeConstraints?.maxHeight ?? 0;
    final int viewId = _createWindow(PlatformDispatcher.instance.engineId!, request);
    ffi.calloc.free(request);
    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    setView(flutterView);
  }

  @override
  Size get size {
    _ensureNotDestroyed();
    final Pointer<_Size> size = ffi.calloc<_Size>();
    _getWindowSize(getWindowHandle(), size);
    final Size result = Size(size.ref.width, size.ref.height);
    ffi.calloc.free(size);
    return result;
  }

  @override
  WindowState get state {
    _ensureNotDestroyed();
    final int state = _getWindowState(getWindowHandle());
    return WindowState.values[state];
  }

  @override
  void modify({Size? size, String? title, WindowState? state}) {
    _ensureNotDestroyed();
    if (state != null) {
      setWindowState(state);
    }
    if (title != null) {
      setWindowTitle(title);
    }
    if (size != null) {
      setWindowSize(size);
    }
  }

  void setWindowState(WindowState state) {
    _ensureNotDestroyed();
    _setWindowState(getWindowHandle(), state.index);
  }

  void setWindowTitle(String title) {
    _ensureNotDestroyed();
    final Pointer<ffi.Utf16> titlePointer = title.toNativeUtf16();
    _setWindowTitle(getWindowHandle(), titlePointer);
    ffi.calloc.free(titlePointer);
  }

  void setWindowSize(Size size) {
    _ensureNotDestroyed();
    _setWindowSize(getWindowHandle(), size.width, size.height);
  }

  Pointer<Void> getWindowHandle() {
    _ensureNotDestroyed();
    return _getWindowHandle(PlatformDispatcher.instance.engineId!, rootView.viewId);
  }

  void _ensureNotDestroyed() {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
  }

  final RegularWindowControllerDelegate _delegate;
  bool _destroyed = false;

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    _destroyWindow(getWindowHandle());;
    _destroyed = true;
    _delegate.onWindowDestroyed();
    _owner.removeMessageHandler(this);
  }

  static const int WM_SIZE = 0x0005;
  static const int WM_CLOSE = 0x0010;

  @override
  int? handleWindowsMessage(
    FlutterView view,
    Pointer<Void> windowHandle,
    int message,
    int wParam,
    int lParam,
  ) {
    if (view.viewId != rootView.viewId) {
      return null;
    }

    if (message == WM_CLOSE) {
      _delegate.onWindowCloseRequested(this);
      return 0;
    } else if (message == WM_SIZE) {
      notifyListeners();
    }
    return null;
  }

  final WindowingOwnerWin32 _owner;

  @Native<Int64 Function(Int64, Pointer<_WindowCreationRequest>)>(
    symbol: 'flutter_create_regular_window',
  )
  external static int _createWindow(int engineId, Pointer<_WindowCreationRequest> request);

  @Native<Pointer<Void> Function(Int64, Int64)>(symbol: 'flutter_get_window_handle')
  external static Pointer<Void> _getWindowHandle(int engineId, int viewId);

  @Native<Void Function(Pointer<Void>)>(symbol: 'DestroyWindow')
  external static void _destroyWindow(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>, Pointer<_Size>)>(symbol: 'flutter_get_window_size')
  external static void _getWindowSize(Pointer<Void> windowHandle, Pointer<_Size> size);

  @Native<Int64 Function(Pointer<Void>)>(symbol: 'flutter_get_window_state')
  external static int _getWindowState(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>, Int64)>(symbol: 'flutter_set_window_state')
  external static void _setWindowState(Pointer<Void> windowHandle, int state);

  @Native<Void Function(Pointer<Void>, Pointer<ffi.Utf16>)>(symbol: 'SetWindowTextW')
  external static void _setWindowTitle(Pointer<Void> windowHandle, Pointer<ffi.Utf16> title);

  @Native<Void Function(Pointer<Void>, Double, Double)>(symbol: 'flutter_set_window_size')
  external static void _setWindowSize(Pointer<Void> windowHandle, double width, double height);
}

/// Request to initialize windowing system.
final class _WindowingInitRequest extends Struct {
  external Pointer<NativeFunction<Void Function(Pointer<_WindowsMessage>)>> onMessage;
}

final class _WindowCreationRequest extends Struct {
  @Double()
  external double width;

  @Double()
  external double height;

  @Double()
  external double minWidth;

  @Double()
  external double minHeight;

  @Double()
  external double maxWidth;

  @Double()
  external double maxHeight;
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

final class _Size extends Struct {
  @Double()
  external double width;

  @Double()
  external double height;
}
