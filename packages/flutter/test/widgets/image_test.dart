// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/image_data.dart';
import 'semantics_tester.dart';

// This must be run with [WidgetTester.runAsync] since it performs real async
// work.
Future<ui.Image> createTestImage([List<int> bytes = kTransparentImage]) async {
  final ui.Codec codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  final ui.FrameInfo frameInfo = await codec.getNextFrame();
  return frameInfo.image;
}

void main() {
  testWidgets('Verify Image resets its RenderImage when changing providers', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final TestImageProvider imageProvider1 = TestImageProvider();
    await tester.pumpWidget(
      Container(
        key: key,
        child: Image(
          image: imageProvider1,
          excludeFromSemantics: true,
        ),
      ),
      null,
      EnginePhase.layout,
    );
    RenderImage renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNotNull);

    final TestImageProvider imageProvider2 = TestImageProvider();
    await tester.pumpWidget(
      Container(
        key: key,
        child: Image(
          image: imageProvider2,
          excludeFromSemantics: true,
        ),
      ),
      null,
      EnginePhase.layout,
    );

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNull);
  });

  testWidgets('Verify Image doesn\'t reset its RenderImage when changing providers if it has gaplessPlayback set', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final TestImageProvider imageProvider1 = TestImageProvider();
    await tester.pumpWidget(
      Container(
        key: key,
        child: Image(
          gaplessPlayback: true,
          image: imageProvider1,
          excludeFromSemantics: true,
        ),
      ),
      null,
      EnginePhase.layout,
    );
    RenderImage renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNotNull);

    final TestImageProvider imageProvider2 = TestImageProvider();
    await tester.pumpWidget(
      Container(
        key: key,
        child: Image(
          gaplessPlayback: true,
          image: imageProvider2,
          excludeFromSemantics: true,
        ),
      ),
      null,
      EnginePhase.layout,
    );

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNotNull);
  });

  testWidgets('Verify Image resets its RenderImage when changing providers if it has a key', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final TestImageProvider imageProvider1 = TestImageProvider();
    await tester.pumpWidget(
      Image(
        key: key,
        image: imageProvider1,
        excludeFromSemantics: true,
      ),
      null,
      EnginePhase.layout,
    );
    RenderImage renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNotNull);

    final TestImageProvider imageProvider2 = TestImageProvider();
    await tester.pumpWidget(
      Image(
        key: key,
        image: imageProvider2,
        excludeFromSemantics: true,
      ),
      null,
      EnginePhase.layout,
    );

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNull);
  });

  testWidgets('Verify Image doesn\'t reset its RenderImage when changing providers if it has gaplessPlayback set', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final TestImageProvider imageProvider1 = TestImageProvider();
    await tester.pumpWidget(
      Image(
        key: key,
        gaplessPlayback: true,
        image: imageProvider1,
        excludeFromSemantics: true,
      ),
      null,
      EnginePhase.layout,
    );
    RenderImage renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNotNull);

    final TestImageProvider imageProvider2 = TestImageProvider();
    await tester.pumpWidget(
      Image(
        key: key,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        image: imageProvider2,
      ),
      null,
      EnginePhase.layout,
    );

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNotNull);
  });

  testWidgets('Verify ImageProvider configuration inheritance', (WidgetTester tester) async {
    final GlobalKey mediaQueryKey1 = GlobalKey(debugLabel: 'mediaQueryKey1');
    final GlobalKey mediaQueryKey2 = GlobalKey(debugLabel: 'mediaQueryKey2');
    final GlobalKey imageKey = GlobalKey(debugLabel: 'image');
    final TestImageProvider imageProvider = TestImageProvider();

    // Of the two nested MediaQuery objects, the innermost one,
    // mediaQuery2, should define the configuration of the imageProvider.
    await tester.pumpWidget(
      MediaQuery(
        key: mediaQueryKey1,
        data: const MediaQueryData(
          devicePixelRatio: 10.0,
          padding: EdgeInsets.zero,
        ),
        child: MediaQuery(
          key: mediaQueryKey2,
          data: const MediaQueryData(
            devicePixelRatio: 5.0,
            padding: EdgeInsets.zero,
          ),
          child: Image(
            excludeFromSemantics: true,
            key: imageKey,
            image: imageProvider,
          ),
        ),
      ),
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 5.0);

    // This is the same widget hierarchy as before except that the
    // two MediaQuery objects have exchanged places. The imageProvider
    // should be resolved again, with the new innermost MediaQuery.
    await tester.pumpWidget(
      MediaQuery(
        key: mediaQueryKey2,
        data: const MediaQueryData(
          devicePixelRatio: 5.0,
          padding: EdgeInsets.zero,
        ),
        child: MediaQuery(
          key: mediaQueryKey1,
          data: const MediaQueryData(
            devicePixelRatio: 10.0,
            padding: EdgeInsets.zero,
          ),
          child: Image(
            excludeFromSemantics: true,
            key: imageKey,
            image: imageProvider,
          ),
        ),
      ),
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 10.0);
  });

  testWidgets('Verify ImageProvider configuration inheritance again', (WidgetTester tester) async {
    final GlobalKey mediaQueryKey1 = GlobalKey(debugLabel: 'mediaQueryKey1');
    final GlobalKey mediaQueryKey2 = GlobalKey(debugLabel: 'mediaQueryKey2');
    final GlobalKey imageKey = GlobalKey(debugLabel: 'image');
    final TestImageProvider imageProvider = TestImageProvider();

    // This is just a variation on the previous test. In this version the location
    // of the Image changes and the MediaQuery widgets do not.
    await tester.pumpWidget(
      Row(
        textDirection: TextDirection.ltr,
        children: <Widget> [
          MediaQuery(
            key: mediaQueryKey2,
            data: const MediaQueryData(
              devicePixelRatio: 5.0,
              padding: EdgeInsets.zero,
            ),
            child: Image(
              excludeFromSemantics: true,
              key: imageKey,
              image: imageProvider,
            ),
          ),
          MediaQuery(
            key: mediaQueryKey1,
            data: const MediaQueryData(
              devicePixelRatio: 10.0,
              padding: EdgeInsets.zero,
            ),
            child: Container(width: 100.0),
          ),
        ],
      ),
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 5.0);

    await tester.pumpWidget(
      Row(
        textDirection: TextDirection.ltr,
        children: <Widget> [
          MediaQuery(
            key: mediaQueryKey2,
            data: const MediaQueryData(
              devicePixelRatio: 5.0,
              padding: EdgeInsets.zero,
            ),
            child: Container(width: 100.0),
          ),
          MediaQuery(
            key: mediaQueryKey1,
            data: const MediaQueryData(
              devicePixelRatio: 10.0,
              padding: EdgeInsets.zero,
            ),
            child: Image(
              excludeFromSemantics: true,
              key: imageKey,
              image: imageProvider,
            ),
          ),
        ],
      ),
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 10.0);
  });

  testWidgets('Verify Image stops listening to ImageStream', (WidgetTester tester) async {
    final TestImageProvider imageProvider = TestImageProvider();
    await tester.pumpWidget(Image(image: imageProvider, excludeFromSemantics: true));
    final State<Image> image = tester.state/*State<Image>*/(find.byType(Image));
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, unresolved, 2 listeners), pixels: null, loadingProgress: null, frameNumber: null, wasSynchronouslyLoaded: false)'));
    imageProvider.complete();
    await tester.pump();
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, [100×100] @ 1.0x, 1 listener), pixels: [100×100] @ 1.0x, loadingProgress: null, frameNumber: 0, wasSynchronouslyLoaded: false)'));
    await tester.pumpWidget(Container());
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(lifecycle state: defunct, not mounted, stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, [100×100] @ 1.0x, 0 listeners), pixels: [100×100] @ 1.0x, loadingProgress: null, frameNumber: 0, wasSynchronouslyLoaded: false)'));
  });

  testWidgets('Stream completer errors can be listened to by attaching before resolving', (WidgetTester tester) async {
    dynamic capturedException;
    StackTrace capturedStackTrace;
    ImageInfo capturedImage;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
    };
    final ImageListener listener = (ImageInfo info, bool synchronous) {
      capturedImage = info;
    };

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final TestImageProvider imageProvider = TestImageProvider();
    imageProvider._streamCompleter.addListener(ImageStreamListener(listener, onError: errorListener));
    ImageConfiguration configuration;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          configuration = createLocalImageConfiguration(context);
          return Container();
        },
      ),
    );
    imageProvider.resolve(configuration);
    imageProvider.fail(testException, testStack);

    expect(tester.binding.microtaskCount, 1);
    await tester.idle(); // Let the failed completer's future hit the stream completer.
    expect(tester.binding.microtaskCount, 0);

    expect(capturedImage, isNull); // The image stream listeners should never be called.
    // The image stream error handler should have the original exception.
    expect(capturedException, testException);
    expect(capturedStackTrace, testStack);
    // If there is an error listener, there should be no FlutterError reported.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stream completer errors can be listened to by attaching after resolving', (WidgetTester tester) async {
    dynamic capturedException;
    StackTrace capturedStackTrace;
    dynamic reportedException;
    StackTrace reportedStackTrace;
    ImageInfo capturedImage;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
    };
    final ImageListener listener = (ImageInfo info, bool synchronous) {
      capturedImage = info;
    };
    FlutterError.onError = (FlutterErrorDetails flutterError) {
      reportedException = flutterError.exception;
      reportedStackTrace = flutterError.stack;
    };

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final TestImageProvider imageProvider = TestImageProvider();
    ImageConfiguration configuration;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          configuration = createLocalImageConfiguration(context);
          return Container();
        },
      ),
    );
    final ImageStream streamUnderTest = imageProvider.resolve(configuration);

    imageProvider.fail(testException, testStack);

    expect(tester.binding.microtaskCount, 1);
    await tester.idle(); // Let the failed completer's future hit the stream completer.
    expect(tester.binding.microtaskCount, 0);

    // Since there's no listeners attached yet, report error up via
    // FlutterError.
    expect(reportedException, testException);
    expect(reportedStackTrace, testStack);

    streamUnderTest.addListener(ImageStreamListener(listener, onError: errorListener));

    expect(capturedImage, isNull); // The image stream listeners should never be called.
    // The image stream error handler should have the original exception.
    expect(capturedException, testException);
    expect(capturedStackTrace, testStack);
  });

  testWidgets('Duplicate listener registration does not affect error listeners', (WidgetTester tester) async {
    dynamic capturedException;
    StackTrace capturedStackTrace;
    ImageInfo capturedImage;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
    };
    final ImageListener listener = (ImageInfo info, bool synchronous) {
      capturedImage = info;
    };

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final TestImageProvider imageProvider = TestImageProvider();
    imageProvider._streamCompleter.addListener(ImageStreamListener(listener, onError: errorListener));
    // Add the exact same listener a second time without the errorListener.
    imageProvider._streamCompleter.addListener(ImageStreamListener(listener));
    ImageConfiguration configuration;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          configuration = createLocalImageConfiguration(context);
          return Container();
        },
      ),
    );
    imageProvider.resolve(configuration);
    imageProvider.fail(testException, testStack);

    expect(tester.binding.microtaskCount, 1);
    await tester.idle(); // Let the failed completer's future hit the stream completer.
    expect(tester.binding.microtaskCount, 0);

    expect(capturedImage, isNull); // The image stream listeners should never be called.
    // The image stream error handler should have the original exception.
    expect(capturedException, testException);
    expect(capturedStackTrace, testStack);
    // If there is an error listener, there should be no FlutterError reported.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Duplicate error listeners are all called', (WidgetTester tester) async {
    dynamic capturedException;
    StackTrace capturedStackTrace;
    ImageInfo capturedImage;
    int errorListenerCalled = 0;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
      errorListenerCalled++;
    };
    final ImageListener listener = (ImageInfo info, bool synchronous) {
      capturedImage = info;
    };

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final TestImageProvider imageProvider = TestImageProvider();
    imageProvider._streamCompleter.addListener(ImageStreamListener(listener, onError: errorListener));
    // Add the exact same errorListener a second time.
    imageProvider._streamCompleter.addListener(ImageStreamListener(listener, onError: errorListener));
    ImageConfiguration configuration;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          configuration = createLocalImageConfiguration(context);
          return Container();
        },
      ),
    );
    imageProvider.resolve(configuration);
    imageProvider.fail(testException, testStack);

    expect(tester.binding.microtaskCount, 1);
    await tester.idle(); // Let the failed completer's future hit the stream completer.
    expect(tester.binding.microtaskCount, 0);

    expect(capturedImage, isNull); // The image stream listeners should never be called.
    // The image stream error handler should have the original exception.
    expect(capturedException, testException);
    expect(capturedStackTrace, testStack);
    expect(errorListenerCalled, 2);
    // If there is an error listener, there should be no FlutterError reported.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Listeners are only removed if callback tuple matches', (WidgetTester tester) async {
    bool errorListenerCalled = false;
    dynamic reportedException;
    StackTrace reportedStackTrace;
    ImageInfo capturedImage;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      errorListenerCalled = true;
      reportedException = exception;
      reportedStackTrace = stackTrace;
    };
    final ImageListener listener = (ImageInfo info, bool synchronous) {
      capturedImage = info;
    };

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final TestImageProvider imageProvider = TestImageProvider();
    imageProvider._streamCompleter.addListener(ImageStreamListener(listener, onError: errorListener));
    // Now remove the listener the error listener is attached to.
    // Don't explicitly remove the error listener.
    imageProvider._streamCompleter.removeListener(ImageStreamListener(listener));
    ImageConfiguration configuration;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          configuration = createLocalImageConfiguration(context);
          return Container();
        },
      ),
    );
    imageProvider.resolve(configuration);

    imageProvider.fail(testException, testStack);

    expect(tester.binding.microtaskCount, 1);
    await tester.idle(); // Let the failed completer's future hit the stream completer.
    expect(tester.binding.microtaskCount, 0);

    expect(errorListenerCalled, true);
    expect(reportedException, testException);
    expect(reportedStackTrace, testStack);
    expect(capturedImage, isNull); // The image stream listeners should never be called.
  });

  testWidgets('Removing listener removes one listener and error listener', (WidgetTester tester) async {
    int errorListenerCalled = 0;
    ImageInfo capturedImage;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      errorListenerCalled++;
    };
    final ImageListener listener = (ImageInfo info, bool synchronous) {
      capturedImage = info;
    };

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final TestImageProvider imageProvider = TestImageProvider();
    imageProvider._streamCompleter.addListener(ImageStreamListener(listener, onError: errorListener));
    // Duplicates the same set of listener and errorListener.
    imageProvider._streamCompleter.addListener(ImageStreamListener(listener, onError: errorListener));
    // Now remove one entry of the specified listener and associated error listener.
    // Don't explicitly remove the error listener.
    imageProvider._streamCompleter.removeListener(ImageStreamListener(listener, onError: errorListener));
    ImageConfiguration configuration;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          configuration = createLocalImageConfiguration(context);
          return Container();
        },
      ),
    );
    imageProvider.resolve(configuration);

    imageProvider.fail(testException, testStack);

    expect(tester.binding.microtaskCount, 1);
    await tester.idle(); // Let the failed completer's future hit the stream completer.
    expect(tester.binding.microtaskCount, 0);

    expect(errorListenerCalled, 1);
    expect(capturedImage, isNull); // The image stream listeners should never be called.
  });

  testWidgets('Image.memory control test', (WidgetTester tester) async {
    await tester.pumpWidget(Image.memory(Uint8List.fromList(kTransparentImage), excludeFromSemantics: true,));
  });

  testWidgets('Image color and colorBlend parameters', (WidgetTester tester) async {
    await tester.pumpWidget(
      Image(
        excludeFromSemantics: true,
        image: TestImageProvider(),
        color: const Color(0xFF00FF00),
        colorBlendMode: BlendMode.clear,
      ),
    );
    final RenderImage renderer = tester.renderObject<RenderImage>(find.byType(Image));
    expect(renderer.color, const Color(0xFF00FF00));
    expect(renderer.colorBlendMode, BlendMode.clear);
  });

  testWidgets('Precache', (WidgetTester tester) async {
    final TestImageProvider provider = TestImageProvider();
    Future<void> precache;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          precache = precacheImage(provider, context);
          return Container();
        }
      )
    );
    provider.complete();
    await precache;
    expect(provider._lastResolvedConfiguration, isNotNull);

    // Check that a second resolve of the same image is synchronous.
    final ImageStream stream = provider.resolve(provider._lastResolvedConfiguration);
    bool isSync;
    stream.addListener(ImageStreamListener((ImageInfo image, bool sync) { isSync = sync; }));
    expect(isSync, isTrue);
  });

  testWidgets('Precache remove listeners immediately after future completes, does not crash on successive calls #25143', (WidgetTester tester) async {
    final TestImageStreamCompleter imageStreamCompleter = TestImageStreamCompleter();
    final TestImageProvider provider = TestImageProvider(streamCompleter: imageStreamCompleter);

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          precacheImage(provider, context);
          return Container();
        }
      )
    );

    expect(imageStreamCompleter.listeners.length, 2);
    imageStreamCompleter.listeners.toList()[1].onImage(null, null);

    expect(imageStreamCompleter.listeners.length, 1);
    imageStreamCompleter.listeners.toList()[0].onImage(null, null);

    expect(imageStreamCompleter.listeners.length, 0);
  });

  testWidgets('Precache completes with onError on error', (WidgetTester tester) async {
    dynamic capturedException;
    StackTrace capturedStackTrace;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
    };

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final TestImageProvider imageProvider = TestImageProvider();
    Future<void> precache;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          precache = precacheImage(imageProvider, context, onError: errorListener);
          return Container();
        }
      )
    );
    imageProvider.fail(testException, testStack);
    await precache;

    // The image stream error handler should have the original exception.
    expect(capturedException, testException);
    expect(capturedStackTrace, testStack);
    // If there is an error listener, there should be no FlutterError reported.
    expect(tester.takeException(), isNull);
  });

  testWidgets('TickerMode controls stream registration', (WidgetTester tester) async {
    final TestImageStreamCompleter imageStreamCompleter = TestImageStreamCompleter();
    final Image image = Image(
      excludeFromSemantics: true,
      image: TestImageProvider(streamCompleter: imageStreamCompleter),
    );
    await tester.pumpWidget(
      TickerMode(
        enabled: true,
        child: image,
      ),
    );
    expect(imageStreamCompleter.listeners.length, 2);
    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        child: image,
      ),
    );
    expect(imageStreamCompleter.listeners.length, 1);
  });

  testWidgets('Verify Image shows correct RenderImage when changing to an already completed provider', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();

    final TestImageProvider imageProvider1 = TestImageProvider();
    final TestImageProvider imageProvider2 = TestImageProvider();

    await tester.pumpWidget(
        Container(
            key: key,
            child: Image(
                excludeFromSemantics: true,
                image: imageProvider1,
            ),
        ),
        null,
        EnginePhase.layout,
    );
    RenderImage renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    imageProvider2.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNotNull);

    final ui.Image oldImage = renderImage.image;

    await tester.pumpWidget(
        Container(
            key: key,
            child: Image(
              excludeFromSemantics: true,
              image: imageProvider2,
            ),
        ),
        null,
        EnginePhase.layout,
    );

    renderImage = key.currentContext.findRenderObject() as RenderImage;
    expect(renderImage.image, isNotNull);
    expect(renderImage.image, isNot(equals(oldImage)));
  });

  testWidgets('Image State can be reconfigured to use another image', (WidgetTester tester) async {
    final Image image1 = Image(image: TestImageProvider()..complete(), width: 10.0, excludeFromSemantics: true);
    final Image image2 = Image(image: TestImageProvider()..complete(), width: 20.0, excludeFromSemantics: true);

    final Column column = Column(children: <Widget>[image1, image2]);
    await tester.pumpWidget(column, null, EnginePhase.layout);

    final Column columnSwapped = Column(children: <Widget>[image2, image1]);
    await tester.pumpWidget(columnSwapped, null, EnginePhase.layout);

    final List<RenderImage> renderObjects = tester.renderObjectList<RenderImage>(find.byType(Image)).toList();
    expect(renderObjects, hasLength(2));
    expect(renderObjects[0].image, isNotNull);
    expect(renderObjects[0].width, 20.0);
    expect(renderObjects[1].image, isNotNull);
    expect(renderObjects[1].width, 10.0);
  });

  testWidgets('Image contributes semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: <Widget>[
            Image(
              image: TestImageProvider(),
              width: 100.0,
              height: 100.0,
              semanticLabel: 'test',
            ),
          ],
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          label: 'test',
          rect: const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
          textDirection: TextDirection.ltr,
          flags: <SemanticsFlag>[SemanticsFlag.isImage],
        ),
      ],
    ), ignoreTransform: true));
    semantics.dispose();
  });

  testWidgets('Image can exclude semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Image(
          image: TestImageProvider(),
          width: 100.0,
          height: 100.0,
          excludeFromSemantics: true,
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[]
    )));
    semantics.dispose();
  });

  testWidgets('Image invokes frameBuilder with correct frameNumber argument', (WidgetTester tester) async {
    final ui.Codec codec = await tester.runAsync(() {
      return ui.instantiateImageCodec(Uint8List.fromList(kAnimatedGif));
    });

    Future<ui.Image> nextFrame() async {
      final ui.FrameInfo frameInfo = await tester.runAsync(codec.getNextFrame);
      return frameInfo.image;
    }

    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);
    int lastFrame;

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
          lastFrame = frame;
          return Center(child: child);
        },
      ),
    );

    expect(lastFrame, isNull);
    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    streamCompleter.setData(imageInfo: ImageInfo(image: await nextFrame()));
    await tester.pump();
    expect(lastFrame, 0);
    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    streamCompleter.setData(imageInfo: ImageInfo(image: await nextFrame()));
    await tester.pump();
    expect(lastFrame, 1);
    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('Image invokes frameBuilder with correct wasSynchronouslyLoaded=false', (WidgetTester tester) async {
    final ui.Image image = await tester.runAsync(createTestImage);
    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);
    int lastFrame;
    bool lastFrameWasSync;

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
          lastFrame = frame;
          lastFrameWasSync = wasSynchronouslyLoaded;
          return child;
        },
      ),
    );

    expect(lastFrame, isNull);
    expect(lastFrameWasSync, isFalse);
    expect(find.byType(RawImage), findsOneWidget);
    streamCompleter.setData(imageInfo: ImageInfo(image: image));
    await tester.pump();
    expect(lastFrame, 0);
    expect(lastFrameWasSync, isFalse);
  });

  testWidgets('Image invokes frameBuilder with correct wasSynchronouslyLoaded=true', (WidgetTester tester) async {
    final ui.Image image = await tester.runAsync(createTestImage);
    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter(ImageInfo(image: image));
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);
    int lastFrame;
    bool lastFrameWasSync;

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
          lastFrame = frame;
          lastFrameWasSync = wasSynchronouslyLoaded;
          return child;
        },
      ),
    );

    expect(lastFrame, 0);
    expect(lastFrameWasSync, isTrue);
    expect(find.byType(RawImage), findsOneWidget);
    streamCompleter.setData(imageInfo: ImageInfo(image: image));
    await tester.pump();
    expect(lastFrame, 1);
    expect(lastFrameWasSync, isTrue);
  });

  testWidgets('Image state handles frameBuilder update', (WidgetTester tester) async {
    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
          return Center(child: child);
        },
      ),
    );

    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    final State<Image> state = tester.state(find.byType(Image));

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
          return Padding(padding: const EdgeInsets.all(1), child: child);
        },
      ),
    );

    expect(find.byType(Center), findsNothing);
    expect(find.byType(Padding), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.state(find.byType(Image)), same(state));
  });

  testWidgets('Image state handles enabling and disabling of tickers', (WidgetTester tester) async {
    final ui.Codec codec = await tester.runAsync(() {
      return ui.instantiateImageCodec(Uint8List.fromList(kAnimatedGif));
    });

    Future<ui.Image> nextFrame() async {
      final ui.FrameInfo frameInfo = await tester.runAsync(codec.getNextFrame);
      return frameInfo.image;
    }

    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);
    int lastFrame;
    int buildCount = 0;

    Widget buildFrame(BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
      lastFrame = frame;
      buildCount++;
      return child;
    }

    await tester.pumpWidget(
      TickerMode(
        enabled: true,
        child: Image(
          image: imageProvider,
          frameBuilder: buildFrame,
        ),
      ),
    );

    final State<Image> state = tester.state(find.byType(Image));
    expect(lastFrame, isNull);
    expect(buildCount, 1);
    streamCompleter.setData(imageInfo: ImageInfo(image: await nextFrame()));
    await tester.pump();
    expect(lastFrame, 0);
    expect(buildCount, 2);

    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        child: Image(
          image: imageProvider,
          frameBuilder: buildFrame,
        ),
      ),
    );

    expect(tester.state(find.byType(Image)), same(state));
    expect(lastFrame, 0);
    expect(buildCount, 3);
    streamCompleter.setData(imageInfo: ImageInfo(image: await nextFrame()));
    streamCompleter.setData(imageInfo: ImageInfo(image: await nextFrame()));
    await tester.pump();
    expect(lastFrame, 0);
    expect(buildCount, 3);

    await tester.pumpWidget(
      TickerMode(
        enabled: true,
        child: Image(
          image: imageProvider,
          frameBuilder: buildFrame,
        ),
      ),
    );

    expect(tester.state(find.byType(Image)), same(state));
    expect(lastFrame, 1); // missed a frame because we weren't animating at the time
    expect(buildCount, 4);
  });

  testWidgets('Image invokes loadingBuilder on chunk event notification', (WidgetTester tester) async {
    final ui.Image image = await tester.runAsync(createTestImage);
    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);
    final List<ImageChunkEvent> chunkEvents = <ImageChunkEvent>[];

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
          chunkEvents.add(loadingProgress);
          if (loadingProgress == null)
            return child;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Text('loading ${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes}'),
          );
        },
      ),
    );

    expect(chunkEvents.length, 1);
    expect(chunkEvents.first, isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 10, expectedTotalBytes: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(chunkEvents.length, 2);
    expect(find.text('loading 10 / 100'), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 30, expectedTotalBytes: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(chunkEvents.length, 3);
    expect(find.text('loading 30 / 100'), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);
    streamCompleter.setData(imageInfo: ImageInfo(image: image));
    await tester.pump();
    expect(chunkEvents.length, 4);
    expect(find.byType(Text), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
  }, skip: isBrowser);

  testWidgets('Image doesn\'t rebuild on chunk events if loadingBuilder is null', (WidgetTester tester) async {
    final ui.Image image = await tester.runAsync(createTestImage);
    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        excludeFromSemantics: true,
      ),
    );

    expect(tester.binding.hasScheduledFrame, isFalse);
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 10, expectedTotalBytes: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
    streamCompleter.setData(imageInfo: ImageInfo(image: image));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 10, expectedTotalBytes: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('Image chains the results of frameBuilder and loadingBuilder', (WidgetTester tester) async {
    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        excludeFromSemantics: true,
        frameBuilder: (BuildContext context, Widget child, int frame, bool wasSynchronouslyLoaded) {
          return Padding(padding: const EdgeInsets.all(1), child: child);
        },
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
          return Center(child: child);
        },
      ),
    );

    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(Padding), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.widget<Padding>(find.byType(Padding)).child, isA<RawImage>());
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 10, expectedTotalBytes: 100));
    await tester.pump();
    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(Padding), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.widget<Center>(find.byType(Center)).child, isA<Padding>());
    expect(tester.widget<Padding>(find.byType(Padding)).child, isA<RawImage>());
  }, skip: isBrowser);

  testWidgets('Image state handles loadingBuilder update from null to non-null', (WidgetTester tester) async {
    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);

    await tester.pumpWidget(
      Image(image: imageProvider),
    );

    expect(find.byType(RawImage), findsOneWidget);
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 10, expectedTotalBytes: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
    final State<Image> state = tester.state(find.byType(Image));

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
          return Center(child: child);
        },
      ),
    );

    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.state(find.byType(Image)), same(state));
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 10, expectedTotalBytes: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
  }, skip: isBrowser);

  testWidgets('Image state handles loadingBuilder update from non-null to null', (WidgetTester tester) async {
    final TestImageStreamCompleter streamCompleter = TestImageStreamCompleter();
    final TestImageProvider imageProvider = TestImageProvider(streamCompleter: streamCompleter);

    await tester.pumpWidget(
      Image(
        image: imageProvider,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
          return Center(child: child);
        },
      ),
    );

    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 10, expectedTotalBytes: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawImage), findsOneWidget);
    final State<Image> state = tester.state(find.byType(Image));

    await tester.pumpWidget(
      Image(image: imageProvider),
    );

    expect(find.byType(Center), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.state(find.byType(Image)), same(state));
    streamCompleter.setData(chunkEvent: const ImageChunkEvent(cumulativeBytesLoaded: 10, expectedTotalBytes: 100));
    expect(tester.binding.hasScheduledFrame, isFalse);
  }, skip: isBrowser);

  testWidgets('Image defers loading while fast scrolling', (WidgetTester tester) async {
    const int gridCells = 1000;
    final List<TestImageProvider> imageProviders = <TestImageProvider>[];
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.builder(
        controller: controller,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: gridCells,
        itemBuilder: (_, int index) {
          final TestImageProvider provider = TestImageProvider();
          imageProviders.add(provider);
          return SizedBox(
            height: 250,
            width: 250,
            child: Image(
              image: provider,
              semanticLabel: index.toString(),
            ),
          );
        },
      ),
    ));

    final bool Function(TestImageProvider) loadCalled = (TestImageProvider provider) => provider.loadCalled;
    final bool Function(TestImageProvider) loadNotCalled = (TestImageProvider provider) => !provider.loadCalled;

    expect(find.bySemanticsLabel('5'), findsOneWidget);
    expect(imageProviders.length, 12);
    expect(imageProviders.every(loadCalled), true);

    imageProviders.clear();

    // Simulate a very fast fling.
    controller.animateTo(
      30000,
      duration: const Duration(seconds: 2),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    // The last 15 images on screen have loaded because the scrolling settled there.
    // The rest have not loaded.
    expect(imageProviders.length, 309);
    expect(imageProviders.skip(309 - 15).every(loadCalled), true);
    expect(imageProviders.take(309 - 15).every(loadNotCalled), true);
  });
}

