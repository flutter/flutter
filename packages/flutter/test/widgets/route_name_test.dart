import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';


void main() {
  testWidgets('RouteName creates semantics for a route', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: const RouteName(
          name: 'login',
          child: const Text('foo')
        )
      )
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
          id: 1,
          value: 'login',
          textDirection: TextDirection.ltr,
          flags: <SemanticsFlag>[SemanticsFlag.isRoute],
          children: <TestSemantics>[
            new TestSemantics(
              id: 2,
              label: 'foo',
              textDirection: TextDirection.ltr,
            )
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true, ignoreId: true));

    semantics.dispose();
  });
}