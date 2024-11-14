// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser') // This file contains web-only library.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/painting/_network_image_web.dart';
import 'package:flutter/src/web.dart' as web_shim;
import 'package:flutter/src/widgets/_web_image_web.dart' hide precacheWebImage;
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:web/web.dart' as web;

import '../image_data.dart';
import '../painting/_test_http_request.dart';
import 'semantics_tester.dart';

void main() {
  late int originalCacheSize;
  late web_shim.HTMLImageElement image10x10;

  setUp(() async {
    originalCacheSize = webImageCache.maximumSize;
    webImageCache.clear();
    webImageCache.clearLiveImages();
    image10x10 = createTestWebImage(width: 10, height: 10);
  });

  tearDown(() {
    debugRestoreHttpRequestFactory();
    webImageCache.maximumSize = originalCacheSize;
  });

  testWidgets('defaults to Image.network if src is same origin',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    final String imageUrl = '${web_shim.window.origin}/images/image.jpg';

    await tester.pumpWidget(WebImage.network(imageUrl));
    await tester.pumpAndSettle();

    // Since the request for the bytes succeeds, this should put an
    // Image.network (which resolves to a RawImage) in the widget tree.
    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('defaults to Image.network if src bytes can be fetched',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    await tester.pumpWidget(
        WebImage.network('https://www.example.com/images/frame.png'));
    await tester.pumpAndSettle();

    // Since the request for the bytes succeeds, this should put an
    // Image.network (which resolves to a RawImage) in the widget tree.
    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('defaults to HtmlElementView if src bytes cannot be fetched',
      (WidgetTester tester) async {
    final TestHttpRequest testHttpRequest = TestHttpRequest()
      ..status = 500
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    await tester.pumpWidget(
      WebImage.network('https://www.example.com/images/frame.png'),
    );
    // Pump once to create and start resolving the image.
    await tester.pumpAndSettle();

    // Since the request for the bytes succeeds, this should put an
    // Image.network (which resolves to a RawWebImage) in the widget tree.
    expect(find.byType(RawWebImage), findsOneWidget);
  });

  testWidgets('Verify WebImage does not use disposed handles', (WidgetTester tester) async {
    final web_shim.HTMLImageElement image100x100 = createTestWebImage(width: 100, height: 100);

    final _TestWebImageProvider imageProvider1 = _TestWebImageProvider('http://example.com/pic1');
    final _TestWebImageProvider imageProvider2 = _TestWebImageProvider('http://example.com/pic2');

    final ValueNotifier<_TestWebImageProvider> imageListenable = ValueNotifier<_TestWebImageProvider>(imageProvider1);
    addTearDown(imageListenable.dispose);
    final ValueNotifier<int> innerListenable = ValueNotifier<int>(0);
    addTearDown(innerListenable.dispose);

    bool imageLoaded = false;

    await tester.pumpWidget(ValueListenableBuilder<_TestWebImageProvider>(
      valueListenable: imageListenable,
      builder: (BuildContext context, _TestWebImageProvider image, Widget? child) => WebImage(
        image: image,
        frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
          if (frame == 0) {
            imageLoaded = true;
          }
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => ValueListenableBuilder<int>(
              valueListenable: innerListenable,
              builder: (BuildContext context, int value, Widget? valueListenableChild) => KeyedSubtree(
                key: UniqueKey(),
                child: child,
              ),
            ),
          );
        },
      ),
    ));

    imageLoaded = false;
    imageProvider1.complete(image10x10);
    await tester.idle();
    await tester.pump();
    expect(imageLoaded, true);

    imageLoaded = false;
    imageListenable.value = imageProvider2;
    innerListenable.value += 1;
    imageProvider2.complete(image100x100);
    await tester.idle();
    await tester.pump();
    expect(imageLoaded, true);
  });

  testWidgets('Verify WebImage resets its RenderWebImage when changing providers', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final _TestWebImageProvider imageProvider1 = _TestWebImageProvider('example.com/pic.jpg');
    await tester.pumpWidget(
      Container(
        key: key,
        child: WebImage(
          image: imageProvider1,
          excludeFromSemantics: true,
        ),
      ),
      phase: EnginePhase.layout,
    );
    RenderWebImage renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete(image10x10);
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNotNull);

    final _TestWebImageProvider imageProvider2 = _TestWebImageProvider('example.com/pic2.jpg');
    await tester.pumpWidget(
      Container(
        key: key,
        child: WebImage(
          image: imageProvider2,
          excludeFromSemantics: true,
        ),
      ),
      phase: EnginePhase.layout,
    );

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNull);
  });

  testWidgets("Verify WebImage doesn't reset its RenderWebImage when changing providers if it has gaplessPlayback set", (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final _TestWebImageProvider imageProvider1 = _TestWebImageProvider('example.com/pic.jpg');
    await tester.pumpWidget(
      Container(
        key: key,
        child: WebImage(
          gaplessPlayback: true,
          image: imageProvider1,
          excludeFromSemantics: true,
        ),
      ),
      phase: EnginePhase.layout,
    );
    RenderWebImage renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete(image10x10);
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNotNull);

    final _TestWebImageProvider imageProvider2 = _TestWebImageProvider('example.com/pic2.jpg');
    await tester.pumpWidget(
      Container(
        key: key,
        child: WebImage(
          gaplessPlayback: true,
          image: imageProvider2,
          excludeFromSemantics: true,
        ),
      ),
      phase: EnginePhase.layout,
    );

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNotNull);
  });

  testWidgets('Verify WebImage resets its RenderWebImage when changing providers if it has a key', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final _TestWebImageProvider imageProvider1 = _TestWebImageProvider('example.com/pic.jpg');
    await tester.pumpWidget(
      WebImage(
        key: key,
        image: imageProvider1,
        excludeFromSemantics: true,
      ),
      phase: EnginePhase.layout,
    );
    RenderWebImage renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete(image10x10);
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNotNull);

    final _TestWebImageProvider imageProvider2 = _TestWebImageProvider('example.com/pic2.jpg');
    await tester.pumpWidget(
      WebImage(
        key: key,
        image: imageProvider2,
        excludeFromSemantics: true,
      ),
      phase: EnginePhase.layout,
    );

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNull);
  });

  testWidgets("Verify WebImage doesn't reset its RenderWebImage when changing providers if it has gaplessPlayback set", (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final _TestWebImageProvider imageProvider1 = _TestWebImageProvider('example.com/pic.jpg');
    await tester.pumpWidget(
      WebImage(
        key: key,
        gaplessPlayback: true,
        image: imageProvider1,
        excludeFromSemantics: true,
      ),
      phase: EnginePhase.layout,
    );
    RenderWebImage renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete(image10x10);
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNotNull);

    final _TestWebImageProvider imageProvider2 = _TestWebImageProvider('example.com/pic2.jpg');
    await tester.pumpWidget(
      WebImage(
        key: key,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        image: imageProvider2,
      ),
      phase: EnginePhase.layout,
    );

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNotNull);
  });

  testWidgets('Verify WebImage stops listening to WebImageStream', (WidgetTester tester) async {
    final web_shim.HTMLImageElement image100x100 = createTestWebImage(width: 100, height: 100);
    // Web does not override the toString, whereas VM does
    final String imageString = image100x100.toString();

    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg');
    await tester.pumpWidget(WebImage(image: imageProvider, excludeFromSemantics: true));
    final State<WebImage> image = tester.state/*State<WebImage>*/(find.byType(WebImage));
    expect(image.toString(), equalsIgnoringHashCodes('WebImageState#00000(stream: WebImageStream#00000(OneFrameWebImageStreamCompleter#00000, unresolved, 2 listeners, 0 ephemeralErrorListeners), <img>: null, wasSynchronouslyLoaded: false)'));
    imageProvider.complete(image100x100);
    await tester.pump();
    expect(image.toString(), equalsIgnoringHashCodes('WebImageState#00000(stream: WebImageStream#00000(OneFrameWebImageStreamCompleter#00000, $imageString, 1 listener, 0 ephemeralErrorListeners), <img>: $imageString, wasSynchronouslyLoaded: false)'));
    await tester.pumpWidget(Container());
    expect(image.toString(), equalsIgnoringHashCodes('WebImageState#00000(lifecycle state: defunct, not mounted, stream: WebImageStream#00000(OneFrameWebImageStreamCompleter#00000, $imageString, 0 listeners, 0 ephemeralErrorListeners), <img>: null, wasSynchronouslyLoaded: false)'));
  });

  testWidgets('Stream completer errors can be listened to by attaching before resolving', (WidgetTester tester) async {
    dynamic capturedException;
    StackTrace? capturedStackTrace;
    WebImageInfo? capturedImage;
    void errorListener(dynamic exception, StackTrace? stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
    }
    void listener(WebImageInfo info, bool synchronous) {
      capturedImage = info;
    }
    void fetchableListener(bool synchronous) {
    }

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg');
    imageProvider._streamCompleter.addListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));
    imageProvider.resolve();
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
    StackTrace? capturedStackTrace;
    dynamic reportedException;
    StackTrace? reportedStackTrace;
    WebImageInfo? capturedImage;
    void errorListener(dynamic exception, StackTrace? stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
    }
    void listener(WebImageInfo info, bool synchronous) {
      capturedImage = info;
    }
    void fetchableListener(bool synchronous) {
    }
    FlutterError.onError = (FlutterErrorDetails flutterError) {
      reportedException = flutterError.exception;
      reportedStackTrace = flutterError.stack;
    };

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg');
    final WebImageStream streamUnderTest = imageProvider.resolve();

    imageProvider.fail(testException, testStack);

    expect(tester.binding.microtaskCount, 1);
    await tester.idle(); // Let the failed completer's future hit the stream completer.
    expect(tester.binding.microtaskCount, 0);

    // Since there's no listeners attached yet, report error up via
    // FlutterError.
    expect(reportedException, testException);
    expect(reportedStackTrace, testStack);

    streamUnderTest.addListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));

    expect(capturedImage, isNull); // The image stream listeners should never be called.
    // The image stream error handler should have the original exception.
    expect(capturedException, testException);
    expect(capturedStackTrace, testStack);
  });

  testWidgets('Duplicate listener registration does not affect error listeners', (WidgetTester tester) async {
    dynamic capturedException;
    StackTrace? capturedStackTrace;
    WebImageInfo? capturedImage;
    void errorListener(dynamic exception, StackTrace? stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
    }
    void listener(WebImageInfo info, bool synchronous) {
      capturedImage = info;
    }
    void fetchableListener(bool synchronous) {
    }

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg');
    imageProvider._streamCompleter.addListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));
    // Add the exact same listener a second time without the errorListener.
    imageProvider._streamCompleter.addListener(WebImageStreamListener(listener, fetchableListener));
    imageProvider.resolve();
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
    StackTrace? capturedStackTrace;
    WebImageInfo? capturedImage;
    int errorListenerCalled = 0;
    void errorListener(dynamic exception, StackTrace? stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
      errorListenerCalled++;
    }
    void listener(WebImageInfo info, bool synchronous) {
      capturedImage = info;
    }
    void fetchableListener(bool synchronous) {
    }

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg');
    imageProvider._streamCompleter.addListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));
    // Add the exact same errorListener a second time.
    imageProvider._streamCompleter.addListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));
    imageProvider.resolve();
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
    StackTrace? reportedStackTrace;
    WebImageInfo? capturedImage;
    void errorListener(dynamic exception, StackTrace? stackTrace) {
      errorListenerCalled = true;
      reportedException = exception;
      reportedStackTrace = stackTrace;
    }
    void listener(WebImageInfo info, bool synchronous) {
      capturedImage = info;
    }
    void fetchableListener(bool synchronous) {
    }

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg');
    imageProvider._streamCompleter.addListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));
    // Now remove the listener the error listener is attached to.
    // Don't explicitly remove the error listener.
    imageProvider._streamCompleter.removeListener(WebImageStreamListener(listener, fetchableListener));
    imageProvider.resolve();

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
    WebImageInfo? capturedImage;
    void errorListener(dynamic exception, StackTrace? stackTrace) {
      errorListenerCalled++;
    }
    void listener(WebImageInfo info, bool synchronous) {
      capturedImage = info;
    }
    void fetchableListener(bool synchronous) {
    }

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg');
    imageProvider._streamCompleter.addListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));
    // Duplicates the same set of listener and errorListener.
    imageProvider._streamCompleter.addListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));
    // Now remove one entry of the specified listener and associated error listener.
    // Don't explicitly remove the error listener.
    imageProvider._streamCompleter.removeListener(WebImageStreamListener(listener, fetchableListener, onError: errorListener));
    imageProvider.resolve();

    imageProvider.fail(testException, testStack);

    expect(tester.binding.microtaskCount, 1);
    await tester.idle(); // Let the failed completer's future hit the stream completer.
    expect(tester.binding.microtaskCount, 0);

    expect(errorListenerCalled, 1);
    expect(capturedImage, isNull); // The image stream listeners should never be called.
  });

  testWidgets('Precache',
  (WidgetTester tester) async {
    final _TestWebImageProvider provider = _TestWebImageProvider('example.com/pic.jpg');
    late Future<void> precache;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          precache = precacheWebImage(provider, context);
          return Container();
        },
      ),
    );
    provider.complete(image10x10);
    await precache;

    // Check that a second resolve of the same image is synchronous.
    final WebImageStream stream = provider.resolve();
    late bool isSync;
    stream.addListener(WebImageStreamListener((WebImageInfo image, bool sync) {
      isSync = sync;
    }, (bool sync) {}));
    expect(isSync, isTrue);
  });

  testWidgets('Precache removes original listener immediately after future completes, does not crash on successive calls #25143',
  experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(), // The test leaks by design, see [_TestImageStreamCompleter].
  (WidgetTester tester) async {
    final _TestWebImageStreamCompleter imageStreamCompleter = _TestWebImageStreamCompleter();
    final _TestWebImageProvider provider = _TestWebImageProvider('example.com/pic.jpg', streamCompleter: imageStreamCompleter);

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          precacheWebImage(provider, context);
          return Container();
        },
      ),
    );

    // Two listeners - one is the listener added by precacheImage, the other by the ImageCache.
    final List<WebImageStreamListener> listeners = imageStreamCompleter.listeners.toList();
    expect(listeners.length, 2);

    // Make sure the first listener can be called re-entrantly
    final WebImageInfo imageInfo = WebImageInfo(image10x10);

    listeners[1].onImage(imageInfo.clone(), false);
    listeners[1].onImage(imageInfo.clone(), false);

    // Make sure the second listener can be called re-entrantly.
    listeners[0].onImage(imageInfo.clone(), false);
    listeners[0].onImage(imageInfo.clone(), false);

    imageStreamCompleter.dispose();
    imageCache.clear();
  });

  testWidgets('Precache completes with onError on error', (WidgetTester tester) async {
    dynamic capturedException;
    StackTrace? capturedStackTrace;
    void errorListener(dynamic exception, StackTrace? stackTrace) {
      capturedException = exception;
      capturedStackTrace = stackTrace;
    }

    final Exception testException = Exception('cannot resolve host');
    final StackTrace testStack = StackTrace.current;
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg');
    late Future<void> precache;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          precache = precacheWebImage(imageProvider, context, onError: errorListener);
          return Container();
        },
      ),
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
    final _TestWebImageStreamCompleter imageStreamCompleter = _TestWebImageStreamCompleter();
    final WebImage image = WebImage(
      excludeFromSemantics: true,
      image: _TestWebImageProvider('example.com/pic.jpg', streamCompleter: imageStreamCompleter),
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

  testWidgets('Verify WebImage shows correct RenderWebImage when changing to an already completed provider', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();

    final _TestWebImageProvider imageProvider1 = _TestWebImageProvider('example.com/pic1.jpg');
    final _TestWebImageProvider imageProvider2 = _TestWebImageProvider('example.com/pic2.jpg');
    final web_shim.HTMLImageElement image100x100 = createTestWebImage(width: 100, height: 100);

    await tester.pumpWidget(
        Container(
            key: key,
            child: WebImage(
                excludeFromSemantics: true,
                image: imageProvider1,
            ),
        ),
        phase: EnginePhase.layout,
    );
    RenderWebImage renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNull);

    imageProvider1.complete(image10x10);
    imageProvider2.complete(image100x100);
    await tester.idle(); // resolve the future from the image provider
    await tester.pump(null, EnginePhase.layout);

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNotNull);

    final web_shim.HTMLImageElement oldImage = renderImage.image!;

    await tester.pumpWidget(
        Container(
            key: key,
            child: WebImage(
              excludeFromSemantics: true,
              image: imageProvider2,
            ),
        ),
        phase: EnginePhase.layout,
    );

    renderImage = key.currentContext!.findRenderObject()! as RenderWebImage;
    expect(renderImage.image, isNotNull);
    expect(renderImage.image, isNot(equals(oldImage)));
  });

  testWidgets('WebImage State can be reconfigured to use another image', (WidgetTester tester) async {
    final WebImage image1 = WebImage(image: _TestWebImageProvider('example.com/pic1.jpg')..complete(image10x10.cloneNode(true) as web_shim.HTMLImageElement), width: 10.0, excludeFromSemantics: true);
    final WebImage image2 = WebImage(image: _TestWebImageProvider('example.com/pic2.jpg')..complete(image10x10.cloneNode(true) as web_shim.HTMLImageElement), width: 20.0, excludeFromSemantics: true);

    final Column column = Column(children: <Widget>[image1, image2]);
    await tester.pumpWidget(column, phase:EnginePhase.layout);

    final Column columnSwapped = Column(children: <Widget>[image2, image1]);
    await tester.pumpWidget(columnSwapped, phase: EnginePhase.layout);

    final List<RenderWebImage> renderObjects = tester.renderObjectList<RenderWebImage>(find.byType(WebImage)).toList();
    expect(renderObjects, hasLength(2));
    expect(renderObjects[0].image, isNotNull);
    expect(renderObjects[0].width, 20.0);
    expect(renderObjects[1].image, isNotNull);
    expect(renderObjects[1].width, 10.0);
  });

  testWidgets('WebImage contributes semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: <Widget>[
            WebImage(
              image: _TestWebImageProvider('example.com/pic.jpg'),
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

  testWidgets('WebImage can exclude semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: WebImage(
          image: _TestWebImageProvider('example.com/pic.jpg'),
          width: 100.0,
          height: 100.0,
          excludeFromSemantics: true,
        ),
      ),
    );

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[],
    )));
    semantics.dispose();
  });

  testWidgets('WebImage invokes frameBuilder with correct wasSynchronouslyLoaded=false', (WidgetTester tester) async {
    final _TestWebImageStreamCompleter streamCompleter = _TestWebImageStreamCompleter();
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg', streamCompleter: streamCompleter);
    int? lastFrame;
    late bool lastFrameWasSync;

    await tester.pumpWidget(
      WebImage(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
          lastFrame = frame;
          lastFrameWasSync = wasSynchronouslyLoaded;
          return child;
        },
      ),
    );

    expect(lastFrame, isNull);
    expect(lastFrameWasSync, isFalse);
    expect(find.byType(RawWebImage), findsOneWidget);

    final WebImageInfo info = WebImageInfo(image10x10);
    streamCompleter.setData(imageInfo: info);
    await tester.pump();

    expect(lastFrame, 0);
    expect(lastFrameWasSync, isFalse);
  });

  testWidgets('Image invokes frameBuilder with correct wasSynchronouslyLoaded=true',
  experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(), // The test leaks by design, see [_TestImageStreamCompleter].
  (WidgetTester tester) async {
    final _TestWebImageStreamCompleter streamCompleter = _TestWebImageStreamCompleter(WebImageInfo(image10x10.cloneNode(true) as web_shim.HTMLImageElement));
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg', streamCompleter: streamCompleter);
    int? lastFrame;
    late bool lastFrameWasSync;

    await tester.pumpWidget(
      WebImage(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
          lastFrame = frame;
          lastFrameWasSync = wasSynchronouslyLoaded;
          return child;
        },
      ),
    );

    expect(lastFrame, 0);
    expect(lastFrameWasSync, isTrue);
    expect(find.byType(RawWebImage), findsOneWidget);
    streamCompleter.setData(imageInfo: WebImageInfo(image10x10.cloneNode(true) as web_shim.HTMLImageElement));
    await tester.pump();
    expect(lastFrame, 1);
    expect(lastFrameWasSync, isTrue);
  });

  testWidgets('WebImage state handles frameBuilder update', (WidgetTester tester) async {
    final _TestWebImageStreamCompleter streamCompleter = _TestWebImageStreamCompleter();
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg', streamCompleter: streamCompleter);

    await tester.pumpWidget(
      WebImage(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
          return Center(child: child);
        },
      ),
    );

    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(RawWebImage), findsOneWidget);
    final State<WebImage> state = tester.state(find.byType(WebImage));

    await tester.pumpWidget(
      WebImage(
        image: imageProvider,
        frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
          return Padding(padding: const EdgeInsets.all(1), child: child);
        },
      ),
    );

    expect(find.byType(Center), findsNothing);
    expect(find.byType(Padding), findsOneWidget);
    expect(find.byType(RawWebImage), findsOneWidget);
    expect(tester.state(find.byType(WebImage)), same(state));
  });

  testWidgets('WebImage chains the results of frameBuilder and loadingBuilder', (WidgetTester tester) async {
    final _TestWebImageStreamCompleter streamCompleter = _TestWebImageStreamCompleter();
    final _TestWebImageProvider imageProvider = _TestWebImageProvider('example.com/pic.jpg', streamCompleter: streamCompleter);

    await tester.pumpWidget(
      WebImage(
        image: imageProvider,
        excludeFromSemantics: true,
        frameBuilder: (BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded) {
          return Padding(padding: const EdgeInsets.all(1), child: child);
        },
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          return Center(child: child);
        },
      ),
    );

    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(Padding), findsOneWidget);
    expect(find.byType(RawWebImage), findsOneWidget);
    expect(tester.widget<Padding>(find.byType(Padding)).child, isA<RawWebImage>());
    await tester.pump();
    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(Padding), findsOneWidget);
    expect(find.byType(RawWebImage), findsOneWidget);
    expect(tester.widget<Center>(find.byType(Center)).child, isA<Padding>());
    expect(tester.widget<Padding>(find.byType(Padding)).child, isA<RawWebImage>());
  });

  testWidgets('Verify WebImage resets its WebImageListeners', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final _TestWebImageStreamCompleter imageStreamCompleter = _TestWebImageStreamCompleter();
    final _TestWebImageProvider imageProvider1 = _TestWebImageProvider('example.com/pic.jpg', streamCompleter: imageStreamCompleter);
    await tester.pumpWidget(
      Container(
        key: key,
        child: WebImage(
          image: imageProvider1,
        ),
      ),
    );
    // listener from resolveStreamForKey is always added.
    expect(imageStreamCompleter.listeners.length, 2);


    final _TestWebImageProvider imageProvider2 = _TestWebImageProvider('example.com/pic2.jpg');
    await tester.pumpWidget(
      Container(
        key: key,
        child: WebImage(
          image: imageProvider2,
          excludeFromSemantics: true,
        ),
      ),
      phase: EnginePhase.layout,
    );

    // only listener from resolveStreamForKey is left.
    expect(imageStreamCompleter.listeners.length, 1);
  });

  testWidgets('Verify WebImage resets its ErrorListeners', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    final _TestWebImageStreamCompleter imageStreamCompleter = _TestWebImageStreamCompleter();
    final _TestWebImageProvider imageProvider1 = _TestWebImageProvider('example.com/pic.jpg', streamCompleter: imageStreamCompleter);
    await tester.pumpWidget(
      Container(
        key: key,
        child: WebImage(
          image: imageProvider1,
          errorBuilder: (_,__,___) => Container(),
        ),
      ),
    );
    // listener from resolveStreamForKey is always added.
    expect(imageStreamCompleter.listeners.length, 2);


    final _TestWebImageProvider imageProvider2 = _TestWebImageProvider('example.com/pic2.jpg');
    await tester.pumpWidget(
      Container(
        key: key,
        child: WebImage(
          image: imageProvider2,
          excludeFromSemantics: true,
        ),
      ),
      phase: EnginePhase.layout,
    );

    // only listener from resolveStreamForKey is left.
    expect(imageStreamCompleter.listeners.length, 1);
  });

  testWidgets('Same web image provider in multiple parts of the tree, no cache room left', (WidgetTester tester) async {
    webImageCache.maximumSize = 0;

    final _TestWebImageProvider provider1 = _TestWebImageProvider('example.com/pic1.jpg');
    final _TestWebImageProvider provider2 = _TestWebImageProvider('example.com/pic2.jpg');

    expect(provider1.loadCallCount, 0);
    expect(provider2.loadCallCount, 0);
    expect(imageCache.liveImageCount, 0);

    await tester.pumpWidget(Column(
      children: <Widget>[
        WebImage(image: provider1),
        WebImage(image: provider2),
        WebImage(image: provider1),
        WebImage(image: provider1),
        WebImage(image: provider2),
      ],
    ));

    expect(webImageCache.liveImageCount, 2);
    expect(webImageCache.statusForKey(provider1.src).live, true);
    expect(webImageCache.statusForKey(provider1.src).pending, false);
    expect(webImageCache.statusForKey(provider1.src).keepAlive, false);
    expect(webImageCache.statusForKey(provider2.src).live, true);
    expect(webImageCache.statusForKey(provider2.src).pending, false);
    expect(webImageCache.statusForKey(provider2.src).keepAlive, false);

    expect(provider1.loadCallCount, 1);
    expect(provider2.loadCallCount, 1);

    provider1.complete(image10x10.cloneNode(true) as web_shim.HTMLImageElement);
    await tester.idle();

    provider2.complete(image10x10.cloneNode(true) as web_shim.HTMLImageElement);
    await tester.idle();

    expect(webImageCache.liveImageCount, 2);
    expect(webImageCache.currentSize, 0);

    await tester.pumpWidget(WebImage(image: provider2));
    await tester.idle();
    expect(webImageCache.statusForKey(provider1.src).untracked, true);
    expect(webImageCache.statusForKey(provider2.src).live, true);
    expect(webImageCache.statusForKey(provider2.src).pending, false);
    expect(webImageCache.statusForKey(provider2.src).keepAlive, false);
    expect(webImageCache.liveImageCount, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.idle();
    expect(provider1.loadCallCount, 1);
    expect(provider2.loadCallCount, 1);
    expect(webImageCache.liveImageCount, 0);
  });

  testWidgets('precacheWebImage does not hold weak ref for more than a frame',
  (WidgetTester tester) async {
    webImageCache.maximumSize = 0;
    final _TestWebImageProvider provider = _TestWebImageProvider('example.com/pic.jpg');
    late Future<void> precache;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          precache = precacheWebImage(provider, context);
          return Container();
        },
      ),
    );
    provider.complete(image10x10);
    await precache;

    // Should have ended up with only a weak ref, not in cache because cache size is 0
    expect(webImageCache.liveImageCount, 1);
    expect(webImageCache.containsKey(provider.src), false);

    final WebImageCacheStatus providerLocation = (await provider.obtainCacheStatus())!;

    expect(providerLocation, isNotNull);
    expect(providerLocation.live, true);
    expect(providerLocation.keepAlive, false);
    expect(providerLocation.pending, false);

    // Check that a second resolve of the same image is synchronous.
    final WebImageStream stream = provider.resolve();
    late bool isSync;
    final WebImageStreamListener listener = WebImageStreamListener((WebImageInfo image, bool syncCall) {
      isSync = syncCall;
    }, (bool syncCall) {});

    // Still have live ref because frame has not pumped yet.
    await tester.pump();
    expect(webImageCache.liveImageCount, 1);

    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();
    // Live ref should be gone - we didn't listen to the stream.
    expect(webImageCache.liveImageCount, 0);
    expect(webImageCache.currentSize, 0);

    stream.addListener(listener);
    expect(isSync, true); // because the stream still has the image.

    expect(webImageCache.liveImageCount, 0);
    expect(webImageCache.currentSize, 0);

    expect(provider.loadCallCount, 1);
  });

  testWidgets('precacheWebImage allows time to take over weak reference',
  experimentalLeakTesting: LeakTesting.settings.withIgnoredAll(), // The test leaks by design, see [_TestImageStreamCompleter].
  (WidgetTester tester) async {
    final _TestWebImageProvider provider = _TestWebImageProvider('example.com/pic.jpg');
    late Future<void> precache;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          precache = precacheWebImage(provider, context);
          return Container();
        },
      ),
    );
    provider.complete(image10x10);
    await precache;

    // Should have ended up in the cache and have a weak reference.
    expect(webImageCache.liveImageCount, 1);
    expect(webImageCache.currentSize, 1);
    expect(webImageCache.containsKey(provider.src), true);

    // Check that a second resolve of the same image is synchronous.
    final WebImageStream stream = provider.resolve();
    late bool isSync;
    final WebImageStreamListener listener = WebImageStreamListener((WebImageInfo image, bool syncCall) { isSync = syncCall; }, (bool syncCall) {});

    // Should have ended up in the cache and still have a weak reference.
    expect(webImageCache.liveImageCount, 1);
    expect(webImageCache.currentSize, 1);
    expect(webImageCache.containsKey(provider.src), true);

    stream.addListener(listener);
    expect(isSync, true);

    expect(webImageCache.liveImageCount, 1);
    expect(webImageCache.currentSize, 1);
    expect(webImageCache.containsKey(provider.src), true);

    SchedulerBinding.instance.scheduleFrame();
    await tester.pump();

    expect(webImageCache.liveImageCount, 1);
    expect(webImageCache.currentSize, 1);
    expect(webImageCache.containsKey(provider.src), true);
    stream.removeListener(listener);

    expect(webImageCache.liveImageCount, 0);
    expect(webImageCache.currentSize, 1);
    expect(webImageCache.containsKey(provider.src), true);
    expect(provider.loadCallCount, 1);
  });

  testWidgets('evict an image during precache', (WidgetTester tester) async {
    // This test checks that the live image tracking does not hold on to a
    // pending image that will never complete because it has been evicted from
    // the cache.
    // The scenario may arise in a test harness that is trying to load real
    // images using `tester.runAsync()`, and wants to make sure that widgets
    // under test have not also tried to resolve the image in a FakeAsync zone.
    // The image loaded in the FakeAsync zone will never complete, and the
    // runAsync call wants to make sure it gets a load attempt from the correct
    // zone.
    final _TestWebImageProvider provider = _TestWebImageProvider('example.com/pic.jpg');

    await tester.runAsync(() async {
      final List<Future<void>> futures = <Future<void>>[];
      await tester.pumpWidget(Builder(builder: (BuildContext context) {
        futures.add(precacheWebImage(provider, context));
        webImageCache.evict(provider.src);
        futures.add(precacheWebImage(provider, context));
        provider.complete(image10x10);
        return const SizedBox.expand();
      }));
      await Future.wait<void>(futures);
      expect(webImageCache.statusForKey(provider.src).keepAlive, true);
      expect(webImageCache.statusForKey(provider.src).live, true);

      // Schedule a frame to get precacheWebImage to stop listening.
      SchedulerBinding.instance.scheduleFrame();
      await tester.pump();
      expect(webImageCache.statusForKey(provider.src).keepAlive, true);
      expect(webImageCache.statusForKey(provider.src).live, false);

      webImageCache.clear();
    });
  });

  testWidgets('errorBuilder - fails on load', (WidgetTester tester) async {
    final UniqueKey errorKey = UniqueKey();
    late Object caughtException;
    await tester.pumpWidget(
      WebImage(
        image: _FailingWebImageProvider('example.com/pic.jpg', failOnLoad: true, throws: 'threw', image: image10x10),
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          caughtException = error;
          return SizedBox.expand(key: errorKey);
        },
      ),
    );

    await tester.pump();

    expect(find.byKey(errorKey), findsOneWidget);
    expect(caughtException.toString(), 'threw');
    expect(tester.takeException(), isNull);
  });

  testWidgets('no errorBuilder - failure reported to FlutterError', (WidgetTester tester) async {
    await tester.pumpWidget(
      WebImage(
        image: _FailingWebImageProvider('example.com/pic.jpg', failOnLoad: true, throws: 'threw', image: image10x10),
      ),
    );

    await tester.pump();

    expect(tester.takeException(), 'threw');
  });
}

