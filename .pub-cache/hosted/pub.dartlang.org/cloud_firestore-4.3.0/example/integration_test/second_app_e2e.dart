// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_options_secondary.dart';

void runSecondAppTests() {
  group('$FirebaseFirestore', () {
    late FirebaseFirestore firestore;
    late FirebaseFirestore secondFirestoreProject;

    setUpAll(() async {
      firestore = FirebaseFirestore.instance;
      FirebaseApp secondApp = await Firebase.initializeApp(
        name: 'secondApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      secondFirestoreProject = FirebaseFirestore.instanceFor(
        app: secondApp,
      );
    });

    group(
      'Secondary app Firestore instance',
      () {
        test(
            'Second Firestore instance should fail due to firestore.rules forbidding data writes',
            () async {
          // successful write on default app instance
          await firestore
              .collection('flutter-tests/banned/doc')
              .add({'foo': 'bar'});

          // permission denied on second app with Firebase that denies database writes
          await expectLater(
            secondFirestoreProject
                .collection('flutter-tests/banned/doc')
                .add({'foo': 'bar'}),
            throwsA(
              isA<FirebaseException>()
                  .having((e) => e.code, 'code', 'permission-denied'),
            ),
          );
        });
      },
      // Skip on android because the test continually times out on the CI. The test passes when running locally.
      skip: defaultTargetPlatform == TargetPlatform.android,
    );
  });
}
