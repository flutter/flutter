// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runSnapshotMetadataTests() {
  group(
    '$SnapshotMetadata',
    () {
      late FirebaseFirestore /*?*/ firestore;

      setUpAll(() async {
        firestore = FirebaseFirestore.instance;
      });

      Future<CollectionReference> initializeTest(String id) async {
        CollectionReference collection =
            firestore.collection('flutter-tests/$id/query-tests');
        QuerySnapshot snapshot = await collection.get();
        await Future.forEach(snapshot.docs,
            (DocumentSnapshot documentSnapshot) {
          return documentSnapshot.reference.delete();
        });
        return collection;
      }

      test('a snapshot returns the correct [isFromCache] value', () async {
        CollectionReference collection =
            await initializeTest('snapshot-metadata-is-from-cache');
        QuerySnapshot qs =
            await collection.get(const GetOptions(source: Source.cache));
        expect(qs.metadata.isFromCache, isTrue);

        QuerySnapshot qs2 =
            await collection.get(const GetOptions(source: Source.server));
        expect(qs2.metadata.isFromCache, isFalse);
      });
    },
    skip: kIsWeb,
  );
}
