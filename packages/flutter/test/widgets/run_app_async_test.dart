// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance!.resetEpoch();
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
      expect(WidgetsBinding.instance!.renderViewElement, isNull);
      fakeAsync.flushTimers();
      expect(WidgetsBinding.instance!.renderViewElement, isNotNull);
    });
  });
}
