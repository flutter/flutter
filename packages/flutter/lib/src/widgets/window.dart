// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show FlutterView;

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

/// Controller used with the [RegularWindow] widget. This controller
/// provides access to modify and destroy the window, in addition to
/// listening to changes on the window.
class RegularWindowController with ChangeNotifier {
  late int _viewId;

  /// The ID of the view used for this window, which is unique to each window.
  int get viewId => _viewId;

  late Size _size;

  /// The current size of the window. This may differ from the requested size.
  Size get size => _size;

  late int? _parentViewId;

  /// The ID of the parent in which this rendered, if any.
  int? get parentViewId => _parentViewId;

  /// Modifies this window with the provided properties.
  Future<void> modify({Size? size}) {
    throw UnimplementedError();
  }

  /// Destroys this window.
  Future<void> destroy() {
    return destroyWindow(viewId);
  }
}

class RegularWindow extends StatefulWidget {
  RegularWindow(
      {required Size preferredSize,
      this.onDestroyed,
      this.controller,
      required this.child})
      : _future = createRegular(size: preferredSize);

  final RegularWindowController? controller;
  void Function()? onDestroyed;
  final Future<RegularWindowMetadata> _future;
  final Widget child;

  @override
  State<RegularWindow> createState() => _RegularWindowState();
}

class _RegularWindowState extends State<RegularWindow> {
  _WindowListener? _listener;

