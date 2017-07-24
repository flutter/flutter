// Copyright (c) 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'image_test_utils.dart';

Future<Null> main() async {
  final ui.Image testImage = await createTestImage();  // must run outside test zone to complete

  group('FadeInImage', () {
    testWidgets('animates uncached image and shows cached image immediately', (WidgetTester tester) async {
      // State type is private, hence using dynamic.
      dynamic state() => tester.state(find.byType(FadeInImage));

      // The placeholder is expected to be already loaded
      final TestImageProvider placeholderProvider = new TestImageProvider(testImage);
      placeholderProvider.complete();

      // Test case: long loading image
      final TestImageProvider syncImageProvider = new TestImageProvider(testImage);

      await tester.pumpWidget(new FadeInImage(
        placeholder: new Image(image: placeholderProvider),
        image: new Image(image: syncImageProvider),
        fadeOutDuration: const Duration(milliseconds: 50),
        fadeInDuration: const Duration(milliseconds: 50),
      ));

      expect(state().phase, FadeInImagePhase.waiting);
      syncImageProvider.complete();  // load the image
      expect(state().phase, FadeInImagePhase.fadeOut);  // fade out placeholder
      for (int i = 0; i < 7; i += 1) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(state().phase, FadeInImagePhase.fadeIn);  // fade in image
      for (int i = 0; i < 6; i += 1) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(state().phase, FadeInImagePhase.completed);  // done

      // Test case: re-use state object (didUpdateWidget)
      final dynamic stateBeforeDidUpdateWidget = state();
      await tester.pumpWidget(new FadeInImage(
        placeholder: new Image(image: placeholderProvider),
        image: new Image(image: syncImageProvider),
      ));
      final dynamic stateAfterDidUpdateWidget = state();
      expect(stateAfterDidUpdateWidget, same(stateBeforeDidUpdateWidget));
      expect(stateAfterDidUpdateWidget.phase, FadeInImagePhase.completed);  // completes immediately

      // Test case: new state object but cached image
      final dynamic stateBeforeRecreate = state();
      await tester.pumpWidget(new Container());  // clear widget tree to prevent state reuse
      await tester.pumpWidget(new FadeInImage(
        placeholder: new Image(image: placeholderProvider),
        image: new Image(image: syncImageProvider),
      ));
      final dynamic stateAfterRecreate = state();
      expect(stateAfterRecreate, isNot(same(stateBeforeRecreate)));
      expect(stateAfterRecreate.phase, FadeInImagePhase.completed);  // completes immediately
    });
  });
}
