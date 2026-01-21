// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide NetworkImage;
import 'package:flutter/rendering.dart';
import 'package:flutter/src/painting/_network_image_web.dart' hide NetworkImage;
import 'package:flutter/src/painting/_web_image_info_web.dart';
import 'package:flutter/src/web.dart' as web_shim;
import 'package:flutter/src/widgets/_web_image_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import '../image_data.dart';
import '../widgets/web_platform_view_registry_utils.dart';
import '_test_http_request.dart';

late final ui.Image testImage;

void runTests() {
  _TestBinding.ensureInitialized();
  late FakePlatformViewRegistry fakePlatformViewRegistry;

  setUpAll(() async {
    testImage = await createTestImage();
    fakePlatformViewRegistry = FakePlatformViewRegistry();
    ui_web.debugOverridePlatformViewRegistry(fakePlatformViewRegistry);
  });

  tearDown(() {
    debugRestoreHttpRequestFactory();
    debugRestoreImgElementFactory();
    _TestBinding.instance.overrideCodec = null;
  });

  tearDownAll(() {
    ui_web.debugOverridePlatformViewRegistry(null);
  });

  testWidgets('loads an image from the network with headers', (WidgetTester tester) async {
    final testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    const headers = <String, String>{'flutter': 'flutter', 'second': 'second'};

    final image = Image.network(_uniqueUrl(tester.testDescription), headers: headers);

    await tester.pumpWidget(image);

    assert(mapEquals(testHttpRequest.responseHeaders, headers), true);
  });

  testWidgets('loads an image from the network with unsuccessful HTTP code', (
    WidgetTester tester,
  ) async {
    final testHttpRequest = TestHttpRequest()
      ..status = 404
      ..mockEvent = MockEvent('error', web.Event('test error'));

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    const headers = <String, String>{'flutter': 'flutter', 'second': 'second'};

    final image = Image.network(_uniqueUrl(tester.testDescription), headers: headers);

    await tester.pumpWidget(image);
    expect(
      tester.takeException(),
      isA<NetworkImageLoadException>().having(
        (NetworkImageLoadException e) => e.statusCode,
        'status code',
        404,
      ),
    );
  });

  testWidgets('loads an image from the network with empty response', (WidgetTester tester) async {
    final testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('successful load'))
      ..response = (Uint8List.fromList(<int>[])).buffer;

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    const headers = <String, String>{'flutter': 'flutter', 'second': 'second'};

    final String url = _uniqueUrl(tester.testDescription);
    final image = Image.network(url, headers: headers);

    await tester.pumpWidget(image);
    expect(tester.takeException().toString(), 'HTTP request failed, statusCode: 200, $url');
  });

  testWidgets('When strategy is default, emits an error if the image is cross-origin', (
    WidgetTester tester,
  ) async {
    final failingRequest = TestHttpRequest()
      ..status = 500
      ..mockEvent = MockEvent('load', web.Event('bytes inaccessible'))
      ..response = (Uint8List.fromList(<int>[])).buffer;

    httpRequestFactory = () {
      return failingRequest.getMock() as web_shim.XMLHttpRequest;
    };

    imgElementFactory = () {
      throw UnimplementedError();
    };

    final networkImage = NetworkImage(_uniqueUrl(tester.testDescription));
    ImageInfo? imageInfo;
    Object? recordedError;
    Completer<void>? imageCompleter;
    await tester.runAsync(() async {
      imageCompleter = Completer<void>();
      final ImageStream stream = networkImage.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (ImageInfo info, bool isSync) {
            imageInfo = info;
            imageCompleter!.complete();
          },
          onError: (Object error, StackTrace? stackTrace) {
            recordedError = error;
            imageCompleter!.complete();
          },
        ),
      );
    });
    await tester.runAsync(() async {
      await imageCompleter!.future;
    });
    expect(recordedError, isNotNull);
    expect(imageInfo, isNull);
  });

  testWidgets('When strategy is .fallback, emits a WebImageInfo if the image is cross-origin', (
    WidgetTester tester,
  ) async {
    final failingRequest = TestHttpRequest()
      ..status = 500
      ..mockEvent = MockEvent('load', web.Event('bytes inaccessible'))
      ..response = (Uint8List.fromList(<int>[])).buffer;
    final testImg = TestImgElement();

    httpRequestFactory = () {
      return failingRequest.getMock() as web_shim.XMLHttpRequest;
    };

    imgElementFactory = () {
      return testImg.getMock() as web_shim.HTMLImageElement;
    };

    final String url = _uniqueUrl(tester.testDescription);
    final networkImage = NetworkImage(url, webHtmlElementStrategy: WebHtmlElementStrategy.fallback);
    ImageInfo? imageInfo;
    Object? recordedError;
    Completer<void>? imageCompleter;
    await tester.runAsync(() async {
      imageCompleter = Completer<void>();
      final ImageStream stream = networkImage.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (ImageInfo info, bool isSync) {
            imageInfo = info;
            imageCompleter!.complete();
          },
          onError: (Object error, StackTrace? stackTrace) {
            recordedError = error;
            imageCompleter!.complete();
          },
        ),
      );
    });
    await tester.runAsync(() async {
      testImg.decodeSuccess();
      await imageCompleter!.future;
    });
    expect(recordedError, isNull);
    expect(imageInfo, isA<WebImageInfo>());

    final webImageInfo = imageInfo! as WebImageInfo;
    expect(webImageInfo.htmlImage.src, equals(url));
  });

  testWidgets(
    'When strategy is .fallback, emits an error if the image is cross-origin but fails to decode',
    (WidgetTester tester) async {
      final failingRequest = TestHttpRequest()
        ..status = 500
        ..mockEvent = MockEvent('load', web.Event('bytes inaccessible'))
        ..response = (Uint8List.fromList(<int>[])).buffer;
      final testImg = TestImgElement();

      httpRequestFactory = () {
        return failingRequest.getMock() as web_shim.XMLHttpRequest;
      };

      imgElementFactory = () {
        return testImg.getMock() as web_shim.HTMLImageElement;
      };

      final networkImage = NetworkImage(
        _uniqueUrl(tester.testDescription),
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      );
      ImageInfo? imageInfo;
      Object? recordedError;
      Completer<void>? imageCompleter;
      await tester.runAsync(() async {
        imageCompleter = Completer<void>();
        final ImageStream stream = networkImage.resolve(ImageConfiguration.empty);
        stream.addListener(
          ImageStreamListener(
            (ImageInfo info, bool isSync) {
              imageInfo = info;
              imageCompleter!.complete();
            },
            onError: (Object error, StackTrace? stackTrace) {
              recordedError = error;
              imageCompleter!.complete();
            },
          ),
        );
      });
      await tester.runAsync(() async {
        testImg.decodeFailure();
        await imageCompleter!.future;
      });
      expect(recordedError, isNotNull);
      expect(imageInfo, isNull);
    },
  );

  testWidgets('When strategy is .prefer, emits an WebImageInfo if the image is same-origin', (
    WidgetTester tester,
  ) async {
    final testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;
    final testImg = TestImgElement();

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    imgElementFactory = () {
      return testImg.getMock() as web_shim.HTMLImageElement;
    };

    final String url = _uniqueUrl(tester.testDescription);
    final networkImage = NetworkImage(url, webHtmlElementStrategy: WebHtmlElementStrategy.prefer);
    ImageInfo? imageInfo;
    Object? recordedError;
    Completer<void>? imageCompleter;
    await tester.runAsync(() async {
      imageCompleter = Completer<void>();
      final ImageStream stream = networkImage.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (ImageInfo info, bool isSync) {
            imageInfo = info;
            imageCompleter!.complete();
          },
          onError: (Object error, StackTrace? stackTrace) {
            recordedError = error;
            imageCompleter!.complete();
          },
        ),
      );
    });
    await tester.runAsync(() async {
      testImg.decodeSuccess();
      await imageCompleter!.future;
    });
    expect(recordedError, isNull);
    expect(imageInfo, isA<WebImageInfo>());

    final webImageInfo = imageInfo! as WebImageInfo;
    expect(webImageInfo.htmlImage.src, equals(url));
  });

  testWidgets('When strategy is .prefer, emits a normal image if headers is not null', (
    WidgetTester tester,
  ) async {
    final testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;
    final testImg = TestImgElement();

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    imgElementFactory = () {
      return testImg.getMock() as web_shim.HTMLImageElement;
    };

    final networkImage = NetworkImage(
      _uniqueUrl(tester.testDescription),
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      headers: const <String, String>{'flutter': 'flutter', 'second': 'second'},
    );
    ImageInfo? imageInfo;
    Object? recordedError;
    Completer<void>? imageCompleter;
    await tester.runAsync(() async {
      imageCompleter = Completer<void>();
      final ImageStream stream = networkImage.resolve(ImageConfiguration.empty);
      stream.addListener(
        ImageStreamListener(
          (ImageInfo info, bool isSync) {
            imageInfo = info;
            imageCompleter!.complete();
          },
          onError: (Object error, StackTrace? stackTrace) {
            recordedError = error;
            imageCompleter!.complete();
          },
        ),
      );
    });
    await tester.runAsync(() async {
      testImg.decodeSuccess();
      await imageCompleter!.future;
    });
    expect(recordedError, isNull);
    expect(imageInfo, isNotNull);
    expect(imageInfo, isNot(isA<WebImageInfo>()));
  });

  testWidgets('Image renders an image using a Platform View if the image info is WebImageInfo', (
    WidgetTester tester,
  ) async {
    final testImg = TestImgElement();

    final streamCompleter = _TestImageStreamCompleter();
    final imageProvider = _TestImageProvider(streamCompleter: streamCompleter);

    await tester.pumpWidget(Image(image: imageProvider));

    // Before getting a WebImageInfo, the Image resolves to a RawImage.
    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byType(RawWebImage), findsNothing);
    expect(find.byType(PlatformViewLink), findsNothing);
    streamCompleter.setData(
      imageInfo: WebImageInfo(testImg.getMock() as web_shim.HTMLImageElement),
    );
    await tester.pump();
    expect(find.byType(RawImage), findsNothing);
    // After getting a WebImageInfo, the Image uses a Platform View to render.
    expect(find.byType(RawWebImage), findsOneWidget);
    expect(find.byType(PlatformViewLink), findsOneWidget);
  });

  testWidgets('Does not crash when disposed between frames', (WidgetTester tester) async {
    final testHttpRequest = TestHttpRequest()
      ..status = 200
      ..mockEvent = MockEvent('load', web.Event('test error'))
      ..response = (Uint8List.fromList(kTransparentImage)).buffer;

    httpRequestFactory = () {
      return testHttpRequest.getMock() as web_shim.XMLHttpRequest;
    };

    final secondFrameLock = Completer<void>();

    // Override the codec so that the 2nd frame is delayed.
    _TestBinding.instance.overrideCodec = _TwoFrameCodec(
      onFrame: (int frameNumber) async {
        if (frameNumber == 1) {
          await secondFrameLock.future;
        }
      },
    );

    // Mount the image, displaying the 1st frame.
    await tester.pumpWidget(Image.network(_uniqueUrl(tester.testDescription)));
    // Clear the image cache, so that the image completer will be disposed as
    // soon as the image is unmounted.
    imageCache.clear();
    // The image is unmounted, disposing `MultiFrameImageStreamCompleter`.
    await tester.pumpWidget(Container());
    // Finish decoding the 2nd frame. If the image completer has been properly
    // disposed, nothing will happen; otherwise the
    // `MultiFrameImageStreamCompleter` is still alive and will call
    // of `_ForwardingImageStreamCompleter.setImage` and causes a crash.
    secondFrameLock.complete();
    expect(imageCache.currentSize, 0);
    // The test passes if there are no crashes.
  });

  testWidgets('Can handle gestures when using a Platform View', (WidgetTester tester) async {
    final testImg = TestImgElement();
    // Give the test img naturalHeight and naturalWidth so it can be hit by a
    // tap gesture.
    testImg
      ..src = _uniqueUrl(tester.testDescription)
      ..naturalWidth = 10
      ..naturalHeight = 10;

    final streamCompleter = _TestImageStreamCompleter();
    final imageProvider = _TestImageProvider(streamCompleter: streamCompleter);
    final Key containerKey = UniqueKey();
    var taps = 0;

    await tester.pumpWidget(
      GestureDetector(
        onTap: () => taps++,
        child: Container(
          key: containerKey,
          width: 200,
          height: 200,
          // Add a color to make it a visible container. This ensures that
          // GestureDetector's default hit test behavior works.
          color: const Color(0xFF00FF00),
          child: Image(image: imageProvider),
        ),
      ),
    );
    streamCompleter.setData(
      imageInfo: WebImageInfo(testImg.getMock() as web_shim.HTMLImageElement),
    );
    await tester.pumpAndSettle();
    expect(taps, isZero);
    await tester.tap(find.byKey(containerKey), warnIfMissed: false);
    expect(taps, 1);
  });

  testWidgets('Creates an <img> with width and height set', (WidgetTester tester) async {
    final testImg = TestImgElement();
    testImg.src = _uniqueUrl(tester.testDescription);

    final streamCompleter = _TestImageStreamCompleter();
    final imageProvider = _TestImageProvider(streamCompleter: streamCompleter);

    await tester.pumpWidget(Image(image: imageProvider));
    streamCompleter.setData(
      imageInfo: WebImageInfo(testImg.getMock() as web_shim.HTMLImageElement),
    );
    await tester.pumpAndSettle();
    final FakePlatformView imgElementPlatformView = fakePlatformViewRegistry.views.single;
    expect(imgElementPlatformView.htmlElement, isA<web.HTMLImageElement>());
    final imgElement = imgElementPlatformView.htmlElement as web.HTMLImageElement;
    expect(imgElement.src, testImg.src);
    expect(imgElement.style.width, '100%');
    expect(imgElement.style.height, '100%');
  });

  testWidgets('Creates an <img> with pointer-events: none', (WidgetTester tester) async {
    final testImg = TestImgElement();
    testImg.src = _uniqueUrl(tester.testDescription);

    final streamCompleter = _TestImageStreamCompleter();
    final imageProvider = _TestImageProvider(streamCompleter: streamCompleter);

    await tester.pumpWidget(Image(image: imageProvider));
    streamCompleter.setData(
      imageInfo: WebImageInfo(testImg.getMock() as web_shim.HTMLImageElement),
    );
    await tester.pumpAndSettle();
    final FakePlatformView imgElementPlatformView = fakePlatformViewRegistry.views.single;
    expect(imgElementPlatformView.htmlElement, isA<web.HTMLImageElement>());
    final imgElement = imgElementPlatformView.htmlElement as web.HTMLImageElement;
    expect(imgElement.style.pointerEvents, 'none');
  });

  group('RenderWebImage', () {
    testWidgets('BoxFit.contain centers and sizes the image correctly', (
      WidgetTester tester,
    ) async {
      final testImg = TestImgElement();
      testImg
        ..src = _uniqueUrl(tester.testDescription)
        ..naturalWidth = 200
        ..naturalHeight = 100;
      final image = WebImageInfo(testImg.getMock() as web_shim.HTMLImageElement);
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: RawWebImage(image: image, fit: BoxFit.contain),
          ),
        ),
      );

      final RenderWebImage renderWebImage = tester.renderObject(find.byType(RawWebImage));
      expect(renderWebImage.size, const Size(300, 300));

      final RenderBox child = renderWebImage.child!;
      expect(child.size, const Size(300, 150));

      final parentData = child.parentData! as BoxParentData;
      expect(parentData.offset, const Offset(0, 75));
    });

    testWidgets('BoxFit.cover sizes and clips the image correctly', (WidgetTester tester) async {
      final testImg = TestImgElement();
      testImg
        ..src = _uniqueUrl(tester.testDescription)
        ..naturalWidth = 200
        ..naturalHeight = 100;
      final image = WebImageInfo(testImg.getMock() as web_shim.HTMLImageElement);
      await tester.pumpWidget(
        RepaintBoundary(
          child: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: RawWebImage(image: image, fit: BoxFit.cover, alignment: Alignment.bottomRight),
            ),
          ),
        ),
      );

      // Pump and settle so the layer tree updates.
      await tester.pumpAndSettle();

      final RenderWebImage renderWebImage = tester.renderObject(find.byType(RawWebImage));
      expect(renderWebImage.size, const Size(300, 300));

      final RenderBox child = renderWebImage.child!;
      expect(child.size, const Size(600, 300));

      final parentData = child.parentData! as BoxParentData;
      expect(parentData.offset, const Offset(-300, 0));

      expect(tester.layers, contains(isA<ClipRectLayer>()));
      final ClipRectLayer clipLayer = tester.layers.whereType<ClipRectLayer>().first;
      expect(clipLayer.clipRect, const Rect.fromLTWH(250, 150, 300, 300));
    });

    testWidgets('BoxFit.none does not scale and clips when necessary', (WidgetTester tester) async {
      final testImg = TestImgElement();
      testImg
        ..src = _uniqueUrl(tester.testDescription)
        ..naturalWidth = 200
        ..naturalHeight = 100;
      final image = WebImageInfo(testImg.getMock() as web_shim.HTMLImageElement);
      await tester.pumpWidget(
        RepaintBoundary(
          child: Center(
            child: SizedBox(
              width: 100,
              height: 50,
              child: RawWebImage(image: image, fit: BoxFit.none, alignment: Alignment.topLeft),
            ),
          ),
        ),
      );

      // Pump and settle so the layer tree updates.
      await tester.pumpAndSettle();

      final RenderWebImage renderWebImage = tester.renderObject(find.byType(RawWebImage));
      expect(renderWebImage.size, const Size(100, 50));

      final RenderBox child = renderWebImage.child!;
      expect(child.size, const Size(200, 100));

      final parentData = child.parentData! as BoxParentData;
      expect(parentData.offset, Offset.zero);

      expect(tester.layers, contains(isA<ClipRectLayer>()));
    });

    testWidgets('Alignment works correctly with various BoxFit values', (
      WidgetTester tester,
    ) async {
      final testImg = TestImgElement();
      testImg
        ..src = _uniqueUrl(tester.testDescription)
        ..naturalWidth = 200
        ..naturalHeight = 100;
      final image = WebImageInfo(testImg.getMock() as web_shim.HTMLImageElement);
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: RawWebImage(image: image, fit: BoxFit.contain, alignment: Alignment.topLeft),
          ),
        ),
      );

      RenderWebImage renderWebImage = tester.renderObject(find.byType(RawWebImage));
      RenderBox child = renderWebImage.child!;
      var parentData = child.parentData! as BoxParentData;
      expect(parentData.offset, Offset.zero);

      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: RawWebImage(image: image, fit: BoxFit.contain, alignment: Alignment.bottomRight),
          ),
        ),
      );

      renderWebImage = tester.renderObject(find.byType(RawWebImage));
      child = renderWebImage.child!;
      parentData = child.parentData! as BoxParentData;
      expect(parentData.offset, const Offset(0, 150));
    });
  });
}

