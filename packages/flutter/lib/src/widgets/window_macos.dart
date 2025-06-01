// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi' hide Size;
import 'dart:ui' show FlutterView;

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'binding.dart';
import 'window.dart';

/// The macOS implementation of the windowing API.
class WindowingOwnerMacOS extends WindowingOwner {
  @override
  RegularWindowController createRegularWindowController({
    required WindowSizing contentSize,
    required RegularWindowControllerDelegate delegate,
  }) {
    final RegularWindowControllerMacOS res = RegularWindowControllerMacOS(
      owner: this,
      delegate: delegate,
      contentSize: contentSize,
    );
    _activeControllers.add(res);
    return res;
  }

  @override
  bool hasTopLevelWindows() {
    return _activeControllers.isNotEmpty;
  }

  final List<WindowController> _activeControllers = <WindowController>[];

  /// Returns the window handle for the given [view], or null is the window
  /// handle is not available.
  /// The window handle is a pointer to NSWindow instance.
  static Pointer<Void> getWindowHandle(FlutterView view) {
    return _getWindowHandle(PlatformDispatcher.instance.engineId!, view.viewId);
  }

  @Native<Pointer<Void> Function(Int64, Int64)>(symbol: 'FlutterGetWindowHandle')
  external static Pointer<Void> _getWindowHandle(int engineId, int viewId);
}

/// The macOS implementation of the regular window controller.
class RegularWindowControllerMacOS extends RegularWindowController {
  /// Creates a new regular window controller for macOS. When this constructor
  /// completes the FlutterView is created and framework is aware of it.
  RegularWindowControllerMacOS({
    required WindowingOwnerMacOS owner,
    required RegularWindowControllerDelegate delegate,
    required WindowSizing contentSize,
    String? title,
  }) : _owner = owner,
       _delegate = delegate,
       super.empty() {
    _onClose = NativeCallable<Void Function()>.isolateLocal(_handleOnClose);
    _onResize = NativeCallable<Void Function()>.isolateLocal(_handleOnResize);
    final Pointer<_WindowCreationRequest> request =
        ffi.calloc<_WindowCreationRequest>()
          ..ref.contentSize.set(contentSize)
          ..ref.onClose = _onClose.nativeFunction
          ..ref.onSizeChange = _onResize.nativeFunction;

    final int viewId = _createWindow(PlatformDispatcher.instance.engineId!, request);
    ffi.calloc.free(request);
    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    setView(flutterView);
    if (title != null) {
      setTitle(title);
    }
  }

  /// Returns window handle for the current window.
  /// The handle is a pointer to NSWindow instance.
  Pointer<Void> getWindowHandle() {
    _ensureNotDestroyed();
    return WindowingOwnerMacOS.getWindowHandle(rootView);
  }

