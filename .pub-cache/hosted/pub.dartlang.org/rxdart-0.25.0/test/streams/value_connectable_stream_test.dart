import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

class MockStream<T> extends Mock implements Stream<T> {}

void main() {
  group('BehaviorConnectableStream', () {
    test('should not emit before connecting', () {
      final stream = MockStream<int>();
      final connectableStream = ValueConnectableStream(stream);

      when(stream.listen(any, onError: anyNamed('onError')))
          .thenReturn(Stream.fromIterable(const [1, 2, 3]).listen(null));

      verifyNever(stream.listen(any,
          onError: anyNamed('onError'), onDone: anyNamed('onDone')));

      connectableStream.connect();

      verify(stream.listen(any,
          onError: anyNamed('onError'), onDone: anyNamed('onDone')));
    });

    test('should begin emitting items after connection', () {
      var count = 0;
      const items = [1, 2, 3];
      final stream = ValueConnectableStream(Stream.fromIterable(items));

      stream.connect();

      expect(stream, emitsInOrder(items));
      stream.listen(expectAsync1((i) {
        expect(stream.value, items[count]);
        count++;
      }, count: items.length));
    });

    test('stops emitting after the connection is cancelled', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).publishValue();

      stream.connect()..cancel(); // ignore: unawaited_futures

      expect(stream, neverEmits(anything));
    });

    test('stops emitting after the last subscriber unsubscribes', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();

      stream.listen(null)..cancel(); // ignore: unawaited_futures

      expect(stream, neverEmits(anything));
    });

    test('keeps emitting with an active subscription', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();

      stream.listen(null);
      stream.listen(null)..cancel(); // ignore: unawaited_futures

      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
    });

    test('multicasts a single-subscription stream', () async {
      final stream = ValueConnectableStream(
        Stream.fromIterable(const [1, 2, 3]),
      ).autoConnect();

      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
    });

    test('replays the latest item', () async {
      final stream = ValueConnectableStream(
        Stream.fromIterable(const [1, 2, 3]),
      ).autoConnect();

      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));

      await Future<Null>.delayed(Duration(milliseconds: 200));

      expect(stream, emits(3));
    });

    test('replays the seeded item', () async {
      final stream =
          ValueConnectableStream.seeded(StreamController<int>().stream, 3)
              .autoConnect();

      expect(stream, emitsInOrder(const <int>[3]));
      expect(stream, emitsInOrder(const <int>[3]));
      expect(stream, emitsInOrder(const <int>[3]));

      await Future<Null>.delayed(Duration(milliseconds: 200));

      expect(stream, emits(3));
    });

    test('replays the seeded null item', () async {
      final stream =
          ValueConnectableStream.seeded(StreamController<int>().stream, null)
              .autoConnect();

      expect(stream, emitsInOrder(const <int>[null]));
      expect(stream, emitsInOrder(const <int>[null]));
      expect(stream, emitsInOrder(const <int>[null]));

      await Future<Null>.delayed(Duration(milliseconds: 200));

      expect(stream, emits(null));
    });

    test('can multicast streams', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();

      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
    });

    test('transform Stream with initial value', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareValueSeeded(0);

      expect(stream.value, 0);
      expect(stream, emitsInOrder(const <int>[0, 1, 2, 3]));
    });

    test('provides access to the latest value', () async {
      const items = [1, 2, 3];
      var count = 0;
      final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();

      stream.listen(expectAsync1((data) {
        expect(data, items[count]);
        count++;
        if (count == items.length) {
          expect(stream.value, 3);
        }
      }, count: items.length));
    });

    test('provides access to the latest error', () async {
      final source = StreamController<int>();
      final stream = ValueConnectableStream(source.stream).autoConnect();

      source.sink.add(1);
      source.sink.add(2);
      source.sink.add(3);
      source.sink.addError(Exception('error'));

      stream.listen(
        null,
        onError: (Object error) {
          expect(stream.value, isNull);
          expect(stream.hasValue, isFalse);
          expect(stream.errorAndStackTrace.error, error);
          expect(stream.hasError, isTrue);
        },
      );
    });

    test('provide a function to autoconnect that stops listening', () async {
      final stream = Stream.fromIterable(const [1, 2, 3])
          .publishValue()
          .autoConnect(connection: (subscription) => subscription.cancel());

      expect(await stream.isEmpty, true);
    });

    test('refCount cancels source subscription when no listeners remain',
        () async {
      {
        var isCanceled = false;

        final controller =
            StreamController<void>(onCancel: () => isCanceled = true);
        final stream = controller.stream.shareValue();

        StreamSubscription subscription;
        subscription = stream.listen(null);

        await subscription.cancel();
        expect(isCanceled, true);
      }

      {
        var isCanceled = false;

        final controller =
            StreamController<void>(onCancel: () => isCanceled = true);
        final stream = controller.stream.shareValueSeeded(null);

        StreamSubscription subscription;
        subscription = stream.listen(null);

        await subscription.cancel();
        expect(isCanceled, true);
      }
    });

    test('can close shareValue() stream', () async {
      {
        final isCanceled = Completer<void>();

        final controller = StreamController<bool>();
        controller.stream
            .shareValue()
            .doOnCancel(() => isCanceled.complete())
            .listen(null);

        controller.add(true);
        await Future<void>.delayed(Duration.zero);
        await controller.close();

        expect(isCanceled.future, completes);
      }

      {
        final isCanceled = Completer<void>();

        final controller = StreamController<bool>();
        controller.stream
            .shareValueSeeded(false)
            .doOnCancel(() => isCanceled.complete())
            .listen(null);

        controller.add(true);
        await Future<void>.delayed(Duration.zero);
        await controller.close();

        expect(isCanceled.future, completes);
      }
    });
  });
}
