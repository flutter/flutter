// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('!vm')
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:typed_data/src/typed_buffer.dart';

const List<int> browserSafeIntSamples = [
  0x8000000000000000, // 2^63
  0x100000001,
  0x100000000, // 2^32
  0x0ffffffff,
  0xaaaaaaaa,
  0x80000001,
  0x80000000, // 2^31
  0x7fffffff,
  0x55555555,
  0x10001,
  0x10000, // 2^16
  0x0ffff,
  0xaaaa,
  0x8001,
  0x8000, // 2^15
  0x7fff,
  0x5555,
  0x101,
  0x100, // 2^8
  0x0ff,
  0xaa,
  0x81,
  0x80, // 2^7
  0x7f,
  0x55,
  0x02,
  0x01,
  0x00
];

void main() {
  initTests(browserSafeIntSamples);
}

void initTests(List<int> intSamples) {
  testUint(intSamples, 8, (l) => Uint8Buffer(l));
  testInt(intSamples, 8, (l) => Int8Buffer(l));
  test('Uint8ClampedBuffer', () {
    testIntBuffer(
        intSamples, 8, 0, 255, (l) => Uint8ClampedBuffer(l), clampUint8);
  });
  testUint(intSamples, 16, (l) => Uint16Buffer(l));
  testInt(intSamples, 16, (l) => Int16Buffer(l));
  testUint(intSamples, 32, (l) => Uint32Buffer(l));

  testInt(intSamples, 32, (l) => Int32Buffer(l));

  testUint(intSamples, 64, (l) => Uint64Buffer(l),
      // JS doesn't support 64-bit ints, so only test this on the VM.
      testOn: 'dart-vm');
  testInt(intSamples, 64, (l) => Int64Buffer(l),
      // JS doesn't support 64-bit ints, so only test this on the VM.
      testOn: 'dart-vm');

  testInt32x4Buffer(intSamples);

  var roundedFloatSamples = floatSamples.map(roundToFloat).toList();
  testFloatBuffer(32, roundedFloatSamples, () => Float32Buffer(), roundToFloat);
  testFloatBuffer(64, doubleSamples, () => Float64Buffer(), (x) => x);

  testFloat32x4Buffer(roundedFloatSamples);

  group('addAll', () {
    for (var type in ['a list', 'an iterable']) {
      group('with $type', () {
        late Iterable<int> source;
        late Uint8Buffer buffer;
        setUp(() {
          source = [1, 2, 3, 4, 5];
          if (type == 'an iterable') {
            source = (source as List<int>).reversed.toList().reversed;
          }
          buffer = Uint8Buffer();
        });

        test('adds values to the buffer', () {
          buffer.addAll(source, 1, 4);
          expect(buffer, equals([2, 3, 4]));

          buffer.addAll(source, 4);
          expect(buffer, equals([2, 3, 4, 5]));

          buffer.addAll(source, 0, 1);
          expect(buffer, equals([2, 3, 4, 5, 1]));
        });

        test('does nothing for empty slices', () {
          buffer.addAll([6, 7, 8, 9, 10]);

          buffer.addAll(source, 0, 0);
          expect(buffer, equals([6, 7, 8, 9, 10]));

          buffer.addAll(source, 3, 3);
          expect(buffer, equals([6, 7, 8, 9, 10]));

          buffer.addAll(source, 5);
          expect(buffer, equals([6, 7, 8, 9, 10]));

          buffer.addAll(source, 5, 5);
          expect(buffer, equals([6, 7, 8, 9, 10]));
        });

        test('throws errors for invalid start and end', () {
          expect(() => buffer.addAll(source, -1), throwsRangeError);
          expect(() => buffer.addAll(source, -1, 2), throwsRangeError);
          expect(() => buffer.addAll(source, 10), throwsStateError);
          expect(() => buffer.addAll(source, 10, 11), throwsStateError);
          expect(() => buffer.addAll(source, 3, 2), throwsRangeError);
          expect(() => buffer.addAll(source, 3, 10), throwsStateError);
          expect(() => buffer.addAll(source, 3, -1), throwsRangeError);
        });
      });
    }
  });

  group('insertAll', () {
    for (var type in ['a list', 'an iterable']) {
      group('with $type', () {
        late Iterable<int> source;
        late Uint8Buffer buffer;
        setUp(() {
          source = [1, 2, 3, 4, 5];
          if (type == 'an iterable') {
            source = (source as List<int>).reversed.toList().reversed;
          }
          buffer = Uint8Buffer()..addAll([6, 7, 8, 9, 10]);
        });

        test('inserts values into the buffer', () {
          buffer.insertAll(0, source, 1, 4);
          expect(buffer, equals([2, 3, 4, 6, 7, 8, 9, 10]));

          buffer.insertAll(3, source, 4);
          expect(buffer, equals([2, 3, 4, 5, 6, 7, 8, 9, 10]));

          buffer.insertAll(5, source, 0, 1);
          expect(buffer, equals([2, 3, 4, 5, 6, 1, 7, 8, 9, 10]));
        });

        // Regression test for #1.
        test('inserts values into the buffer after removeRange()', () {
          buffer.removeRange(1, 4);
          buffer.insertAll(1, source);
          expect(buffer, equals([6, 1, 2, 3, 4, 5, 10]));
        });

        test('does nothing for empty slices', () {
          buffer.insertAll(1, source, 0, 0);
          expect(buffer, equals([6, 7, 8, 9, 10]));

          buffer.insertAll(2, source, 3, 3);
          expect(buffer, equals([6, 7, 8, 9, 10]));

          buffer.insertAll(3, source, 5);
          expect(buffer, equals([6, 7, 8, 9, 10]));

          buffer.insertAll(4, source, 5, 5);
          expect(buffer, equals([6, 7, 8, 9, 10]));
        });

        test('throws errors for invalid start and end', () {
          expect(() => buffer.insertAll(-1, source), throwsRangeError);
          expect(() => buffer.insertAll(6, source), throwsRangeError);
          expect(() => buffer.insertAll(1, source, -1), throwsRangeError);
          expect(() => buffer.insertAll(2, source, -1, 2), throwsRangeError);
          expect(() => buffer.insertAll(3, source, 10), throwsStateError);
          expect(() => buffer.insertAll(4, source, 10, 11), throwsStateError);
          expect(() => buffer.insertAll(5, source, 3, 2), throwsRangeError);
          expect(() => buffer.insertAll(1, source, 3, 10), throwsStateError);
          expect(() => buffer.insertAll(2, source, 3, -1), throwsRangeError);
        });
      });
    }
  });
}

