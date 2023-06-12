import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/compat/file_service_compat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';

void main() {
  group('Check header values', () {
    test('Valid headers should be parsed normally', () async {
      var eTag = 'test';
      var fileExtension = 'jpg';
      var contentType = 'image/jpeg';
      var contentLength = 16;
      var maxAge = const Duration(hours: 2);

      var client = MockClient((request) async {
        return Response.bytes(Uint8List(contentLength), 200, headers: {
          'etag': 'test',
          'content-type': contentType,
          'cache-control': 'max-age=${maxAge.inSeconds}'
        });
      });

      await withClock(Clock.fixed(DateTime.now()), () async {
        var httpFileFetcher = HttpFileService(httpClient: client);
        final now = clock.now();
        final response = await httpFileFetcher.get('test.com/image');

        expect(response.contentLength, contentLength);
        expect(response.eTag, eTag);
        expect(response.fileExtension, '.$fileExtension');
        expect(response.validTill, now.add(maxAge));
        expect(response.statusCode, 200);
      });
    });

    test('Weird contenttype should still parse', () async {
      var fileExtension = 'cov';
      var contentType = 'unknown/$fileExtension';

      var client = MockClient((request) async {
        return Response.bytes(Uint8List(16), 200,
            headers: {'content-type': contentType});
      });

      var httpFileFetcher = HttpFileService(httpClient: client);
      final response = await httpFileFetcher.get('test.com/image');

      expect(response.fileExtension, '.$fileExtension');
    });

    test('Content-Type parameters should be ignored', () async {
      var fileExtension = 'mp3';
      var contentType = 'audio/mpeg;chartset=UTF-8';

      var client = MockClient((request) async {
        return Response.bytes(Uint8List(16), 200,
            headers: {'content-type': contentType});
      });

      var httpFileFetcher = HttpFileService(httpClient: client);
      final response = await httpFileFetcher.get('test.com/document');

      expect(response.fileExtension, '.$fileExtension');
    });

    test('Test CompatFileService', () async {
      var eTag = 'test';
      var fileExtension = 'jpg';
      var contentType = 'image/jpeg';
      var contentLength = 16;
      var maxAge = const Duration(hours: 2);

      var client = MockClient((request) async {
        return Response.bytes(Uint8List(contentLength), 200, headers: {
          'etag': 'test',
          'content-type': contentType,
          'cache-control': 'max-age=${maxAge.inSeconds}'
        });
      });

      Future<FileFetcherResponse> _defaultHttpGetter(String url,
          {Map<String, String> headers}) async {
        var httpResponse = await client.get(url, headers: headers);
        return HttpFileFetcherResponse(httpResponse);
      }

      await withClock(Clock.fixed(DateTime.now()), () async {
        var httpFileFetcher = FileServiceCompat(_defaultHttpGetter);
        final now = clock.now();
        final response = await httpFileFetcher.get('test.com/image');

        expect(response.contentLength, contentLength);
        expect(response.eTag, eTag);
        expect(response.fileExtension, '.$fileExtension');
        expect(response.validTill, now.add(maxAge));
        expect(response.statusCode, 200);
      });
    });
  });
}
