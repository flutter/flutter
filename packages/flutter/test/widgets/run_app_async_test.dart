// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.resetEpoch();
  });

  test('WidgetBinding build rendering tree and warm up frame back to back', () {
    final FakeAsync fakeAsync = FakeAsync();
    fakeAsync.run((FakeAsync async) {
      runApp(
        const MaterialApp(
          home: Material(
            child: Text('test'),
          ),
        ),
      );
      // Rendering tree is not built synchronously.
      expect(WidgetsBinding.instance.renderViewElement, isNull);
      fakeAsync.flushTimers();
      expect(WidgetsBinding.instance.renderViewElement, isNotNull);
    });
  });

  test('runApp.onFlutterInitialized callback is executed if it is not null', () async {
    final FakeAsync fakeAsync = FakeAsync();
    int count = 0;
    fakeAsync.run((FakeAsync async) {
      runApp(
          const Placeholder(),
          onFlutterInitialized: () {
            count ++;
          },
      );

      expect(count, equals(0));
      async.flushTimers();
      expect(count, equals(1));
    });
  });
}
