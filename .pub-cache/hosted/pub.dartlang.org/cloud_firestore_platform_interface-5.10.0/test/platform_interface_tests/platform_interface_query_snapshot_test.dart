// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

const _kPath = 'document';

DocumentSnapshotPlatform documentSnapshotPlatform =
    DocumentSnapshotPlatform(FirebaseFirestorePlatform.instance, _kPath, {});
final List<DocumentSnapshotPlatform> _kDocuments = [documentSnapshotPlatform];
DocumentChangePlatform documentChangePlatform = DocumentChangePlatform(
    DocumentChangeType.added, -1, 1, documentSnapshotPlatform);
final _kDocumentChanges = [documentChangePlatform];
final _kMetaData = SnapshotMetadataPlatform(true, true);

class TestQuerySnapshot extends QuerySnapshotPlatform {
  TestQuerySnapshot._() : super(_kDocuments, _kDocumentChanges, _kMetaData);
}

void main() {
  initializeMethodChannel();

  group('$DocumentReferencePlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    test('constructor', () {
      final querySnapshot = TestQuerySnapshot._();
      expect(querySnapshot, isInstanceOf<QuerySnapshotPlatform>());
    });

    test('documentChanges', () {
      final snapshot = TestQuerySnapshot._();
      final documentChanges = snapshot.docChanges;
      expect(documentChanges, isInstanceOf<List<DocumentChangePlatform>>());
      expect(documentChanges, _kDocumentChanges);
    });

    test('documents', () {
      final snapshot = TestQuerySnapshot._();
      final documents = snapshot.docs;
      expect(documents, isInstanceOf<List<DocumentSnapshotPlatform>>());
      expect(documents, _kDocuments);
    });

    test('metadata', () {
      final snapshot = TestQuerySnapshot._();
      final metaData = snapshot.metadata;
      expect(metaData, isInstanceOf<SnapshotMetadataPlatform>());
      expect(metaData.hasPendingWrites, isTrue);
      expect(metaData.isFromCache, isTrue);
    });

    test('size', () {
      final snapshot = TestQuerySnapshot._();
      expect(snapshot.size, 1);
    });
  });
}
