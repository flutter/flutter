// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/src/widgets/crossfade_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import '../painting/image_data.dart';
import '../painting/image_test_utils.dart';

const Duration animationDuration = Duration(milliseconds: 50);

class CrossfadeImageParts {
  const CrossfadeImageParts(this.crossfadeImageElement, this.animatedCrossFadeElement, this.placeholder, this.target)
      : assert(crossfadeImageElement != null);

  final ComponentElement crossfadeImageElement;
  final AnimatedCrossFade animatedCrossFadeElement;
  final Image placeholder;
  final RawImage target;

  State get state {
    StatefulElement animatedCrossfadeElement;
    crossfadeImageElement.visitChildren((Element child) {
      expect(animatedCrossfadeElement, isNull);
      animatedCrossfadeElement = child as StatefulElement;
    });
    expect(animatedCrossfadeElement, isNotNull);
    return animatedCrossfadeElement.state;
  }
}

class LoadTestImageProvider extends ImageProvider<dynamic> {
  LoadTestImageProvider(this.provider);

  final ImageProvider provider;

  ImageStreamCompleter testLoad(dynamic key, DecoderCallback decode) {
    return provider.load(key, decode);
  }

  @override
  Future<dynamic> obtainKey(ImageConfiguration configuration) {
    return null;
  }

  @override
  ImageStreamCompleter load(dynamic key, DecoderCallback decode) {
    return null;
  }
}

CrossfadeImageParts findCrossfadeImage(WidgetTester tester) {
  final ComponentElement crossfadeImageElement = tester.element(find.byType(CrossfadeImage));

  final AnimatedCrossFade animatedCrossFade = tester.widget(find.byType(AnimatedCrossFade));
  final Image firstChild = animatedCrossFade.firstChild as Image;
  final RawImage secondChild = animatedCrossFade.secondChild as RawImage;

  return CrossfadeImageParts(crossfadeImageElement, animatedCrossFade, firstChild, secondChild);
}

