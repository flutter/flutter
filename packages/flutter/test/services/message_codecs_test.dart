// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:flutter/services.dart';
import '../flutter_test_alternative.dart';

void main() {
  group('Binary codec', () {
    const MessageCodec<ByteData> binary = BinaryCodec();
    test('should encode and decode simple messages', () {
      _checkEncodeDecode<ByteData>(binary, null);
      _checkEncodeDecode<ByteData>(binary, ByteData(0));
      _checkEncodeDecode<ByteData>(binary, ByteData(4)..setInt32(0, -7));
    });
  });
  group('String codec', () {
    const MessageCodec<String> string = StringCodec();
    test('should encode and decode simple messages', () {
      _checkEncodeDecode<String>(string, null);
      _checkEncodeDecode<String>(string, '');
      _checkEncodeDecode<String>(string, 'hello');
      _checkEncodeDecode<String>(string, 'special chars >\u263A\u{1F602}<');
    });
    test('ByteData with offset', () {
      const MessageCodec<String> string = StringCodec();
      final ByteData helloWorldByteData = string.encodeMessage('hello world');
      final ByteData helloByteData = string.encodeMessage('hello');

      final ByteData offsetByteData = ByteData.view(
          helloWorldByteData.buffer,
          helloByteData.lengthInBytes,
          helloWorldByteData.lengthInBytes - helloByteData.lengthInBytes
      );

      expect(string.decodeMessage(offsetByteData), ' world');
    });
  });
  group('JSON message codec', () {
    const MessageCodec<dynamic> json = JSONMessageCodec();
    test('should encode and decode simple messages', () {
      _checkEncodeDecode<dynamic>(json, null);
      _checkEncodeDecode<dynamic>(json, true);
      _checkEncodeDecode<dynamic>(json, false);
      _checkEncodeDecode<dynamic>(json, 7);
      _checkEncodeDecode<dynamic>(json, -7);
      _checkEncodeDecode<dynamic>(json, 98742923489);
      _checkEncodeDecode<dynamic>(json, -98742923489);
      _checkEncodeDecode<dynamic>(json, 9223372036854775807);
      _checkEncodeDecode<dynamic>(json, -9223372036854775807);
      _checkEncodeDecode<dynamic>(json, 3.14);
      _checkEncodeDecode<dynamic>(json, '');
      _checkEncodeDecode<dynamic>(json, 'hello');
      _checkEncodeDecode<dynamic>(json, 'special chars >\u263A\u{1F602}<');
    });
    test('should encode and decode composite message', () {
      final List<dynamic> message = <dynamic>[
        null,
        true,
        false,
        -707,
        -7000000007,
        -7000000000000000007,
        -3.14,
        '',
        'hello',
        <dynamic>['nested', <dynamic>[]],
        <dynamic, dynamic>{ 'a': 'nested', 'b': <dynamic, dynamic>{} },
        'world',
      ];
      _checkEncodeDecode<dynamic>(json, message);
    });
  });
  group('Standard message codec', () {
    const MessageCodec<dynamic> standard = StandardMessageCodec();
    test('should encode integers correctly at boundary cases', () {
      _checkEncoding<dynamic>(
        standard,
        -0x7fffffff - 1,
        <int>[3, 0x00, 0x00, 0x00, 0x80],
      );
      _checkEncoding<dynamic>(
        standard,
        -0x7fffffff - 2,
        <int>[4, 0xff, 0xff, 0xff, 0x7f, 0xff, 0xff, 0xff, 0xff],
      );
      _checkEncoding<dynamic>(
        standard,
        0x7fffffff,
        <int>[3, 0xff, 0xff, 0xff, 0x7f],
      );
      _checkEncoding<dynamic>(
        standard,
        0x7fffffff + 1,
        <int>[4, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00],
      );
      _checkEncoding<dynamic>(
        standard,
        -0x7fffffffffffffff - 1,
        <int>[4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80],
      );
      _checkEncoding<dynamic>(
        standard,
        -0x7fffffffffffffff - 2,
        <int>[4, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f],
      );
      _checkEncoding<dynamic>(
        standard,
        0x7fffffffffffffff,
        <int>[4, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f],
      );
      _checkEncoding<dynamic>(
        standard,
        0x7fffffffffffffff + 1,
        <int>[4, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80],
      );
    });
    test('should encode sizes correctly at boundary cases', () {
      _checkEncoding<dynamic>(
        standard,
        Uint8List(253),
        <int>[8, 253]..addAll(List<int>.filled(253, 0)),
      );
      _checkEncoding<dynamic>(
        standard,
        Uint8List(254),
        <int>[8, 254, 254, 0]..addAll(List<int>.filled(254, 0)),
      );
      _checkEncoding<dynamic>(
        standard,
        Uint8List(0xffff),
        <int>[8, 254, 0xff, 0xff]..addAll(List<int>.filled(0xffff, 0)),
      );
      _checkEncoding<dynamic>(
        standard,
        Uint8List(0xffff + 1),
        <int>[8, 255, 0, 0, 1, 0]..addAll(List<int>.filled(0xffff + 1, 0)),
      );
    });
    test('should encode and decode simple messages', () {
      _checkEncodeDecode<dynamic>(standard, null);
      _checkEncodeDecode<dynamic>(standard, true);
      _checkEncodeDecode<dynamic>(standard, false);
      _checkEncodeDecode<dynamic>(standard, 7);
      _checkEncodeDecode<dynamic>(standard, -7);
      _checkEncodeDecode<dynamic>(standard, 98742923489);
      _checkEncodeDecode<dynamic>(standard, -98742923489);
      _checkEncodeDecode<dynamic>(standard, 9223372036854775807);
      _checkEncodeDecode<dynamic>(standard, -9223372036854775807);
      _checkEncodeDecode<dynamic>(standard, 3.14);
      _checkEncodeDecode<dynamic>(standard, double.infinity);
      _checkEncodeDecode<dynamic>(standard, double.nan);
      _checkEncodeDecode<dynamic>(standard, '');
      _checkEncodeDecode<dynamic>(standard, 'hello');
      _checkEncodeDecode<dynamic>(standard, 'special chars >\u263A\u{1F602}<');
    });
    test('should encode and decode composite message', () {
      final List<dynamic> message = <dynamic>[
        null,
        true,
        false,
        -707,
        -7000000007,
        -7000000000000000007,
        -3.14,
        '',
        'hello',
        Uint8List.fromList(<int>[0xBA, 0x5E, 0xBA, 0x11]),
        Int32List.fromList(<int>[-0x7fffffff - 1, 0, 0x7fffffff]),
        null, // ensures the offset of the following list is unaligned.
        Int64List.fromList(
            <int>[-0x7fffffffffffffff - 1, 0, 0x7fffffffffffffff]),
        null, // ensures the offset of the following list is unaligned.
        Float64List.fromList(<double>[
          double.negativeInfinity,
          -double.maxFinite,
          -double.minPositive,
          -0.0,
          0.0,
          double.minPositive,
          double.maxFinite,
          double.infinity,
          double.nan
        ]),
        <dynamic>['nested', <dynamic>[]],
        <dynamic, dynamic>{ 'a': 'nested', null: <dynamic, dynamic>{} },
        'world',
      ];
      _checkEncodeDecode<dynamic>(standard, message);
    });
    test('should align doubles to 8 bytes', () {
      _checkEncoding<dynamic>(
        standard,
        1.0,
        <int>[6, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0xf0, 0x3f],
      );
    });
  });
}

