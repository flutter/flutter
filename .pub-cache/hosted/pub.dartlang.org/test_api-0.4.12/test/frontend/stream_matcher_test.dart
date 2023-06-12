// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  setUpAll(() {
    glyph.ascii = true;
  });

  late Stream stream;
  late StreamQueue queue;
  late Stream errorStream;
  late StreamQueue errorQueue;
  setUp(() {
    stream = Stream.fromIterable([1, 2, 3, 4, 5]);
    queue = StreamQueue(Stream.fromIterable([1, 2, 3, 4, 5]));
    errorStream = Stream.fromFuture(Future.error('oh no!', StackTrace.current));
    errorQueue = StreamQueue(
        Stream.fromFuture(Future.error('oh no!', StackTrace.current)));
  });

  group('emits()', () {
    test('matches the first event of a Stream', () {
      expect(stream, emits(1));
    });

    test('rejects the first event of a Stream', () {
      expect(
          expectLater(stream, emits(2)),
          throwsTestFailure(allOf([
            startsWith('Expected: should emit an event that <2>\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n')
          ])));
    });

    test('matches and consumes the next event of a StreamQueue', () {
      expect(queue, emits(1));
      expect(queue.next, completion(equals(2)));
      expect(queue, emits(3));
      expect(queue.next, completion(equals(4)));
    });

    test('rejects and does not consume the first event of a StreamQueue', () {
      expect(
          expectLater(queue, emits(2)),
          throwsTestFailure(allOf([
            startsWith('Expected: should emit an event that <2>\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n')
          ])));

      expect(queue, emits(1));
    });

    test('rejects an empty stream', () {
      expect(
          expectLater(Stream.empty(), emits(1)),
          throwsTestFailure(allOf([
            startsWith('Expected: should emit an event that <1>\n'),
            endsWith('   Which: emitted x Stream closed.\n')
          ])));
    });

    test('forwards a stream error', () {
      expect(expectLater(errorStream, emits(1)), throwsA('oh no!'));
    });

    test('wraps a normal matcher', () {
      expect(queue, emits(lessThan(5)));
      expect(expectLater(queue, emits(greaterThan(5))),
          throwsTestFailure(anything));
    });

    test('returns a StreamMatcher as-is', () {
      expect(queue, emits(emitsThrough(4)));
      expect(queue, emits(5));
    });
  });

  group('emitsDone', () {
    test('succeeds for an empty stream', () {
      expect(Stream.empty(), emitsDone);
    });

    test('fails for a stream with events', () {
      expect(
          expectLater(stream, emitsDone),
          throwsTestFailure(allOf([
            startsWith('Expected: should be done\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n')
          ])));
    });
  });

  group('emitsError()', () {
    test('consumes a matching error', () {
      expect(errorQueue, emitsError('oh no!'));
      expect(errorQueue.hasNext, completion(isFalse));
    });

    test('fails for a non-matching error', () {
      expect(
          expectLater(errorStream, emitsError('oh heck')),
          throwsTestFailure(allOf([
            startsWith("Expected: should emit an error that 'oh heck'\n"),
            contains('   Which: emitted ! oh no!\n'),
            contains('                  x Stream closed.\n'
                "            which threw 'oh no!'\n"
                '                  stack '),
            endsWith('                  which is different.\n'
                '                        Expected: oh heck\n'
                '                          Actual: oh no!\n'
                '                                     ^\n'
                '                         Differ at offset 3\n')
          ])));
    });

    test('fails for a stream with events', () {
      expect(
          expectLater(stream, emitsDone),
          throwsTestFailure(allOf([
            startsWith('Expected: should be done\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n')
          ])));
    });
  });

  group('mayEmit()', () {
    test('consumes a matching event', () {
      expect(queue, mayEmit(1));
      expect(queue, emits(2));
    });

    test('allows a non-matching event', () {
      expect(queue, mayEmit('fish'));
      expect(queue, emits(1));
    });
  });

  group('emitsAnyOf()', () {
    test('consumes an event that matches a matcher', () {
      expect(queue, emitsAnyOf([2, 1, 3]));
      expect(queue, emits(2));
    });

    test('consumes as many events as possible', () {
      expect(
          queue,
          emitsAnyOf([
            1,
            emitsInOrder([1, 2]),
            emitsInOrder([1, 2, 3])
          ]));

      expect(queue, emits(4));
    });

    test('fails if no matchers match', () {
      expect(
          expectLater(stream, emitsAnyOf([2, 3, 4])),
          throwsTestFailure(allOf([
            startsWith('Expected: should do one of the following:\n'
                '          * emit an event that <2>\n'
                '          * emit an event that <3>\n'
                '          * emit an event that <4>\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n'
                '            which failed all options:\n'
                '                  * failed to emit an event that <2>\n'
                '                  * failed to emit an event that <3>\n'
                '                  * failed to emit an event that <4>\n')
          ])));
    });

    test('allows an error if any matcher matches', () {
      expect(errorStream, emitsAnyOf([1, 2, emitsError('oh no!')]));
    });

    test('rethrows an error if no matcher matches', () {
      expect(
          expectLater(errorStream, emitsAnyOf([1, 2, 3])), throwsA('oh no!'));
    });
  });

  group('emitsInOrder()', () {
    test('consumes matching events', () {
      expect(queue, emitsInOrder([1, 2, emitsThrough(4)]));
      expect(queue, emits(5));
    });

    test("fails if the matchers don't match in order", () {
      expect(
          expectLater(queue, emitsInOrder([1, 3, 2])),
          throwsTestFailure(allOf([
            startsWith('Expected: should do the following in order:\n'
                '          * emit an event that <1>\n'
                '          * emit an event that <3>\n'
                '          * emit an event that <2>\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n'
                "            which didn't emit an event that <3>\n")
          ])));
    });
  });

  group('emitsThrough()', () {
    test('consumes events including those matching the matcher', () {
      expect(queue, emitsThrough(emitsInOrder([3, 4])));
      expect(queue, emits(5));
    });

    test('consumes the entire queue with emitsDone', () {
      expect(queue, emitsThrough(emitsDone));
      expect(queue.hasNext, completion(isFalse));
    });

    test('fails if the queue never matches the matcher', () {
      expect(
          expectLater(queue, emitsThrough(6)),
          throwsTestFailure(allOf([
            startsWith('Expected: should eventually emit an event that <6>\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n'
                '            which never did emit an event that <6>\n')
          ])));
    });
  });

  group('mayEmitMultiple()', () {
    test('consumes multiple instances of the given matcher', () {
      expect(queue, mayEmitMultiple(lessThan(3)));
      expect(queue, emits(3));
    });

    test('consumes zero instances of the given matcher', () {
      expect(queue, mayEmitMultiple(6));
      expect(queue, emits(1));
    });

    test("doesn't rethrow errors", () {
      expect(errorQueue, mayEmitMultiple(1));
      expect(errorQueue, emitsError('oh no!'));
    });
  });

  group('neverEmits()', () {
    test('succeeds if the event never matches', () {
      expect(queue, neverEmits(6));
      expect(queue, emits(1));
    });

    test('fails if the event matches', () {
      expect(
          expectLater(stream, neverEmits(4)),
          throwsTestFailure(allOf([
            startsWith('Expected: should never emit an event that <4>\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n'
                '            which after 3 events did emit an event that <4>\n')
          ])));
    });

    test('fails if emitsDone matches', () {
      expect(expectLater(stream, neverEmits(emitsDone)),
          throwsTestFailure(anything));
    });

    test("doesn't rethrow errors", () {
      expect(errorQueue, neverEmits(6));
      expect(errorQueue, emitsError('oh no!'));
    });
  });

  group('emitsInAnyOrder()', () {
    test('consumes events that match in any order', () {
      expect(queue, emitsInAnyOrder([3, 1, 2]));
      expect(queue, emits(4));
    });

    test("fails if the events don't match in any order", () {
      expect(
          expectLater(stream, emitsInAnyOrder([4, 1, 2])),
          throwsTestFailure(allOf([
            startsWith('Expected: should do the following in any order:\n'
                '          * emit an event that <4>\n'
                '          * emit an event that <1>\n'
                '          * emit an event that <2>\n'),
            endsWith('   Which: emitted * 1\n'
                '                  * 2\n'
                '                  * 3\n'
                '                  * 4\n'
                '                  * 5\n'
                '                  x Stream closed.\n')
          ])));
    });

    test("doesn't rethrow if some ordering matches", () {
      expect(errorQueue, emitsInAnyOrder([emitsDone, emitsError('oh no!')]));
    });

    test('rethrows if no ordering matches', () {
      expect(
          expectLater(errorQueue, emitsInAnyOrder([1, emitsError('oh no!')])),
          throwsA('oh no!'));
    });
  });

  test('A custom StreamController doesn\'t hang on close', () async {
    var controller = StreamController<void>();
    var done = expectLater(controller.stream, emits(null));
    controller.add(null);
    await done;
    await controller.close();
  });
}
