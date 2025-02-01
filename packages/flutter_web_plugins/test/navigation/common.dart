// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web_plugins/url_strategy.dart';

/// A mock implementation of [PlatformLocation] that doesn't access the browser.
class TestPlatformLocation implements PlatformLocation {
  @override
  String pathname = '';

  @override
  String search = '';

  @override
  String hash = '';

  @override
  Object? get state => null;

  /// Mocks the base href of the document.
  String baseHref = '';

  @override
  void addPopStateListener(EventListener fn) {
    throw UnimplementedError();
  }

  @override
  void removePopStateListener(EventListener fn) {
    throw UnimplementedError();
  }

  @override
  void pushState(Object? state, String title, String url) {}

  @override
  void replaceState(Object? state, String title, String url) {}

  @override
  void go(int count) {
    throw UnimplementedError();
  }

  @override
  String getBaseHref() => baseHref;
}
