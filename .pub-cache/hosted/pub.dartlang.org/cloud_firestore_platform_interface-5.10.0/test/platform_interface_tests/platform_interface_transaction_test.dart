// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

class TestTransaction extends TransactionPlatform {
  TestTransaction._() : super();
}

void main() {
  initializeMethodChannel();

  group('$TransactionPlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp(
        name: 'testApp',
        options: const FirebaseOptions(
          appId: '1:123:ios:123',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '123',
        ),
      );
    });

    test('constructor', () {
      final transaction = TestTransaction._();
      expect(transaction, isInstanceOf<TransactionPlatform>());
    });

    test('verify()', () {
      final transaction = TestTransaction._();
      TransactionPlatform.verify(transaction);
      expect(transaction, isInstanceOf<TransactionPlatform>());
    });

    test('throws if .commands', () {
      final transaction = TestTransaction._();
      try {
        transaction.commands;
      } on UnimplementedError catch (e) {
        expect(e.message, equals('commands is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .get', () async {
      final transaction = TestTransaction._();
      try {
        await transaction.get('foo');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('get() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .delete', () {
      final transaction = TestTransaction._();
      try {
        transaction.delete('foo');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('delete() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .update', () {
      final transaction = TestTransaction._();
      try {
        transaction.update('foo', {});
      } on UnimplementedError catch (e) {
        expect(e.message, equals('update() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .set', () {
      final transaction = TestTransaction._();
      try {
        transaction.set('foo', {});
      } on UnimplementedError catch (e) {
        expect(e.message, equals('set() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}
