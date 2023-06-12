import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

class MockStream<T> extends Mock implements Stream<T> {}

void main() {
  group('ReplayConnectableStream', () {
    test('should not emit before connecting', () {
      final stream = MockStream<int>();
      final connectableStream = ReplayConnectableStream(stream);

      when(stream.listen(any, onError: anyNamed('onError')))
          .thenReturn(Stream.fromIterable(const [1, 2, 3]).listen(null));

      verifyNever(stream.listen(any,
          onError: anyNamed('onError'), onDone: anyNamed('onDone')));

      connectableStream.connect();

      verify(stream.listen(any,
          onError: anyNamed('onError'), onDone: anyNamed('onDone')));
    });

    test('should begin emitting items after connection', () {
      const items = [1, 2, 3];
      final stream = ReplayConnectableStream(Stream.fromIterable(items));

      stream.connect();

      expect(stream, emitsInOrder(items));
      stream.listen(expectAsync1((int i) {
        expect(stream.values, items.sublist(0, i));
      }, count: items.length));
    });

    test('stops emitting after the connection is cancelled', () async {
      final ConnectableStream<int> stream =
          Stream<int>.fromIterable(<int>[1, 2, 3]).publishReplay();

      stream.connect()..cancel(); // ignore: unawaited_futures

      expect(stream, neverEmits(anything));
    });

    test('stops emitting after the last subscriber unsubscribes', () async {
      final Stream<int> stream =
          Stream<int>.fromIterable(<int>[1, 2, 3]).shareReplay();

      stream.listen(null)..cancel(); // ignore: unawaited_futures

      expect(stream, neverEmits(anything));
    });

    test('keeps emitting with an active subscription', () async {
      final Stream<int> stream =
          Stream<int>.fromIterable(<int>[1, 2, 3]).shareReplay();

      stream.listen(null);
      stream.listen(null)..cancel(); // ignore: unawaited_futures

      expect(stream, emitsInOrder(<int>[1, 2, 3]));
    });

    test('multicasts a single-subscription stream', () async {
      final Stream<int> stream = ReplayConnectableStream<int>(
        Stream<int>.fromIterable(<int>[1, 2, 3]),
      ).autoConnect();

      expect(stream, emitsInOrder(<int>[1, 2, 3]));
      expect(stream, emitsInOrder(<int>[1, 2, 3]));
      expect(stream, emitsInOrder(<int>[1, 2, 3]));
    });

    test('replays the max number of items', () async {
      final Stream<int> stream = ReplayConnectableStream<int>(
        Stream<int>.fromIterable(<int>[1, 2, 3]),
        maxSize: 2,
      ).autoConnect();

      expect(stream, emitsInOrder(<int>[1, 2, 3]));
      expect(stream, emitsInOrder(<int>[1, 2, 3]));
      expect(stream, emitsInOrder(<int>[1, 2, 3]));

      await Future<Null>.delayed(Duration(milliseconds: 200));

      expect(stream, emitsInOrder(<int>[2, 3]));
    });

    test('can multicast streams', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareReplay();

      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
    });

    test('only holds a certain number of values', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareReplay();

      expect(stream.values, const <int>[]);
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
    });

    test('provides access to all items', () async {
      const items = [1, 2, 3];
      var count = 0;
      final stream = Stream.fromIterable(const [1, 2, 3]).shareReplay();

      stream.listen(expectAsync1((int data) {
        expect(data, items[count]);
        count++;
        if (count == items.length) {
          expect(stream.values, items);
        }
      }, count: items.length));
    });

    test('provides access to a certain number of items', () async {
      const items = [1, 2, 3];
      var count = 0;
      final stream =
          Stream.fromIterable(const [1, 2, 3]).shareReplay(maxSize: 2);

      stream.listen(expectAsync1((data) {
        expect(data, items[count]);
        count++;
        if (count == items.length) {
          expect(stream.values, const <int>[2, 3]);
        }
      }, count: items.length));
    });

    test('provide a function to autoconnect that stops listening', () async {
      final stream = Stream.fromIterable(const [1, 2, 3])
          .publishReplay()
          .autoConnect(connection: (subscription) => subscription.cancel());

      expect(await stream.isEmpty, true);
    });

    test('refCount cancels source subscription when no listeners remain',
        () async {
      var isCanceled = false;

      final controller =
          StreamController<void>(onCancel: () => isCanceled = true);
      final stream = controller.stream.shareReplay();

      StreamSubscription subscription;
      subscription = stream.listen(null);

      await subscription.cancel();
      expect(isCanceled, true);
    });

    test('can close shareReplay() stream', () async {
      final isCanceled = Completer<void>();

      final controller = StreamController<bool>();
      controller.stream
          .shareReplay()
          .doOnCancel(() => isCanceled.complete())
          .listen(null);

      controller.add(true);
      await Future<void>.delayed(Duration.zero);
      await controller.close();

      expect(isCanceled.future, completes);
    });
  });
}
