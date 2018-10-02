// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Events bubble up the tree', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
      Listener(
        onPointerDown: (_) {
          log.add('top');
        },
        child: Listener(
          onPointerDown: (_) {
            log.add('middle');
          },
          child: DecoratedBox(
            decoration: const BoxDecoration(),
            child: Listener(
              onPointerDown: (_) {
                log.add('bottom');
              },
              child: const Text('X', textDirection: TextDirection.ltr)
            )
          )
        )
      )
    );

    await tester.tap(find.text('X'));

    expect(log, equals(<String>[
      'bottom',
      'middle',
      'top',
    ]));
  });
}
