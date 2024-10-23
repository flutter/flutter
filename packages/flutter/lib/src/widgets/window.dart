// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Defines the anchor point for the anchor rectangle or child [Window] when
/// positioning a [Window]. The specified anchor is used to derive an anchor
/// point on the anchor rectangle that the anchor point for the child [Window]
/// will be positioned relative to. If a corner anchor is set (e.g. [topLeft]
/// or [bottomRight]), the anchor point will be at the specified corner;
/// otherwise, the derived anchor point will be centered on the specified edge,
/// or in the center of the anchor rectangle if no edge is specified.
enum WindowPositionerAnchor {
  /// If the [WindowPositioner.parentAnchor] is set to [center], then the
  /// child [Window] will be positioned relative to the center
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [center], then the middle
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  center,

  /// If the [WindowPositioner.parentAnchor] is set to [top], then the
  /// child [Window] will be positioned relative to the top
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [top], then the top
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  top,

  /// If the [WindowPositioner.parentAnchor] is set to [bottom], then the
  /// child [Window] will be positioned relative to the bottom
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [bottom], then the bottom
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  bottom,

  /// If the [WindowPositioner.parentAnchor] is set to [left], then the
  /// child [Window] will be positioned relative to the left
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [left], then the left
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  left,

  /// If the [WindowPositioner.parentAnchor] is set to [right], then the
  /// child [Window] will be positioned relative to the right
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [right], then the right
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  right,

  /// If the [WindowPositioner.parentAnchor] is set to [topLeft], then the
  /// child [Window] will be positioned relative to the top left
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [topLeft], then the top left
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  topLeft,

  /// If the [WindowPositioner.parentAnchor] is set to [bottomLeft], then the
  /// child [Window] will be positioned relative to the bottom left
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [bottomLeft], then the bottom left
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  bottomLeft,

  /// If the [WindowPositioner.parentAnchor] is set to [topRight], then the
  /// child [Window] will be positioned relative to the top right
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [topRight], then the top right
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  topRight,

  /// If the [WindowPositioner.parentAnchor] is set to [bottomRight], then the
  /// child [Window] will be positioned relative to the bottom right
  /// of the parent [Window].
  ///
  /// If [WindowPositioner.childAnchor] is set to  [bottomRight], then the bottom right
  /// of the child [Window] will be positioned relative to
  /// [WindowPositioner.parentAnchor].
  bottomRight,
}

/// The [WindowPositionerConstraintAdjustment] value defines the ways in which
/// Flutter will adjust the position of the [Window], if the unadjusted position would result
/// in the surface being partly constrained.
///
/// Whether a [Window] is considered 'constrained' is left to the platform
/// to determine. For example, the surface may be partly outside the
/// compositor's defined 'work area', thus necessitating the child [Window]'s
/// position be adjusted until it is entirely inside the work area.
///
/// 'Flip' means reverse the anchor points and offset along an axis.
/// 'Slide' means adjust the offset along an axis.
/// 'Resize' means adjust the client [Window] size along an axis.
///
/// The adjustments can be combined, according to a defined precedence: 1)
/// Flip, 2) Slide, 3) Resize.
enum WindowPositionerConstraintAdjustment {
  /// If [slideX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the X-axis, then it will be
  /// translated in the X-direction (either negative or positive) in order
  /// to best display the window on screen.
  slideX,

  /// If [slideY] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the Y-axis, then it will be
  /// translated in the Y-direction (either negative or positive) in order
  /// to best display the window on screen.
  slideY,

  /// If [flipX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the X-axis in one direction, then
  /// it will be flipped to the opposite side of its parent in order to show
  /// to best display the window on screen.
  flipX,

  /// If [flipY] is specified in [WindowPositioner.constraintAdjustment]
  /// and then [Window] would be displayed off the screen in the Y-axis in one direction, then
  /// it will be flipped to the opposite side of its parent in order to show
  /// it on screen.
  flipY,

  /// If [resizeX] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the X-axis, then
  /// its width will be reduced such that it fits on screen.
  resizeX,

  /// If [resizeY] is specified in [WindowPositioner.constraintAdjustment]
  /// and the [Window] would be displayed off the screen in the Y-axis, then
  /// its height will be reduced such that it fits on screen.
  resizeY,
}

