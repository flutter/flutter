// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:quiver/testing/async.dart';

import 'package:test/test.dart';
import '../services/mocks_for_image_cache.dart';

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
      new SynchronousFuture<ImageInfo>(new TestImageInfo(key))
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

class BackgroundImageProvider extends ImageProvider<BackgroundImageProvider> {
  final Completer<ImageInfo> _completer = new Completer<ImageInfo>();

  @override
  Future<BackgroundImageProvider> obtainKey(ImageConfiguration configuration) {
    return new SynchronousFuture<BackgroundImageProvider>(this);
  }

  @override
  ImageStream resolve(ImageConfiguration configuration) {
    return super.resolve(configuration);
  }

  @override
  ImageStreamCompleter load(BackgroundImageProvider key) {
    return new OneFrameImageStreamCompleter(_completer.future);
  }

  void complete() {
    _completer.complete(new ImageInfo(image: new TestImage()));
  }

  @override
  String toString() => '$runtimeType($hashCode)';
}

class TestImage extends ui.Image {
  @override
  int get width => 100;

  @override
  int get height => 100;

  @override
  void dispose() { }
}

void main() {
  test("Decoration.lerp()", () {
    BoxDecoration a = const BoxDecoration(backgroundColor: const Color(0xFFFFFFFF));
    BoxDecoration b = const BoxDecoration(backgroundColor: const Color(0x00000000));

    BoxDecoration c = Decoration.lerp(a, b, 0.0);
    expect(c.backgroundColor, equals(a.backgroundColor));

    c = Decoration.lerp(a, b, 0.25);
    expect(c.backgroundColor, equals(Color.lerp(const Color(0xFFFFFFFF), const Color(0x00000000), 0.25)));

    c = Decoration.lerp(a, b, 1.0);
    expect(c.backgroundColor, equals(b.backgroundColor));
  });

  test("BoxDecorationImageListenerSync", () {
    ImageProvider imageProvider = new SynchronousTestImageProvider();
    BackgroundImage backgroundImage = new BackgroundImage(image: imageProvider);

    BoxDecoration boxDecoration = new BoxDecoration(backgroundImage: backgroundImage);
    bool onChangedCalled = false;
    BoxPainter boxPainter = boxDecoration.createBoxPainter(() {
      onChangedCalled = true;
    });

    TestCanvas canvas = new TestCanvas();
    ImageConfiguration imageConfiguration = const ImageConfiguration(size: Size.zero);
    boxPainter.paint(canvas, Offset.zero, imageConfiguration);

    // The onChanged callback should not be invoked during the call to boxPainter.paint
    expect(onChangedCalled, equals(false));
  });

  test("BoxDecorationImageListenerAsync", () {
    new FakeAsync().run((FakeAsync async) {
      ImageProvider imageProvider = new AsyncTestImageProvider();
      BackgroundImage backgroundImage = new BackgroundImage(image: imageProvider);

      BoxDecoration boxDecoration = new BoxDecoration(backgroundImage: backgroundImage);
      bool onChangedCalled = false;
      BoxPainter boxPainter = boxDecoration.createBoxPainter(() {
        onChangedCalled = true;
      });

      TestCanvas canvas = new TestCanvas();
      ImageConfiguration imageConfiguration = const ImageConfiguration(size: Size.zero);
      boxPainter.paint(canvas, Offset.zero, imageConfiguration);

      // The onChanged callback should be invoked asynchronously.
      expect(onChangedCalled, equals(false));
      async.flushMicrotasks();
      expect(onChangedCalled, equals(true));
    });
  });

  // Regression test for https://github.com/flutter/flutter/issues/7289.
  // A reference test would be better.
  test("BoxDecoration backgroundImage clip", () {
    void testDecoration({ BoxShape shape, BorderRadius borderRadius, bool expectClip}) {
      new FakeAsync().run((FakeAsync async) {
        BackgroundImageProvider imageProvider = new BackgroundImageProvider();
        BackgroundImage backgroundImage = new BackgroundImage(image: imageProvider);

        BoxDecoration boxDecoration = new BoxDecoration(
          shape: shape,
          borderRadius: borderRadius,
          backgroundImage: backgroundImage,
        );

        List<Invocation> invocations = <Invocation>[];
        TestCanvas canvas = new TestCanvas(invocations);
        ImageConfiguration imageConfiguration = const ImageConfiguration(
            size: const Size(100.0, 100.0)
        );
        bool onChangedCalled = false;
        BoxPainter boxPainter = boxDecoration.createBoxPainter(() {
          onChangedCalled = true;
        });

        // _BoxDecorationPainter._paintBackgroundImage() resolves the background
        // image and adds a listener to the resolved image stream.
        boxPainter.paint(canvas, Offset.zero, imageConfiguration);
        imageProvider.complete();

        // Run the listener which calls onChanged() which saves an internal
        // reference to the TestImage.
        async.flushMicrotasks();
        expect(onChangedCalled, isTrue);
        boxPainter.paint(canvas, Offset.zero, imageConfiguration);

        // We expect a clip to preceed the drawImageRect call.
        List<Invocation> commands = canvas.invocations.where((Invocation invocation) {
          return invocation.memberName == #clipPath || invocation.memberName == #drawImageRect;
        }).toList();
        if (expectClip) { // We expect a clip to preceed the drawImageRect call.
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
    testDecoration(borderRadius: new BorderRadius.all(const Radius.circular(16.0)), expectClip: true);
    testDecoration(expectClip: false);
  });
}
