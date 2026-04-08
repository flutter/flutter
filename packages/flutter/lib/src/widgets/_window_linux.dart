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

  /// View windows keyed by view ID.
  final Map<int, _FlView> _views = <int, _FlView>{};

  @internal
  @override
  RegularWindowController createRegularWindowController({
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    bool decorated = true,
    required RegularWindowControllerDelegate delegate,
  }) {
    final controller = RegularWindowControllerLinux(
      owner: this,
      delegate: delegate,
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      title: title,
      decorated: decorated,
    );
    _windows[controller.rootView.viewId] = controller._window;
    _views[controller.rootView.viewId] = controller._view;
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
    bool decorated = true,
  }) {
    final controller = DialogWindowControllerLinux(
      owner: this,
      delegate: delegate,
      preferredSize: preferredSize,
      preferredConstraints: preferredConstraints,
      parent: parent,
      title: title,
      decorated: decorated,
    );
    _windows[controller.rootView.viewId] = controller._window;
    _views[controller.rootView.viewId] = controller._view;
    return controller;
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
    final controller = TooltipWindowControllerLinux(
      owner: this,
      delegate: delegate,
      preferredConstraints: preferredConstraints,
      anchorRect: anchorRect,
      positioner: positioner,
      parent: parent,
    );
    _windows[controller.rootView.viewId] = controller._window;
    _views[controller.rootView.viewId] = controller._view;
    return controller;
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

  @internal
  @override
  SatelliteWindowController createSatelliteWindowController({
    required SatelliteWindowControllerDelegate delegate,
    required BaseWindowController parent,
    required WindowPositioner initialPositioner,
    Rect? initialAnchorRect,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
  }) {
    throw UnimplementedError('Satellite windows are not yet implemented on Linux.');
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
    bool decorated = true,
  }) : _owner = owner,
       _delegate = delegate,
       _window = _GtkWindow(_GtkWindowType.toplevel),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windowMonitor = _FlWindowMonitor(
      _window,
      onConfigure: notifyListeners,
      onStateChanged: notifyListeners,
      onIsActiveNotify: notifyListeners,
      onTitleNotify: notifyListeners,
      onClose: () {
        _delegate.onWindowCloseRequested(this);
      },
      onDestroy: _delegate.onWindowDestroyed,
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
    _window.setDecorated(decorated);
    final engine = _FlEngine.current();
    _view = _FlView(engine);
    _viewMonitor = _FlViewMonitor(
      _view,
      onFirstFrame: () {
        _window.present();
      },
    );
    final int viewId = _view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    _view.show();
    _window.add(_view);
  }

  final WindowingOwnerLinux _owner;
  final RegularWindowControllerDelegate _delegate;
  final _GtkWindow _window;
  late final _FlView _view;
  late final _FlViewMonitor _viewMonitor;
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
    _viewMonitor.close();
    _viewMonitor.unref();
    _window.destroy();
    _windowMonitor.close();
    _windowMonitor.unref();
    _destroyed = true;
    _owner._windows.remove(rootView.viewId);
    _owner._views.remove(rootView.viewId);
  }

  @override
  @internal
  String get title => _window.getTitle();

  @override
  @internal
  bool get isActivated => _window.isActive();

  @override
  @internal
  bool get isMaximized => _window.getWindow().getState().contains(_GdkWindowState.maximized);

  @override
  @internal
  // NOTE: On Wayland this is never set, see https://gitlab.gnome.org/GNOME/gtk/-/issues/67
  bool get isMinimized => _window.getWindow().getState().contains(_GdkWindowState.iconified);

  @override
  @internal
  bool get isFullscreen => _window.getWindow().getState().contains(_GdkWindowState.fullscreen);

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
      maxWidth: constraints.maxWidth.isInfinite
          ? _kMaxWindowDimensions
          : constraints.maxWidth.toInt(),
      maxHeight: constraints.maxHeight.isInfinite
          ? _kMaxWindowDimensions
          : constraints.maxHeight.toInt(),
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
    bool decorated = true,
  }) : _owner = owner,
       _delegate = delegate,
       _parent = parent,
       _window = _GtkWindow(_GtkWindowType.toplevel),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _window.setTypeHint(_GdkWindowTypeHint.dialog);
    if (parent != null) {
      final _GtkWindow? parentWindow = owner._windows[parent.rootView.viewId];
      if (parentWindow == null) {
        throw Exception('Failed to find dialog parent window');
      }
      _window.setTransientFor(parentWindow);
      _window.setModal(true);
    }

    _windowMonitor = _FlWindowMonitor(
      _window,
      onConfigure: notifyListeners,
      onStateChanged: notifyListeners,
      onIsActiveNotify: notifyListeners,
      onTitleNotify: notifyListeners,
      onClose: () {
        _delegate.onWindowCloseRequested(this);
      },
      onDestroy: _delegate.onWindowDestroyed,
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
    _window.setDecorated(decorated);
    final engine = _FlEngine.current();
    _view = _FlView(engine);
    _viewMonitor = _FlViewMonitor(
      _view,
      onFirstFrame: () {
        _window.present();
      },
    );
    final int viewId = _view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    _view.show();
    _window.add(_view);
  }

  final WindowingOwnerLinux _owner;
  final DialogWindowControllerDelegate _delegate;
  final _GtkWindow _window;
  final BaseWindowController? _parent;
  late final _FlView _view;
  late final _FlViewMonitor _viewMonitor;
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
    _viewMonitor.close();
    _viewMonitor.unref();
    _window.destroy();
    _windowMonitor.close();
    _windowMonitor.unref();
    _destroyed = true;
    _owner._windows.remove(rootView.viewId);
    _owner._views.remove(rootView.viewId);
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
  bool get isMinimized => _window.getWindow().getState().contains(_GdkWindowState.iconified);

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