/// Defines the type of a [Window]
enum WindowArchetype {
  /// Defines a standard [Window]
  regular,

  /// Defines a [Window] that is on a layer above [regular] [Window]s and is not dockable
  floatingRegular,

  /// Defines a dialog [Window]
  dialog,

  /// Defines a satellite [Window]
  satellite,

  /// Defines a popup [Window]
  popup,

  /// Defines a tooltip
  tip,
}

/// The [WindowPositioner] provides a collection of rules for the placement
/// of a child [Window] relative to a parent [Window]. Rules can be defined to ensure
/// the child [Window] remains within the visible area's borders, and to
/// specify how the child [Window] changes its position, such as sliding along
/// an axis, or flipping around a rectangle.
class WindowPositioner {
  /// Const constructor for [WindowPositioner].
  const WindowPositioner({
    this.parentAnchor = WindowPositionerAnchor.center,
    this.childAnchor = WindowPositionerAnchor.center,
    this.offset = Offset.zero,
    this.constraintAdjustment = const <WindowPositionerConstraintAdjustment>{},
  });

  /// Copy a [WindowPositioner] with some fields replaced.
  WindowPositioner copyWith({
    WindowPositionerAnchor? parentAnchor,
    WindowPositionerAnchor? childAnchor,
    Offset? offset,
    Set<WindowPositionerConstraintAdjustment>? constraintAdjustment,
  }) {
    return WindowPositioner(
      parentAnchor: parentAnchor ?? this.parentAnchor,
      childAnchor: childAnchor ?? this.childAnchor,
      offset: offset ?? this.offset,
      constraintAdjustment: constraintAdjustment ?? this.constraintAdjustment,
    );
  }

  /// Defines the anchor point for the anchor rectangle. The specified anchor
  /// is used to derive an anchor point that the child [Window] will be
  /// positioned relative to. If a corner anchor is set (e.g. [topLeft] or
  /// [bottomRight]), the anchor point will be at the specified corner;
  /// otherwise, the derived anchor point will be centered on the specified
  /// edge, or in the center of the anchor rectangle if no edge is specified.
  final WindowPositionerAnchor parentAnchor;

  /// Defines the anchor point for the child [Window]. The specified anchor
  /// is used to derive an anchor point that will be positioned relative to the
  /// parentAnchor. If a corner anchor is set (e.g. [topLeft] or
  /// [bottomRight]), the anchor point will be at the specified corner;
  /// otherwise, the derived anchor point will be centered on the specified
  /// edge, or in the center of the anchor rectangle if no edge is specified.
  final WindowPositionerAnchor childAnchor;

  /// Specify the [Window] position offset relative to the position of the
  /// anchor on the anchor rectangle and the anchor on the child. For
  /// example if the anchor of the anchor rectangle is at (x, y), the [Window]
  /// has the child_anchor [topLeft], and the offset is (ox, oy), the calculated
  /// [Window] position will be (x + ox, y + oy). The offset position of the
  /// [Window] is the one used for constraint testing. See constraintAdjustment.
  ///
  /// An example use case is placing a popup menu on top of a user interface
  /// element, while aligning the user interface element of the parent [Window]
  /// with some user interface element placed somewhere in the popup [Window].
  final Offset offset;

  /// The constraintAdjustment value define ways Flutter will adjust
  /// the position of the [Window], if the unadjusted position would result
  /// in the surface being partly constrained.
  ///
  /// Whether a [Window] is considered 'constrained' is left to the platform
  /// to determine. For example, the surface may be partly outside the
  /// output's 'work area', thus necessitating the child [Window]'s
  /// position be adjusted until it is entirely inside the work area.
  ///
  /// The adjustments can be combined, according to a defined precedence: 1)
  /// Flip, 2) Slide, 3) Resize.
  final Set<WindowPositionerConstraintAdjustment> constraintAdjustment;
}

class WindowChangedEvent {
  WindowChangedEvent({this.size});
  Size? size;
}

class _WindowMetadata {
  _WindowMetadata(
      {required this.flView,
      required this.archetype,
      required this.size,
      this.parent});

