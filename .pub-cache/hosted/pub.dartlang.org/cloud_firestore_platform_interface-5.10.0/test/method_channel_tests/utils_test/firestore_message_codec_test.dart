// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas
// import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_field_value.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/utils/firestore_message_codec.dart';

import 'package:firebase_core/firebase_core.dart';

import '../../utils/test_firestore_message_codec.dart';
import '../../utils/test_common.dart';

void main() {
  initializeMethodChannel();
  MethodChannelFirebaseFirestore? firestore;

  setUpAll(() async {
    firestore = MethodChannelFirebaseFirestore();
    await Firebase.initializeApp();
  });
  group('$FirestoreMessageCodec', () {
    const MessageCodec<dynamic> codec = TestFirestoreMessageCodec();
    final DateTime testTime = DateTime(2015, 10, 30, 11, 16);
    final Timestamp timestamp = Timestamp.fromDate(testTime);
    test('should encode and decode simple messages', () {
      _checkEncodeDecode<dynamic>(codec, testTime);
      _checkEncodeDecode<dynamic>(codec, timestamp);
      _checkEncodeDecode<dynamic>(
          codec, const GeoPoint(37.421939, -122.083509));
      _checkEncodeDecode<dynamic>(codec, firestore!.doc('foo/bar'));
    });
    test('should encode and decode composite message', () {
      final List<dynamic> message = <dynamic>[
        testTime,
        const GeoPoint(37.421939, -122.083509),
        firestore!.doc('foo/bar'),
      ];
      _checkEncodeDecode<dynamic>(codec, message);
    });
    test('encode and decode blob', () {
      final Uint8List bytes = Uint8List(4);
      bytes[0] = 128;
      final Blob message = Blob(bytes);
      _checkEncodeDecode<dynamic>(codec, message);
    });

    test('encode and decode FieldValue', () {
      const MessageCodec<dynamic> decoder = TestFirestoreMessageCodec();

      _checkEncodeDecode<dynamic>(
        codec,
        FieldValuePlatform(
          FieldValueFactoryPlatform.instance.arrayUnion(<int>[123]),
        ),
        decodingCodec: decoder,
      );
      _checkEncodeDecode<dynamic>(
        codec,
        FieldValuePlatform(
          FieldValueFactoryPlatform.instance.arrayRemove(<int>[123]),
        ),
        decodingCodec: decoder,
      );
      _checkEncodeDecode<dynamic>(
        codec,
        FieldValuePlatform(
          FieldValueFactoryPlatform.instance.delete(),
        ),
        decodingCodec: decoder,
      );
      _checkEncodeDecode<dynamic>(
        codec,
        FieldValuePlatform(
          FieldValueFactoryPlatform.instance.serverTimestamp(),
        ),
        decodingCodec: decoder,
      );
      _checkEncodeDecode<dynamic>(
        codec,
        FieldValuePlatform(
          FieldValueFactoryPlatform.instance.increment(1.0),
        ),
        decodingCodec: decoder,
      );
      _checkEncodeDecode<dynamic>(
        codec,
        FieldValuePlatform(
          FieldValueFactoryPlatform.instance.increment(1),
        ),
        decodingCodec: decoder,
      );
    });

    test('encode and decode FieldPath', () {
      _checkEncodeDecode<dynamic>(codec, FieldPath.documentId);
    });
  });
}

void _checkEncodeDecode<T>(
  MessageCodec<T?> codec,
  T? message, {
  MessageCodec<T>? decodingCodec,
}) {
  MessageCodec<T?> decoder = decodingCodec ?? codec;

  final ByteData? encoded = codec.encodeMessage(message);
  final T? decoded = decoder.decodeMessage(encoded);
  if (message == null) {
    expect(encoded, isNull);
    expect(decoded, isNull);
  } else {
    expect(_deepEquals(message, decoded), isTrue);
    final ByteData encodedAgain = codec.encodeMessage(decoded)!;
    expect(
      encodedAgain.buffer.asUint8List(),
      orderedEquals(encoded!.buffer.asUint8List()),
    );
  }
}

bool _deepEquals(dynamic valueA, dynamic valueB) {
  if (valueA is TypedData) {
    return valueB is TypedData && _deepEqualsTypedData(valueA, valueB);
  }
  if (valueA is List) return valueB is List && _deepEqualsList(valueA, valueB);
  if (valueA is Map) return valueB is Map && _deepEqualsMap(valueA, valueB);
  if (valueA is double && valueA.isNaN) return valueB is double && valueB.isNaN;
  if (valueA is FieldValuePlatform) {
    return valueB is FieldValuePlatform &&
        _deepEqualsFieldValue(valueA, valueB);
  }
  if (valueA is FieldPath) {
    return valueB is FieldPath && valueA.runtimeType == valueB.runtimeType;
  }
  return valueA == valueB;
}

bool _deepEqualsTypedData(TypedData valueA, TypedData valueB) {
  if (valueA is ByteData) {
    return valueB is ByteData &&
        _deepEqualsList(
            valueA.buffer.asUint8List(), valueB.buffer.asUint8List());
  }
  if (valueA is Uint8List) {
    return valueB is Uint8List && _deepEqualsList(valueA, valueB);
  }
  if (valueA is Int32List) {
    return valueB is Int32List && _deepEqualsList(valueA, valueB);
  }
  if (valueA is Int64List) {
    return valueB is Int64List && _deepEqualsList(valueA, valueB);
  }
  if (valueA is Float64List) {
    return valueB is Float64List && _deepEqualsList(valueA, valueB);
  }
  throw 'Unexpected typed data: $valueA';
}

bool _deepEqualsList(List<dynamic> valueA, List<dynamic> valueB) {
  if (valueA.length != valueB.length) return false;
  for (int i = 0; i < valueA.length; i++) {
    if (!_deepEquals(valueA[i], valueB[i])) return false;
  }
  return true;
}

bool _deepEqualsMap(
  Map<dynamic, dynamic> valueA,
  Map<dynamic, dynamic> valueB,
) {
  if (valueA.length != valueB.length) return false;
  for (final dynamic key in valueA.keys) {
    if (!valueB.containsKey(key) || !_deepEquals(valueA[key], valueB[key])) {
      return false;
    }
  }
  return true;
}

bool _deepEqualsFieldValue(FieldValuePlatform a, FieldValuePlatform b) {
  MethodChannelFieldValue valueA = FieldValuePlatform.getDelegate(a);
  MethodChannelFieldValue valueB = FieldValuePlatform.getDelegate(b);

  if (valueA.type != valueB.type) return false;
  if (valueA.value == null) return valueB.value == null;
  if (valueA.value is List) return _deepEqualsList(valueA.value, valueB.value);
  if (valueA.value is Map) return _deepEqualsMap(valueA.value, valueB.value);
  return valueA.value == valueB.value;
}
