// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Defines the type of the Window
enum WindowArchetype {
  /// Defines a traditional window
  regular,

  /// Defines a popup window
  popup,
}

/// Defines the possible states a window can be in.
enum WindowState {
  /// Window is in its normal state, neither maximized, nor minimized.
  restored,

  /// Window is maximized, occupying the full screen but still showing the system UI.
  maximized,

  /// Window is minimized and not visible on the screen.
  minimized,
}

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

/// Controller used with the [RegularWindow] widget. This controller
/// provides access to modify and destroy the window, in addition to
/// listening to changes on the window.
abstract class WindowController with ChangeNotifier {
  WindowController._({
    VoidCallback? onDestroyed,
    void Function(String)? onError,
    required Future<_WindowCreationResult> future,
  }) : _future = future {
    _future
        .then((_WindowCreationResult metadata) async {
          _view = metadata.view;
          _state = metadata.state;
          _size = metadata.size;
          notifyListeners();

          SchedulerBinding.instance.addPostFrameCallback((_) async {
            _listener = _WindowListener(
              viewId: metadata.view.viewId,
              onChanged: (_WindowChangeProperties properties) {
                if (properties.size != null) {
                  _size = properties.size!;
                  notifyListeners();
                }
              },
              onDestroyed: () {
                _view = null;
                _isPendingDestroy = false;
                notifyListeners();
                onDestroyed?.call();
              },
            );
            _WindowingAppGlobalData.instance._listen(_listener);
          });
        })
        .catchError((Object? error) {
          onError?.call(error.toString());
        });
  }

  /// Returns true if the window associated with the controller has been
  /// created and is ready to be used. Otherwise, returns false.
  bool get isReady => _view != null;

  final Future<_WindowCreationResult> _future;

  late _WindowListener _listener;

  /// The ID of the view used for this window, which is unique to each window.
  FlutterView get view => _view!;
  FlutterView? _view;

  /// The current size of the window. This may differ from the requested size.
  Size get size => _size;
  Size _size = Size.zero;

  /// The current state of the window.
  WindowState? get state => _state;
  WindowState? _state;

  /// The archetype of the window.
  WindowArchetype get type;

  bool _isPendingDestroy = false;

  /// Destroys this window.
  Future<void> destroy() async {
    if (!isReady || _isPendingDestroy) {
      return;
    }

    _isPendingDestroy = true;
    return _destroyWindow(view.viewId);
  }
}

/// Provided to [RegularWindow]. When this controller is initialized, a
/// native window is created for the current platform. This controller
/// can then be used to modify the window, listen to changes, or destroy
/// the window.
class RegularWindowController extends WindowController {
  /// Creates a [RegularWindowController] with the provided properties.
  /// Upon construction, the window is created for the platform.
  ///
  /// [title] the title of the window
  /// [state] the initial state of the window
  /// [sizeConstraints] the size constraints of the window
  /// [onDestroyed] a callback that is called when the window is destroyed
  /// [onError] a callback that is called when an error is encountered
  /// [size] the size of the window
  RegularWindowController({
    String? title,
    WindowState? state,
    BoxConstraints? sizeConstraints,
    VoidCallback? onDestroyed,
    void Function(String)? onError,
    required Size size,
  }) : super._(
         onDestroyed: onDestroyed,
         onError: onError,
         future: _createRegular(
           size: size,
           sizeConstraints: sizeConstraints,
           title: title,
           state: state,
         ),
       );

  @override
  WindowArchetype get type => WindowArchetype.regular;

  /// Modify the properties of the window.
  Future<void> modify({Size? size}) {
    throw UnimplementedError();
  }
}

abstract class ChildWindowController extends WindowController {
  ChildWindowController._({
    VoidCallback? onDestroyed,
    void Function(String)? onError,
    required Future<_WindowCreationResult> future,
  }) : super._(onDestroyed: onDestroyed, onError: onError, future: future);

  FlutterView get parent;
}

class PopupWindowController extends ChildWindowController {
  PopupWindowController({
    VoidCallback? onDestroyed,
    void Function(String)? onError,
    Rect? anchorRect,
    WindowPositioner positioner = const WindowPositioner(),
    required FlutterView parent,
    required Size size,
  }) : _parent = parent,
       super._(
         onDestroyed: onDestroyed,
         onError: onError,
         future: _createPopup(
           parentViewId: parent.viewId,
           size: size,
           anchorRect: anchorRect,
           positioner: positioner,
         ),
       );

