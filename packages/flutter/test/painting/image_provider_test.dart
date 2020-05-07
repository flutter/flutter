// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../rendering/rendering_tester.dart';
import 'image_data.dart';
import 'mocks_for_image_cache.dart';

void main() {

  final DecoderCallback basicDecoder = (Uint8List bytes, {int cacheWidth, int cacheHeight}) {
    return PaintingBinding.instance.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
  };

  setUpAll(() {
    TestRenderingFlutterBinding(); // initializes the imageCache
  });

  FlutterExceptionHandler oldError;
  setUp(() {
    oldError = FlutterError.onError;
  });

  tearDown(() {
    FlutterError.onError = oldError;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  group('ImageProvider', () {
    group('Image cache', () {
      tearDown(() {
        imageCache.clear();
      });

      test('AssetImageProvider - evicts on failure to load', () async {
        final Completer<FlutterError> error = Completer<FlutterError>();
        FlutterError.onError = (FlutterErrorDetails details) {
          error.complete(details.exception as FlutterError);
        };

        const ImageProvider provider = ExactAssetImage('does-not-exist');
        final Object key = await provider.obtainKey(ImageConfiguration.empty);
        expect(imageCache.statusForKey(provider).untracked, true);
        expect(imageCache.pendingImageCount, 0);

        provider.resolve(ImageConfiguration.empty);

        expect(imageCache.statusForKey(key).pending, true);
        expect(imageCache.pendingImageCount, 1);

        await error.future;

        expect(imageCache.statusForKey(provider).untracked, true);
        expect(imageCache.pendingImageCount, 0);
      }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56314

      test('AssetImageProvider - evicts on null load', () async {
        final Completer<StateError> error = Completer<StateError>();
        FlutterError.onError = (FlutterErrorDetails details) {
          error.complete(details.exception as StateError);
        };

        final ImageProvider provider = ExactAssetImage('does-not-exist', bundle: TestAssetBundle());
        final Object key = await provider.obtainKey(ImageConfiguration.empty);
        expect(imageCache.statusForKey(provider).untracked, true);
        expect(imageCache.pendingImageCount, 0);

        provider.resolve(ImageConfiguration.empty);

        expect(imageCache.statusForKey(key).pending, true);
        expect(imageCache.pendingImageCount, 1);

        await error.future;

        expect(imageCache.statusForKey(provider).untracked, true);
        expect(imageCache.pendingImageCount, 0);
      });

      test('ImageProvider can evict images', () async {
        final Uint8List bytes = Uint8List.fromList(kTransparentImage);
        final MemoryImage imageProvider = MemoryImage(bytes);
        final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
        final Completer<void> completer = Completer<void>();
        stream.addListener(ImageStreamListener((ImageInfo info, bool syncCall) => completer.complete()));
        await completer.future;

        expect(imageCache.currentSize, 1);
        expect(await MemoryImage(bytes).evict(), true);
        expect(imageCache.currentSize, 0);
      });

      test('ImageProvider.evict respects the provided ImageCache', () async {
        final ImageCache otherCache = ImageCache();
        final Uint8List bytes = Uint8List.fromList(kTransparentImage);
        final MemoryImage imageProvider = MemoryImage(bytes);
        final ImageStreamCompleter cacheStream = otherCache.putIfAbsent(
          imageProvider, () => imageProvider.load(imageProvider, basicDecoder),
        );
        final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
        final Completer<void> completer = Completer<void>();
        final Completer<void> cacheCompleter = Completer<void>();
        stream.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
          completer.complete();
        }));
        cacheStream.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
          cacheCompleter.complete();
        }));
        await Future.wait(<Future<void>>[completer.future, cacheCompleter.future]);

        expect(otherCache.currentSize, 1);
        expect(imageCache.currentSize, 1);
        expect(await imageProvider.evict(cache: otherCache), true);
        expect(otherCache.currentSize, 0);
        expect(imageCache.currentSize, 1);
      });

      test('ImageProvider errors can always be caught', () async {
        final ErrorImageProvider imageProvider = ErrorImageProvider();
        final Completer<bool> caughtError = Completer<bool>();
        FlutterError.onError = (FlutterErrorDetails details) {
          caughtError.complete(false);
        };
        final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
        stream.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
          caughtError.complete(false);
        }, onError: (dynamic error, StackTrace stackTrace) {
          caughtError.complete(true);
        }));
        expect(await caughtError.future, true);
      });
    });

    test('obtainKey errors will be caught', () async {
      final ImageProvider imageProvider = ObtainKeyErrorImageProvider();
      final Completer<bool> caughtError = Completer<bool>();
      FlutterError.onError = (FlutterErrorDetails details) {
        caughtError.complete(false);
      };
      final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
      stream.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
        caughtError.complete(false);
      }, onError: (dynamic error, StackTrace stackTrace) {
        caughtError.complete(true);
      }));
      expect(await caughtError.future, true);
    });

    test('obtainKey errors will be caught - check location', () async {
      final ImageProvider imageProvider = ObtainKeyErrorImageProvider();
      final Completer<bool> caughtError = Completer<bool>();
      FlutterError.onError = (FlutterErrorDetails details) {
        caughtError.complete(true);
      };
      await imageProvider.obtainCacheStatus(configuration: ImageConfiguration.empty);

      expect(await caughtError.future, true);
    });

    test('resolve sync errors will be caught', () async {
      bool uncaught = false;
      final Zone testZone = Zone.current.fork(specification: ZoneSpecification(
        handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
          uncaught = true;
        },
      ));
      await testZone.run(() async {
        final ImageProvider imageProvider = LoadErrorImageProvider();
        final Completer<bool> caughtError = Completer<bool>();
        FlutterError.onError = (FlutterErrorDetails details) {
          throw Error();
        };
        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
        result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
        }, onError: (dynamic error, StackTrace stackTrace) {
          caughtError.complete(true);
        }));
        expect(await caughtError.future, true);
      });
      expect(uncaught, false);
    });

    test('resolve errors in the completer will be caught', () async {
      bool uncaught = false;
      final Zone testZone = Zone.current.fork(specification: ZoneSpecification(
        handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
          uncaught = true;
        },
      ));
      await testZone.run(() async {
        final ImageProvider imageProvider = LoadErrorCompleterImageProvider();
        final Completer<bool> caughtError = Completer<bool>();
        FlutterError.onError = (FlutterErrorDetails details) {
          throw Error();
        };
        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
        result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
        }, onError: (dynamic error, StackTrace stackTrace) {
          caughtError.complete(true);
        }));
        expect(await caughtError.future, true);
      });
      expect(uncaught, false);
    });

    test('File image with empty file throws expected error and evicts from cache', () async {
      final Completer<StateError> error = Completer<StateError>();
      FlutterError.onError = (FlutterErrorDetails details) {
        error.complete(details.exception as StateError);
      };
      final MemoryFileSystem fs = MemoryFileSystem();
      final File file = fs.file('/empty.png')..createSync(recursive: true);
      final FileImage provider = FileImage(file);

      expect(imageCache.statusForKey(provider).untracked, true);
      expect(imageCache.pendingImageCount, 0);

      provider.resolve(ImageConfiguration.empty);

      expect(imageCache.statusForKey(provider).pending, true);
      expect(imageCache.pendingImageCount, 1);

      expect(await error.future, isStateError);
      expect(imageCache.statusForKey(provider).untracked, true);
      expect(imageCache.pendingImageCount, 0);
    });

    group('NetworkImage', () {
      MockHttpClient httpClient;

      setUp(() {
        httpClient = MockHttpClient();
        debugNetworkImageHttpClientProvider = () => httpClient;
      });

      tearDown(() {
        debugNetworkImageHttpClientProvider = null;
      });

      test('Expect thrown exception with statusCode - evicts from cache', () async {
        final int errorStatusCode = HttpStatus.notFound;
        const String requestUrl = 'foo-url';

        final MockHttpClientRequest request = MockHttpClientRequest();
        final MockHttpClientResponse response = MockHttpClientResponse();
        when(httpClient.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
        when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
        when(response.statusCode).thenReturn(errorStatusCode);

        final Completer<dynamic> caughtError = Completer<dynamic>();

        final ImageProvider imageProvider = NetworkImage(nonconst(requestUrl));
        expect(imageCache.pendingImageCount, 0);
        expect(imageCache.statusForKey(imageProvider).untracked, true);

        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);

        expect(imageCache.pendingImageCount, 1);
        expect(imageCache.statusForKey(imageProvider).pending, true);

        result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
        }, onError: (dynamic error, StackTrace stackTrace) {
          caughtError.complete(error);
        }));

        final dynamic err = await caughtError.future;

        expect(imageCache.pendingImageCount, 0);
        expect(imageCache.statusForKey(imageProvider).untracked, true);

        expect(
          err,
          isA<NetworkImageLoadException>()
            .having((NetworkImageLoadException e) => e.statusCode, 'statusCode', errorStatusCode)
            .having((NetworkImageLoadException e) => e.uri, 'uri', Uri.base.resolve(requestUrl)),
        );
      }, skip: isBrowser);  // Browser implementation does not use HTTP client but an <img> tag.

      test('Disallows null urls', () {
        expect(() {
          NetworkImage(nonconst(null));
        }, throwsAssertionError);
      });

      test('Uses the HttpClient provided by debugNetworkImageHttpClientProvider if set', () async {
        when(httpClient.getUrl(any)).thenThrow('client1');
        final List<dynamic> capturedErrors = <dynamic>[];

        Future<void> loadNetworkImage() async {
          final NetworkImage networkImage = NetworkImage(nonconst('foo'));
          final ImageStreamCompleter completer = networkImage.load(networkImage, basicDecoder);
          completer.addListener(ImageStreamListener(
            (ImageInfo image, bool synchronousCall) { },
            onError: (dynamic error, StackTrace stackTrace) {
              capturedErrors.add(error);
            },
          ));
          await Future<void>.value();
        }

        await loadNetworkImage();
        expect(capturedErrors, <dynamic>['client1']);
        final MockHttpClient client2 = MockHttpClient();
        when(client2.getUrl(any)).thenThrow('client2');
        debugNetworkImageHttpClientProvider = () => client2;
        await loadNetworkImage();
        expect(capturedErrors, <dynamic>['client1', 'client2']);
      }, skip: isBrowser); // Browser implementation does not use HTTP client but an <img> tag.

      test('Propagates http client errors during resolve()', () async {
        when(httpClient.getUrl(any)).thenThrow(Error());
        bool uncaught = false;

        await runZoned(() async {
          const ImageProvider imageProvider = NetworkImage('asdasdasdas');
          final Completer<bool> caughtError = Completer<bool>();
          FlutterError.onError = (FlutterErrorDetails details) {
            throw Error();
          };
          final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
          result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
          }, onError: (dynamic error, StackTrace stackTrace) {
            caughtError.complete(true);
          }));
          expect(await caughtError.future, true);
        }, zoneSpecification: ZoneSpecification(
          handleUncaughtError: (Zone zone, ZoneDelegate zoneDelegate, Zone parent, Object error, StackTrace stackTrace) {
            uncaught = true;
          },
        ));
        expect(uncaught, false);
      });

      test('Notifies listeners of chunk events', () async {
        const int chunkSize = 8;
        final List<Uint8List> chunks = <Uint8List>[
          for (int offset = 0; offset < kTransparentImage.length; offset += chunkSize)
            Uint8List.fromList(kTransparentImage.skip(offset).take(chunkSize).toList()),
        ];
        final Completer<void> imageAvailable = Completer<void>();
        final MockHttpClientRequest request = MockHttpClientRequest();
        final MockHttpClientResponse response = MockHttpClientResponse();
        when(httpClient.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
        when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
        when(response.statusCode).thenReturn(HttpStatus.ok);
        when(response.contentLength).thenReturn(kTransparentImage.length);
        when(response.listen(
          any,
          onDone: anyNamed('onDone'),
          onError: anyNamed('onError'),
          cancelOnError: anyNamed('cancelOnError'),
        )).thenAnswer((Invocation invocation) {
          final void Function(List<int>) onData = invocation.positionalArguments[0] as void Function(List<int>);
          final void Function(Object) onError = invocation.namedArguments[#onError] as void Function(Object);
          final VoidCallback onDone = invocation.namedArguments[#onDone] as VoidCallback;
          final bool cancelOnError = invocation.namedArguments[#cancelOnError] as bool;

          return Stream<Uint8List>.fromIterable(chunks).listen(
            onData,
            onDone: onDone,
            onError: onError,
            cancelOnError: cancelOnError,
          );
        });

        final ImageProvider imageProvider = NetworkImage(nonconst('foo'));
        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
        final List<ImageChunkEvent> events = <ImageChunkEvent>[];
        result.addListener(ImageStreamListener(
          (ImageInfo image, bool synchronousCall) {
            imageAvailable.complete();
          },
          onChunk: (ImageChunkEvent event) {
            events.add(event);
          },
          onError: (dynamic error, StackTrace stackTrace) {
            imageAvailable.completeError(error, stackTrace);
          },
        ));
        await imageAvailable.future;
        expect(events.length, chunks.length);
        for (int i = 0; i < events.length; i++) {
          expect(events[i].cumulativeBytesLoaded, math.min((i + 1) * chunkSize, kTransparentImage.length));
          expect(events[i].expectedTotalBytes, kTransparentImage.length);
        }
      }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56317

      test('NetworkImage is evicted from cache on SocketException', () async {
        final MockHttpClient mockHttpClient = MockHttpClient();
        when(mockHttpClient.getUrl(any)).thenAnswer((_) => throw const SocketException('test exception'));
        debugNetworkImageHttpClientProvider = () => mockHttpClient;


        final ImageProvider imageProvider = NetworkImage(nonconst('testing.url'));
        expect(imageCache.pendingImageCount, 0);
        expect(imageCache.statusForKey(imageProvider).untracked, true);

        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);

        expect(imageCache.pendingImageCount, 1);
        expect(imageCache.statusForKey(imageProvider).pending, true);
        final Completer<dynamic> caughtError = Completer<dynamic>();
        result.addListener(ImageStreamListener(
          (ImageInfo info, bool syncCall) {},
          onError: (dynamic error, StackTrace stackTrace) {
            caughtError.complete(error);
          },
        ));

        final dynamic err = await caughtError.future;

        expect(err, isA<SocketException>());

        expect(imageCache.pendingImageCount, 0);
        expect(imageCache.statusForKey(imageProvider).untracked, true);
        expect(imageCache.containsKey(result), isFalse);

        debugNetworkImageHttpClientProvider = null;
      }, skip: isBrowser); // Browser does not resolve images this way.
    });
  });

  test('ResizeImage resizes to the correct dimensions', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage imageProvider = MemoryImage(bytes);
    final Size rawImageSize = await _resolveAndGetSize(imageProvider);
    expect(rawImageSize, const Size(1, 1));

    const Size resizeDims = Size(14, 7);
    final ResizeImage resizedImage = ResizeImage(MemoryImage(bytes), width: resizeDims.width.round(), height: resizeDims.height.round());
    const ImageConfiguration resizeConfig = ImageConfiguration(size: resizeDims);
    final Size resizedImageSize = await _resolveAndGetSize(resizedImage, configuration: resizeConfig);
    expect(resizedImageSize, resizeDims);
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56312

  test('ResizeImage does not resize when no size is passed', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage imageProvider = MemoryImage(bytes);
    final Size rawImageSize = await _resolveAndGetSize(imageProvider);
    expect(rawImageSize, const Size(1, 1));

    // Cannot pass in two null arguments for cache dimensions, so will use the regular
    // MemoryImage
    final MemoryImage resizedImage = MemoryImage(bytes);
    final Size resizedImageSize = await _resolveAndGetSize(resizedImage);
    expect(resizedImageSize, const Size(1, 1));
  });

  test('ResizeImage stores values', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 10, height: 20);
    expect(resizeImage.width, 10);
    expect(resizeImage.height, 20);
    expect(resizeImage.imageProvider, memoryImage);

    expect(memoryImage.resolve(ImageConfiguration.empty) != resizeImage.resolve(ImageConfiguration.empty), true);
  });

  test('ResizeImage takes one dim', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 10, height: null);
    expect(resizeImage.width, 10);
    expect(resizeImage.height, null);
    expect(resizeImage.imageProvider, memoryImage);

    expect(memoryImage.resolve(ImageConfiguration.empty) != resizeImage.resolve(ImageConfiguration.empty), true);
  });

  test('ResizeImage forms closure', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 123, height: 321);

    final DecoderCallback decode = (Uint8List bytes, {int cacheWidth, int cacheHeight}) {
      expect(cacheWidth, 123);
      expect(cacheHeight, 321);
      return PaintingBinding.instance.instantiateImageCodec(bytes, cacheWidth: cacheWidth, cacheHeight: cacheHeight);
    };

    resizeImage.load(await resizeImage.obtainKey(ImageConfiguration.empty), decode);
  });

  test('ResizeImage handles sync obtainKey', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final MemoryImage memoryImage = MemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 123, height: 321);

    bool isAsync = false;
    resizeImage.obtainKey(ImageConfiguration.empty).then((Object key) {
      expect(isAsync, false);
    });
    isAsync = true;
    expect(isAsync, true);
  });

  test('ResizeImage handles async obtainKey', () async {
    final Uint8List bytes = Uint8List.fromList(kTransparentImage);
    final AsyncKeyMemoryImage memoryImage = AsyncKeyMemoryImage(bytes);
    final ResizeImage resizeImage = ResizeImage(memoryImage, width: 123, height: 321);

    bool isAsync = false;
    resizeImage.obtainKey(ImageConfiguration.empty).then((Object key) {
      expect(isAsync, true);
    });
    isAsync = true;
    expect(isAsync, true);
  });

  test('File image with empty file throws expected error (load)', () async {
    final Completer<StateError> error = Completer<StateError>();
    FlutterError.onError = (FlutterErrorDetails details) {
      error.complete(details.exception as StateError);
    };
    final MemoryFileSystem fs = MemoryFileSystem();
    final File file = fs.file('/empty.png')..createSync(recursive: true);
    final FileImage provider = FileImage(file);

    expect(provider.load(provider, null), isA<MultiFrameImageStreamCompleter>());

    expect(await error.future, isStateError);
  });
}

Future<Size> _resolveAndGetSize(ImageProvider imageProvider,
    {ImageConfiguration configuration = ImageConfiguration.empty}) async {
  final ImageStream stream = imageProvider.resolve(configuration);
  final Completer<Size> completer = Completer<Size>();
  final ImageStreamListener listener =
    ImageStreamListener((ImageInfo image, bool synchronousCall) {
      final int height = image.image.height;
      final int width = image.image.width;
      completer.complete(Size(width.toDouble(), height.toDouble()));
    }
  );
  stream.addListener(listener);
  return await completer.future;
}

// This version of MemoryImage guarantees obtainKey returns a future that has not been
// completed synchronously.
class AsyncKeyMemoryImage extends MemoryImage {
  const AsyncKeyMemoryImage(Uint8List bytes) : super(bytes);

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    return Future<MemoryImage>(() => this);
  }
}

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return null;
  }
}
