// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  late StreamChannelController controller;
  late MultiChannel channel1;
  late MultiChannel channel2;
  setUp(() {
    controller = StreamChannelController();
    channel1 = MultiChannel<int>(controller.local);
    channel2 = MultiChannel<int>(controller.foreign);
  });

  group('the default virtual channel', () {
    test('begins connected', () {
      var first = true;
      channel2.stream.listen(expectAsync1((message) {
        if (first) {
          expect(message, equals(1));
          first = false;
        } else {
          expect(message, equals(2));
        }
      }, count: 2));

      channel1.sink.add(1);
      channel1.sink.add(2);
    });

    test('closes the remote virtual channel when it closes', () {
      expect(channel2.stream.toList(), completion(isEmpty));
      expect(channel2.sink.done, completes);

      channel1.sink.close();
    });

    test('closes the local virtual channel when it closes', () {
      expect(channel1.stream.toList(), completion(isEmpty));
      expect(channel1.sink.done, completes);

      channel1.sink.close();
    });

    test(
        "doesn't closes the local virtual channel when the stream "
        'subscription is canceled', () {
      channel1.sink.done.then(expectAsync1((_) {}, count: 0));

      channel1.stream.listen((_) {}).cancel();

      // Ensure that there's enough time for the channel to close if it's going
      // to.
      return pumpEventQueue();
    });

    test(
        'closes the underlying channel when it closes without any other '
        'virtual channels', () {
      expect(controller.local.sink.done, completes);
      expect(controller.foreign.sink.done, completes);

      channel1.sink.close();
    });

    test(
        "doesn't close the underlying channel when it closes with other "
        'virtual channels', () {
      controller.local.sink.done.then(expectAsync1((_) {}, count: 0));
      controller.foreign.sink.done.then(expectAsync1((_) {}, count: 0));

      // Establish another virtual connection which should keep the underlying
      // connection open.
      channel2.virtualChannel(channel1.virtualChannel().id);
      channel1.sink.close();

      // Ensure that there's enough time for the underlying channel to complete
      // if it's going to.
      return pumpEventQueue();
    });
  });

  group('a locally-created virtual channel', () {
    late VirtualChannel virtual1;
    late VirtualChannel virtual2;
    setUp(() {
      virtual1 = channel1.virtualChannel();
      virtual2 = channel2.virtualChannel(virtual1.id);
    });

    test('sends messages only to the other virtual channel', () {
      var first = true;
      virtual2.stream.listen(expectAsync1((message) {
        if (first) {
          expect(message, equals(1));
          first = false;
        } else {
          expect(message, equals(2));
        }
      }, count: 2));

      // No other virtual channels should receive the message.
      for (var i = 0; i < 10; i++) {
        var virtual = channel2.virtualChannel(channel1.virtualChannel().id);
        virtual.stream.listen(expectAsync1((_) {}, count: 0));
      }
      channel2.stream.listen(expectAsync1((_) {}, count: 0));

      virtual1.sink.add(1);
      virtual1.sink.add(2);
    });

    test('closes the remote virtual channel when it closes', () {
      expect(virtual2.stream.toList(), completion(isEmpty));
      expect(virtual2.sink.done, completes);

      virtual1.sink.close();
    });

    test('closes the local virtual channel when it closes', () {
      expect(virtual1.stream.toList(), completion(isEmpty));
      expect(virtual1.sink.done, completes);

      virtual1.sink.close();
    });

    test(
        "doesn't closes the local virtual channel when the stream "
        'subscription is canceled', () {
      virtual1.sink.done.then(expectAsync1((_) {}, count: 0));
      virtual1.stream.listen((_) {}).cancel();

      // Ensure that there's enough time for the channel to close if it's going
      // to.
      return pumpEventQueue();
    });

    test(
        'closes the underlying channel when it closes without any other '
        'virtual channels', () async {
      // First close the default channel so we can test the new channel as the
      // last living virtual channel.
      unawaited(channel1.sink.close());

      await channel2.stream.toList();
      expect(controller.local.sink.done, completes);
      expect(controller.foreign.sink.done, completes);

      unawaited(virtual1.sink.close());
    });

    test(
        "doesn't close the underlying channel when it closes with other "
        'virtual channels', () {
      controller.local.sink.done.then(expectAsync1((_) {}, count: 0));
      controller.foreign.sink.done.then(expectAsync1((_) {}, count: 0));

      virtual1.sink.close();

      // Ensure that there's enough time for the underlying channel to complete
      // if it's going to.
      return pumpEventQueue();
    });

    test("doesn't conflict with a remote virtual channel", () {
      var virtual3 = channel2.virtualChannel();
      var virtual4 = channel1.virtualChannel(virtual3.id);

      // This is an implementation detail, but we assert it here to make sure
      // we're properly testing two channels with the same id.
      expect(virtual1.id, equals(virtual3.id));

      virtual2.stream
          .listen(expectAsync1((message) => expect(message, equals(1))));
      virtual4.stream
          .listen(expectAsync1((message) => expect(message, equals(2))));

      virtual1.sink.add(1);
      virtual3.sink.add(2);
    });
  });

  group('a remotely-created virtual channel', () {
    late VirtualChannel virtual1;
    late VirtualChannel virtual2;
    setUp(() {
      virtual1 = channel1.virtualChannel();
      virtual2 = channel2.virtualChannel(virtual1.id);
    });

    test('sends messages only to the other virtual channel', () {
      var first = true;
      virtual1.stream.listen(expectAsync1((message) {
        if (first) {
          expect(message, equals(1));
          first = false;
        } else {
          expect(message, equals(2));
        }
      }, count: 2));

      // No other virtual channels should receive the message.
      for (var i = 0; i < 10; i++) {
        var virtual = channel2.virtualChannel(channel1.virtualChannel().id);
        virtual.stream.listen(expectAsync1((_) {}, count: 0));
      }
      channel1.stream.listen(expectAsync1((_) {}, count: 0));

      virtual2.sink.add(1);
      virtual2.sink.add(2);
    });

    test('closes the remote virtual channel when it closes', () {
      expect(virtual1.stream.toList(), completion(isEmpty));
      expect(virtual1.sink.done, completes);

      virtual2.sink.close();
    });

    test('closes the local virtual channel when it closes', () {
      expect(virtual2.stream.toList(), completion(isEmpty));
      expect(virtual2.sink.done, completes);

      virtual2.sink.close();
    });

    test(
        "doesn't closes the local virtual channel when the stream "
        'subscription is canceled', () {
      virtual2.sink.done.then(expectAsync1((_) {}, count: 0));
      virtual2.stream.listen((_) {}).cancel();

      // Ensure that there's enough time for the channel to close if it's going
      // to.
      return pumpEventQueue();
    });

    test(
        'closes the underlying channel when it closes without any other '
        'virtual channels', () async {
      // First close the default channel so we can test the new channel as the
      // last living virtual channel.
      unawaited(channel2.sink.close());

      await channel1.stream.toList();
      expect(controller.local.sink.done, completes);
      expect(controller.foreign.sink.done, completes);

      unawaited(virtual2.sink.close());
    });

    test(
        "doesn't close the underlying channel when it closes with other "
        'virtual channels', () {
      controller.local.sink.done.then(expectAsync1((_) {}, count: 0));
      controller.foreign.sink.done.then(expectAsync1((_) {}, count: 0));

      virtual2.sink.close();

      // Ensure that there's enough time for the underlying channel to complete
      // if it's going to.
      return pumpEventQueue();
    });

    test("doesn't allow another virtual channel with the same id", () {
      expect(() => channel2.virtualChannel(virtual1.id), throwsArgumentError);
    });

    test('dispatches events received before the virtual channel is created',
        () async {
      virtual1 = channel1.virtualChannel();

      virtual1.sink.add(1);
      await pumpEventQueue();

      virtual1.sink.add(2);
      await pumpEventQueue();

      expect(channel2.virtualChannel(virtual1.id).stream, emitsInOrder([1, 2]));
    });

    test(
        'dispatches close events received before the virtual channel is '
        'created', () async {
      virtual1 = channel1.virtualChannel();

      unawaited(virtual1.sink.close());
      await pumpEventQueue();

      expect(channel2.virtualChannel(virtual1.id).stream.toList(),
          completion(isEmpty));
    });
  });

  group('when the underlying stream', () {
    late VirtualChannel virtual1;
    late VirtualChannel virtual2;
    setUp(() {
      virtual1 = channel1.virtualChannel();
      virtual2 = channel2.virtualChannel(virtual1.id);
    });

    test('closes, all virtual channels close', () {
      expect(channel1.stream.toList(), completion(isEmpty));
      expect(channel1.sink.done, completes);
      expect(channel2.stream.toList(), completion(isEmpty));
      expect(channel2.sink.done, completes);
      expect(virtual1.stream.toList(), completion(isEmpty));
      expect(virtual1.sink.done, completes);
      expect(virtual2.stream.toList(), completion(isEmpty));
      expect(virtual2.sink.done, completes);

      controller.local.sink.close();
    });

    test('closes, more virtual channels are created closed', () async {
      unawaited(channel2.sink.close());
      unawaited(virtual2.sink.close());

      // Wait for the existing channels to emit done events.
      await channel1.stream.toList();
      await virtual1.stream.toList();

      var virtual = channel1.virtualChannel();
      expect(virtual.stream.toList(), completion(isEmpty));
      expect(virtual.sink.done, completes);

      virtual = channel1.virtualChannel();
      expect(virtual.stream.toList(), completion(isEmpty));
      expect(virtual.sink.done, completes);
    });

    test('emits an error, the error is sent only to the default channel', () {
      channel1.stream.listen(expectAsync1((_) {}, count: 0),
          onError: expectAsync1((error) => expect(error, equals('oh no'))));
      virtual1.stream.listen(expectAsync1((_) {}, count: 0),
          onError: expectAsync1((_) {}, count: 0));

      controller.foreign.sink.addError('oh no');
    });
  });

  group('stream channel rules', () {
    group('for the main stream:', () {
      test(
          'closing the sink causes the stream to close before it emits any more '
          'events', () {
        channel1.sink.add(1);
        channel1.sink.add(2);
        channel1.sink.add(3);

        channel2.stream.listen(expectAsync1((message) {
          expect(message, equals(1));
          channel2.sink.close();
        }, count: 1));
      });

      test('after the stream closes, the sink ignores events', () async {
        unawaited(channel1.sink.close());

        // Wait for the done event to be delivered.
        await channel2.stream.toList();
        channel2.sink.add(1);
        channel2.sink.add(2);
        channel2.sink.add(3);
        unawaited(channel2.sink.close());

        // None of our channel.sink additions should make it to the other endpoint.
        channel1.stream.listen(expectAsync1((_) {}, count: 0));
        await pumpEventQueue();
      });

      test("canceling the stream's subscription has no effect on the sink",
          () async {
        unawaited(channel1.stream.listen(null).cancel());
        await pumpEventQueue();

        channel1.sink.add(1);
        channel1.sink.add(2);
        channel1.sink.add(3);
        unawaited(channel1.sink.close());
        expect(channel2.stream.toList(), completion(equals([1, 2, 3])));
      });

      test("canceling the stream's subscription doesn't stop a done event",
          () async {
        unawaited(channel1.stream.listen(null).cancel());
        await pumpEventQueue();

        unawaited(channel2.sink.close());
        await pumpEventQueue();

        channel1.sink.add(1);
        channel1.sink.add(2);
        channel1.sink.add(3);
        unawaited(channel1.sink.close());

        // The sink should be ignoring events because the channel closed.
        channel2.stream.listen(expectAsync1((_) {}, count: 0));
        await pumpEventQueue();
      });
    });

    group('for a virtual channel:', () {
      late VirtualChannel virtual1;
      late VirtualChannel virtual2;
      setUp(() {
        virtual1 = channel1.virtualChannel();
        virtual2 = channel2.virtualChannel(virtual1.id);
      });

      test(
          'closing the sink causes the stream to close before it emits any more '
          'events', () {
        virtual1.sink.add(1);
        virtual1.sink.add(2);
        virtual1.sink.add(3);

        virtual2.stream.listen(expectAsync1((message) {
          expect(message, equals(1));
          virtual2.sink.close();
        }, count: 1));
      });

      test('after the stream closes, the sink ignores events', () async {
        unawaited(virtual1.sink.close());

        // Wait for the done event to be delivered.
        await virtual2.stream.toList();
        virtual2.sink.add(1);
        virtual2.sink.add(2);
        virtual2.sink.add(3);
        unawaited(virtual2.sink.close());

        // None of our virtual.sink additions should make it to the other endpoint.
        virtual1.stream.listen(expectAsync1((_) {}, count: 0));
        await pumpEventQueue();
      });

      test("canceling the stream's subscription has no effect on the sink",
          () async {
        unawaited(virtual1.stream.listen(null).cancel());
        await pumpEventQueue();

        virtual1.sink.add(1);
        virtual1.sink.add(2);
        virtual1.sink.add(3);
        unawaited(virtual1.sink.close());
        expect(virtual2.stream.toList(), completion(equals([1, 2, 3])));
      });

      test("canceling the stream's subscription doesn't stop a done event",
          () async {
        unawaited(virtual1.stream.listen(null).cancel());
        await pumpEventQueue();

        unawaited(virtual2.sink.close());
        await pumpEventQueue();

        virtual1.sink.add(1);
        virtual1.sink.add(2);
        virtual1.sink.add(3);
        unawaited(virtual1.sink.close());

        // The sink should be ignoring events because the stream closed.
        virtual2.stream.listen(expectAsync1((_) {}, count: 0));
        await pumpEventQueue();
      });
    });
  });
}