/// Implementation of [TooltipWindowController] for the Linux platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [TooltipWindowController], the base class for tooltip windows.
class TooltipWindowControllerLinux extends TooltipWindowController {
  /// Creates a new tooltip window controller for Linux.
  ///
  /// When this constructor completes the native window has been created and
  /// has a view associated with it.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [TooltipWindowController], the base class for tooltip windows.
  @internal
  TooltipWindowControllerLinux({
    required WindowingOwnerLinux owner,
    required TooltipWindowControllerDelegate delegate,
    required BoxConstraints preferredConstraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) : _owner = owner,
       _delegate = delegate,
       _parent = parent,
       _window = _GtkWindow(_GtkWindowType.popup),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _window.setTypeHint(_GdkWindowTypeHint.tooltip);
    _window.setDecorated(false);
    _window.realize();

    _windowMonitor = _FlWindowMonitor(
      _window,
      onConfigure: notifyListeners,
      onDestroy: _delegate.onWindowDestroyed,
    );
    setConstraints(preferredConstraints);
    final engine = _FlEngine.current();
    _view = _FlView(engine, isSizedToContent: true);
    _viewMonitor = _FlViewMonitor(
      _view,
      onFirstFrame: () {
        _window.show();
      },
    );
    final int viewId = _view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    _view.show();
    _window.add(_view);

    final _GtkWindow? parentWindow = _owner._windows[_parent.rootView.viewId];
    if (parentWindow == null) {
      throw Exception('Failed to find tooltip parent window');
    }
    _window.setTransientFor(parentWindow);
    updatePosition(anchorRect: anchorRect, positioner: positioner);
  }

