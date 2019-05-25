// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';

import '../flutter_test_alternative.dart';

void main() {
  group(consolidateHttpClientResponseBytes, () {
    final List<int> chunkOne = <int>[0, 1, 2, 3, 4, 5];
    final List<int> chunkTwo = <int>[6, 7, 8, 9, 10];
    MockHttpClient client;
    MockHttpClientResponse response;
    MockHttpHeaders headers;

    setUp(() {
      client = MockHttpClient();
      response = MockHttpClientResponse();
      headers = MockHttpHeaders();
      when(client.autoUncompress).thenReturn(true);
      when(response.headers).thenReturn(headers);
      when(headers.value(HttpHeaders.contentEncodingHeader)).thenReturn(null);
      when(response.listen(
         any,
         onDone: anyNamed('onDone'),
         onError: anyNamed('onError'),
         cancelOnError: anyNamed('cancelOnError'),
      )).thenAnswer((Invocation invocation) {
        final void Function(List<int>) onData = invocation.positionalArguments[0];
        final void Function(Object) onError = invocation.namedArguments[#onError];
        final void Function() onDone = invocation.namedArguments[#onDone];
        final bool cancelOnError = invocation.namedArguments[#cancelOnError];

        return Stream<List<int>>.fromIterable(
            <List<int>>[chunkOne, chunkTwo]).listen(
          onData,
          onDone: onDone,
          onError: onError,
          cancelOnError: cancelOnError,
        );
      });
    });

    test('Converts an HttpClientResponse with contentLength to bytes', () async {
      when(response.contentLength)
          .thenReturn(chunkOne.length + chunkTwo.length);
      final List<int> bytes =
          await consolidateHttpClientResponseBytes(response, client: client);

      expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Converts a compressed HttpClientResponse with contentLength to bytes', () async {
      when(response.contentLength).thenReturn(chunkOne.length);
      final List<int> bytes =
          await consolidateHttpClientResponseBytes(response, client: client);

      expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Converts an HttpClientResponse without contentLength to bytes', () async {
      when(response.contentLength).thenReturn(-1);
      final List<int> bytes =
          await consolidateHttpClientResponseBytes(response, client: client);

      expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Notifies onBytesReceived for every chunk of bytes', () async {
      final int syntheticTotal = (chunkOne.length + chunkTwo.length) * 2;
      when(response.contentLength).thenReturn(syntheticTotal);
      final List<int> records = <int>[];
      await consolidateHttpClientResponseBytes(
        response,
        client: client,
        onBytesReceived: (int cumulative, int total) {
          records.addAll(<int>[cumulative, total]);
        },
      );

      expect(records, <int>[
        chunkOne.length,
        syntheticTotal,
        chunkOne.length + chunkTwo.length,
        syntheticTotal,
      ]);
    });

    test('forwards errors from HttpClientResponse', () async {
      when(response.listen(
        any,
        onDone: anyNamed('onDone'),
        onError: anyNamed('onError'),
        cancelOnError: anyNamed('cancelOnError'),
      )).thenAnswer((Invocation invocation) {
        final void Function(List<int>) onData = invocation.positionalArguments[0];
        final void Function(Object) onError = invocation.namedArguments[#onError];
        final void Function() onDone = invocation.namedArguments[#onDone];
        final bool cancelOnError = invocation.namedArguments[#cancelOnError];

        return Stream<List<int>>.fromFuture(
                Future<List<int>>.error(Exception('Test Error')))
            .listen(
          onData,
          onDone: onDone,
          onError: onError,
          cancelOnError: cancelOnError,
        );
      });
      when(response.contentLength).thenReturn(-1);

      expect(consolidateHttpClientResponseBytes(response, client: client),
          throwsA(isInstanceOf<Exception>()));
    });

    test('Propagates error to Future return value if onBytesReceived throws', () async {
      when(response.contentLength).thenReturn(-1);
      final Future<List<int>> result = consolidateHttpClientResponseBytes(
        response,
        client: client,
        onBytesReceived: (int cumulative, int total) {
          throw 'misbehaving callback';
        },
      );

      expect(result, throwsA(equals('misbehaving callback')));
    });

    group('when gzipped', () {
      final List<int> gzipped = gzip.encode(chunkOne.followedBy(chunkTwo).toList());
      final List<int> gzippedChunkOne = gzipped.sublist(0, gzipped.length ~/ 2);
      final List<int> gzippedChunkTwo = gzipped.sublist(gzipped.length ~/ 2);

      setUp(() {
        when(headers.value(HttpHeaders.contentEncodingHeader)).thenReturn('gzip');
        when(response.listen(
          any,
          onDone: anyNamed('onDone'),
          onError: anyNamed('onError'),
          cancelOnError: anyNamed('cancelOnError'),
        )).thenAnswer((Invocation invocation) {
          final void Function(List<int>) onData = invocation.positionalArguments[0];
          final void Function(Object) onError = invocation.namedArguments[#onError];
          final void Function() onDone = invocation.namedArguments[#onDone];
          final bool cancelOnError = invocation.namedArguments[#cancelOnError];

          return Stream<List<int>>.fromIterable(
              <List<int>>[gzippedChunkOne, gzippedChunkTwo]).listen(
            onData,
            onDone: onDone,
            onError: onError,
            cancelOnError: cancelOnError,
          );
        });
      });

      test('Uncompresses GZIP bytes if autoUncompress is true and response.autoUncompress is false', () async {
        when(client.autoUncompress).thenReturn(false);
        when(response.contentLength).thenReturn(gzipped.length);
        final List<int> bytes = await consolidateHttpClientResponseBytes(response, client: client);
        expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      });

      test('returns gzipped bytes if autoUncompress is false and response.autoUncompress is false', () async {
        when(client.autoUncompress).thenReturn(false);
        when(response.contentLength).thenReturn(gzipped.length);
        final List<int> bytes = await consolidateHttpClientResponseBytes(response, client: client, autoUncompress: false);
        expect(bytes, gzipped);
      });

      test('Notifies onBytesReceived with gzipped numbers', () async {
        when(client.autoUncompress).thenReturn(false);
        when(response.contentLength).thenReturn(gzipped.length);
        final List<int> records = <int>[];
        await consolidateHttpClientResponseBytes(
          response,
          client: client,
          onBytesReceived: (int cumulative, int total) {
            records.addAll(<int>[cumulative, total]);
          },
        );

        expect(records, <int>[
          gzippedChunkOne.length,
          gzipped.length,
          gzipped.length,
          gzipped.length,
        ]);
      });

      test('Notifies onBytesReceived with expectedContentLength of -1 if response.autoUncompress is true', () async {
        final int syntheticTotal = (chunkOne.length + chunkTwo.length) * 2;
        when(response.contentLength).thenReturn(syntheticTotal);
        final List<int> records = <int>[];
        await consolidateHttpClientResponseBytes(
          response,
          client: client,
          onBytesReceived: (int cumulative, int total) {
            records.addAll(<int>[cumulative, total]);
          },
        );

        expect(records, <int>[
          gzippedChunkOne.length,
          null,
          gzipped.length,
          null,
        ]);
      });
    });
  });
}

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}
