// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' hide window;
import 'package:ui/ui.dart' as ui;

import 'engine/history_test.dart';
import 'matchers.dart';

const MethodCodec codec = JSONMethodCodec();

void emptyCallback(ByteData data) {}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  EngineSingletonFlutterWindow window;

  setUp(() {
    ui.webOnlyInitializeEngine();
    window = EngineSingletonFlutterWindow(0, EnginePlatformDispatcher.instance);
  });

  tearDown(() async {
    await window.debugResetHistory();
    window = null;
  });

  test('window.defaultRouteName should not change', () async {
    final TestUrlStrategy strategy = TestUrlStrategy.fromEntry(
      TestHistoryEntry('initial state', null, '/initial'),
    );
    await window.debugInitializeHistory(strategy, useSingle: true);
    expect(window.defaultRouteName, '/initial');

    // Changing the URL in the address bar later shouldn't affect [window.defaultRouteName].
    strategy.replaceState(null, null, '/newpath');
    expect(window.defaultRouteName, '/initial');
  });

  test('window.defaultRouteName should reset after navigation platform message',
      () async {
    await window.debugInitializeHistory(TestUrlStrategy.fromEntry(
      TestHistoryEntry('initial state', null, '/initial'),
    ), useSingle: true);
    // Reading it multiple times should return the same value.
    expect(window.defaultRouteName, '/initial');
    expect(window.defaultRouteName, '/initial');
    window.sendPlatformMessage(
      'flutter/navigation',
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routeUpdated',
        <String, dynamic>{'routeName': '/bar'},
      )),
      emptyCallback,
    );
    // After a navigation platform message, [window.defaultRouteName] should
    // reset to "/".
    expect(window.defaultRouteName, '/');
  });

  test('can disable location strategy', () async {
    // Disable URL strategy.
    expect(() => jsSetUrlStrategy(null), returnsNormally);
    // History should be initialized.
    expect(window.browserHistory, isNotNull);
    // But without a URL strategy.
    expect(window.browserHistory.urlStrategy, isNull);
    // Current path is always "/" in this case.
    expect(window.browserHistory.currentPath, '/');

    // Perform some navigation operations.
    routeInformationUpdated('/foo/bar', null);
    // Path should not be updated because URL strategy is disabled.
    expect(window.browserHistory.currentPath, '/');
  });

  test('js interop throws on wrong type', () {
    expect(() => jsSetUrlStrategy(123), throwsA(anything));
    expect(() => jsSetUrlStrategy('foo'), throwsA(anything));
    expect(() => jsSetUrlStrategy(false), throwsA(anything));
  });

  test('cannot set url strategy after it is initialized', () async {
    final testStrategy = TestUrlStrategy.fromEntry(
      TestHistoryEntry('initial state', null, '/'),
    );
    await window.debugInitializeHistory(testStrategy, useSingle: true);

    expect(() => jsSetUrlStrategy(null), throwsA(isAssertionError));
  });

  test('cannot set url strategy more than once', () async {
    // First time is okay.
    expect(() => jsSetUrlStrategy(null), returnsNormally);
    // Second time is not allowed.
    expect(() => jsSetUrlStrategy(null), throwsA(isAssertionError));
  });
}

void jsSetUrlStrategy(dynamic strategy) {
  js_util.callMethod(
    html.window,
    '_flutter_web_set_location_strategy',
    <dynamic>[strategy],
  );
}
