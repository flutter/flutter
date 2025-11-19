// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$TextScaleFactorProvider', () {
    late TextScaleFactorProvider provider;

    setUp(() {
      provider = TextScaleFactorProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('appends probe element', () async {
      expect(domDocument.getElementsByTagName('flt-font-size-probe'), hasLength(1));
    });

    group('textScaleFactor', () {
      test('initial value is correct', () {
        expect(provider.textScaleFactor, 1.0);
      });

      test('reflects changes in the root font size', () async {
        const double deltaTolerance = 1e-5;

        final DomElement root = domDocument.documentElement!;
        final String oldFontSize = root.style.fontSize;
        addTearDown(() => root.style.fontSize = oldFontSize);

        root.style.fontSize = '16px';
        await Future<void>.delayed(Duration.zero);
        expect(provider.textScaleFactor, 1.0);

        root.style.fontSize = '20px';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(provider.textScaleFactor, 1.25);

        root.style.fontSize = '24px';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(provider.textScaleFactor, 1.5);

        root.style.fontSize = '14.4px';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(provider.textScaleFactor, closeTo(0.9, deltaTolerance));

        root.style.fontSize = '12.8px';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(provider.textScaleFactor, closeTo(0.8, deltaTolerance));

        root.style.fontSize = '';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(provider.textScaleFactor, 1.0);
      });
    });

    group('onTextScaleFactorChanged', () {
      test('reflects changes in the root font size', () async {
        const double deltaTolerance = 1e-5;

        double? lastEmittedTextScaleFactor;
        final StreamSubscription<double> subscription = provider.onTextScaleFactorChanged.listen(
          (double value) => lastEmittedTextScaleFactor = value,
        );
        addTearDown(subscription.cancel);

        final DomElement root = domDocument.documentElement!;
        final String oldFontSize = root.style.fontSize;
        addTearDown(() => root.style.fontSize = oldFontSize);

        root.style.fontSize = '20px';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(lastEmittedTextScaleFactor, 1.25);

        root.style.fontSize = '24px';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(lastEmittedTextScaleFactor, 1.5);

        root.style.fontSize = '14.4px';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(lastEmittedTextScaleFactor, closeTo(0.9, deltaTolerance));

        root.style.fontSize = '12.8px';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(lastEmittedTextScaleFactor, closeTo(0.8, deltaTolerance));

        root.style.fontSize = '';
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(lastEmittedTextScaleFactor, 1.0);
      });
    });

    group('dispose', () {
      test('removes probe element', () {
        provider.dispose();
        expect(domDocument.getElementsByTagName('flt-font-size-probe'), isEmpty);
      });

      test('stops listening to the changes in the root font size', () async {
        double? lastEmittedTextScaleFactor;
        final StreamSubscription<double> subscription = provider.onTextScaleFactorChanged.listen(
          (double value) => lastEmittedTextScaleFactor = value,
        );
        addTearDown(subscription.cancel);

        final DomElement root = domDocument.documentElement!;
        final String oldFontSize = root.style.fontSize;
        addTearDown(() => root.style.fontSize = oldFontSize);

        provider.dispose();

        for (final String fontSize in ['16px', '20px', '24px', '14.4px', '12.8px', '']) {
          root.style.fontSize = fontSize;
          await Future<void>.delayed(Duration.zero);
          expect(provider.textScaleFactor, 1.0);
          expect(lastEmittedTextScaleFactor, isNull);
        }
      });

      test('closes onTextScaleFactorChanged stream', () async {
        final Completer<bool> completer = Completer<bool>();
        provider.onTextScaleFactorChanged.listen(
          null,
          onDone: () {
            completer.complete(true);
          },
        );

        provider.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(completer.future, completion(isTrue));
      });
    });
  });
}