const doubleSamples = [
  0.0,
  5e-324, //                  Minimal denormal value.
  2.225073858507201e-308, //  Maximal denormal value.
  2.2250738585072014e-308, // Minimal normal value.
  0.9999999999999999, //      Maximum value < 1.
  1.0,
  1.0000000000000002, //      Minimum value > 1.
  4294967295.0, //            2^32 -1.
  4294967296.0, //            2^32.
  4503599627370495.5, //      Maximal fractional value.
  9007199254740992.0, //      Maximal exact value (adding one gets lost).
  1.7976931348623157e+308, // Maximal value.
  1.0 / 0.0, //               Infinity.
  0.0 / 0.0, //               NaN.
  0.49999999999999994, //     Round-traps 1-3 (adding 0.5 and rounding towards
  4503599627370497.0, //      minus infinity will not be the same as rounding
  9007199254740991.0 //       to nearest with 0.5 rounding up).
];

const floatSamples = [
  0.0,
  1.4e-45, //        Minimal denormal value.
  1.1754942E-38, //  Maximal denormal value.
  1.17549435E-38, // Minimal normal value.
  0.99999994, //     Maximal value < 1.
  1.0,
  1.0000001, //      Minimal value > 1.
  8388607.5, //      Maximal fractional value.
  16777216.0, //     Maximal exact value.
  3.4028235e+38, //  Maximal value.
  1.0 / 0.0, //      Infinity.
  0.0 / 0.0, //      NaN.
  0.99999994, //     Round traps 1-3.
  8388609.0,
  16777215.0
];

