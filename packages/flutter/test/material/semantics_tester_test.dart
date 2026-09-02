// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
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

  testWidgets('includesNodeWith accepts attributed fields and hint alone', (
    WidgetTester tester,
  ) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Semantics(
        container: true,
        attributedLabel: AttributedString('label'),
        attributedValue: AttributedString('value'),
        attributedHint: AttributedString('hint'),
        textDirection: TextDirection.ltr,
        child: Container(),
      ),
    );

    expect(semantics, includesNodeWith(attributedLabel: AttributedString('label')));
    expect(semantics, includesNodeWith(attributedValue: AttributedString('value')));
    expect(semantics, includesNodeWith(attributedHint: AttributedString('hint')));
    expect(semantics, includesNodeWith(hint: 'hint'));
    semantics.dispose();
  });
}
