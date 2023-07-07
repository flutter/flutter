// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

const _kCollectionId = 'test';
const _kDocumentId = 'document';

class TestDocumentReference extends DocumentReferencePlatform {
  TestDocumentReference._()
      : super(FirebaseFirestorePlatform.instance,
            '$_kCollectionId/$_kDocumentId');
}

/// Collection reference pointing to the same collection as
/// [TestDocumentReference].
///
/// However, this has a leading `/` for testing path equality.
class ShadowTestDocumentReference extends DocumentReferencePlatform {
  ShadowTestDocumentReference._()
      : super(FirebaseFirestorePlatform.instance,
            '/$_kCollectionId/$_kDocumentId');
}

void main() {
  initializeMethodChannel();

  group('$DocumentReferencePlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    test('constructor', () {
      final testDocRef = TestDocumentReference._();
      expect(testDocRef, isInstanceOf<DocumentReferencePlatform>());
      expect(testDocRef.id, equals(_kDocumentId));
      expect(testDocRef.path, equals('$_kCollectionId/$_kDocumentId'));
    });

    test('path', () {
      final document = TestDocumentReference._();
      expect(document.path, equals('$_kCollectionId/$_kDocumentId'));
    });

    test('==', () {
      final other = ShadowTestDocumentReference._();
      final reference = TestDocumentReference._();
      expect(other, equals(reference));
    });

    test('id', () {
      final document = TestDocumentReference._();
      expect(document.id, equals(_kDocumentId));
    });

    test('parent', () {
      final document = TestDocumentReference._();
      final parent = document.parent;
      final parentPath = parent.path;
      expect(parent, isInstanceOf<CollectionReferencePlatform>());
      expect(parentPath, equals(_kCollectionId));
    });

    test('collection', () {
      final document = TestDocumentReference._();
      expect(document.collection('extra').path,
          equals('$_kCollectionId/$_kDocumentId/extra'));
    });

    test('throws if .delete', () async {
      final document = TestDocumentReference._();
      try {
        await document.delete();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('delete() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .get', () async {
      final document = TestDocumentReference._();
      try {
        await document.get();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('get() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .snapshots', () {
      final document = TestDocumentReference._();
      try {
        document.snapshots();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('snapshots() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .set', () async {
      final document = TestDocumentReference._();
      try {
        await document.set({});
      } on UnimplementedError catch (e) {
        expect(e.message, equals('set() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .update', () async {
      final document = TestDocumentReference._();
      try {
        await document.update({});
      } on UnimplementedError catch (e) {
        expect(e.message, equals('update() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}
