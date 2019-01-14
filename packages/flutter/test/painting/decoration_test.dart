// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Image, ImageByteFormat, ColorFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:quiver/testing/async.dart';
import '../flutter_test_alternative.dart';

import '../painting/mocks_for_image_cache.dart';
import '../rendering/rendering_tester.dart';

class TestCanvas implements Canvas {
  TestCanvas([this.invocations]);

  final List<Invocation> invocations;

  @override
  void noSuchMethod(Invocation invocation) {
    invocations?.add(invocation);
  }
}

class SynchronousTestImageProvider extends ImageProvider<int> {
  @override
  Future<int> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<int>(1);
  }

  @override
  ImageStreamCompleter load(int key) {
    return OneFrameImageStreamCompleter(
      SynchronousFuture<ImageInfo>(TestImageInfo(key, image: TestImage(), scale: 1.0))
    );
  }
}

class AsyncTestImageProvider extends ImageProvider<int> {
  @override
  Future<int> obtainKey(ImageConfiguration configuration) {
    return Future<int>.value(2);
  }

  @override
  ImageStreamCompleter load(int key) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.value(TestImageInfo(key))
    );
  }
}

class DelayedImageProvider extends ImageProvider<DelayedImageProvider> {
  final Completer<ImageInfo> _completer = Completer<ImageInfo>();

  @override
  Future<DelayedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<DelayedImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(DelayedImageProvider key) {
    return OneFrameImageStreamCompleter(_completer.future);
  }

  void complete() {
    _completer.complete(ImageInfo(image: TestImage()));
  }

  @override
  String toString() => '${describeIdentity(this)}}()';
}

class TestImage implements ui.Image {
  @override
  int get width => 100;

  @override
  int get height => 100;

  @override
  void dispose() { }

  @override
  Future<ByteData> toByteData({ui.ImageByteFormat format}) async {
    throw UnsupportedError('Cannot encode test image');
  }
}

