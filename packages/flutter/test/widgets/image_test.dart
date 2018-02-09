// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/image_data.dart';

void main() {
  testWidgets('Verify Image resets its RenderImage when changing providers', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();
    final TestImageProvider imageProvider1 = new TestImageProvider();
    await tester.pumpWidget(
      new Container(
        key: key,
        child: new Image(
          image: imageProvider1
        )
      ),
      null,
      EnginePhase.layout,
    );
    RenderImage renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);

    final TestImageProvider imageProvider2 = new TestImageProvider();
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
    final TestImageProvider imageProvider1 = new TestImageProvider();
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

    final TestImageProvider imageProvider2 = new TestImageProvider();
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
    final TestImageProvider imageProvider1 = new TestImageProvider();
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

    final TestImageProvider imageProvider2 = new TestImageProvider();
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
    final TestImageProvider imageProvider1 = new TestImageProvider();
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

    final TestImageProvider imageProvider2 = new TestImageProvider();
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

  testWidgets('Verify ImageProvider configuration inheritance', (WidgetTester tester) async {
    final GlobalKey mediaQueryKey1 = new GlobalKey(debugLabel: 'mediaQueryKey1');
    final GlobalKey mediaQueryKey2 = new GlobalKey(debugLabel: 'mediaQueryKey2');
    final GlobalKey imageKey = new GlobalKey(debugLabel: 'image');
    final TestImageProvider imageProvider = new TestImageProvider();

    // Of the two nested MediaQuery objects, the innermost one,
    // mediaQuery2, should define the configuration of the imageProvider.
    await tester.pumpWidget(
      new MediaQuery(
        key: mediaQueryKey1,
        data: const MediaQueryData(
          devicePixelRatio: 10.0,
          padding: EdgeInsets.zero,
        ),
        child: new MediaQuery(
          key: mediaQueryKey2,
          data: const MediaQueryData(
            devicePixelRatio: 5.0,
            padding: EdgeInsets.zero,
          ),
          child: new Image(
            key: imageKey,
            image: imageProvider
          ),
        )
      )
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 5.0);

    // This is the same widget hierarchy as before except that the
    // two MediaQuery objects have exchanged places. The imageProvider
    // should be resolved again, with the new innermost MediaQuery.
    await tester.pumpWidget(
      new MediaQuery(
        key: mediaQueryKey2,
        data: const MediaQueryData(
          devicePixelRatio: 5.0,
          padding: EdgeInsets.zero,
        ),
        child: new MediaQuery(
          key: mediaQueryKey1,
          data: const MediaQueryData(
            devicePixelRatio: 10.0,
            padding: EdgeInsets.zero,
          ),
          child: new Image(
            key: imageKey,
            image: imageProvider
          ),
        )
      )
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 10.0);
  });

  testWidgets('Verify ImageProvider configuration inheritance again', (WidgetTester tester) async {
    final GlobalKey mediaQueryKey1 = new GlobalKey(debugLabel: 'mediaQueryKey1');
    final GlobalKey mediaQueryKey2 = new GlobalKey(debugLabel: 'mediaQueryKey2');
    final GlobalKey imageKey = new GlobalKey(debugLabel: 'image');
    final TestImageProvider imageProvider = new TestImageProvider();

    // This is just a variation on the previous test. In this version the location
    // of the Image changes and the MediaQuery widgets do not.
    await tester.pumpWidget(
      new Row(
        textDirection: TextDirection.ltr,
        children: <Widget> [
          new MediaQuery(
            key: mediaQueryKey2,
            data: const MediaQueryData(
              devicePixelRatio: 5.0,
              padding: EdgeInsets.zero,
            ),
            child: new Image(
              key: imageKey,
              image: imageProvider
            )
          ),
          new MediaQuery(
            key: mediaQueryKey1,
            data: const MediaQueryData(
              devicePixelRatio: 10.0,
              padding: EdgeInsets.zero,
            ),
            child: new Container(width: 100.0)
          )
        ]
      )
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 5.0);

    await tester.pumpWidget(
      new Row(
        textDirection: TextDirection.ltr,
        children: <Widget> [
          new MediaQuery(
            key: mediaQueryKey2,
            data: const MediaQueryData(
              devicePixelRatio: 5.0,
              padding: EdgeInsets.zero,
            ),
            child: new Container(width: 100.0)
          ),
          new MediaQuery(
            key: mediaQueryKey1,
            data: const MediaQueryData(
              devicePixelRatio: 10.0,
              padding: EdgeInsets.zero,
            ),
            child: new Image(
              key: imageKey,
              image: imageProvider
            )
          )
        ]
      )
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 10.0);
  });

  testWidgets('Verify Image stops listening to ImageStream', (WidgetTester tester) async {
    final TestImageProvider imageProvider = new TestImageProvider();
    await tester.pumpWidget(new Image(image: imageProvider));
    final State<Image> image = tester.state/*State<Image>*/(find.byType(Image));
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, unresolved, 1 listener), pixels: null)'));
    imageProvider.complete();
    await tester.pump();
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, [100×100] @ 1.0x, 1 listener), pixels: [100×100] @ 1.0x)'));
    await tester.pumpWidget(new Container());
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(lifecycle state: defunct, not mounted, stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, [100×100] @ 1.0x, 0 listeners), pixels: [100×100] @ 1.0x)'));
  });

  testWidgets('Image.memory control test', (WidgetTester tester) async {
    await tester.pumpWidget(new Image.memory(new Uint8List.fromList(kTransparentImage)));
  });

  testWidgets('Image color and colorBlend parameters', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Image(
        image: new TestImageProvider(),
        color: const Color(0xFF00FF00),
        colorBlendMode: BlendMode.clear
      )
    );
    final RenderImage renderer = tester.renderObject<RenderImage>(find.byType(Image));
    expect(renderer.color, const Color(0xFF00FF00));
    expect(renderer.colorBlendMode, BlendMode.clear);
  });

  testWidgets('Precache', (WidgetTester tester) async {
    final TestImageProvider provider = new TestImageProvider();
    Future<Null> precache;
    await tester.pumpWidget(
      new Builder(
        builder: (BuildContext context) {
          precache = precacheImage(provider, context);
          return new Container();
        }
      )
    );
    provider.complete();
    await precache;
    expect(provider._lastResolvedConfiguration, isNotNull);

    // Check that a second resolve of the same image is synchronous.
    final ImageStream stream = provider.resolve(provider._lastResolvedConfiguration);
    bool isSync;
    stream.addListener((ImageInfo image, bool sync) { isSync = sync; });
    expect(isSync, isTrue);
  });

  testWidgets('TickerMode controls stream registration', (WidgetTester tester) async {
    final TestImageStreamCompleter imageStreamCompleter = new TestImageStreamCompleter();
    final Image image = new Image(
      image: new TestImageProvider(streamCompleter: imageStreamCompleter),
    );
    await tester.pumpWidget(
      new TickerMode(
        enabled: true,
        child: image,
      ),
    );
    expect(imageStreamCompleter.listeners.length, 1);
    await tester.pumpWidget(
      new TickerMode(
        enabled: false,
        child: image,
      ),
    );
    expect(imageStreamCompleter.listeners.length, 0);
  });

  testWidgets('Verify Image shows correct RenderImage when changing to an already completed provider', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();

    final TestImageProvider imageProvider1 = new TestImageProvider();
    final TestImageProvider imageProvider2 = new TestImageProvider();

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
    imageProvider2.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);

    final ui.Image oldImage = renderImage.image;

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
    expect(renderImage.image, isNotNull);
    expect(renderImage.image, isNot(equals(oldImage)));
  });

  testWidgets('Image State can be reconfigured to use another image', (WidgetTester tester) async {
    final Image image1 = new Image(image: new TestImageProvider()..complete(), width: 10.0);
    final Image image2 = new Image(image: new TestImageProvider()..complete(), width: 20.0);

    final Column column = new Column(children: <Widget>[image1, image2]);
    await tester.pumpWidget(column, null, EnginePhase.layout);

    final Column columnSwapped = new Column(children: <Widget>[image2, image1]);
    await tester.pumpWidget(columnSwapped, null, EnginePhase.layout);

    final List<RenderImage> renderObjects = tester.renderObjectList<RenderImage>(find.byType(Image)).toList();
    expect(renderObjects, hasLength(2));
    expect(renderObjects[0].image, isNotNull);
    expect(renderObjects[0].width, 20.0);
    expect(renderObjects[1].image, isNotNull);
    expect(renderObjects[1].width, 10.0);
  });
}

class TestImageProvider extends ImageProvider<TestImageProvider> {
  final Completer<ImageInfo> _completer = new Completer<ImageInfo>();
  ImageStreamCompleter _streamCompleter;
  ImageConfiguration _lastResolvedConfiguration;

  TestImageProvider({ImageStreamCompleter streamCompleter}) {
    _streamCompleter = streamCompleter
      ?? new OneFrameImageStreamCompleter(_completer.future);
  }

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return new SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStream resolve(ImageConfiguration configuration) {
    _lastResolvedConfiguration = configuration;
    return super.resolve(configuration);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key) => _streamCompleter;

  void complete() {
    _completer.complete(new ImageInfo(image: new TestImage()));
  }

  @override
  String toString() => '${describeIdentity(this)}()';
}

class TestImageStreamCompleter extends ImageStreamCompleter {
  final List<ImageListener> listeners = <ImageListener> [];

  @override
  void addListener(ImageListener listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(ImageListener listener) {
    listeners.remove(listener);
  }
}

class TestImage implements ui.Image {
  @override
  int get width => 100;

  @override
  int get height => 100;

  @override
  void dispose() { }

  @override
  String toString() => '[$width\u00D7$height]';
}
