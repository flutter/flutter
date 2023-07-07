// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import './mock.dart';

void main() {
  setupCloudFirestoreMocks();
  FirebaseFirestore? firestore;
  FirebaseFirestore? firestoreSecondary;

  MethodChannelFirebaseFirestore.channel.setMockMethodCallHandler((call) async {
    String path = call.arguments['path'];

    if (call.method == 'DocumentReference#get' && path == 'doc/exists') {
      return {
        'data': {
          'foo': 'bar',
        },
        'metadata': {
          'hasPendingWrites': true,
          'isFromCache': true,
        }
      };
    }

    if (call.method == 'DocumentReference#set' && path == 'doc/exists') {
      return {
        'data': {
          'foo': 'bar',
        },
      };
    }

    return null;
  });

  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'foo',
      options: const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );

    firestore = FirebaseFirestore.instance;
    firestoreSecondary = FirebaseFirestore.instanceFor(app: secondaryApp);
  });

  group('$WriteBatch', () {
    test('requires document reference from same Firestore instance', () {
      DocumentReference badRef = firestoreSecondary!.doc('doc/exists');

      const data = {'foo': 1};
      var batch = firestore!.batch();
      expect(() => batch.set(badRef, data), throwsAssertionError);
      expect(() => batch.update(badRef, data), throwsAssertionError);
      expect(() => batch.delete(badRef), throwsAssertionError);
    });
  });
}
