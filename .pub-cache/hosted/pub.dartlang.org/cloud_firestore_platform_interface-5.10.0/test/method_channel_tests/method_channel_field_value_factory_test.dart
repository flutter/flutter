// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_collection_reference.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_field_value_factory.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_field_value.dart';

import '../utils/test_common.dart';

const _kCollectionId = 'test';

void main() {
  initializeMethodChannel();
  group('$MethodChannelFieldValueFactory()', () {
    setUpAll(() async {
      await Firebase.initializeApp(
        name: 'testApp',
        options: const FirebaseOptions(
          appId: '1:1234567890:ios:42424242424242',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '1234567890',
        ),
      );
      MethodChannelCollectionReference(
          FirebaseFirestorePlatform.instance, _kCollectionId);
    });
    final MethodChannelFieldValueFactory factory =
        MethodChannelFieldValueFactory();
    test('arrayRemove', () {
      final MethodChannelFieldValue actual = factory.arrayRemove([1]);
      expect(actual.type, equals(FieldValueType.arrayRemove));
      expect(actual, equals(factory.arrayRemove([1])));
      expect(actual, isNot(equals(factory.arrayRemove([2]))));
    });
    test('arrayUnion', () {
      final MethodChannelFieldValue actual = factory.arrayUnion([1]);
      expect(actual.type, equals(FieldValueType.arrayUnion));
      expect(actual, equals(factory.arrayUnion([1])));
      expect(actual, isNot(equals(factory.arrayUnion([2]))));
    });
    test('delete', () {
      final MethodChannelFieldValue actual = factory.delete();
      expect(actual.type, equals(FieldValueType.delete));
      expect(actual, equals(factory.delete()));
      expect(actual, isNot(equals(factory.serverTimestamp())));
    });
    test('increment', () {
      final MethodChannelFieldValue actualInt = factory.increment(1);
      expect(actualInt.type, equals(FieldValueType.incrementInteger));
      final MethodChannelFieldValue actualDouble = factory.increment(1.0);
      expect(actualDouble.type, equals(FieldValueType.incrementDouble));
      expect(actualInt, equals(factory.increment(1)));
      expect(actualInt, isNot(equals(actualDouble)));
    });
    test('serverTimestamp', () {
      final MethodChannelFieldValue actual = factory.serverTimestamp();
      expect(actual.type, equals(FieldValueType.serverTimestamp));
      expect(actual, equals(factory.serverTimestamp()));
    });
  });
}