web_shim.HTMLImageElement createTestWebImage(
    {required int width, required int height}) {
  final web_shim.HTMLCanvasElement canvas =
      web_shim.document.createElement('canvas') as web_shim.HTMLCanvasElement;
  canvas
    ..width = width
    ..height = height;
  final web_shim.HTMLImageElement image =
      web_shim.document.createElement('img') as web_shim.HTMLImageElement;
  image.src = canvas.toDataURL();
  return image;
}

class _TestWebImageProvider extends WebImageProviderImpl {
  _TestWebImageProvider(super.src, {WebImageStreamCompleter? streamCompleter}) {
    _streamCompleter = streamCompleter ??
        OneFrameWebImageStreamCompleter(
          SynchronousFuture<bool>(false),
          _imageCompleter.future,
        );
  }

  final Completer<WebImageInfo> _imageCompleter = Completer<WebImageInfo>();
  late WebImageStreamCompleter _streamCompleter;

  bool get loadCalled => _loadCallCount > 0;
  int get loadCallCount => _loadCallCount;
  int _loadCallCount = 0;

  @override
  void resolveStreamForKey(
      WebImageStream stream, String key, ImageErrorListener handleError) {
    super.resolveStreamForKey(stream, key, handleError);
  }

  @override
  WebImageStreamCompleter loadImage(String key) {
    _loadCallCount += 1;
    return _streamCompleter;
  }

