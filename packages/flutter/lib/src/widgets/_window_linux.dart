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

  /// The registrar that tracks the native windows and views created by this
  /// owner, keyed by view ID.
  ///
  /// Subclasses that create their own window types should register the native
  /// window and view they create with this registrar so that features such as
  /// parenting and positioning can locate them by view ID.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  @protected
  LinuxWindowRegistrar get registrar => _registrar;
  final LinuxWindowRegistrar _registrar = LinuxWindowRegistrar();

  @internal
  @override
  WindowController createWindowController({
    Size? size,
    BoxConstraints? constraints,
    required bool resizable,
    String? title,
    required WindowControllerDelegate delegate,
  }) {
    final controller = WindowControllerLinux(
      owner: this,
      delegate: delegate,
      size: size,
      constraints: constraints,
      title: title,
      resizable: resizable,
    );
    _registrar.register(
      viewId: controller.rootView.viewId,
      windowHandle: controller._window.instance.cast(),
      viewHandle: controller._view.instance.cast(),
    );
    return controller;
  }

  @internal
  @override
  DialogWindowController createDialogWindowController({
    required DialogWindowControllerDelegate delegate,
    Size? size,
    BoxConstraints? constraints,
    required bool resizable,
    BaseWindowController? parent,
    String? title,
  }) {
    final controller = DialogWindowControllerLinux(
      owner: this,
      delegate: delegate,
      size: size,
      constraints: constraints,
      parent: parent,
      title: title,
      resizable: resizable,
    );
    _registrar.register(
      viewId: controller.rootView.viewId,
      windowHandle: controller._window.instance.cast(),
      viewHandle: controller._view.instance.cast(),
    );
    return controller;
  }

  @internal
  @override
  TooltipWindowController createTooltipWindowController({
    required TooltipWindowControllerDelegate delegate,
    required BoxConstraints constraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) {
    final controller = TooltipWindowControllerLinux(
      owner: this,
      delegate: delegate,
      constraints: constraints,
      anchorRect: anchorRect,
      positioner: positioner,
      parent: parent,
    );
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _registrar.registerPopover(
        viewId: controller.rootView.viewId,
        popoverHandle: controller.windowHandle,
        viewHandle: controller.flutterViewHandle,
      );
    } else {
      _registrar.register(
        viewId: controller.rootView.viewId,
        windowHandle: controller.windowHandle,
        viewHandle: controller.flutterViewHandle,
      );
    }
    return controller;
  }

  @internal
  @override
  PopupWindowController createPopupWindowController({
    required PopupWindowControllerDelegate delegate,
    required BoxConstraints constraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) {
    final controller = PopupWindowControllerLinux(
      owner: this,
      delegate: delegate,
      constraints: constraints,
      anchorRect: anchorRect,
      positioner: positioner,
      parent: parent,
    );
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _registrar.registerPopover(
        viewId: controller.rootView.viewId,
        popoverHandle: controller.windowHandle,
        viewHandle: controller.flutterViewHandle,
      );
    } else {
      _registrar.register(
        viewId: controller.rootView.viewId,
        windowHandle: controller.windowHandle,
        viewHandle: controller.flutterViewHandle,
      );
    }
    return controller;
  }

  @internal
  @override
  SatelliteWindowController createSatelliteWindowController({
    required SatelliteWindowControllerDelegate delegate,
    required BaseWindowController parent,
    required WindowPositioner initialPositioner,
    Rect? initialAnchorRect,
    Size? size,
    BoxConstraints? constraints,
    bool resizable = false,
    String? title,
  }) {
    throw UnimplementedError('Satellite windows are not yet implemented on Linux.');
  }
}

/// Tracks the native GTK windows and Flutter views managed by a
/// [WindowingOwnerLinux], keyed by their [FlutterView.viewId].
///
/// A [WindowingOwnerLinux] uses this registrar to remember the native window
/// and view backing each controller it creates. Out-of-tree owners that
/// subclass [WindowingOwnerLinux] to implement additional window types must
/// register the native window and view they create via [register], and remove
/// them via [unregister] when the window is destroyed. Doing so allows other
/// windows (for example dialogs, popups, and tooltips) to locate a parent
/// window or view by its view ID.
///
/// {@macro flutter.widgets.windowing.experimental}
@internal
class LinuxWindowRegistrar {
  final Map<int, _GtkWindow> _windows = <int, _GtkWindow>{};
  final Map<int, _FlView> _views = <int, _FlView>{};

  /// Registers the native window and view backing the window identified by
  /// [viewId].
  ///
  /// The [windowHandle] must be a pointer to a
  /// [GtkWindow](https://docs.gtk.org/gtk3/class.Window.html) and the
  /// [viewHandle] must be a pointer to an
  /// [FlView](https://github.com/flutter/flutter/blob/main/engine/src/flutter/shell/platform/linux/public/flutter_linux/fl_view.h).
  ///
  /// The handles must remain valid until the window is unregistered via
  /// [unregister].
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void register({
    required int viewId,
    required ffi.Pointer<ffi.Void> windowHandle,
    required ffi.Pointer<ffi.Void> viewHandle,
  }) {
    _windows[viewId] = _GtkWindow.fromHandle(windowHandle);
    _views[viewId] = _FlView.fromHandle(viewHandle);
  }

  /// Registers a GTK4 popover and its Flutter view.
  ///
  /// A popover is a widget-backed transient surface rather than a
  /// [GtkWindow]. It can still host a Flutter view, but cannot parent a
  /// regular or dialog window.
  @internal
  void registerPopover({
    required int viewId,
    required ffi.Pointer<ffi.Void> popoverHandle,
    required ffi.Pointer<ffi.Void> viewHandle,
  }) {
    assert(popoverHandle != ffi.nullptr);
    _views[viewId] = _FlView.fromHandle(viewHandle);
  }

  /// Removes any native window and view registered for [viewId].
  ///
  /// It is permissible to call this method with a [viewId] that has not been
  /// registered, in which case it has no effect.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  void unregister(int viewId) {
    _windows.remove(viewId);
    _views.remove(viewId);
  }

  _GtkWindow? _windowForViewId(int viewId) => _windows[viewId];

  _FlView? _viewForViewId(int viewId) => _views[viewId];
}

