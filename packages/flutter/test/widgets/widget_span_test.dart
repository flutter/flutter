// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WidgetSpan codeUnitAt', () {
    const InlineSpan span = WidgetSpan(child: SizedBox());
    expect(span.codeUnitAt(-1), isNull);
    expect(span.codeUnitAt(0), PlaceholderSpan.placeholderCodeUnit);
    expect(span.codeUnitAt(1), isNull);
    expect(span.codeUnitAt(2), isNull);

    const InlineSpan nestedSpan = TextSpan(text: 'AAA', children: <InlineSpan>[span, span]);
    expect(nestedSpan.codeUnitAt(-1), isNull);
    expect(nestedSpan.codeUnitAt(0), 65);
    expect(nestedSpan.codeUnitAt(1), 65);
    expect(nestedSpan.codeUnitAt(2), 65);
    expect(nestedSpan.codeUnitAt(3), PlaceholderSpan.placeholderCodeUnit);
    expect(nestedSpan.codeUnitAt(4), PlaceholderSpan.placeholderCodeUnit);
    expect(nestedSpan.codeUnitAt(5), isNull);
  });

  test('WidgetSpan.extractFromInlineSpan applies the correct scaling factor', () {
    const a = WidgetSpan(child: SizedBox(), style: TextStyle(fontSize: 0));
    const b = WidgetSpan(child: SizedBox(), style: TextStyle(fontSize: 10));
    const c = WidgetSpan(child: SizedBox());
    const d = WidgetSpan(child: SizedBox(), style: TextStyle(letterSpacing: 999));

    const span = TextSpan(
      children: <InlineSpan>[
        a, // fontSize = 0.
        TextSpan(
          children: <InlineSpan>[
            b, // fontSize = 10.
            c, // fontSize = 20.
          ],
          style: TextStyle(fontSize: 20),
        ),
        d, // fontSize = 14.
      ],
    );

    double effectiveTextScaleFactorFromWidget(Widget widget) {
      final child = (widget as ProxyWidget).child as Semantics;
      final dynamic grandChild = child.child;
      final textScaleFactor = grandChild.textScaleFactor as double; // ignore: avoid_dynamic_calls
      return textScaleFactor;
    }

    final List<double> textScaleFactors = WidgetSpan.extractFromInlineSpan(
      span,
      const _QuadraticScaler(),
    ).map(effectiveTextScaleFactorFromWidget).toList();

    expect(textScaleFactors, <double>[
      0, // a
      10, // b
      20, // c
      14, // d
    ]);
  });

  for (final depth in <int>[1, 2]) {
    testWidgets('WidgetSpan text scales once at depth $depth', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/166050.
      const referenceKey = ValueKey<String>('reference');
      const inlineKey = ValueKey<String>('inline');
      Widget inlineText = const Text('A', key: inlineKey);
      for (var i = 0; i < depth; i += 1) {
        inlineText = Text.rich(WidgetSpan(child: inlineText));
      }
      final child = Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('A', key: referenceKey),
                inlineText,
              ],
            ),
          ),
        ),
      );

      for (final textScaler in <TextScaler>[
        TextScaler.noScaling,
        const TextScaler.linear(2),
        const TextScaler.linear(3),
        const _MediaQueryQuadraticScaler(),
      ]) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: child,
          ),
        );

        // Include the WidgetSpan's paint transform in the measured size.
        final Size referenceSize = tester.getRect(find.byKey(referenceKey)).size;
        expect(referenceSize, Size.square(textScaler.scale(14)));
        expect(tester.getRect(find.byKey(inlineKey)).size, referenceSize);
      }
    });
  }

  testWidgets('WidgetSpan respects explicit paragraph and child text scalers', (
    WidgetTester tester,
  ) async {
    const inlineKey = ValueKey<String>('inline');
    const boxKey = ValueKey<String>('box');
    for (final childTextScaler in <TextScaler?>[null, const TextScaler.linear(1.5)]) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(3)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RichText(
                textScaler: const TextScaler.linear(2),
                text: TextSpan(
                  children: <InlineSpan>[
                    WidgetSpan(
                      child: Text(
                        'A',
                        key: inlineKey,
                        style: const TextStyle(fontSize: 14),
                        textScaler: childTextScaler,
                      ),
                    ),
                    const WidgetSpan(child: SizedBox(key: boxKey, width: 10, height: 12)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final double childFontSize = childTextScaler?.scale(14) ?? 14;
      expect(tester.getRect(find.byKey(inlineKey)).size, Size.square(2 * childFontSize));
      expect(tester.getRect(find.byKey(boxKey)).size, const Size(20, 24));
    }
  });
}

class _QuadraticScaler extends TextScaler {
  const _QuadraticScaler();

  @override
  double scale(double fontSize) => fontSize * fontSize;

  @override
  double get textScaleFactor => throw UnimplementedError();
}

class _MediaQueryQuadraticScaler extends _QuadraticScaler {
  const _MediaQueryQuadraticScaler();

  @override
  double get textScaleFactor => scale(kDefaultFontSize) / kDefaultFontSize;
}
