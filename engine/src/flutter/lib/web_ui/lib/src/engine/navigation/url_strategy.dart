// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../dom.dart';
import '../safe_browser_api.dart';
import 'js_url_strategy.dart';

/// Wraps a custom implementation of [ui_web.UrlStrategy] that was previously converted
/// to a [JsUrlStrategy].
class CustomUrlStrategy extends ui_web.UrlStrategy {
  /// Wraps the [delegate] in a [CustomUrlStrategy] instance.
  CustomUrlStrategy.fromJs(this.delegate);

  final JsUrlStrategy delegate;

  @override
  ui.VoidCallback addPopStateListener(ui_web.PopStateListener fn) =>
      delegate.addPopStateListener(allowInterop((DomEvent event) =>
        fn((event as DomPopStateEvent).state)
      ));

  @override
  String getPath() => delegate.getPath();

  @override
  Object? getState() => delegate.getState();

  @override
  String prepareExternalUrl(String internalUrl) =>
      delegate.prepareExternalUrl(internalUrl);

  @override
  void pushState(Object? state, String title, String url) =>
      delegate.pushState(state, title, url);

  @override
  void replaceState(Object? state, String title, String url) =>
      delegate.replaceState(state, title, url);

  @override
  Future<void> go(int count) => delegate.go(count.toDouble());
}
