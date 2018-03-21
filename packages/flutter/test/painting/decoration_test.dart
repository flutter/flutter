// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image, ColorFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:quiver/testing/async.dart';
import 'package:test/test.dart';

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
    return new SynchronousFuture<int>(1);
  }

  @override
  ImageStreamCompleter load(int key) {
    return new OneFrameImageStreamCompleter(
      new SynchronousFuture<ImageInfo>(new TestImageInfo(key, image: new TestImage(), scale: 1.0))
    );
  }
}

class AsyncTestImageProvider extends ImageProvider<int> {
  @override
  Future<int> obtainKey(ImageConfiguration configuration) {
    return new Future<int>.value(2);
  }

  @override
  ImageStreamCompleter load(int key) {
    return new OneFrameImageStreamCompleter(
      new Future<ImageInfo>.value(new TestImageInfo(key))
    );
  }
}

class DelayedImageProvider extends ImageProvider<DelayedImageProvider> {
  final Completer<ImageInfo> _completer = new Completer<ImageInfo>();

  @override
  Future<DelayedImageProvider> obtainKey(ImageConfiguration configuration) {
    return new SynchronousFuture<DelayedImageProvider>(this);
  }

  @override
  ImageStream resolve(ImageConfiguration configuration) {
    return super.resolve(configuration);
  }

  @override
  ImageStreamCompleter load(DelayedImageProvider key) {
    return new OneFrameImageStreamCompleter(_completer.future);
  }