void _checkEncoding<T>(MessageCodec<T> codec, T message, List<int> expectedBytes) {
  final ByteData encoded = codec.encodeMessage(message);
  expect(
    encoded.buffer.asUint8List(0, encoded.lengthInBytes),
    orderedEquals(expectedBytes),
  );
}

void _checkEncodeDecode<T>(MessageCodec<T> codec, T message) {
  final ByteData encoded = codec.encodeMessage(message);
  final T decoded = codec.decodeMessage(encoded);
  if (message == null) {
    expect(encoded, isNull);
    expect(decoded, isNull);
  } else {
    expect(_deepEquals(message, decoded), isTrue);
    final ByteData encodedAgain = codec.encodeMessage(decoded);
    expect(
      encodedAgain.buffer.asUint8List(),
      orderedEquals(encoded.buffer.asUint8List()),
    );
  }
}

bool _deepEquals(dynamic valueA, dynamic valueB) {
  if (valueA is TypedData)
    return valueB is TypedData && _deepEqualsTypedData(valueA, valueB);
  if (valueA is List)
    return valueB is List && _deepEqualsList(valueA, valueB);
  if (valueA is Map)
    return valueB is Map && _deepEqualsMap(valueA, valueB);
  if (valueA is double && valueA.isNaN)
    return valueB is double && valueB.isNaN;
  return valueA == valueB;
}

bool _deepEqualsTypedData(TypedData valueA, TypedData valueB) {
  if (valueA is ByteData) {
    return valueB is ByteData
        && _deepEqualsList(
            valueA.buffer.asUint8List(), valueB.buffer.asUint8List());
  }
  if (valueA is Uint8List)
    return valueB is Uint8List && _deepEqualsList(valueA, valueB);
  if (valueA is Int32List)
    return valueB is Int32List && _deepEqualsList(valueA, valueB);
  if (valueA is Int64List)
    return valueB is Int64List && _deepEqualsList(valueA, valueB);
  if (valueA is Float64List)
    return valueB is Float64List && _deepEqualsList(valueA, valueB);
  throw 'Unexpected typed data: $valueA';
}

bool _deepEqualsList(List<dynamic> valueA, List<dynamic> valueB) {
  if (valueA.length != valueB.length)
    return false;
  for (int i = 0; i < valueA.length; i++) {
    if (!_deepEquals(valueA[i], valueB[i]))
      return false;
  }
  return true;
}

bool _deepEqualsMap(Map<dynamic, dynamic> valueA, Map<dynamic, dynamic> valueB) {
  if (valueA.length != valueB.length)
    return false;
  for (final dynamic key in valueA.keys) {
    if (!valueB.containsKey(key) || !_deepEquals(valueA[key], valueB[key]))
      return false;
  }
  return true;
}
