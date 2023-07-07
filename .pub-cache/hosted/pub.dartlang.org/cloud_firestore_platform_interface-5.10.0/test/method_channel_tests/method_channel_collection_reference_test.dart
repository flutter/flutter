// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_collection_reference.dart';

import '../utils/test_common.dart';

const _kCollectionId = 'test';
const _kDocumentId = 'document';

void main() {
  initializeMethodChannel();

  MethodChannelCollectionReference? _testCollection;

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
    _testCollection = MethodChannelCollectionReference(
        FirebaseFirestorePlatform.instance, _kCollectionId);
  });

  group('$MethodChannelCollectionReference', () {
    test('Parent', () {
      expect(_testCollection!.parent, isNull);
      expect(
          MethodChannelCollectionReference(FirebaseFirestorePlatform.instance,
                  '$_kCollectionId/$_kDocumentId/test')
              .parent!
              .path,
          equals('$_kCollectionId/$_kDocumentId'));
    });
    test('Document', () {
      expect(_testCollection!.doc().path.split('/').length, equals(2));
      expect(_testCollection!.doc(_kDocumentId).path.split('/').last,
          equals(_kDocumentId));
    });
  });
}
