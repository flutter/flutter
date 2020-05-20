// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// A registry for factories that create platform views.
class PlatformViewRegistry {
  /// Private constructor so this class can be a singleton.
  PlatformViewRegistry._();

  /// The platform view factories which have been registered.
  final Map<String, PlatformViewFactory> registeredFactories =
      <String, PlatformViewFactory>{};

  final Map<int, html.Element> _createdViews = <int, html.Element>{};

  /// Register [viewTypeId] as being creating by the given [factory].
  bool registerViewFactory(String viewTypeId, PlatformViewFactory factory) {
    if (registeredFactories.containsKey(viewTypeId)) {
      return false;
    }
    registeredFactories[viewTypeId] = factory;
    return true;
  }

  /// Returns the view that has been created with the given [id], or `null` if
  /// no such view exists.
  html.Element getCreatedView(int id) {
    return _createdViews[id];
  }
}

/// A function which takes a unique [id] and creates an HTML element.
typedef PlatformViewFactory = html.Element Function(int viewId);

/// The platform view registry for this app.
final PlatformViewRegistry platformViewRegistry = PlatformViewRegistry._();

/// Handles a platform call to `flutter/platform_views`.
///
/// Used to create and dispose platform views.
void handlePlatformViewCall(
  ByteData data,
  ui.PlatformMessageResponseCallback callback,
) {
  const MethodCodec codec = StandardMethodCodec();
  final MethodCall decoded = codec.decodeMethodCall(data);

  switch (decoded.method) {
    case 'create':
      _createPlatformView(decoded, callback);
      return;
    case 'dispose':
      _disposePlatformView(decoded, callback);
      return;
  }
  callback(null);
}

void _createPlatformView(
    MethodCall methodCall, ui.PlatformMessageResponseCallback callback) {
  final Map<dynamic, dynamic> args =
      methodCall.arguments as Map<dynamic, dynamic>;
  final int id = args['id'] as int;
  final String viewType = args['viewType'] as String;
  const MethodCodec codec = StandardMethodCodec();

  // TODO(het): Use 'direction', 'width', and 'height'.
  if (!platformViewRegistry.registeredFactories.containsKey(viewType)) {
    callback(codec.encodeErrorEnvelope(
      code: 'Unregistered factory',
      message: "No factory registered for viewtype '$viewType'",
    ));
    return;
  }
  // TODO(het): Use creation parameters.
  final html.Element element =
      platformViewRegistry.registeredFactories[viewType](id);

  platformViewRegistry._createdViews[id] = element;
  callback(codec.encodeSuccessEnvelope(null));
}

void _disposePlatformView(
    MethodCall methodCall, ui.PlatformMessageResponseCallback callback) {
  final int id = methodCall.arguments as int;
  const MethodCodec codec = StandardMethodCodec();

  // Remove the root element of the view from the DOM.
  platformViewRegistry._createdViews[id]?.remove();
  platformViewRegistry._createdViews.remove(id);

  callback(codec.encodeSuccessEnvelope(null));
}