  void complete(web_shim.HTMLImageElement image) {
    _imageCompleter.complete(WebImageInfo(image));
  }

  void fail(Object exception, StackTrace? stackTrace) {
    _imageCompleter.completeError(exception, stackTrace);
  }
}

/// An [WebImageStreamCompleter] that gives access to the added listeners.
///
/// Such an access to listeners is hacky,
/// because it breaks encapsulation by allowing to invoke listeners without
/// taking care about lifecycle of the created images, that may result in not disposed images.
///
/// That's why some tests that use it
/// are opted out from leak tracking.
class _TestWebImageStreamCompleter extends WebImageStreamCompleter {
  _TestWebImageStreamCompleter([this._currentImage]);

  WebImageInfo? _currentImage;
  final Set<WebImageStreamListener> listeners = <WebImageStreamListener>{};

  @override
  void addListener(WebImageStreamListener listener) {
    listeners.add(listener);
    if (_currentImage != null) {
      listener.onImage(_currentImage!.clone(), true);
    }
  }

  @override
  void removeListener(WebImageStreamListener listener) {
    listeners.remove(listener);
  }

  void setData({
    WebImageInfo? imageInfo,
  }) {
    if (imageInfo != null) {
      _currentImage = imageInfo;
    }
    final List<WebImageStreamListener> localListeners = listeners.toList();
    for (final WebImageStreamListener listener in localListeners) {
      if (imageInfo != null) {
        listener.onImage(imageInfo.clone(), false);
      }
    }
  }

  void setError({
    required Object exception,
    StackTrace? stackTrace,
  }) {
    final List<WebImageStreamListener> localListeners = listeners.toList();
    for (final WebImageStreamListener listener in localListeners) {
      listener.onError?.call(exception, stackTrace);
    }
  }

  void dispose() {
    final List<WebImageStreamListener> listenersCopy = listeners.toList();
    listenersCopy.forEach(removeListener);
  }
}

class _FailingWebImageProvider extends WebImageProviderImpl {
  _FailingWebImageProvider(super.src, {
    this.failOnLoad = false,
    required this.throws,
    required this.image,
  }) : assert(failOnLoad);

  final bool failOnLoad;
  final Object throws;
  final web_shim.HTMLImageElement image;

  @override
  WebImageStreamCompleter loadImage(String src) {
    if (failOnLoad) {
      throw throws;
    }
    return OneFrameWebImageStreamCompleter(
      Future<bool>.value(false),
      Future<WebImageInfo>.value(
        WebImageInfo(
          image,
        ),
      ),
    );
  }
}
