import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

class MockStream<T> extends Mock implements Stream<T> {}

void main() {
  group('PublishConnectableStream', () {
    test('should not emit before connecting', () {
      final stream = MockStream<int>();
      final connectableStream = PublishConnectableStream(stream);

      when(stream.listen(any, onError: anyNamed('onError')))
          .thenReturn(Stream<int>.fromIterable(const [1, 2, 3]).listen(null));

      verifyNever(stream.listen(any,
          onError: anyNamed('onError'), onDone: anyNamed('onDone')));

      connectableStream.connect();

      verify(stream.listen(any,
          onError: anyNamed('onError'), onDone: anyNamed('onDone')));
    });

    test('should begin emitting items after connection', () {
      final ConnectableStream<int> stream = PublishConnectableStream<int>(
          Stream<int>.fromIterable(<int>[1, 2, 3]));

      stream.connect();

      expect(stream, emitsInOrder(<int>[1, 2, 3]));
    });

    test('stops emitting after the connection is cancelled', () async {
      final ConnectableStream<int> stream =
          Stream<int>.fromIterable(<int>[1, 2, 3]).publishValue();

      stream.connect()..cancel(); // ignore: unawaited_futures

      expect(stream, neverEmits(anything));
    });

    test('multicasts a single-subscription stream', () async {
      final stream = PublishConnectableStream(
        Stream.fromIterable(const [1, 2, 3]),
      ).autoConnect();

      expect(stream, emitsInOrder(<int>[1, 2, 3]));
      expect(stream, emitsInOrder(<int>[1, 2, 3]));
      expect(stream, emitsInOrder(<int>[1, 2, 3]));
    });

    test('can multicast streams', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).publish();

      stream.connect();

      expect(stream, emitsInOrder(<int>[1, 2, 3]));
      expect(stream, emitsInOrder(<int>[1, 2, 3]));
      expect(stream, emitsInOrder(<int>[1, 2, 3]));
    });

    test('refcount automatically connects', () async {
      final stream = Stream.fromIterable(const [1, 2, 3]).share();

      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
      expect(stream, emitsInOrder(const <int>[1, 2, 3]));
    });

    test('provide a function to autoconnect that stops listening', () async {
      final stream = Stream.fromIterable(const [1, 2, 3])
          .publish()
          .autoConnect(connection: (subscription) => subscription.cancel());

      expect(await stream.isEmpty, true);
    });

    test('refCount cancels source subscription when no listeners remain',
        () async {
      var isCanceled = false;

      final controller =
          StreamController<void>(onCancel: () => isCanceled = true);
      final stream = controller.stream.share();

      StreamSubscription subscription;
      subscription = stream.listen(null);

      await subscription.cancel();
      expect(isCanceled, true);
    });

    test('can close share() stream', () async {
      final isCanceled = Completer<void>();

      final controller = StreamController<bool>();
      controller.stream
          .share()
          .doOnCancel(() => isCanceled.complete())
          .listen(null);

      controller.add(true);
      await Future<void>.delayed(Duration.zero);
      await controller.close();

      expect(isCanceled.future, completes);
    });
  });
}
