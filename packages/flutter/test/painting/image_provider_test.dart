// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:test_api/test_api.dart' show TypeMatcher;

import '../rendering/rendering_tester.dart';
import 'image_data.dart';
import 'mocks_for_image_cache.dart';

void main() {
  group(ImageProvider, () {
    setUpAll(() {
      TestRenderingFlutterBinding(); // initializes the imageCache
    });

    group('Image cache', () {
      tearDown(() {
        imageCache.clear();
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
          imageProvider, () => imageProvider.load(imageProvider),
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

    group(NetworkImage, () {
      test('Expect thrown exception with statusCode', () async {
        final int errorStatusCode = HttpStatus.notFound;
        const String requestUrl = 'foo-url';

        debugNetworkImageHttpClientProvider = returnErrorStatusCode;

        final Completer<dynamic> caughtError = Completer<dynamic>();

        final ImageProvider imageProvider = NetworkImage(nonconst(requestUrl));
        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
        result.addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
        }, onError: (dynamic error, StackTrace stackTrace) {
          caughtError.complete(error);
        }));

        final dynamic err = await caughtError.future;
        expect(
          err,
          const TypeMatcher<NetworkImageLoadException>()
            .having((NetworkImageLoadException e) => e.statusCode, 'statusCode', errorStatusCode)
            .having((NetworkImageLoadException e) => e.uri, 'uri', Uri.base.resolve(requestUrl)),
        );
      });

      test('Disallows null urls', () {
        expect(() {
          NetworkImage(nonconst(null));
        }, throwsAssertionError);
      });

      test('Uses the HttpClient provided by debugNetworkImageHttpClientProvider if set', () async {
        debugNetworkImageHttpClientProvider = throwOnAnyClient1;

        final List<dynamic> capturedErrors = <dynamic>[];

        Future<void> loadNetworkImage() async {
          final NetworkImage networkImage = NetworkImage(nonconst('foo'));
          final Completer<bool> completer = Completer<bool>();
          networkImage.load(networkImage).addListener(ImageStreamListener(
            (ImageInfo image, bool synchronousCall) {
              completer.complete(true);
            },
            onError: (dynamic error, StackTrace stackTrace) {
              capturedErrors.add(error);
              completer.complete(false);
            },
          ));
          await completer.future;
        }

        await loadNetworkImage();
        expect(capturedErrors, isNotNull);
        expect(capturedErrors.length, 1);
        expect(capturedErrors[0], equals('client1'));

        debugNetworkImageHttpClientProvider = throwOnAnyClient2;
        await loadNetworkImage();
        expect(capturedErrors, isNotNull);
        expect(capturedErrors.length, 2);
        expect(capturedErrors[0], equals('client1'));
        expect(capturedErrors[1], equals('client2'));
      }, skip: isBrowser);

      test('Propagates http client errors during resolve()', () async {
        debugNetworkImageHttpClientProvider = throwErrorOnAny;
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
        debugNetworkImageHttpClientProvider = respondOnAny;

        const int chunkSize = 8;
        final List<Uint8List> chunks = createChunks(chunkSize);

        final Completer<void> imageAvailable = Completer<void>();
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
      }, skip: isBrowser);

      test('Uses http request headers', () async {
        debugNetworkImageHttpClientProvider = respondOnAnyWithHeaders;

        final Completer<bool> imageAvailable = Completer<bool>();
        final ImageProvider imageProvider = NetworkImage(nonconst('foo'),
          headers: const <String, String>{'flutter': 'flutter'},
        );
        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
        result.addListener(ImageStreamListener(
              (ImageInfo image, bool synchronousCall) {
            imageAvailable.complete(true);
          },
          onError: (dynamic error, StackTrace stackTrace) {
            imageAvailable.completeError(error, stackTrace);
          },
        ));
        expect(await imageAvailable.future, isTrue);
      }, skip: isBrowser);

      test('Handles http stream errors', () async {
        debugNetworkImageHttpClientProvider = respondErrorOnAny;

        final Completer<String> imageAvailable = Completer<String>();
        final ImageProvider imageProvider = NetworkImage(nonconst('bar'));
        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
        final List<ImageChunkEvent> events = <ImageChunkEvent>[];

        result.addListener(ImageStreamListener(
          (ImageInfo image, bool synchronousCall) {
            imageAvailable.complete(null);
          },
          onChunk: (ImageChunkEvent event) {
            events.add(event);
          },
          onError: (dynamic error, StackTrace stackTrace) {
            imageAvailable.complete(error);
          },
        ));
        final String error = await imageAvailable.future;
        expect(error, 'failed chunk');
      }, skip: isBrowser);

      test('Handles http connection errors', () async {
        debugNetworkImageHttpClientProvider = respondErrorOnConnection;

        final Completer<dynamic> imageAvailable = Completer<dynamic>();
        final ImageProvider imageProvider = NetworkImage(nonconst('baz'));
        final ImageStream result = imageProvider.resolve(ImageConfiguration.empty);
        result.addListener(ImageStreamListener(
              (ImageInfo image, bool synchronousCall) {
            imageAvailable.complete(null);
          },
          onError: (dynamic error, StackTrace stackTrace) {
            imageAvailable.complete(error);
          },
        ));
        final dynamic err = await imageAvailable.future;
        expect(err, const TypeMatcher<NetworkImageLoadException>()
            .having((NetworkImageLoadException e) => e.toString(), 'e', startsWith('HTTP request failed'))
            .having((NetworkImageLoadException e) => e.statusCode, 'statusCode', HttpStatus.badGateway)
            .having((NetworkImageLoadException e) => e.uri.toString(), 'uri', endsWith('/baz')));
      }, skip: isBrowser);
    });
  });
}

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}