void main() {
  TestRenderingFlutterBinding(); // initializes the imageCache

  test('Decoration.lerp()', () {
    const BoxDecoration a = BoxDecoration(color: Color(0xFFFFFFFF));
    const BoxDecoration b = BoxDecoration(color: Color(0x00000000));

    BoxDecoration c = Decoration.lerp(a, b, 0.0);
    expect(c.color, equals(a.color));

    c = Decoration.lerp(a, b, 0.25);
    expect(c.color, equals(Color.lerp(const Color(0xFFFFFFFF), const Color(0x00000000), 0.25)));

    c = Decoration.lerp(a, b, 1.0);
    expect(c.color, equals(b.color));
  });

  test('BoxDecorationImageListenerSync', () {
    final ImageProvider imageProvider = SynchronousTestImageProvider();
    final DecorationImage backgroundImage = DecorationImage(image: imageProvider);

    final BoxDecoration boxDecoration = BoxDecoration(image: backgroundImage);
    bool onChangedCalled = false;
    final BoxPainter boxPainter = boxDecoration.createBoxPainter(() {
      onChangedCalled = true;
    });

    final TestCanvas canvas = TestCanvas();
    const ImageConfiguration imageConfiguration = ImageConfiguration(size: Size.zero);
    boxPainter.paint(canvas, Offset.zero, imageConfiguration);

    // The onChanged callback should not be invoked during the call to boxPainter.paint
    expect(onChangedCalled, equals(false));
  });

  test('BoxDecorationImageListenerAsync', () {
    FakeAsync().run((FakeAsync async) {
      final ImageProvider imageProvider = AsyncTestImageProvider();
      final DecorationImage backgroundImage = DecorationImage(image: imageProvider);

      final BoxDecoration boxDecoration = BoxDecoration(image: backgroundImage);
      bool onChangedCalled = false;
      final BoxPainter boxPainter = boxDecoration.createBoxPainter(() {
        onChangedCalled = true;
      });

      final TestCanvas canvas = TestCanvas();
      const ImageConfiguration imageConfiguration = ImageConfiguration(size: Size.zero);
      boxPainter.paint(canvas, Offset.zero, imageConfiguration);

      // The onChanged callback should be invoked asynchronously.
      expect(onChangedCalled, equals(false));
      async.flushMicrotasks();
      expect(onChangedCalled, equals(true));
    });
  });

  // Regression test for https://github.com/flutter/flutter/issues/7289.
  // A reference test would be better.
  test('BoxDecoration backgroundImage clip', () {
    void testDecoration({ BoxShape shape = BoxShape.rectangle, BorderRadius borderRadius, bool expectClip}) {
      assert(shape != null);
      FakeAsync().run((FakeAsync async) {
        final DelayedImageProvider imageProvider = DelayedImageProvider();
        final DecorationImage backgroundImage = DecorationImage(image: imageProvider);

        final BoxDecoration boxDecoration = BoxDecoration(
          shape: shape,
          borderRadius: borderRadius,
          image: backgroundImage,
        );

        final List<Invocation> invocations = <Invocation>[];
        final TestCanvas canvas = TestCanvas(invocations);
        const ImageConfiguration imageConfiguration = ImageConfiguration(
            size: Size(100.0, 100.0)
        );
        bool onChangedCalled = false;
        final BoxPainter boxPainter = boxDecoration.createBoxPainter(() {
          onChangedCalled = true;
        });

        // _BoxDecorationPainter._paintDecorationImage() resolves the background
        // image and adds a listener to the resolved image stream.
        boxPainter.paint(canvas, Offset.zero, imageConfiguration);
        imageProvider.complete();

        // Run the listener which calls onChanged() which saves an internal
        // reference to the TestImage.
        async.flushMicrotasks();
        expect(onChangedCalled, isTrue);
        boxPainter.paint(canvas, Offset.zero, imageConfiguration);

        // We expect a clip to precede the drawImageRect call.
        final List<Invocation> commands = canvas.invocations.where((Invocation invocation) {
          return invocation.memberName == #clipPath || invocation.memberName == #drawImageRect;
        }).toList();
        if (expectClip) { // We expect a clip to precede the drawImageRect call.
          expect(commands.length, 2);
          expect(commands[0].memberName, equals(#clipPath));
          expect(commands[1].memberName, equals(#drawImageRect));
        } else {
          expect(commands.length, 1);
          expect(commands[0].memberName, equals(#drawImageRect));
        }
      });
    }

    testDecoration(shape: BoxShape.circle, expectClip: true);
    testDecoration(borderRadius: const BorderRadius.all(Radius.circular(16.0)), expectClip: true);
    testDecoration(expectClip: false);
  });

  test('DecorationImage test', () {
    const ColorFilter colorFilter = ui.ColorFilter.mode(Color(0xFF00FF00), BlendMode.src);
    final DecorationImage backgroundImage = DecorationImage(
      image: SynchronousTestImageProvider(),
      colorFilter: colorFilter,
      fit: BoxFit.contain,
      alignment: Alignment.bottomLeft,
      centerSlice: Rect.fromLTWH(10.0, 20.0, 30.0, 40.0),
      repeat: ImageRepeat.repeatY,
    );

    final BoxDecoration boxDecoration = BoxDecoration(image: backgroundImage);
    final BoxPainter boxPainter = boxDecoration.createBoxPainter(() { assert(false); });
    final TestCanvas canvas = TestCanvas(<Invocation>[]);
    boxPainter.paint(canvas, Offset.zero, const ImageConfiguration(size: Size(100.0, 100.0)));

    final Invocation call = canvas.invocations.singleWhere((Invocation call) => call.memberName == #drawImageNine);
    expect(call.isMethod, isTrue);
    expect(call.positionalArguments, hasLength(4));
    expect(call.positionalArguments[0], isInstanceOf<TestImage>());
    expect(call.positionalArguments[1], Rect.fromLTRB(10.0, 20.0, 40.0, 60.0));
    expect(call.positionalArguments[2], Rect.fromLTRB(0.0, 0.0, 100.0, 100.0));
    expect(call.positionalArguments[3], isInstanceOf<Paint>());
    expect(call.positionalArguments[3].isAntiAlias, false);
    expect(call.positionalArguments[3].colorFilter, colorFilter);
    expect(call.positionalArguments[3].filterQuality, FilterQuality.low);
  });

  test('BoxDecoration.lerp - shapes', () {
    // We don't lerp the shape, we just switch from one to the other at t=0.5.
    // (Use a ShapeDecoration and ShapeBorder if you want to lerp the shapes...)
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(shape: BoxShape.rectangle),
        const BoxDecoration(shape: BoxShape.circle),
        -1.0,
      ),
      const BoxDecoration(shape: BoxShape.rectangle)
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(shape: BoxShape.rectangle),
        const BoxDecoration(shape: BoxShape.circle),
        0.0,
      ),
      const BoxDecoration(shape: BoxShape.rectangle)
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(shape: BoxShape.rectangle),
        const BoxDecoration(shape: BoxShape.circle),
        0.25,
      ),
      const BoxDecoration(shape: BoxShape.rectangle)
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(shape: BoxShape.rectangle),
        const BoxDecoration(shape: BoxShape.circle),
        0.75,
      ),
      const BoxDecoration(shape: BoxShape.circle)
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(shape: BoxShape.rectangle),
        const BoxDecoration(shape: BoxShape.circle),
        1.0,
      ),
      const BoxDecoration(shape: BoxShape.circle)
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(shape: BoxShape.rectangle),
        const BoxDecoration(shape: BoxShape.circle),
        2.0,
      ),
      const BoxDecoration(shape: BoxShape.circle)
    );
  });

  test('BoxDecoration.lerp - gradients', () {
    const Gradient gradient = LinearGradient(colors: <Color>[ Color(0x00000000), Color(0xFFFFFFFF) ]);
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(),
        const BoxDecoration(gradient: gradient),
        -1.0,
      ),
      const BoxDecoration(gradient: LinearGradient(colors: <Color>[ Color(0x00000000), Color(0x00FFFFFF) ]))
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(),
        const BoxDecoration(gradient: gradient),
        0.0,
      ),
      const BoxDecoration()
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(),
        const BoxDecoration(gradient: gradient),
        0.25,
      ),
      const BoxDecoration(gradient: LinearGradient(colors: <Color>[ Color(0x00000000), Color(0x40FFFFFF) ]))
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(),
        const BoxDecoration(gradient: gradient),
        0.75,
      ),
      const BoxDecoration(gradient: LinearGradient(colors: <Color>[ Color(0x00000000), Color(0xBFFFFFFF) ]))
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(),
        const BoxDecoration(gradient: gradient),
        1.0,
      ),
      const BoxDecoration(gradient: gradient)
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(),
        const BoxDecoration(gradient: gradient),
        2.0,
      ),
      const BoxDecoration(gradient: gradient)
    );
  });

  test('Decoration.lerp with unrelated decorations', () {
    expect(Decoration.lerp(const FlutterLogoDecoration(), const BoxDecoration(), 0.0), isInstanceOf<FlutterLogoDecoration>()); // ignore: CONST_EVAL_THROWS_EXCEPTION
    expect(Decoration.lerp(const FlutterLogoDecoration(), const BoxDecoration(), 0.25), isInstanceOf<FlutterLogoDecoration>()); // ignore: CONST_EVAL_THROWS_EXCEPTION
    expect(Decoration.lerp(const FlutterLogoDecoration(), const BoxDecoration(), 0.75), isInstanceOf<BoxDecoration>()); // ignore: CONST_EVAL_THROWS_EXCEPTION
    expect(Decoration.lerp(const FlutterLogoDecoration(), const BoxDecoration(), 1.0), isInstanceOf<BoxDecoration>()); // ignore: CONST_EVAL_THROWS_EXCEPTION
  });

  test('paintImage BoxFit.none scale test', () {
    for (double scale = 1.0; scale <= 4.0; scale += 1.0) {
      final TestCanvas canvas = TestCanvas(<Invocation>[]);

      final Rect outputRect = Rect.fromLTWH(30.0, 30.0, 250.0, 250.0);
      final ui.Image image = TestImage();

      paintImage(
        canvas: canvas,
        rect: outputRect,
        image: image,
        scale: scale,
        alignment: Alignment.bottomRight,
        fit: BoxFit.none,
        repeat: ImageRepeat.noRepeat,
        flipHorizontally: false,
      );

      const Size imageSize = Size(100.0, 100.0);

      final Invocation call = canvas.invocations.firstWhere((Invocation call) => call.memberName == #drawImageRect);

      expect(call.isMethod, isTrue);
      expect(call.positionalArguments, hasLength(4));

      expect(call.positionalArguments[0], isInstanceOf<TestImage>());

      // sourceRect should contain all pixels of the source image
      expect(call.positionalArguments[1], Offset.zero & imageSize);

      // Image should be scaled down (divided by scale)
      // and be positioned in the bottom right of the outputRect
      final Size expectedTileSize = imageSize / scale;
      final Rect expectedTileRect = Rect.fromPoints(
        outputRect.bottomRight.translate(-expectedTileSize.width, -expectedTileSize.height),
        outputRect.bottomRight,
      );
      expect(call.positionalArguments[2], expectedTileRect);

      expect(call.positionalArguments[3], isInstanceOf<Paint>());
    }
  });

  test('paintImage BoxFit.scaleDown scale test', () {
    for (double scale = 1.0; scale <= 4.0; scale += 1.0) {
      final TestCanvas canvas = TestCanvas(<Invocation>[]);

      // container size > scaled image size
      final Rect outputRect = Rect.fromLTWH(30.0, 30.0, 250.0, 250.0);
      final ui.Image image = TestImage();

      paintImage(
        canvas: canvas,
        rect: outputRect,
        image: image,
        scale: scale,
        alignment: Alignment.bottomRight,
        fit: BoxFit.scaleDown,
        repeat: ImageRepeat.noRepeat,
        flipHorizontally: false,
      );

      const Size imageSize = Size(100.0, 100.0);

      final Invocation call = canvas.invocations.firstWhere((Invocation call) => call.memberName == #drawImageRect);

      expect(call.isMethod, isTrue);
      expect(call.positionalArguments, hasLength(4));

      expect(call.positionalArguments[0], isInstanceOf<TestImage>());

      // sourceRect should contain all pixels of the source image
      expect(call.positionalArguments[1], Offset.zero & imageSize);

      // Image should be scaled down (divided by scale)
      // and be positioned in the bottom right of the outputRect
      final Size expectedTileSize = imageSize / scale;
      final Rect expectedTileRect = Rect.fromPoints(
        outputRect.bottomRight.translate(-expectedTileSize.width, -expectedTileSize.height),
        outputRect.bottomRight,
      );
      expect(call.positionalArguments[2], expectedTileRect);

      expect(call.positionalArguments[3], isInstanceOf<Paint>());
    }
  });

  test('paintImage BoxFit.scaleDown test', () {
    final TestCanvas canvas = TestCanvas(<Invocation>[]);

    // container height (20 px) < scaled image height (50 px)
    final Rect outputRect = Rect.fromLTWH(30.0, 30.0, 250.0, 20.0);
    final ui.Image image = TestImage();

    paintImage(
      canvas: canvas,
      rect: outputRect,
      image: image,
      scale: 2.0,
      alignment: Alignment.bottomRight,
      fit: BoxFit.scaleDown,
      repeat: ImageRepeat.noRepeat,
      flipHorizontally: false,
    );

    const Size imageSize = Size(100.0, 100.0);

    final Invocation call = canvas.invocations.firstWhere((Invocation call) => call.memberName == #drawImageRect);

    expect(call.isMethod, isTrue);
    expect(call.positionalArguments, hasLength(4));

    expect(call.positionalArguments[0], isInstanceOf<TestImage>());

    // sourceRect should contain all pixels of the source image
    expect(call.positionalArguments[1], Offset.zero & imageSize);

    // Image should be scaled down to fit in hejght
    // and be positioned in the bottom right of the outputRect
    const Size expectedTileSize = Size(20.0, 20.0);
    final Rect expectedTileRect = Rect.fromPoints(
      outputRect.bottomRight.translate(-expectedTileSize.width, -expectedTileSize.height),
      outputRect.bottomRight,
    );
    expect(call.positionalArguments[2], expectedTileRect);

    expect(call.positionalArguments[3], isInstanceOf<Paint>());
  });

  test('paintImage boxFit, scale and alignment test', () {
    const List<BoxFit> boxFits = <BoxFit>[
      BoxFit.contain,
      BoxFit.cover,
      BoxFit.fitWidth,
      BoxFit.fitWidth,
      BoxFit.fitHeight,
      BoxFit.none,
      BoxFit.scaleDown,
    ];

    for(BoxFit boxFit in boxFits) {
      final TestCanvas canvas = TestCanvas(<Invocation>[]);

      final Rect outputRect = Rect.fromLTWH(30.0, 30.0, 250.0, 250.0);
      final ui.Image image = TestImage();

      paintImage(
        canvas: canvas,
        rect: outputRect,
        image: image,
        scale: 3.0,
        alignment: Alignment.center,
        fit: boxFit,
        repeat: ImageRepeat.noRepeat,
        flipHorizontally: false,
      );

      final Invocation call = canvas.invocations.firstWhere((Invocation call) => call.memberName == #drawImageRect);

      expect(call.isMethod, isTrue);
      expect(call.positionalArguments, hasLength(4));

      // Image should be positioned in the center of the container
      expect(call.positionalArguments[2].center, outputRect.center);
    }
  });
}
