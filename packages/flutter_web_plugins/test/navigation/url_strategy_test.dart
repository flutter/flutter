// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

@TestOn('chrome') // Uses web-only Flutter SDK

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  group('$HashUrlStrategy', () {
    late TestPlatformLocation location;

    setUp(() {
      location = TestPlatformLocation();
    });

    test('leading slash is optional', () {
      final HashUrlStrategy strategy = HashUrlStrategy(location);

      location.hash = '#/';
      expect(strategy.getPath(), '/');

      location.hash = '#/foo';
      expect(strategy.getPath(), '/foo');

      location.hash = '#foo';
      expect(strategy.getPath(), 'foo');
    });

    test('path must be prepended with octothorpe', () {
      final HashUrlStrategy strategy = HashUrlStrategy(location);

      location.hash = '/';
      expect(strategy.getPath(), '/');

      location.hash = '/foo';
      expect(strategy.getPath(), '/');

      location.hash = 'foo';
      expect(strategy.getPath(), '/');
    });

    test('path should not be empty', () {
      final HashUrlStrategy strategy = HashUrlStrategy(location);

      location.hash = '';
      expect(strategy.getPath(), '/');

      location.hash = '#';
      expect(strategy.getPath(), '/');
    });

    test('generates external path correctly in the presence of BrowserLocation',
        () {
      final HashUrlStrategy strategy1 = HashUrlStrategy();

      expect(strategy1.prepareExternalUrl(''),
          '/navigation/url_strategy_test.html');
      expect(strategy1.prepareExternalUrl('/'), '#/');
      expect(strategy1.prepareExternalUrl('bar'), '#bar');
      expect(strategy1.prepareExternalUrl('/bar'), '#/bar');
      expect(strategy1.prepareExternalUrl('/bar/'), '#/bar/');
    });

    test('pushState and replaceState', () {
      final HashUrlStrategy strategy1 = HashUrlStrategy();

      strategy1.pushState("state", "title", "url");
      expect(strategy1.getState(), "state");

      strategy1.pushState("", "title", "url");
      expect(strategy1.getState(), "");

      strategy1.replaceState("state", "title", "url");
      expect(strategy1.getState(), "state");

      strategy1.replaceState("", "title", "url");
      expect(strategy1.getState(), "");
    });
  });

  group('$PathUrlStrategy', () {
    late TestPlatformLocation location;

    setUp(() {
      location = TestPlatformLocation();
    });

    test('validates base href', () {
      location.baseHref = '/';
      expect(
        () => PathUrlStrategy(location),
        returnsNormally,
      );

      location.baseHref = '/foo/';
      expect(
        () => PathUrlStrategy(location),
        returnsNormally,
      );

      location.baseHref = '';
      expect(
        () => PathUrlStrategy(location),
        throwsException,
      );

      location.baseHref = 'foo';
      expect(
        () => PathUrlStrategy(location),
        throwsException,
      );

      location.baseHref = '/foo';
      expect(
        () => PathUrlStrategy(location),
        throwsException,
      );
    });

    test('leading slash is always prepended', () {
      location.baseHref = '/';
      final PathUrlStrategy strategy = PathUrlStrategy(location);

      location.pathname = '';
      expect(strategy.getPath(), '/');

      location.pathname = 'foo';
      expect(strategy.getPath(), '/foo');
    });

    test('gets path correctly in the presence of basePath', () {
      location.baseHref = 'https://example.com/foo/';
      final PathUrlStrategy strategy = PathUrlStrategy(location);

      location.pathname = '/foo/';
      expect(strategy.getPath(), '/');

      location.pathname = '/foo';
      expect(strategy.getPath(), '/');

      location.pathname = '/foo/bar';
      expect(strategy.getPath(), '/bar');
    });

    test('gets path correctly in the presence of query params', () {
      location.baseHref = 'https://example.com/foo/';
      location.pathname = '/foo/bar';
      final PathUrlStrategy strategy = PathUrlStrategy(location);

      location.search = '?q=1';
      expect(strategy.getPath(), '/bar?q=1');

      location.search = '?q=1&t=r';
      expect(strategy.getPath(), '/bar?q=1&t=r');
    });

    test('generates external path correctly in the presence of basePath', () {
      location.baseHref = 'https://example.com/foo/';
      final PathUrlStrategy strategy = PathUrlStrategy(location);

      expect(strategy.prepareExternalUrl(''), '/foo');
      expect(strategy.prepareExternalUrl('/'), '/foo/');
      expect(strategy.prepareExternalUrl('bar'), '/foo/bar');
      expect(strategy.prepareExternalUrl('/bar'), '/foo/bar');
      expect(strategy.prepareExternalUrl('/bar/'), '/foo/bar/');
    });
  });
}

/// A mock implementation of [PlatformLocation] that doesn't access the browser.
class TestPlatformLocation extends PlatformLocation {
  @override
  String pathname = '';

  @override
  String search = '';

  @override
  String hash = '';

  @override
  Object? Function() state = () => null;

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
  void pushState(dynamic state, String title, String url) {
    throw UnimplementedError();
  }

  @override
  void replaceState(dynamic state, String title, String url) {
    throw UnimplementedError();
  }

  @override
  void go(int count) {
    throw UnimplementedError();
  }

  @override
  String getBaseHref() => baseHref;
}
