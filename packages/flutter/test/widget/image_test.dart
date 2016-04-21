// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui show Image;

import 'package:mojo/core.dart' as core;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  testWidgets('Verify NetworkImage sets an ObjectKey on its ImageResource if it doesn\'t have a key', (WidgetTester tester) {
      final String testUrl = 'https://foo.bar/baz1.png';
      tester.pumpWidget(
        new NetworkImage(
          scale: 1.0,
          src: testUrl
        )
      );

      ImageResource imageResource = imageCache.load(testUrl, scale: 1.0);
      expect(find.byKey(new ObjectKey(imageResource)), findsOneWidget);
  });

  testWidgets('Verify NetworkImage doesn\'t set an ObjectKey on its ImageResource if it has a key', (WidgetTester tester) {
      final String testUrl = 'https://foo.bar/baz2.png';
      tester.pumpWidget(
        new NetworkImage(
          key: new GlobalKey(),
          scale: 1.0,
          src: testUrl
        )
      );

      ImageResource imageResource = imageCache.load(testUrl, scale: 1.0);
      expect(find.byKey(new ObjectKey(imageResource)), findsNothing);
  });

  testWidgets('Verify AsyncImage sets an ObjectKey on its ImageResource if it doesn\'t have a key', (WidgetTester tester) {
      ImageProvider imageProvider = new TestImageProvider();
      tester.pumpWidget(new AsyncImage(provider: imageProvider));

      ImageResource imageResource = imageCache.loadProvider(imageProvider);
      expect(find.byKey(new ObjectKey(imageResource)), findsOneWidget);
  });

  testWidgets('Verify AsyncImage doesn\'t set an ObjectKey on its ImageResource if it has a key', (WidgetTester tester) {
      ImageProvider imageProvider = new TestImageProvider();
      tester.pumpWidget(
        new AsyncImage(
          key: new GlobalKey(),
          provider: imageProvider
        )
      );

      ImageResource imageResource = imageCache.loadProvider(imageProvider);
      expect(find.byKey(new ObjectKey(imageResource)), findsNothing);
  });

  testWidgets('Verify AssetImage sets an ObjectKey on its ImageResource if it doesn\'t have a key', (WidgetTester tester) {
      final String name = 'foo';
      final AssetBundle assetBundle = new TestAssetBundle();
      tester.pumpWidget(
        new AssetImage(
          name: name,
          bundle: assetBundle
        )
      );

      ImageResource imageResource = assetBundle.loadImage(name);
      expect(find.byKey(new ObjectKey(imageResource)), findsOneWidget);
  });

  testWidgets('Verify AssetImage doesn\'t set an ObjectKey on its ImageResource if it has a key', (WidgetTester tester) {
      final String name = 'foo';
      final AssetBundle assetBundle = new TestAssetBundle();
      tester.pumpWidget(
        new AssetImage(
          key: new GlobalKey(),
          name: name,
          bundle: assetBundle
        )
      );

      ImageResource imageResource = assetBundle.loadImage(name);
      expect(find.byKey(new ObjectKey(imageResource)), findsNothing);
  });

  testWidgets('Verify AsyncImage resets its RenderImage when changing providers if it doesn\'t have a key', (WidgetTester tester) {
      final GlobalKey key = new GlobalKey();
      TestImageProvider imageProvider1 = new TestImageProvider();
      tester.pumpWidget(
        new Container(
          key: key,
          child: new AsyncImage(
            provider: imageProvider1
          )
        ),
        null,
        EnginePhase.layout
      );
      RenderImage renderImage = key.currentContext.findRenderObject();
      expect(renderImage.image, isNull);

      imageProvider1.complete();
      tester.flushMicrotasks(); // resolve the future from the image provider
      tester.pump(null, EnginePhase.layout);

      renderImage = key.currentContext.findRenderObject();
      expect(renderImage.image, isNotNull);

      TestImageProvider imageProvider2 = new TestImageProvider();
      tester.pumpWidget(
        new Container(
          key: key,
          child: new AsyncImage(
            provider: imageProvider2
          )
        ),
        null,
        EnginePhase.layout
      );

      renderImage = key.currentContext.findRenderObject();
      expect(renderImage.image, isNull);

  });

  testWidgets('Verify AsyncImage doesn\'t reset its RenderImage when changing providers if it has a key', (WidgetTester tester) {
      final GlobalKey key = new GlobalKey();
      TestImageProvider imageProvider1 = new TestImageProvider();
      tester.pumpWidget(
        new AsyncImage(
            key: key,
            provider: imageProvider1
        ),
        null,
        EnginePhase.layout
      );
      RenderImage renderImage = key.currentContext.findRenderObject();
      expect(renderImage.image, isNull);

      imageProvider1.complete();
      tester.flushMicrotasks(); // resolve the future from the image provider
      tester.pump(null, EnginePhase.layout);

      renderImage = key.currentContext.findRenderObject();
      expect(renderImage.image, isNotNull);

      TestImageProvider imageProvider2 = new TestImageProvider();
      tester.pumpWidget(
        new AsyncImage(
          key: key,
          provider: imageProvider2
        ),
        null,
        EnginePhase.layout
      );

      renderImage = key.currentContext.findRenderObject();
      expect(renderImage.image, isNotNull);
  });

}

class TestImageProvider extends ImageProvider {
  final Completer<ImageInfo> _completer = new Completer<ImageInfo>();

  @override
  Future<ImageInfo> loadImage() => _completer.future;

  void complete() {
    _completer.complete(new ImageInfo(image:new TestImage()));
  }
}

class TestAssetBundle extends AssetBundle {
  final ImageResource _imageResource = new ImageResource(new Completer<ImageInfo>().future);

  @override
  ImageResource loadImage(String key) => _imageResource;

  @override
  Future<String> loadString(String key) => new Completer<String>().future;

  @override
  Future<core.MojoDataPipeConsumer> load(String key) => new Completer<core.MojoDataPipeConsumer>().future;
}

class TestImage extends ui.Image {
  @override
  int get width => 100;

  @override
  int get height => 100;

  @override
  void dispose() {
  }
}
