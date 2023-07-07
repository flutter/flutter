// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runCollectionReferenceTests() {
  group('$CollectionReference', () {
    late FirebaseFirestore firestore;

    setUpAll(() async {
      firestore = FirebaseFirestore.instance;
    });

    Future<CollectionReference<Map<String, dynamic>>> initializeTest(
      String id,
    ) async {
      CollectionReference<Map<String, dynamic>> collection =
          firestore.collection('flutter-tests/$id/query-tests');
      QuerySnapshot<Map<String, dynamic>> snapshot = await collection.get();

      await Future.forEach(snapshot.docs,
          (DocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
        return documentSnapshot.reference.delete();
      });
      return collection;
    }

    test('add() adds a document', () async {
      CollectionReference<Map<String, dynamic>> collection =
          await initializeTest('collection-reference-add');
      var rand = Random();
      var randNum = rand.nextInt(999999);
      DocumentReference<Map<String, dynamic>> doc = await collection.add({
        'value': randNum,
      });
      DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();
      expect(randNum, equals(snapshot.data()!['value']));
    });

    test('snapshots() can be reused', () async {
      final foo = await initializeTest('foo');

      final snapshot = foo.snapshots();
      final snapshot2 = foo.snapshots();

      expect(
        await snapshot.first,
        isA<QuerySnapshot<Map<String, dynamic>>>()
            .having((e) => e.docs, 'docs', []),
      );
      expect(
        await snapshot2.first,
        isA<QuerySnapshot<Map<String, dynamic>>>()
            .having((e) => e.docs, 'docs', []),
      );

      await foo.add({'value': 42});

      expect(
        await snapshot.first,
        isA<QuerySnapshot<Map<String, dynamic>>>()
            .having((e) => e.docs, 'docs', [
          isA<QueryDocumentSnapshot>()
              .having((e) => e.data(), 'data', {'value': 42}),
        ]),
      );
      expect(
        await snapshot2.first,
        isA<QuerySnapshot<Map<String, dynamic>>>()
            .having((e) => e.docs, 'docs', [
          isA<QueryDocumentSnapshot<Map<String, dynamic>>>()
              .having((e) => e.data(), 'data', {'value': 42}),
        ]),
      );
    });

    group('withConverter', () {
      test(
        'add/snapshot',
        () async {
          final foo = await initializeTest('foo');
          final fooConverter = foo.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          final fooSnapshot = foo.snapshots();
          final fooConverterSnapshot = fooConverter.snapshots();

          await expectLater(
            fooSnapshot,
            emits(
              isA<QuerySnapshot<Map<String, dynamic>>>()
                  .having((e) => e.docs, 'docs', []),
            ),
          );
          await expectLater(
            fooConverterSnapshot,
            emits(
              isA<QuerySnapshot<int>>().having((e) => e.docs, 'docs', []),
            ),
          );

          final newDocument = await fooConverter.add(42);

          await expectLater(
            newDocument.get(),
            completion(
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 42),
            ),
          );

          await expectLater(
            fooSnapshot,
            emits(
              isA<QuerySnapshot>().having((e) => e.docs, 'docs', [
                isA<QueryDocumentSnapshot>()
                    .having((e) => e.data(), 'data', {'value': 42})
              ]),
            ),
          );
          await expectLater(
            fooConverterSnapshot,
            emits(
              isA<QuerySnapshot<int>>().having((e) => e.docs, 'docs', [
                isA<QueryDocumentSnapshot<int>>()
                    .having((e) => e.data(), 'data', 42)
              ]),
            ),
          );

          await foo.add({'value': 21});

          await expectLater(
            fooSnapshot,
            emits(
              isA<QuerySnapshot>().having(
                (e) => e.docs,
                'docs',
                unorderedEquals([
                  isA<QueryDocumentSnapshot<Map<String, dynamic>>>()
                      .having((e) => e.data(), 'data', {'value': 42}),
                  isA<QueryDocumentSnapshot<Map<String, dynamic>>>()
                      .having((e) => e.data(), 'data', {'value': 21})
                ]),
              ),
            ),
          );

          await expectLater(
            fooConverterSnapshot,
            emits(
              isA<QuerySnapshot<int>>().having(
                (e) => e.docs,
                'docs',
                unorderedEquals([
                  isA<QueryDocumentSnapshot<int>>()
                      .having((e) => e.data(), 'data', 42),
                  isA<QueryDocumentSnapshot<int>>()
                      .having((e) => e.data(), 'data', 21)
                ]),
              ),
            ),
          );
        },
        timeout: const Timeout.factor(3),
      );
    });
  });
}