HttpClient returnErrorStatusCode() {
  final int errorStatusCode = HttpStatus.notFound;

  debugNetworkImageHttpClientProvider = returnErrorStatusCode;

  final MockHttpClientRequest request = MockHttpClientRequest();
  final MockHttpClientResponse response = MockHttpClientResponse();
  final MockHttpClient httpClient = MockHttpClient();
  when(httpClient.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
  when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
  when(response.statusCode).thenReturn(errorStatusCode);

  return httpClient;
}

HttpClient throwOnAnyClient1() {
  final MockHttpClient httpClient = MockHttpClient();
  when(httpClient.getUrl(any)).thenThrow('client1');
  return httpClient;
}

HttpClient throwOnAnyClient2() {
  final MockHttpClient httpClient = MockHttpClient();
  when(httpClient.getUrl(any)).thenThrow('client2');
  return httpClient;
}

HttpClient throwErrorOnAny() {
  final MockHttpClient httpClient = MockHttpClient();
  when(httpClient.getUrl(any)).thenThrow(Exception());
  return httpClient;
}

HttpClient respondOnAny() {
  const int chunkSize = 8;
  final List<Uint8List> chunks = createChunks(chunkSize);
  final MockHttpClientRequest request = MockHttpClientRequest();
  final MockHttpClientResponse response = MockHttpClientResponse();
  final MockHttpClient httpClient = MockHttpClient();
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
    final void Function(Uint8List) onData = invocation.positionalArguments[0];
    final void Function(Object) onError = invocation.namedArguments[#onError];
    final void Function() onDone = invocation.namedArguments[#onDone];
    final bool cancelOnError = invocation.namedArguments[#cancelOnError];

    return Stream<Uint8List>.fromIterable(chunks).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  });
  return httpClient;
}

HttpClient respondOnAnyWithHeaders() {
  final List<Invocation> invocations = <Invocation>[];

  const int chunkSize = 8;
  final List<Uint8List> chunks = createChunks(chunkSize);
  final MockHttpClientRequest request = MockHttpClientRequest();
  final MockHttpClientResponse response = MockHttpClientResponse();
  final MockHttpClient httpClient = MockHttpClient();
  final MockHttpHeaders headers = MockHttpHeaders();
  when(httpClient.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
  when(request.headers).thenReturn(headers);
  when(headers.add(any, any)).thenAnswer((Invocation invocation) {
    invocations.add(invocation);
  });

  when(request.close()).thenAnswer((Invocation invocation) {
    if (invocations.length == 1 &&
        invocations[0].positionalArguments.length == 2 &&
        invocations[0].positionalArguments[0] == 'flutter' &&
        invocations[0].positionalArguments[1] == 'flutter') {
      return Future<HttpClientResponse>.value(response);
    } else {
      return Future<HttpClientResponse>.value(null);
    }
  });
  when(response.statusCode).thenReturn(HttpStatus.ok);
  when(response.contentLength).thenReturn(kTransparentImage.length);
  when(response.listen(
    any,
    onDone: anyNamed('onDone'),
    onError: anyNamed('onError'),
    cancelOnError: anyNamed('cancelOnError'),
  )).thenAnswer((Invocation invocation) {
    final void Function(Uint8List) onData = invocation.positionalArguments[0];
    final void Function(Object) onError = invocation.namedArguments[#onError];
    final void Function() onDone = invocation.namedArguments[#onDone];
    final bool cancelOnError = invocation.namedArguments[#cancelOnError];

    return Stream<Uint8List>.fromIterable(chunks).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  });
  return httpClient;
}

HttpClient respondErrorOnConnection() {
  final MockHttpClientRequest request = MockHttpClientRequest();
  final MockHttpClientResponse response = MockHttpClientResponse();
  final MockHttpClient httpClient = MockHttpClient();
  when(httpClient.getUrl(any)).thenAnswer((_) => Future<HttpClientRequest>.value(request));
  when(request.close()).thenAnswer((_) => Future<HttpClientResponse>.value(response));
  when(response.statusCode).thenReturn(HttpStatus.badGateway);
  return httpClient;
}

HttpClient respondErrorOnAny() {
  const int chunkSize = 8;
  final MockHttpClientRequest request = MockHttpClientRequest();
  final MockHttpClientResponse response = MockHttpClientResponse();
  final MockHttpClient httpClient = MockHttpClient();
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
    final void Function(Uint8List) onData = invocation.positionalArguments[0];
    final void Function(Object) onError = invocation.namedArguments[#onError];
    final void Function() onDone = invocation.namedArguments[#onDone];
    final bool cancelOnError = invocation.namedArguments[#cancelOnError];

    return createRottenChunks(chunkSize).listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  });
  return httpClient;
}

List<Uint8List> createChunks(int chunkSize) {
  final List<Uint8List> chunks = <Uint8List>[
    for (int offset = 0; offset < kTransparentImage.length; offset += chunkSize)
      Uint8List.fromList(kTransparentImage.skip(offset).take(chunkSize).toList()),
  ];
  return chunks;
}

Stream<Uint8List> createRottenChunks(int chunkSize) async* {
  yield Uint8List.fromList(kTransparentImage.take(chunkSize).toList());
  throw 'failed chunk';
}