  @override
  void initState() {
    super.initState();
    widget._future.then((RegularWindowMetadata metadata) async {
      if (widget.controller != null) {
        widget.controller!._parentViewId = metadata.parentViewId;
        widget.controller!._size = metadata.size;
      }

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        final _WindowingAppContext? windowingAppContext =
            _WindowingAppContext.of(context);
        assert(windowingAppContext != null);
        _listener = _WindowListener(
            viewId: metadata.view.viewId,
            onChanged: (_WindowChangeProperties properties) {
              if (widget.controller == null) {
                return;
              }

              if (properties.size != null) {
                widget.controller!._size = properties.size!;
              }

              if (properties.parentViewId != null) {
                widget.controller!._parentViewId = properties.parentViewId;
              }
            },
            onDestroyed: widget.onDestroyed);
        windowingAppContext!.windowingApp._registerListener(_listener!);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    final _WindowingAppContext? windowingAppContext =
        _WindowingAppContext.of(context);
    if (_listener != null) {
      assert(windowingAppContext != null);
      windowingAppContext!.windowingApp._unregisterListener(_listener!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: widget._future,
        builder: (BuildContext context,
            AsyncSnapshot<RegularWindowMetadata> metadata) {
          if (!metadata.hasData) {
            final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
            return binding.wrapWithDefaultView(Container());
          }

          return View(
              view: metadata.data!.view,
              child: WindowContext(
                  viewId: metadata.data!.view.viewId, child: widget.child));
        });
  }
}

/// Provides descendents with access to the [Window] in which they are rendered
class WindowContext extends InheritedWidget {
  /// [window] the [Window]
  const WindowContext({super.key, required this.viewId, required super.child});

  /// The view ID in this context
  final int viewId;

  /// Returns the [WindowContext] if any
  static WindowContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WindowContext>();
  }

  @override
  bool updateShouldNotify(WindowContext oldWidget) {
    return viewId != oldWidget.viewId;
  }
}

abstract class WindowMetadata {
  WindowMetadata({required this.view, required this.size, this.parentViewId});

  final FlutterView view;
  final Size size;
  final int? parentViewId;

  WindowArchetype get type;
}

class RegularWindowMetadata extends WindowMetadata {
  RegularWindowMetadata(
      {required super.view, required super.size, super.parentViewId});

  @override
  WindowArchetype get type => WindowArchetype.regular;
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
  final int? parent;
}

/// Creates a regular window for the platform and returns the metadata associated
/// with the new window. Users should prefer using the [RegularWindow]
/// widget instead of this method.
///
/// [size] the size of the new [Window] in pixels
Future<RegularWindowMetadata> createRegular({required Size size}) async {
  final _WindowMetadata metadata =
      await _createWindow(viewBuilder: (MethodChannel channel) async {
    return await channel.invokeMethod('createWindow', <String, dynamic>{
      'size': <int>[size.width.toInt(), size.height.toInt()],
    }) as Map<Object?, Object?>;
  });
  return RegularWindowMetadata(view: metadata.flView, size: metadata.size);
}

Future<_WindowMetadata> _createWindow(
    {required Future<Map<Object?, Object?>> Function(MethodChannel channel)
        viewBuilder}) async {
  WidgetsFlutterBinding.ensureInitialized();
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

  return _WindowMetadata(
      flView: flView,
      archetype: archetype,
      size: Size((size[0]! as int).toDouble(), (size[1]! as int).toDouble()),
      parent: parentViewId);
}

/// Destroys the window associated with the provided view ID.
///
/// [viewId] the view id of the window that should be destroyed
Future<void> destroyWindow(int viewId) async {
  try {
    await SystemChannels.windowing
        .invokeMethod('destroyWindow', <String, dynamic>{'viewId': viewId});
  } on PlatformException catch (e) {
    throw ArgumentError(
        'Unable to delete window with view_id=$viewId. Does the window exist? Error: $e');
  }
}

class _WindowChangeProperties {
  _WindowChangeProperties({this.size, this.parentViewId});

  Size? size;
  int? parentViewId;
}

class _WindowListener {
  _WindowListener(
      {required this.viewId,
      required this.onChanged,
      required this.onDestroyed});

  int viewId;
  void Function(_WindowChangeProperties) onChanged;
  void Function()? onDestroyed;
}

/// Declares that an application will create multiple [Window]s.
/// The current [Window] can be looked up with [WindowContext.of].
class WindowingApp extends StatelessWidget {
  WindowingApp({super.key, required this.children}) {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChannels.windowing.setMethodCallHandler(_methodCallHandler);
  }

  final List<Widget> children;
  final List<_WindowListener> _listeners = [];

  Future<void> _methodCallHandler(MethodCall call) async {
    final Map<Object?, Object?> arguments =
        call.arguments as Map<Object?, Object?>;

    switch (call.method) {
      case 'onWindowCreated':
        final int viewId = arguments['viewId']! as int;
        int? parentViewId;
        if (arguments['parentViewId'] != null) {
          parentViewId = arguments['parentViewId']! as int;
        }

        final _WindowChangeProperties properties =
            _WindowChangeProperties(parentViewId: parentViewId);
        for (final _WindowListener listener in _listeners) {
          if (listener.viewId == viewId) {
            listener.onChanged(properties);
          }
        }
      case 'onWindowChanged':
        final int viewId = arguments['viewId']! as int;
        Size? size;
        if (arguments['size'] != null) {
          final List<Object?> sizeRaw = arguments['size']! as List<Object?>;
          size = Size(
              (sizeRaw[0]! as int).toDouble(), (sizeRaw[1]! as int).toDouble());
        }

        final _WindowChangeProperties properties =
            _WindowChangeProperties(size: size);
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
    }
  }

  void _registerListener(_WindowListener listener) {
    _listeners.add(listener);
  }

  void _unregisterListener(_WindowListener listener) {
    _listeners.remove(listener);
  }

  @override
  Widget build(BuildContext context) {
    return _WindowingAppContext(
        windowingApp: this, child: ViewCollection(views: children));
  }
}

class _WindowingAppContext extends InheritedWidget {
  const _WindowingAppContext(
      {super.key, required super.child, required this.windowingApp});

  final WindowingApp windowingApp;

  /// Returns the [MultiWindowAppContext] if any
  static _WindowingAppContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_WindowingAppContext>();
  }

  @override
  bool updateShouldNotify(_WindowingAppContext oldWidget) {
    return windowingApp != oldWidget.windowingApp;
  }
}
