// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';

import '../flutter_test_alternative.dart';

void main() {
  group(getHttpClientResponseBytes, () {
    final Uint8List chunkOne = Uint8List.fromList(<int>[0, 1, 2, 3, 4, 5]);
    final Uint8List chunkTwo = Uint8List.fromList(<int>[6, 7, 8, 9, 10]);
    MockHttpClientResponse response;

    setUp(() {
      response = MockHttpClientResponse();
      when(response.compressionState).thenReturn(HttpClientResponseCompressionState.notCompressed);
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

        return Stream<Uint8List>.fromIterable(
            <Uint8List>[chunkOne, chunkTwo]).listen(
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
      final List<int> bytes = (await getHttpClientResponseBytes(response))
          .materialize().asUint8List();

      expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Converts a compressed HttpClientResponse with contentLength to bytes', () async {
      when(response.contentLength).thenReturn(chunkOne.length);
      final List<int> bytes = (await getHttpClientResponseBytes(response))
          .materialize().asUint8List();

      expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Converts an HttpClientResponse without contentLength to bytes', () async {
      when(response.contentLength).thenReturn(-1);
      final List<int> bytes = (await getHttpClientResponseBytes(response))
          .materialize().asUint8List();

      expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Notifies onBytesReceived for every chunk of bytes', () async {
      final int syntheticTotal = (chunkOne.length + chunkTwo.length) * 2;
      when(response.contentLength).thenReturn(syntheticTotal);
      final List<int> records = <int>[];
      await getHttpClientResponseBytes(
        response,
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

        return Stream<Uint8List>.fromFuture(
                Future<Uint8List>.error(Exception('Test Error')))
            .listen(
          onData,
          onDone: onDone,
          onError: onError,
          cancelOnError: cancelOnError,
        );
      });
      when(response.contentLength).thenReturn(-1);

      expect(getHttpClientResponseBytes(response),
          throwsA(isInstanceOf<Exception>()));
    });

    test('Propagates error to Future return value if onBytesReceived throws', () async {
      when(response.contentLength).thenReturn(-1);
      final Future<TransferableTypedData> result = getHttpClientResponseBytes(
        response,
        onBytesReceived: (int cumulative, int total) {
          throw 'misbehaving callback';
        },
      );

      expect(result, throwsA(equals('misbehaving callback')));
    });

    group('when gzipped', () {
      final Uint8List gzipped = gzip.encode(chunkOne.followedBy(chunkTwo).toList());
      final Uint8List gzippedChunkOne = gzipped.sublist(0, gzipped.length ~/ 2);
      final Uint8List gzippedChunkTwo = gzipped.sublist(gzipped.length ~/ 2);

      setUp(() {
        when(response.compressionState).thenReturn(HttpClientResponseCompressionState.compressed);
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

          return Stream<Uint8List>.fromIterable(
              <Uint8List>[gzippedChunkOne, gzippedChunkTwo]).listen(
            onData,
            onDone: onDone,
            onError: onError,
            cancelOnError: cancelOnError,
          );
        });
      });

      test('Uncompresses GZIP bytes if autoUncompress is true and response.compressionState is compressed', () async {
        when(response.compressionState).thenReturn(HttpClientResponseCompressionState.compressed);
        when(response.contentLength).thenReturn(gzipped.length);
        final List<int> bytes = (await getHttpClientResponseBytes(response)).materialize().asUint8List();
        expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      });

      test('returns gzipped bytes if autoUncompress is false and response.compressionState is compressed', () async {
        when(response.compressionState).thenReturn(HttpClientResponseCompressionState.compressed);
        when(response.contentLength).thenReturn(gzipped.length);
        final List<int> bytes = (await getHttpClientResponseBytes(response, autoUncompress: false)).materialize().asUint8List();
        expect(bytes, gzipped);
      });

      test('Notifies onBytesReceived with gzipped numbers', () async {
        when(response.compressionState).thenReturn(HttpClientResponseCompressionState.compressed);
        when(response.contentLength).thenReturn(gzipped.length);
        final List<int> records = <int>[];
        await getHttpClientResponseBytes(
          response,
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

      test('Notifies onBytesReceived with expectedContentLength of -1 if response.compressionState is decompressed', () async {
        final int syntheticTotal = (chunkOne.length + chunkTwo.length) * 2;
        when(response.compressionState).thenReturn(HttpClientResponseCompressionState.decompressed);
        when(response.contentLength).thenReturn(syntheticTotal);
        final List<int> records = <int>[];
        await getHttpClientResponseBytes(
          response,
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

class MockHttpClientResponse extends Mock implements HttpClientResponse {}
