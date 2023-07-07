// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/widgets.dart';

import 'shim/dart_ui.dart' as ui;

const String _viewType = '__webPointerInterceptorViewType__';
const String _debug = 'debug__';

// Computes a "view type" for different configurations of the widget.
String _getViewType({bool debug = false}) {
  return debug ? _viewType + _debug : _viewType;
}

// Registers a viewFactory for this widget.
void _registerFactory({bool debug = false}) {
  final String viewType = _getViewType(debug: debug);
  ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final html.Element htmlElement = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%';
    if (debug) {
      htmlElement.style.backgroundColor = 'rgba(255, 0, 0, .5)';
    }
    return htmlElement;
  }, isVisible: false);
}

/// The web implementation of the `PointerInterceptor` widget.
///
/// A `Widget` that prevents clicks from being swallowed by [HtmlElementView]s.
class PointerInterceptor extends StatelessWidget {
  /// Creates a PointerInterceptor for the web.
  PointerInterceptor({
    required this.child,
    this.intercepting = true,
    this.debug = false,
    Key? key,
  }) : super(key: key) {
    if (!_registered) {
      _register();
    }
  }

  /// The `Widget` that is being wrapped by this `PointerInterceptor`.
  final Widget child;

  /// Whether or not this `PointerInterceptor` should intercept pointer events.
  final bool intercepting;

  /// When true, the widget renders with a semi-transparent red background, for debug purposes.
  ///
  /// This is useful when rendering this as a "layout" widget, like the root child
  /// of a [Drawer].
  final bool debug;

  // Keeps track if this widget has already registered its view factories or not.
  static bool _registered = false;

  // Registers the view factories for the interceptor widgets.
  static void _register() {
    assert(!_registered);

    _registerFactory();
    _registerFactory(debug: true);

    _registered = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!intercepting) {
      return child;
    }

    final String viewType = _getViewType(debug: debug);
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(
          child: HtmlElementView(
            viewType: viewType,
          ),
        ),
        child,
      ],
    );
  }
}