// Generates a unique URL based on the provided key, preventing unintended caching.
//
// Requests within this file must each have a unique URL; otherwise, responses
// may be cached inadvertently. This often leads to subtle, frustrating bugs
// that are difficult to debug.
//
// Test cases that only contain one request each can use
// `tester.testDescription` as the key.
String _uniqueUrl(Object key) {
  return 'https://www.example.com/images/frame_${identityHashCode(key)}.png';
}

// A normal `AutomatedTestWidgetsFlutterBinding` except that it allows certain
// overrides.
class _TestBinding extends AutomatedTestWidgetsFlutterBinding {
  static late final _TestBinding instance;
  @override
  void initInstances() {
    super.initInstances();
    instance = this;
  }

  // If this value is not null, then [instantiateImageCodecWithSize] always
  // return this codec instead of decoding the image stream.
  ui.Codec? overrideCodec;

  @override
  Future<ui.Codec> instantiateImageCodecWithSize(
    ui.ImmutableBuffer buffer, {
    ui.TargetImageSizeCallback? getTargetSize,
  }) {
    if (overrideCodec != null) {
      return Future<ui.Codec>.value(overrideCodec);
    }
    return super.instantiateImageCodecWithSize(buffer, getTargetSize: getTargetSize);
  }

  static _TestBinding ensureInitialized() {
    _TestBinding();
    return _TestBinding.instance;
  }
}

