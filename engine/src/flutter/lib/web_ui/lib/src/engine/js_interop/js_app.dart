// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'package:ui/src/engine.dart';

/// The JS bindings for the configuration object passed to [FlutterApp.addView].
extension type JsFlutterViewOptions._primary(JSObject _) implements JSObject {
  factory JsFlutterViewOptions({
    required DomElement hostElement,
    JsViewConstraints? viewConstraints,
    Object? initialData,
  }) => JsFlutterViewOptions._(
    hostElement: hostElement,
    viewConstraints: viewConstraints,
    initialData: initialData?.toJSAnyDeep,
  );
  external factory JsFlutterViewOptions._({
    required DomElement hostElement,
    JsViewConstraints? viewConstraints,
    JSAny? initialData,
  });

  @JS('hostElement')
  external DomElement? get _hostElement;
  DomElement get hostElement {
    assert(_hostElement != null, '`hostElement` passed to addView cannot be null.');
    return _hostElement!;
  }

  external JsViewConstraints? get viewConstraints;
  external JSAny? get initialData;
}

/// The JS bindings for a [ViewConstraints] object.
///
/// Attributes are expressed in *logical* pixels.
extension type JsViewConstraints._(JSObject _) implements JSObject {
  external factory JsViewConstraints({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  });

  external double? get maxHeight;
  external double? get maxWidth;
  external double? get minHeight;
  external double? get minWidth;
}

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
