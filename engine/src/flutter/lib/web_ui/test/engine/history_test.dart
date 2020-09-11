// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
@TestOn('!safari')
// TODO(nurhan): https://github.com/flutter/flutter/issues/51169

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../spy.dart';

TestLocationStrategy get strategy => window.browserHistory.locationStrategy;
Future<void> setStrategy(TestLocationStrategy newStrategy) async {
  await window.browserHistory.setLocationStrategy(newStrategy);
}

Map<String, dynamic> _wrapOriginState(dynamic state) {
  return <String, dynamic>{'origin': true, 'state': state};
}

Map<String, dynamic> _tagStateWithSerialCount(dynamic state, int serialCount) {
  return <String, dynamic> {
    'serialCount': serialCount,
    'state': state,
  };
}

const Map<String, bool> originState = <String, bool>{'origin': true};
const Map<String, bool> flutterState = <String, bool>{'flutter': true};

const MethodCodec codec = JSONMethodCodec();

void emptyCallback(ByteData date) {}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$SingleEntryBrowserHistory', () {
    final PlatformMessagesSpy spy = PlatformMessagesSpy();

    setUp(() async {
      await window.debugSwitchBrowserHistory(useSingle: true);
      spy.setUp();
    });

    tearDown(() async {
      spy.tearDown();
      await setStrategy(null);
    });

    test('basic setup works', () async {
      await setStrategy(TestLocationStrategy.fromEntry(
          TestHistoryEntry('initial state', null, '/initial')));

      // There should be two entries: origin and flutter.
      expect(strategy.history, hasLength(2));

      // The origin entry is setup but its path should remain unchanged.
      final TestHistoryEntry originEntry = strategy.history[0];
      expect(originEntry.state, _wrapOriginState('initial state'));
      expect(originEntry.url, '/initial');

      // The flutter entry is pushed and its path should be derived from the
      // origin entry.
      final TestHistoryEntry flutterEntry = strategy.history[1];
      expect(flutterEntry.state, flutterState);
      expect(flutterEntry.url, '/initial');

      // The flutter entry is the current entry.
      expect(strategy.currentEntry, flutterEntry);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);

    test('browser back button pops routes correctly', () async {
      await setStrategy(TestLocationStrategy.fromEntry(TestHistoryEntry(null, null, '/home')));
      // Initially, we should be on the flutter entry.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/home');
      await routeUpdated('/page1');
      // The number of entries shouldn't change.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      // But the url of the current entry (flutter entry) should be updated.
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/page1');

      // No platform messages have been sent so far.
      expect(spy.messages, isEmpty);
      // Clicking back should take us to page1.
      await strategy.back();
      // First, the framework should've received a `popRoute` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'popRoute');
      expect(spy.messages[0].methodArguments, isNull);
      // We still have 2 entries.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      // The url of the current entry (flutter entry) should go back to /home.
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/home');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);

    test('multiple browser back clicks', () async {
      await setStrategy(TestLocationStrategy.fromEntry(TestHistoryEntry(null, null, '/home')));

      await routeUpdated('/page1');
      await routeUpdated('/page2');

      // Make sure we are on page2.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/page2');

      // Back to page1.
      await strategy.back();
      // 1. The engine sends a `popRoute` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'popRoute');
      expect(spy.messages[0].methodArguments, isNull);
      spy.messages.clear();
      // 2. The framework sends a `routePopped` platform message.
      await routeUpdated('/page1');
      // 3. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/page1');

      // Back to home.
      await strategy.back();
      // 1. The engine sends a `popRoute` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'popRoute');
      expect(spy.messages[0].methodArguments, isNull);
      spy.messages.clear();
      // 2. The framework sends a `routePopped` platform message.
      await routeUpdated('/home');
      // 3. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/home');

      // The next browser back will exit the app. We store the strategy locally
      // because it will be remove from the browser history class once it exits
      // the app.
      TestLocationStrategy originalStrategy = strategy;
      await originalStrategy.back();
      // 1. The engine sends a `popRoute` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'popRoute');
      expect(spy.messages[0].methodArguments, isNull);
      spy.messages.clear();
      // 2. The framework sends a `SystemNavigator.pop` platform message
      // because there are no more routes to pop.
      await systemNavigatorPop();
      // 3. The active entry doesn't belong to our history anymore because we
      // navigated past it.
      expect(originalStrategy.currentEntryIndex, -1);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge ||
            browserEngine == BrowserEngine.webkit);

    test('handle user-provided url', () async {
      await setStrategy(TestLocationStrategy.fromEntry(TestHistoryEntry(null, null, '/home')));

      await strategy.simulateUserTypingUrl('/page3');
      // This delay is necessary to wait for [BrowserHistory] because it
      // performs a `back` operation which results in a new event loop.
      await Future<void>.delayed(Duration.zero);
      // 1. The engine sends a `pushRoute` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRoute');
      expect(spy.messages[0].methodArguments, '/page3');
      spy.messages.clear();
      // 2. The framework sends a `routePushed` platform message.
      await routeUpdated('/page3');
      // 3. The history state should reflect that /page3 is currently active.
      expect(strategy.history, hasLength(3));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/page3');

      // Back to home.
      await strategy.back();
      // 1. The engine sends a `popRoute` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'popRoute');
      expect(spy.messages[0].methodArguments, isNull);
      spy.messages.clear();
      // 2. The framework sends a `routePopped` platform message.
      await routeUpdated('/home');
      // 3. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/home');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);

    test('user types unknown url', () async {
      await setStrategy(TestLocationStrategy.fromEntry(TestHistoryEntry(null, null, '/home')));

      await strategy.simulateUserTypingUrl('/unknown');
      // This delay is necessary to wait for [BrowserHistory] because it
      // performs a `back` operation which results in a new event loop.
      await Future<void>.delayed(Duration.zero);
      // 1. The engine sends a `pushRoute` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRoute');
      expect(spy.messages[0].methodArguments, '/unknown');
      spy.messages.clear();
      // 2. The framework doesn't recognize the route name and ignores it.
      // 3. The history state should reflect that /home is currently active.
      expect(strategy.history, hasLength(3));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/home');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);
  });

  group('$MultiEntriesBrowserHistory', () {
    final PlatformMessagesSpy spy = PlatformMessagesSpy();

    setUp(() async {
      await window.debugSwitchBrowserHistory(useSingle: false);
      spy.setUp();
    });

    tearDown(() async {
      spy.tearDown();
      await setStrategy(null);
    });

    test('basic setup works', () async {
      await setStrategy(TestLocationStrategy.fromEntry(
          TestHistoryEntry('initial state', null, '/initial')));

      // There should be only one entry.
      expect(strategy.history, hasLength(1));

      // The origin entry is tagged and its path should remain unchanged.
      final TestHistoryEntry taggedOriginEntry = strategy.history[0];
      expect(taggedOriginEntry.state, _tagStateWithSerialCount('initial state', 0));
      expect(taggedOriginEntry.url, '/initial');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);

    test('browser back button push route infromation correctly', () async {
      await setStrategy(TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/home')));
      // Initially, we should be on the flutter entry.
      expect(strategy.history, hasLength(1));
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('initial state', 0));
      expect(strategy.currentEntry.url, '/home');
      await routeInfomrationUpdated('/page1', 'page1 state');
      // Should have two history entries now.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      // But the url of the current entry (flutter entry) should be updated.
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('page1 state', 1));
      expect(strategy.currentEntry.url, '/page1');

      // No platform messages have been sent so far.
      expect(spy.messages, isEmpty);
      // Clicking back should take us to page1.
      await strategy.back();
      // First, the framework should've received a `pushRouteInformation`
      // platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRouteInformation');
      expect(spy.messages[0].methodArguments, <dynamic, dynamic>{
        'location': '/home',
        'state': 'initial state',
      });
      // There are still two browser history entries, but we are back to the
      // original state.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 0);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('initial state', 0));
      expect(strategy.currentEntry.url, '/home');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);

    test('multiple browser back clicks', () async {
      await setStrategy(TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/home')));

      await routeInfomrationUpdated('/page1', 'page1 state');
      await routeInfomrationUpdated('/page2', 'page2 state');

      // Make sure we are on page2.
      expect(strategy.history, hasLength(3));
      expect(strategy.currentEntryIndex, 2);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('page2 state', 2));
      expect(strategy.currentEntry.url, '/page2');

      // Back to page1.
      await strategy.back();
      // 1. The engine sends a `pushRouteInformation` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRouteInformation');
      expect(spy.messages[0].methodArguments, <dynamic, dynamic>{
        'location': '/page1',
        'state': 'page1 state',
      });
      spy.messages.clear();
      // 2. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(3));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('page1 state', 1));
      expect(strategy.currentEntry.url, '/page1');
      // Back to home.
      await strategy.back();
      // 1. The engine sends a `pushRouteInformation` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRouteInformation');
      expect(spy.messages[0].methodArguments, <dynamic, dynamic>{
        'location': '/home',
        'state': 'initial state',
      });
      spy.messages.clear();
      // 2. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(3));
      expect(strategy.currentEntryIndex, 0);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('initial state', 0));
      expect(strategy.currentEntry.url, '/home');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge ||
            browserEngine == BrowserEngine.webkit);

    test('handle user-provided url', () async {
      await setStrategy(TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/home')));

      await strategy.simulateUserTypingUrl('/page3');
      // This delay is necessary to wait for [BrowserHistory] because it
      // performs a `back` operation which results in a new event loop.
      await Future<void>.delayed(Duration.zero);
      // 1. The engine sends a `pushRouteInformation` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRouteInformation');
      expect(spy.messages[0].methodArguments, <dynamic, dynamic>{
        'location': '/page3',
        'state': null,
      });
      spy.messages.clear();
      // 2. The history state should reflect that /page3 is currently active.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount(null, 1));
      expect(strategy.currentEntry.url, '/page3');

      // Back to home.
      await strategy.back();
      // 1. The engine sends a `pushRouteInformation` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRouteInformation');
      expect(spy.messages[0].methodArguments, <dynamic, dynamic>{
        'location': '/home',
        'state': 'initial state',
      });
      spy.messages.clear();
      // 2. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 0);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('initial state', 0));
      expect(strategy.currentEntry.url, '/home');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);

    test('forward button works', () async {
      await setStrategy(TestLocationStrategy.fromEntry(TestHistoryEntry('initial state', null, '/home')));

      await routeInfomrationUpdated('/page1', 'page1 state');
      await routeInfomrationUpdated('/page2', 'page2 state');

      // Make sure we are on page2.
      expect(strategy.history, hasLength(3));
      expect(strategy.currentEntryIndex, 2);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('page2 state', 2));
      expect(strategy.currentEntry.url, '/page2');

      // Back to page1.
      await strategy.back();
      // 1. The engine sends a `pushRouteInformation` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRouteInformation');
      expect(spy.messages[0].methodArguments, <dynamic, dynamic>{
        'location': '/page1',
        'state': 'page1 state',
      });
      spy.messages.clear();
      // 2. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(3));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('page1 state', 1));
      expect(strategy.currentEntry.url, '/page1');

      // Forward to page2
      await strategy.back(count: -1);
      // 1. The engine sends a `pushRouteInformation` platform message.
      expect(spy.messages, hasLength(1));
      expect(spy.messages[0].channel, 'flutter/navigation');
      expect(spy.messages[0].methodName, 'pushRouteInformation');
      expect(spy.messages[0].methodArguments, <dynamic, dynamic>{
        'location': '/page2',
        'state': 'page2 state',
      });
      spy.messages.clear();
      // 2. The history state should reflect that /page2 is currently active.
      expect(strategy.history, hasLength(3));
      expect(strategy.currentEntryIndex, 2);
      expect(strategy.currentEntry.state, _tagStateWithSerialCount('page2 state', 2));
      expect(strategy.currentEntry.url, '/page2');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);
  });

  group('$HashLocationStrategy', () {
    TestPlatformLocation location;

    setUp(() {
      location = TestPlatformLocation();
    });

    tearDown(() {
      location = null;
    });

    test('leading slash is optional', () {
      final HashLocationStrategy strategy = HashLocationStrategy(location);

      location.hash = '#/';
      expect(strategy.path, '/');

      location.hash = '#/foo';
      expect(strategy.path, '/foo');

      location.hash = '#foo';
      expect(strategy.path, 'foo');
    });

    test('path should not be empty', () {
      final HashLocationStrategy strategy = HashLocationStrategy(location);

      location.hash = '';
      expect(strategy.path, '/');

      location.hash = '#';
      expect(strategy.path, '/');
    });
  });
}

Future<void> routeUpdated(String routeName) {
  final Completer<void> completer = Completer<void>();
  window.sendPlatformMessage(
    'flutter/navigation',
    codec.encodeMethodCall(MethodCall(
      'routeUpdated',
      <String, dynamic>{'routeName': routeName},
    )),
    (_) => completer.complete(),
  );
  return completer.future;
}

Future<void> routeInfomrationUpdated(String location, dynamic state) {
  final Completer<void> completer = Completer<void>();
  window.sendPlatformMessage(
    'flutter/navigation',
    codec.encodeMethodCall(MethodCall(
      'routeInformationUpdated',
      <String, dynamic>{'location': location, 'state': state},
    )),
    (_) => completer.complete(),
  );
  return completer.future;
}

Future<void> systemNavigatorPop() {
  final Completer<void> completer = Completer<void>();
  window.sendPlatformMessage(
    'flutter/platform',
    codec.encodeMethodCall(MethodCall('SystemNavigator.pop')),
    (_) => completer.complete(),
  );
  return completer.future;
}

/// A mock implementation of [PlatformLocation] that doesn't access the browser.
class TestPlatformLocation extends PlatformLocation {
  String pathname;
  String search;
  String hash;
  dynamic state;

  void onPopState(html.EventListener fn) {
    throw UnimplementedError();
  }

  void offPopState(html.EventListener fn) {
    throw UnimplementedError();
  }

  void onHashChange(html.EventListener fn) {
    throw UnimplementedError();
  }

  void offHashChange(html.EventListener fn) {
    throw UnimplementedError();
  }

  void pushState(dynamic state, String title, String url) {
    throw UnimplementedError();
  }

  void replaceState(dynamic state, String title, String url) {
    throw UnimplementedError();
  }

  void back(int count) {
    throw UnimplementedError();
  }
}
