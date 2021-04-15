// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' hide window;
import 'package:ui/ui.dart' as ui;

import 'engine/history_test.dart';
import 'matchers.dart';

const MethodCodec codec = JSONMethodCodec();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  late EngineSingletonFlutterWindow window;

  setUp(() {
    ui.webOnlyInitializeEngine();
    window = EngineSingletonFlutterWindow(0, EnginePlatformDispatcher.instance);
  });

  tearDown(() async {
    await window.resetHistory();
  });

  test('window.defaultRouteName should not change', () async {
    final TestUrlStrategy strategy = TestUrlStrategy.fromEntry(
      TestHistoryEntry('initial state', null, '/initial'),
    );
    await window.debugInitializeHistory(strategy, useSingle: true);
    expect(window.defaultRouteName, '/initial');

    // Changing the URL in the address bar later shouldn't affect [window.defaultRouteName].
    strategy.replaceState(null, '', '/newpath');
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

    Completer<void> callback = Completer<void>();
    window.sendPlatformMessage(
      'flutter/navigation',
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routeUpdated',
        <String, dynamic>{'routeName': '/bar'},
      )),
      (_) { callback.complete(); },
    );
    // After a navigation platform message, [window.defaultRouteName] should
    // reset to "/".
    expect(window.defaultRouteName, '/');
  });

  test('should throw when using nav1 and nav2 together',
      () async {
    await window.debugInitializeHistory(TestUrlStrategy.fromEntry(
      TestHistoryEntry('initial state', null, '/initial'),
    ), useSingle: false);
    // Receive nav1 update first.
    Completer<void> callback = Completer<void>();
    window.sendPlatformMessage(
      'flutter/navigation',
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routeUpdated',
        <String, dynamic>{'routeName': '/bar'},
      )),
      (_) { callback.complete(); },
    );
    await callback.future;
    expect(window.browserHistory is SingleEntryBrowserHistory, true);
    expect(window.browserHistory.urlStrategy!.getPath(), '/bar');

    // We can still receive nav2 update.
    callback = Completer<void>();
    window.sendPlatformMessage(
      'flutter/navigation',
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routeInformationUpdated',
        <String, dynamic>{
          'location': '/baz',
          'state': null,
        },
      )),
      (_) { callback.complete(); },
    );
    await callback.future;
    expect(window.browserHistory is MultiEntriesBrowserHistory, true);
    expect(window.browserHistory.urlStrategy!.getPath(), '/baz');

    // Throws assertion error if it receives nav1 update after nav2 update.
    late AssertionError caughtAssertion;
    await window.handleNavigationMessage(
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routeUpdated',
        <String, dynamic>{'routeName': '/foo'},
      ))
    ).catchError((Object e) {
      caughtAssertion = e as AssertionError;
    });

    expect(
      caughtAssertion.message,
      'Receives old navigator update in a router application. This can '
      'happen if you use non-router versions of '
      'MaterialApp/CupertinoApp/WidgetsApp together with the router versions of them.'
    );
    // The history does not change.
    expect(window.browserHistory is MultiEntriesBrowserHistory, true);
    expect(window.browserHistory.urlStrategy!.getPath(), '/baz');
  });

  test('initialize browser history with default url strategy (single)', () async {
    // On purpose, we don't initialize history on the window. We want to let the
    // window to self-initialize when it receives a navigation message.

    // Without initializing history, the default route name should be
    // initialized to "/" in tests.
    expect(window.defaultRouteName, '/');

    Completer<void> callback = Completer<void>();
    window.sendPlatformMessage(
      'flutter/navigation',
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routeUpdated',
        <String, dynamic>{'routeName': '/bar'},
      )),
      (_) { callback.complete(); },
    );
    await callback.future;
    expect(window.browserHistory is SingleEntryBrowserHistory, true);
    // The url strategy should've been set to the default, and the path
    // should've been correctly set to "/bar".
    expect(window.browserHistory.urlStrategy, isNot(isNull));
    expect(window.browserHistory.urlStrategy!.getPath(), '/bar');
  }, skip: true); // https://github.com/flutter/flutter/issues/50836

  test('initialize browser history with default url strategy (multiple)', () async {
    // On purpose, we don't initialize history on the window. We want to let the
    // window to self-initialize when it receives a navigation message.

    // Without initializing history, the default route name should be
    // initialized to "/" in tests.
    expect(window.defaultRouteName, '/');

    Completer<void> callback = Completer<void>();
    window.sendPlatformMessage(
      'flutter/navigation',
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routeInformationUpdated',
        <String, dynamic>{
          'location': '/baz',
          'state': null,
        },
      )),
      (_) { callback.complete(); },
    );
    await callback.future;
    expect(window.browserHistory is MultiEntriesBrowserHistory, true);
    // The url strategy should've been set to the default, and the path
    // should've been correctly set to "/baz".
    expect(window.browserHistory.urlStrategy, isNot(isNull));
    expect(window.browserHistory.urlStrategy!.getPath(), '/baz');
  }, skip: true); // https://github.com/flutter/flutter/issues/50836

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
    await routeInformationUpdated('/foo/bar', null);
    // Path should not be updated because URL strategy is disabled.
    expect(window.browserHistory.currentPath, '/');
  }, skip: true);

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

  // Regression test for https://github.com/flutter/flutter/issues/77817
  test('window.locale(s) are not nullable', () {
    // If the getters were nullable, these expressions would result in compiler errors.
    ui.window.locale.countryCode;
    ui.window.locales.first.countryCode;
  });
}

void jsSetUrlStrategy(dynamic strategy) {
  js_util.callMethod(
    html.window,
    '_flutter_web_set_location_strategy',
    <dynamic>[strategy],
  );
}
