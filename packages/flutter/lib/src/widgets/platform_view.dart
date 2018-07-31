// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'framework.dart';

/// Embeds an Android view in the Widget hierarchy.
///
/// Embedding Android views is an expensive operation and should be avoided when a Flutter
/// equivalent is possible.
///
/// The embedded Android view is painted just like any other Flutter widget and transformations
/// apply to it as well.
///
/// The widget fill all available space, the parent of this object must provide bounded layout
/// constraints.
///
/// The Android view object is created using a [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html).
/// Plugins can register platform view factories with [PlatformViewRegistry#registerViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewRegistry.html#registerViewFactory-java.lang.String-io.flutter.plugin.platform.PlatformViewFactory-).
///
/// Registration is typically done in the plugin's registerWith method, e.g:
///
/// ```java
///   public static void registerWith(Registrar registrar) {
///     registrar.platformViewRegistry().registerViewFactory("webview", new WebViewFactory(registrar.messenger()));
///   }
/// ```
///
/// The Android view's lifetime is the same as the lifetime of the [State] object for this widget.
/// When the [State] is disposed the platform view (and auxiliary resources) are lazily
/// released (some resources are immediately released and some by platform garbage collector).
/// A stateful widget's state is disposed the the widget is removed from the tree or when it is
/// moved within the tree. If the stateful widget has a key and it's only moved relative to its siblings,
/// or it has a [GlobalKey] and it's moved within the tree, it will not be disposed.
class AndroidView extends StatefulWidget {
  /// Creates a widget that embeds an Android view.
  ///
  /// The `viewType` parameter must not be null.
  const AndroidView({
    Key key,
    @required this.viewType,
    this.onPlatformViewCreated
  }) : assert(viewType != null),
       super(key: key);

  /// The unique identifier for Android view type to be embedded by this widget.
  /// A [PlatformViewFactory](/javadoc/io/flutter/plugin/platform/PlatformViewFactory.html)
  /// for this type must have been registered.
  ///
  /// See also: [AndroidView] for an example of registering a platform view factory.
  final String viewType;

  /// Callback to invoke after the Android view has been created.
  ///
  /// May be null.
  final OnPlatformViewCreated onPlatformViewCreated;

  @override
  State createState() => new _AndroidViewState();
}

class _AndroidViewState extends State<AndroidView> {
  int _id;
  AndroidViewController _controller;

  @override
  Widget build(BuildContext context) {
    return new _AndroidPlatformView(controller: _controller);
  }

  @override
  void initState() {
    super.initState();
    _createNewAndroidView();
  }

  @override
  void didUpdateWidget(AndroidView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewType == oldWidget.viewType)
      return;
    _controller.dispose();
    _createNewAndroidView();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createNewAndroidView() {
    _id = platformViewsRegistry.getNextPlatformViewId();
    _controller = PlatformViewsService.initAndroidView(
        id: _id,
        viewType: widget.viewType,
        onPlatformViewCreated: widget.onPlatformViewCreated
    );
  }

}

class _AndroidPlatformView extends LeafRenderObjectWidget {
  const _AndroidPlatformView({
    Key key,
    @required this.controller,
  }) : assert(controller != null),
       super(key: key);

  final AndroidViewController controller;

  @override
  RenderObject createRenderObject(BuildContext context) =>
    new RenderAndroidView(viewController: controller);

  @override
  void updateRenderObject(BuildContext context, RenderAndroidView renderObject) {
    renderObject.viewController = controller;
  }
}