  bool _destroyed = false;

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    final Pointer<Void> handle = getWindowHandle();
    _destroyed = true;
    _owner._activeControllers.remove(this);
    _destroyWindow(PlatformDispatcher.instance.engineId!, handle);
    _delegate.onWindowDestroyed();
    _onClose.close();
    _onResize.close();
  }

  void _handleOnClose() {
    _delegate.onWindowCloseRequested(this);
  }

  void _handleOnResize() {
    notifyListeners();
  }

  @override
  void updateContentSize(WindowSizing sizing) {
    _ensureNotDestroyed();
    final Pointer<_Sizing> ffiSizing = ffi.calloc<_Sizing>();
    ffiSizing.ref.set(sizing);
    _setWindowContentSize(getWindowHandle(), ffiSizing);
    ffi.calloc.free(ffiSizing);
  }

  @override
  void setTitle(String title) {
    _ensureNotDestroyed();
    final Pointer<ffi.Utf8> titlePointer = title.toNativeUtf8();
    _setWindowTitle(getWindowHandle(), titlePointer);
    ffi.calloc.free(titlePointer);
  }

  final WindowingOwnerMacOS _owner;
  final RegularWindowControllerDelegate _delegate;
  late final NativeCallable<Void Function()> _onClose;
  late final NativeCallable<Void Function()> _onResize;

  @override
  Size get contentSize {
    _ensureNotDestroyed();
    final _Size size = _getWindowContentSize(getWindowHandle());
    return Size(size.width, size.height);
  }

  @override
  void activate() {
    _ensureNotDestroyed();
    _activate(getWindowHandle());
  }

  @override
  void setMaximized(bool maximized) {
    _ensureNotDestroyed();
    _setMaximized(getWindowHandle(), maximized);
  }

  @override
  bool isMaximized() {
    _ensureNotDestroyed();
    return _isMaximized(getWindowHandle());
  }

  @override
  void setMinimized(bool minimized) {
    _ensureNotDestroyed();
    if (minimized) {
      _minimize(getWindowHandle());
    } else {
      _unminimize(getWindowHandle());
    }
  }

  @override
  bool isMinimized() {
    _ensureNotDestroyed();
    return _isMinimized(getWindowHandle());
  }

  @override
  void setFullscreen(bool fullscreen, {int? displayId}) {
    _ensureNotDestroyed();
    _setFullscreen(getWindowHandle(), fullscreen);
  }

  @override
  bool isFullscreen() {
    _ensureNotDestroyed();
    return _isFullscreen(getWindowHandle());
  }

  void _ensureNotDestroyed() {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
  }

  @Native<Int64 Function(Int64, Pointer<_WindowCreationRequest>)>(
    symbol: 'FlutterCreateRegularWindow',
  )
  external static int _createWindow(int engineId, Pointer<_WindowCreationRequest> request);

  @Native<Void Function(Int64, Pointer<Void>)>(symbol: 'FlutterDestroyWindow')
  external static void _destroyWindow(int engineId, Pointer<Void> handle);

  @Native<_Size Function(Pointer<Void>)>(symbol: 'FlutterGetWindowContentSize')
  external static _Size _getWindowContentSize(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>, Pointer<_Sizing>)>(symbol: 'FlutterSetWindowContentSize')
  external static void _setWindowContentSize(Pointer<Void> windowHandle, Pointer<_Sizing> size);

  @Native<Void Function(Pointer<Void>, Pointer<ffi.Utf8>)>(symbol: 'FlutterSetWindowTitle')
  external static void _setWindowTitle(Pointer<Void> windowHandle, Pointer<ffi.Utf8> title);

  @Native<Void Function(Pointer<Void>, Bool)>(symbol: 'FlutterWindowSetMaximized')
  external static void _setMaximized(Pointer<Void> windowHandle, bool maximized);

  @Native<Bool Function(Pointer<Void>)>(symbol: 'FlutterWindowIsMaximized')
  external static bool _isMaximized(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>)>(symbol: 'FlutterWindowMinimize')
  external static void _minimize(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>)>(symbol: 'FlutterWindowUnminimize')
  external static void _unminimize(Pointer<Void> windowHandle);

  @Native<Bool Function(Pointer<Void>)>(symbol: 'FlutterWindowIsMinimized')
  external static bool _isMinimized(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>, Bool)>(symbol: 'FlutterWindowSetFullScreen')
  external static void _setFullscreen(Pointer<Void> windowHandle, bool fullscreen);

  @Native<Bool Function(Pointer<Void>)>(symbol: 'FlutterWindowIsFullScreen')
  external static bool _isFullscreen(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>)>(symbol: 'FlutterWindowActivate')
  external static void _activate(Pointer<Void> windowHandle);
}

final class _Sizing extends Struct {
  @Bool()
  external bool hasSize;

  @Double()
  external double width;

  @Double()
  external double height;

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

  void set(WindowSizing sizing) {
    final Size? size = sizing.preferredSize;
    if (size != null) {
      hasSize = true;
      width = size.width;
      height = size.height;
    } else {
      hasSize = false;
    }

    final BoxConstraints? constraints = sizing.constraints;
    if (constraints != null) {
      hasConstraints = true;
      minWidth = constraints.minWidth;
      minHeight = constraints.minHeight;
      maxWidth = constraints.maxWidth;
      maxHeight = constraints.maxHeight;
    } else {
      hasConstraints = false;
    }
  }
}

final class _WindowCreationRequest extends Struct {
  external _Sizing contentSize;

  external Pointer<NativeFunction<Void Function()>> onClose;
  external Pointer<NativeFunction<Void Function()>> onSizeChange;
}

final class _Size extends Struct {
  @Double()
  external double width;

  @Double()
  external double height;
}
