// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('Semantics tester visits last child', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    const textStyle = TextStyle();
    final recognizer = TapGestureRecognizer();
    addTearDown(recognizer.dispose);

    await tester.pumpWidget(
      Text.rich(
        TextSpan(
          children: <TextSpan>[
            const TextSpan(text: 'hello'),
            TextSpan(text: 'world', recognizer: recognizer..onTap = () {}),
          ],
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ),
    );
    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(label: 'hello', textDirection: TextDirection.ltr),
            TestSemantics(),
          ],
        ),
      ],
    );
    expect(
      semantics,
      isNot(
        hasSemantics(expectedSemantics, ignoreTransform: true, ignoreId: true, ignoreRect: true),
      ),
    );
    semantics.dispose();
  });

  testWidgets('Semantics tester support flags as an int', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          selected: true,
          child: Container(),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              label: 'test1',
              rect: TestSemantics.fullScreen,
              flags: SemanticsFlag.hasSelectedState.index | SemanticsFlag.isSelected.index,
            ),
          ],
        ),
      ),
    );
    semantics.dispose();
  });

  testWidgets('Semantics tester support flags as a list of SemanticsFlag', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          selected: true,
          child: Container(),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              label: 'test1',
              rect: TestSemantics.fullScreen,
              flags: <SemanticsFlag>[SemanticsFlag.hasSelectedState, SemanticsFlag.isSelected],
            ),
          ],
        ),
      ),
    );
    semantics.dispose();
  });

  testWidgets('Semantics tester support flags as a SemanticsFlags', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        child: Semantics(
          label: 'test1',
          textDirection: TextDirection.ltr,
          selected: true,
          child: Container(),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 1,
              label: 'test1',
              rect: TestSemantics.fullScreen,
              flags: SemanticsFlags(isSelected: Tristate.isTrue),
            ),
          ],
        ),
      ),
    );
    semantics.dispose();
  });

  testWidgets('Semantics tester compares controlsNodes', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(container: true, controlsNodes: const <String>{'actual'}, child: Container()),
    );

    final expectedSemantics = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: TestSemantics.fullScreen,
          controlsNodes: const <String>{'expected'},
        ),
      ],
    );

    expect(semantics, isNot(hasSemantics(expectedSemantics)));
    semantics.dispose();
  });

  testWidgets('Semantics tester compares attributed string locales', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        attributedLabel: AttributedString(
          'label',
          attributes: <StringAttribute>[
            LocaleStringAttribute(
              locale: const Locale('en'),
              range: const TextRange(start: 0, end: 5),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
        child: Container(),
      ),
    );

    expect(
      semantics,
      includesNodeWith(
        label: 'label',
        attributedLabel: AttributedString(
          'label',
          attributes: <StringAttribute>[
            LocaleStringAttribute(
              locale: const Locale('en'),
              range: const TextRange(start: 0, end: 5),
            ),
          ],
        ),
      ),
    );
    expect(
      semantics,
      isNot(
        includesNodeWith(
          label: 'label',
          attributedLabel: AttributedString(
            'label',
            attributes: <StringAttribute>[
              LocaleStringAttribute(
                locale: const Locale('es'),
                range: const TextRange(start: 0, end: 5),
              ),
            ],
          ),
        ),
      ),
    );
    semantics.dispose();
  });

  testWidgets('includesNodeWith accepts minValue and maxValue', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        value: '5',
        minValue: '0',
        maxValue: '10',
        textDirection: TextDirection.ltr,
        child: Container(),
      ),
    );

    expect(semantics, includesNodeWith(minValue: '0'));
    expect(semantics, includesNodeWith(maxValue: '10'));
    semantics.dispose();
  });
}
