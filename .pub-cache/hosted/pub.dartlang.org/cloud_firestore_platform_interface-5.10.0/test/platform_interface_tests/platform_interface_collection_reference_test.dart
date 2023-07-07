// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

const _kCollectionId = 'collection';
const _kDocumentId = 'document';
const _kSubcollectionId = 'subcollection';

class TestCollectionReference extends CollectionReferencePlatform {
  TestCollectionReference._()
      : super(FirebaseFirestorePlatform.instance, _kCollectionId);
}

/// Collection reference pointing to the same collection as
/// [TestCollectionReference].
///
/// However, this has a leading `/` for testing path equality.
class ShadowTestCollectionReference extends CollectionReferencePlatform {
  ShadowTestCollectionReference._()
      : super(FirebaseFirestorePlatform.instance, '/$_kCollectionId');
}

class TestSubcollectionReference extends CollectionReferencePlatform {
  TestSubcollectionReference._()
      : super(FirebaseFirestorePlatform.instance,
            '$_kCollectionId/$_kDocumentId/$_kSubcollectionId');
}

void main() {
  initializeMethodChannel();

  group('$CollectionReferencePlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    test('constructor', () {
      final testColRef = TestCollectionReference._();
      expect(testColRef, isInstanceOf<CollectionReferencePlatform>());
      expect(testColRef.id, equals(_kCollectionId));
    });

    test('id', () {
      final collection = TestCollectionReference._();
      expect(collection.id, equals(_kCollectionId));
    });

    test('==', () {
      final other = ShadowTestCollectionReference._();
      final collection = TestCollectionReference._();
      expect(other, equals(collection));
    });

    test('parent', () {
      final collection = TestSubcollectionReference._();
      final parent = collection.parent!;
      final parentPath = parent.path;
      expect(parent, isInstanceOf<DocumentReferencePlatform>());
      expect(parentPath, equals('$_kCollectionId/$_kDocumentId'));
    });

    test('path', () {
      final document = TestCollectionReference._();
      expect(document.path, equals(_kCollectionId));
    });

    test('throws if .doc', () {
      final document = TestCollectionReference._();
      try {
        document.doc();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('doc() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}