  final FlutterView flView;
  final WindowArchetype archetype;
  final Size size;
  final Window? parent;
}

/// Defines a [Window] created by the application. To use [Window]s, you must wrap
/// your application in the [MultiWindowApp] widget. New [Window]s are created via
/// global functions like [createRegular] and [createPopup].
abstract class Window {
  /// [view] the underlying [FlutterView]
  /// [builder] render function containing the content of this [Window]
  /// [size] initial [Size] of the [Window]
  /// [parent] the parent of this window, if any
  Window({required this.view, required this.builder, required this.size});

  /// The underlying [FlutterView] associated with this [Window]
  final FlutterView view;

  /// The render function containing the content of this [Window]
  final Widget Function(BuildContext context) builder;

  /// The current [Size] of the [Window]
  Size size;

  /// A list of child [Window]s associated with this window
  final List<Window> children = <Window>[];

  UniqueKey _key = UniqueKey();

  bool canBeParentOf(WindowArchetype archetype) {
    final Map<WindowArchetype, List<WindowArchetype>> compatibilityMap = {
      WindowArchetype.popup: [
        WindowArchetype.regular,
        WindowArchetype.floatingRegular,
        WindowArchetype.dialog,
        WindowArchetype.satellite,
        WindowArchetype.popup,
      ],
      WindowArchetype.dialog: [
        WindowArchetype.regular,
        WindowArchetype.floatingRegular,
        WindowArchetype.dialog,
        WindowArchetype.satellite,
      ],
      WindowArchetype.satellite: [
        WindowArchetype.regular,
        WindowArchetype.floatingRegular,
        WindowArchetype.dialog,
      ],
      // TODO: Handle remaining archetypes
    };

    final List<WindowArchetype>? compatibleParentArchetypes =
        compatibilityMap[archetype];

    if (compatibleParentArchetypes == null) {
      return false;
    }

    bool hasDialogDescendant(Window window) {
      if (window.children
          .any((child) => child.archetype == WindowArchetype.dialog)) {
        return true;
      }
      for (Window child in window.children) {
        if (hasDialogDescendant(child)) {
          return true;
        }
      }
      return false;
    }

    final Window window;
    if (this.archetype == WindowArchetype.satellite) {
      assert(parent != null, 'Parent must not be null for satellite windows.');
      window = parent!;
    } else {
      window = this;
    }

    return compatibleParentArchetypes.contains(this.archetype) &&
        !hasDialogDescendant(window);
  }

  final StreamController<void> _onDestroyedController =
      StreamController<void>.broadcast();
  final StreamController<WindowChangedEvent> _onWindowChangedController =
      StreamController<WindowChangedEvent>.broadcast();

  Stream<void> get destroyedStream {
    return _onDestroyedController.stream;
  }

  Stream<WindowChangedEvent> get changedStream {
    return _onWindowChangedController.stream;
  }

  WindowArchetype get archetype;
  Window? get parent;
}

/// Describes a top level window that is created with [createRegular].
class RegularWindow extends Window {
  /// [view] the underlying [FlutterView]
  /// [builder] render function containing the content of this [Window]
  /// [size] initial [Size] of the [Window]
  RegularWindow(
      {required super.view, required super.builder, required super.size});

  @override
  WindowArchetype get archetype {
    return WindowArchetype.regular;
  }

  @override
  Window? get parent {
    return null;
  }
}

class PopupWindow extends Window {
  PopupWindow(
      {required super.view,
      required super.builder,
      required super.size,
      required Window parentWindow})
      : _parent = parentWindow;

  final Window _parent;

  @override
  WindowArchetype get archetype {
    return WindowArchetype.popup;
  }

  @override
  Window? get parent {
    return _parent;
  }
}

/// Creates a new regular [Window].
///
/// [context] the current [BuildContext], which must include a [MultiWindowAppContext]
/// [size] the size of the new [Window] in pixels
/// [builder] a builder function that returns the contents of the new [Window]
Future<RegularWindow> createRegular(
    {required BuildContext context,
    required Size size,
    required WidgetBuilder builder}) async {
  final MultiWindowAppContext? multiViewAppContext =
      MultiWindowAppContext.of(context);
  if (multiViewAppContext == null) {
    throw Exception(
        'Cannot create a window: your application does not use MultiViewApp. Try wrapping your toplevel application in a MultiViewApp widget');
  }

  return multiViewAppContext.windowController
      .createRegular(size: size, builder: builder);
}

