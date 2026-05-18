// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('TestSemantics compares controlsNodes', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    try {
      await tester.pumpWidget(
        Semantics(
          controlsNodes: const <String>{'actual'},
          child: const SizedBox.square(dimension: 10),
        ),
      );

      expect(
        semantics,
        isNot(
          hasSemantics(
            TestSemantics.root(
              children: <TestSemantics>[
                TestSemantics.rootChild(controlsNodes: const <String>{'expected'}),
              ],
            ),
            ignoreId: true,
            ignoreRect: true,
            ignoreTransform: true,
          ),
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('includesNodeWith compares attributed label locales', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    try {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            attributedLabel: AttributedString(
              'label',
              attributes: <StringAttribute>[
                LocaleStringAttribute(
                  range: const TextRange(start: 0, end: 5),
                  locale: const Locale('en', 'US'),
                ),
              ],
            ),
            child: const SizedBox.square(dimension: 10),
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
                  range: const TextRange(start: 0, end: 5),
                  locale: const Locale('de', 'DE'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      semantics.dispose();
    }
  });

  test('includesNodeWith accepts minValue and maxValue as matcher criteria', () {
    expect(() => includesNodeWith(minValue: '0'), returnsNormally);
    expect(() => includesNodeWith(maxValue: '10'), returnsNormally);
  });
}