///
/// {@macro flutter.widgets.windowing.experimental}
@internal
abstract mixin class BaseWindowControllerLinux {
  WindowingOwnerLinux get _owner;
  FlutterView get rootView;
  _FlView get _view;
  bool get _destroyed;
  set _destroyed(bool value);

  void notifyListeners();

  @internal
  bool get isDestroyed => _destroyed;

  /// Returns a pointer to the underlying GTK host widget.
  ///
  /// This is a `GtkWindow` for regular and dialog controllers. GTK4 tooltip
  /// and popup controllers use `GtkPopover` so their anchors can be placed by
  /// the compositor on Wayland.
  ///
  /// Using this pointer implies the user is aware of any side effects changes may have to Flutter behavior.
  ///
  /// The handle is only valid for the lifetime of the window. Once the window
  /// is destroyed, this handle becomes invalid and must not be used.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  @internal
  ffi.Pointer<ffi.Void> get windowHandle;

  /// Returns pointer to the [FlView](https://github.com/flutter/flutter/blob/main/engine/src/flutter/shell/platform/linux/public/flutter_linux/fl_view.h)
  /// that renders the Flutter content in this window.
  ///
  /// Using this pointer implies the user is aware of any side effects changes may have to Flutter behavior.
  ///
  /// The handle is only valid for the lifetime of the window. Once the window
  /// is destroyed, this handle becomes invalid and must not be used.
  ///
  void _checkNotDestroyed() {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
  }

  void _unregisterAndNotify() {
    _owner.registrar.unregister(rootView.viewId);
    notifyListeners();
  }

  @internal
  ffi.Pointer<ffi.Void> get flutterViewHandle {
    _checkNotDestroyed();
    return _view.instance.cast();
  }
}

/// Shared implementation for regular and dialog windows.
mixin _ToplevelWindowControllerLinux on BaseWindowControllerLinux {
  _GtkWindow get _window;
  _FlViewMonitor get _viewMonitor;
  _FlWindowMonitor get _windowMonitor;
  set _windowMonitor(_FlWindowMonitor monitor);

  void _createToplevelWindowMonitor({
    required VoidCallback onClose,
    required VoidCallback onDestroy,
  }) {
    _windowMonitor = _FlWindowMonitor(
      _window,
      onConfigure: notifyListeners,
      onStateChanged: notifyListeners,
      onIsActiveNotify: notifyListeners,
      onTitleNotify: notifyListeners,
      onClose: onClose,
      onDestroy: onDestroy,
    );
  }

  @internal
  Size get contentSize => _window.getSize();

  void destroy() {
    if (_destroyed) {
      return;
    }
    _viewMonitor.close();
    _viewMonitor.unref();
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      // GTK4 closes windows through close-request. Disconnect the monitor
      // before asking GTK to close so a programmatic destroy does not re-enter
      // the Dart close delegate. GTK3 can retain its destroy signal path.
      _windowMonitor.close();
      _windowMonitor.unref();
      _destroyed = true;
      _window.destroy();
      _onWindowDestroyed();
      _unregisterAndNotify();
      return;
    }
    _window.destroy();
    _windowMonitor.close();
    _windowMonitor.unref();
    _destroyed = true;
    _unregisterAndNotify();
  }

  void _onWindowDestroyed();

  @internal
  String get title => _window.getTitle();

  @internal
  bool get isActivated => _window.isActive();

  @internal
  // NOTE: On Wayland this is never set, see https://gitlab.gnome.org/GNOME/gtk/-/issues/67
  bool get isMinimized => _window.isMinimized();

  @internal
  void setSize(Size size) {
    _window.resize(size.width.toInt(), size.height.toInt());
  }

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

  @internal
  void setTitle(String title) {
    _window.setTitle(title);
  }

  @internal
  void activate() {
    _window.present();
  }

  @internal
  void setMinimized(bool minimized) {
    if (minimized) {
      _window.iconify();
    } else {
      _window.deiconify();
    }
  }

  @override
  ffi.Pointer<ffi.Void> get windowHandle {
    _checkNotDestroyed();
    return _window.instance.cast();
  }
}

/// Shared GTK3 positioning logic for tooltip and popup controllers.
///
/// GTK4 has no [GdkWindow.moveToRect] equivalent. Its controllers use
/// [GtkPopover] positioning in their public [updatePosition] implementations.
mixin _PositionedWindowControllerLinux on BaseWindowControllerLinux {
  _GtkWindow get _window;
  BaseWindowController get _parent;
  Rect get _anchorRect;
  WindowPositioner get _positioner;

  void _updateGtk3Position() {
    final _GtkWindow? parentWindow = _owner.registrar._windowForViewId(_parent.rootView.viewId);
    final _FlView? view = _owner.registrar._viewForViewId(_parent.rootView.viewId);
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

  _GtkPositionType _popoverPosition(
    WindowPositionerAnchor parentAnchor,
    WindowPositionerAnchor childAnchor,
  ) {
    return switch (parentAnchor) {
      WindowPositionerAnchor.top ||
      WindowPositionerAnchor.topLeft ||
      WindowPositionerAnchor.topRight => _GtkPositionType.top,
      WindowPositionerAnchor.bottom ||
      WindowPositionerAnchor.bottomLeft ||
      WindowPositionerAnchor.bottomRight => _GtkPositionType.bottom,
      WindowPositionerAnchor.left => _GtkPositionType.left,
      WindowPositionerAnchor.right => _GtkPositionType.right,
      WindowPositionerAnchor.center => switch (childAnchor) {
        WindowPositionerAnchor.top ||
        WindowPositionerAnchor.topLeft ||
        WindowPositionerAnchor.topRight => _GtkPositionType.bottom,
        WindowPositionerAnchor.bottom ||
        WindowPositionerAnchor.bottomLeft ||
        WindowPositionerAnchor.bottomRight => _GtkPositionType.top,
        WindowPositionerAnchor.left => _GtkPositionType.right,
        WindowPositionerAnchor.right => _GtkPositionType.left,
        WindowPositionerAnchor.center => _GtkPositionType.bottom,
      },
    };
  }
}

/// Shared GTK4 popover presentation lifecycle.
///
/// A Flutter [ViewAnchor] attaches the view during its parent's next frame.
/// Realizing the widgets only after that frame prevents GTK4 from presenting
/// an unparented view.
mixin _Gtk4PopoverWindowControllerLinux on BaseWindowControllerLinux {
  _GtkPopover get _popover;
  _FlView? get _parentView;

  void _showPopover() {
    // Flutter manages focus internally, so the GtkRoot can have no focused
    // widget. GtkPopover's focus traversal assumes one exists when autohide
    // is enabled; use the parent view as its native focus fallback.
    _parentView!.grabFocus();
    _popover.popup();
  }

  void _realizePopoverAfterParentFrame() {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!_destroyed) {
        _popover.realize();
        _view.realize();
      }
    });
  }
}

