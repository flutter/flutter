// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debugRethrowError rethrows caught error', (WidgetTester tester) async {
    FutureBuilder.debugRethrowError = true;
    final Completer<void> caughtError = Completer<void>();
    await runZonedGuarded(() async {
      final Completer<String> completer = Completer<String>();
      await tester.pumpWidget(FutureBuilder<String>(
        future: completer.future,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          return Text(snapshot.toString(), textDirection: TextDirection.ltr);
        },
      ), const Duration(seconds: 1));
      completer.completeError('bad');
    }, (Object error, StackTrace stack) {
      expectSync(error, equals('bad'));
      caughtError.complete();
    });
    await tester.pumpAndSettle();
    expectSync(caughtError.isCompleted, isFalse);
    FutureBuilder.debugRethrowError = true;
  });
}