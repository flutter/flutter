// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
@TestOn('!safari')
// TODO(nurhan): https://github.com/flutter/flutter/issues/51169

import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../spy.dart';

TestLocationStrategy _strategy;
TestLocationStrategy get strategy => _strategy;
set strategy(TestLocationStrategy newStrategy) {
  window.locationStrategy = _strategy = newStrategy;
}

const Map<String, bool> originState = <String, bool>{'origin': true};
const Map<String, bool> flutterState = <String, bool>{'flutter': true};

const MethodCodec codec = JSONMethodCodec();

void emptyCallback(ByteData date) {}

void main() {
  group('BrowserHistory', () {
    final PlatformMessagesSpy spy = PlatformMessagesSpy();

    setUp(() {
      spy.setUp();
    });

    tearDown(() {
      spy.tearDown();
      strategy = null;
    });

    test('basic setup works', () {
      strategy = TestLocationStrategy.fromEntry(
          TestHistoryEntry('initial state', null, '/initial'));

      // There should be two entries: origin and flutter.
      expect(strategy.history, hasLength(2));

      // The origin entry is setup but its path should remain unchanged.
      final TestHistoryEntry originEntry = strategy.history[0];
      expect(originEntry.state, originState);
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
      strategy =
          TestLocationStrategy.fromEntry(TestHistoryEntry(null, null, '/home'));

      // Initially, we should be on the flutter entry.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/home');

      pushRoute('/page1');
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
      strategy =
          TestLocationStrategy.fromEntry(TestHistoryEntry(null, null, '/home'));

      pushRoute('/page1');
      pushRoute('/page2');

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
      popRoute('/page1');
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
      popRoute('/home');
      // 3. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/home');

      // The next browser back will exit the app.
      await strategy.back();
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
      expect(strategy.currentEntryIndex, -1);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge ||
            browserEngine == BrowserEngine.webkit);

    test('handle user-provided url', () async {
      strategy =
          TestLocationStrategy.fromEntry(TestHistoryEntry(null, null, '/home'));

      await _strategy.simulateUserTypingUrl('/page3');
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
      pushRoute('/page3');
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
      popRoute('/home');
      // 3. The history state should reflect that /page1 is currently active.
      expect(strategy.history, hasLength(2));
      expect(strategy.currentEntryIndex, 1);
      expect(strategy.currentEntry.state, flutterState);
      expect(strategy.currentEntry.url, '/home');
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50836
        skip: browserEngine == BrowserEngine.edge);

    test('user types unknown url', () async {
      strategy =
          TestLocationStrategy.fromEntry(TestHistoryEntry(null, null, '/home'));

      await _strategy.simulateUserTypingUrl('/unknown');
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
}

void pushRoute(String routeName) {
  window.sendPlatformMessage(
    'flutter/navigation',
    codec.encodeMethodCall(MethodCall(
      'routePushed',
      <String, dynamic>{'previousRouteName': '/foo', 'routeName': routeName},
    )),
    emptyCallback,
  );
}

void replaceRoute(String routeName) {
  window.sendPlatformMessage(
    'flutter/navigation',
    codec.encodeMethodCall(MethodCall(
      'routeReplaced',
      <String, dynamic>{'previousRouteName': '/foo', 'routeName': routeName},
    )),
    emptyCallback,
  );
}

void popRoute(String previousRouteName) {
  window.sendPlatformMessage(
    'flutter/navigation',
    codec.encodeMethodCall(MethodCall(
      'routePopped',
      <String, dynamic>{
        'previousRouteName': previousRouteName,
        'routeName': '/foo'
      },
    )),
    emptyCallback,
  );
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
