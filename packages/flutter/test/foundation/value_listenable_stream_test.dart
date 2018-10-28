// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('valueListenableToStreamAdapter', (WidgetTester tester) async {
    final List<String> logs = <String>[];
    final ValueNotifier<int> listenable = ValueNotifier<int>(null);
    final Stream<int> stream = valueListenableToStreamAdapter<int>(listenable);
    final StreamSubscription<int> subscription = stream.listen(
      (int event) {
        logs.add('data $event');
      },
    );
    expect(logs, <String>[]);
    listenable.value = 1;
    expect(logs, <String>[]);
    await tester.idle();
    expect(logs, <String>['data 1']);
    listenable.value = 2;
    listenable.value = 3;
    expect(logs, <String>['data 1']);
    await tester.idle();
    expect(logs, <String>['data 1', 'data 2', 'data 3']);
    subscription.pause();
    listenable.value = 4;
    await tester.idle();
    expect(logs, <String>['data 1', 'data 2', 'data 3']);
    subscription.resume();
    listenable.value = 5;
    expect(logs, <String>['data 1', 'data 2', 'data 3']);
    await tester.idle();
    expect(logs, <String>['data 1', 'data 2', 'data 3', 'data 5']);
    listenable.value = 6;
    subscription.cancel();
    await tester.idle();
    listenable.value = 7;
    await tester.idle();
    expect(logs, <String>['data 1', 'data 2', 'data 3', 'data 5']);
  });
  testWidgets('valueToFutureAdapter', (WidgetTester tester) async {
    final ValueNotifier<int> listenable = ValueNotifier<int>(null);
    bool returnValue = false;
    bool done = false;
    final Future<void> future = listenableToFutureAdapter(listenable, () => returnValue);
    future.then((void value) { done = true; });
    expect(done, isFalse);
    await tester.idle();
    expect(done, isFalse);
    await tester.idle();
    listenable.value = 1;
    await tester.idle();
    expect(done, isFalse);
    returnValue = true;
    await tester.idle();
    expect(done, isFalse);
    listenable.value = 1;
    await tester.idle();
    expect(done, isFalse);
    listenable.value = 2;
    await tester.idle();
    expect(done, isTrue);
  });
  testWidgets('listenableToFutureAdapter', (WidgetTester tester) async {
    final ValueNotifier<int> listenable = ValueNotifier<int>(null);
    bool returnValue = false;
    int done = -1;
    final Future<int> future = valueListenableToFutureAdapter<int>(listenable, (int value) => returnValue);
    future.then((int value) { done = value; });
    expect(done, -1);
    await tester.idle();
    expect(done, -1);
    await tester.idle();
    listenable.value = 1;
    await tester.idle();
    expect(done, -1);
    returnValue = true;
    await tester.idle();
    expect(done, -1);
    listenable.value = 1;
    await tester.idle();
    expect(done, -1);
    listenable.value = 2;
    await tester.idle();
    expect(done, 2);
  });
  testWidgets('listenableToFutureAdapter - with changes', (WidgetTester tester) async {
    final ValueNotifier<int> listenable = ValueNotifier<int>(null);
    bool done = false;
    final Future<void> future = listenableToFutureAdapter(listenable, () {
      listenable.value = 2; // should cause it to throw
      return true;
    });
    future.then(
      (void value) { expectSync(true, isFalse); },
      onError: (dynamic error, StackTrace stack) {
        done = error is StateError && error.message.contains('listenableToFutureAdapter');
      },
    );
    listenable.value = 1;
    expect(done, isFalse);
    await tester.idle();
    expect(done, isTrue);
    expect(listenable.value, 2);
  });
  testWidgets('valueListenableToFutureAdapter - with changes', (WidgetTester tester) async {
    final ValueNotifier<int> listenable = ValueNotifier<int>(null);
    bool done = false;
    final Future<int> future = valueListenableToFutureAdapter<int>(listenable, (int value) {
      listenable.value = 2; // should cause it to throw
      return true;
    });
    future.then(
      (int value) { expectSync(true, isFalse); },
      onError: (dynamic error, StackTrace stack) {
        done = error is StateError && error.message.contains('valueListenableToFutureAdapter');
      },
    );
    listenable.value = 1;
    expect(done, isFalse);
    await tester.idle();
    expect(done, isTrue);
    expect(listenable.value, 2);
  });
  testWidgets('listenableToFutureAdapter - with error', (WidgetTester tester) async {
    final ValueNotifier<int> listenable = ValueNotifier<int>(null);
    bool done = false;
    final Future<void> future = listenableToFutureAdapter(listenable, () {
      throw 'test';
    });
    future.then(
      (void value) { expectSync(true, isFalse); },
      onError: (dynamic error, StackTrace stack) {
        done = error == 'test';
      },
    );
    listenable.value = 1;
    expect(done, isFalse);
    await tester.idle();
    expect(done, isTrue);
  });
  testWidgets('valueListenableToFutureAdapter - with changes', (WidgetTester tester) async {
    final ValueNotifier<int> listenable = ValueNotifier<int>(null);
    bool done = false;
    final Future<int> future = valueListenableToFutureAdapter<int>(listenable, (int value) {
      throw 'test';
    });
    future.then(
      (int value) { expectSync(true, isFalse); },
      onError: (dynamic error, StackTrace stack) {
        done = error == 'test';
      },
    );
    listenable.value = 1;
    expect(done, isFalse);
    await tester.idle();
    expect(done, isTrue);
  });
}