  final FlutterView _parent;

  @override
  WindowArchetype get type => WindowArchetype.popup;

  @override
  FlutterView get parent => _parent;
}

class _Window extends StatefulWidget {
  /// Creates a regular window widget
  const _Window({super.key, required this.controller, required this.child});

  final WindowController controller;
  final Widget child;

  @override
  State<_Window> createState() => _WindowState();
}

class _WindowState extends State<_Window> {
  @override
  Future<void> dispose() async {
    super.dispose();

    if (widget.controller.isReady && !widget.controller._isPendingDestroy) {
      await widget.controller.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WindowCreationResult>(
      key: widget.key,
      future: widget.controller._future,
      builder: (BuildContext context, AsyncSnapshot<_WindowCreationResult> metadata) {
        if (!metadata.hasData) {
          return const ViewCollection(views: <Widget>[]);
        }

        return View(
          view: metadata.data!.view,
          child: WindowControllerContext(controller: widget.controller, child: widget.child),
        );
      },
    );
  }
}

/// A widget that creates a regular window. This content of this window is
/// rendered into a [View], meaning that this widget must be rendered into
/// either a [ViewAnchor] or a [ViewCollection].
class RegularWindow extends StatelessWidget {
  /// Creates a regular window widget
  const RegularWindow({super.key, required this.controller, required this.child});

  /// Controller for this widget.
  final RegularWindowController controller;

  /// The content rendered into this window.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Window(key: key, controller: controller, child: child);
  }
}

/// A widget that creates a popup window. This content of this window is
/// rendered into a [View], meaning that this widget must be rendered into
/// either a [ViewAnchor] or a [ViewCollection].
class PopupWindow extends StatelessWidget {
  /// Creates a regular window widget
  const PopupWindow({super.key, required this.controller, required this.child});

  /// Controller for this widget.
  final PopupWindowController controller;

  /// The content rendered into this window.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Window(key: key, controller: controller, child: child);
  }
}

/// Provides descendents with access to the [WindowController] in which
/// they are being rendered
class WindowControllerContext extends InheritedWidget {
  /// Creates a new [WindowControllerContext]
  /// [controller] the controller associated with this window
  /// [child] the child widget
  const WindowControllerContext({super.key, required this.controller, required super.child});

  /// The controller associated with this window.
  final WindowController controller;

