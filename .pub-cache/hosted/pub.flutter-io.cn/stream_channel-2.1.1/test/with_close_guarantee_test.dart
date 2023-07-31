// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

final _delayTransformer = StreamTransformer.fromHandlers(
    handleData: (data, sink) => Future.microtask(() => sink.add(data)),
    handleDone: (sink) => Future.microtask(() => sink.close()));

final _delaySinkTransformer =
    StreamSinkTransformer.fromStreamTransformer(_delayTransformer);

void main() {
  late StreamChannelController controller;
  late StreamChannel channel;
  setUp(() {
    controller = StreamChannelController();

    // Add a bunch of layers of asynchronous dispatch between the channel and
    // the underlying controllers.
    var stream = controller.foreign.stream;
    var sink = controller.foreign.sink;
    for (var i = 0; i < 10; i++) {
      stream = stream.transform(_delayTransformer);
      sink = _delaySinkTransformer.bind(sink);
    }

    channel = StreamChannel.withCloseGuarantee(stream, sink);
  });

  test(
      'closing the event sink causes the stream to close before it emits any '
      'more events', () async {
    controller.local.sink.add(1);
    controller.local.sink.add(2);
    controller.local.sink.add(3);

    expect(
        channel.stream
            .listen(expectAsync1((event) {
              if (event == 2) channel.sink.close();
            }, count: 2))
            .asFuture(),
        completes);

    await pumpEventQueue();
  });

  test(
      'closing the event sink before events are emitted causes the stream to '
      'close immediately', () async {
    unawaited(channel.sink.close());
    channel.stream.listen(expectAsync1((_) {}, count: 0),
        onError: expectAsync2((_, __) {}, count: 0),
        onDone: expectAsync0(() {}));

    controller.local.sink.add(1);
    controller.local.sink.add(2);
    controller.local.sink.add(3);
    unawaited(controller.local.sink.close());

    await pumpEventQueue();
  });
}