/// Creates a new popup [Window]
///
/// [context] the current [BuildContext], which must include a [MultiWindowAppContext]
/// [parent] the [Window] to which this popup is associated
/// [size] the [Size] of the popup
/// [anchorRect] the [Rect] to which this popup is anchored, relative to the
///              client area of the parent [Window]. If null, the popup is
///              anchored to the window frame of the parent [Window].
/// [positioner] defines the constraints by which the popup is positioned
/// [builder] a builder function that returns the contents of the new [Window]
Future<PopupWindow> createPopup(
    {required BuildContext context,
    required Window parent,
    required Size size,
    Rect? anchorRect,
    required WindowPositioner positioner,
    required WidgetBuilder builder}) async {
  final MultiWindowAppContext? multiViewAppContext =
      MultiWindowAppContext.of(context);
  if (multiViewAppContext == null) {
    throw Exception(
        'Cannot create a window: your application does not use MultiViewApp. Try wrapping your toplevel application in a MultiViewApp widget');
  }

  return multiViewAppContext.windowController.createPopup(
      parent: parent,
      size: size,
      anchorRect: anchorRect,
      positioner: positioner,
      builder: builder);
}

/// Destroys the provided [Window]
///
/// [context] the current [BuildContext], which must include a [MultiWindowAppContext]
/// [window] the [Window] to be destroyed
Future<void> destroyWindow(BuildContext context, Window window) async {
  final MultiWindowAppContext? multiViewAppContext =
      MultiWindowAppContext.of(context);
  if (multiViewAppContext == null) {
    throw Exception(
        'Cannot create a window: your application does not use MultiViewApp. Try wrapping your toplevel application in a MultiViewApp widget');
  }

  return multiViewAppContext.windowController.destroyWindow(window);
}

/// Declares that an application will create multiple [Window]s.
/// The current [Window] can be looked up with [WindowContext.of].
class MultiWindowApp extends StatefulWidget {
  /// [initialWindows] A list of [Function]s to create [Window]s that will be run as soon as the app starts.
  const MultiWindowApp({super.key, this.initialWindows});

  /// A list of [Function]s to create [Window]s that will be run as soon as the app starts.
  final List<Future<Window> Function(BuildContext)>? initialWindows;

  @override
  State<MultiWindowApp> createState() => WindowController();
}

/// Provides methods to create, update, and delete [Window]s. It is preferred that
/// you use the global functions like [createRegular] and [destroyWindow] over
/// accessing the [WindowController] directly.
class WindowController extends State<MultiWindowApp> {
  List<Window> _windows = <Window>[];

  @override
  void initState() {
    super.initState();
    SystemChannels.windowing.setMethodCallHandler(_methodCallHandler);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    final Map<Object?, Object?> arguments =
        call.arguments as Map<Object?, Object?>;

    switch (call.method) {
      case 'onWindowChanged':
        final int viewId = arguments['viewId']! as int;
        final Window? window = _findWindow(viewId);
        assert(window != null);
        Size? size;
        if (arguments['size'] != null) {
          final List<Object?> sizeRaw = arguments['size']! as List<Object?>;
          size = Size(
              (sizeRaw[0]! as int).toDouble(), (sizeRaw[1]! as int).toDouble());
        }
        _changed(window!, size);
      case 'onWindowDestroyed':
        final int viewId = arguments['viewId']! as int;
        _remove(viewId);
    }
  }