/// Implementation of [WindowController] for the Linux platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [WindowController], the base class for regular windows.
class WindowControllerLinux extends WindowController
    with BaseWindowControllerLinux, _ToplevelWindowControllerLinux {
  /// Creates a new regular window controller for Linux.
  ///
  /// When this constructor completes the native window has been created and
  /// has a view associated with it.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [WindowController], the base class for regular windows.
  @internal
  WindowControllerLinux({
    required WindowingOwnerLinux owner,
    required WindowControllerDelegate delegate,
    Size? size,
    BoxConstraints? constraints,
    String? title,
    bool decorated = true,
    required bool resizable,
  }) : _owner = owner,
       _delegate = delegate,
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    final _LinuxWindowingWindow createdWindow = _LinuxWindowing.createRegularWindow(
      _FlEngine.current(),
      preferredSize: size,
      preferredConstraints: constraints,
      title: title,
      decorated: decorated,
      resizable: resizable,
    );
    _window = createdWindow.window;
    _view = createdWindow.view;

    _createToplevelWindowMonitor(
      onClose: () {
        _delegate.onWindowCloseRequested(this);
      },
      onDestroy: _delegate.onWindowDestroyed,
    );
    _viewMonitor = _FlViewMonitor(
      _view,
      onFirstFrame: () {
        _window.present();
      },
    );
    // Mapping during this constructor can re-enter Flutter while the root
    // widget tree is being mounted. Schedule it on the next event turn
    // instead. A multi-view root has no mapped view yet, so a post-frame
    // callback would never run to bootstrap this first window.
    Future<void>(() {
      if (!_destroyed) {
        _window.present();
      }
    });
    final int viewId = createdWindow.viewId;
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
  }

  @override
  final WindowingOwnerLinux _owner;
  final WindowControllerDelegate _delegate;
  @override
  late final _GtkWindow _window;
  @override
  late final _FlView _view;
  @override
  late final _FlViewMonitor _viewMonitor;
  @override
  late final _FlWindowMonitor _windowMonitor;
  @override
  bool _destroyed = false;

  @override
  void _onWindowDestroyed() {
    _delegate.onWindowDestroyed();
  }

  @override
  @internal
  bool get isMaximized => _window.isMaximized();

  @override
  @internal
  bool get isFullscreen => _window.isFullscreen();

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
class DialogWindowControllerLinux extends DialogWindowController
    with BaseWindowControllerLinux, _ToplevelWindowControllerLinux {
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
    Size? size,
    BoxConstraints? constraints,
    BaseWindowController? parent,
    String? title,
    bool decorated = true,
    required bool resizable,
  }) : _owner = owner,
       _delegate = delegate,
       _parent = parent,
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    _GtkWindow? parentWindow;
    if (parent != null) {
      parentWindow = owner.registrar._windowForViewId(parent.rootView.viewId);
      if (parentWindow == null) {
        throw Exception('Failed to find dialog parent window');
      }
    }

    final _LinuxWindowingWindow createdWindow = _LinuxWindowing.createDialogWindow(
      _FlEngine.current(),
      parent: parentWindow,
      preferredSize: size,
      preferredConstraints: constraints,
      title: title,
      decorated: decorated,
      resizable: resizable,
    );
    _window = createdWindow.window;
    _view = createdWindow.view;

    _createToplevelWindowMonitor(
      onClose: () {
        _delegate.onWindowCloseRequested(this);
      },
      onDestroy: _delegate.onWindowDestroyed,
    );
    _viewMonitor = _FlViewMonitor(
      _view,
      onFirstFrame: () {
        _window.present();
      },
    );
    // See WindowControllerLinux: defer mapping until the next event turn.
    Future<void>(() {
      if (!_destroyed) {
        _window.present();
      }
    });
    final int viewId = createdWindow.viewId;
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );
  }

  @override
  final WindowingOwnerLinux _owner;
  final DialogWindowControllerDelegate _delegate;
  @override
  late final _GtkWindow _window;
  final BaseWindowController? _parent;
  @override
  late final _FlView _view;
  @override
  late final _FlViewMonitor _viewMonitor;
  @override
  late final _FlWindowMonitor _windowMonitor;
  @override
  bool _destroyed = false;

  @override
  void _onWindowDestroyed() {
    _delegate.onWindowDestroyed();
  }

  @override
  @internal
  BaseWindowController? get parent => _parent;
}