int clampUint8(int x) => x < 0
    ? 0
    : x > 255
        ? 255
        : x;

void doubleEqual(num x, num y) {
  if (y.isNaN) {
    expect(x.isNaN, isTrue);
  } else {
    expect(x, equals(y));
  }
}

Rounder intRounder(int bits) {
  var highBit = 1 << (bits - 1);
  var mask = highBit - 1;
  return (int x) => (x & mask) - (x & highBit);
}

double roundToFloat(double value) {
  return (Float32List(1)..[0] = value)[0];
}

void testFloat32x4Buffer(List<double> floatSamples) {
  var float4Samples = <Float32x4>[];
  for (var i = 0; i < floatSamples.length - 3; i++) {
    float4Samples.add(Float32x4(floatSamples[i], floatSamples[i + 1],
        floatSamples[i + 2], floatSamples[i + 3]));
  }

  void floatEquals(num x, num y) {
    if (y.isNaN) {
      expect(x.isNaN, isTrue);
    } else {
      expect(x, equals(y));
    }
  }

  void x4Equals(Float32x4 x, Float32x4 y) {
    floatEquals(x.x, y.x);
    floatEquals(x.y, y.y);
    floatEquals(x.z, y.z);
    floatEquals(x.w, y.w);
  }

  test('Float32x4Buffer', () {
    var buffer = Float32x4Buffer(5);
    expect(buffer, const TypeMatcher<List<Float32x4>>());

    expect(buffer.length, equals(5));
    expect(buffer.elementSizeInBytes, equals(128 ~/ 8));
    expect(buffer.lengthInBytes, equals(5 * 128 ~/ 8));
    expect(buffer.offsetInBytes, equals(0));

    x4Equals(buffer[0], Float32x4.zero());
    buffer.length = 0;
    expect(buffer.length, equals(0));

    for (var sample in float4Samples) {
      buffer.add(sample);
      x4Equals(buffer[buffer.length - 1], sample);
    }
    expect(buffer.length, equals(float4Samples.length));

    buffer.addAll(float4Samples);
    expect(buffer.length, equals(float4Samples.length * 2));
    for (var i = 0; i < float4Samples.length; i++) {
      x4Equals(buffer[i], buffer[float4Samples.length + i]);
    }

    buffer.removeRange(4, 4 + float4Samples.length);
    for (var i = 0; i < float4Samples.length; i++) {
      x4Equals(buffer[i], float4Samples[i]);
    }

    // Test underlying buffer.
    buffer.length = 1;
    buffer[0] = float4Samples[0]; // Does not contain NaN.

    var floats = Float32List.view(buffer.buffer);
    expect(floats[0], equals(buffer[0].x));
    expect(floats[1], equals(buffer[0].y));
    expect(floats[2], equals(buffer[0].z));
    expect(floats[3], equals(buffer[0].w));
  });
}

