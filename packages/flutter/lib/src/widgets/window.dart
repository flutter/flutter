// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Defines the possible archetypes for a window.
enum WindowArchetype {
  /// Defines a traditional window
  regular,

  /// Defines a popup window
  popup,
}

/// Defines the possible states that a window can be in.
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

/// Base class for window controllers.
///
/// A window controller must provide a [future] that resolves to a
/// a [WindowCreationResult] object. This object contains the view
/// associated with the window, the archetype of the window, the size
/// of the window, and the state of the window.
///
/// The caller may also provide a callback to be called when the window
/// is destroyed, and a callback to be called when an error is encountered
/// during the creation of the window.
///
/// Each [WindowController] is associated with exactly one root [FlutterView].
///
/// When the window is destroyed for any reason (either by the caller or by the
/// platform), the content of the controller will thereafter be invalid. Callers
/// may check if this content is invalid via the [isReady] property.
///
/// This class implements the [Listenable] interface, so callers can listen
/// for changes to the window's properties.
abstract class WindowController with ChangeNotifier {
  /// Creates a [WindowController] with the provided properties.
  /// Upon construction, this widget begins creating a window for the platform.
  /// The [future] parameter is a future that resolves to a [WindowCreationResult]
  /// object.
  /// The [onDestroyed] parameter is a callback that is called when the window
  /// is destroyed.
  /// The [onError] parameter is a callback that is called when an error is
  /// encountered during creation.
  WindowController({
    VoidCallback? onDestroyed,
    void Function(String)? onError,
    required this.future,
  }) {
    future
        .then((WindowCreationResult metadata) async {
          _handleCreationResult(metadata);

          _listener = _WindowListener(
            viewId: metadata.rootView.viewId,
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
        })
        .catchError((Object? error) {
          onError?.call(error.toString());
        });
  }

  void _handleCreationResult(WindowCreationResult metadata) {
    _view = metadata.rootView;
    _size = metadata.size;
    notifyListeners();
  }

  /// Returns true if the window associated with the controller has been
  /// created and is ready to be used. Otherwise, returns false.
  bool get isReady => _view != null;

  /// The future that resolves when the window has been created.
  final Future<WindowCreationResult> future;

  late final _WindowListener _listener;

  /// The root view associated to this window, which is unique to each window.
  FlutterView get rootView => _view!;
  FlutterView? _view;

  /// The current size of the window. This may differ from the requested size.
  Size get size => _size;
  Size _size = Size.zero;

  /// The archetype of the window.
  WindowArchetype get type;

  bool _isPendingDestroy = false;

  /// Destroys this window. If the window is not ready or is already pending
  /// destruction, then nothing happens. Otherwise, we begin destroying the
  /// window.
  Future<void> destroy() async {
    if (!isReady || _isPendingDestroy) {
      return;
    }

    _isPendingDestroy = true;
    return _destroyWindow(rootView.viewId);
  }
}

/// A controller for a regular window.
///
/// A regular window is a traditional window that can be resized, minimized,
/// maximized, and closed. Upon construction, the window is created for the
/// platform with the provided properties.
///
/// This class does not interact with the widget tree. Instead, it is typically
/// provided to the [RegularWindow] widget, who does the work of rendering the
/// content inside of this window.
///
/// An example usage might look like:
/// ```dart
/// final RegularWindowController controller = RegularWindowController(
///   size: const Size(800, 600),
///   sizeConstraints: const BoxConstraints(minWidth: 640, minHeight: 480),
///   title: "Example Window",
/// );
/// runWidget(RegularWindow(
///   controller: controller,
///   child: MaterialApp(home: Container())));
/// ```
///
/// When provided to a [RegularWindow] widget, widgets inside of the [child]
/// parameter will have access to the [RegularWindowController] via the
/// [WindowControllerContext] widget.
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
  }) : super(
         onDestroyed: onDestroyed,
         onError: onError,
         future: _createRegular(
           size: size,
           sizeConstraints: sizeConstraints,
           title: title,
           state: state,
         ),
       ) {}

  @override
  void _handleCreationResult(WindowCreationResult metadata) {
    _state = (metadata as _RegularWindowCreationResult).state;
    super._handleCreationResult(metadata);
  }

  @override
  WindowArchetype get type => WindowArchetype.regular;

  /// The current state of the window.
  WindowState get state => _state;
  WindowState _state = WindowState.restored;

  /// Modify the properties of the window. The window must be ready before
  /// calling this method. If the window is not ready, an assertion will be
  /// thrown. The caller must provide at least one of the following parameters:
  ///
  /// [size] the new size of the window
  /// [title] the new title of the window
  /// [state] the new state of the window
  ///
  /// If no parameters are provided, then an assertion will be thrown.
  Future<void> modify({Size? size, String? title, WindowState? state}) {
    assert(isReady, 'Window is not ready');
    return _modifyRegular(viewId: rootView.viewId, size: size, title: title, state: state);
  }
}