/// Implementation of [TooltipWindowController] for the Linux platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [TooltipWindowController], the base class for tooltip windows.
class TooltipWindowControllerLinux extends TooltipWindowController
    with
        BaseWindowControllerLinux,
        _PositionedWindowControllerLinux,
        _Gtk4PopoverWindowControllerLinux {
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
    required BoxConstraints constraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) : _owner = owner,
       _delegate = delegate,
       _parent = parent,
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    final engine = _FlEngine.current();
    _view = _FlView(engine, isSizedToContent: true);
    final int viewId = _view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );

    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _parentView = _owner.registrar._viewForViewId(_parent.rootView.viewId);
      if (_parentView == null) {
        throw Exception('Failed to find tooltip parent view');
      }
      _popover = _GtkPopover()
        ..setParent(_parentView!)
        ..setChild(_view)
        ..setAutohide(true)
        ..setHasArrow(true);
      _host = _popover;
      _popoverMonitor = _FlPopoverMonitor(_popover, onClosed: _handlePopoverClosed);
    } else {
      _window = _GtkWindow(_GtkWindowType.popup)
        ..setTypeHint(_GdkWindowTypeHint.tooltip)
        ..setDecorated(false)
        // Force creation as Flutter will try and render to it immediately.
        ..realize();
      _host = _window;
      _windowMonitor = _FlWindowMonitor(
        _window,
        onConfigure: notifyListeners,
        onDestroy: _delegate.onWindowDestroyed,
      );
      final _GtkWindow? parentWindow = _owner.registrar._windowForViewId(_parent.rootView.viewId);
      if (parentWindow == null) {
        throw Exception('Failed to find tooltip parent window');
      }
      _window.setTransientFor(parentWindow);
      _window.add(_view);
    }

    setConstraints(constraints);
    _viewMonitor = _FlViewMonitor(
      _view,
      onFirstFrame: () {
        if (_LinuxWindowing.gtkMajorVersion >= 4) {
          _showPopover();
        } else {
          _window.show();
        }
      },
    );
    _view.show();
    updatePosition(anchorRect: anchorRect, positioner: positioner);
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _realizePopoverAfterParentFrame();
    }
  }

  @override
  final WindowingOwnerLinux _owner;
  final TooltipWindowControllerDelegate _delegate;
  @override
  late final _GtkWindow _window;
  @override
  late final _GtkPopover _popover;
  @override
  _FlView? _parentView;
  late final _GtkWidget _host;
  @override
  late Rect _anchorRect;
  @override
  late WindowPositioner _positioner;
  @override
  final BaseWindowController _parent;
  @override
  late final _FlView _view;
  late final _FlViewMonitor _viewMonitor;
  late final _FlWindowMonitor _windowMonitor;
  late final _FlPopoverMonitor _popoverMonitor;
  @override
  bool _destroyed = false;

  @override
  @internal
  bool get isDestroyed => _destroyed;

  @override
  @internal
  Size get contentSize => _host.getSize();

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _disposePopover();
      return;
    }
    _viewMonitor.close();
    _viewMonitor.unref();
    _window.destroy();
    _windowMonitor.close();
    _windowMonitor.unref();
    _destroyed = true;
    _owner.registrar.unregister(rootView.viewId);
    notifyListeners();
  }

  @override
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner}) {
    if (anchorRect != null) {
      _anchorRect = anchorRect;
    }
    if (positioner != null) {
      _positioner = positioner;
    }

    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _popover
        ..setPointingTo(
          Rect.fromLTWH(
            _anchorRect.left + _positioner.offset.dx,
            _anchorRect.top + _positioner.offset.dy,
            _anchorRect.width,
            _anchorRect.height,
          ),
        )
        ..setPosition(_popoverPosition(_positioner.parentAnchor, _positioner.childAnchor));
      return;
    }

    // This is only applied in GTK3 the first time the tooltip is shown as GTK3
    // only sends updates when the popup surface configure event is
    // received. Since GTK3 does not set the [reactive flag](https://wayland.app/protocols/xdg-shell#xdg_positioner:request:set_reactive)
    // on the positioner it is only [received once](https://wayland.app/protocols/xdg-shell#xdg_popup:event:configure).
    // This means if a Linux tooltip is resized it will not be repositioned.
    _updateGtk3Position();
  }

  @override
  @internal
  BaseWindowController get parent => _parent;

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _popover.setSizeRequest(constraints.minWidth.toInt(), constraints.minHeight.toInt());
      return;
    }
    _window.setGeometryHints(
      minWidth: constraints.minWidth.toInt(),
      minHeight: constraints.minHeight.toInt(),
      maxWidth: constraints.maxWidth.isInfinite ? 0x7fffffff : constraints.maxWidth.toInt(),
      maxHeight: constraints.maxHeight.isInfinite ? 0x7fffffff : constraints.maxHeight.toInt(),
    );
  }

  void _handlePopoverClosed() {
    _disposePopover();
  }

  void _disposePopover() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _viewMonitor.close();
    _viewMonitor.unref();
    _popoverMonitor.close();
    _popoverMonitor.unref();
    _popover
      ..popdown()
      ..unparent();
    _delegate.onWindowDestroyed();
    _owner.registrar.unregister(rootView.viewId);
    notifyListeners();
  }

  @override
  ffi.Pointer<ffi.Void> get windowHandle {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
    return _host.instance.cast();
  }

  @override
  ffi.Pointer<ffi.Void> get flutterViewHandle {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
    return _view.instance.cast();
  }
}

