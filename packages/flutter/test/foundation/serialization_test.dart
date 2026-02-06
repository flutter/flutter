// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Write and read buffer round-trip', () {
    test('of empty buffer', () {
      final write = WriteBuffer();
      final ByteData written = write.done();

      expect(written.lengthInBytes, 0);
    });
    test('of single byte', () {
      final write = WriteBuffer();
      write.putUint8(201);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(1));
      final read = ReadBuffer(written);
      expect(read.getUint8(), equals(201));
    });
    test('of 32-bit integer', () {
      final write = WriteBuffer();
      write.putInt32(-9);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(4));
      final read = ReadBuffer(written);
      expect(read.getInt32(), equals(-9));
    });
    test('of 32-bit integer in big endian', () {
      final write = WriteBuffer();
      write.putInt32(-9, endian: Endian.big);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(4));
      final read = ReadBuffer(written);
      expect(read.getInt32(endian: Endian.big), equals(-9));
    });
    test('of 64-bit integer', () {
      final write = WriteBuffer();
      write.putInt64(-9000000000000);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(8));
      final read = ReadBuffer(written);
      expect(read.getInt64(), equals(-9000000000000));
    }, skip: kIsWeb); // [intended] bigint isn't supported on web.
    test('of 64-bit integer in big endian', () {
      final write = WriteBuffer();
      write.putInt64(-9000000000000, endian: Endian.big);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(8));
      final read = ReadBuffer(written);
      expect(read.getInt64(endian: Endian.big), equals(-9000000000000));
    }, skip: kIsWeb); // [intended] bigint isn't supported on web.
    test('of double', () {
      final write = WriteBuffer();
      write.putFloat64(3.14);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(8));
      final read = ReadBuffer(written);
      expect(read.getFloat64(), equals(3.14));
    });
    test('of double in big endian', () {
      final write = WriteBuffer();
      write.putFloat64(3.14, endian: Endian.big);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(8));
      final read = ReadBuffer(written);
      expect(read.getFloat64(endian: Endian.big), equals(3.14));
    });
    test('of 32-bit int list when unaligned', () {
      final integers = Int32List.fromList(<int>[-99, 2, 99]);
      final write = WriteBuffer();
      write.putUint8(9);
      write.putInt32List(integers);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(16));
      final read = ReadBuffer(written);
      read.getUint8();
      expect(read.getInt32List(3), equals(integers));
    });
    test('of 64-bit int list when unaligned', () {
      final integers = Int64List.fromList(<int>[-99, 2, 99]);
      final write = WriteBuffer();
      write.putUint8(9);
      write.putInt64List(integers);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(32));
      final read = ReadBuffer(written);
      read.getUint8();
      expect(read.getInt64List(3), equals(integers));
    }, skip: kIsWeb); // [intended] bigint isn't supported on web.
    test('of float list when unaligned', () {
      final floats = Float32List.fromList(<double>[3.14, double.nan]);
      final write = WriteBuffer();
      write.putUint8(9);
      write.putFloat32List(floats);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(12));
      final read = ReadBuffer(written);
      read.getUint8();
      final Float32List readFloats = read.getFloat32List(2);
      expect(readFloats[0], closeTo(3.14, 0.0001));
      expect(readFloats[1], isNaN);
    });
    test('of double list when unaligned', () {
      final doubles = Float64List.fromList(<double>[3.14, double.nan]);
      final write = WriteBuffer();
      write.putUint8(9);
      write.putFloat64List(doubles);
      final ByteData written = write.done();
      expect(written.lengthInBytes, equals(24));
      final read = ReadBuffer(written);
      read.getUint8();
      final Float64List readDoubles = read.getFloat64List(2);
      expect(readDoubles[0], equals(3.14));
      expect(readDoubles[1], isNaN);
    });
    test('done twice', () {
      final write = WriteBuffer();
      write.done();
      expect(() => write.done(), throwsStateError);
    });
    test('empty WriteBuffer', () {
      expect(() => WriteBuffer(startCapacity: 0), throwsAssertionError);
    });
    test('size 1', () {
      expect(() => WriteBuffer(startCapacity: 1), returnsNormally);
    });
  });
}
