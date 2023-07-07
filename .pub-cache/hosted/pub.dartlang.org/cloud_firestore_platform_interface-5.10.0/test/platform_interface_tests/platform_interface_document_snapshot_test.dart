// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

const _kPath = 'document';
const _kMetadata = {'isFromCache': true, 'hasPendingWrites': true};
const _kData = {'foo': 'bar'};

class TestDocumentSnapshot extends DocumentSnapshotPlatform {
  TestDocumentSnapshot._()
      : super(FirebaseFirestorePlatform.instance, _kPath,
            {'data': _kData, 'metadata': _kMetadata});
}

void main() {
  initializeMethodChannel();

  group('$DocumentReferencePlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    test('constructor', () {
      final snapshot = TestDocumentSnapshot._();
      expect(snapshot, isInstanceOf<DocumentSnapshotPlatform>());
    });

    test('id', () {
      final snapshot = TestDocumentSnapshot._();
      expect(snapshot.id, equals(_kPath));
    });

    test('metadata', () {
      final snapshot = TestDocumentSnapshot._();
      final metaData = snapshot.metadata;
      expect(metaData, isInstanceOf<SnapshotMetadataPlatform>());
      expect(metaData.hasPendingWrites, isTrue);
      expect(metaData.isFromCache, isTrue);
    });

    test('exists', () {
      final snapshot = TestDocumentSnapshot._();
      expect(snapshot.exists, isTrue);
    });

    test('reference', () {
      final snapshot = TestDocumentSnapshot._();
      final reference = snapshot.reference;
      expect(reference, isInstanceOf<DocumentReferencePlatform>());
      expect(reference.id, equals(_kPath));
    });

    test('data', () {
      final snapshot = TestDocumentSnapshot._();
      expect(snapshot.data(), _kData);
    });

    test('get', () {
      final snapshot = TestDocumentSnapshot._();
      expect(snapshot.get('foo'), 'bar');
    });

    test('[]', () {
      final snapshot = TestDocumentSnapshot._();
      expect(snapshot['foo'], 'bar');
    });
  });
}
