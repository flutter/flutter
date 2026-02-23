// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Linear TextScaler', () {
    test('equality', () {
      const a = TextScaler.linear(3.0);
      final TextScaler b = TextScaler.noScaling.clamp(minScaleFactor: 3.0);
      // Creates a non-const TextScaler instance.
      final c = TextScaler.linear(3.0); // ignore: prefer_const_constructors
      final TextScaler d = TextScaler.noScaling
          .clamp(minScaleFactor: 1, maxScaleFactor: 5)
          .clamp(minScaleFactor: 3, maxScaleFactor: 6);

      final list = <TextScaler>[a, b, c, d];
      for (final lhs in list) {
        expect(list, everyElement(lhs));
      }
    });

    test('clamping', () {
      expect(TextScaler.noScaling.clamp(minScaleFactor: 3.0), const TextScaler.linear(3.0));
      expect(const TextScaler.linear(5.0).clamp(maxScaleFactor: 3.0), const TextScaler.linear(3.0));
      expect(const TextScaler.linear(5.0).clamp(maxScaleFactor: 3.0), const TextScaler.linear(3.0));
      expect(
        const TextScaler.linear(5.0).clamp(minScaleFactor: 3.0, maxScaleFactor: 3.0),
        const TextScaler.linear(3.0),
      );
      // Asserts when min > max.
      expect(
        () => TextScaler.noScaling.clamp(minScaleFactor: 5.0, maxScaleFactor: 4.0),
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'message',
            contains('maxScaleFactor >= minScaleFactor'),
          ),
        ),
      );
    });
  });

  group('SystemTextScaler', () {
    testWidgets('equality', (WidgetTester tester) async {
      addTearDown(() => tester.platformDispatcher.clearAllTestValues());

      tester.platformDispatcher.textScaleFactorTestValue = 123;
      final TextScaler scaler1 = MediaQueryData.fromView(tester.view).textScaler;
      tester.platformDispatcher.textScaleFactorTestValue = 345;
      final TextScaler scaler2 = MediaQueryData.fromView(tester.view).textScaler;
      tester.platformDispatcher.textScaleFactorTestValue = 123;
      final TextScaler scaler3 = MediaQueryData.fromView(tester.view).textScaler;
      expect(scaler1, scaler3);
      expect(scaler1, isNot(scaler2));
    });

    testWidgets('Reclamping', (WidgetTester tester) async {
      final TextScaler defaultScaler = MediaQueryData.fromView(tester.view).textScaler;

      // Does not raise maxScale > minScale
      final TextScaler scaler1 = defaultScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1.5);
      final TextScaler scaler2 = scaler1.clamp(minScaleFactor: 0.5, maxScaleFactor: 1);
      expect(scaler2, TextScaler.noScaling);

      // No overlap, first scaler < second scaler. uses new minScale of last clamp
      final TextScaler scaler3 = defaultScaler.clamp(minScaleFactor: 1, maxScaleFactor: 2);
      final TextScaler scaler4 = scaler3.clamp(minScaleFactor: 3, maxScaleFactor: 4);
      expect(scaler4, const TextScaler.linear(3));

      // No overlap, first scaler > second scaler. uses new maxScale of last clamp
      final TextScaler scaler5 = defaultScaler.clamp(minScaleFactor: 5, maxScaleFactor: 6);
      final TextScaler scaler6 = scaler5.clamp(minScaleFactor: 3, maxScaleFactor: 4);
      expect(scaler6, const TextScaler.linear(4));

      // Overlap, combine clamps
      final TextScaler scaler7 = defaultScaler.clamp(minScaleFactor: 1, maxScaleFactor: 3);
      final TextScaler scaler8 = scaler7.clamp(minScaleFactor: 2, maxScaleFactor: 4);
      expect(scaler8, defaultScaler.clamp(minScaleFactor: 2, maxScaleFactor: 3));
    });
  });

  testWidgets('ClampedScaler asserts', (WidgetTester tester) async {
    final TextScaler defaultScaler = MediaQueryData.fromView(tester.view).textScaler;
    final TextScaler clampedScaler = defaultScaler.clamp(minScaleFactor: 1, maxScaleFactor: 5);
    expect(
      () => clampedScaler.clamp(minScaleFactor: 3, maxScaleFactor: 2),
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'message',
          contains('maxScaleFactor >= minScaleFactor'),
        ),
      ),
    );

    expect(
      () => clampedScaler.clamp(minScaleFactor: 3, maxScaleFactor: double.nan),
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'message',
          contains('maxScaleFactor >= minScaleFactor'),
        ),
      ),
    );

    expect(
      () => clampedScaler.clamp(minScaleFactor: -1, maxScaleFactor: 2),
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'message',
          contains('minScaleFactor >= 0'),
        ),
      ),
    );

    expect(
      () => clampedScaler.clamp(minScaleFactor: double.infinity),
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'message',
          contains('minScaleFactor.isFinite'),
        ),
      ),
    );
  });
}