abstract class ChildWindowController extends WindowController {
  ChildWindowController({
    VoidCallback? onDestroyed,
    void Function(String)? onError,
    required Future<WindowCreationResult> future,
    required FlutterView parent,
  }) : _parent = parent,
       super(onDestroyed: onDestroyed, onError: onError, future: future);

  FlutterView get parent => _parent;
  final FlutterView _parent;
}

class PopupWindowController extends ChildWindowController {
  PopupWindowController({
    BoxConstraints? sizeConstraints,
    VoidCallback? onDestroyed,
    void Function(String)? onError,
    Rect? anchorRect,
    WindowPositioner positioner = const WindowPositioner(),
    required FlutterView parent,
    required Size size,
  }) : super(
         onDestroyed: onDestroyed,
         onError: onError,
         future: _createPopup(
           parentViewId: parent.viewId,
           size: size,
           sizeConstraints: sizeConstraints,
           anchorRect: anchorRect,
           positioner: positioner,
         ),
         parent: parent,
       );

  @override
  WindowArchetype get type => WindowArchetype.popup;
}

class _Window extends StatefulWidget {
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
    await widget.controller.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WindowCreationResult>(
      key: widget.key,
      future: widget.controller.future,
      builder: (BuildContext context, AsyncSnapshot<WindowCreationResult> metadata) {
        if (!metadata.hasData) {
          return const ViewCollection(views: <Widget>[]);
        }

        return View(
          view: metadata.data!.rootView,
          child: WindowControllerContext(controller: widget.controller, child: widget.child),
        );
      },
    );
  }
}

/// The [RegularWindow] widget provides a way to render a regular window in the
/// widget tree. The provided [controller] creates the native window that backs
/// the widget. The [child] widget is rendered into this newly created window.
///
/// While the window is being created, the [RegularWindow] widget will render
/// an empty [ViewCollection] widget. Once the window is created, the [child]
/// widget will be rendered into the window inside of a [View].
///
/// An example usage might look like:
/// ```dart
/// final RegularWindowController controller = RegularWindowController(
///   size: const Size(800, 600),
///   sizeConstraints: const BoxConstraints(minWidth: 640, minHeight: 480),
///   title: "Example Window",
/// );
/// runApp(RegularWindow(
///   controller: controller,
///   child: MaterialApp(home: Container())));
/// ```
///
/// When a [RegularWindow] widget is removed from the tree, the window that was created
/// by the [controller] is automatically destroyed if it has not yet been destroyed.
///
/// Widgets in the same tree as the [child] widget will have access to the
/// [RegularWindowController] via the [WindowControllerContext] widget.
class RegularWindow extends StatelessWidget {
  /// Creates a regular window widget.
  /// [controller] the controller for this window
  /// [child] the content to render into this window
  /// [key] the key for this widget
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

/// Provides descendents with access to the [WindowController] associated with
/// the window that is being rendered.
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

/// Used by the [WindowController], this class defines the raw data
/// associated with the creation of a window. This object can be constructed
/// from anywhere, but it is typically returned by internal methods that create
/// windows.
abstract class WindowCreationResult {
  /// Creates a new [WindowCreationResult]
  /// [rootView] the view associated with this window
  /// [archetype] the archetype of this window
  /// [size] the size of this window
  /// [state] the state of this window
  WindowCreationResult({
    this.parentView,
    required this.rootView,
    required this.archetype,
    required this.size,
  });

  /// The view associated with this window.
  final FlutterView rootView;

  final FlutterView? parentView;

  /// The archetype of this window.
  final WindowArchetype archetype;

  /// The size of this window.
  final Size size;
}

class _RegularWindowCreationResult extends WindowCreationResult {
  _RegularWindowCreationResult({
    super.parentView,
    required super.rootView,
    required super.archetype,
    required super.size,
    required this.state,
  });

