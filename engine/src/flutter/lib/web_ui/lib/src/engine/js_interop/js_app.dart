// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:ui/src/engine.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

/// The JS bindings for the configuration object passed to [FlutterApp.addView].
///
/// This is the public [ui_web.FlutterViewOptions]. The engine reads the host
/// element through [JsFlutterViewOptionsExtension.hostDomElement].
typedef JsFlutterViewOptions = ui_web.FlutterViewOptions;

/// Engine-only accessors for [JsFlutterViewOptions].
extension JsFlutterViewOptionsExtension on JsFlutterViewOptions {
  @JS('hostElement')
  external DomElement? get _hostElement;

  /// The host element, as the engine-internal [DomElement] type, which can't
  /// appear in `dart:ui_web`.
  DomElement get hostDomElement {
    assert(_hostElement != null, '`hostElement` passed to addView cannot be null.');
    return _hostElement!;
  }
}

/// The JS bindings for a [ViewConstraints] object.
///
/// Attributes are expressed in *logical* pixels.
typedef JsViewConstraints = ui_web.FlutterViewConstraints;

/// The public JS API of a running Flutter Web App.
extension type FlutterApp._primary(JSObject _) implements JSObject {
  factory FlutterApp({
    required AddFlutterViewFn addView,
    required RemoveFlutterViewFn removeView,
  }) => FlutterApp._(addView: addView.toJS, removeView: ((int id) => removeView(id)).toJS);
  external factory FlutterApp._({required JSFunction addView, required JSFunction removeView});

  @JS('addView')
  external int addView(JsFlutterViewOptions options);

  @JS('removeView')
  external JsFlutterViewOptions? removeView(int id);
}

/// Typedef for the function that adds a new view to the app.
///
/// Returns the ID of the newly created view.
typedef AddFlutterViewFn = int Function(JsFlutterViewOptions);

/// Typedef for the function that removes a view from the app.
///
/// Returns the configuration used to create the view.
typedef RemoveFlutterViewFn = JsFlutterViewOptions? Function(int);
