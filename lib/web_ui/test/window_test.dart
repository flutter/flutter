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

  // window.defaultRouteName is now permanently decoupled from the history,
  // even in subsequent tests, because the PlatformDispatcher caches it.

  test('window.defaultRouteName should reset after navigation platform message',
      () async {
    await window.debugInitializeHistory(TestUrlStrategy.fromEntry(
      // The URL here does not set the PlatformDispatcher's defaultRouteName,
      // since it got cached as soon as we read it above.
      TestHistoryEntry('initial state', null, '/not-really-inital/THIS_IS_IGNORED'),
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
    await callback.future;
    // After a navigation platform message, the PlatformDispatcher's
    // defaultRouteName resets to "/".
    expect(window.defaultRouteName, '/');
  });

  // window.defaultRouteName is now '/'.

  test('can switch history mode', () async {
    Completer<void> callback;
    await window.debugInitializeHistory(TestUrlStrategy.fromEntry(
      TestHistoryEntry('initial state', null, '/initial'),
    ), useSingle: false);
    expect(window.browserHistory, isA<MultiEntriesBrowserHistory>());

    Future<void> check<T>(String method, Map<String, Object?> arguments) async {
      callback = Completer<void>();
      window.sendPlatformMessage(
        'flutter/navigation',
        JSONMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
        (_) { callback.complete(); },
      );
      await callback.future;
      expect(window.browserHistory, isA<T>());
    }

    await check<SingleEntryBrowserHistory>('selectSingleEntryHistory', <String, dynamic>{}); // -> single
    await check<MultiEntriesBrowserHistory>('selectMultiEntryHistory', <String, dynamic>{}); // -> multi
    await check<SingleEntryBrowserHistory>('routeUpdated', <String, dynamic>{'routeName': '/bar'}); // -> single
    await check<SingleEntryBrowserHistory>('routeInformationUpdated', <String, dynamic>{'location': '/bar'}); // does not change mode
    await check<MultiEntriesBrowserHistory>('selectMultiEntryHistory', <String, dynamic>{}); // -> multi
    await check<MultiEntriesBrowserHistory>('routeInformationUpdated', <String, dynamic>{'location': '/bar'}); // does not change mode
  });

  test('should not throw when using nav1 and nav2 together',
      () async {
    await window.debugInitializeHistory(TestUrlStrategy.fromEntry(
      TestHistoryEntry('initial state', null, '/initial'),
    ), useSingle: false);
    expect(window.browserHistory, isA<MultiEntriesBrowserHistory>());

    // routeUpdated resets the history type
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
    expect(window.browserHistory, isA<SingleEntryBrowserHistory>());
    expect(window.browserHistory.urlStrategy!.getPath(), '/bar');

    // routeInformationUpdated does not
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
    expect(window.browserHistory, isA<SingleEntryBrowserHistory>());
    expect(window.browserHistory.urlStrategy!.getPath(), '/baz');

    // they can be interleaved safely
    await window.handleNavigationMessage(
      JSONMethodCodec().encodeMethodCall(MethodCall(
        'routeUpdated',
        <String, dynamic>{'routeName': '/foo'},
      ))
    );
    expect(window.browserHistory, isA<SingleEntryBrowserHistory>());
    expect(window.browserHistory.urlStrategy!.getPath(), '/foo');
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
    expect(window.browserHistory, isA<SingleEntryBrowserHistory>());
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
    expect(window.browserHistory, isA<MultiEntriesBrowserHistory>());
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
