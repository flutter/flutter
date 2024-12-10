// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

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
  Window(
      {required this.view,
      required this.builder,
      required this.size,
      this.parent});

  /// The underlying [FlutterView] associated with this [Window]
  final FlutterView view;

  /// The render function containing the content of this [Window]
  final Widget Function(BuildContext context) builder;

  /// The current [Size] of the [Window]
  Size size;

  /// The parent of this window, which may or may not exist.
  final Window? parent;

  /// A list of child [Window]s associated with this window
  final List<Window> children = <Window>[];

  UniqueKey _key = UniqueKey();

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
    final Map<Object?, Object?> creationData =
        await viewBuilder(SystemChannels.windowing);
    final int viewId = creationData['viewId']! as int;
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