  final WindowingOwnerLinux _owner;
  final TooltipWindowControllerDelegate _delegate;
  final _GtkWindow _window;
  late Rect _anchorRect;
  late WindowPositioner _positioner;
  final BaseWindowController _parent;
  late final _FlView _view;
  late final _FlViewMonitor _viewMonitor;
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
    _viewMonitor.close();
    _viewMonitor.unref();
    _window.destroy();
    _windowMonitor.close();
    _windowMonitor.unref();
    _destroyed = true;
    _owner._windows.remove(rootView.viewId);
    _owner._views.remove(rootView.viewId);
  }

  @override
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner}) {
    if (anchorRect != null) {
      _anchorRect = anchorRect;
    }
    if (positioner != null) {
      _positioner = positioner;
    }

    final _GtkWindow? parentWindow = _owner._windows[_parent.rootView.viewId];
    final _FlView? view = _owner._views[_parent.rootView.viewId];
    var offset = (0, 0);
    if (parentWindow != null && view != null) {
      offset = view.translateCoordinates(parentWindow, (0, 0)) ?? (0, 0);
    }
    // This is only applied in GTK3 the first time the tooltip is shown as GTK3
    // only sends updates when the popup surface configure event is
    // received. Since GTK3 does not set the [reactive flag](https://wayland.app/protocols/xdg-shell#xdg_positioner:request:set_reactive)
    // on the positioner it is only [received once](https://wayland.app/protocols/xdg-shell#xdg_popup:event:configure).
    // This means if a Linux tooltip is resized it will not be repositioned.
    _window.getWindow().moveToRect(
      x: _anchorRect.left.toInt() + offset.$1,
      y: _anchorRect.top.toInt() + offset.$2,
      width: (_anchorRect.right - _anchorRect.left).toInt(),
      height: (_anchorRect.bottom - _anchorRect.top).toInt(),
      rectAnchor: _anchorToGravity(_positioner.parentAnchor),
      windowAnchor: _anchorToGravity(_positioner.childAnchor),
      anchorHints: _constraintAdjustmentToHints(_positioner.constraintAdjustment),
      rectAnchorDx: _positioner.offset.dx.toInt(),
      rectAnchorDy: _positioner.offset.dy.toInt(),
    );
  }

  _GdkGravity _anchorToGravity(WindowPositionerAnchor anchor) {
    return switch (anchor) {
      WindowPositionerAnchor.center => _GdkGravity.center,
      WindowPositionerAnchor.top => _GdkGravity.north,
      WindowPositionerAnchor.bottom => _GdkGravity.south,
      WindowPositionerAnchor.left => _GdkGravity.west,
      WindowPositionerAnchor.right => _GdkGravity.east,
      WindowPositionerAnchor.topLeft => _GdkGravity.northWest,
      WindowPositionerAnchor.bottomLeft => _GdkGravity.southWest,
      WindowPositionerAnchor.topRight => _GdkGravity.northEast,
      WindowPositionerAnchor.bottomRight => _GdkGravity.southEast,
    };
  }

  Set<_GdkAnchorHint> _constraintAdjustmentToHints(
    WindowPositionerConstraintAdjustment adjustment,
  ) {
    return <_GdkAnchorHint>{
      if (adjustment.flipX) _GdkAnchorHint.flipX,
      if (adjustment.flipY) _GdkAnchorHint.flipY,
      if (adjustment.slideX) _GdkAnchorHint.slideX,
      if (adjustment.slideY) _GdkAnchorHint.slideY,
      if (adjustment.resizeX) _GdkAnchorHint.resizeX,
      if (adjustment.resizeY) _GdkAnchorHint.resizeY,
    };
  }

  @override
  @internal
  BaseWindowController get parent => _parent;

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
}

// The following classes are thin wrappers around the corresponding GTK/GDK
// objects, with only the methods we need implemented. The method signatures
// and enum values are designed to match the corresponding C APIs as closely
// as possible, to minimize the amount of translation needed in the method
// implementations.

/// The type of a GtkWindow. Matches the GtkWindowType enum in gtk/gtktypes.h.
enum _GtkWindowType {
  toplevel,
  // ignore: unused_field
  popup,
}

/// States a toplevel window can be in. Matches the order of the GdkWindowState
/// enum in gdk/gdkwindow.h, except these are bit positions when passed to GTK.
enum _GdkWindowState {
  withdrawn,
  iconified,
  maximized,
  sticky,
  fullscreen,
  above,
  below,
  focused,
  tiled,
  topTiled,
  topResizable,
  rightTiled,
  rightResizable,
  bottomTiled,
  bottomResizable,
  leftTiled,
  leftResizable,
}