  /// The state of the window
  final WindowState state;
}

Future<_RegularWindowCreationResult> _createRegular({
  required Size size,
  BoxConstraints? sizeConstraints,
  String? title,
  WindowState? state,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final Map<Object?, Object?> creationData =
      await SystemChannels.windowing.invokeMethod('createWindow', <String, dynamic>{
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
  final int viewId = creationData['viewId']! as int;
  final List<Object?> resultSize = creationData['size']! as List<Object?>;
  final WindowState resultState =
      (creationData['state'] as String?) != null
          ? WindowState.values.firstWhere(
            (WindowState e) => e.toString() == creationData['state'],
            orElse:
                () => throw Exception('Invalid window state received: ${creationData['state']}'),
          )
          : WindowState.restored;

  final FlutterView flView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
    (FlutterView view) => view.viewId == viewId,
    orElse: () {
      throw Exception('No matching view found for viewId: $viewId');
    },
  );

  return _RegularWindowCreationResult(
    rootView: flView,
    archetype: WindowArchetype.regular,
    size: Size(resultSize[0]! as double, resultSize[1]! as double),
    state: resultState,
  );
}

class _PopupWindowCreationResult extends WindowCreationResult {
  _PopupWindowCreationResult({
    required super.parentView,
    required super.rootView,
    required super.archetype,
    required super.size,
    required this.relativePosition,
  });

  /// The relative position to the parent.
  final Offset relativePosition;
}

Future<_PopupWindowCreationResult> _createPopup({
  required int parentViewId,
  required Size size,
  BoxConstraints? sizeConstraints,
  Rect? anchorRect,
  required WindowPositioner positioner,
}) async {
  final List<String> constraintAdjustmentList = <String>[];
  for (final WindowPositionerConstraintAdjustment adjustment in positioner.constraintAdjustment) {
    constraintAdjustmentList.add(adjustment.toString());
  }

  WidgetsFlutterBinding.ensureInitialized();
  final Map<Object?, Object?> creationData =
      await SystemChannels.windowing.invokeMethod('createPopup', <String, dynamic>{
            'parentViewId': parentViewId,
            'size': <double>[size.width, size.height],
            'minSize':
                sizeConstraints != null
                    ? <double>[sizeConstraints.minWidth, sizeConstraints.minHeight]
                    : null,
            'maxSize':
                sizeConstraints != null
                    ? <double>[sizeConstraints.maxWidth, sizeConstraints.maxHeight]
                    : null,
            'positioner': <String, dynamic>{
              'anchorRect':
                  anchorRect != null
                      ? <double>[
                        anchorRect.left,
                        anchorRect.top,
                        anchorRect.width,
                        anchorRect.height,
                      ]
                      : null,
              'parentAnchor': positioner.parentAnchor.toString(),
              'childAnchor': positioner.childAnchor.toString(),
              'offset': <double>[positioner.offset.dx, positioner.offset.dy],
              'constraintAdjustment': constraintAdjustmentList,
            },
          })
          as Map<Object?, Object?>;

  final int viewId = creationData['viewId']! as int;
  final List<Object?> resultSize = creationData['size']! as List<Object?>;
  final int resultParentViewId = creationData['parentViewId']! as int;
  final List<dynamic>? relativePositionList = creationData['relativePosition'] as List<dynamic>?;
  final Offset relativePosition =
      (relativePositionList != null && relativePositionList.length == 2)
          ? Offset(relativePositionList[0] as double, relativePositionList[1] as double)
          : Offset.zero;
  final FlutterView flView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
    (FlutterView view) => view.viewId == viewId,
    orElse: () {
      throw Exception('No matching view found for viewId: $viewId');
    },
  );
  final FlutterView parentView = WidgetsBinding.instance.platformDispatcher.views.firstWhere(
    (FlutterView view) => view.viewId == resultParentViewId,
    orElse: () {
      throw Exception('No matching view found for viewId: $viewId');
    },
  );

  return _PopupWindowCreationResult(
    rootView: flView,
    parentView: parentView,
    archetype: WindowArchetype.regular,
    size: Size(resultSize[0]! as double, resultSize[1]! as double),
    relativePosition: relativePosition,
  );
}

Future<void> _modifyRegular({required int viewId, Size? size, String? title, WindowState? state}) {
  assert(size != null || title != null || state != null);
  return SystemChannels.windowing.invokeMethod('modifyRegular', <String, dynamic>{
    'viewId': viewId,
    'size': size != null ? <double>[size.width, size.height] : null,
    'title': title,
    'state': state?.toString(),
  });
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
  _WindowChangeProperties({this.size, this.relativePosition});

  Size? size;
  Offset? relativePosition;
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
        Offset? relativePosition;
        if (arguments['relativePosition'] != null) {
          final List<Object?> relativePositionRaw = arguments['relativePosition']! as List<Object?>;
          relativePosition = Offset(
            relativePositionRaw[0]! as double,
            relativePositionRaw[1]! as double,
          );
        }

        final _WindowChangeProperties properties = _WindowChangeProperties(
          size: size,
          relativePosition: relativePosition,
        );
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
