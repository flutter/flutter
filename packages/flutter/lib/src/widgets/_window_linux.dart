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

import 'dart:io';
import 'dart:ui' show Display, FlutterView;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../foundation/_features.dart';
import '_window.dart';
import '_window_linux_ffi.dart';
import '_window_positioner.dart';
import 'binding.dart';

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
  final Map<int, GtkWindow> _windows = <int, GtkWindow>{};

  /// View windows keyed by view ID.
  final Map<int, FlView> _views = <int, FlView>{};

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
    _views[controller.rootView.viewId] = controller._view;
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
    final controller = TooltipWindowControllerLinux(
      owner: this,
      delegate: delegate,
      preferredConstraints: preferredConstraints,
      isSizedToContent: isSizedToContent,
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
       _window = GtkWindow(GTK_WINDOW_TOPLEVEL),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _windowMonitor = FlWindowMonitor(
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
    _view = FlView(WidgetsBinding.instance.platformDispatcher.engineId!);
    final int viewId = _view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    _view.show();
    _window.add(_view);
    _window.present();
  }

  final WindowingOwnerLinux _owner;
  final RegularWindowControllerDelegate _delegate;
  final GtkWindow _window;
  late final FlView _view;
  late final FlWindowMonitor _windowMonitor;
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
  bool get isMaximized => (_window.getWindow().getState() & GDK_WINDOW_STATE_MAXIMIZED) != 0;

  @override
  @internal
  // NOTE: On Wayland this is never set, see https://gitlab.gnome.org/GNOME/gtk/-/issues/67
  bool get isMinimized => (_window.getWindow().getState() & GDK_WINDOW_STATE_ICONIFIED) != 0;

  @override
  @internal
  bool get isFullscreen => (_window.getWindow().getState() & GDK_WINDOW_STATE_FULLSCREEN) != 0;

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
       _window = GtkWindow(GTK_WINDOW_TOPLEVEL),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _window.setTypeHint(GDK_WINDOW_TYPE_HINT_DIALOG);
    if (parent != null) {
      final GtkWindow? parentWindow = owner._windows[parent.rootView.viewId];
      if (parentWindow != null) {
        _window.setTransientFor(parentWindow);
        _window.setModal(true);
      }
    }

    _windowMonitor = FlWindowMonitor(
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
    _view = FlView(WidgetsBinding.instance.platformDispatcher.engineId!);
    final int viewId = _view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    _view.show();
    _window.add(_view);
    _window.present();
  }

  final WindowingOwnerLinux _owner;
  final DialogWindowControllerDelegate _delegate;
  final GtkWindow _window;
  final BaseWindowController? _parent;
  late final FlView _view;
  late final FlWindowMonitor _windowMonitor;
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
  bool get isMinimized => (_window.getWindow().getState() & GDK_WINDOW_STATE_ICONIFIED) != 0;

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
    required bool isSizedToContent,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) : _owner = owner,
       _delegate = delegate,
       _parent = parent,
       _window = GtkWindow(GTK_WINDOW_POPUP),
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    //_window.setTypeHint(_GDK_WINDOW_TYPE_HINT_TOOLTIP);
    _window.setDecorated(false);
    _window.realize();

    _windowMonitor = FlWindowMonitor(
      _window,
      onConfigure: notifyListeners,
      onDestroy: _delegate.onWindowDestroyed,
    );
    setConstraints(preferredConstraints);
    _view = FlView(
      WidgetsBinding.instance.platformDispatcher.engineId!,
      isSizedToContent: isSizedToContent,
    );
    final int viewId = _view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
    _view.show();
    _window.add(_view);

    final GtkWindow? parentWindow = _owner._windows[_parent.rootView.viewId];
    if (parentWindow != null) {
      _window.setTransientFor(parentWindow);
    }
    updatePosition(anchorRect: anchorRect, positioner: positioner);

    _window.show();
  }

  final WindowingOwnerLinux _owner;
  final TooltipWindowControllerDelegate _delegate;
  final GtkWindow _window;
  late Rect _anchorRect;
  late WindowPositioner _positioner;
  final BaseWindowController _parent;
  late final FlView _view;
  late final FlWindowMonitor _windowMonitor;
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

    final GtkWindow? parentWindow = _owner._windows[_parent.rootView.viewId];
    final FlView? view = _owner._views[_parent.rootView.viewId];
    var offset = (0, 0);
    if (parentWindow != null && view != null) {
      offset = view.translateCoordinates(parentWindow, (0, 0)) ?? (0, 0);
    }
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

  int _anchorToGravity(WindowPositionerAnchor anchor) {
    switch (anchor) {
      case WindowPositionerAnchor.center:
        return GDK_GRAVITY_CENTER;
      case WindowPositionerAnchor.top:
        return GDK_GRAVITY_NORTH;
      case WindowPositionerAnchor.bottom:
        return GDK_GRAVITY_SOUTH;
      case WindowPositionerAnchor.left:
        return GDK_GRAVITY_WEST;
      case WindowPositionerAnchor.right:
        return GDK_GRAVITY_EAST;
      case WindowPositionerAnchor.topLeft:
        return GDK_GRAVITY_NORTH_WEST;
      case WindowPositionerAnchor.bottomLeft:
        return GDK_GRAVITY_SOUTH_WEST;
      case WindowPositionerAnchor.topRight:
        return GDK_GRAVITY_NORTH_EAST;
      case WindowPositionerAnchor.bottomRight:
        return GDK_GRAVITY_SOUTH_EAST;
    }
  }

  int _constraintAdjustmentToHints(WindowPositionerConstraintAdjustment adjustment) {
    int hints = 0;
    if (adjustment.flipX) {
      hints |= GDK_ANCHOR_FLIP_X;
    }
    if (adjustment.flipY) {
      hints |= GDK_ANCHOR_FLIP_Y;
    }
    if (adjustment.slideX) {
      hints |= GDK_ANCHOR_SLIDE_X;
    }
    if (adjustment.slideY) {
      hints |= GDK_ANCHOR_SLIDE_Y;
    }
    if (adjustment.resizeX) {
      hints |= GDK_ANCHOR_RESIZE_X;
    }
    if (adjustment.resizeY) {
      hints |= GDK_ANCHOR_RESIZE_Y;
    }
    return hints;
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
