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

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:ui' show Display, FlutterView;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../foundation/_features.dart';
import '_window.dart';
import 'binding.dart';

// Maximum width and height a window can be.
// In C this would be INT_MAX, but since we can't determine that from Dart let's assume it's 32 bit signed. In any case this is far beyond any reasonable window size.
const _kMaxWindowDimensions = 0x7fffffff;

const String _kWindowingDisabledErrorMessage = '''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

@ffi.Native<ffi.Pointer Function(ffi.Int)>(symbol: 'g_malloc0')
external ffi.Pointer _gMalloc0(int count);

@ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'g_free')
external void _gFree(ffi.Pointer value);

ffi.Pointer<ffi.Uint8> _stringToNative(String value) {
  final units = utf8.encode(value);
  final buffer = _gMalloc0(units.length + 1).cast<ffi.Uint8>();
  final nativeString = buffer.asTypedList(units.length + 1);
  nativeString.setAll(0, units);
  nativeString[units.length] = 0;
  return buffer;
}

String _nativeToString(ffi.Pointer<ffi.Uint8> value) {
  var length = 0;
  while (value[length] != 0) {
    length++;
  }
  return utf8.decode(value.asTypedList(length));
}

typedef _GCallback = ffi.Void Function();

class _GObject {
  final ffi.Pointer instance;

  const _GObject(this.instance);

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'g_object_unref')
  external static void _unref(ffi.Pointer widget);
  void unref() {
    _unref(instance);
  }
}

class _GtkWidget extends _GObject {
  const _GtkWidget(ffi.Pointer instance) : super(instance);

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_widget_show')
  external static void _gtkWidgetShow(ffi.Pointer widget);
  void show() {
    _gtkWidgetShow(instance);
  }

  @ffi.Native<ffi.Bool Function(ffi.Pointer)>(symbol: 'gtk_widget_get_visible')
  external static bool _gtkWidgetGetVisible(ffi.Pointer widget);
  bool getVisible() {
    return _gtkWidgetGetVisible(instance);
  }

  @ffi.Native<ffi.Pointer Function(ffi.Pointer)>(symbol: 'gtk_widget_get_window')
  external static ffi.Pointer _gtkWidgetGetWindow(ffi.Pointer widget);
  _GdkWindow getWindow() {
    return _GdkWindow(_gtkWidgetGetWindow(instance));
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_widget_destroy')
  external static void _gtkWindowDestroy(ffi.Pointer widget);
  void destroy() {
    _gtkWindowDestroy(instance);
  }
}

class _GdkWindow extends _GObject {
  const _GdkWindow(ffi.Pointer instance) : super(instance);

  @ffi.Native<ffi.Int Function(ffi.Pointer)>(symbol: 'gdk_window_get_state')
  external static int _gdkWindowGetState(ffi.Pointer window);
  int getState() {
    return _gdkWindowGetState(instance);
  }
}

final class _GdkGeometry extends ffi.Struct {
  @ffi.Int()
  external int min_width;

  @ffi.Int()
  external int min_height;

  @ffi.Int()
  external int max_width;

  @ffi.Int()
  external int max_height;

  @ffi.Int()
  external int base_width;

  @ffi.Int()
  external int base_height;

  @ffi.Int()
  external int width_inc;

  @ffi.Int()
  external int height_inc;

  @ffi.Double()
  external double min_aspect;

  @ffi.Double()
  external double max_aspect;

  @ffi.Int()
  external int win_gravity;

  factory _GdkGeometry() {
    return ffi.Struct.create();
  }
}

const int _GDK_WINDOW_STATE_ICONIFIED = 1 << 1;
const int _GDK_WINDOW_STATE_MAXIMIZED = 1 << 2;
const int _GDK_WINDOW_STATE_FULLSCREEN = 1 << 4;

class _GtkWindow extends _GtkWidget {
  @ffi.Native<ffi.Pointer Function(ffi.Int)>(symbol: 'gtk_window_new')
  external static ffi.Pointer _gtkWindowNew(int type);

  _GtkWindow() : super(_gtkWindowNew(0));

  @ffi.Native<ffi.Void Function(ffi.Pointer, ffi.Pointer)>(symbol: 'gtk_container_add')
  external static void _gtkContainerAdd(ffi.Pointer container, ffi.Pointer child);
  void add(_GtkWidget child) {
    _gtkContainerAdd(instance, child.instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_window_present')
  external static void _gtkWindowPresent(ffi.Pointer window);
  void present() {
    _gtkWindowPresent(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer, ffi.Pointer<ffi.Uint8>)>(
    symbol: 'gtk_window_set_title',
  )
  external static void _gtkWindowSetTitle(ffi.Pointer window, ffi.Pointer<ffi.Uint8> title);
  void setTitle(String title) {
    final titleBuffer = _stringToNative(title);
    _gtkWindowSetTitle(instance, titleBuffer);
    _gFree(titleBuffer);
  }

  @ffi.Native<ffi.Pointer<ffi.Uint8> Function(ffi.Pointer)>(symbol: 'gtk_window_get_title')
  external static ffi.Pointer<ffi.Uint8> _gtkWindowGetTitle(ffi.Pointer window);
  String getTitle() {
    return _nativeToString(_gtkWindowGetTitle(instance));
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer, ffi.Int, ffi.Int)>(
    symbol: 'gtk_window_set_default_size',
  )
  external static void _gtkWindowSetDefaultSize(ffi.Pointer window, int width, int height);
  void setDefaultSize(int width, int height) {
    _gtkWindowSetDefaultSize(instance, width, height);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer, ffi.Pointer, ffi.Pointer<_GdkGeometry>, ffi.Int)>(
    symbol: 'gtk_window_set_geometry_hints',
  )
  external static void _gtkWindowSetGeometryHints(
    ffi.Pointer window,
    ffi.Pointer geometryWidget,
    ffi.Pointer<_GdkGeometry> geometry,
    int geometryMask,
  );
  void setGeometryHints({int? minWidth, int? minHeight, int? maxWidth, int? maxHeight}) {
    final geometry = _gMalloc0(ffi.sizeOf<_GdkGeometry>()).cast<_GdkGeometry>();
    final g = geometry.ref;
    int geometryMask = 0;
    if (minWidth != null || minHeight != null) {
      g.min_width = minWidth ?? 0;
      g.min_height = minHeight ?? 0;
      geometryMask |= 2; // GDK_HINT_MIN_SIZE
    }
    if (maxWidth != null || maxHeight != null) {
      g.max_width = maxWidth ?? _kMaxWindowDimensions;
      g.max_height = maxHeight ?? _kMaxWindowDimensions;
      geometryMask |= 4; // GDK_HINT_MAX_SIZE
    }
    _gtkWindowSetGeometryHints(instance, ffi.nullptr, geometry, geometryMask);
    _gFree(geometry);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer, ffi.Int, ffi.Int)>(symbol: 'gtk_window_resize')
  external static void _gtkWindowResize(ffi.Pointer window, int width, int height);
  void resize(int width, int height) {
    _gtkWindowResize(instance, width, height);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_window_maximize')
  external static void _gtkWindowMaximize(ffi.Pointer window);
  void maximize() {
    _gtkWindowMaximize(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_window_unmaximize')
  external static void _gtkWindowUnmaximize(ffi.Pointer window);
  void unmaximize() {
    _gtkWindowUnmaximize(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_window_iconify')
  external static void _gtkWindowIconify(ffi.Pointer window);
  void iconify() {
    _gtkWindowIconify(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_window_deiconify')
  external static void _gtkWindowDeiconify(ffi.Pointer window);
  void deiconify() {
    _gtkWindowDeiconify(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_window_fullscreen')
  external static void _gtkWindowFullscreen(ffi.Pointer window);
  void fullscreen() {
    _gtkWindowFullscreen(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer)>(symbol: 'gtk_window_unfullscreen')
  external static void _gtkWindowUnfullscreen(ffi.Pointer window);
  void unfullscreen() {
    _gtkWindowUnfullscreen(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer, ffi.Pointer<ffi.Int>, ffi.Pointer<ffi.Int>)>(
    symbol: 'gtk_window_get_size',
  )
  external static void _gtkWindowGetSize(
    ffi.Pointer window,
    ffi.Pointer<ffi.Int> width,
    ffi.Pointer<ffi.Int> height,
  );
  Size getSize() {
    final width = _gMalloc0(ffi.sizeOf<ffi.Int>()).cast<ffi.Int>();
    final height = _gMalloc0(ffi.sizeOf<ffi.Int>()).cast<ffi.Int>();
    _gtkWindowGetSize(instance, width, height);
    final result = Size(width.value.toDouble(), height.value.toDouble());
    _gFree(width);
    _gFree(height);
    return result;
  }
}

class _FlView extends _GtkWidget {
  @ffi.Native<ffi.Pointer Function(ffi.Pointer)>(symbol: 'fl_view_new_for_engine')
  external static ffi.Pointer _flViewNewForEngine(ffi.Pointer engine);

  _FlView()
    : super(_flViewNewForEngine(ffi.Pointer.fromAddress(PlatformDispatcher.instance.engineId!)));

  @ffi.Native<ffi.Int64 Function(ffi.Pointer)>(symbol: 'fl_view_get_id')
  external static int _flViewGetId(ffi.Pointer view);
  int getId() {
    return _flViewGetId(instance);
  }
}

class _FlWindowMonitor extends _GObject {
  final ffi.NativeCallable<ffi.Void Function()> _onConfigureFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onStateChangedFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onCloseFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onDestroyFunction;

  @ffi.Native<
    ffi.Pointer Function(ffi.Pointer, ffi.Pointer, ffi.Pointer, ffi.Pointer, ffi.Pointer)
  >(symbol: 'fl_window_monitor_new')
  external static ffi.Pointer _flWindowMonitorNew(
    ffi.Pointer window,
    ffi.Pointer onConfigure,
    ffi.Pointer onStateChanged,
    ffi.Pointer onClose,
    ffi.Pointer onDestroy,
  );

  factory _FlWindowMonitor(
    _GtkWindow window,
    Function() onConfigure,
    Function() onStateChanged,
    Function() onClose,
    Function() onDestroy,
  ) {
    return _FlWindowMonitor._internal(
      window.instance,
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onConfigure),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onStateChanged),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onClose),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onDestroy),
    );
  }

  _FlWindowMonitor._internal(
    ffi.Pointer window,
    this._onConfigureFunction,
    this._onStateChangedFunction,
    this._onCloseFunction,
    this._onDestroyFunction,
  ) : super(
        _flWindowMonitorNew(
          window,
          _onConfigureFunction.nativeFunction,
          _onStateChangedFunction.nativeFunction,
          _onCloseFunction.nativeFunction,
          _onDestroyFunction.nativeFunction,
        ),
      );

  void close() {
    _onConfigureFunction.close();
    _onStateChangedFunction.close();
    _onCloseFunction.close();
    _onDestroyFunction.close();
  }
}

/// [WindowingOwner] implementation for Linux.
///
/// If [Platform.isLinux] is false, then the constructor will throw an
/// [UnsupportedError].
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowingOwner], the abstract class that manages native windows.
@internal
class WindowingOwnerLinux extends WindowingOwner {
  /// Creates a new [WindowingOwnerLinux] instance.
  ///
  /// If [Platform.isLinux] is false, then this constructor will throw an
  /// [UnsupportedError]
  ///
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [WindowingOwner], the abstract class that manages native windows.
  @internal
  WindowingOwnerLinux() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    if (!Platform.isLinux) {
      throw UnsupportedError('Only available on the Linux platform');
    }

    assert(
      PlatformDispatcher.instance.engineId != null,
      'WindowingOwnerLinux must be created after the engine has been initialized.',
    );
  }

  @internal
  @override
  RegularWindowController createRegularWindowController({
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    required RegularWindowControllerDelegate delegate,
  }) {
    return RegularWindowControllerLinux(
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
    throw UnimplementedError('Dialog windows are not yet implemented on Linux.');
  }

  @internal
  @override
  bool hasTopLevelWindows() {
    // FIXME(robert-ancell):
    return false;
  }
}

/// Implementation of [RegularWindowController] for the Linux platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [RegularWindowController], the base class for regular windows.
class RegularWindowControllerLinux extends RegularWindowController {
  final RegularWindowControllerDelegate _delegate;
  final _GtkWindow _window;
  late final _FlWindowMonitor _windowMonitor; // FIXME: unref and close

  /// Creates a new regular window controller for Linux.
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
  RegularWindowControllerLinux({
    required RegularWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  }) : _delegate = delegate,
       _window = _GtkWindow(),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windowMonitor = _FlWindowMonitor(
      _window,
      // onConfigure
      () {
        notifyListeners();
      },
      // onStateChanged
      () {
        notifyListeners();
      },
      // onClose
      () {
        _delegate.onWindowCloseRequested(this);
      },
      // onDestroy
      () {
        _delegate.onWindowDestroyed();
      },
    );
    if (preferredSize != null) {
      _window.setDefaultSize(preferredSize.width.toInt(), preferredSize.height.toInt());
    }
    if (preferredConstraints != null) {
      setConstraints(preferredConstraints);
    }
    if (title != null) {
      setTitle(title);
    }
    final view = _FlView();
    final viewId = view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    view.show();
    _window.add(view);
    _window.present();
  }

  @override
  @internal
  Size get contentSize => _window.getSize();

  @override
  void destroy() {
    _window.destroy();
  }

  @override
  @internal
  String get title => _window.getTitle();

  @override
  @internal
  bool get isActivated => _window.getVisible();

  @override
  @internal
  bool get isMaximized => (_window.getWindow().getState() & _GDK_WINDOW_STATE_MAXIMIZED) != 0;

  @override
  @internal
  // NOTE: On Wayland this is never set, see https://gitlab.gnome.org/GNOME/gtk/-/issues/67
  bool get isMinimized => (_window.getWindow().getState() & _GDK_WINDOW_STATE_ICONIFIED) != 0;

  @override
  @internal
  bool get isFullscreen => (_window.getWindow().getState() & _GDK_WINDOW_STATE_FULLSCREEN) != 0;

  @override
  @internal
  void setSize(Size size) {
    _window.resize(size.width.toInt(), size.height.toInt());
  }

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    _window.setGeometryHints(
      minWidth: constraints.minWidth.toInt(),
      minHeight: constraints.minHeight.toInt(),
      maxWidth: constraints.maxWidth.isInfinite ? 0x7fffffff : constraints.maxWidth.toInt(),
      maxHeight: constraints.maxHeight.isInfinite ? 0x7fffffff : constraints.maxHeight.toInt(),
    );
  }

  @override
  @internal
  void setTitle(String title) {
    _window.setTitle(title);
    notifyListeners();
  }

  @override
  @internal
  void activate() {
    _window.present();
  }

  @override
  @internal
  void setMaximized(bool maximized) {
    if (maximized) {
      _window.maximize();
    } else {
      _window.unmaximize();
    }
  }

  @override
  @internal
  void setMinimized(bool minimized) {
    if (minimized) {
      _window.iconify();
    } else {
      _window.deiconify();
    }
  }

  @override
  @internal
  void setFullscreen(bool fullscreen, {Display? display}) {
    // FIXME(robert-ancell): display currently ignored
    if (fullscreen) {
      _window.fullscreen();
    } else {
      _window.unfullscreen();
    }
  }
}
