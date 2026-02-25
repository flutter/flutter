// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'dart:ui';

// Maximum width and height a window can be.
// In C this would be INT_MAX, but since we can't determine that from Dart let's assume it's 32 bit signed. In any case this is far beyond any reasonable window size.
const int _kMaxWindowDimensions = 0x7fffffff;

const int GTK_WINDOW_TOPLEVEL = 0;
const int GTK_WINDOW_POPUP = 0;

const int GDK_GRAVITY_NORTH_WEST = 1;
const int GDK_GRAVITY_NORTH = 2;
const int GDK_GRAVITY_NORTH_EAST = 3;
const int GDK_GRAVITY_WEST = 4;
const int GDK_GRAVITY_CENTER = 5;
const int GDK_GRAVITY_EAST = 6;
const int GDK_GRAVITY_SOUTH_WEST = 7;
const int GDK_GRAVITY_SOUTH = 8;
const int GDK_GRAVITY_SOUTH_EAST = 9;
const int GDK_GRAVITY_STATIC = 10;

const int GDK_ANCHOR_FLIP_X = 1;
const int GDK_ANCHOR_FLIP_Y = 2;
const int GDK_ANCHOR_SLIDE_X = 4;
const int GDK_ANCHOR_SLIDE_Y = 8;
const int GDK_ANCHOR_RESIZE_X = 16;
const int GDK_ANCHOR_RESIZE_Y = 32;

/// Flag to indicated if a window is iconified.
const int GDK_WINDOW_STATE_ICONIFIED = 1 << 1;

/// Flag to indicated if a window is maximized.
const int GDK_WINDOW_STATE_MAXIMIZED = 1 << 2;

/// Flag to indicated if a window is fullscreen.
const int GDK_WINDOW_STATE_FULLSCREEN = 1 << 4;

/// Window hint for dialogs.
const int GDK_WINDOW_TYPE_HINT_DIALOG = 1;

/// Window hint for tooltips.
const int _GDK_WINDOW_TYPE_HINT_TOOLTIP = 10;

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
class GObject {
  /// Creates a wrapper to an existing [GObject] in [instance].
  const GObject(this.instance);

  /// The pointer to the underlying [GObject].
  final ffi.Pointer<ffi.NativeType> instance;

  /// Drop reference to this object.
  void unref() {
    _unref(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'g_object_unref')
  external static void _unref(ffi.Pointer<ffi.NativeType> widget);
}

/// Wraps GtkContainer
class GtkContainer extends GtkWidget {
  /// Creates a wrapper to an existing [GtkContainer] in [instance].
  const GtkContainer(super.instance);

