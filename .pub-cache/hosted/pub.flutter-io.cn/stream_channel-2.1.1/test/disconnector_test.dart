// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late StreamController streamController;
  late StreamController sinkController;
  late Disconnector disconnector;
  late StreamChannel channel;
  setUp(() {
    streamController = StreamController();
    sinkController = StreamController();
    disconnector = Disconnector();
    channel = StreamChannel.withGuarantees(
            streamController.stream, sinkController.sink)
        .transform(disconnector);
  });

  group('before disconnection', () {
    test('forwards events from the sink as normal', () {
      channel.sink.add(1);
      channel.sink.add(2);
      channel.sink.add(3);
      channel.sink.close();

      expect(sinkController.stream.toList(), completion(equals([1, 2, 3])));
    });

    test('forwards events to the stream as normal', () {
      streamController.add(1);
      streamController.add(2);
      streamController.add(3);
      streamController.close();

      expect(channel.stream.toList(), completion(equals([1, 2, 3])));
    });

    test("events can't be added when the sink is explicitly closed", () {
      sinkController.stream.listen(null); // Work around sdk#19095.

      expect(channel.sink.close(), completes);
      expect(() => channel.sink.add(1), throwsStateError);
      expect(() => channel.sink.addError('oh no'), throwsStateError);
      expect(() => channel.sink.addStream(Stream.fromIterable([])),
          throwsStateError);
    });

    test("events can't be added while a stream is being added", () {
      var controller = StreamController();
      channel.sink.addStream(controller.stream);

      expect(() => channel.sink.add(1), throwsStateError);
      expect(() => channel.sink.addError('oh no'), throwsStateError);
      expect(() => channel.sink.addStream(Stream.fromIterable([])),
          throwsStateError);
      expect(() => channel.sink.close(), throwsStateError);

      controller.close();
    });
  });

  test('cancels addStream when disconnected', () async {
    var canceled = false;
    var controller = StreamController(onCancel: () {
      canceled = true;
    });
    expect(channel.sink.addStream(controller.stream), completes);
    unawaited(disconnector.disconnect());

    await pumpEventQueue();
    expect(canceled, isTrue);
  });

  test('disconnect() returns the close future from the inner sink', () async {
    var streamController = StreamController();
    var sinkController = StreamController();
    var disconnector = Disconnector();
    var sink = _CloseCompleterSink(sinkController.sink);
    StreamChannel.withGuarantees(streamController.stream, sink)
        .transform(disconnector);

    var disconnectFutureFired = false;
    expect(
        disconnector.disconnect().then((_) {
          disconnectFutureFired = true;
        }),
        completes);

    // Give the future time to fire early if it's going to.
    await pumpEventQueue();
    expect(disconnectFutureFired, isFalse);

    // When the inner sink's close future completes, so should the
    // disconnector's.
    sink.completer.complete();
    await pumpEventQueue();
    expect(disconnectFutureFired, isTrue);
  });

  group('after disconnection', () {
    setUp(() {
      disconnector.disconnect();
    });

    test('closes the inner sink and ignores events to the outer sink', () {
      channel.sink.add(1);
      channel.sink.add(2);
      channel.sink.add(3);
      channel.sink.close();

      expect(sinkController.stream.toList(), completion(isEmpty));
    });

    test('closes the stream', () {
      expect(channel.stream.toList(), completion(isEmpty));
    });

    test('completes done', () {
      sinkController.stream.listen(null); // Work around sdk#19095.
      expect(channel.sink.done, completes);
    });

    test('still emits state errors after explicit close', () {
      sinkController.stream.listen(null); // Work around sdk#19095.
      expect(channel.sink.close(), completes);

      expect(() => channel.sink.add(1), throwsStateError);
      expect(() => channel.sink.addError('oh no'), throwsStateError);
    });
  });
}

/// A [StreamSink] wrapper that adds the ability to manually complete the Future
/// returned by [close] using [completer].
class _CloseCompleterSink extends DelegatingStreamSink {
  /// The completer for the future returned by [close].
  final completer = Completer();

  _CloseCompleterSink(StreamSink inner) : super(inner);

  @override
  Future<void> close() {
    super.close();
    return completer.future;
  }
}
