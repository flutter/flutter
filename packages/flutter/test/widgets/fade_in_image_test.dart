// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../painting/image_test_utils.dart';

Future<Null> main() async {
  // These must run outside test zone to complete
  final ui.Image targetImage = await createTestImage();
  final ui.Image placeholderImage = await createTestImage();

  group('FadeInImage', () {
    testWidgets('animates uncached image and shows cached image immediately', (WidgetTester tester) async {
      // State type is private, hence using dynamic.
      dynamic state() => tester.state(find.byType(FadeInImage));

      RawImage displayedImage() => tester.widget(find.byType(RawImage));

      // The placeholder is expected to be already loaded
      final TestImageProvider placeholderProvider = new TestImageProvider(placeholderImage);

      // Test case: long loading image
      final TestImageProvider imageProvider = new TestImageProvider(targetImage);

      await tester.pumpWidget(new FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
        fadeOutDuration: const Duration(milliseconds: 50),
        fadeInDuration: const Duration(milliseconds: 50),
      ));

      expect(displayedImage().image, null); // image providers haven't completed yet
      placeholderProvider.complete();
      await tester.pump();

      expect(displayedImage().image, same(placeholderImage)); // placeholder completed
      expect(state().phase, FadeInImagePhase.waiting);

      imageProvider.complete(); // load the image
      expect(state().phase, FadeInImagePhase.fadeOut); // fade out placeholder
      for (int i = 0; i < 7; i += 1) {
        expect(displayedImage().image, same(placeholderImage));
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(displayedImage().image, same(targetImage));
      expect(state().phase, FadeInImagePhase.fadeIn); // fade in image
      for (int i = 0; i < 6; i += 1) {
        expect(displayedImage().image, same(targetImage));
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(state().phase, FadeInImagePhase.completed); // done
      expect(displayedImage().image, same(targetImage));

      // Test case: re-use state object (didUpdateWidget)
      final dynamic stateBeforeDidUpdateWidget = state();
      await tester.pumpWidget(new FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
      ));
      final dynamic stateAfterDidUpdateWidget = state();
      expect(stateAfterDidUpdateWidget, same(stateBeforeDidUpdateWidget));
      expect(stateAfterDidUpdateWidget.phase, FadeInImagePhase.completed); // completes immediately
      expect(displayedImage().image, same(targetImage));

      // Test case: new state object but cached image
      final dynamic stateBeforeRecreate = state();
      await tester.pumpWidget(new Container()); // clear widget tree to prevent state reuse
      await tester.pumpWidget(new FadeInImage(
        placeholder: placeholderProvider,
        image: imageProvider,
      ));
      expect(displayedImage().image, same(targetImage));
      final dynamic stateAfterRecreate = state();
      expect(stateAfterRecreate, isNot(same(stateBeforeRecreate)));
      expect(stateAfterRecreate.phase, FadeInImagePhase.completed); // completes immediately
      expect(displayedImage().image, same(targetImage));
    });
  });
}