  Future<_WindowMetadata> _createWindow(
      {required Future<Map<Object?, Object?>> Function(MethodChannel channel)
          viewBuilder,
      required WidgetBuilder builder}) async {
    final Map<Object?, Object?>? creationData =
        await viewBuilder(SystemChannels.windowing);
    final int viewId = creationData!['viewId']! as int;
    final WindowArchetype archetype =
        WindowArchetype.values[creationData['archetype']! as int];
    final List<Object?> size = creationData['size']! as List<Object?>;
    final int? parentViewId = creationData['parentViewId'] as int?;

    final FlutterView flView =
        WidgetsBinding.instance.platformDispatcher.views.firstWhere(
      (FlutterView view) => view.viewId == viewId,
      orElse: () {
        throw Exception('No matching view found for viewId: $viewId');
      },
    );

    Window? parent;
    if (parentViewId != null) {
      parent = _findWindow(parentViewId);
      assert(parent != null,
          'No matching window found for parentViewId: $parentViewId');
    }

    return _WindowMetadata(
        flView: flView,
        archetype: archetype,
        size: Size((size[0]! as int).toDouble(), (size[1]! as int).toDouble()),
        parent: parent);
  }

  /// Creates a new regular [Window]
  ///
  /// [size] the size of the new [Window] in pixels
  /// [builder] a builder function that returns the contents of the new [Window]
  Future<RegularWindow> createRegular(
      {required Size size, required WidgetBuilder builder}) async {
    final _WindowMetadata metadata = await _createWindow(
        viewBuilder: (MethodChannel channel) async {
          return await channel.invokeMethod('createWindow', <String, dynamic>{
            'size': <int>[size.width.toInt(), size.height.toInt()],
          }) as Map<Object?, Object?>;
        },
        builder: builder);
    final RegularWindow window = RegularWindow(
        view: metadata.flView, builder: builder, size: metadata.size);
    _add(window);
    return window;
  }

  /// Creates a new popup [Window]
  ///
  /// [parent] the [Window] to which this popup is associated
  /// [size] the [Size] of the popup
  /// [anchorRect] the [Rect] to which this popup is anchored, relative to the
  ///              client area of the parent [Window]. If null, the popup is
  ///              anchored to the window frame of the parent [Window].
  /// [positioner] defines the constraints by which the popup is positioned
  /// [builder] a builder function that returns the contents of the new [Window]
  Future<PopupWindow> createPopup(
      {required Window parent,
      required Size size,
      Rect? anchorRect,
      required WindowPositioner positioner,
      required WidgetBuilder builder}) async {
    if (!parent.canBeParentOf(WindowArchetype.popup)) {
      throw ArgumentError(
          'Incompatible parent window. The parent window must have one of '
          'the following archetypes: WindowArchetype.regular, '
          'WindowArchetype.floatingRegular, WindowArchetype.dialog, '
          'WindowArchetype.satellite, or WindowArchetype.popup. Additionally, '
          'if the parent is a satellite window, its closest non-satellite '
          'ancestor must not have any dialog descendants. If the parent is not '
          'a satellite, it must not have any dialog descendants itself.');
    }

    int constraintAdjustmentBitmask = 0;
    for (final WindowPositionerConstraintAdjustment adjustment
        in positioner.constraintAdjustment) {
      constraintAdjustmentBitmask |= 1 << adjustment.index;
    }

    final _WindowMetadata metadata = await _createWindow(
        viewBuilder: (MethodChannel channel) async {
          return await channel.invokeMethod('createPopup', <String, dynamic>{
            'parent': parent.view.viewId,
            'size': <int>[size.width.toInt(), size.height.toInt()],
            'anchorRect': anchorRect != null
                ? [
                    anchorRect.left.toInt(),
                    anchorRect.top.toInt(),
                    anchorRect.width.toInt(),
                    anchorRect.height.toInt()
                  ]
                : null,
            'positionerParentAnchor': positioner.parentAnchor.index,
            'positionerChildAnchor': positioner.childAnchor.index,
            'positionerOffset': <int>[
              positioner.offset.dx.toInt(),
              positioner.offset.dy.toInt()
            ],
            'positionerConstraintAdjustment': constraintAdjustmentBitmask
          }) as Map<Object?, Object?>;
        },
        builder: builder);

    final PopupWindow window = PopupWindow(
        view: metadata.flView,
        builder: builder,
        size: metadata.size,
        parentWindow: metadata.parent!);
    _add(window);
    return window;
  }