// Takes bit-size, min value, max value, function to create a buffer, and
// the rounding that is applied when storing values outside the valid range
// into the buffer.
void testFloatBuffer(
  int bitSize,
  List<double> samples,
  TypedDataBuffer<double> Function() create,
  double Function(double v) round,
) {
  test('Float${bitSize}Buffer', () {
    var buffer = create();
    expect(buffer, const TypeMatcher<List<double>>());
    var byteSize = bitSize ~/ 8;

    expect(buffer.length, equals(0));
    buffer.add(0.0);
    expect(buffer.length, equals(1));
    expect(buffer.removeLast(), equals(0.0));
    expect(buffer.length, equals(0));

    for (var value in samples) {
      buffer.add(value);
      doubleEqual(buffer[buffer.length - 1], round(value));
    }
    expect(buffer.length, equals(samples.length));

    buffer.addAll(samples);
    expect(buffer.length, equals(samples.length * 2));
    for (var i = 0; i < samples.length; i++) {
      doubleEqual(buffer[i], buffer[samples.length + i]);
    }

    buffer.removeRange(samples.length, buffer.length);
    expect(buffer.length, equals(samples.length));

    buffer.insertAll(0, samples);
    expect(buffer.length, equals(samples.length * 2));
    for (var i = 0; i < samples.length; i++) {
      doubleEqual(buffer[i], buffer[samples.length + i]);
    }

    buffer.length = samples.length;
    expect(buffer.length, equals(samples.length));

    // TypedData.
    expect(buffer.elementSizeInBytes, equals(byteSize));
    expect(buffer.lengthInBytes, equals(byteSize * buffer.length));
    expect(buffer.offsetInBytes, equals(0));

    // Accessing the buffer works.
    // Accessing the underlying buffer works.
    buffer.length = 2;
    buffer[0] = samples[0];
    buffer[1] = samples[1];
    var bytes = Uint8List.view(buffer.buffer);
    for (var i = 0; i < byteSize; i++) {
      var tmp = bytes[i];
      bytes[i] = bytes[byteSize + i];
      bytes[byteSize + i] = tmp;
    }
    doubleEqual(buffer[0], round(samples[1]));
    doubleEqual(buffer[1], round(samples[0]));
  });
}

void testInt(
  List<int> intSamples,
  int bits,
  TypedDataBuffer<int> Function(int length) buffer, {
  String? testOn,
}) {
  var min = -(1 << (bits - 1));
  var max = -(min + 1);
  test('Int${bits}Buffer', () {
    testIntBuffer(intSamples, bits, min, max, buffer, intRounder(bits));
  }, testOn: testOn);
}

void testInt32x4Buffer(List<int> intSamples) {
  test('Int32x4Buffer', () {
    var bytes = 128 ~/ 8;
    Matcher equals32x4(Int32x4 expected) => MatchesInt32x4(expected);

    var buffer = Int32x4Buffer(0);
    expect(buffer, const TypeMatcher<List<Int32x4>>());
    expect(buffer.length, equals(0));

    expect(buffer.elementSizeInBytes, equals(bytes));
    expect(buffer.lengthInBytes, equals(0));
    expect(buffer.offsetInBytes, equals(0));

    var sample = Int32x4(-0x80000000, -1, 0, 0x7fffffff);
    buffer.add(sample);
    expect(buffer.length, equals(1));
    expect(buffer[0], equals32x4(sample));

    expect(buffer.elementSizeInBytes, equals(bytes));
    expect(buffer.lengthInBytes, equals(bytes));
    expect(buffer.offsetInBytes, equals(0));

    buffer.length = 0;
    expect(buffer.length, equals(0));

    var samples = intSamples
        .map((value) => Int32x4(value, -value, ~value, ~ -value))
        .toList();
    for (var value in samples) {
      var length = buffer.length;
      buffer.add(value);
      expect(buffer.length, equals(length + 1));
      expect(buffer[length], equals32x4(value));
    }

    buffer.addAll(samples); // Add all the values at once.
    for (var i = 0; i < samples.length; i++) {
      expect(buffer[samples.length + i], equals32x4(buffer[i]));
    }

    // Remove range works and changes length.
    buffer.removeRange(samples.length, buffer.length);
    expect(buffer.length, equals(samples.length));

    // Accessing the underlying buffer works.
    buffer.length = 2;
    buffer[0] = Int32x4(-80000000, 0x7fffffff, 0, -1);
    var byteBuffer = Uint8List.view(buffer.buffer);
    var halfBytes = bytes ~/ 2;
    for (var i = 0; i < halfBytes; i++) {
      var tmp = byteBuffer[i];
      byteBuffer[i] = byteBuffer[halfBytes + i];
      byteBuffer[halfBytes + i] = tmp;
    }
    var result = Int32x4(0, -1, -80000000, 0x7fffffff);
    expect(buffer[0], equals32x4(result));
  });
}

