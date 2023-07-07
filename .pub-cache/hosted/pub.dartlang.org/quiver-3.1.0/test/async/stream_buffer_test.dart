// Copyright 2014 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.async.stream_buffer_test;

import 'package:quiver/src/async/stream_buffer.dart';
import 'package:test/test.dart';

void main() {
  group('StreamBuffer', () {
    test('returns orderly overlaps', () {
      StreamBuffer<int> buf = StreamBuffer();
      Stream.fromIterable([
        [1],
        [2, 3, 4],
        [5, 6, 7, 8]
      ]).pipe(buf);
      return Future.wait([buf.read(2), buf.read(4), buf.read(2)]).then((vals) {
        expect(vals[0], equals([1, 2]));
        expect(vals[1], equals([3, 4, 5, 6]));
        expect(vals[2], equals([7, 8]));
      }).then((_) {
        buf.close();
      });
    }, tags: ['fails-on-dartdevc']);

    test('respects pausing of stream', () {
      StreamBuffer<int> buf = StreamBuffer()..limit = 2;
      Stream.fromIterable([
        [1],
        [2],
        [3],
        [4]
      ]).pipe(buf);
      return buf.read(2).then((val) {
        expect(val, [1, 2]);
      }).then((_) {
        return buf.read(2);
      }).then((val) {
        expect(val, [3, 4]);
      });
    }, tags: ['fails-on-dartdevc']);

    test('throws when reading too much', () {
      StreamBuffer<int> buf = StreamBuffer()..limit = 1;
      Stream.fromIterable([
        [1],
        [2]
      ]).pipe(buf);
      try {
        buf.read(2);
      } catch (e) {
        expect(e, isArgumentError);
        return;
      }
      fail('error not thrown when reading more data than buffer limit');
    });

    test('allows patching of streams', () {
      StreamBuffer<int> buf = StreamBuffer();
      Stream.fromIterable([
        [1, 2]
      ]).pipe(buf).then((_) {
        return Stream.fromIterable([
          [3, 4]
        ]).pipe(buf);
      });
      return Future.wait([buf.read(1), buf.read(2), buf.read(1)]).then((vals) {
        expect(vals[0], equals([1]));
        expect(vals[1], equals([2, 3]));
        expect(vals[2], equals([4]));
      });
    });

    test('underflows when asked to', () async {
      StreamBuffer<int> buf = StreamBuffer(throwOnError: true);
      Future<List<int>> futureBytes = buf.read(4);
      Stream.fromIterable([
        [1, 2, 3]
      ]).pipe(buf);
      try {
        List<int> bytes = await futureBytes;
        fail('should not have gotten bytes: $bytes');
      } catch (e) {
        expect(e is UnderflowError, isTrue, reason: '!UnderflowError: $e');
      }
    });

    test('accepts several streams', () async {
      StreamBuffer<int> buf = StreamBuffer();
      Stream.fromIterable([
        [1]
      ]).pipe(buf);
      Stream.fromIterable([
        [2, 3, 4, 5]
      ]).pipe(buf);
      final vals = await buf.read(4);
      expect(vals, equals([2, 3, 4, 5]));
      buf.close();
    });
  });
}
