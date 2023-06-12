// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

import 'test_util.dart';

void main() {
  test('hijacking a non-hijackable request throws a StateError', () {
    expect(() => Request('GET', localhostUri).hijack((_) {}), throwsStateError);
  });

  test(
      'hijacking a hijackable request throws a HijackException and calls '
      'onHijack', () {
    var request =
        Request('GET', localhostUri, onHijack: expectAsync1((callback) {
      var streamController = StreamController<List<int>>();
      streamController.add([1, 2, 3]);
      streamController.close();

      var sinkController = StreamController<List<int>>();
      expect(sinkController.stream.first, completion(equals([4, 5, 6])));

      callback(StreamChannel(streamController.stream, sinkController));
    }));

    expect(
        () => request.hijack(expectAsync1((channel) {
              expect(channel.stream.first, completion(equals([1, 2, 3])));
              channel.sink.add([4, 5, 6]);
              channel.sink.close();
            })),
        throwsHijackException);
  });

  test('hijacking a hijackable request twice throws a StateError', () {
    // Assert that the [onHijack] callback is only called once.
    var request =
        Request('GET', localhostUri, onHijack: expectAsync1((_) {}, count: 1));

    expect(() => request.hijack((_) {}), throwsHijackException);

    expect(() => request.hijack((_) {}), throwsStateError);
  });

  group('calling change', () {
    test('hijacking a non-hijackable request throws a StateError', () {
      var request = Request('GET', localhostUri);
      var newRequest = request.change();
      expect(() => newRequest.hijack((_) {}), throwsStateError);
    });

    test(
        'hijacking a hijackable request throws a HijackException and calls '
        'onHijack', () {
      var request =
          Request('GET', localhostUri, onHijack: expectAsync1((callback) {
        var streamController = StreamController<List<int>>();
        streamController.add([1, 2, 3]);
        streamController.close();

        var sinkController = StreamController<List<int>>();
        expect(sinkController.stream.first, completion(equals([4, 5, 6])));

        callback(StreamChannel(streamController.stream, sinkController));
      }));

      var newRequest = request.change();

      expect(
          () => newRequest.hijack(expectAsync1((channel) {
                expect(channel.stream.first, completion(equals([1, 2, 3])));
                channel.sink.add([4, 5, 6]);
                channel.sink.close();
              })),
          throwsHijackException);
    });

    test(
        'hijacking the original request after calling change throws a '
        'StateError', () {
      // Assert that the [onHijack] callback is only called once.
      var request = Request('GET', localhostUri,
          onHijack: expectAsync1((_) {}, count: 1));

      var newRequest = request.change();

      expect(() => newRequest.hijack((_) {}), throwsHijackException);

      expect(() => request.hijack((_) {}), throwsStateError);
    });
  });
}
