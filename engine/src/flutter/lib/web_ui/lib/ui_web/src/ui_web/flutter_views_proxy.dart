// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:js_interop';

import 'package:ui/src/engine.dart';

/// Exposes web-only functionality for this app's `FlutterView`s objects.
final FlutterViewManagerProxy views = FlutterViewManagerProxy(
  viewManager: EnginePlatformDispatcher.instance.viewManager,
);

/// This class exposes web-only attributes for the registered views in a multi-view app.
class FlutterViewManagerProxy {
  FlutterViewManagerProxy({required FlutterViewManager viewManager}) : _viewManager = viewManager;
  // The proxied viewManager instance.
  final FlutterViewManager _viewManager;

  /// Returns the host element for [viewId].
  ///
  /// In the full-page mode, the host element is the `<body>` element of the page
  /// and the view is the one and only [PlatformDispatcher.implicitView].
  ///
  /// In the add-to-app mode, the host element is the value of `hostElement`
  /// provided when creating the view.
  ///
  /// This is useful for plugins and apps to have a safe DOM Element where they
  /// can add their own custom HTML elements (for example: file inputs for the
  /// file_selector plugin).
  JSAny? getHostElement(int viewId) {
    return _viewManager.getHostElement(viewId) as JSAny?;
  }

  /// Returns the `initialData` configuration value passed from JS when `viewId` was added.
  ///
  /// Developers can access the initial data from Dart in two ways:
  ///  * Defining their own `staticInterop` class that describes what you're
  ///    passing to your views, to retain type safety on Dart (preferred).
  ///  * Calling [NullableUndefineableJSAnyExtension.dartify] and accessing the
  ///    returned object as if it were a [Map] (not recommended).
  JSAny? getInitialData(int viewId) {
    return _viewManager.getOptions(viewId)?.initialData;
  }

  /// Adds a view to the application, embedding it into the host element specified in options.
  ///
  /// This registers an embedded view within the DOM element provided in
  /// [FlutterViewOptions.hostElement]. The newly created view will participate in
  /// frame rendering and receive pointer, text, and semantics events.
  ///
  /// Returns the unique integer identifier `viewId` assigned to the new view. The host
  /// application can then bind widgets to this view using the `View` widget or multi-view
  /// app builders.
  ///
  /// To unmount and destroy the view, call [removeView] with the returned `viewId`.
  int addView(FlutterViewOptions options) {
    return _viewManager.createAndRegisterView(options).viewId;
  }

  /// Removes and disposes the view with the given [viewId].
  ///
  /// Unregisters the view from the engine's view manager, removes its DOM nodes,
  /// and disposes of its associated rendering surface.
  ///
  /// If no view exists with [viewId], this call is a no-op.
  void removeView(int viewId) {
    _viewManager.disposeAndUnregisterView(viewId);
  }
}

/// Options for creating and embedding a new Flutter view.
///
/// Describes the configuration of a view embedded into a web page, including its
/// DOM container element, layout constraints, and optional initial data payload.
///
/// This is a JS-interop extension type that describes the same JavaScript options
/// object passed to `app.addView(...)` from JavaScript.
extension type FlutterViewOptions._(JSObject _) implements JSObject {
  /// Creates options for a new Flutter view.
  ///
  /// The [hostElement] parameter is required and specifies the DOM container element
  /// (such as an `HTMLElement`) where the view's canvas and DOM elements are mounted.
  ///
  /// [viewConstraints] optionally specifies layout constraints for the view in logical pixels.
  ///
  /// [initialData] is an optional custom object passed to the view, which can later be retrieved
  /// via [FlutterViewManagerProxy.getInitialData].
  factory FlutterViewOptions({
    required JSObject hostElement,
    FlutterViewConstraints? viewConstraints,
    Object? initialData,
  }) => FlutterViewOptions._js(
    hostElement: hostElement,
    viewConstraints: viewConstraints,
    initialData: initialData?.toJSAnyDeep,
  );

  external factory FlutterViewOptions._js({
    required JSObject hostElement,
    FlutterViewConstraints? viewConstraints,
    JSAny? initialData,
  });

  /// The DOM element into which the Flutter view will be embedded.
  external JSObject get hostElement;

  /// The constraints for the Flutter view.
  external FlutterViewConstraints? get viewConstraints;

  /// Optional initial data to pass to the Flutter view.
  external JSAny? get initialData;
}

/// Constraints for the size of an embedded Flutter view.
///
/// All dimension attributes are expressed in *logical* pixels.
///
/// This is a JS-interop extension type wrapping the underlying JavaScript constraints object,
/// maintaining compatibility with the engine's JavaScript `ViewConstraints` API.
extension type FlutterViewConstraints._(JSObject _) implements JSObject {
  /// Creates constraints for a Flutter view in logical pixels.
  external factory FlutterViewConstraints({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  });

  /// The minimum width of the Flutter view, in logical pixels.
  external double? get minWidth;

  /// The maximum width of the Flutter view, in logical pixels.
  external double? get maxWidth;

  /// The minimum height of the Flutter view, in logical pixels.
  external double? get minHeight;

  /// The maximum height of the Flutter view, in logical pixels.
  external double? get maxHeight;
}
