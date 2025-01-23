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

/// A widget that creates a regular window. This content of this window is
/// rendered into a [View], meaning that this widget must be rendered into
/// either a [ViewAnchor] or a [ViewCollection].
class RegularWindow extends StatefulWidget {
  /// Creates a regular window widget
  const RegularWindow({super.key, required this.controller, required this.child});

  /// Controller for this widget.
  final RegularWindowController controller;

  /// The content rendered into this window.
  final Widget child;

  @override
  State<RegularWindow> createState() => _RegularWindowState();
}

class _RegularWindowState extends State<RegularWindow> {
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