class TestImageProvider extends ImageProvider<TestImageProvider> {
  TestImageProvider({ImageStreamCompleter streamCompleter}) {
    _streamCompleter = streamCompleter
      ?? OneFrameImageStreamCompleter(_completer.future);
  }

  final Completer<ImageInfo> _completer = Completer<ImageInfo>();
  ImageStreamCompleter _streamCompleter;
  ImageConfiguration _lastResolvedConfiguration;

  bool get loadCalled => _loadCalled;
  bool _loadCalled = false;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TestImageProvider>(this);
  }

  @override
  void resolveStreamForKey(ImageConfiguration configuration, ImageStream stream, TestImageProvider key, ImageErrorListener handleError) {
    _lastResolvedConfiguration = configuration;
    super.resolveStreamForKey(configuration, stream, key, handleError);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key, DecoderCallback decode) {
    _loadCalled = true;
    return _streamCompleter;
  }

  void complete() {
    _completer.complete(ImageInfo(image: TestImage()));
  }

  void fail(dynamic exception, StackTrace stackTrace) {
    _completer.completeError(exception, stackTrace);
  }

  @override
  String toString() => '${describeIdentity(this)}()';
}

class TestImageStreamCompleter extends ImageStreamCompleter {
  TestImageStreamCompleter([this._currentImage]);

  ImageInfo _currentImage;
  final Set<ImageStreamListener> listeners = <ImageStreamListener>{};

  @override
  void addListener(ImageStreamListener listener) {
    listeners.add(listener);
    if (_currentImage != null) {
      listener.onImage(_currentImage, true);
    }
  }

  @override
  void removeListener(ImageStreamListener listener) {
    listeners.remove(listener);
  }

  void setData({
    ImageInfo imageInfo,
    ImageChunkEvent chunkEvent,
  }) {
    if (imageInfo != null) {
      _currentImage = imageInfo;
    }
    final List<ImageStreamListener> localListeners = listeners.toList();
    for (final ImageStreamListener listener in localListeners) {
      if (imageInfo != null) {
        listener.onImage(imageInfo, false);
      }
      if (chunkEvent != null && listener.onChunk != null) {
        listener.onChunk(chunkEvent);
      }
    }
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
  Future<ByteData> toByteData({ ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba }) async {
    throw UnsupportedError('Cannot encode test image');
  }

  @override
  String toString() => '[$width\u00D7$height]';
}