class _TestImageProvider extends ImageProvider<Object> {
  _TestImageProvider({required ImageStreamCompleter streamCompleter}) {
    _streamCompleter = streamCompleter;
  }

  final Completer<ImageInfo> _completer = Completer<ImageInfo>();
  late ImageStreamCompleter _streamCompleter;

  @override
  Future<Object> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_TestImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(Object key, ImageDecoderCallback decode) {
    return _streamCompleter;
  }

  void complete(web_shim.HTMLImageElement image) {
    _completer.complete(WebImageInfo(image));
  }

  void fail(Object exception, StackTrace? stackTrace) {
    _completer.completeError(exception, stackTrace);
  }

  @override
  String toString() => '${describeIdentity(this)}()';
}

/// An [ImageStreamCompleter] that gives access to the added listeners.
///
/// Such an access to listeners is hacky,
/// because it breaks encapsulation by allowing to invoke listeners without
/// taking care about lifecycle of the created images, that may result in not disposed images.
///
/// That's why some tests that use it are opted out from leak tracking.
class _TestImageStreamCompleter extends ImageStreamCompleter {
  _TestImageStreamCompleter();

  ImageInfo? _currentImage;
  final Set<ImageStreamListener> listeners = <ImageStreamListener>{};

  @override
  void addListener(ImageStreamListener listener) {
    listeners.add(listener);
    if (_currentImage != null) {
      listener.onImage(_currentImage!.clone(), true);
    }
  }

