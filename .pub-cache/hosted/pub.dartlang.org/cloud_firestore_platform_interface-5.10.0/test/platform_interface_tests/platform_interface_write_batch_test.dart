// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

class TestWriteBatch extends WriteBatchPlatform {
  TestWriteBatch._() : super();
}

void main() {
  initializeMethodChannel();

  group('$WriteBatchPlatform()', () {
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
      final batch = TestWriteBatch._();
      expect(batch, isInstanceOf<WriteBatchPlatform>());
    });

    test('verify()', () {
      final batch = TestWriteBatch._();
      WriteBatchPlatform.verify(batch);
      expect(batch, isInstanceOf<WriteBatchPlatform>());
    });

    test('throws if .commit', () async {
      final batch = TestWriteBatch._();
      try {
        await batch.commit();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('commit() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .delete', () {
      final batch = TestWriteBatch._();
      try {
        batch.delete('foo');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('delete() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .set', () {
      final batch = TestWriteBatch._();
      try {
        batch.set('foo', {});
      } on UnimplementedError catch (e) {
        expect(e.message, equals('set() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .update', () {
      final batch = TestWriteBatch._();
      try {
        batch.update('foo', {});
      } on UnimplementedError catch (e) {
        expect(e.message, equals('update() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}
