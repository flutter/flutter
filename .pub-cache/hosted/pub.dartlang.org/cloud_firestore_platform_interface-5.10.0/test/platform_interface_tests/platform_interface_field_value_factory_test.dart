// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

class TestFieldValueFactory extends FieldValueFactoryPlatform {
  TestFieldValueFactory._() : super();
}

void main() {
  initializeMethodChannel();

  group('$FieldValueFactoryPlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    test('constructor', () {
      final fieldValueFactory = TestFieldValueFactory._();
      expect(fieldValueFactory, isInstanceOf<FieldValueFactoryPlatform>());
    });

    test('throws if .arrayUnion', () {
      final fieldValueFactory = TestFieldValueFactory._();
      try {
        fieldValueFactory.arrayUnion([]);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('arrayUnion() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .arrayRemove', () {
      final fieldValueFactory = TestFieldValueFactory._();
      try {
        fieldValueFactory.arrayRemove([]);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('arrayRemove() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .delete', () {
      final fieldValueFactory = TestFieldValueFactory._();
      try {
        fieldValueFactory.delete();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('delete() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .serverTimestamp', () {
      final fieldValueFactory = TestFieldValueFactory._();
      try {
        fieldValueFactory.serverTimestamp();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('serverTimestamp() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .increment', () {
      final fieldValueFactory = TestFieldValueFactory._();
      try {
        fieldValueFactory.increment(1);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('increment() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}
