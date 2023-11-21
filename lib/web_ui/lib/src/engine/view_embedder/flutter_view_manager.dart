// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'package:ui/src/engine.dart';

/// Encapsulates view objects, and their optional metadata indexed by `viewId`.
class FlutterViewManager {
  // A map of EngineFlutterViews indexed by their viewId.
  final Map<int, EngineFlutterView> _viewData = <int, EngineFlutterView>{};
  // A map of (optional) JsFlutterViewOptions, indexed by their viewId.
  final Map<int, JsFlutterViewOptions> _jsViewOptions =
      <int, JsFlutterViewOptions>{};
  // The controller of the [onViewsChanged] stream.
  final StreamController<void> _onViewsChangedController =
      StreamController<void>.broadcast();

  /// A stream of `void` events that will fire when a view is registered/unregistered.
  Stream<void> get onViewsChanged => _onViewsChangedController.stream;

  /// Exposes all the [EngineFlutterView]s registered so far.
  Iterable<EngineFlutterView> get views => _viewData.values;

  /// Retrieves an [EngineFlutterView] by its `viewId`.
  EngineFlutterView? operator [](int viewId) {
    return _viewData[viewId];
  }

  /// Stores a [view] and its (optional) [jsViewOptions], indexed by `viewId`.
  ///
  /// Returns the registered [view].
  EngineFlutterView registerView(
    EngineFlutterView view, {
    JsFlutterViewOptions? jsViewOptions,
  }) {
    final int viewId = view.viewId;
    // This assert knows of kImplicitViewId, so some tests like test/engine/routing_test.dart
    // can pass. The kImplicitViewId exception should be removed!
    assert(viewId == kImplicitViewId || !_viewData.containsKey(viewId)); // Adding the same view twice?

    // Store the view, and the jsViewOptions, if any...
    _viewData[viewId] = view;
    if (jsViewOptions != null) {
      _jsViewOptions[viewId] = jsViewOptions;
    }
    _onViewsChangedController.add(null);

    return view;
  }

  /// Un-registers [viewId].
  ///
  /// Returns its [JsFlutterViewOptions] (if any).
  JsFlutterViewOptions? unregisterView(int viewId) {
    _viewData.remove(viewId); // .dispose();
    final JsFlutterViewOptions? jsViewOptions = _jsViewOptions.remove(viewId);
    _onViewsChangedController.add(null);
    return jsViewOptions;
  }

  /// Returns the [JsFlutterViewOptions] associated to `viewId` (if any).
  ///
  /// This is useful for plugins and apps that need this information, and can
  /// be exposed through a method in ui_web.
  JsFlutterViewOptions? getOptions(int viewId) {
    return _jsViewOptions[viewId];
  }
}