  /// Returns the [WindowContext] if any
  static WindowControllerContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WindowControllerContext>();
  }

  @override
  bool updateShouldNotify(WindowControllerContext oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// The raw data returned as a result of creating a window.
class _WindowCreationResult {
  /// Creates a new window.
  _WindowCreationResult({
    required this.view,
    required this.archetype,
    required this.size,
    this.state,
    this.parent,
  });

  /// The view associated with the window.
  final FlutterView view;

  /// The archetype of the window.
  final WindowArchetype archetype;

  /// The initial size of the window.
  final Size size;

  /// The initial state of the window.
  /// Used by WindowArchetype.regular.
  final WindowState? state;

  /// The id of the window's parent, if any.
  final int? parent;
}

Future<_WindowCreationResult> _createRegular({
  required Size size,
  BoxConstraints? sizeConstraints,
  String? title,
  WindowState? state,
}) {
  return _createWindow(
    archetype: WindowArchetype.regular,
    viewBuilder: (MethodChannel channel) async {
      return await channel.invokeMethod('createWindow', <String, dynamic>{
            'size': <double>[size.width, size.height],
            'minSize':
                sizeConstraints != null
                    ? <double>[sizeConstraints.minWidth, sizeConstraints.minHeight]
                    : null,
            'maxSize':
                sizeConstraints != null
                    ? <double>[sizeConstraints.maxWidth, sizeConstraints.maxHeight]
                    : null,
            'title': title,
            'state': state?.toString(),
          })
          as Map<Object?, Object?>;
    },
  );
}

Future<_WindowCreationResult> _createPopup({
  required int parentViewId,
  required Size size,
  Rect? anchorRect,
  required WindowPositioner positioner,
}) {
  int constraintAdjustmentBitmask = 0;
  for (final WindowPositionerConstraintAdjustment adjustment in positioner.constraintAdjustment) {
    constraintAdjustmentBitmask |= 1 << adjustment.index;
  }

  return _createWindow(
    archetype: WindowArchetype.popup,
    viewBuilder: (MethodChannel channel) async {
      return await channel.invokeMethod('createPopup', <String, dynamic>{
            'parent': parentViewId,
            'size': <int>[size.width.toInt(), size.height.toInt()],
            'anchorRect':
                anchorRect != null
                    ? <int>[
                      anchorRect.left.toInt(),
                      anchorRect.top.toInt(),
                      anchorRect.width.toInt(),
                      anchorRect.height.toInt(),
                    ]
                    : null,
            'positionerParentAnchor': positioner.parentAnchor.index,
            'positionerChildAnchor': positioner.childAnchor.index,
            'positionerOffset': <int>[positioner.offset.dx.toInt(), positioner.offset.dy.toInt()],
            'positionerConstraintAdjustment': constraintAdjustmentBitmask,
          })
          as Map<Object?, Object?>;
    },
  );
}

Future<_WindowCreationResult> _createWindow({
  required WindowArchetype archetype,
  required Future<Map<Object?, Object?>> Function(MethodChannel channel) viewBuilder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final Map<Object?, Object?> creationData = await viewBuilder(SystemChannels.windowing);
  final int viewId = creationData['viewId']! as int;
  final List<Object?> size = creationData['size']! as List<Object?>;

  final WindowState? state =
      (creationData['state'] as String?) != null
          ? WindowState.values.firstWhere(
            (WindowState e) => e.toString() == creationData['state'],
            orElse:
                () => throw Exception('Invalid window state received: ${creationData['state']}'),
          )
          : null;

  final FlutterView flView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
    (FlutterView view) => view.viewId == viewId,
    orElse: () {
      throw Exception('No matching view found for viewId: $viewId');
    },
  );

  return _WindowCreationResult(
    view: flView,
    archetype: archetype,
    size: Size(size[0]! as double, size[1]! as double),
    state: state,
  );
}

Future<void> _destroyWindow(int viewId) async {
  try {
    await SystemChannels.windowing.invokeMethod('destroyWindow', <String, dynamic>{
      'viewId': viewId,
    });
  } on PlatformException catch (e) {
    throw ArgumentError(
      'Unable to delete window with view_id=$viewId. Does the window exist? Error: $e',
    );
  }
}

class _WindowChangeProperties {
  _WindowChangeProperties({this.size});

  Size? size;
  int? parentViewId;
}

class _WindowListener {
  _WindowListener({required this.viewId, required this.onChanged, required this.onDestroyed});

  int viewId;
  void Function(_WindowChangeProperties) onChanged;
  void Function()? onDestroyed;
}

class _WindowingAppGlobalData {
  _WindowingAppGlobalData() {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChannels.windowing.setMethodCallHandler(_methodCallHandler);
  }

  static _WindowingAppGlobalData get instance {
    _instance ??= _WindowingAppGlobalData();
    return _instance!;
  }

  final List<_WindowListener> _listeners = <_WindowListener>[];
  static _WindowingAppGlobalData? _instance;

  Future<void> _methodCallHandler(MethodCall call) async {
    final Map<Object?, Object?> arguments = call.arguments as Map<Object?, Object?>;

    switch (call.method) {
      case 'onWindowChanged':
        final int viewId = arguments['viewId']! as int;
        Size? size;
        if (arguments['size'] != null) {
          final List<Object?> sizeRaw = arguments['size']! as List<Object?>;
          size = Size(sizeRaw[0]! as double, sizeRaw[1]! as double);
        }

        final _WindowChangeProperties properties = _WindowChangeProperties(size: size);
        for (final _WindowListener listener in _listeners) {
          if (listener.viewId == viewId) {
            listener.onChanged(properties);
          }
        }
      case 'onWindowDestroyed':
        final int viewId = arguments['viewId']! as int;
        for (final _WindowListener listener in _listeners) {
          if (listener.viewId == viewId) {
            listener.onDestroyed?.call();
          }
        }

        _listeners.removeWhere((_WindowListener listener) => listener.viewId == viewId);
    }
  }

  void _listen(_WindowListener listener) {
    _listeners.add(listener);
  }
}
