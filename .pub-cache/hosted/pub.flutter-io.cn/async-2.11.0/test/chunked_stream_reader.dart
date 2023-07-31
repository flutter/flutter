// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:test/test.dart';

void main() {
  test('readChunk() chunk by chunk', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(2), equals([1, 2]));
    expect(await r.readChunk(3), equals([3, 4, 5]));
    expect(await r.readChunk(4), equals([6, 7, 8, 9]));
    expect(await r.readChunk(1), equals([10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() element by element', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    for (var i = 0; i < 10; i++) {
      expect(await r.readChunk(1), equals([i + 1]));
    }
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() exact elements', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(10), equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() past end', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(20), equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() chunks of 2 elements', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(2), equals([1, 2]));
    expect(await r.readChunk(2), equals([3, 4]));
    expect(await r.readChunk(2), equals([5, 6]));
    expect(await r.readChunk(2), equals([7, 8]));
    expect(await r.readChunk(2), equals([9, 10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() chunks of 3 elements', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(3), equals([1, 2, 3]));
    expect(await r.readChunk(3), equals([4, 5, 6]));
    expect(await r.readChunk(3), equals([7, 8, 9]));
    expect(await r.readChunk(3), equals([10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() cancel half way', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(5), equals([1, 2, 3, 4, 5]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() propagates exception', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      throw Exception('stopping here');
    }());

    expect(await r.readChunk(3), equals([1, 2, 3]));
    await expectLater(r.readChunk(3), throwsException);

    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readStream() forwards chunks', () async {
    final chunk2 = [3, 4, 5];
    final chunk3 = [6, 7, 8, 9];
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield chunk2;
      yield chunk3;
      yield [10];
    }());

    expect(await r.readChunk(1), equals([1]));
    final i = StreamIterator(r.readStream(9));
    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([2]));

    // We must forward the exact chunks otherwise it's not efficient!
    // Hence, we have a reference equality check here.
    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([3, 4, 5]));
    expect(i.current == chunk2, isTrue);

    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([6, 7, 8, 9]));
    expect(i.current == chunk3, isTrue);

    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([10]));
    expect(await i.moveNext(), isFalse);

    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readStream() cancel at the exact end', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(1), equals([1]));
    final i = StreamIterator(r.readStream(7));
    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([2]));

    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([3, 4, 5]));

    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([6, 7, 8]));

    await i.cancel(); // cancel substream just as it's ending

    expect(await r.readChunk(2), equals([9, 10]));

    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readStream() cancel at the exact end on chunk boundary', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(1), equals([1]));
    final i = StreamIterator(r.readStream(8));
    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([2]));

    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([3, 4, 5]));

    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([6, 7, 8, 9]));

    await i.cancel(); // cancel substream just as it's ending

    expect(await r.readChunk(2), equals([10]));

    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readStream() is drained when canceled', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(1), equals([1]));
    final i = StreamIterator(r.readStream(7));
    expect(await i.moveNext(), isTrue);
    expect(i.current, equals([2]));
    // Cancelling here should skip the remainder of the substream
    // and we continue to read 9 and 10 from r
    await i.cancel();

    expect(await r.readChunk(2), equals([9, 10]));

    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readStream() concurrent reads is forbidden', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(1), equals([1]));
    // Notice we are not reading this substream:
    r.readStream(7);

    expectLater(r.readChunk(2), throwsStateError);
  });

  test('readStream() supports draining', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(1), equals([1]));
    await r.readStream(7).drain();
    expect(await r.readChunk(2), equals([9, 10]));

    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('nested ChunkedStreamReader', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readChunk(1), equals([1]));
    final r2 = ChunkedStreamReader(r.readStream(7));
    expect(await r2.readChunk(2), equals([2, 3]));
    expect(await r2.readChunk(1), equals([4]));
    await r2.cancel();

    expect(await r.readChunk(2), equals([9, 10]));

    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readBytes() chunks of 3 elements', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2];
      yield [3, 4, 5];
      yield [6, 7, 8, 9];
      yield [10];
    }());

    expect(await r.readBytes(3), allOf(equals([1, 2, 3]), isA<Uint8List>()));
    expect(await r.readBytes(3), allOf(equals([4, 5, 6]), isA<Uint8List>()));
    expect(await r.readBytes(3), allOf(equals([7, 8, 9]), isA<Uint8List>()));
    expect(await r.readBytes(3), allOf(equals([10]), isA<Uint8List>()));
    expect(await r.readBytes(1), equals([]));
    expect(await r.readBytes(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readBytes(1), equals([]));
  });

  test('readChunk() until exact end of stream', () async {
    final stream = Stream.fromIterable(Iterable.generate(
      10,
      (_) => Uint8List(512),
    ));

    final r = ChunkedStreamReader(stream);
    while (true) {
      final c = await r.readBytes(1024);
      if (c.isEmpty) {
        break;
      }
    }
  });

  test('cancel while readChunk() is pending', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2, 3];
      // This will hang forever, so we will call cancel()
      await Completer().future;
      yield [4]; // this should never be reachable
      fail('unreachable!');
    }());

    expect(await r.readBytes(2), equals([1, 2]));

    final future = r.readChunk(2);

    // Wait a tiny bit and cancel
    await Future.microtask(() => null);
    r.cancel();

    expect(await future, hasLength(lessThan(2)));
  });

  test('cancel while readStream() is pending', () async {
    final r = ChunkedStreamReader(() async* {
      yield [1, 2, 3];
      // This will hang forever, so we will call cancel()
      await Completer().future;
      yield [4]; // this should never be reachable
      fail('unreachable!');
    }());

    expect(await collectBytes(r.readStream(2)), equals([1, 2]));

    final stream = r.readStream(2);

    // Wait a tiny bit and cancel
    await Future.microtask(() => null);
    r.cancel();

    expect(await collectBytes(stream), hasLength(lessThan(2)));
  });

  test('readChunk() chunk by chunk (Uint8List)', () async {
    final r = ChunkedStreamReader(() async* {
      yield Uint8List.fromList([1, 2]);
      yield Uint8List.fromList([3, 4, 5]);
      yield Uint8List.fromList([6, 7, 8, 9]);
      yield Uint8List.fromList([10]);
    }());

    expect(await r.readChunk(2), equals([1, 2]));
    expect(await r.readChunk(3), equals([3, 4, 5]));
    expect(await r.readChunk(4), equals([6, 7, 8, 9]));
    expect(await r.readChunk(1), equals([10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() element by element (Uint8List)', () async {
    final r = ChunkedStreamReader(() async* {
      yield Uint8List.fromList([1, 2]);
      yield Uint8List.fromList([3, 4, 5]);
      yield Uint8List.fromList([6, 7, 8, 9]);
      yield Uint8List.fromList([10]);
    }());

    for (var i = 0; i < 10; i++) {
      expect(await r.readChunk(1), equals([i + 1]));
    }
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() exact elements (Uint8List)', () async {
    final r = ChunkedStreamReader(() async* {
      yield Uint8List.fromList([1, 2]);
      yield Uint8List.fromList([3, 4, 5]);
      yield Uint8List.fromList([6, 7, 8, 9]);
      yield Uint8List.fromList([10]);
    }());

    expect(await r.readChunk(10), equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() past end (Uint8List)', () async {
    final r = ChunkedStreamReader(() async* {
      yield Uint8List.fromList([1, 2]);
      yield Uint8List.fromList([3, 4, 5]);
      yield Uint8List.fromList([6, 7, 8, 9]);
      yield Uint8List.fromList([10]);
    }());

    expect(await r.readChunk(20), equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() chunks of 2 elements (Uint8List)', () async {
    final r = ChunkedStreamReader(() async* {
      yield Uint8List.fromList([1, 2]);
      yield Uint8List.fromList([3, 4, 5]);
      yield Uint8List.fromList([6, 7, 8, 9]);
      yield Uint8List.fromList([10]);
    }());

    expect(await r.readChunk(2), equals([1, 2]));
    expect(await r.readChunk(2), equals([3, 4]));
    expect(await r.readChunk(2), equals([5, 6]));
    expect(await r.readChunk(2), equals([7, 8]));
    expect(await r.readChunk(2), equals([9, 10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });

  test('readChunk() chunks of 3 elements (Uint8List)', () async {
    final r = ChunkedStreamReader(() async* {
      yield Uint8List.fromList([1, 2]);
      yield Uint8List.fromList([3, 4, 5]);
      yield Uint8List.fromList([6, 7, 8, 9]);
      yield Uint8List.fromList([10]);
    }());

    expect(await r.readChunk(3), equals([1, 2, 3]));
    expect(await r.readChunk(3), equals([4, 5, 6]));
    expect(await r.readChunk(3), equals([7, 8, 9]));
    expect(await r.readChunk(3), equals([10]));
    expect(await r.readChunk(1), equals([]));
    expect(await r.readChunk(1), equals([]));
    await r.cancel(); // check this is okay!
    expect(await r.readChunk(1), equals([]));
  });
}