Future<void> main() async {
  // These must run outside test zone to complete
  final ui.Image targetImage = await createTestImage();
  final ui.Image placeholderImage = await createTestImage();
  final ui.Image replacementImage = await createTestImage();

  group('CrossfadeImage', () {
    testWidgets('animates an uncached image', (WidgetTester tester) async {
      final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
      final TestImageProvider imageProvider = TestImageProvider(targetImage);

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: CrossfadeImage(
          placeholder: placeholderProvider,
          image: imageProvider,
          crossfadeDuration: animationDuration,
          crossfadeCurve: Curves.linear,
          excludeFromSemantics: true,
        ),
      ));

      // Verify initial state before any loading.
      expect(findCrossfadeImage(tester).placeholder.image, placeholderProvider);
      expect(findCrossfadeImage(tester).target.image, null);
      expect(findCrossfadeImage(tester).animatedCrossFadeElement.crossFadeState, same(CrossFadeState.showFirst));

      // Verify state after placeholder has loaded.
      placeholderProvider.complete();
      await tester.pump();
      expect(findCrossfadeImage(tester).placeholder.image, placeholderProvider);
      expect(findCrossfadeImage(tester).target.image, null);
      expect(findCrossfadeImage(tester).animatedCrossFadeElement.crossFadeState, same(CrossFadeState.showFirst));

      // Verify state after target has loaded but before animation has completed.
      imageProvider.complete();
      await tester.pump();
      expect(findCrossfadeImage(tester).placeholder.image, placeholderProvider);
      expect(findCrossfadeImage(tester).target.image, same(targetImage));
      expect(findCrossfadeImage(tester).animatedCrossFadeElement.crossFadeState, same(CrossFadeState.showSecond));

      // Verify state after the animation has completed. (Not verifying the details of the animation here.)
      await tester.pump(animationDuration);
      expect(findCrossfadeImage(tester).placeholder.image, placeholderProvider);
      expect(findCrossfadeImage(tester).target.image, same(targetImage));
      expect(findCrossfadeImage(tester).animatedCrossFadeElement.crossFadeState, same(CrossFadeState.showSecond));

      // Verify the state after rebuilding with both placeholder and target fully resolved.
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: CrossfadeImage(
          placeholder: placeholderProvider,
          image: imageProvider,
          crossfadeDuration: animationDuration,
          crossfadeCurve: Curves.linear,
          excludeFromSemantics: true,
        ),
      ));
      expect(findCrossfadeImage(tester).placeholder.image, placeholderProvider);
      expect(findCrossfadeImage(tester).target.image, same(targetImage));
      expect(findCrossfadeImage(tester).animatedCrossFadeElement.crossFadeState, same(CrossFadeState.showSecond));
    });

    testWidgets('shows a cached image immediately when skipFadeOnSynchronousLoad=true', (WidgetTester tester) async {
      final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
      final TestImageProvider imageProvider = TestImageProvider(targetImage);
      imageProvider.resolve(FakeImageConfiguration());
      imageProvider.complete();

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: CrossfadeImage(
          placeholder: placeholderProvider,
          image: imageProvider,
        ),
      ));

      expect(find.byType(RawImage), findsNWidgets(1));

      final RawImage rawImage = tester.widget(find.byType(RawImage));
      expect(rawImage.image, same(targetImage));
    });

    testWidgets('handles updating the placeholder image', (WidgetTester tester) async {
      final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
      final TestImageProvider secondPlaceholderProvider = TestImageProvider(replacementImage);
      final TestImageProvider imageProvider = TestImageProvider(targetImage);

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: CrossfadeImage(
          placeholder: placeholderProvider,
          image: imageProvider,
          crossfadeDuration: animationDuration,
          excludeFromSemantics: true,
        ),
      ));

      final State state = findCrossfadeImage(tester).state;
      placeholderProvider.complete();
      await tester.pump();
      expect(findCrossfadeImage(tester).placeholder.image, placeholderProvider);

      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: CrossfadeImage(
          placeholder: secondPlaceholderProvider,
          image: imageProvider,
          crossfadeDuration: animationDuration,
          excludeFromSemantics: true,
        ),
      ));

      secondPlaceholderProvider.complete();
      await tester.pump();
      expect(findCrossfadeImage(tester).placeholder.image, secondPlaceholderProvider);
      expect(findCrossfadeImage(tester).state, same(state));
    });

    group('ImageProvider', () {

      testWidgets('memory placeholder cacheWidth and cacheHeight is passed through', (WidgetTester tester) async {
        final Uint8List testBytes = Uint8List.fromList(kTransparentImage);
        final CrossfadeImage image = CrossfadeImage.memoryNetwork(
          placeholder: testBytes,
          image: 'test.com',
          placeholderCacheWidth: 20,
          placeholderCacheHeight: 30,
          imageCacheWidth: 40,
          imageCacheHeight: 50,
        );

        bool called = false;
        final DecoderCallback decode = (Uint8List bytes, {int cacheWidth, int cacheHeight}) {
          expect(cacheWidth, 20);
          expect(cacheHeight, 30);
          called = true;
          return PaintingBinding.instance.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
        };
        final ImageProvider resizeImage = image.placeholder;
        expect(image.placeholder, isA<ResizeImage>());
        expect(called, false);
        final LoadTestImageProvider testProvider = LoadTestImageProvider(image.placeholder);
        testProvider.testLoad(await resizeImage.obtainKey(ImageConfiguration.empty), decode);
        expect(called, true);
      });

      testWidgets('do not resize when null cache dimensions', (WidgetTester tester) async {
        final Uint8List testBytes = Uint8List.fromList(kTransparentImage);
        final CrossfadeImage image = CrossfadeImage.memoryNetwork(
          placeholder: testBytes,
          image: 'test.com',
        );

        bool called = false;
        final DecoderCallback decode = (Uint8List bytes, {int cacheWidth, int cacheHeight}) {
          expect(cacheWidth, null);
          expect(cacheHeight, null);
          called = true;
          return PaintingBinding.instance.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
        };
        // image.placeholder should be an instance of MemoryImage instead of ResizeImage
        final ImageProvider memoryImage = image.placeholder;
        expect(image.placeholder, isA<MemoryImage>());
        expect(called, false);
        final LoadTestImageProvider testProvider = LoadTestImageProvider(image.placeholder);
        testProvider.testLoad(await memoryImage.obtainKey(ImageConfiguration.empty), decode);
        expect(called, true);
      });
    });

    group('semantics', () {
      testWidgets('only one Semantics node appears within CrossfadeImage', (WidgetTester tester) async {
        final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
        final TestImageProvider imageProvider = TestImageProvider(targetImage);

        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: CrossfadeImage(
            placeholder: placeholderProvider,
            image: imageProvider,
          ),
        ));

        expect(find.byType(Semantics), findsOneWidget);
      });

      testWidgets('is excluded if excludeFromSemantics is true', (WidgetTester tester) async {
        final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
        final TestImageProvider imageProvider = TestImageProvider(targetImage);

        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: CrossfadeImage(
            placeholder: placeholderProvider,
            image: imageProvider,
            excludeFromSemantics: true,
          ),
        ));

        expect(find.byType(Semantics), findsNothing);
      });

      group('label', () {
        const String imageSemanticText = 'Test image semantic label';

        testWidgets('defaults to image label if placeholder label is unspecified', (WidgetTester tester) async {
          Semantics semanticsWidget() => tester.widget(find.byType(Semantics));

          final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
          final TestImageProvider imageProvider = TestImageProvider(targetImage);

          await tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: CrossfadeImage(
              placeholder: placeholderProvider,
              image: imageProvider,
              crossfadeDuration: animationDuration,
              imageSemanticLabel: imageSemanticText,
            ),
          ));

          placeholderProvider.complete();
          await tester.pump();
          expect(semanticsWidget().properties.label, imageSemanticText);

          imageProvider.complete();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 51));
          expect(semanticsWidget().properties.label, imageSemanticText);
        });

        testWidgets('is empty without any specified semantics labels', (WidgetTester tester) async {
          Semantics semanticsWidget() => tester.widget(find.byType(Semantics));

          final TestImageProvider placeholderProvider = TestImageProvider(placeholderImage);
          final TestImageProvider imageProvider = TestImageProvider(targetImage);

          await tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: CrossfadeImage(
              placeholder: placeholderProvider,
              image: imageProvider,
              crossfadeDuration: animationDuration,
            ),
          ));

          placeholderProvider.complete();
          await tester.pump();
          expect(semanticsWidget().properties.label, isEmpty);

          imageProvider.complete();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 51));
          expect(semanticsWidget().properties.label, isEmpty);
        });
      });
    });
  });
}
