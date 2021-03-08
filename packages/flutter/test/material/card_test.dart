// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Card can take semantic text from multiple children', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: Card(
              semanticContainer: false,
              child: Column(
                children: <Widget>[
                  const Text('I am text!'),
                  const Text('Moar text!!1'),
                  MaterialButton(
                    child: const Text('Button'),
                    onPressed: () { },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            id: 1,
            elevation: 1.0,
            thickness: 0.0,
            children: <TestSemantics>[
              TestSemantics(
                id: 2,
                label: 'I am text!',
                textDirection: TextDirection.ltr,
              ),
              TestSemantics(
                id: 3,
                label: 'Moar text!!1',
                textDirection: TextDirection.ltr,
              ),
              TestSemantics(
                id: 4,
                label: 'Button',
                textDirection: TextDirection.ltr,
                actions: <SemanticsAction>[
                  SemanticsAction.tap,
                ],
                flags: <SemanticsFlag>[
                  SemanticsFlag.hasEnabledState,
                  SemanticsFlag.isButton,
                  SemanticsFlag.isEnabled,
                  SemanticsFlag.isFocusable,
                ],
              ),
            ],
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Card merges children when it is a semanticContainer', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    debugResetSemanticsIdCounter();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: Card(
              semanticContainer: true,
              child: Column(
                children: const <Widget>[
                  Text('First child'),
                  Text('Second child'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics(
            id: 1,
            label: 'First child\nSecond child',
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
      ignoreTransform: true,
      ignoreRect: true,
    ));

    semantics.dispose();
  });

  testWidgets('Card margin', (WidgetTester tester) async {
    const Key contentsKey = ValueKey<String>('contents');

    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Card(
          child: Container(
            key: contentsKey,
            color: const Color(0xFF00FF00),
            width: 100.0,
            height: 100.0,
          ),
        ),
      ),
    );

    // Default margin is 4
    expect(tester.getTopLeft(find.byType(Card)), Offset.zero);
    expect(tester.getSize(find.byType(Card)), const Size(108.0, 108.0));

    expect(tester.getTopLeft(find.byKey(contentsKey)), const Offset(4.0, 4.0));
    expect(tester.getSize(find.byKey(contentsKey)), const Size(100.0, 100.0));

    await tester.pumpWidget(
      Container(
        alignment: Alignment.topLeft,
        child: Card(
          margin: EdgeInsets.zero,
          child: Container(
            key: contentsKey,
            color: const Color(0xFF00FF00),
            width: 100.0,
            height: 100.0,
          ),
        ),
      ),
    );

    // Specified margin is zero
    expect(tester.getTopLeft(find.byType(Card)), Offset.zero);
    expect(tester.getSize(find.byType(Card)), const Size(100.0, 100.0));

    expect(tester.getTopLeft(find.byKey(contentsKey)), Offset.zero);
    expect(tester.getSize(find.byKey(contentsKey)), const Size(100.0, 100.0));
  });

  testWidgets('Card clipBehavior property passes through to the Material', (WidgetTester tester) async {
    await tester.pumpWidget(const Card());
    expect(tester.widget<Material>(find.byType(Material)).clipBehavior, Clip.none);

    await tester.pumpWidget(const Card(clipBehavior: Clip.antiAlias));
    expect(tester.widget<Material>(find.byType(Material)).clipBehavior, Clip.antiAlias);
  });

  testWidgets('Card clipBehavior property defers to theme when null', (WidgetTester tester) async {
    await tester.pumpWidget(Builder(builder: (BuildContext context) {
      final ThemeData themeData = Theme.of(context);
      return Theme(
        data: themeData.copyWith(
          cardTheme: themeData.cardTheme.copyWith(
            clipBehavior: Clip.antiAliasWithSaveLayer,
          ),
        ),
        child: const Card(clipBehavior: null),
      );
    }));
    expect(tester.widget<Material>(find.byType(Material)).clipBehavior, Clip.antiAliasWithSaveLayer);
  });

  testWidgets('Card shadowColor', (WidgetTester tester) async {
    Material _getCardMaterial(WidgetTester tester) {
      return tester.widget<Material>(
        find.descendant(
          of: find.byType(Card),
          matching: find.byType(Material),
        ),
      );
    }

    Card _getCard(WidgetTester tester) {
      return tester.widget<Card>(
          find.byType(Card)
      );
    }

    await tester.pumpWidget(
      const Card(),
    );

    expect(_getCard(tester).shadowColor, null);
    expect(_getCardMaterial(tester).shadowColor, const Color(0xFF000000));

    await tester.pumpWidget(
      const Card(
        shadowColor: Colors.red,
      ),
    );

    expect(_getCardMaterial(tester).shadowColor, _getCard(tester).shadowColor);
    expect(_getCardMaterial(tester).shadowColor, Colors.red);
  });
}
