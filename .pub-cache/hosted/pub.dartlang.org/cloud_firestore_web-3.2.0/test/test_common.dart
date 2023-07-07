// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js' as js;
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore_web/src/interop/firestore.dart' as web;

import 'package:cloud_firestore_web/src/document_reference_web.dart';
import 'package:cloud_firestore_web/src/query_web.dart';

const kCollectionId = 'test';

class MockWebDocumentSnapshot extends Mock implements web.DocumentSnapshot {}

class MockWebSnapshotMetaData extends Mock implements web.SnapshotMetadata {}

class MockFirestoreWeb extends Mock implements web.Firestore {}

class MockWebTransaction extends Mock implements web.Transaction {}

class MockWebWriteBatch extends Mock implements web.WriteBatch {}

//ignore: avoid_implementing_value_types
class MockDocumentReference extends Mock implements DocumentReferenceWeb {}

//ignore: avoid_implementing_value_types
class MockFirestore extends Mock implements FirebaseFirestoreWeb {}

class MockWebDocumentReference extends Mock implements web.DocumentReference {}

class MockWebCollectionReference extends Mock
    implements web.CollectionReference {}

// ignore: must_be_immutable, avoid_implementing_value_types
class MockQueryWeb extends Mock implements QueryWeb {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshotPlatform {}

web.Firestore mockFirestore() {
  final mockFirestoreWeb = MockFirestoreWeb();
  final js.JsObject firebaseMock = js.JsObject.jsify(<String, dynamic>{
    'firestore': js.allowInterop((_) => mockFirestoreWeb),
    'app': js.allowInterop((String name) {
      return js.JsObject.jsify(<String, dynamic>{
        'name': name,
        'options': <String, String>{'appId': '123'},
      });
    })
  });
  js.context['firebase'] = firebaseMock;
  FirebasePlatform.instance = FirebaseCoreWeb();
  FirebaseFirestorePlatform.instance = FirebaseFirestoreWeb();
  return mockFirestoreWeb;
}
