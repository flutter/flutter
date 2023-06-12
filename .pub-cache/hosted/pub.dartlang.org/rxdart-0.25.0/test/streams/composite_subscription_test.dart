import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

void main() {
  group('CompositeSubscription', () {
    test('should cancel all subscriptions on clear()', () {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();
      final composite = CompositeSubscription();

      composite
        ..add(stream.listen(null))
        ..add(stream.listen(null))
        ..add(stream.listen(null));

      composite.clear();

      expect(stream, neverEmits(anything));
    });
    test('should cancel all subscriptions on dispose()', () {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();
      final composite = CompositeSubscription();

      composite
        ..add(stream.listen(null))
        ..add(stream.listen(null))
        ..add(stream.listen(null));

      composite.dispose();

      expect(stream, neverEmits(anything));
    });
    test(
        'should throw exception if trying to add subscription to disposed composite',
        () {
      final stream = Stream.fromIterable(const [1, 2, 3]).shareValue();
      final composite = CompositeSubscription();

      composite.dispose();

      expect(() => composite.add(stream.listen(null)), throwsA(anything));
    });
    test('should cancel subscription on if it is removed from composite', () {
      const value = 1;
      final stream = Stream.fromIterable([value]).shareValue();
      final composite = CompositeSubscription();
      final subscription = stream.listen(null);

      composite.add(subscription);
      composite.remove(subscription);

      expect(stream, neverEmits(anything));
    });
    test('Rx.compositeSubscription.addNotNull', () {
      final composite = CompositeSubscription();

      expect(() => composite.add<void>(null),
          throwsA(TypeMatcher<AssertionError>()));
    });
    test('Rx.compositeSubscription.pauseAndResume', () {
      final composite = CompositeSubscription();
      final s1 = Stream.fromIterable(const [1, 2, 3]).listen(null),
          s2 = Stream.fromIterable(const [4, 5, 6]).listen(null);

      composite.add(s1);
      composite.add(s2);
      composite.pauseAll();

      expect(composite.allPaused, isTrue);
      expect(s1.isPaused, isTrue);
      expect(s2.isPaused, isTrue);

      composite.resumeAll();

      expect(composite.allPaused, isFalse);
      expect(s1.isPaused, isFalse);
      expect(s2.isPaused, isFalse);
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

      completer.complete();

      await expectLater(completer.future.then((_) => composite.allPaused),
          completion(isFalse));
    });
    test('Rx.compositeSubscription.allPaused', () {
      final composite = CompositeSubscription();
      final s1 = Stream.fromIterable(const [1, 2, 3]).listen(null),
          s2 = Stream.fromIterable(const [4, 5, 6]).listen(null);

      expect(composite.allPaused, isFalse);

      composite.add(s1);
      composite.add(s2);

      expect(composite.allPaused, isFalse);

      composite.pauseAll();

      expect(composite.allPaused, isTrue);

      composite.remove(s1);
      composite.remove(s2);

      /// all subscriptions are removed, allPaused should yield false
      expect(composite.allPaused, isFalse);
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

      s1.resume();
      s2.resume();

      expect(composite.allPaused, isFalse);
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
