// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'framework.dart';
import 'platform_view.dart';

/// Callback signature for when the platform view's DOM element was created.
///
/// [element] is the DOM element that was created.
typedef ElementCreatedCallback = void Function(Object element);

const String _kDefaultVisibleViewType = '_default_document_create_element_visible';
const String _kDefaultInvisibleViewType = '_default_document_create_element_invisible';

/// Embeds an HTML element in the Widget hierarchy in Flutter Web.
///
/// *NOTE*: This only works in Flutter Web. To embed web content on other
/// platforms, consider using the `flutter_webview` plugin.
///
/// Embedding HTML is an expensive operation and should be avoided when a
/// Flutter equivalent is possible.
///
/// The embedded HTML is painted just like any other Flutter widget and
/// transformations apply to it as well. This widget should only be used in
/// Flutter Web.
///
/// {@macro flutter.widgets.AndroidView.layout}
///
/// Due to security restrictions with cross-origin `<iframe>` elements, Flutter
/// cannot dispatch pointer events to an HTML view. If an `<iframe>` is the
/// target of an event, the window containing the `<iframe>` is not notified
/// of the event. In particular, this means that any pointer events which land
/// on an `<iframe>` will not be seen by Flutter, and so the HTML view cannot
/// participate in gesture detection with other widgets.
///
/// The way we enable accessibility on Flutter for web is to have a full-page
/// button which waits for a double tap. Placing this full-page button in front
/// of the scene would cause platform views not to receive pointer events. The
/// tradeoff is that by placing the scene in front of the semantics placeholder
/// will cause platform views to block pointer events from reaching the
/// placeholder. This means that in order to enable accessibility, you must
/// double tap the app *outside of a platform view*. As a consequence, a
/// full-screen platform view will make it impossible to enable accessibility.
/// Make sure that your HTML views are sized no larger than necessary, or you
/// may cause difficulty for users trying to enable accessibility.
///
/// {@macro flutter.widgets.AndroidView.lifetime}
class HtmlElementView extends StatelessWidget {
  /// Creates a platform view for Flutter Web.
  ///
  /// `viewType` identifies the type of platform view to create.
  const HtmlElementView({
    super.key,
    required this.viewType,
    this.onPlatformViewCreated,
    this.creationParams,
  });

  /// Creates a platform view that creates a DOM element specified by [tagName].
  ///
  /// [isVisible] indicates whether the view is visible to the user or not.
  /// Setting this to false allows the rendering pipeline to perform extra
  /// optimizations knowing that the view will not result in any pixels painted
  /// on the screen.
  ///
  /// [onElementCreated] is called when the DOM element is created. It can be
  /// used by the app to customize the element by adding attributes and styles.
  ///
  /// ```dart
  /// import 'package:flutter/widgets.dart';
  /// import 'package:web/web.dart' as web;
  ///
  /// // ...
  ///
  /// class MyWidget extends StatelessWidget {
  ///   const MyWidget({super.key});
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return HtmlElementView.domElement(
  ///       tagName: 'div',
  ///       onElementCreated: (Object element) {
  ///         element as web.HTMLElement;
  ///         element.style
  ///             ..backgroundColor = 'blue'
  ///             ..border = '1px solid red';
  ///       },
  ///     );
  ///   }
  /// }
  /// ```
  HtmlElementView.domElement({
    super.key,
    required String tagName,
    bool isVisible = true,
    ElementCreatedCallback? onElementCreated,
  })  : viewType = isVisible ? _kDefaultVisibleViewType : _kDefaultInvisibleViewType,
        onPlatformViewCreated = _createPlatformViewCallbackForElementCallback(onElementCreated),
        creationParams = <dynamic, dynamic>{'tagName': tagName} {
    _registerDefaultFactories();
  }

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  /// Callback to invoke after the platform view has been created.
  ///
  /// May be null.
  final PlatformViewCreatedCallback? onPlatformViewCreated;

  /// Passed as the 2nd argument (i.e. `params`) of the registered view factory.
  final Object? creationParams;

  static PlatformViewCreatedCallback? _createPlatformViewCallbackForElementCallback(
    ElementCreatedCallback? onElementCreated,
  ) {
    if (onElementCreated == null) {
      return null;
    }
    return (int id) {
      onElementCreated(_platformViewsRegistry.getViewById(id));
    };
  }

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      onCreatePlatformView: _createHtmlElementView,
      surfaceFactory: (BuildContext context, PlatformViewController controller) {
        return PlatformViewSurface(
          controller: controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
    );
  }

  /// Creates the controller and kicks off its initialization.
  _HtmlElementViewController _createHtmlElementView(
    PlatformViewCreationParams params,
  ) {
    final _HtmlElementViewController controller = _HtmlElementViewController(
      params.id,
      viewType,
      creationParams,
    );
    controller._initialize().then((_) {
      params.onPlatformViewCreated(params.id);
      onPlatformViewCreated?.call(params.id);
    });
    return controller;
  }
}

class _HtmlElementViewController extends PlatformViewController {
  _HtmlElementViewController(
    this.viewId,
    this.viewType,
    this.creationParams,
  );

  @override
  final int viewId;

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  final dynamic creationParams;

  bool _initialized = false;

  Future<void> _initialize() async {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': viewType,
      'params': creationParams,
    };
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    _initialized = true;
  }

  @override
  Future<void> clearFocus() async {
    // Currently this does nothing on Flutter Web.
    // TODO(het): Implement this. See https://github.com/flutter/flutter/issues/39496
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    // We do not dispatch pointer events to HTML views because they may contain
    // cross-origin iframes, which only accept user-generated events.
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      await SystemChannels.platform_views.invokeMethod<void>('dispose', viewId);
    }
  }
}

/// Overrides the [ui_web.PlatformViewRegistry] used by [HtmlElementView].
///
/// This is used for testing view factory registration.
@visibleForTesting
ui_web.PlatformViewRegistry? debugOverridePlatformViewRegistry;
ui_web.PlatformViewRegistry get _platformViewsRegistry => debugOverridePlatformViewRegistry ?? ui_web.platformViewRegistry;

bool _areDefaultFactoriesRegistered = false;

/// Reset default view factories so that they are registered again next time.
///
/// There is no way to acually unregister a view factory, so this is only useful
/// during testing when switching to a new [FakePlatformViewRegistry] to make
/// sure the default view factories are re-registered.
@visibleForTesting
void debugResetDefaultFactories() {
  _areDefaultFactoriesRegistered = false;
}

void _registerDefaultFactories() {
  if (_areDefaultFactoriesRegistered) {
    return;
  }

  _platformViewsRegistry.registerViewFactory(
    _kDefaultVisibleViewType,
    _defaultFactory,
  );
  _platformViewsRegistry.registerViewFactory(
    _kDefaultInvisibleViewType,
    _defaultFactory,
    isVisible: false,
  );
}

web.Element _defaultFactory(
  int viewId, {
  Object? params,
}) {
  params!;
  params as _DefaultFactoryParams;
  return web.document.createElement(params.tagName);
}

typedef _DefaultFactoryParams = Map<Object?, Object?>;

extension on _DefaultFactoryParams {
  String get tagName => this['tagName']! as String;
}