/// Implementation of [PopupWindowController] for the Linux platform.
///
/// {@macro flutter.widgets.windowing.experimental}
///
/// See also:
///
///  * [PopupWindowController], the base class for popup windows.
class PopupWindowControllerLinux extends PopupWindowController
    with
        BaseWindowControllerLinux,
        _PositionedWindowControllerLinux,
        _Gtk4PopoverWindowControllerLinux {
  /// Creates a new popup window controller for Linux.
  ///
  /// When this constructor completes the native window has been created and
  /// has a view associated with it.
  ///
  /// {@macro flutter.widgets.windowing.experimental}
  ///
  /// See also:
  ///
  ///  * [PopupWindowController], the base class for popup windows.
  @internal
  PopupWindowControllerLinux({
    required WindowingOwnerLinux owner,
    required PopupWindowControllerDelegate delegate,
    required BoxConstraints constraints,
    required Rect anchorRect,
    required WindowPositioner positioner,
    required BaseWindowController parent,
  }) : _owner = owner,
       _delegate = delegate,
       _parent = parent,
       super.empty() {
    if (!isWindowingEnabled) {
      throw UnsupportedError(_kWindowingDisabledErrorMessage);
    }

    final engine = _FlEngine.current();
    _view = _FlView(engine, isSizedToContent: true);
    final int viewId = _view.getId();
    rootView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
    );

    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _parentView = _owner.registrar._viewForViewId(_parent.rootView.viewId);
      if (_parentView == null) {
        throw Exception('Failed to find popup parent view');
      }
      _popover = _GtkPopover()
        ..setParent(_parentView!)
        ..setChild(_view)
        ..setAutohide(true)
        ..setHasArrow(true);
      _host = _popover;
      _popoverMonitor = _FlPopoverMonitor(_popover, onClosed: _handlePopoverClosed);
    } else {
      _window = _GtkWindow(_GtkWindowType.popup)
        ..setDecorated(false)
        ..realize();
      _host = _window;
      _windowMonitor = _FlWindowMonitor(
        _window,
        onConfigure: notifyListeners,
        onMovedToRect: (x, y, width, height) {
          _offsetFromParent = Offset(x.toDouble(), y.toDouble());
        },
        onDestroy: _delegate.onWindowDestroyed,
      );
      final _GtkWindow? parentWindow = _owner.registrar._windowForViewId(_parent.rootView.viewId);
      if (parentWindow == null) {
        throw Exception('Failed to find popup parent window');
      }
      _window.setTransientFor(parentWindow);
      _window.add(_view);
    }

    setConstraints(constraints);
    _viewMonitor = _FlViewMonitor(
      _view,
      onFirstFrame: () {
        if (_LinuxWindowing.gtkMajorVersion >= 4) {
          _showPopover();
        } else {
          _window.show();
        }
      },
    );
    _view.show();
    updatePosition(anchorRect: anchorRect, positioner: positioner);
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _realizePopoverAfterParentFrame();
    }
  }

  @override
  final WindowingOwnerLinux _owner;
  final PopupWindowControllerDelegate _delegate;
  @override
  late final _GtkWindow _window;
  @override
  late final _GtkPopover _popover;
  @override
  _FlView? _parentView;
  late final _GtkWidget _host;
  @override
  late Rect _anchorRect;
  @override
  late WindowPositioner _positioner;
  @override
  final BaseWindowController _parent;
  @override
  late final _FlView _view;
  late final _FlViewMonitor _viewMonitor;
  late final _FlWindowMonitor _windowMonitor;
  late final _FlPopoverMonitor _popoverMonitor;
  Offset? _offsetFromParent;
  @override
  bool _destroyed = false;

  @override
  @internal
  bool get isDestroyed => _destroyed;

  @override
  @internal
  Size get contentSize => _host.getSize();

  @override
  void destroy() {
    if (_destroyed) {
      return;
    }
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _disposePopover();
      return;
    }
    _viewMonitor.close();
    _viewMonitor.unref();
    _window.destroy();
    _windowMonitor.close();
    _windowMonitor.unref();
    _destroyed = true;
    _owner.registrar.unregister(rootView.viewId);
    notifyListeners();
  }

  @override
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner}) {
    if (anchorRect != null) {
      _anchorRect = anchorRect;
    }
    if (positioner != null) {
      _positioner = positioner;
    }

    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      final pointingTo = Rect.fromLTWH(
        _anchorRect.left + _positioner.offset.dx,
        _anchorRect.top + _positioner.offset.dy,
        _anchorRect.width,
        _anchorRect.height,
      );
      _popover
        ..setPointingTo(pointingTo)
        ..setPosition(_popoverPosition(_positioner.parentAnchor, _positioner.childAnchor));
      _offsetFromParent = pointingTo.topLeft;
      notifyListeners();
      return;
    }

    // This is only applied in GTK3 the first time the popup is shown as GTK3
    // only sends updates when the popup surface configure event is
    // received. Since GTK3 does not set the [reactive flag](https://wayland.app/protocols/xdg-shell#xdg_positioner:request:set_reactive)
    // on the positioner it is only [received once](https://wayland.app/protocols/xdg-shell#xdg_popup:event:configure).
    // This means if a Linux popup is resized it will not be repositioned.
    _updateGtk3Position();
  }

  @override
  Offset get offsetFromParent {
    return _offsetFromParent ?? Offset.zero;
  }

  @override
  @internal
  BaseWindowController get parent => _parent;

  @override
  @internal
  void setConstraints(BoxConstraints constraints) {
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _popover.setSizeRequest(constraints.minWidth.toInt(), constraints.minHeight.toInt());
      return;
    }
    _window.setGeometryHints(
      minWidth: constraints.minWidth.toInt(),
      minHeight: constraints.minHeight.toInt(),
      maxWidth: constraints.maxWidth.isInfinite ? 0x7fffffff : constraints.maxWidth.toInt(),
      maxHeight: constraints.maxHeight.isInfinite ? 0x7fffffff : constraints.maxHeight.toInt(),
    );
  }

  void _handlePopoverClosed() {
    _disposePopover();
  }

  void _disposePopover() {
    if (_destroyed) {
      return;
    }
    _destroyed = true;
    _viewMonitor.close();
    _viewMonitor.unref();
    _popoverMonitor.close();
    _popoverMonitor.unref();
    _popover
      ..popdown()
      ..unparent();
    _delegate.onWindowDestroyed();
    _owner.registrar.unregister(rootView.viewId);
    notifyListeners();
  }

  @override
  ffi.Pointer<ffi.Void> get windowHandle {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
    return _host.instance.cast();
  }

  @override
  ffi.Pointer<ffi.Void> get flutterViewHandle {
    if (_destroyed) {
      throw StateError('Window has been destroyed.');
    }
    return _view.instance.cast();
  }
}

final class _LinuxWindowingWindowResult extends ffi.Struct {
  external ffi.Pointer<ffi.NativeType> window;
  external ffi.Pointer<ffi.NativeType> view;

  @ffi.Int64()
  external int viewId;
}

final class _LinuxWindowingWindow {
  const _LinuxWindowingWindow({required this.window, required this.view, required this.viewId});

  final _GtkWindow window;
  final _FlView view;
  final int viewId;
}

class _LinuxWindowing {
  static int get gtkMajorVersion => _getGtkMajorVersion();

  static _LinuxWindowingWindow createRegularWindow(
    _FlEngine engine, {
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    required bool decorated,
    required bool resizable,
  }) {
    final ffi.Pointer<ffi.Uint8> titleBuffer = title != null ? _stringToNative(title) : ffi.nullptr;
    try {
      return _createWindow(
        _createRegularWindow(
          engine.instance,
          preferredSize != null,
          preferredSize?.width.toInt() ?? 0,
          preferredSize?.height.toInt() ?? 0,
          preferredConstraints != null,
          preferredConstraints?.minWidth.toInt() ?? 0,
          preferredConstraints?.minHeight.toInt() ?? 0,
          preferredConstraints?.maxWidth.isInfinite ?? true
              ? _kMaxWindowDimensions
              : preferredConstraints!.maxWidth.toInt(),
          preferredConstraints?.maxHeight.isInfinite ?? true
              ? _kMaxWindowDimensions
              : preferredConstraints!.maxHeight.toInt(),
          titleBuffer,
          decorated,
          resizable,
        ),
      );
    } finally {
      if (titleBuffer != ffi.nullptr) {
        _gFree(titleBuffer);
      }
    }
  }