  /// Destroys the provided [Window]
  ///
  /// [window] the [Window] to be destroyed
  Future<void> destroyWindow(Window window) async {
    try {
      await SystemChannels.windowing.invokeMethod(
          'destroyWindow', <String, dynamic>{'viewId': window.view.viewId});
      _remove(window.view.viewId);
    } on PlatformException catch (e) {
      throw ArgumentError(
          'Unable to delete window with view_id=${window.view.viewId}. Does the window exist? Error: $e');
    }
  }

  void _add(Window window) {
    final List<Window> copy = List<Window>.from(_windows);
    if (window.parent != null) {
      window.parent!.children.add(window);
      Window rootWindow = window;
      while (rootWindow.parent != null) {
        rootWindow = rootWindow.parent!;
      }
      rootWindow._key = UniqueKey();
    } else {
      copy.add(window);
    }

    setState(() {
      _windows = copy;
    });
  }

  Window? _findWindow(int viewId) {
    Window? find(int viewId, Window window) {
      if (window.view.viewId == viewId) {
        return window;
      }

      for (final Window other in window.children) {
        final Window? result = find(viewId, other);
        if (result != null) {
          return result;
        }
      }

      return null;
    }

    for (final Window other in _windows) {
      final Window? result = find(viewId, other);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  void _remove(int viewId) {
    final List<Window> copy = List<Window>.from(_windows);

    final Window? toDelete = _findWindow(viewId);
    if (toDelete == null) {
      return;
    }

    if (toDelete.parent == null) {
      copy.remove(toDelete);
    } else {
      toDelete.parent!.children.remove(toDelete);
    }

    toDelete._onDestroyedController.add(null);

    setState(() {
      _windows = copy;
    });
  }

  void _changed(Window window, Size? size) {
    if (size != null) {
      window.size = size;
      window._onWindowChangedController.add(WindowChangedEvent(size: size));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiWindowAppContext(
        windows: _windows,
        windowController: this,
        child: _MultiWindowAppView(
            initialWindows: widget.initialWindows, windows: _windows));
  }
}

/// Provides access to the list of [Window]s.
/// Users may provide the identifier of a [View] to look up a particular
/// [Window] if any exists.
///
/// This class also provides access to the [WindowController] which is
/// used internally to provide access to create, update, and delete methods
/// on the windowing system.
class MultiWindowAppContext extends InheritedWidget {
  /// [windows] a list of [Window]s
  /// [windowController] the [WindowController] active in this context
  const MultiWindowAppContext(
      {super.key,
      required super.child,
      required this.windows,
      required this.windowController});

  /// The list of Windows
  final List<Window> windows;

  /// The [WindowController] active in this context
  final WindowController windowController;

  /// Returns the [MultiWindowAppContext] if any
  static MultiWindowAppContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MultiWindowAppContext>();
  }

  @override
  bool updateShouldNotify(MultiWindowAppContext oldWidget) {
    return windows != oldWidget.windows ||
        windowController != oldWidget.windowController;
  }
}

class _MultiWindowAppView extends StatefulWidget {
  const _MultiWindowAppView(
      {required this.initialWindows, required this.windows});

  final List<Future<Window> Function(BuildContext)>? initialWindows;
  final List<Window> windows;

  @override
  State<StatefulWidget> createState() => _MultiWindowAppViewState();
}

class _MultiWindowAppViewState extends State<_MultiWindowAppView> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.initialWindows != null) {
        for (final Future<Window> Function(BuildContext) window
            in widget.initialWindows!) {
          await window(context);
        }
      }
    });
  }

  Widget buildView(BuildContext context, Window window) {
    return View(
        key: window._key,
        view: window.view,
        child: WindowContext(window: window, child: window.builder(context)));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> views = <Widget>[];
    for (final Window window in widget.windows) {
      views.add(buildView(context, window));
    }
    return ViewCollection(views: views);
  }
}

/// Provides descendents with access to the [Window] in which they are rendered
class WindowContext extends InheritedWidget {
  /// [window] the [Window]
  const WindowContext({super.key, required this.window, required super.child});

  /// The [Window] in this context
  final Window window;

  /// Returns the [WindowContext] if any
  static WindowContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WindowContext>();
  }

  @override
  bool updateShouldNotify(WindowContext oldWidget) {
    return window != oldWidget.window;
  }
}
