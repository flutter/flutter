import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  test('Rx.materialize.happyPath', () async {
    final stream = Stream.value(1);
    final notifications = <Notification<int>>[];

    stream.materialize().listen(notifications.add, onDone: expectAsync0(() {
      expect(
          notifications, [Notification.onData(1), Notification<int>.onDone()]);
    }));
  });

  test('Rx.materialize.reusable', () async {
    final transformer = MaterializeStreamTransformer<int>();
    final stream = Stream.value(1).asBroadcastStream();
    final notificationsA = <Notification<int>>[],
        notificationsB = <Notification<int>>[];

    stream.transform(transformer).listen(notificationsA.add,
        onDone: expectAsync0(() {
      expect(
          notificationsA, [Notification.onData(1), Notification<int>.onDone()]);
    }));

    stream.transform(transformer).listen(notificationsB.add,
        onDone: expectAsync0(() {
      expect(
          notificationsB, [Notification.onData(1), Notification<int>.onDone()]);
    }));
  });

  test('materializeTransformer.happyPath', () async {
    final stream = Stream.fromIterable(const [1]);
    final notifications = <Notification<int>>[];

    stream
        .transform(MaterializeStreamTransformer<int>())
        .listen(notifications.add, onDone: expectAsync0(() {
      expect(
          notifications, [Notification.onData(1), Notification<int>.onDone()]);
    }));
  });

  test('materializeTransformer.sadPath', () async {
    final stream = Stream<int>.error(Exception());
    final notifications = <Notification<int>>[];

    stream
        .transform(MaterializeStreamTransformer<int>())
        .listen(notifications.add,
            onError: expectAsync2((Exception e, StackTrace s) {
              // Check to ensure the stream does not come to this point
              expect(true, isFalse);
            }, count: 0), onDone: expectAsync0(() {
      expect(notifications.length, 2);
      expect(notifications[0].isOnError, isTrue);
      expect(notifications[1].isOnDone, isTrue);
    }));
  });

  test('materializeTransformer.onPause.onResume', () async {
    final stream = Stream.fromIterable(const [1]);
    final notifications = <Notification<int>>[];

    stream
        .transform(MaterializeStreamTransformer<int>())
        .listen(notifications.add, onDone: expectAsync0(() {
      expect(notifications, <Notification<int>>[
        Notification.onData(1),
        Notification<int>.onDone()
      ]);
    }))
          ..pause()
          ..resume();
  });

  test('Rx.materialize accidental broadcast', () async {
    final controller = StreamController<int>();

    final stream = controller.stream.materialize();

    stream.listen(null);
    expect(() => stream.listen(null), throwsStateError);

    controller.add(1);
  });
}