/// Hints for the window manager on how to treat a window. Matches the
/// GdkWindowTypeHint enum in gdk/gdkwindow.h.
enum _GdkWindowTypeHint {
  // ignore: unused_field
  normal,
  dialog,
  // ignore: unused_field
  menu,
  // ignore: unused_field
  toolbar,
  // ignore: unused_field
  splashscreen,
  // ignore: unused_field
  utility,
  // ignore: unused_field
  dock,
  // ignore: unused_field
  desktop,
  // ignore: unused_field
  dropdown_menu,
  // ignore: unused_field
  popup_menu,
  // ignore: unused_field
  tooltip,
  // ignore: unused_field
  notification,
  // ignore: unused_field
  combo,
  // ignore: unused_field
  dnd,
}

/// Window reference points. Matches the GdkGravity enum in gdk/gdkwindow.h.
enum _GdkGravity {
  // ignore: unused_field
  none,
  northWest,
  north,
  northEast,
  west,
  center,
  east,
  southWest,
  south,
  southEast,
  // ignore: unused_field
  static_,
}

/// Positioning hints for aligning a window relative to a rectangle. Matches
/// the GdkAnchorHint enum in gdk/gdkwindow.h, except these are bit positions
/// when passed to GTK.
enum _GdkAnchorHint { flipX, flipY, slideX, slideY, resizeX, resizeY }

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

/// Wraps GObject.
class _GObject {
  /// Creates a wrapper to an existing [GObject] in [instance].
  const _GObject(this.instance);

  /// The pointer to the underlying [GObject].
  final ffi.Pointer<ffi.NativeType> instance;

  /// Drop reference to this object.
  void unref() {
    _unref(instance);
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'g_object_unref')
  external static void _unref(ffi.Pointer<ffi.NativeType> widget);
}

/// Wraps GtkContainer.
class _GtkContainer extends _GtkWidget {
  /// Creates a wrapper to an existing [GtkContainer] in [instance].
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

/// Wraps GtkWidget.
class _GtkWidget extends _GObject {
  /// Creates a wrapper to an existing [GtkWidget] in [instance].
  const _GtkWidget(super.instance);

  /// Creates the GDK resources associated with a widget.
  void realize() {
    _gtkWidgetRealize(instance);
  }

  /// Show the widget (defaults to hidden).
  void show() {
    _gtkWidgetShow(instance);
  }

  /// Get the low level window backing this widget.
  _GdkWindow getWindow() {
    return _GdkWindow(_gtkWidgetGetWindow(instance));
  }

  /// Get the scale factor that maps window coordinates to device pixels.
  int getScaleFactor() {
    return _gtkWidgetGetScaleFactor(instance);
  }

