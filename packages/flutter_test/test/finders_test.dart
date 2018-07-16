// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('text', () {
    testWidgets('finds Text widgets', (WidgetTester tester) async {
      await tester.pumpWidget(_boilerplate(
        const Text('test'),
      ));
      expect(find.text('test'), findsOneWidget);
    });
  
    testWidgets('finds Text.rich widgets', (WidgetTester tester) async {
      await tester.pumpWidget(_boilerplate(
        const Text.rich(
          TextSpan(text: 't', children: <TextSpan>[
            const TextSpan(text: 'e'),
            const TextSpan(text: 'st'),
          ]
        ),
      )));

      expect(find.text('test'), findsOneWidget);
    });
  });

  group('hitTestable', () {
    testWidgets('excludes non-hit-testable widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        _boilerplate(new IndexedStack(
          sizing: StackFit.expand,
          children: <Widget>[
            new GestureDetector(
              key: const ValueKey<int>(0),
              behavior: HitTestBehavior.opaque,
              onTap: () { },
              child: const SizedBox.expand(),
            ),
            new GestureDetector(
              key: const ValueKey<int>(1),
              behavior: HitTestBehavior.opaque,
              onTap: () { },
              child: const SizedBox.expand(),
            ),
          ],
        )),
      );
      expect(find.byType(GestureDetector), findsNWidgets(2));
      final Finder hitTestable = find.byType(GestureDetector).hitTestable(at: Alignment.center);
      expect(hitTestable, findsOneWidget);
      expect(tester.widget(hitTestable).key, const ValueKey<int>(0));
    });
  });
}

Widget _boilerplate(Widget child) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: child,
  );
}
