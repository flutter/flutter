// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui show Image, ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../painting/image_data.dart';
import 'semantics_tester.dart';

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

    final TestImageProvider imageProvider2 = TestImageProvider();
    await tester.pumpWidget(
      Container(
        key: key,
        child: Image(
          image: imageProvider2,
          excludeFromSemantics: true,
        )
      ),
      null,
      EnginePhase.layout
    );

    renderImage = key.currentContext.findRenderObject();
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

    final TestImageProvider imageProvider2 = TestImageProvider();
    await tester.pumpWidget(
      Container(
        key: key,
        child: Image(
          gaplessPlayback: true,
          image: imageProvider2,
          excludeFromSemantics: true,
        )
      ),
      null,
      EnginePhase.layout
    );

    renderImage = key.currentContext.findRenderObject();
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
      EnginePhase.layout
    );
    RenderImage renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);

    final TestImageProvider imageProvider2 = TestImageProvider();
    await tester.pumpWidget(
      Image(
        key: key,
        image: imageProvider2,
        excludeFromSemantics: true,
      ),
      null,
      EnginePhase.layout
    );

    renderImage = key.currentContext.findRenderObject();
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
      EnginePhase.layout
    );
    RenderImage renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNull);

    imageProvider1.complete();
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext.findRenderObject();
    expect(renderImage.image, isNotNull);

    final TestImageProvider imageProvider2 = TestImageProvider();
    await tester.pumpWidget(
      Image(
        key: key,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        image: imageProvider2
      ),
      null,
      EnginePhase.layout
    );

    renderImage = key.currentContext.findRenderObject();
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
            image: imageProvider
          ),
        )
      )
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
              image: imageProvider
            )
          ),
          MediaQuery(
            key: mediaQueryKey1,
            data: const MediaQueryData(
              devicePixelRatio: 10.0,
              padding: EdgeInsets.zero,
            ),
            child: Container(width: 100.0)
          )
        ]
      )
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
            child: Container(width: 100.0)
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
              image: imageProvider
            )
          )
        ]
      )
    );

    expect(imageProvider._lastResolvedConfiguration.devicePixelRatio, 10.0);
  });

  testWidgets('Verify Image stops listening to ImageStream', (WidgetTester tester) async {
    final TestImageProvider imageProvider = TestImageProvider();
    await tester.pumpWidget(Image(image: imageProvider, excludeFromSemantics: true));
    final State<Image> image = tester.state/*State<Image>*/(find.byType(Image));
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, unresolved, 2 listeners), pixels: null)'));
    imageProvider.complete();
    await tester.pump();
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, [100×100] @ 1.0x, 1 listener), pixels: [100×100] @ 1.0x)'));
    await tester.pumpWidget(Container());
    expect(image.toString(), equalsIgnoringHashCodes('_ImageState#00000(lifecycle state: defunct, not mounted, stream: ImageStream#00000(OneFrameImageStreamCompleter#00000, [100×100] @ 1.0x, 0 listeners), pixels: [100×100] @ 1.0x)'));
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
    imageProvider._streamCompleter.addListener(listener, onError: errorListener);
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

    streamUnderTest.addListener(listener, onError: errorListener);

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
    imageProvider._streamCompleter.addListener(listener, onError: errorListener);
    // Add the exact same listener a second time without the errorListener.
    imageProvider._streamCompleter.addListener(listener);
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
    imageProvider._streamCompleter.addListener(listener, onError: errorListener);
    // Add the exact same errorListener a second time.
    imageProvider._streamCompleter.addListener(null, onError: errorListener);
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

  testWidgets('Error listeners are removed along with listeners', (WidgetTester tester) async {
    bool errorListenerCalled = false;
    dynamic reportedException;
    StackTrace reportedStackTrace;
    ImageInfo capturedImage;
    final ImageErrorListener errorListener = (dynamic exception, StackTrace stackTrace) {
      errorListenerCalled = true;
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
    imageProvider._streamCompleter.addListener(listener, onError: errorListener);
    // Now remove the listener the error listener is attached to.
    // Don't explicitly remove the error listener.
    imageProvider._streamCompleter.removeListener(listener);
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

    expect(errorListenerCalled, false);
    // Since the error listener is removed, bubble up to FlutterError.
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
    imageProvider._streamCompleter.addListener(listener, onError: errorListener);
    // Duplicates the same set of listener and errorListener.
    imageProvider._streamCompleter.addListener(listener, onError: errorListener);
    // Now remove one entry of the specified listener and associated error listener.
    // Don't explicitly remove the error listener.
    imageProvider._streamCompleter.removeListener(listener);
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
        colorBlendMode: BlendMode.clear
      )
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
    stream.addListener((ImageInfo image, bool sync) { isSync = sync; });
    expect(isSync, isTrue);
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
        Container(
            key: key,
            child: Image(
              excludeFromSemantics: true,
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
          rect: Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
          textDirection: TextDirection.ltr,
          flags: <SemanticsFlag>[SemanticsFlag.isImage],
        )
      ]
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
}

class TestImageProvider extends ImageProvider<TestImageProvider> {
  TestImageProvider({ImageStreamCompleter streamCompleter}) {
    _streamCompleter = streamCompleter
      ?? OneFrameImageStreamCompleter(_completer.future);
  }

  final Completer<ImageInfo> _completer = Completer<ImageInfo>();
  ImageStreamCompleter _streamCompleter;
  ImageConfiguration _lastResolvedConfiguration;

  @override
  Future<TestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<TestImageProvider>(this);
  }

  @override
  ImageStream resolve(ImageConfiguration configuration) {
    _lastResolvedConfiguration = configuration;
    return super.resolve(configuration);
  }

  @override
  ImageStreamCompleter load(TestImageProvider key) => _streamCompleter;

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
  final Map<ImageListener, ImageErrorListener> listeners = <ImageListener, ImageErrorListener> {};

  @override
  void addListener(ImageListener listener, { ImageErrorListener onError }) {
    listeners[listener] = onError;
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
  Future<ByteData> toByteData({ui.ImageByteFormat format}) async {
    throw UnsupportedError('Cannot encode test image');
  }

  @override
  String toString() => '[$width\u00D7$height]';
}