  void complete() {
    _completer.complete(new ImageInfo(image: new TestImage()));
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
}

void main() {
  new TestRenderingFlutterBinding(); // initializes the imageCache

  test('Decoration.lerp()', () {
    const BoxDecoration a = const BoxDecoration(color: const Color(0xFFFFFFFF));
    const BoxDecoration b = const BoxDecoration(color: const Color(0x00000000));

    BoxDecoration c = Decoration.lerp(a, b, 0.0);
    expect(c.color, equals(a.color));

    c = Decoration.lerp(a, b, 0.25);
    expect(c.color, equals(Color.lerp(const Color(0xFFFFFFFF), const Color(0x00000000), 0.25)));

    c = Decoration.lerp(a, b, 1.0);
    expect(c.color, equals(b.color));
  });

  test('BoxDecorationImageListenerSync', () {
    final ImageProvider imageProvider = new SynchronousTestImageProvider();
    final DecorationImage backgroundImage = new DecorationImage(image: imageProvider);

    final BoxDecoration boxDecoration = new BoxDecoration(image: backgroundImage);
    bool onChangedCalled = false;
    final BoxPainter boxPainter = boxDecoration.createBoxPainter(() {
      onChangedCalled = true;
    });

    final TestCanvas canvas = new TestCanvas();
    const ImageConfiguration imageConfiguration = const ImageConfiguration(size: Size.zero);
    boxPainter.paint(canvas, Offset.zero, imageConfiguration);

    // The onChanged callback should not be invoked during the call to boxPainter.paint
    expect(onChangedCalled, equals(false));
  });

  test('BoxDecorationImageListenerAsync', () {
    new FakeAsync().run((FakeAsync async) {
      final ImageProvider imageProvider = new AsyncTestImageProvider();
      final DecorationImage backgroundImage = new DecorationImage(image: imageProvider);

      final BoxDecoration boxDecoration = new BoxDecoration(image: backgroundImage);
      bool onChangedCalled = false;
      final BoxPainter boxPainter = boxDecoration.createBoxPainter(() {
        onChangedCalled = true;
      });

      final TestCanvas canvas = new TestCanvas();
      const ImageConfiguration imageConfiguration = const ImageConfiguration(size: Size.zero);
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
    void testDecoration({ BoxShape shape: BoxShape.rectangle, BorderRadius borderRadius, bool expectClip}) {
      assert(shape != null);
      new FakeAsync().run((FakeAsync async) {
        final DelayedImageProvider imageProvider = new DelayedImageProvider();
        final DecorationImage backgroundImage = new DecorationImage(image: imageProvider);

        final BoxDecoration boxDecoration = new BoxDecoration(
          shape: shape,
          borderRadius: borderRadius,
          image: backgroundImage,
        );

        final List<Invocation> invocations = <Invocation>[];
        final TestCanvas canvas = new TestCanvas(invocations);
        const ImageConfiguration imageConfiguration = const ImageConfiguration(
            size: const Size(100.0, 100.0)
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
    testDecoration(borderRadius: const BorderRadius.all(const Radius.circular(16.0)), expectClip: true);
    testDecoration(expectClip: false);
  });

  test('DecorationImage test', () {
    const ColorFilter colorFilter = const ui.ColorFilter.mode(const Color(0xFF00FF00), BlendMode.src);
    final DecorationImage backgroundImage = new DecorationImage(
      image: new SynchronousTestImageProvider(),
      colorFilter: colorFilter,
      fit: BoxFit.contain,
      alignment: Alignment.bottomLeft,
      centerSlice: new Rect.fromLTWH(10.0, 20.0, 30.0, 40.0),
      repeat: ImageRepeat.repeatY,
    );

    final BoxDecoration boxDecoration = new BoxDecoration(image: backgroundImage);
    final BoxPainter boxPainter = boxDecoration.createBoxPainter(() { assert(false); });
    final TestCanvas canvas = new TestCanvas(<Invocation>[]);
    boxPainter.paint(canvas, Offset.zero, const ImageConfiguration(size: const Size(100.0, 100.0)));

    final Invocation call = canvas.invocations.singleWhere((Invocation call) => call.memberName == #drawImageNine);
    expect(call.isMethod, isTrue);
    expect(call.positionalArguments, hasLength(4));
    expect(call.positionalArguments[0], const isInstanceOf<TestImage>());
    expect(call.positionalArguments[1], new Rect.fromLTRB(10.0, 20.0, 40.0, 60.0));
    expect(call.positionalArguments[2], new Rect.fromLTRB(0.0, 0.0, 100.0, 100.0));
    expect(call.positionalArguments[3], const isInstanceOf<Paint>());
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
    const Gradient gradient = const LinearGradient(colors: const <Color>[ const Color(0x00000000), const Color(0xFFFFFFFF) ]);
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(),
        const BoxDecoration(gradient: gradient),
        -1.0,
      ),
      const BoxDecoration(gradient: const LinearGradient(colors: const <Color>[ const Color(0x00000000), const Color(0x00FFFFFF) ]))
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
      const BoxDecoration(gradient: const LinearGradient(colors: const <Color>[ const Color(0x00000000), const Color(0x40FFFFFF) ]))
    );
    expect(
      BoxDecoration.lerp(
        const BoxDecoration(),
        const BoxDecoration(gradient: gradient),
        0.75,
      ),
      const BoxDecoration(gradient: const LinearGradient(colors: const <Color>[ const Color(0x00000000), const Color(0xBFFFFFFF) ]))
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
    expect(Decoration.lerp(const FlutterLogoDecoration(), const BoxDecoration(), 0.0), const isInstanceOf<FlutterLogoDecoration>()); // ignore: CONST_EVAL_THROWS_EXCEPTION
    expect(Decoration.lerp(const FlutterLogoDecoration(), const BoxDecoration(), 0.25), const isInstanceOf<FlutterLogoDecoration>()); // ignore: CONST_EVAL_THROWS_EXCEPTION
    expect(Decoration.lerp(const FlutterLogoDecoration(), const BoxDecoration(), 0.75), const isInstanceOf<BoxDecoration>()); // ignore: CONST_EVAL_THROWS_EXCEPTION
    expect(Decoration.lerp(const FlutterLogoDecoration(), const BoxDecoration(), 1.0), const isInstanceOf<BoxDecoration>()); // ignore: CONST_EVAL_THROWS_EXCEPTION
  });
}
