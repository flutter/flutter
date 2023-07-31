// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late StreamChannelCompleter completer;
  late StreamController streamController;
  late StreamController sinkController;
  late StreamChannel innerChannel;
  setUp(() {
    completer = StreamChannelCompleter();
    streamController = StreamController();
    sinkController = StreamController();
    innerChannel = StreamChannel(streamController.stream, sinkController.sink);
  });

  group('when a channel is set before accessing', () {
    test('forwards events through the stream', () {
      completer.setChannel(innerChannel);
      expect(completer.channel.stream.toList(), completion(equals([1, 2, 3])));

      streamController.add(1);
      streamController.add(2);
      streamController.add(3);
      streamController.close();
    });

    test('forwards events through the sink', () {
      completer.setChannel(innerChannel);
      expect(sinkController.stream.toList(), completion(equals([1, 2, 3])));

      completer.channel.sink.add(1);
      completer.channel.sink.add(2);
      completer.channel.sink.add(3);
      completer.channel.sink.close();
    });

    test('forwards an error through the stream', () {
      completer.setError('oh no');
      expect(completer.channel.stream.first, throwsA('oh no'));
    });

    test('drops sink events', () {
      completer.setError('oh no');
      expect(completer.channel.sink.done, completes);
      completer.channel.sink.add(1);
      completer.channel.sink.addError('oh no');
    });
  });

  group('when a channel is set after accessing', () {
    test('forwards events through the stream', () async {
      expect(completer.channel.stream.toList(), completion(equals([1, 2, 3])));
      await pumpEventQueue();

      completer.setChannel(innerChannel);
      streamController.add(1);
      streamController.add(2);
      streamController.add(3);
      unawaited(streamController.close());
    });

    test('forwards events through the sink', () async {
      completer.channel.sink.add(1);
      completer.channel.sink.add(2);
      completer.channel.sink.add(3);
      unawaited(completer.channel.sink.close());
      await pumpEventQueue();

      completer.setChannel(innerChannel);
      expect(sinkController.stream.toList(), completion(equals([1, 2, 3])));
    });

    test('forwards an error through the stream', () async {
      expect(completer.channel.stream.first, throwsA('oh no'));
      await pumpEventQueue();

      completer.setError('oh no');
    });

    test('drops sink events', () async {
      expect(completer.channel.sink.done, completes);
      completer.channel.sink.add(1);
      completer.channel.sink.addError('oh no');
      await pumpEventQueue();

      completer.setError('oh no');
    });
  });

  group('forFuture', () {
    test('forwards a StreamChannel', () {
      var channel =
          StreamChannelCompleter.fromFuture(Future.value(innerChannel));
      channel.sink.add(1);
      channel.sink.close();
      streamController.sink.add(2);
      streamController.sink.close();

      expect(sinkController.stream.toList(), completion(equals([1])));
      expect(channel.stream.toList(), completion(equals([2])));
    });

    test('forwards an error', () {
      var channel = StreamChannelCompleter.fromFuture(Future.error('oh no'));
      expect(channel.stream.toList(), throwsA('oh no'));
    });
  });

  test("doesn't allow the channel to be set multiple times", () {
    completer.setChannel(innerChannel);
    expect(() => completer.setChannel(innerChannel), throwsStateError);
    expect(() => completer.setChannel(innerChannel), throwsStateError);
  });
}
