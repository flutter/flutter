// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' hide Base64Encoder;
import 'dart:convert';

import 'package:_discoveryapis_commons/src/api_requester.dart';
import 'package:_discoveryapis_commons/src/multipart_media_uploader.dart';
import 'package:_discoveryapis_commons/src/requests.dart';
import 'package:_discoveryapis_commons/src/resumable_media_uploader.dart';
import 'package:_discoveryapis_commons/src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

typedef ServerMockCallback<T> = Future<http.StreamedResponse> Function(
    http.BaseRequest request, dynamic json);

const _requestHeaders = {
  'user-agent': 'google-api-dart-client/package-version',
  'x-goog-api-client': 'gl-dart/dart-version gdcl/package-version',
};

class HttpServerMock extends http.BaseClient {
  late ServerMockCallback _callback;
  late bool _expectJson;

  void register(ServerMockCallback callback, bool expectJson) {
    _callback = callback;
    _expectJson = expectJson;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    Object? data;
    if (_expectJson) {
      final jsonString =
          await request.finalize().transform(utf8.decoder).join();

      if (jsonString.isEmpty) {
        data = null;
      } else {
        data = json.decode(jsonString);
      }
    } else {
      data = await request.finalize().toBytes();
    }
    return _callback(request, data);
  }
}

http.StreamedResponse stringResponse(
    int status, Map<String, String> headers, String body) {
  final stream = Stream<List<int>>.fromIterable([utf8.encode(body)]);
  return http.StreamedResponse(stream, status, headers: headers);
}

http.StreamedResponse binaryResponse(
    int status, Map<String, String> headers, List<int> bytes) {
  final stream = Stream<List<int>>.fromIterable([bytes]);
  return http.StreamedResponse(stream, status, headers: headers);
}

Stream<List<int>> byteStream(String s) {
  final bodyController = StreamController<List<int>>()
    ..add(utf8.encode(s))
    ..close();
  return bodyController.stream;
}

class TestError {}

const isApiRequestError = TypeMatcher<ApiRequestError>();
const isDetailedApiRequestError = TypeMatcher<DetailedApiRequestError>();
const isTestError = TypeMatcher<TestError>();

