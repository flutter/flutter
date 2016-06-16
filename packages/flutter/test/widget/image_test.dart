// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Verify Image resets its RenderImage when changing providers', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();
    TestImageProvider imageProvider1 = new TestImageProvider();
    await tester.pumpWidget(
      new Container(
        key: key,
        child: new Image(
          image: imageProvider1
        )
      ),
      null,
      EnginePhase.layout
    );
    RenderImage renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);

    TestImageProvider imageProvider2 = new TestImageProvider();
    await tester.pumpWidget(
      new Container(
        key: key,
        child: new Image(
          image: imageProvider2
        )
      ),
      null,
      EnginePhase.layout
    );

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);
  });

  testWidgets('Verify Image doesn\'t reset its RenderImage when changing providers if it has gaplessPlayback set', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();
    TestImageProvider imageProvider1 = new TestImageProvider();
    await tester.pumpWidget(
      new Container(
        key: key,
        child: new Image(
          gaplessPlayback: true,
          image: imageProvider1
        )
      ),
      null,
      EnginePhase.layout
    );
    RenderImage renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);

    TestImageProvider imageProvider2 = new TestImageProvider();
    await tester.pumpWidget(
      new Container(
        key: key,
        child: new Image(
          gaplessPlayback: true,
          image: imageProvider2
        )
      ),
      null,
      EnginePhase.layout
    );

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);
  });

  testWidgets('Verify Image resets its RenderImage when changing providers if it has a key', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();
    TestImageProvider imageProvider1 = new TestImageProvider();
    await tester.pumpWidget(
      new Image(
        key: key,
        image: imageProvider1
      ),
      null,
      EnginePhase.layout
    );
    RenderImage renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);

    TestImageProvider imageProvider2 = new TestImageProvider();
    await tester.pumpWidget(
      new Image(
        key: key,
        image: imageProvider2
      ),
      null,
      EnginePhase.layout
    );

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);
  });

  testWidgets('Verify Image doesn\'t reset its RenderImage when changing providers if it has gaplessPlayback set', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();
    TestImageProvider imageProvider1 = new TestImageProvider();
    await tester.pumpWidget(
      new Image(
        key: key,
        gaplessPlayback: true,
        image: imageProvider1
      ),
      null,
      EnginePhase.layout
    );
    RenderImage renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);

    TestImageProvider imageProvider2 = new TestImageProvider();
    await tester.pumpWidget(
      new Image(
        key: key,
        gaplessPlayback: true,
        image: imageProvider2
      ),
      null,
      EnginePhase.layout
    );

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);
  });

}

class TestImageProvider extends ImageProvider<TestImageProvider> {
  final Completer<ImageInfo> _completer = new Completer<ImageInfo>();

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return new SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key) => new OneFrameImageStreamCompleter(_completer.future);

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
