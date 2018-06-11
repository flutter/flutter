import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('outerConstraints expands hit test area', (WidgetTester tester) async {
    int pressed = 0;

    await tester.pumpWidget(new RawMaterialButton(
      onPressed: () {
        pressed++;
      },
      constraints: new BoxConstraints.tight(const Size(10.0, 10.0)),
      outerConstraints: const BoxConstraints(minWidth: 100.0, minHeight: 100.0),
      child: const Text('+', textDirection: TextDirection.ltr),
    ));

    await tester.tapAt(const Offset(100.0, 100.0));

    expect(pressed, 1);
  });

  testWidgets('outerConstraints expands semantics area', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Center(
        child: new RawMaterialButton(
          onPressed: () {},
          constraints: new BoxConstraints.tight(const Size(10.0, 10.0)),
          outerConstraints: const BoxConstraints(minWidth: 100.0, minHeight: 100.0),
          child: const Text('+', textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
        new TestSemantics(
          id: 1,
          flags: <SemanticsFlag>[
            SemanticsFlag.isButton,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
          ],
          actions: <SemanticsAction>[
            SemanticsAction.tap,
          ],
          label: '+',
          textDirection: TextDirection.ltr,
          rect: Rect.fromLTRB(0.0, 0.0, 100.0, 100.0),
          children: <TestSemantics>[],
        ),
      ]
    ), ignoreTransform: true));

    semantics.dispose();
  });
}