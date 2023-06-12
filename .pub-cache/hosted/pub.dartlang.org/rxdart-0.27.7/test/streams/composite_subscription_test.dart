import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('CompositeSubscription', () {
    test('cast to StreamSubscription of any type', () {
      final cs = CompositeSubscription();

      expect(cs, isA<StreamSubscription<void>>());
      // ignore: prefer_void_to_null
      expect(cs, isA<StreamSubscription<Null>>());
      expect(cs, isA<StreamSubscription<int>>());
      expect(cs, isA<StreamSubscription<int?>>());
      expect(cs, isA<StreamSubscription<Object>>());
      expect(cs, isA<StreamSubscription<Object?>>());

      cs as StreamSubscription<void>; // ignore: unnecessary_cast
      // ignore: unnecessary_cast, prefer_void_to_null
      cs as StreamSubscription<Null>;
      cs as StreamSubscription<int>; // ignore: unnecessary_cast
      cs as StreamSubscription<int?>; // ignore: unnecessary_cast
      cs as StreamSubscription<Object>; // ignore: unnecessary_cast
      cs as StreamSubscription<Object?>; // ignore: unnecessary_cast

      expect(true, true);
    });

    group('throws UnsupportedError', () {
      test('when calling asFuture()', () {
        expect(
            () => CompositeSubscription().asFuture(0), throwsUnsupportedError);
      });

      test('when calling onData()', () {
        expect(() => CompositeSubscription().onData((_) {}),
            throwsUnsupportedError);
      });

      test('when calling onError()', () {
        expect(() => CompositeSubscription().onError((Object _) {}),
            throwsUnsupportedError);
      });

      test('when calling onDone()', () {
        expect(() => CompositeSubscription().onDone(() {}),
            throwsUnsupportedError);
      });
    });

    group('Rx.compositeSubscription.clear', () {
      test('should cancel all subscriptions', () {
        final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();
        final composite = CompositeSubscription();

        composite
          ..add(stream.listen(null))
          ..add(stream.listen(null))
          ..add(stream.listen(null));

        final done = composite.clear();

        expect(stream, neverEmits(anything));
        expect(done, isA<Future>());
      });

      test(
        'should return null since no subscription has been canceled clear()',
        () {
          final composite = CompositeSubscription();
          final done = composite.clear();
          expect(done, null);
        },
      );
    });

    group('Rx.compositeSubscription.onDispose', () {
      test('should cancel all subscriptions when calling dispose()', () {
        final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();
        final composite = CompositeSubscription();

        composite
          ..add(stream.listen(null))
          ..add(stream.listen(null))
          ..add(stream.listen(null));

        final done = composite.dispose();

        expect(stream, neverEmits(anything));
        expect(done, isA<Future>());
      });

      test('should cancel all subscriptions when calling cancel()', () {
        final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();
        final composite = CompositeSubscription();

        composite
          ..add(stream.listen(null))
          ..add(stream.listen(null))
          ..add(stream.listen(null));

        final done = composite.cancel();

        expect(stream, neverEmits(anything));
        expect(done, isA<Future>());
      });

      test(
        'should return null since no subscription has been canceled on dispose()',
        () {
          final composite = CompositeSubscription();
          final done = composite.dispose();
          expect(done, null);
        },
      );

      test(
        'should return Future completed with null since no subscription has been canceled on cancel()',
        () {
          final composite = CompositeSubscription();
          final done = composite.cancel();
          expect(done, completion(null));
        },
      );

      test(
        'should throw exception if trying to add subscription to disposed composite, after calling dispose()',
        () {
          final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();
          final composite = CompositeSubscription();

          composite.dispose();

          expect(() => composite.add(stream.listen(null)), throwsA(anything));
        },
      );

      test(
        'should throw exception if trying to add subscription to disposed composite, after calling cancel()',
        () {
          final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();
          final composite = CompositeSubscription();

          composite.cancel();

          expect(() => composite.add(stream.listen(null)), throwsA(anything));
        },
      );
    });

    group('Rx.compositeSubscription.remove', () {
      test('should cancel subscription on if it is removed from composite', () {
        const value = 1;
        final stream = Stream.fromIterable([value]).shareValue();
        final composite = CompositeSubscription();
        final subscription = stream.listen(null);

        composite.add(subscription);
        final done = composite.remove(subscription);

        expect(stream, neverEmits(anything));
        expect(done, isA<Future>());
      });

      test(
        'should not cancel the subscription since it is not present in the composite',
        () {
          const value = 1;
          final stream = Stream.fromIterable([value]).shareValue();
          final composite = CompositeSubscription();
          final subscription = stream.listen(null);

          final done = composite.remove(subscription);

          expect(stream, emits(anything));
          expect(done, null);
        },
      );
    });

    test('Rx.compositeSubscription.pauseAndResume()', () {
      final composite = CompositeSubscription();
      final s1 = Stream.fromIterable(const [1, 2, 3]).listen(null),
          s2 = Stream.fromIterable(const [4, 5, 6]).listen(null);

      composite.add(s1);
      composite.add(s2);

      void expectPaused() {
        expect(composite.allPaused, isTrue);
        expect(composite.isPaused, isTrue);

        expect(s1.isPaused, isTrue);
        expect(s2.isPaused, isTrue);
      }

      void expectResumed() {
        expect(composite.allPaused, isFalse);
        expect(composite.isPaused, isFalse);

        expect(s1.isPaused, isFalse);
        expect(s2.isPaused, isFalse);
      }

      composite.pauseAll();

      expectPaused();

      composite.resumeAll();

      expectResumed();

      composite.pause();

      expectPaused();

      composite.resume();

      expectResumed();
    });

    test('Rx.compositeSubscription.resumeWithFuture', () async {
      final composite = CompositeSubscription();
      final s1 = Stream.fromIterable(const [1, 2, 3]).listen(null),
          s2 = Stream.fromIterable(const [4, 5, 6]).listen(null);
      final completer = Completer<void>();

      composite.add(s1);
      composite.add(s2);
      composite.pauseAll(completer.future);

      expect(composite.allPaused, isTrue);
      expect(composite.isPaused, isTrue);

      completer.complete();

      await expectLater(completer.future.then((_) => composite.allPaused),
          completion(isFalse));
      await expectLater(completer.future.then((_) => composite.isPaused),
          completion(isFalse));
    });

    test('Rx.compositeSubscription.allPaused', () {
      final composite = CompositeSubscription();
      final s1 = Stream.fromIterable(const [1, 2, 3]).listen(null),
          s2 = Stream.fromIterable(const [4, 5, 6]).listen(null);

      expect(composite.allPaused, isFalse);
      expect(composite.isPaused, isFalse);

      composite.add(s1);
      composite.add(s2);

      expect(composite.allPaused, isFalse);
      expect(composite.isPaused, isFalse);

      composite.pauseAll();

      expect(composite.allPaused, isTrue);
      expect(composite.isPaused, isTrue);

      composite.remove(s1);
      composite.remove(s2);

      /// all subscriptions are removed, allPaused should yield false
      expect(composite.allPaused, isFalse);
      expect(composite.isPaused, isFalse);
    });

    test('Rx.compositeSubscription.allPaused.indirectly', () {
      final composite = CompositeSubscription();
      final s1 = Stream.fromIterable(const [1, 2, 3]).listen(null),
          s2 = Stream.fromIterable(const [4, 5, 6]).listen(null);

      s1.pause();
      s2.pause();

      composite.add(s1);
      composite.add(s2);

      expect(composite.allPaused, isTrue);
      expect(composite.isPaused, isTrue);

      s1.resume();
      s2.resume();

      expect(composite.allPaused, isFalse);
      expect(composite.isPaused, isFalse);
    });

    test('Rx.compositeSubscription.size', () {
      final composite = CompositeSubscription();
      final s1 = Stream.fromIterable(const [1, 2, 3]).listen(null),
          s2 = Stream.fromIterable(const [4, 5, 6]).listen(null);

      expect(composite.isEmpty, isTrue);
      expect(composite.isNotEmpty, isFalse);
      expect(composite.length, 0);

      composite.add(s1);
      composite.add(s2);

      expect(composite.isEmpty, isFalse);
      expect(composite.isNotEmpty, isTrue);
      expect(composite.length, 2);

      composite.remove(s1);
      composite.remove(s2);

      expect(composite.isEmpty, isTrue);
      expect(composite.isNotEmpty, isFalse);
      expect(composite.length, 0);
    });
  });
}