void main() {
  group('isJson', () {
    for (var entry in {
      'application/json': true,
      // case doesn't matter
      'APPLICATION/JSON': true,
      // charset is fine
      'application/json; charset=utf-8': true,
      // Regression test for https://github.com/google/googleapis.dart/issues/99
      'application/fhir+json; charset=utf-8': true,
      // false cases
      'application/ecmascript': false,
      'application/javascript': false,
      'application/x-ecmascript': false,
      'application/x-javascript': false,
      'text/ecmascript': false,
      'text/javascript': false,
      'text/javascript1.0': false,
      'text/javascript1.1': false,
      'text/javascript1.2': false,
      'text/javascript1.3': false,
      'text/javascript1.4': false,
      'text/javascript1.5': false,
      'text/jscript': false,
      'text/livescript': false,
      'text/x-ecmascript': false,
      'text/x-javascript': false,
    }.entries) {
      test(entry.key, () {
        expect(isJson(entry.key), entry.value);
      });
    }
  });

  test('escaper', () {
    expect(escapeVariable('a/b%c '), equals('a%2Fb%25c%20'));
  });

  group('chunk-stack', () {
    const chunkSize = 9;

    List folded(List<List<int>> byteArrays) =>
        byteArrays.fold([], (buf, e) => buf..addAll(e));

    test('finalize', () {
      final chunkStack = ChunkStack(9)..finalize();
      expect(() => chunkStack.addBytes([1]), throwsA(isStateError));
      expect(chunkStack.finalize, throwsA(isStateError));
    });

    test('empty', () {
      final chunkStack = ChunkStack(9);
      expect(chunkStack.length, equals(0));
      chunkStack.finalize();
      expect(chunkStack.length, equals(0));
    });

    test('sub-chunk-size', () {
      final bytes = [1, 2, 3];

      final chunkStack = ChunkStack(9)..addBytes(bytes);
      expect(chunkStack.length, equals(0));
      chunkStack.finalize();
      expect(chunkStack.length, equals(1));
      expect(chunkStack.totalByteLength, equals(bytes.length));

      final chunks = chunkStack.removeSublist(0, chunkStack.length);
      expect(chunkStack.length, equals(0));
      expect(chunks, hasLength(1));

      expect(folded(chunks.first.byteArrays), equals(bytes));
      expect(chunks.first.offset, equals(0));
      expect(chunks.first.length, equals(3));
      expect(chunks.first.endOfChunk, equals(bytes.length));
    });

    test('exact-chunk-size', () {
      final bytes = [1, 2, 3, 4, 5, 6, 7, 8, 9];

      final chunkStack = ChunkStack(9)..addBytes(bytes);
      expect(chunkStack.length, equals(1));
      chunkStack.finalize();
      expect(chunkStack.length, equals(1));
      expect(chunkStack.totalByteLength, equals(bytes.length));

      final chunks = chunkStack.removeSublist(0, chunkStack.length);
      expect(chunkStack.length, equals(0));
      expect(chunks, hasLength(1));

      expect(folded(chunks.first.byteArrays), equals(bytes));
      expect(chunks.first.offset, equals(0));
      expect(chunks.first.length, equals(bytes.length));
      expect(chunks.first.endOfChunk, equals(bytes.length));
    });

    test('super-chunk-size', () {
      final bytes0 = [1, 2, 3, 4];
      final bytes1 = [1, 2, 3, 4];
      final bytes2 = [5, 6, 7, 8, 9, 10, 11];
      final bytes = folded([bytes0, bytes1, bytes2]);

      final chunkStack = ChunkStack(9)
        ..addBytes(bytes0)
        ..addBytes(bytes1)
        ..addBytes(bytes2);
      expect(chunkStack.length, equals(1));
      chunkStack.finalize();
      expect(chunkStack.length, equals(2));
      expect(chunkStack.totalByteLength, equals(bytes.length));

      final chunks = chunkStack.removeSublist(0, chunkStack.length);
      expect(chunkStack.length, equals(0));
      expect(chunks, hasLength(2));

      expect(
          folded(chunks.first.byteArrays), equals(bytes.sublist(0, chunkSize)));
      expect(chunks.first.offset, equals(0));
      expect(chunks.first.length, equals(chunkSize));
      expect(chunks.first.endOfChunk, equals(chunkSize));

      expect(folded(chunks.last.byteArrays), equals(bytes.sublist(chunkSize)));
      expect(chunks.last.offset, equals(chunkSize));
      expect(chunks.last.length, equals(bytes.length - chunkSize));
      expect(chunks.last.endOfChunk, equals(bytes.length));
    });
  });

  test('media', () {
    // Tests for [MediaRange]
    final partialRange = ByteRange(1, 100);
    expect(partialRange.start, equals(1));
    expect(partialRange.end, equals(100));

    final fullRange = ByteRange(0, -1);
    expect(fullRange.start, equals(0));
    expect(fullRange.end, equals(-1));

    final singleByte = ByteRange(0, 0);
    expect(singleByte.length, equals(1));

    expect(() => ByteRange(-1, 0), throwsA(anything));
    expect(() => ByteRange(-1, 1), throwsA(anything));

    // Tests for [DownloadOptions]
    expect(DownloadOptions.metadata.isMetadataDownload, isTrue);

    expect(DownloadOptions.fullMedia.isFullDownload, isTrue);
    expect(DownloadOptions.fullMedia.isMetadataDownload, isFalse);

    // Tests for [Media]
    final stream = StreamController<List<int>>().stream;
    expect(() => Media(stream, -1, contentType: 'foobar'),
        throwsA(isArgumentError));

    final lengthUnknownMedia = Media(stream, null);
    expect(lengthUnknownMedia.stream, equals(stream));
    expect(lengthUnknownMedia.length, equals(null));

    final media = Media(stream, 10, contentType: 'foobar');
    expect(media.stream, equals(stream));
    expect(media.length, equals(10));
    expect(media.contentType, equals('foobar'));

    // Tests for [ResumableUploadOptions]
    expect(() => ResumableUploadOptions(numberOfAttempts: 0),
        throwsA(isArgumentError));
    expect(
        () => ResumableUploadOptions(chunkSize: 1), throwsA(isArgumentError));
  });

  group('api-requester', () {
    late HttpServerMock httpMock;
    String rootUrl, basePath;
    late ApiRequester requester;

    final responseHeaders = {
      'content-type': 'application/json; charset=utf-8',
    };

    setUp(() {
      httpMock = HttpServerMock();
      rootUrl = 'http://example.com/';
      basePath = 'base/';
      requester = ApiRequester(httpMock, rootUrl, basePath, _requestHeaders);
    });

    // Tests for Request, Response

    group('metadata-request-response', () {
      test('empty-request-empty-response', () async {
        httpMock.register(expectAsync2((http.BaseRequest request, json) async {
          expect(request.method, equals('GET'));
          expect(
              '${request.url}', equals('http://example.com/base/abc?alt=json'));
          return stringResponse(200, responseHeaders, '');
        }), true);

        expect(await requester.request('abc', 'GET'), isNull);
      });

      test('json-map-request-json-map-response', () async {
        httpMock.register(expectAsync2((http.BaseRequest request, json) async {
          expect(request.method, equals('GET'));
          expect(
              '${request.url}', equals('http://example.com/base/abc?alt=json'));
          expect(json is Map, isTrue);
          expect(json, hasLength(1));
          expect(json, containsPair('foo', 'bar'));
          return stringResponse(200, responseHeaders, '{"foo2" : "bar2"}');
        }), true);

        final response = await requester.request(
          'abc',
          'GET',
          body: json.encode({'foo': 'bar'}),
        );
        expect(response is Map, isTrue);
        expect(response, hasLength(1));
        expect(response, containsPair('foo2', 'bar2'));
      });

      test('json-list-request-json-list-response', () async {
        httpMock.register(expectAsync2((http.BaseRequest request, json) async {
          expect(request.method, equals('GET'));
          expect(
              '${request.url}', equals('http://example.com/base/abc?alt=json'));
          expect(json is List, isTrue);
          final jsonList = json as List;
          expect(jsonList, hasLength(2));
          expect(jsonList[0], equals('a'));
          expect(jsonList[1], equals(1));
          return stringResponse(200, responseHeaders, '["b", 2]');
        }), true);

        final response = await requester.request(
          'abc',
          'GET',
          body: json.encode(['a', 1]),
        ) as List;
        expect(response[0], equals('b'));
        expect(response[1], equals(2));
      });
    });

    group('media-download', () {
      test('media-download', () async {
        httpMock.register(expectAsync2((http.BaseRequest request, data) async {
          expect(request.method, equals('GET'));
          expect('${request.url}',
              equals('http://example.com/base/abc?alt=media'));
          expect(data, isEmpty);
          final headers = {
            'content-length': '${_data256.length}',
            'content-type': 'foobar',
          };
          return binaryResponse(200, headers, _data256);
        }), false);

        final result = await requester.request('abc', 'GET',
            body: '', downloadOptions: DownloadOptions.fullMedia);

        final media = result as Media;
        expect(media.contentType, equals('foobar'));
        expect(media.length, equals(_data256.length));

        expect(
          await media.stream.fold([], (List b, d) => b..addAll(d)),
          equals(_data256),
        );
      });

      test('media-download-partial', () async {
        final data64 = _data256.sublist(128, 128 + 64);

        httpMock.register(expectAsync2((http.BaseRequest request, data) async {
          expect(request.method, equals('GET'));
          expect('${request.url}',
              equals('http://example.com/base/abc?alt=media'));
          expect(data, isEmpty);
          expect(request.headers['range'], equals('bytes=128-191'));
          final headers = {
            'content-length': '${data64.length}',
            'content-type': 'foobar',
            'content-range': 'bytes 128-191/256',
          };
          return binaryResponse(200, headers, data64);
        }), false);
        final range = ByteRange(128, 128 + 64 - 1);
        final options = PartialDownloadOptions(range);

        final result = await requester.request('abc', 'GET',
            body: '', downloadOptions: options);
        final media = result as Media;
        expect(media.contentType, equals('foobar'));
        expect(media.length, equals(data64.length));

        expect(
          await media.stream.fold([], (List b, d) => b..addAll(d)),
          equals(data64),
        );
      });

      test('json-upload-media-download', () async {
        httpMock.register(expectAsync2((http.BaseRequest request, json) async {
          expect(request.method, equals('GET'));
          expect('${request.url}',
              equals('http://example.com/base/abc?alt=media'));
          final jsonList = json as List;
          expect(jsonList, hasLength(2));
          expect(jsonList[0], equals('a'));
          expect(jsonList[1], equals(1));

          final headers = {
            'content-length': '${_data256.length}',
            'content-type': 'foobar',
          };
          return binaryResponse(200, headers, _data256);
        }), true);

        final result = await requester.request('abc', 'GET',
            body: json.encode(['a', 1]),
            downloadOptions: DownloadOptions.fullMedia);
        final media = result as Media;
        expect(media.contentType, equals('foobar'));
        expect(media.length, equals(_data256.length));

        final d = await media.stream.fold([], (List b, d) => b..addAll(d));
        expect(d, equals(_data256));
      });
    });

    // Tests for media uploads

    group('media-upload', () {
      Stream<List<int>> streamFromByteArrays(List<List<int>> byteArrays) {
        final controller = StreamController<List<int>>();
        for (var array in byteArrays) {
          controller.add(array);
        }
        controller.close();
        return controller.stream;
      }

      Media mediaFromByteArrays(List<List<int>> byteArrays,
          {bool withLen = true}) {
        final len = withLen
            ? byteArrays.fold<int>(0, (int v, array) => v + array.length)
            : null;
        return Media(streamFromByteArrays(byteArrays), len,
            contentType: 'foobar');
      }

      Future<http.StreamedResponse> validateServerRequest(
        Map e,
        http.BaseRequest request,
        List<int>? data,
      ) =>
          Future.sync(() {
            final h = e['headers'] as Map;
            final r = e['response'] as http.StreamedResponse;

            expect(request.url.toString(), equals(e['url']));
            expect(request.method, equals(e['method']));
            h.forEach((k, v) {
              expect(request.headers[k], equals(v));
            });

            expect(data, equals(e['data']));
            return r;
          });

      ServerMockCallback serverRequestValidator(List<Map> expectations) {
        var i = 0;
        return (http.BaseRequest request, data) => validateServerRequest(
              expectations[i++],
              request,
              data as List<int>?,
            );
      }

      test('simple', () async {
        final bytes = List.generate(10 * 256 * 1024 + 1, (i) => i % 256);
        final expectations = [
          {
            'url': 'http://example.com/xyz?uploadType=media&alt=json',
            'method': 'POST',
            'data': bytes,
            'headers': {
              'content-length': '${bytes.length}',
              'content-type': 'foobar',
            },
            'response': stringResponse(200, responseHeaders, '')
          },
        ];

        httpMock.register(
            expectAsync2(serverRequestValidator(expectations)), false);
        final media = mediaFromByteArrays([bytes]);

        await requester.request('/xyz', 'POST', uploadMedia: media);
      });

      test('multipart-upload', () async {
        final bytes = List.generate(10 * 256 * 1024 + 1, (i) => i % 256);
        final contentBytes = '--314159265358979323846\r\n'
            'Content-Type: $contentTypeJsonUtf8\r\n\r\n'
            'BODY'
            '\r\n--314159265358979323846\r\n'
            'Content-Type: foobar\r\n'
            'Content-Transfer-Encoding: base64\r\n\r\n'
            '${base64.encode(bytes)}'
            '\r\n--314159265358979323846--';

        final expectations = [
          {
            'url': 'http://example.com/xyz?uploadType=multipart&alt=json',
            'method': 'POST',
            'data': utf8.encode(contentBytes),
            'headers': {
              'content-length': '${contentBytes.length}',
              'content-type':
                  'multipart/related; boundary="314159265358979323846"',
            },
            'response': stringResponse(200, responseHeaders, '')
          },
        ];

        httpMock.register(
            expectAsync2(serverRequestValidator(expectations)), false);
        final media = mediaFromByteArrays([bytes]);
        await requester.request(
          '/xyz',
          'POST',
          body: 'BODY',
          uploadMedia: media,
        );
      });

      group('resumable-upload', () {
        // TODO: respect [stream]
        List<Map> buildExpectations(
          List<int> bytes,
          int chunkSize,
          bool stream, {
          int numberOfServerErrors = 0,
        }) {
          final totalLength = bytes.length;
          var numberOfChunks = totalLength ~/ chunkSize;
          var numberOfBytesInLastChunk = totalLength % chunkSize;

          if (numberOfBytesInLastChunk > 0) {
            numberOfChunks++;
          } else {
            numberOfBytesInLastChunk = chunkSize;
          }

          final expectations = [
            // First request is making a POST and gets the upload URL.
            {
              'url': 'http://example.com/xyz?uploadType=resumable&alt=json',
              'method': 'POST',
              'data': [],
              'headers': {
                'content-length': '0',
                'content-type': 'application/json; charset=utf-8',
                'x-upload-content-type': 'foobar',
              }..addAll(stream
                  ? {}
                  : {
                      'x-upload-content-length': '$totalLength',
                    }),
              'response':
                  stringResponse(200, {'location': 'http://upload.com/'}, '')
            }
          ];

          for (var i = 0; i < numberOfChunks; i++) {
            final isLast = i == (numberOfChunks - 1);
            final lengthMarker = stream && !isLast ? '*' : '$totalLength';

            var bytesToExpect = chunkSize;
            if (isLast) {
              bytesToExpect = numberOfBytesInLastChunk;
            }

            final start = i * chunkSize;
            final end = start + bytesToExpect;
            final sublist = bytes.sublist(start, end);

            final firstContentRange = 'bytes $start-${end - 1}/$lengthMarker';
            final firstRange = 'bytes=0-${end - 1}';

            // We issue [numberOfServerErrors] 503 errors first, and then a
            // successful response.
            for (var j = 0; j < (numberOfServerErrors + 1); j++) {
              final successfulResponse = j == numberOfServerErrors;

              http.StreamedResponse response;
              if (successfulResponse) {
                final headers = isLast
                    ? {'content-type': 'application/json; charset=utf-8'}
                    : {'range': firstRange};
                response = stringResponse(isLast ? 200 : 308, headers, '');
              } else {
                final headers = <String, String>{};
                response = stringResponse(503, headers, '');
              }

              expectations.add({
                'url': 'http://upload.com/',
                'method': 'PUT',
                'data': sublist,
                'headers': {
                  'content-length': '${sublist.length}',
                  'content-range': firstContentRange,
                  'content-type': 'foobar',
                },
                'response': response,
              });
            }
          }
          return expectations;
        }

        List<List<int>> makeParts(List<int> bytes, List<int> splits) {
          final parts = <List<int>>[];
          var lastEnd = 0;
          for (var i = 0; i < splits.length; i++) {
            parts.add(bytes.sublist(lastEnd, splits[i]));
            lastEnd = splits[i];
          }
          return parts;
        }

        void runTest(
            int chunkSizeInBlocks, int length, List<int> splits, bool stream,
            {int numberOfServerErrors = 0,
            ResumableUploadOptions? resumableOptions,
            int? expectedErrorStatus,
            int? messagesNrOfFailure}) {
          final chunkSize = chunkSizeInBlocks * 256 * 1024;

          final bytes = List<int>.generate(length, (i) => i % 256);
          final parts = makeParts(bytes, splits);

          // Simulation of our server
          var expectations = buildExpectations(bytes, chunkSize, false,
              numberOfServerErrors: numberOfServerErrors);
          // If the server simulates 50X errors and the client resumes only
          // a limited amount of time, we'll truncate the number of requests
          // the server expects.
          // [The client will give up and if the server expects more, the test
          //  would timeout.]
          if (expectedErrorStatus != null) {
            expectations = expectations.sublist(0, messagesNrOfFailure);
          }
          httpMock.register(
            expectAsync2(
              serverRequestValidator(expectations),
              count: expectations.length,
            ),
            false,
          );

          // Our client
          final media = mediaFromByteArrays(parts);

          resumableOptions ??= ResumableUploadOptions(chunkSize: chunkSize);
          final result = requester.request('/xyz', 'POST',
              uploadMedia: media, uploadOptions: resumableOptions);
          if (expectedErrorStatus != null) {
            result.catchError(expectAsync1((dynamic error) {
              expect(error is DetailedApiRequestError, isTrue);
              expect(
                (error as DetailedApiRequestError).status,
                equals(expectedErrorStatus),
              );
            }));
          } else {
            result.then(expectAsync1((_) {}));
          }
        }

        Duration? Function(int) backoffWrapper(int callCount) =>
            expectAsync1((int failedAttempts) {
              final duration =
                  ResumableUploadOptions.exponentialBackoff(failedAttempts)
                      as Duration;
              expect(duration.inSeconds, equals(1 << (failedAttempts - 1)));
              return const Duration(milliseconds: 1);
            }, count: callCount);

        test('length-small-block', () {
          runTest(1, 10, [10], false);
        });

        test('length-small-block-parts', () {
          runTest(1, 20, [1, 2, 3, 4, 5, 6, 7, 19, 20], false);
        });

        test('length-big-block', () {
          runTest(1, 1024 * 1024, [1024 * 1024], false);
        });

        test('length-big-block-parts', () {
          runTest(
              1,
              1024 * 1024,
              [
                1,
                256 * 1024 - 1,
                256 * 1024,
                256 * 1024 + 1,
                1024 * 1024 - 1,
                1024 * 1024
              ],
              false);
        });

        test('length-big-block-parts-non-divisible', () {
          runTest(
              1,
              1024 * 1024 + 1,
              [
                1,
                256 * 1024 - 1,
                256 * 1024,
                256 * 1024 + 1,
                1024 * 1024 - 1,
                1024 * 1024,
                1024 * 1024 + 1
              ],
              false);
        });

        test('stream-small-block', () {
          runTest(1, 10, [10], true);
        });

        test('stream-small-block-parts', () {
          runTest(1, 20, [1, 2, 3, 4, 5, 6, 7, 19, 20], true);
        });

        test('stream-big-block', () {
          runTest(1, 1024 * 1024, [1024 * 1024], true);
        });

        test('stream-big-block-parts', () {
          runTest(
              1,
              1024 * 1024,
              [
                1,
                256 * 1024 - 1,
                256 * 1024,
                256 * 1024 + 1,
                1024 * 1024 - 1,
                1024 * 1024
              ],
              true);
        });

        test('stream-big-block-parts--with-server-error-recovery', () {
          const numFailedAttempts = 4 * 3;
          final options = ResumableUploadOptions(
              chunkSize: 256 * 1024,
              numberOfAttempts: 4,
              backoffFunction: backoffWrapper(numFailedAttempts));
          runTest(
              1,
              1024 * 1024,
              [
                1,
                256 * 1024 - 1,
                256 * 1024,
                256 * 1024 + 1,
                1024 * 1024 - 1,
                1024 * 1024
              ],
              true,
              numberOfServerErrors: 3,
              resumableOptions: options);
        });

        test('stream-big-block-parts--server-error', () {
          const numFailedAttempts = 2;
          final options = ResumableUploadOptions(
              chunkSize: 256 * 1024,
              backoffFunction: backoffWrapper(numFailedAttempts));
          runTest(
              1,
              1024 * 1024,
              [
                1,
                256 * 1024 - 1,
                256 * 1024,
                256 * 1024 + 1,
                1024 * 1024 - 1,
                1024 * 1024
              ],
              true,
              numberOfServerErrors: 3,
              resumableOptions: options,
              expectedErrorStatus: 503,
              messagesNrOfFailure: 4);
        });
      });
    });

    // Tests for error responses
    group('request-errors', () {
      void makeTestError() {
        // All errors from the [http.Client] propagate through.
        // We use [TestError] to simulate it.
        httpMock.register(
          expectAsync2(
            (http.BaseRequest request, string) =>
                Future<http.StreamedResponse>.error(TestError()),
          ),
          false,
        );
      }

      void makeDetailed400Error() {
        httpMock.register(
          expectAsync2(
            (http.BaseRequest request, string) async => stringResponse(400,
                responseHeaders, '{"error" : {"code" : 42, "message": "foo"}}'),
          ),
          false,
        );
      }

      void makeErrorsError() {
        const errorJson = '''
          { "error" :
            { "code" : 42,
              "message" : "foo",
              "errors" : [
                {"reason" : "InvalidEmailError"},
                {"domain" : "account", "message": "error"}
              ]
            }
          }
          ''';
        httpMock.register(
          expectAsync2(
            (http.BaseRequest request, string) async =>
                stringResponse(400, responseHeaders, errorJson),
          ),
          false,
        );
      }

      void makeNormal199Error() {
        httpMock.register(
          expectAsync2(
            (http.BaseRequest request, string) async =>
                stringResponse(199, {}, ''),
          ),
          false,
        );
      }

      void makeInvalidContentTypeError() {
        httpMock.register(
          expectAsync2((http.BaseRequest request, string) async {
            final responseHeaders = {'content-type': 'image/png'};
            return stringResponse(200, responseHeaders, '');
          }),
          false,
        );
      }

      test('normal-http-client', () {
        makeTestError();
        expect(requester.request('abc', 'GET'), throwsA(isTestError));
      });

      test('normal-detailed-400', () {
        makeDetailed400Error();
        requester
            .request('abc', 'GET')
            .catchError(expectAsync2((dynamic error, dynamic stack) {
          expect(error, isDetailedApiRequestError);
          final e = error as DetailedApiRequestError;
          expect(e.status, equals(42));
          expect(e.message, equals('foo'));
        }));
      });

      test('error-with-multiple-errors', () {
        makeErrorsError();
        requester
            .request('abc', 'GET')
            .catchError(expectAsync2((dynamic error, dynamic stack) {
          expect(error, isDetailedApiRequestError);
          final e = error as DetailedApiRequestError;
          expect(e.status, equals(42));
          expect(e.message, equals('foo'));
          expect(e.errors.length, equals(2));
          expect(e.errors.first.reason, equals('InvalidEmailError'));
          expect(e.errors.last.domain, equals('account'));
          expect(e.errors.last.message, equals('error'));
        }));
      });

      test('normal-199', () {
        makeNormal199Error();
        expect(requester.request('abc', 'GET'), throwsA(isApiRequestError));
      });

      test('normal-invalid-content-type', () {
        makeInvalidContentTypeError();
        expect(requester.request('abc', 'GET'), throwsA(isApiRequestError));
      });

      final options = DownloadOptions.fullMedia;
      test('media-http-client', () {
        makeTestError();
        expect(requester.request('abc', 'GET', downloadOptions: options),
            throwsA(isTestError));
      });

      test('media-detailed-400', () {
        makeDetailed400Error();
        requester
            .request('abc', 'GET')
            .catchError(expectAsync2((dynamic error, dynamic stack) {
          expect(error, isDetailedApiRequestError);
          final e = error as DetailedApiRequestError;
          expect(e.status, equals(42));
          expect(e.message, equals('foo'));
        }));
      });

      test('media-199', () {
        makeNormal199Error();
        expect(requester.request('abc', 'GET', downloadOptions: options),
            throwsA(isApiRequestError));
      });
    });

    // Tests for path/query parameters

    test('request-parameters-query', () async {
      final queryParams = {
        'a': ['a1', 'a2'],
        's': ['s1']
      };
      httpMock.register(expectAsync2((http.BaseRequest request, json) async {
        expect(request.method, equals('GET'));
        expect('${request.url}',
            equals('http://example.com/base/abc?a=a1&a=a2&s=s1&alt=json'));
        return stringResponse(200, responseHeaders, '');
      }), true);

      expect(
        await requester.request('abc', 'GET', queryParams: queryParams),
        isNull,
      );
    });

    test('request-parameters-path', () async {
      httpMock.register(expectAsync2((http.BaseRequest request, json) async {
        expect(request.method, equals('GET'));
        expect('${request.url}',
            equals('http://example.com/base/s/foo/a1/a2/bar/s1/e?alt=json'));
        return stringResponse(200, responseHeaders, '');
      }), true);

      expect(await requester.request('s/foo/a1/a2/bar/s1/e', 'GET'), isNull);
    });
  });
  group('errors', () {
    test('error-detail-from-json', () {
      var detail = ApiRequestErrorDetail.fromJson({});
      expect(detail.domain, isNull);
      expect(detail.reason, isNull);
      expect(detail.message, isNull);
      expect(detail.location, isNull);
      expect(detail.locationType, isNull);
      expect(detail.extendedHelp, isNull);
      expect(detail.sendReport, isNull);

      final json = {
        'domain': 'value-domain',
        'reason': 'value-reason',
        'message': 'value-message',
        'location': 'value-location',
        'locationType': 'value-locationType',
        'extendedHelp': 'value-extendedHelp',
        'sendReport': 'value-sendReport'
      };

      detail = ApiRequestErrorDetail.fromJson(json);
      expect(detail.originalJson, json);
      expect(detail.domain, json['domain']);
      expect(detail.reason, json['reason']);
      expect(detail.message, json['message']);
      expect(detail.location, json['location']);
      expect(detail.locationType, json['locationType']);
      expect(detail.extendedHelp, json['extendedHelp']);
      expect(detail.sendReport, json['sendReport']);
    });
  });
}

final _data256 = List.generate(256, (i) => i);
