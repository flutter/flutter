// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

void main() {
  group('combineLatest', () {
    test('flows through combine callback', () async {
      var source = StreamController<int>();
      var other = StreamController<int>();
      int sum(int a, int b) => a + b;

      var results = <int>[];
      unawaited(
          source.stream.combineLatest(other.stream, sum).forEach(results.add));

      source.add(1);
      await Future(() {});
      expect(results, isEmpty);

      other.add(2);
      await Future(() {});
      expect(results, [3]);

      source.add(3);
      await Future(() {});
      expect(results, [3, 5]);

      source.add(4);
      await Future(() {});
      expect(results, [3, 5, 6]);

      other.add(5);
      await Future(() {});
      expect(results, [3, 5, 6, 9]);
    });

    test('can combine different typed streams', () async {
      var source = StreamController<String>();
      var other = StreamController<int>();
      String times(String a, int b) => a * b;

      var results = <String>[];
      unawaited(source.stream
          .combineLatest(other.stream, times)
          .forEach(results.add));

      source
        ..add('a')
        ..add('b');
      await Future(() {});
      expect(results, isEmpty);

      other.add(2);
      await Future(() {});
      expect(results, ['bb']);

      other.add(3);
      await Future(() {});
      expect(results, ['bb', 'bbb']);

      source.add('c');
      await Future(() {});
      expect(results, ['bb', 'bbb', 'ccc']);
    });

    test('ends after both streams have ended', () async {
      var source = StreamController<int>();
      var other = StreamController<int>();
      int sum(int a, int b) => a + b;

      var done = false;
      source.stream
          .combineLatest(other.stream, sum)
          .listen(null, onDone: () => done = true);

      source.add(1);

      await source.close();
      await Future(() {});
      expect(done, false);

      await other.close();
      await Future(() {});
      expect(done, true);
    });

    test('ends if source stream closes without ever emitting a value',
        () async {
      var source = const Stream<int>.empty();
      var other = StreamController<int>();

      int sum(int a, int b) => a + b;

      var done = false;
      source
          .combineLatest(other.stream, sum)
          .listen(null, onDone: () => done = true);

      await Future(() {});
      // Nothing can ever be emitted on the result, may as well close.
      expect(done, true);
    });

    test('ends if other stream closes without ever emitting a value', () async {
      var source = StreamController<int>();
      var other = const Stream<int>.empty();

      int sum(int a, int b) => a + b;

      var done = false;
      source.stream
          .combineLatest(other, sum)
          .listen(null, onDone: () => done = true);

      await Future(() {});
      // Nothing can ever be emitted on the result, may as well close.
      expect(done, true);
    });

    test('forwards errors', () async {
      var source = StreamController<int>();
      var other = StreamController<int>();
      int sum(int a, int b) => throw _NumberedException(3);

      var errors = [];
      source.stream
          .combineLatest(other.stream, sum)
          .listen(null, onError: errors.add);

      source.addError(_NumberedException(1));
      other.addError(_NumberedException(2));

      source.add(1);
      other.add(2);

      await Future(() {});

      expect(errors, [_isException(1), _isException(2), _isException(3)]);
    });

    group('broadcast source', () {
      test('can cancel and relisten to broadcast stream', () async {
        var source = StreamController<int>.broadcast();
        var other = StreamController<int>();
        int combine(int a, int b) => a + b;

        var emittedValues = <int>[];
        var transformed = source.stream.combineLatest(other.stream, combine);

        var subscription = transformed.listen(emittedValues.add);

        source.add(1);
        other.add(2);
        await Future(() {});
        expect(emittedValues, [3]);

        await subscription.cancel();

        subscription = transformed.listen(emittedValues.add);
        source.add(3);
        await Future(() {});
        expect(emittedValues, [3, 5]);
      });
    });
  });
}

class _NumberedException implements Exception {
  final int id;
  _NumberedException(this.id);
}

Matcher _isException(int id) =>
    const TypeMatcher<_NumberedException>().having((n) => n.id, 'id', id);
