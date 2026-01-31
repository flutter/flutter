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
import '_window_positioner.dart';
import 'binding.dart';

// Maximum width and height a window can be.
// In C this would be INT_MAX, but since we can't determine that from Dart let's assume it's 32 bit signed. In any case this is far beyond any reasonable window size.
const int _kMaxWindowDimensions = 0x7fffffff;

const String _kWindowingDisabledErrorMessage = '''
Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';

@ffi.Native<ffi.Pointer<ffi.NativeType> Function(ffi.Int)>(symbol: 'g_malloc0')
external ffi.Pointer<ffi.NativeType> _gMalloc0(int count);

@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'g_free')
external void _gFree(ffi.Pointer<ffi.NativeType> value);

ffi.Pointer<ffi.Uint8> _stringToNative(String value) {
  final Uint8List units = utf8.encode(value);
  final ffi.Pointer<ffi.Uint8> buffer = _gMalloc0(units.length + 1).cast<ffi.Uint8>();
  final Uint8List nativeString = buffer.asTypedList(units.length + 1);
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

/// Wraps GObject
class _GObject {
  const _GObject(this.instance);

  final ffi.Pointer<ffi.NativeType> instance;

  /// Drop reference to this object.
  void unref() {
    _unref(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'g_object_unref')
  external static void _unref(ffi.Pointer<ffi.NativeType> widget);
}

/// Wraps GtkContainer
class _GtkContainer extends _GtkWidget {
  const _GtkContainer(super.instance);

  /// Adds [child] widget to this container.
  void add(_GtkWidget child) {
    _gtkContainerAdd(instance, child.instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Pointer<ffi.NativeType>)>(
    symbol: 'gtk_container_add',
  )
  external static void _gtkContainerAdd(
    ffi.Pointer<ffi.NativeType> container,
    ffi.Pointer<ffi.NativeType> child,
  );
}

/// Wraps GtkWidget
class _GtkWidget extends _GObject {
  const _GtkWidget(super.instance);

  /// Show the widget (defaults to hidden).
  void show() {
    _gtkWidgetShow(instance);
  }

  /// Get the low level window backing this widget.
  _GdkWindow getWindow() {
    return _GdkWindow(_gtkWidgetGetWindow(instance));
  }

  /// Destroy the widget.
  void destroy() {
    _gtkWindowDestroy(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_show')
  external static void _gtkWidgetShow(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Pointer<ffi.NativeType> Function(ffi.Pointer<ffi.NativeType>)>(
    symbol: 'gtk_widget_get_window',
  )
  external static ffi.Pointer<ffi.NativeType> _gtkWidgetGetWindow(
    ffi.Pointer<ffi.NativeType> widget,
  );

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_destroy')
  external static void _gtkWindowDestroy(ffi.Pointer<ffi.NativeType> widget);
}

/// Wraps GdkWindow
class _GdkWindow extends _GObject {
  const _GdkWindow(super.instance);

  /// Gets the window state bitfield (_GDK_WINDOW_STATE_*).
  int getState() {
    return _gdkWindowGetState(instance);
  }

  @ffi.Native<ffi.Int Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gdk_window_get_state')
  external static int _gdkWindowGetState(ffi.Pointer<ffi.NativeType> window);
}

/// Wrapds GdkGeometry
final class _GdkGeometry extends ffi.Struct {
  factory _GdkGeometry() {
    return ffi.Struct.create();
  }

  @ffi.Int()
  external int minWidth;

  @ffi.Int()
  external int minHeight;

  @ffi.Int()
  external int maxWidth;

  @ffi.Int()
  external int maxHeight;

  @ffi.Int()
  external int baseWidth;

  @ffi.Int()
  external int baseHeight;

  @ffi.Int()
  external int widthInc;

  @ffi.Int()
  external int heightInc;

  @ffi.Double()
  external double minAspect;

  @ffi.Double()
  external double maxAspect;

  @ffi.Int()
  external int winGravity;
}

const int _GDK_WINDOW_STATE_ICONIFIED = 1 << 1;
const int _GDK_WINDOW_STATE_MAXIMIZED = 1 << 2;
const int _GDK_WINDOW_STATE_FULLSCREEN = 1 << 4;

const int _GDK_WINDOW_TYPE_HINT_DIALOG = 1;

/// Wraps GtkWindow
class _GtkWindow extends _GtkContainer {
  /// Create a new GtkWindow
  _GtkWindow() : super(_gtkWindowNew(0));

  /// Make window visible and grab focus.
  void present() {
    _gtkWindowPresent(instance);
  }

  /// Sets the parent window.
  void setTransientFor(_GtkWindow parent) {
    _gtkWindowSetTransientFor(instance, parent.instance);
  }

  /// Set if this window is modal to its parent.
  void setModal(bool modal) {
    _gtkWindowSetModal(instance, modal);
  }

  /// Set the type of this window.
  void setTypeHint(int hint) {
    _gtkWindowSetTypeHint(instance, hint);
  }

  /// Sets the title of the window.
  void setTitle(String title) {
    final ffi.Pointer<ffi.Uint8> titleBuffer = _stringToNative(title);
    _gtkWindowSetTitle(instance, titleBuffer);
    _gFree(titleBuffer);
  }

  /// Gets the current title of the window.
  String getTitle() {
    return _nativeToString(_gtkWindowGetTitle(instance));
  }

  /// Set the default size of the window.
  void setDefaultSize(int width, int height) {
    _gtkWindowSetDefaultSize(instance, width, height);
  }

  /// Set minimum and maximum size of the window.
  void setGeometryHints({int? minWidth, int? minHeight, int? maxWidth, int? maxHeight}) {
    final ffi.Pointer<_GdkGeometry> geometry = _gMalloc0(
      ffi.sizeOf<_GdkGeometry>(),
    ).cast<_GdkGeometry>();
    final _GdkGeometry g = geometry.ref;
    var geometryMask = 0;
    if (minWidth != null || minHeight != null) {
      g.minWidth = minWidth ?? 0;
      g.minHeight = minHeight ?? 0;
      geometryMask |= 2; // GDK_HINT_MIN_SIZE
    }
    if (maxWidth != null || maxHeight != null) {
      g.maxWidth = maxWidth ?? _kMaxWindowDimensions;
      g.maxHeight = maxHeight ?? _kMaxWindowDimensions;
      geometryMask |= 4; // GDK_HINT_MAX_SIZE
    }
    _gtkWindowSetGeometryHints(instance, ffi.nullptr, geometry, geometryMask);
    _gFree(geometry);
  }

  /// Resize to [width]x[height].
  void resize(int width, int height) {
    _gtkWindowResize(instance, width, height);
  }

  /// Maximize window.
  void maximize() {
    _gtkWindowMaximize(instance);
  }

  /// Unaximize window.
  void unmaximize() {
    _gtkWindowUnmaximize(instance);
  }

  /// Iconify (minimize) window.
  void iconify() {
    _gtkWindowIconify(instance);
  }

  /// Deconify (unminimize) window.
  void deiconify() {
    _gtkWindowDeiconify(instance);
  }

  /// Make window fullscreen.
  void fullscreen() {
    _gtkWindowFullscreen(instance);
  }

  /// Leave fullscreen.
  void unfullscreen() {
    _gtkWindowUnfullscreen(instance);
  }

  /// Get the current size of the window.
  Size getSize() {
    final ffi.Pointer<ffi.Int> width = _gMalloc0(ffi.sizeOf<ffi.Int>()).cast<ffi.Int>();
    final ffi.Pointer<ffi.Int> height = _gMalloc0(ffi.sizeOf<ffi.Int>()).cast<ffi.Int>();
    _gtkWindowGetSize(instance, width, height);
    final result = Size(width.value.toDouble(), height.value.toDouble());
    _gFree(width);
    _gFree(height);
    return result;
  }

  /// true if this window has keyboard focus.
  bool isActive() {
    return _gtkWindowIsActive(instance);
  }

  @ffi.Native<ffi.Pointer<ffi.NativeType> Function(ffi.Int)>(symbol: 'gtk_window_new')
  external static ffi.Pointer<ffi.NativeType> _gtkWindowNew(int type);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_present')
  external static void _gtkWindowPresent(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Bool)>(
    symbol: 'gtk_window_set_modal',
  )
  external static void _gtkWindowSetModal(ffi.Pointer<ffi.NativeType> window, bool modal);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Int)>(
    symbol: 'gtk_window_set_type_hint',
  )
  external static void _gtkWindowSetTypeHint(ffi.Pointer<ffi.NativeType> window, int hint);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Pointer<ffi.NativeType>)>(
    symbol: 'gtk_window_set_transient_for',
  )
  external static void _gtkWindowSetTransientFor(
    ffi.Pointer<ffi.NativeType> window,
    ffi.Pointer<ffi.NativeType> parent,
  );

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Pointer<ffi.Uint8>)>(
    symbol: 'gtk_window_set_title',
  )
  external static void _gtkWindowSetTitle(
    ffi.Pointer<ffi.NativeType> window,
    ffi.Pointer<ffi.Uint8> title,
  );

  @ffi.Native<ffi.Pointer<ffi.Uint8> Function(ffi.Pointer<ffi.NativeType>)>(
    symbol: 'gtk_window_get_title',
  )
  external static ffi.Pointer<ffi.Uint8> _gtkWindowGetTitle(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Int, ffi.Int)>(
    symbol: 'gtk_window_set_default_size',
  )
  external static void _gtkWindowSetDefaultSize(
    ffi.Pointer<ffi.NativeType> window,
    int width,
    int height,
  );

  @ffi.Native<
    ffi.Void Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<_GdkGeometry>,
      ffi.Int,
    )
  >(symbol: 'gtk_window_set_geometry_hints')
  external static void _gtkWindowSetGeometryHints(
    ffi.Pointer<ffi.NativeType> window,
    ffi.Pointer<ffi.NativeType> geometryWidget,
    ffi.Pointer<_GdkGeometry> geometry,
    int geometryMask,
  );

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Int, ffi.Int)>(
    symbol: 'gtk_window_resize',
  )
  external static void _gtkWindowResize(ffi.Pointer<ffi.NativeType> window, int width, int height);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_maximize')
  external static void _gtkWindowMaximize(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_unmaximize')
  external static void _gtkWindowUnmaximize(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_iconify')
  external static void _gtkWindowIconify(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_deiconify')
  external static void _gtkWindowDeiconify(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_fullscreen')
  external static void _gtkWindowFullscreen(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_unfullscreen')
  external static void _gtkWindowUnfullscreen(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<
    ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Pointer<ffi.Int>, ffi.Pointer<ffi.Int>)
  >(symbol: 'gtk_window_get_size')
  external static void _gtkWindowGetSize(
    ffi.Pointer<ffi.NativeType> window,
    ffi.Pointer<ffi.Int> width,
    ffi.Pointer<ffi.Int> height,
  );

  @ffi.Native<ffi.Bool Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_is_active')
  external static bool _gtkWindowIsActive(ffi.Pointer<ffi.NativeType> widget);
}

/// Wraps FlView
class _FlView extends _GtkWidget {
  /// Create a new FlView widget.
  _FlView()
    : super(
        _flViewNewForEngine(
          ffi.Pointer<ffi.NativeType>.fromAddress(
            WidgetsBinding.instance.platformDispatcher.engineId!,
          ),
        ),
      );

  /// Get the ID for the Flutter view being shown in this widget.
  int getId() {
    return _flViewGetId(instance);
  }

  @ffi.Native<ffi.Pointer<ffi.NativeType> Function(ffi.Pointer<ffi.NativeType>)>(
    symbol: 'fl_view_new_for_engine',
  )
  external static ffi.Pointer<ffi.NativeType> _flViewNewForEngine(
    ffi.Pointer<ffi.NativeType> engine,
  );

  @ffi.Native<ffi.Int64 Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'fl_view_get_id')
  external static int _flViewGetId(ffi.Pointer<ffi.NativeType> view);
}

/// Wraps FlWindowMonitor (helper object for handling signals from GtkWindow).
class _FlWindowMonitor extends _GObject {
  /// Create a new FlWindowMonitor.
  factory _FlWindowMonitor(
    _GtkWindow window,
    void Function() onConfigure,
    void Function() onStateChanged,
    void Function() onIsActiveNotify,
    void Function() onTitleNotify,
    void Function() onClose,
    void Function() onDestroy,
  ) {
    return _FlWindowMonitor._internal(
      window.instance,
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onConfigure),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onStateChanged),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onIsActiveNotify),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onTitleNotify),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onClose),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onDestroy),
    );
  }

  _FlWindowMonitor._internal(
    ffi.Pointer<ffi.NativeType> window,
    this._onConfigureFunction,
    this._onStateChangedFunction,
    this._onIsActiveNotifyFunction,
    this._onTitleNotifyFunction,
    this._onCloseFunction,
    this._onDestroyFunction,
  ) : super(
        _flWindowMonitorNew(
          window,
          _onConfigureFunction.nativeFunction,
          _onStateChangedFunction.nativeFunction,
          _onIsActiveNotifyFunction.nativeFunction,
          _onTitleNotifyFunction.nativeFunction,
          _onCloseFunction.nativeFunction,
          _onDestroyFunction.nativeFunction,
        ),
      );

  final ffi.NativeCallable<ffi.Void Function()> _onConfigureFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onStateChangedFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onIsActiveNotifyFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onTitleNotifyFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onCloseFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onDestroyFunction;

  /// Close all FFI resources used in the monitor.
  void close() {
    _onConfigureFunction.close();
    _onStateChangedFunction.close();
    _onIsActiveNotifyFunction.close();
    _onTitleNotifyFunction.close();
    _onCloseFunction.close();
    _onDestroyFunction.close();
  }

  @ffi.Native<
    ffi.Pointer<ffi.NativeType> Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
    )
  >(symbol: 'fl_window_monitor_new')
  external static ffi.Pointer<ffi.NativeType> _flWindowMonitorNew(
    ffi.Pointer<ffi.NativeType> window,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onConfigure,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onStateChanged,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onIsActiveNotify,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onTitleNotify,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onClose,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onDestroy,
  );
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
      WidgetsBinding.instance.platformDispatcher.engineId != null,
      'WindowingOwnerLinux must be created after the engine has been initialized.',
    );
  }

  /// GTK windows keyed by view ID.
  final Map<int, _GtkWindow> _windows = <int, _GtkWindow>{};

  @internal
  @override
  RegularWindowController createRegularWindowController({
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    required RegularWindowControllerDelegate delegate,
  }) {
    final controller = RegularWindowControllerLinux(
      owner: this,
      delegate: delegate,
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      title: title,
    );
    _windows[controller.rootView.viewId] = controller._window;
    return controller;
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
    final controller = DialogWindowControllerLinux(
      owner: this,
      delegate: delegate,
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      parent: parent,
      title: title,
    );
    _windows[controller.rootView.viewId] = controller._window;
    return controller;
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
    throw UnimplementedError('Tooltip windows are not yet implemented on Linux.');
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
    throw UnimplementedError('Popup windows are not yet implemented on Linux.');
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
    required WindowingOwnerLinux owner,
    required RegularWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  }) : _owner = owner,
       _delegate = delegate,
       _window = _GtkWindow(),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windowMonitor = _FlWindowMonitor(
      _window,
      // onConfigure
      notifyListeners,
      // onStateChanged
      notifyListeners,
      // onIsActiveNotify
      notifyListeners,
      // onTitleNotify
      notifyListeners,
      // onClose
      () {
        _delegate.onWindowCloseRequested(this);
      },
      // onDestroy
      _delegate.onWindowDestroyed,
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
    final int viewId = view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    view.show();
    _window.add(view);
    _window.present();
  }

  final WindowingOwnerLinux _owner;
  final RegularWindowControllerDelegate _delegate;
  final _GtkWindow _window;
  late final _FlWindowMonitor _windowMonitor;
  bool _destroyed = false;

  @override
  @internal
  Size get contentSize => _window.getSize();

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    _window.destroy();
    _windowMonitor.close();
    _windowMonitor.unref();
    _destroyed = true;
    _owner._windows.remove(rootView.viewId);
  }

  @override
  @internal
  String get title => _window.getTitle();

  @override
  @internal
  bool get isActivated => _window.isActive();

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
    // TODO(robert-ancell): display currently ignored
    if (fullscreen) {
      _window.fullscreen();
    } else {
      _window.unfullscreen();
    }
  }
}

/// Implementation of [DialogWindowController] for the Linux platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [DialogWindowController], the base class for dialog windows.
class DialogWindowControllerLinux extends DialogWindowController {
  /// Creates a new dialog window controller for Linux.
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
  DialogWindowControllerLinux({
    required WindowingOwnerLinux owner,
    required DialogWindowControllerDelegate delegate,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    BaseWindowController? parent,
    String? title,
  }) : _owner = owner,
       _delegate = delegate,
       _parent = parent,
       _window = _GtkWindow(),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _window.setTypeHint(_GDK_WINDOW_TYPE_HINT_DIALOG);
    if (parent != null) {
      final _GtkWindow? parentWindow = owner._windows[parent.rootView.viewId];
      if (parentWindow != null) {
        _window.setTransientFor(parentWindow);
        _window.setModal(true);
      }
    }

    _windowMonitor = _FlWindowMonitor(
      _window,
      // onConfigure
      notifyListeners,
      // onStateChanged
      notifyListeners,
      // onIsActiveNotify
      notifyListeners,
      // onTitleNotify
      notifyListeners,
      // onClose
      () {
        _delegate.onWindowCloseRequested(this);
      },
      // onDestroy
      _delegate.onWindowDestroyed,
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
    final int viewId = view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    view.show();
    _window.add(view);
    _window.present();
  }

  final WindowingOwnerLinux _owner;
  final DialogWindowControllerDelegate _delegate;
  final _GtkWindow _window;
  final BaseWindowController? _parent;
  late final _FlWindowMonitor _windowMonitor;
  bool _destroyed = false;

  @override
  @internal
  Size get contentSize => _window.getSize();

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    _window.destroy();
    _windowMonitor.close();
    _windowMonitor.unref();
    _destroyed = true;
    _owner._windows.remove(rootView.viewId);
  }

  @override
  @internal
  BaseWindowController? get parent => _parent;

  @override
  @internal
  String get title => _window.getTitle();

  @override
  @internal
  bool get isActivated => _window.isActive();

  @override
  @internal
  // NOTE: On Wayland this is never set, see https://gitlab.gnome.org/GNOME/gtk/-/issues/67
  bool get isMinimized => (_window.getWindow().getState() & _GDK_WINDOW_STATE_ICONIFIED) != 0;

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
  }

  @override
  @internal
  void activate() {
    _window.present();
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
}
