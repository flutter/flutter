// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'framework.dart';

/// Represents a top-level platform window.
///
/// Children of this widget will render into a separate top level platform window.
class Window extends StatefulWidget {
  /// Const constructor for a [Window].
  ///
  /// The [geometry] and [visible] parameters must not be null.
  const Window({
    Key key,
    this.viewConfiguration,
    @required this.child,
  })  : super(key: key);

  /// The child to render in the new window.
  final Widget child;

  /// The configuration of the top-level window in logical screen coordinates.
  final ViewConfiguration viewConfiguration;

  /// Returns the [ActionDispatcher] associated with the [Actions] widget that
  /// most tightly encloses the given [BuildContext].
  ///
  /// Will throw if no ambient [Actions] widget is found.
  ///
  /// If `nullOk` is set to true, then if no ambient [Actions] widget is found,
  /// this will return null.
  ///
  /// The `context` argument must not be null.
  static FlutterWindow of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    final _WindowMarker marker = context.dependOnInheritedWidgetOfExactType<_WindowMarker>();
    assert(() {
      if (nullOk) {
        return true;
      }
      if (marker == null) {
        throw FlutterError('Unable to find an $Window widget in the given context.\n'
            '$Window.of() was called with a context that does not contain an '
            '$Window widget.\n'
            'No $Window ancestor could be found starting from the context that '
            'was passed to $Window.of(). This can happen if the context comes '
            'from a widget above those widgets.\n'
            'The context used was:\n'
            '  $context');
      }
      return true;
    }());
    return marker?.window;
  }

  @override
  _WindowState createState() => _WindowState();
}

class _WindowState extends State<Window> {
  FlutterWindow _window;

  @override
  Widget build(BuildContext context) {
    return _WindowMarker(
      window: _window,
      viewConfiguration: widget.viewConfiguration,
      child: _WindowRenderWidget(child: widget.child),
    );
  }
}

/// The render widget that creates a new window and layer tree.
class _WindowRenderWidget extends SingleChildRenderObjectWidget {
  const _WindowRenderWidget({Key key, Widget child}) : super(key:key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderWindow();
  }
}

/// Render object for Window widget.
class RenderWindow extends RenderProxyBox {
  /// Creates a window around [child].
  RenderWindow({ RenderBox child }) : super(child);
}

// The InheritedWidget marker for Window.
class _WindowMarker extends InheritedWidget {
  const _WindowMarker({
    Key key,
    @required this.window,
    @required this.viewConfiguration,
    @required Widget child,
  })  : assert(window != null),
        assert(child != null),
        super(key: key, child: child);

  final FlutterWindow window;
  final ViewConfiguration viewConfiguration;

  @override
  bool updateShouldNotify(_WindowMarker oldWidget) {
    return window != oldWidget.window || viewConfiguration != oldWidget.viewConfiguration;
  }
}