  static _LinuxWindowingWindow createDialogWindow(
    _FlEngine engine, {
    _GtkWindow? parent,
    Size? preferredSize,
    BoxConstraints? preferredConstraints,
    String? title,
    required bool decorated,
    required bool resizable,
  }) {
    final ffi.Pointer<ffi.Uint8> titleBuffer = title != null ? _stringToNative(title) : ffi.nullptr;
    try {
      return _createWindow(
        _createDialogWindow(
          engine.instance,
          parent?.instance ?? ffi.nullptr,
          preferredSize != null,
          preferredSize?.width.toInt() ?? 0,
          preferredSize?.height.toInt() ?? 0,
          preferredConstraints != null,
          preferredConstraints?.minWidth.toInt() ?? 0,
          preferredConstraints?.minHeight.toInt() ?? 0,
          preferredConstraints?.maxWidth.isInfinite ?? true
              ? _kMaxWindowDimensions
              : preferredConstraints!.maxWidth.toInt(),
          preferredConstraints?.maxHeight.isInfinite ?? true
              ? _kMaxWindowDimensions
              : preferredConstraints!.maxHeight.toInt(),
          titleBuffer,
          decorated,
          resizable,
        ),
      );
    } finally {
      if (titleBuffer != ffi.nullptr) {
        _gFree(titleBuffer);
      }
    }
  }

  static _LinuxWindowingWindow _createWindow(ffi.Pointer<_LinuxWindowingWindowResult> result) {
    if (result == ffi.nullptr) {
      throw Exception('Linux failed to create a window.');
    }
    try {
      return _LinuxWindowingWindow(
        window: _GtkWindow.fromInstance(result.ref.window),
        view: _FlView.fromInstance(result.ref.view),
        viewId: result.ref.viewId,
      );
    } finally {
      _gFree(result.cast<ffi.NativeType>());
    }
  }

  @ffi.Native<
    ffi.Pointer<_LinuxWindowingWindowResult> Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Bool,
      ffi.Int,
      ffi.Int,
      ffi.Bool,
      ffi.Int,
      ffi.Int,
      ffi.Int,
      ffi.Int,
      ffi.Pointer<ffi.Uint8>,
      ffi.Bool,
      ffi.Bool,
    )
  >(symbol: 'fl_linux_windowing_create_regular_window')
  external static ffi.Pointer<_LinuxWindowingWindowResult> _createRegularWindow(
    ffi.Pointer<ffi.NativeType> engine,
    bool hasPreferredSize,
    int preferredWidth,
    int preferredHeight,
    bool hasPreferredConstraints,
    int minWidth,
    int minHeight,
    int maxWidth,
    int maxHeight,
    ffi.Pointer<ffi.Uint8> title,
    bool decorated,
    bool resizable,
  );

  @ffi.Native<
    ffi.Pointer<_LinuxWindowingWindowResult> Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<ffi.NativeType>,
      ffi.Bool,
      ffi.Int,
      ffi.Int,
      ffi.Bool,
      ffi.Int,
      ffi.Int,
      ffi.Int,
      ffi.Int,
      ffi.Pointer<ffi.Uint8>,
      ffi.Bool,
      ffi.Bool,
    )
  >(symbol: 'fl_linux_windowing_create_dialog_window')
  external static ffi.Pointer<_LinuxWindowingWindowResult> _createDialogWindow(
    ffi.Pointer<ffi.NativeType> engine,
    ffi.Pointer<ffi.NativeType> parent,
    bool hasPreferredSize,
    int preferredWidth,
    int preferredHeight,
    bool hasPreferredConstraints,
    int minWidth,
    int minHeight,
    int maxWidth,
    int maxHeight,
    ffi.Pointer<ffi.Uint8> title,
    bool decorated,
    bool resizable,
  );

  @ffi.Native<ffi.Int Function()>(symbol: 'fl_linux_windowing_get_gtk_major_version')
  external static int _getGtkMajorVersion();
}

// The following classes are thin wrappers around the corresponding GTK/GDK
// objects, with only the methods we need implemented. The method signatures
// and enum values are designed to match the corresponding C APIs as closely
// as possible, to minimize the amount of translation needed in the method
// implementations.

/// The type of a GtkWindow. Matches the GtkWindowType enum in gtk/gtktypes.h.
enum _GtkWindowType {
  // ignore: unused_field
  toplevel,
  // ignore: unused_field
  popup,
}

/// Position of a GTK4 popover relative to its parent widget.
enum _GtkPositionType { left, right, top, bottom }

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
  // ignore: unused_field
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