  @override
  void removeListener(ImageStreamListener listener) {
    listeners.remove(listener);
  }

  void setData({ImageInfo? imageInfo, ImageChunkEvent? chunkEvent}) {
    if (imageInfo != null) {
      _currentImage?.dispose();
      _currentImage = imageInfo;
    }
    final List<ImageStreamListener> localListeners = listeners.toList();
    for (final listener in localListeners) {
      if (imageInfo != null) {
        listener.onImage(imageInfo.clone(), false);
      }
      if (chunkEvent != null && listener.onChunk != null) {
        listener.onChunk!(chunkEvent);
      }
    }
  }

  void setError({required Object exception, StackTrace? stackTrace}) {
    final List<ImageStreamListener> localListeners = listeners.toList();
    for (final listener in localListeners) {
      listener.onError?.call(exception, stackTrace);
    }
  }

  void dispose() {
    final List<ImageStreamListener> listenersCopy = listeners.toList();
    listenersCopy.forEach(removeListener);
  }
}

typedef _OnFrameCallback = Future<void> Function(int frameNumber);

// An image with two frames (_TestFrameInfo).
//
// This codec calls and awaits on the `onFrame` callback before returning each
// frame, whose argument `frameNumber` is a zero-based index.
class _TwoFrameCodec implements ui.Codec {
  _TwoFrameCodec({required this.onFrame});

  final _OnFrameCallback onFrame;
  int _frameNumber = -1;

  @override
  int get frameCount => 2;

  @override
  int get repetitionCount => 0;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    _frameNumber += 1;
    await onFrame(_frameNumber);
    return _TestFrameInfo(testImage);
  }

  @override
  void dispose() {}
}

class _TestFrameInfo implements ui.FrameInfo {
  _TestFrameInfo(this.image);

  @override
  final Duration duration = Duration.zero;

  @override
  final ui.Image image;
}
