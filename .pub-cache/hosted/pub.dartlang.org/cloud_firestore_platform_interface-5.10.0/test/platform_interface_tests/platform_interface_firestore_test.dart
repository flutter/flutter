// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

class TestFirestore extends FirebaseFirestorePlatform {
  TestFirestore._() : super();
}

void main() {
  initializeMethodChannel();
  group('$FirebaseFirestorePlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    test('constructor', () {
      final firestore = TestFirestore._();
      expect(firestore, isInstanceOf<FirebaseFirestorePlatform>());
    });

    test('app', () {
      final firestore = TestFirestore._();

      expect(firestore.app, isInstanceOf<FirebaseApp>());
      expect(firestore.app, equals(Firebase.app()));
    });

    test('throws if .batch', () {
      final firestore = TestFirestore._();
      try {
        firestore.batch();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('batch() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .clearPersistence', () async {
      final firestore = TestFirestore._();
      try {
        await firestore.clearPersistence();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('clearPersistence() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .collection', () {
      final firestore = TestFirestore._();
      try {
        firestore.collection('foo');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('collection() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .collectionGroup', () {
      final firestore = TestFirestore._();
      try {
        firestore.collectionGroup('foo');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('collectionGroup() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .disableNetwork', () async {
      final firestore = TestFirestore._();
      try {
        await firestore.disableNetwork();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('disableNetwork() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .doc', () {
      final firestore = TestFirestore._();
      try {
        firestore.doc('foo');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('doc() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .enableNetwork', () async {
      final firestore = TestFirestore._();
      try {
        await firestore.enableNetwork();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('enableNetwork() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .snapshotsInSync', () {
      final firestore = TestFirestore._();
      try {
        firestore.snapshotsInSync();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('snapshotsInSync() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .runTransaction', () async {
      final firestore = TestFirestore._();
      try {
        await firestore.runTransaction((transaction) async => true);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('runTransaction() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if getting .settings', () async {
      final firestore = TestFirestore._();
      try {
        firestore.settings;
      } on UnimplementedError catch (e) {
        expect(e.message, equals('settings getter is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if setting .settings', () async {
      final firestore = TestFirestore._();
      try {
        firestore.settings = const Settings();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('settings setter is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .terminate', () async {
      final firestore = TestFirestore._();
      try {
        await firestore.terminate();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('terminate() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .waitForPendingWrites', () async {
      final firestore = TestFirestore._();
      try {
        await firestore.waitForPendingWrites();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('waitForPendingWrites() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}
