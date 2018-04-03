import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group(consolidateHttpClientResponseBytes, () {
    final List<int> chunkOne = <int>[0, 1, 2, 3, 4, 5];
    final List<int> chunkTwo = <int>[6, 7, 8, 9, 10];
    MockHttpClientResponse response;

    setUp(() {
      response = new MockHttpClientResponse();
       when(response.listen(
         typed(any),
         onDone: typed(any, named: 'onDone'),
         onError: typed(any, named: 'onError'),
         cancelOnError: typed(any, named: 'cancelOnError')
      )).thenAnswer((Invocation invocation) {
        final void Function(List<int>) onData = invocation.positionalArguments[0];
        final void Function(Object) onError = invocation.namedArguments[#onError];
        final void Function() onDone = invocation.namedArguments[#onDone];
        final bool cancelOnError = invocation.namedArguments[#cancelOnError];

        return new Stream<List<int>>.fromIterable(<List<int>>[chunkOne, chunkTwo])
          .listen(onData, onDone: onDone, onError: onError, cancelOnError: cancelOnError);
      });
    });

    test('Converts an HttpClientResponse with contentLength to bytes', () async {
      when(response.contentLength).thenReturn(chunkOne.length + chunkTwo.length);
      final List<int> bytes = await consolidateHttpClientResponseBytes(response);

      expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('Converts an HttpClientResponse without contentLength to bytes', () async {
      when(response.contentLength).thenReturn(-1);
      final List<int> bytes = await consolidateHttpClientResponseBytes(response);

      expect(bytes, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('forwards errors from HttpClientResponse', () async {
      when(response.listen(
        typed(any),
        onDone: typed(any, named: 'onDone'),
        onError: typed(any, named: 'onError'),
        cancelOnError: typed(any, named: 'cancelOnError')
      )).thenAnswer((Invocation invocation) {
        final void Function(List<int>) onData = invocation.positionalArguments[0];
        final void Function(Object) onError = invocation.namedArguments[#onError];
        final void Function() onDone = invocation.namedArguments[#onDone];
        final bool cancelOnError = invocation.namedArguments[#cancelOnError];

        return new Stream<List<int>>.fromFuture(new Future<List<int>>.error(new Exception('Test Error')))
          .listen(onData, onDone: onDone, onError: onError, cancelOnError: cancelOnError);
      });
      when(response.contentLength).thenReturn(-1);

      expect(consolidateHttpClientResponseBytes(response), throwsA(const isInstanceOf<Exception>()));
    });
  });
}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}