String? _nativeToString(ffi.Pointer<ffi.Uint8> value) {
  if (value == ffi.nullptr) {
    return null;
  }
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

  /// Gives this widget native GTK focus.
  bool grabFocus() {
    return _gtkWidgetGrabFocus(instance);
  }

  /// Sets [parent] as this widget's parent.
  void setParent(_GtkWidget parent) {
    _gtkWidgetSetParent(instance, parent.instance);
  }

  /// Removes this widget from its parent.
  void unparent() {
    _gtkWidgetUnparent(instance);
  }

  /// Requests a minimum size for this widget.
  void setSizeRequest(int width, int height) {
    _gtkWidgetSetSizeRequest(instance, width, height);
  }

  /// Gets this widget's allocated size.
  Size getSize() {
    return Size(_gtkWidgetGetWidth(instance).toDouble(), _gtkWidgetGetHeight(instance).toDouble());
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
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _gtkWindowClose(instance);
    } else {
      _gtkWidgetDestroy(instance);
    }
  }

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_realize')
  external static void _gtkWidgetRealize(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_show')
  external static void _gtkWidgetShow(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Bool Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_grab_focus')
  external static bool _gtkWidgetGrabFocus(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Pointer<ffi.NativeType>)>(
    symbol: 'gtk_widget_set_parent',
  )
  external static void _gtkWidgetSetParent(
    ffi.Pointer<ffi.NativeType> widget,
    ffi.Pointer<ffi.NativeType> parent,
  );

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_unparent')
  external static void _gtkWidgetUnparent(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Int, ffi.Int)>(
    symbol: 'gtk_widget_set_size_request',
  )
  external static void _gtkWidgetSetSizeRequest(
    ffi.Pointer<ffi.NativeType> widget,
    int width,
    int height,
  );

  @ffi.Native<ffi.Int Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_get_width')
  external static int _gtkWidgetGetWidth(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Int Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_get_height')
  external static int _gtkWidgetGetHeight(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Pointer<ffi.NativeType> Function(ffi.Pointer<ffi.NativeType>)>(
    symbol: 'gtk_widget_get_window',
  )
  external static ffi.Pointer<ffi.NativeType> _gtkWidgetGetWindow(
    ffi.Pointer<ffi.NativeType> widget,
  );

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_destroy')
  external static void _gtkWidgetDestroy(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_close')
  external static void _gtkWindowClose(ffi.Pointer<ffi.NativeType> window);

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

/// Wraps GtkPopover for GTK4 anchored transient surfaces.
class _GtkPopover extends _GtkWidget {
  _GtkPopover() : super(_gtkPopoverNew());

  void setChild(_GtkWidget child) {
    _gtkPopoverSetChild(instance, child.instance);
  }

  void setPointingTo(Rect rect) {
    final ffi.Pointer<_GdkRectangle> nativeRect = _gMalloc0(
      ffi.sizeOf<_GdkRectangle>(),
    ).cast<_GdkRectangle>();
    nativeRect.ref
      ..x = rect.left.round()
      ..y = rect.top.round()
      ..width = rect.width.round()
      ..height = rect.height.round();
    _gtkPopoverSetPointingTo(instance, nativeRect.cast());
    _gFree(nativeRect.cast());
  }

  void setPosition(_GtkPositionType position) {
    _gtkPopoverSetPosition(instance, position.index);
  }

  void setAutohide(bool autohide) {
    _gtkPopoverSetAutohide(instance, autohide);
  }

  void setHasArrow(bool hasArrow) {
    _gtkPopoverSetHasArrow(instance, hasArrow);
  }

  void popup() {
    _gtkPopoverPopup(instance);
  }

  void popdown() {
    _gtkPopoverPopdown(instance);
  }

  @ffi.Native<ffi.Pointer<ffi.NativeType> Function()>(symbol: 'gtk_popover_new')
  external static ffi.Pointer<ffi.NativeType> _gtkPopoverNew();

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Pointer<ffi.NativeType>)>(
    symbol: 'gtk_popover_set_child',
  )
  external static void _gtkPopoverSetChild(
    ffi.Pointer<ffi.NativeType> popover,
    ffi.Pointer<ffi.NativeType> child,
  );

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Pointer<ffi.NativeType>)>(
    symbol: 'gtk_popover_set_pointing_to',
  )
  external static void _gtkPopoverSetPointingTo(
    ffi.Pointer<ffi.NativeType> popover,
    ffi.Pointer<ffi.NativeType> rect,
  );

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Int)>(
    symbol: 'gtk_popover_set_position',
  )
  external static void _gtkPopoverSetPosition(ffi.Pointer<ffi.NativeType> popover, int position);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Bool)>(
    symbol: 'gtk_popover_set_autohide',
  )
  external static void _gtkPopoverSetAutohide(ffi.Pointer<ffi.NativeType> popover, bool autohide);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Bool)>(
    symbol: 'gtk_popover_set_has_arrow',
  )
  external static void _gtkPopoverSetHasArrow(ffi.Pointer<ffi.NativeType> popover, bool hasArrow);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_popover_popup')
  external static void _gtkPopoverPopup(ffi.Pointer<ffi.NativeType> popover);

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_popover_popdown')
  external static void _gtkPopoverPopdown(ffi.Pointer<ffi.NativeType> popover);
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

  /// Creates a wrapper to an existing [GtkWindow] in [instance].
  const _GtkWindow.fromInstance(super.instance);

  /// Wraps an existing GtkWindow pointed to by [handle].
  _GtkWindow.fromHandle(ffi.Pointer<ffi.Void> handle) : super(handle.cast());

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
    return _nativeToString(_gtkWindowGetTitle(instance)) ?? '';
  }

  /// Set the default size of the window.
  void setDefaultSize(int width, int height) {
    _gtkWindowSetDefaultSize(instance, width, height);
  }

  /// Set minimum and maximum size of the window.
  void setGeometryHints({int? minWidth, int? minHeight, int? maxWidth, int? maxHeight}) {
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      // GTK4 removed GdkGeometry. Size requests retain the minimum-size
      // contract; maximum constraints need a GTK4 layout policy and are not
      // representable by a GtkWindow API.
      _gtkWidgetSetSizeRequest(instance, minWidth ?? -1, minHeight ?? -1);
      return;
    }
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
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      _gtkWindowSetDefaultSize(instance, width, height);
    } else {
      _gtkWindowResize(instance, width, height);
    }
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
  @override
  Size getSize() {
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      return Size(
        _gtkWidgetGetWidth(instance).toDouble(),
        _gtkWidgetGetHeight(instance).toDouble(),
      );
    }
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

  bool isMaximized() {
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      return _gtkWindowIsMaximized(instance);
    }
    return getWindow().getState().contains(_GdkWindowState.maximized);
  }

  bool isMinimized() {
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      // GTK4 does not expose an iconified state query. This mirrors Wayland's
      // existing GTK3 behavior, where that state is also unavailable.
      return false;
    }
    return getWindow().getState().contains(_GdkWindowState.iconified);
  }

  bool isFullscreen() {
    if (_LinuxWindowing.gtkMajorVersion >= 4) {
      return _gtkWindowIsFullscreen(instance);
    }
    return getWindow().getState().contains(_GdkWindowState.fullscreen);
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

  @ffi.Native<ffi.Void Function(ffi.Pointer<ffi.NativeType>, ffi.Int, ffi.Int)>(
    symbol: 'gtk_widget_set_size_request',
  )
  external static void _gtkWidgetSetSizeRequest(
    ffi.Pointer<ffi.NativeType> widget,
    int width,
    int height,
  );

  @ffi.Native<ffi.Int Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_get_width')
  external static int _gtkWidgetGetWidth(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Int Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_widget_get_height')
  external static int _gtkWidgetGetHeight(ffi.Pointer<ffi.NativeType> widget);

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

  @ffi.Native<ffi.Bool Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_is_maximized')
  external static bool _gtkWindowIsMaximized(ffi.Pointer<ffi.NativeType> widget);

  @ffi.Native<ffi.Bool Function(ffi.Pointer<ffi.NativeType>)>(symbol: 'gtk_window_is_fullscreen')
  external static bool _gtkWindowIsFullscreen(ffi.Pointer<ffi.NativeType> widget);
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

  /// Creates a wrapper to an existing [FlView] in [instance].
  const _FlView.fromInstance(super.instance);

  /// Wraps an existing FlView pointed to by [handle].
  _FlView.fromHandle(ffi.Pointer<ffi.Void> handle) : super(handle.cast());

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
  factory _FlViewMonitor(
    _FlView view, {
    VoidCallback? onFirstFrame,
    void Function(int width, int height)? onSizeChanged,
  }) {
    void noop() {}
    void noopSizeChanged(int width, int height) {}
    return _FlViewMonitor._internal(
      view.instance,
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onFirstFrame ?? noop),
      ffi.NativeCallable<ffi.Void Function(ffi.Int, ffi.Int)>.isolateLocal(
        onSizeChanged ?? noopSizeChanged,
      ),
    );
  }

  _FlViewMonitor._internal(
    ffi.Pointer<ffi.NativeType> view,
    this._onFirstFrameFunction,
    this._onSizeChangedFunction,
  ) : super(
        _flViewMonitorNew(
          view,
          _onFirstFrameFunction.nativeFunction,
          _onSizeChangedFunction.nativeFunction,
        ),
      );

  final ffi.NativeCallable<ffi.Void Function()> _onFirstFrameFunction;
  final ffi.NativeCallable<ffi.Void Function(ffi.Int, ffi.Int)> _onSizeChangedFunction;

  /// Close all FFI resources used in the monitor.
  void close() {
    _onFirstFrameFunction.close();
    _onSizeChangedFunction.close();
  }

  @ffi.Native<
    ffi.Pointer<ffi.NativeType> Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int, ffi.Int)>>,
    )
  >(symbol: 'fl_view_monitor_new')
  external static ffi.Pointer<ffi.NativeType> _flViewMonitorNew(
    ffi.Pointer<ffi.NativeType> view,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onFirstFrame,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int, ffi.Int)>> onSizeChanged,
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
    void Function(int, int, int, int)? onMovedToRect,
    VoidCallback? onClose,
    VoidCallback? onDestroy,
  }) {
    void noop() {}
    void noopMovedToRect(int x, int y, int width, int height) {}
    return _FlWindowMonitor._internal(
      window.instance,
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onConfigure ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onStateChanged ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onIsActiveNotify ?? noop),
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onTitleNotify ?? noop),
      ffi.NativeCallable<ffi.Void Function(ffi.Int, ffi.Int, ffi.Int, ffi.Int)>.isolateLocal(
        onMovedToRect ?? noopMovedToRect,
      ),
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
    this._onMovedToRectFunction,
    this._onCloseFunction,
    this._onDestroyFunction,
  ) : super(
        _flWindowMonitorNew(
          window,
          _onConfigureFunction.nativeFunction,
          _onStateChangedFunction.nativeFunction,
          _onIsActiveNotifyFunction.nativeFunction,
          _onTitleNotifyFunction.nativeFunction,
          _onMovedToRectFunction.nativeFunction,
          _onCloseFunction.nativeFunction,
          _onDestroyFunction.nativeFunction,
        ),
      );

  final ffi.NativeCallable<ffi.Void Function()> _onConfigureFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onStateChangedFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onIsActiveNotifyFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onTitleNotifyFunction;
  final ffi.NativeCallable<ffi.Void Function(ffi.Int, ffi.Int, ffi.Int, ffi.Int)>
  _onMovedToRectFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onCloseFunction;
  final ffi.NativeCallable<ffi.Void Function()> _onDestroyFunction;

  /// Close all FFI resources used in the monitor.
  void close() {
    _onConfigureFunction.close();
    _onStateChangedFunction.close();
    _onIsActiveNotifyFunction.close();
    _onTitleNotifyFunction.close();
    _onMovedToRectFunction.close();
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
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int, ffi.Int, ffi.Int, ffi.Int)>>,
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
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Int, ffi.Int, ffi.Int, ffi.Int)>>
    onMovedToRect,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onClose,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onDestroy,
  );
}

/// Wraps FlPopoverMonitor (helper object for GTK4 popover dismissal).
class _FlPopoverMonitor extends _GObject {
  factory _FlPopoverMonitor(_GtkPopover popover, {required VoidCallback onClosed}) {
    return _FlPopoverMonitor._internal(
      popover.instance,
      ffi.NativeCallable<ffi.Void Function()>.isolateLocal(onClosed),
    );
  }

  _FlPopoverMonitor._internal(ffi.Pointer<ffi.NativeType> popover, this._onClosedFunction)
    : super(_flPopoverMonitorNew(popover, _onClosedFunction.nativeFunction));

  final ffi.NativeCallable<ffi.Void Function()> _onClosedFunction;

  void close() {
    _onClosedFunction.close();
  }

  @ffi.Native<
    ffi.Pointer<ffi.NativeType> Function(
      ffi.Pointer<ffi.NativeType>,
      ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>>,
    )
  >(symbol: 'fl_popover_monitor_new')
  external static ffi.Pointer<ffi.NativeType> _flPopoverMonitorNew(
    ffi.Pointer<ffi.NativeType> popover,
    ffi.Pointer<ffi.NativeFunction<ffi.Void Function()>> onClosed,
  );
}