  /// Adds [child] widget to this container.
  void add(GtkWidget child) {
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
class GtkWidget extends GObject {
  /// Creates a wrapper to an existing [GtkWidget] in [instance].
  const GtkWidget(super.instance);

  /// Creates the GDK resources associated with a widget.
  void realize() {
    _gtkWidgetRealize(instance);
  }

  /// Show the widget (defaults to hidden).
  void show() {
    _gtkWidgetShow(instance);
  }

  /// Get the low level window backing this widget.
  GdkWindow getWindow() {
    return GdkWindow(_gtkWidgetGetWindow(instance));
  }

  /// Get the scale factor that maps window coordinates to device pixels.
  int getScaleFactor() {
    return _gtkWidgetGetScaleFactor(instance);
  }

  (int, int)? translateCoordinates(GtkWidget destWidget, (int, int) src) {
    final ffi.Pointer<ffi.Int> destX = _gMalloc0(ffi.sizeOf<ffi.Int>()).cast<ffi.Int>();
    final ffi.Pointer<ffi.Int> destY = _gMalloc0(ffi.sizeOf<ffi.Int>()).cast<ffi.Int>();
    final translated = _gtkWidgetTranslateCoordinates(
      instance,
      destWidget.instance,
      src.$1,
      src.$2,
      destX,
      destY,
    );
    final result = translated ? (destX.value, destY.value) : null;
    _gFree(destX);
    _gFree(destY);
    return result;
  }

  /// Destroy the widget.
  void destroy() {
    _gtkWindowDestroy(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_realize')
  external static void _gtkWidgetRealize(ffi.Pointer<ffi.NativeType> widget);

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

  @ffi.Native<ffi.Int Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_get_scale_factor')
  external static int _gtkWidgetGetScaleFactor(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<
    ffi.Bool Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<ffi.NativeType>,
      ffi.Int,
      ffi.Int,
      ffi.Pointer<ffi.Int>,
      ffi.Pointer<ffi.Int>,
    )
  >(symbol: 'gtk_widget_translate_coordinates')
  external static bool _gtkWidgetTranslateCoordinates(
    ffi.Pointer<ffi.NativeType> widget,
    ffi.Pointer<ffi.NativeType> destWidget,
    int srcX,
    int srcY,
    ffi.Pointer<ffi.Int> destX,
    ffi.Pointer<ffi.Int> destY,
  );
}

/// Wraps GdkWindow
class GdkWindow extends GObject {
  /// Creates a wrapper to an existing [GdkWindow] in [instance].
  const GdkWindow(super.instance);

  /// Gets the window state bitfield (_GDK_WINDOW_STATE_*).
  int getState() {
    return _gdkWindowGetState(instance);
  }

  /// FIXME
  void moveToRect({
    required int x,
    required int y,
    required int width,
    required int height,
    required int rectAnchor,
    required int windowAnchor,
    required int anchorHints,
    int rectAnchorDx = 0,
    int rectAnchorDy = 0,
  }) {
    final ffi.Pointer<_GdkRectangle> rect = _gMalloc0(
      ffi.sizeOf<_GdkRectangle>(),
    ).cast<_GdkRectangle>();
    final r = rect.ref;
    r.x = x;
    r.y = y;
    r.width = width;
    r.height = height;
    _gdkWindowMoveToRect(
      instance,
      rect,
      rectAnchor,
      windowAnchor,
      anchorHints,
      rectAnchorDx,
      rectAnchorDy,
    );
    _gFree(rect);
  }

  @ffi.Native<ffi.Int Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gdk_window_get_state')
  external static int _gdkWindowGetState(ffi.Pointer<ffi.NativeType> window);

  @ffi.Native<
    ffi.Void Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<ffi.NativeType>,
      ffi.Int,
      ffi.Int,
      ffi.Int,
      ffi.Int,
      ffi.Int,
    )
  >(symbol: 'gdk_window_move_to_rect')
  external static void _gdkWindowMoveToRect(
    ffi.Pointer<ffi.NativeType> window,
    ffi.Pointer<ffi.NativeType> rect,
    int rectAnchor,
    int windowAnchor,
    int anchorHints,
    int rectAnchorDx,
    int rectAnchorDy,
  );
}

/// Wraps GdkRectangle.
final class _GdkRectangle extends ffi.Struct {
  factory _GdkRectangle() {
    return ffi.Struct.create();
  }

  @ffi.Int()
  external int x;

  @ffi.Int()
  external int y;

  @ffi.Int()
  external int width;

  @ffi.Int()
  external int height;
}

/// Wraps GdkGeometry.
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

  /// Height resize increment.
  @ffi.Int()
  external int heightInc;

  @ffi.Double()
  external double minAspect;

  @ffi.Double()
  external double maxAspect;

  @ffi.Int()
  external int winGravity;
}

/// Wraps GtkWindow
class GtkWindow extends GtkContainer {
  /// Create a new [GtkWindow].
  GtkWindow(int type) : super(_gtkWindowNew(type));

  /// Make window visible and grab focus.
  void present() {
    _gtkWindowPresent(instance);
  }

  /// Sets the parent window.
  void setTransientFor(GtkWindow parent) {
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

  /// Sets if this window has decorations (titlebar, borders, shadow).
  void setDecorated(bool decorated) {
    _gtkWindowSetDecorated(instance, decorated);
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

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Bool)>(
    symbol: 'gtk_window_set_decorated',
  )
  external static void _gtkWindowSetDecorated(ffi.Pointer<ffi.NativeType> window, bool decorated);

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
class FlView extends GtkWidget {
  /// Create a new FlView widget.
  FlView(int engineId, {bool isSizedToContent = false})
    : super(
        isSizedToContent
            ? _flViewNewSizedToContent(ffi.Pointer<ffi.NativeType>.fromAddress(engineId))
            : _flViewNewForEngine(ffi.Pointer<ffi.NativeType>.fromAddress(engineId)),
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

  @ffi.Native<ffi.Pointer<ffi.NativeType> Function(ffi.Pointer<ffi.NativeType>)>(
    symbol: 'fl_view_new_sized_to_content',
  )
  external static ffi.Pointer<ffi.NativeType> _flViewNewSizedToContent(
    ffi.Pointer<ffi.NativeType> engine,
  );

  @ffi.Native<ffi.Int64 Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'fl_view_get_id')
  external static int _flViewGetId(ffi.Pointer<ffi.NativeType> view);
}

/// Wraps FlWindowMonitor (helper object for handling signals from GtkWindow).
class FlWindowMonitor extends GObject {
  /// Create a new FlWindowMonitor.
  factory FlWindowMonitor(
    GtkWindow window, {
    VoidCallback? onConfigure,
    VoidCallback? onStateChanged,
    VoidCallback? onIsActiveNotify,
    VoidCallback? onTitleNotify,
    VoidCallback? onClose,
    VoidCallback? onDestroy,
  }) {
    void noop() {}
    return FlWindowMonitor._internal(
      window.instance,
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onConfigure ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onStateChanged ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onIsActiveNotify ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onTitleNotify ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onClose ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onDestroy ?? noop),
    );
  }

  FlWindowMonitor._internal(
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
