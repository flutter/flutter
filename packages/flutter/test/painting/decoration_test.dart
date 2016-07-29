// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:quiver/testing/async.dart';

import 'package:test/test.dart';
import '../services/mocks_for_image_cache.dart';

class TestCanvas implements Canvas {
  @override
  void noSuchMethod(Invocation invocation) {}
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

void main() {
  test("Decoration.lerp()", () {
    BoxDecoration a = new BoxDecoration(backgroundColor: const Color(0xFFFFFFFF));
    BoxDecoration b = new BoxDecoration(backgroundColor: const Color(0x00000000));

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
    ImageConfiguration imageConfiguration = new ImageConfiguration(size: Size.zero);
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
      ImageConfiguration imageConfiguration = new ImageConfiguration(size: Size.zero);
      boxPainter.paint(canvas, Offset.zero, imageConfiguration);

      // The onChanged callback should be invoked asynchronously.
      expect(onChangedCalled, equals(false));
      async.flushMicrotasks();
      expect(onChangedCalled, equals(true));
    });
  });
}
