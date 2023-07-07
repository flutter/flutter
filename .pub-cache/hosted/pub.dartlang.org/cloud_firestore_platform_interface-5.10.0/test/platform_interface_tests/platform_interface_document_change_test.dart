// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

const _kDocumentChangeType = DocumentChangeType.added;
const _kOldIndex = -1;
const _kNewIndex = 1;

class TestDocumentChange extends DocumentChangePlatform {
  TestDocumentChange._()
      : super(
            _kDocumentChangeType,
            _kOldIndex,
            _kNewIndex,
            DocumentSnapshotPlatform(FirebaseFirestorePlatform.instance,
                '$kCollectionId/$kDocumentId', {}));
}

void main() {
  initializeMethodChannel();

  group('$DocumentChangePlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    test('constructor', () {
      final testDocumentChangePlatform = TestDocumentChange._();
      expect(
          testDocumentChangePlatform, isInstanceOf<DocumentChangePlatform>());
      expect(testDocumentChangePlatform.newIndex, equals(_kNewIndex));
      expect(testDocumentChangePlatform.oldIndex, equals(_kOldIndex));
    });
  });
}
