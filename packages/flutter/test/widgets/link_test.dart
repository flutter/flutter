// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('Gestures', () {
    testWidgets(
      'Recognizes tap',
      (WidgetTester tester) async {
        await tester.pumpWidget(WidgetsApp(
          color: const Color.fromRGBO(255, 255, 255, 1.0),
          home: const Link.internal(
            routeName: '/foo',
            child: Text('Foo'),
          ),
        ));
      },
    );

    testWidgets(
      'Recognizes tap when child is also listening for tap',
      (WidgetTester tester) async {
        await tester.pumpWidget(WidgetsApp(
          color: const Color.fromRGBO(255, 255, 255, 1.0),
          home: Link.internal(
            routeName: '/foo',
            child: GestureDetector(
              onTap: () {
                // This should be called && the link should also work.
              },
              child: const Text('Foo'),
            ),
          ),
        ));
      },
    );

    testWidgets(
      'Ancestors do not recognize taps',
      (WidgetTester tester) async {
        await tester.pumpWidget(WidgetsApp(
          color: const Color.fromRGBO(255, 255, 255, 1.0),
          home: GestureDetector(
            onTap: () {
              // This should NOT be called.
            },
            child: const Link.internal(
              routeName: '/foo',
              child: Text('Foo'),
            ),
          ),
        ));
      },
    );
  });
}
