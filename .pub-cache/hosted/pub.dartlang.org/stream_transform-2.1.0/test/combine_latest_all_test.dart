// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/stream_transform.dart';
import 'package:test/test.dart';

Future<void> tick() => Future(() {});

void main() {
  group('combineLatestAll', () {
    test('emits latest values', () async {
      final first = StreamController<String>();
      final second = StreamController<String>();
      final third = StreamController<String>();
      final combined = first.stream.combineLatestAll(
          [second.stream, third.stream]).map((data) => data.join());

      // first:    a----b------------------c--------d---|
      // second:   --1---------2-----------------|
      // third:    -------&----------%---|
      // combined: -------b1&--b2&---b2%---c2%------d2%-|

      expect(combined,
          emitsInOrder(['b1&', 'b2&', 'b2%', 'c2%', 'd2%', emitsDone]));

      first.add('a');
      await tick();
      second.add('1');
      await tick();
      first.add('b');
      await tick();
      third.add('&');
      await tick();
      second.add('2');
      await tick();
      third.add('%');
      await tick();
      await third.close();
      await tick();
      first.add('c');
      await tick();
      await second.close();
      await tick();
      first.add('d');
      await tick();
      await first.close();
    });

    test('ends if a Stream closes without ever emitting a value', () async {
      final first = StreamController<String>();
      final second = StreamController<String>();
      final combined = first.stream.combineLatestAll([second.stream]);

      // first:    -a------b-------|
      // second:   -----|
      // combined: -----|

      expect(combined, emits(emitsDone));

      first.add('a');
      await tick();
      await second.close();
      await tick();
      first.add('b');
    });

    test('forwards errors', () async {
      final first = StreamController<String>();
      final second = StreamController<String>();
      final combined = first.stream
          .combineLatestAll([second.stream]).map((data) => data.join());

      // first:    -a---------|
      // second:   ----1---#
      // combined: ----a1--#

      expect(combined, emitsThrough(emitsError('doh')));

      first.add('a');
      await tick();
      second.add('1');
      await tick();
      second.addError('doh');
    });

    test('ends after both streams have ended', () async {
      final first = StreamController<String>();
      final second = StreamController<String>();

      var done = false;
      first.stream.combineLatestAll([second.stream]).listen(null,
          onDone: () => done = true);

      // first:    -a---|
      // second:   --------1--|
      // combined: --------a1-|

      first.add('a');
      await tick();
      await first.close();
      await tick();

      expect(done, isFalse);

      second.add('1');
      await tick();
      await second.close();
      await tick();

      expect(done, isTrue);
    });

    group('broadcast source', () {
      test('can cancel and relisten to broadcast stream', () async {
        final first = StreamController<String>.broadcast();
        final second = StreamController<String>.broadcast();
        final combined = first.stream
            .combineLatestAll([second.stream]).map((data) => data.join());

        // first:    a------b----------------c------d----e---|
        // second:   --1---------2---3---4------5-|
        // combined: --a1---b1---b2--b3--b4-----c5--d5---e5--|
        // sub1:     ^-----------------!
        // sub2:     ----------------------^-----------------|

        expect(combined.take(4), emitsInOrder(['a1', 'b1', 'b2', 'b3']));

        first.add('a');
        await tick();
        second.add('1');
        await tick();
        first.add('b');
        await tick();
        second.add('2');
        await tick();
        second.add('3');
        await tick();

        // First subscription is canceled here by .take(4)
        expect(first.hasListener, isFalse);
        expect(second.hasListener, isFalse);

        // This emit is thrown away because there are no subscribers
        second.add('4');
        await tick();

        expect(combined, emitsInOrder(['c5', 'd5', 'e5', emitsDone]));

        first.add('c');
        await tick();
        second.add('5');
        await tick();
        await second.close();
        await tick();
        first.add('d');
        await tick();
        first.add('e');
        await tick();
        await first.close();
      });
    });
  });
}
