// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:ffi' hide Size;
import 'dart:io';
import 'dart:ui' show Display, FlutterView;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../foundation/_features.dart';
import '_window.dart';
import '_window_positioner.dart';
import 'binding.dart';

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

const String _kWindowingDisabledErrorMessage = '''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

/// [WindowingOwner] implementation for macOS.
///
/// If [Platform.isMacOS] is false, then the constructor will throw an
/// [UnsupportedError].
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowingOwner], the abstract class that manages native windows.
class WindowingOwnerMacOS extends WindowingOwner {
  /// Creates a new [WindowingOwnerMacOS] instance.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [WindowingOwner], the abstract class that manages native windows.
  @internal
  WindowingOwnerMacOS() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    if (!Platform.isMacOS) {
      throw UnsupportedError('Only available on the macOS platform');
    }

    assert(
      WidgetsBinding.instance.platformDispatcher.engineId != null,
      'WindowingOwnerMacOS must be created after the engine has been initialized.',
    );
  }

  @override
  RegularWindowController createRegularWindowController({
    required RegularWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  }) {
    final res = RegularWindowControllerMacOS(
      owner: this,
      delegate: delegate,
      preferredSize: preferredSize,
      title: title,
    );
    _activeControllers.add(res);
    return res;
  }

  @override
  DialogWindowController createDialogWindowController({
    required DialogWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    BaseWindowController? parent,
    String? title,
  }) {
    final res = DialogWindowControllerMacOS(
      owner: this,
      delegate: delegate,
      preferredSize: preferredSize,
      parent: parent,
      title: title,
    );
    _activeControllers.add(res);
    return res;
  }

  @internal
  @override
  TooltipWindowController createTooltipWindowController({
    required TooltipWindowControllerDelegate delegate,
    required BoxConstraints preferredConstraints,
    required bool isSizedToContent,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) {
    throw UnimplementedError('Tooltip windows are not yet implemented on MacOS.');
  }

  @internal
  @override
  PopupWindowController createPopupWindowController({
    required PopupWindowControllerDelegate delegate,
    required BoxConstraints preferredConstraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) {
    throw UnimplementedError('Popup windows are not yet implemented on MacOS.');
  }

  final List<BaseWindowController> _activeControllers = <BaseWindowController>[];

  /// Returns the window handle for the given [view], or null is the window
  /// handle is not available.
  ///
  /// The window handle is a pointer to the NSWindow instance.
  static Pointer<Void> getWindowHandle(FlutterView view) {
    return _MacOSPlatformInterface.getWindowHandle(
      WidgetsBinding.instance.platformDispatcher.engineId!,
      view.viewId,
    );
  }
}

/// Implementation of [RegularWindowController] for the macOS platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [RegularWindowController], the base class for regular windows.
class RegularWindowControllerMacOS extends RegularWindowController {
  /// Creates a new regular window controller for macOS. When this constructor
  /// completes the FlutterView is created and framework is aware of it.
  RegularWindowControllerMacOS({
    required WindowingOwnerMacOS owner,
    required RegularWindowControllerDelegate delegate,
    required Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  }) : _owner = owner,
       _delegate = delegate,
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _onShouldClose = NativeCallable<Void Function()>.isolateLocal(_handleOnShouldClose);
    _onWillClose = NativeCallable<Void Function()>.isolateLocal(_handleOnWillClose);
    _onResize = NativeCallable<Void Function()>.isolateLocal(_handleOnResize);
    final int viewId = _MacOSPlatformInterface.createRegularWindow(
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      onShouldClose: _onShouldClose.nativeFunction,
      onWillClose: _onWillClose.nativeFunction,
      onNotifyListeners: _onResize.nativeFunction,
    );
    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    rootView = flutterView;
    if (title != null) {
      setTitle(title);
    }
  }

  /// Returns window handle for the current window.
  ///
  /// The handle is a pointer to an NSWindow instance.
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
    _MacOSPlatformInterface.destroyWindow(handle);
  }

  void _handleOnShouldClose() {
    _delegate.onWindowCloseRequested(this);
  }

  void _handleOnWillClose() {
    _destroyed = true;
    _owner._activeControllers.remove(this);
    _delegate.onWindowDestroyed();
    _onShouldClose.close();
    _onWillClose.close();
    _onResize.close();
  }

  void _handleOnResize() {
    notifyListeners();
  }

  @override
  @internal
  void setSize(Size size) {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.setWindowContentSize(getWindowHandle(), size);
  }

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.setWindowConstraints(getWindowHandle(), constraints);
  }

  @override
  void setTitle(String title) {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.setWindowTitle(getWindowHandle(), title);
    notifyListeners();
  }

  final WindowingOwnerMacOS _owner;
  final RegularWindowControllerDelegate _delegate;
  late final NativeCallable<Void Function()> _onShouldClose;
  late final NativeCallable<Void Function()> _onWillClose;
  late final NativeCallable<Void Function()> _onResize;

  @override
  Size get contentSize {
    _ensureNotDestroyed();
    return _MacOSPlatformInterface.getWindowContentSize(getWindowHandle());
  }

  @override
  void activate() {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.activate(getWindowHandle());
  }

  @override
  void setMaximized(bool maximized) {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.setMaximized(getWindowHandle(), maximized);
  }

  @override
  bool get isMaximized {
    _ensureNotDestroyed();
    return _MacOSPlatformInterface.isMaximized(getWindowHandle());
  }

  @override
  void setMinimized(bool minimized) {
    _ensureNotDestroyed();
    if (minimized) {
      _MacOSPlatformInterface.minimize(getWindowHandle());
    } else {
      _MacOSPlatformInterface.unminimize(getWindowHandle());
    }
  }

  @override
  bool get isMinimized {
    _ensureNotDestroyed();
    return _MacOSPlatformInterface.isMinimized(getWindowHandle());
  }

  @override
  void setFullscreen(bool fullscreen, {Display? display}) {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.setFullscreen(getWindowHandle(), fullscreen);
  }

  @override
  bool get isFullscreen {
    _ensureNotDestroyed();
    return _MacOSPlatformInterface.isFullscreen(getWindowHandle());
  }

  void _ensureNotDestroyed() {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
  }

  @override
  bool get isActivated => _MacOSPlatformInterface.isActivated(getWindowHandle());

  @override
  String get title => _MacOSPlatformInterface.getTitle(getWindowHandle());
}

/// Implementation of [DialogWindowController] for the macOS platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [DialogWindowController], the base class for dialog windows.
class DialogWindowControllerMacOS extends DialogWindowController {
  /// Creates a new regular window controller for macOS. When this constructor
  /// completes the FlutterView is created and framework is aware of it.
  DialogWindowControllerMacOS({
    required WindowingOwnerMacOS owner,
    required DialogWindowControllerDelegate delegate,
    required Size? preferredSize,
    this.parent,
    BoxConstraints? preferredConstraints,
    String? title,
  }) : _owner = owner,
       _delegate = delegate,
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _onShouldClose = NativeCallable<Void Function()>.isolateLocal(_handleOnShouldClose);
    _onWillClose = NativeCallable<Void Function()>.isolateLocal(_handleOnWillClose);
    _onResize = NativeCallable<Void Function()>.isolateLocal(_handleOnResize);
    final int viewId = _MacOSPlatformInterface.createDialogWindow(
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      onShouldClose: _onShouldClose.nativeFunction,
      onWillClose: _onWillClose.nativeFunction,
      onNotifyListeners: _onResize.nativeFunction,
      parentViewId: parent?.rootView.viewId,
    );
    final FlutterView flutterView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    rootView = flutterView;
    if (title != null) {
      setTitle(title);
    }
  }

  /// Returns the window handle for this window.
  ///
  /// The handle is a pointer to an `NSWindow` instance.
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
    _MacOSPlatformInterface.destroyWindow(handle);
  }

  void _handleOnShouldClose() {
    _delegate.onWindowCloseRequested(this);
  }

  void _handleOnWillClose() {
    _destroyed = true;
    _owner._activeControllers.remove(this);
    _delegate.onWindowDestroyed();
    _onShouldClose.close();
    _onWillClose.close();
    _onResize.close();
  }

  void _handleOnResize() {
    notifyListeners();
  }

  @override
  @internal
  void setSize(Size size) {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.setWindowContentSize(getWindowHandle(), size);
  }

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.setWindowConstraints(getWindowHandle(), constraints);
  }

  @override
  void setTitle(String title) {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.setWindowTitle(getWindowHandle(), title);
    notifyListeners();
  }

  final WindowingOwnerMacOS _owner;
  final DialogWindowControllerDelegate _delegate;
  late final NativeCallable<Void Function()> _onShouldClose;
  late final NativeCallable<Void Function()> _onWillClose;
  late final NativeCallable<Void Function()> _onResize;

  @override
  Size get contentSize {
    _ensureNotDestroyed();
    return _MacOSPlatformInterface.getWindowContentSize(getWindowHandle());
  }

  @override
  void activate() {
    _ensureNotDestroyed();
    _MacOSPlatformInterface.activate(getWindowHandle());
  }

  @override
  void setMinimized(bool minimized) {
    _ensureNotDestroyed();
    if (minimized) {
      _MacOSPlatformInterface.minimize(getWindowHandle());
    } else {
      _MacOSPlatformInterface.unminimize(getWindowHandle());
    }
  }

  @override
  bool get isMinimized {
    _ensureNotDestroyed();
    return _MacOSPlatformInterface.isMinimized(getWindowHandle());
  }

  void _ensureNotDestroyed() {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
  }

  @override
  bool get isActivated => _MacOSPlatformInterface.isActivated(getWindowHandle());

  @override
  String get title => _MacOSPlatformInterface.getTitle(getWindowHandle());

  @override
  final BaseWindowController? parent;
}

final class _WindowCreationRequest extends Struct {
  @Bool()
  external bool hasSize;
  external _Size contentSize;

  @Bool()
  external bool hasConstraints;
  external _Constraints constraints;

  @Int64()
  external int parentViewId;

  external Pointer<NativeFunction<Void Function()>> onShouldClose;
  external Pointer<NativeFunction<Void Function()>> onWillClose;
  external Pointer<NativeFunction<Void Function()>> onNotifyListeners;
}

final class _Size extends Struct {
  @Double()
  external double width;

  @Double()
  external double height;
}

final class _Constraints extends Struct {
  @Double()
  external double minWidth;

  @Double()
  external double minHeight;

  @Double()
  external double maxWidth;

  @Double()
  external double maxHeight;
}

class _MacOSPlatformInterface {
  @Native<Pointer<Void> Function(Int64, Int64)>(symbol: 'InternalFlutter_Window_GetHandle')
  external static Pointer<Void> getWindowHandle(int engineId, int viewId);

  @Native<Void Function(Pointer<Void>, Pointer<_Size>)>(
    symbol: 'InternalFlutter_Window_SetContentSize',
  )
  external static void _setWindowContentSize(Pointer<Void> windowHandle, Pointer<_Size> size);

  static void setWindowContentSize(Pointer<Void> windowHandle, Size size) {
    final Pointer<_Size> ffiSize = _allocator<_Size>();
    ffiSize.ref
      ..width = size.width
      ..height = size.height;
    _setWindowContentSize(windowHandle, ffiSize);
    _allocator.free(ffiSize);
  }

  @Native<Void Function(Pointer<Void>, Pointer<_Constraints>)>(
    symbol: 'InternalFlutter_Window_SetConstraints',
  )
  external static void _setWindowConstraints(
    Pointer<Void> windowHandle,
    Pointer<_Constraints> size,
  );

  static void setWindowConstraints(Pointer<Void> windowHandle, BoxConstraints constraints) {
    final Pointer<_Constraints> ffiConstraints = _allocator<_Constraints>();
    ffiConstraints.ref
      ..minWidth = constraints.minWidth
      ..minHeight = constraints.minHeight
      ..maxWidth = constraints.maxWidth
      ..maxHeight = constraints.maxHeight;

    _setWindowConstraints(windowHandle, ffiConstraints);
    _allocator.free(ffiConstraints);
  }

  @Native<Int64 Function(Int64, Pointer<_WindowCreationRequest>)>(
    symbol: 'InternalFlutter_WindowController_CreateRegularWindow',
  )
  external static int _createRegularWindow(int engineId, Pointer<_WindowCreationRequest> request);

  /// Creates a new window and returns the viewId of the created FlutterView.
  static int createRegularWindow({
    required Size? preferredSize,
    BoxConstraints? preferredConstraints,
    required Pointer<NativeFunction<Void Function()>> onShouldClose,
    required Pointer<NativeFunction<Void Function()>> onWillClose,
    required Pointer<NativeFunction<Void Function()>> onNotifyListeners,
  }) {
    final Pointer<_WindowCreationRequest> request = _allocator<_WindowCreationRequest>()
      ..ref.onShouldClose = onShouldClose
      ..ref.onWillClose = onWillClose
      ..ref.onNotifyListeners = onNotifyListeners;

    if (preferredSize != null) {
      request.ref
        ..hasSize = true
        ..contentSize.width = preferredSize.width
        ..contentSize.height = preferredSize.height;
    }

    if (preferredConstraints != null) {
      request.ref
        ..hasConstraints = true
        ..constraints.minWidth = preferredConstraints.minWidth
        ..constraints.minHeight = preferredConstraints.minHeight
        ..constraints.maxWidth = preferredConstraints.maxWidth
        ..constraints.maxHeight = preferredConstraints.maxHeight;
    }
    final int viewId = _createRegularWindow(
      WidgetsBinding.instance.platformDispatcher.engineId!,
      request,
    );
    _allocator.free(request);
    return viewId;
  }

  @Native<Int64 Function(Int64, Pointer<_WindowCreationRequest>)>(
    symbol: 'InternalFlutter_WindowController_CreateDialogWindow',
  )
  external static int _createDialogWindow(int engineId, Pointer<_WindowCreationRequest> request);

  /// Creates a new window and returns the viewId of the created FlutterView.
  static int createDialogWindow({
    required Size? preferredSize,
    BoxConstraints? preferredConstraints,
    int? parentViewId,
    required Pointer<NativeFunction<Void Function()>> onShouldClose,
    required Pointer<NativeFunction<Void Function()>> onWillClose,
    required Pointer<NativeFunction<Void Function()>> onNotifyListeners,
  }) {
    final Pointer<_WindowCreationRequest> request = _allocator<_WindowCreationRequest>()
      ..ref.onShouldClose = onShouldClose
      ..ref.onWillClose = onWillClose
      ..ref.onNotifyListeners = onNotifyListeners
      ..ref.parentViewId = parentViewId ?? 0;

    if (preferredSize != null) {
      request.ref
        ..hasSize = true
        ..contentSize.width = preferredSize.width
        ..contentSize.height = preferredSize.height;
    }

    if (preferredConstraints != null) {
      request.ref
        ..hasConstraints = true
        ..constraints.minWidth = preferredConstraints.minWidth
        ..constraints.minHeight = preferredConstraints.minHeight
        ..constraints.maxWidth = preferredConstraints.maxWidth
        ..constraints.maxHeight = preferredConstraints.maxHeight;
    }
    try {
      final int viewId = _createDialogWindow(
        WidgetsBinding.instance.platformDispatcher.engineId!,
        request,
      );
      return viewId;
    } finally {
      _allocator.free(request);
    }
  }

  @Native<Void Function(Int64, Pointer<Void>)>(symbol: 'InternalFlutter_Window_Destroy')
  external static void _destroyWindow(int engineId, Pointer<Void> handle);

  static void destroyWindow(Pointer<Void> windowHandle) {
    _destroyWindow(WidgetsBinding.instance.platformDispatcher.engineId!, windowHandle);
  }

  @Native<_Size Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_GetContentSize')
  external static _Size _getWindowContentSize(Pointer<Void> windowHandle);

  static Size getWindowContentSize(Pointer<Void> windowHandle) {
    final _Size size = _getWindowContentSize(windowHandle);
    return Size(size.width, size.height);
  }

  @Native<Void Function(Pointer<Void>, Pointer<_Utf8>)>(symbol: 'InternalFlutter_Window_SetTitle')
  external static void _setWindowTitle(Pointer<Void> windowHandle, Pointer<_Utf8> title);

  static void setWindowTitle(Pointer<Void> windowHandle, String title) {
    final Pointer<_Utf8> titlePointer = title.toNativeUtf8();
    _setWindowTitle(windowHandle, titlePointer);
    _allocator.free(titlePointer);
  }

  @Native<Void Function(Pointer<Void>, Bool)>(symbol: 'InternalFlutter_Window_SetMaximized')
  external static void setMaximized(Pointer<Void> windowHandle, bool maximized);

  @Native<Bool Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_IsMaximized')
  external static bool isMaximized(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_Minimize')
  external static void minimize(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_Unminimize')
  external static void unminimize(Pointer<Void> windowHandle);

  @Native<Bool Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_IsMinimized')
  external static bool isMinimized(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>, Bool)>(symbol: 'InternalFlutter_Window_SetFullScreen')
  external static void setFullscreen(Pointer<Void> windowHandle, bool fullscreen);

  @Native<Bool Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_IsFullScreen')
  external static bool isFullscreen(Pointer<Void> windowHandle);

  @Native<Void Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_Activate')
  external static void activate(Pointer<Void> windowHandle);

  @Native<Pointer<_Utf8> Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_GetTitle')
  external static Pointer<_Utf8> _getTitle(Pointer<Void> windowHandle);

  static String getTitle(Pointer<Void> windowHandle) {
    final Pointer<_Utf8> title = _getTitle(windowHandle);
    final String result = title.toDartString();
    _allocator.free(title);
    return result;
  }

  @Native<Bool Function(Pointer<Void>)>(symbol: 'InternalFlutter_Window_IsActivated')
  external static bool isActivated(Pointer<Void> windowHandle);
}

// FFI utilities.

typedef _PosixCallocNative = Pointer<Void> Function(IntPtr num, IntPtr size);

@Native<_PosixCallocNative>(symbol: 'calloc')
external Pointer<Void> _posixCalloc(int num, int size);

typedef _PosixFreeNative = Void Function(Pointer<NativeType>);

@Native<Void Function(Pointer<NativeType>)>(symbol: 'free')
external void _posixFree(Pointer<NativeType> ptr);

final Pointer<NativeFunction<_PosixFreeNative>> _posixFreePointer =
    Native.addressOf<NativeFunction<_PosixFreeNative>>(_posixFree);

const _CallocAllocator _allocator = _CallocAllocator._();

final class _CallocAllocator implements Allocator {
  const _CallocAllocator._();

  /// Allocates [byteCount] bytes of zero-initialized of memory on the native
  /// heap.
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    final Pointer<T> result = _posixCalloc(byteCount, 1).cast();

    if (result.address == 0) {
      throw ArgumentError('Could not allocate $byteCount bytes.');
    }
    return result;
  }

  /// Releases memory allocated on the native heap.
  @override
  void free(Pointer<NativeType> pointer) {
    _posixFree(pointer);
  }

  /// Returns a pointer to a native free function.
  Pointer<NativeFinalizerFunction> get nativeFree => _posixFreePointer;
}

/// The contents of a native zero-terminated array of UTF-8 code units.
///
/// The Utf8 type itself has no functionality, it's only intended to be used
/// through a `Pointer<Utf8>` representing the entire array. This pointer is
/// the equivalent of a char pointer (`const char*`) in C code.
final class _Utf8 extends Opaque {}

/// Extension method for converting a`Pointer<Utf8>` to a [String].
extension _Utf8Pointer on Pointer<_Utf8> {
  /// Converts this UTF-8 encoded string to a Dart string.
  ///
  /// Decodes the UTF-8 code units of this zero-terminated byte array as
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
    final Pointer<Uint8> codeUnits = cast<Uint8>();
    if (length != null) {
      RangeError.checkNotNegative(length, 'length');
    } else {
      length = _length(codeUnits);
    }
    return utf8.decode(codeUnits.asTypedList(length));
  }

  static int _length(Pointer<Uint8> codeUnits) {
    var length = 0;
    while (codeUnits[length] != 0) {
      length++;
    }
    return length;
  }

  void _ensureNotNullptr(String operation) {
    if (this == nullptr) {
      throw UnsupportedError("Operation '$operation' not allowed on a 'nullptr'.");
    }
  }
}

/// Extension method for converting a [String] to a `Pointer<Utf8>`.
extension _StringUtf8Pointer on String {
  /// Creates a zero-terminated [_Utf8] code-unit array from this String.
  ///
  /// If this [String] contains NUL characters, converting it back to a string
  /// using [_Utf8Pointer.toDartString] will truncate the result if a length is
  /// not passed.
  ///
  /// Unpaired surrogate code points in this [String] will be encoded as
  /// replacement characters (U+FFFD, encoded as the bytes 0xEF 0xBF 0xBD) in
  /// the UTF-8 encoded result. See [Utf8Encoder] for details on encoding.
  ///
  /// Returns an [allocator]-allocated pointer to the result.
  Pointer<_Utf8> toNativeUtf8({Allocator allocator = _allocator}) {
    final Uint8List units = utf8.encode(this);
    final Pointer<Uint8> result = allocator<Uint8>(units.length + 1);
    final Uint8List nativeString = result.asTypedList(units.length + 1);
    nativeString.setAll(0, units);
    nativeString[units.length] = 0;
    return result.cast();
  }
}