void testIntBuffer(
  List<int> intSamples,
  int bits,
  int min,
  int max,
  TypedDataBuffer<int> Function(int length) create,
  int Function(int val) round,
) {
  assert(round(min) == min);
  assert(round(max) == max);
  // All int buffers default to the value 0.
  var buffer = create(0);
  expect(buffer, const TypeMatcher<List<int>>());
  expect(buffer.length, equals(0));
  var bytes = bits ~/ 8;

  expect(buffer.elementSizeInBytes, equals(bytes));
  expect(buffer.lengthInBytes, equals(0));
  expect(buffer.offsetInBytes, equals(0));

  buffer.add(min);
  expect(buffer.length, equals(1));
  expect(buffer[0], equals(min));

  expect(buffer.elementSizeInBytes, equals(bytes));
  expect(buffer.lengthInBytes, equals(bytes));
  expect(buffer.offsetInBytes, equals(0));

  buffer.length = 0;
  expect(buffer.length, equals(0));

  var samples = intSamples.toList()..addAll(intSamples.map((x) => -x));
  for (var value in samples) {
    var length = buffer.length;
    buffer.add(value);
    expect(buffer.length, equals(length + 1));
    expect(buffer[length], equals(round(value)));
  }
  buffer.addAll(samples); // Add all the values at once.
  for (var i = 0; i < samples.length; i++) {
    expect(buffer[samples.length + i], equals(buffer[i]));
  }

  // Remove range works and changes length.
  buffer.removeRange(samples.length, buffer.length);
  expect(buffer.length, equals(samples.length));

  // Both values are in `samples`, but equality is performed without rounding.
  // For signed 64 bit ints, min and max wrap around, min-1=max and max+1=min
  if (bits == 64) {
    // TODO(keertip): fix tests for Uint64 / Int64 as now Uints are represented
    // as signed ints.
    expect(buffer.contains(min - 1), isTrue);
    expect(buffer.contains(max + 1), isTrue);
  } else {
    // Both values are in `samples`, but equality is performed without rounding.
    expect(buffer.contains(min - 1), isFalse);
    expect(buffer.contains(max + 1), isFalse);
  }
  expect(buffer.contains(round(min - 1)), isTrue);
  expect(buffer.contains(round(max + 1)), isTrue);

  // Accessing the underlying buffer works.
  buffer.length = 2;
  buffer[0] = min;
  buffer[1] = max;
  var byteBuffer = Uint8List.view(buffer.buffer);
  var byteSize = buffer.elementSizeInBytes;
  for (var i = 0; i < byteSize; i++) {
    var tmp = byteBuffer[i];
    byteBuffer[i] = byteBuffer[byteSize + i];
    byteBuffer[byteSize + i] = tmp;
  }
  expect(buffer[0], equals(max));
  expect(buffer[1], equals(min));
}

void testUint(
  List<int> intSamples,
  int bits,
  TypedDataBuffer<int> Function(int length) buffer, {
  String? testOn,
}) {
  var min = 0;
  var rounder = uintRounder(bits);
  var max = rounder(-1);
  test('Uint${bits}Buffer', () {
    testIntBuffer(intSamples, bits, min, max, buffer, rounder);
  }, testOn: testOn);
}

Rounder uintRounder(int bits) {
  var halfbits = (1 << (bits ~/ 2)) - 1;
  var mask = halfbits | (halfbits << (bits ~/ 2));
  return (int x) => x & mask;
}

typedef Rounder = int Function(int value);

class MatchesInt32x4 extends Matcher {
  Int32x4 result;

  MatchesInt32x4(this.result);

  @override
  Description describe(Description description) =>
      description.add('Int32x4.==');

  @override
  bool matches(item, Map matchState) =>
      item is Int32x4 &&
      result.x == item.x &&
      result.y == item.y &&
      result.z == item.z &&
      result.w == item.w;
}
