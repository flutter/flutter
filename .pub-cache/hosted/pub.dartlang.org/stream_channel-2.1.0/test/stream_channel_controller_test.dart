// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  group('asynchronously', () {
    late StreamChannelController controller;
    setUp(() {
      controller = StreamChannelController();
    });

    test('forwards events from the local sink to the foreign stream', () {
      controller.local.sink
        ..add(1)
        ..add(2)
        ..add(3)
        ..close();
      expect(controller.foreign.stream.toList(), completion(equals([1, 2, 3])));
    });

    test('forwards events from the foreign sink to the local stream', () {
      controller.foreign.sink
        ..add(1)
        ..add(2)
        ..add(3)
        ..close();
      expect(controller.local.stream.toList(), completion(equals([1, 2, 3])));
    });

    test(
        'with allowForeignErrors: false, shuts down the connection if an '
        'error is added to the foreign channel', () {
      controller = StreamChannelController(allowForeignErrors: false);

      controller.foreign.sink.addError('oh no');
      expect(controller.foreign.sink.done, throwsA('oh no'));
      expect(controller.foreign.stream.toList(), completion(isEmpty));
      expect(controller.local.sink.done, completes);
      expect(controller.local.stream.toList(), completion(isEmpty));
    });
  });

  group('synchronously', () {
    late StreamChannelController controller;
    setUp(() {
      controller = StreamChannelController(sync: true);
    });

    test(
        'synchronously forwards events from the local sink to the foreign '
        'stream', () {
      var receivedEvent = false;
      var receivedError = false;
      var receivedDone = false;
      controller.foreign.stream.listen(expectAsync1((event) {
        expect(event, equals(1));
        receivedEvent = true;
      }), onError: expectAsync1((error) {
        expect(error, equals('oh no'));
        receivedError = true;
      }), onDone: expectAsync0(() {
        receivedDone = true;
      }));

      controller.local.sink.add(1);
      expect(receivedEvent, isTrue);

      controller.local.sink.addError('oh no');
      expect(receivedError, isTrue);

      controller.local.sink.close();
      expect(receivedDone, isTrue);
    });

    test(
        'synchronously forwards events from the foreign sink to the local '
        'stream', () {
      var receivedEvent = false;
      var receivedError = false;
      var receivedDone = false;
      controller.local.stream.listen(expectAsync1((event) {
        expect(event, equals(1));
        receivedEvent = true;
      }), onError: expectAsync1((error) {
        expect(error, equals('oh no'));
        receivedError = true;
      }), onDone: expectAsync0(() {
        receivedDone = true;
      }));

      controller.foreign.sink.add(1);
      expect(receivedEvent, isTrue);

      controller.foreign.sink.addError('oh no');
      expect(receivedError, isTrue);

      controller.foreign.sink.close();
      expect(receivedDone, isTrue);
    });
  });
}