  /// Translates coordinates from this widget to the [destWidget]. Returns null if the widgets do not have a common ancestor.
  (int, int)? translateCoordinates(_GtkWidget destWidget, (int, int) src) {
    final ffi.Pointer<ffi.Int> dest = _gMalloc0(ffi.sizeOf<ffi.Int>() * 2).cast<ffi.Int>();
    final bool translated = _gtkWidgetTranslateCoordinates(
      instance,
      destWidget.instance,
      src.$1,
      src.$2,
      dest.elementAt(0),
      dest.elementAt(1),
    );
    final (int, int)? result = translated ? (dest[0], dest[1]) : null;
    _gFree(dest);
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

/// Wraps GdkWindow.
class _GdkWindow extends _GObject {
  /// Creates a wrapper to an existing [GdkWindow] in [instance].
  const _GdkWindow(super.instance);

  /// Gets the window state.
  Set<_GdkWindowState> getState() {
    final int stateBits = _gdkWindowGetState(instance);
    final states = <_GdkWindowState>{};
    for (final _GdkWindowState state in _GdkWindowState.values) {
      if ((stateBits & (1 << state.index)) != 0) {
        states.add(state);
      }
    }

    return states;
  }

  /// Move the window to place it relative to the given rectangle according to the specified anchors.
  void moveToRect({
    required int x,
    required int y,
    required int width,
    required int height,
    required _GdkGravity rectAnchor,
    required _GdkGravity windowAnchor,
    required Set<_GdkAnchorHint> anchorHints,
    int rectAnchorDx = 0,
    int rectAnchorDy = 0,
  }) {
    final ffi.Pointer<_GdkRectangle> rect = _gMalloc0(
      ffi.sizeOf<_GdkRectangle>(),
    ).cast<_GdkRectangle>();
    final _GdkRectangle r = rect.ref;
    r.x = x;
    r.y = y;
    r.width = width;
    r.height = height;
    var anchorHintsBits = 0;
    for (final anchor in anchorHints) {
      anchorHintsBits |= 1 << anchor.index;
    }
    _gdkWindowMoveToRect(
      instance,
      rect,
      rectAnchor.index,
      windowAnchor.index,
      anchorHintsBits,
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

  @ffi.Int()
  external int heightInc;

  @ffi.Double()
  external double minAspect;

  @ffi.Double()
  external double maxAspect;

  @ffi.Int()
  external int winGravity;
}

/// Wraps GtkWindow.
class _GtkWindow extends _GtkContainer {
  /// Create a new GtkWindow
  _GtkWindow(_GtkWindowType type) : super(_gtkWindowNew(type.index));

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
  void setTypeHint(_GdkWindowTypeHint hint) {
    _gtkWindowSetTypeHint(instance, hint.index);
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
    final ffi.Pointer<ffi.Int> size = _gMalloc0(ffi.sizeOf<ffi.Int>() * 2).cast<ffi.Int>();
    _gtkWindowGetSize(instance, size.elementAt(0), size.elementAt(1));
    final result = Size(size[0].toDouble(), size[1].toDouble());
    _gFree(size);
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

/// Wraps FlEngine.
class _FlEngine extends _GObject {
  /// Gets the FlEngine object for the engine with the given ID.
  _FlEngine(int engineId) : super(ffi.Pointer<ffi.NativeType>.fromAddress(engineId));

  /// Gets the engine object running in the current isolate.
  factory _FlEngine.current() => _FlEngine(WidgetsBinding.instance.platformDispatcher.engineId!);
}

/// Wraps FlView.
class _FlView extends _GtkWidget {
  /// Create a new FlView widget.
  _FlView(_FlEngine engine, {bool isSizedToContent = false})
    : super(
        isSizedToContent
            ? _flViewNewSizedToContent(engine.instance)
            : _flViewNewForEngine(engine.instance),
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

/// Wraps FlViewMonitor (helper object for handling signals from FlView).
class _FlViewMonitor extends _GObject {
  /// Create a new FlViewMonitor.
  factory _FlViewMonitor(_FlView view, {VoidCallback? onFirstFrame}) {
    void noop() {}
    return _FlViewMonitor._internal(
      view.instance,
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onFirstFrame ?? noop),
    );
  }

  _FlViewMonitor._internal(ffi.Pointer<ffi.NativeType> view, this._onFirstFrameFunction)
    : super(_flViewMonitorNew(view, _onFirstFrameFunction.nativeFunction));

  final ffi.NativeCallable<ffi.Void Function()> _onFirstFrameFunction;

  /// Close all FFI resources used in the monitor.
  void close() {
    _onFirstFrameFunction.close();
  }

  @ffi.Native<
    ffi.Pointer<ffi.NativeType> Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
    )
  >(symbol: 'fl_view_monitor_new')
  external static ffi.Pointer<ffi.NativeType> _flViewMonitorNew(
    ffi.Pointer<ffi.NativeType> view,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onFirstFrame,
  );
}

/// Wraps FlWindowMonitor (helper object for handling signals from GtkWindow).
class _FlWindowMonitor extends _GObject {
  /// Create a new FlWindowMonitor.
  factory _FlWindowMonitor(
    _GtkWindow window, {
    VoidCallback? onConfigure,
    VoidCallback? onStateChanged,
    VoidCallback? onIsActiveNotify,
    VoidCallback? onTitleNotify,
    VoidCallback? onClose,
    VoidCallback? onDestroy,
  }) {
    void noop() {}
    return _FlWindowMonitor._internal(
      window.instance,
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onConfigure ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onStateChanged ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onIsActiveNotify ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onTitleNotify ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onClose ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onDestroy ?? noop),
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
