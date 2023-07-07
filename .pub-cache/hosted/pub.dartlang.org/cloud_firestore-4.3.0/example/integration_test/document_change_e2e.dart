// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runDocumentChangeTests() {
  group('$DocumentChange', () {
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

    test(
      'can add/update values to null in the document',
      () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('null-test');
        DocumentReference<Map<String, dynamic>> doc1 = collection.doc('doc1');

        await expectLater(
          doc1.snapshots(),
          emits(
            isA<DocumentSnapshot<Map<String, dynamic>>>()
                .having((q) => q.exists, 'exists', false),
          ),
        );

        await doc1.set(<String, Object?>{
          'key': null,
          'key2': 42,
        });

        await expectLater(
          doc1.snapshots(),
          emits(
            isA<DocumentSnapshot<Map<String, dynamic>>>()
                .having((q) => q.exists, 'exists', true)
                .having((q) => q.data(), 'data()', <String, Object?>{
              'key': null,
              'key2': 42,
            }),
          ),
        );

        await doc1.set({
          'key': null,
          'key2': null,
        });

        await expectLater(
          doc1.snapshots(),
          emits(
            isA<DocumentSnapshot<Map<String, dynamic>>>()
                .having((q) => q.exists, 'exists', true)
                .having((q) => q.data(), 'data()', <String, Object?>{
              'key': null,
              'key2': null,
            }),
          ),
        );
      },
      timeout: const Timeout.factor(8),
    );

    test('returns the correct metadata when adding and removing', () async {
      CollectionReference<Map<String, dynamic>> collection =
          await initializeTest('add-remove-document');
      DocumentReference<Map<String, dynamic>> doc1 = collection.doc('doc1');

      // Set something in the database
      await doc1.set({'name': 'doc1'});

      Stream<QuerySnapshot<Map<String, dynamic>>> stream =
          collection.snapshots();
      int call = 0;

      StreamSubscription subscription = stream.listen(
        expectAsync1(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            call++;
            if (call == 1) {
              expect(snapshot.docs.length, equals(1));
              expect(snapshot.docChanges.length, equals(1));
              expect(snapshot.docChanges[0], isA<DocumentChange>());
              DocumentChange<Map<String, dynamic>> change =
                  snapshot.docChanges[0];
              expect(change.newIndex, equals(0));
              expect(change.oldIndex, equals(-1));
              expect(change.type, equals(DocumentChangeType.added));
              expect(change.doc.data()!['name'], equals('doc1'));
            } else if (call == 2) {
              expect(snapshot.docs.length, equals(0));
              expect(snapshot.docChanges.length, equals(1));
              expect(snapshot.docChanges[0], isA<DocumentChange>());
              DocumentChange<Map<String, dynamic>> change =
                  snapshot.docChanges[0];
              expect(change.newIndex, equals(-1));
              expect(change.oldIndex, equals(0));
              expect(change.type, equals(DocumentChangeType.removed));
              expect(change.doc.data()!['name'], equals('doc1'));
            } else {
              fail('Should not have been called');
            }
          },
          count: 2,
          reason: 'Stream should only have been called twice.',
        ),
      );

      await Future.delayed(const Duration(seconds: 1)); // Ensure listener fires
      await doc1.delete();

      await subscription.cancel();
    });

    test('returns the correct metadata when modifying', () async {
      CollectionReference<Map<String, dynamic>> collection =
          await initializeTest('add-modify-document');
      DocumentReference<Map<String, dynamic>> doc1 = collection.doc('doc1');
      DocumentReference<Map<String, dynamic>> doc2 = collection.doc('doc2');
      DocumentReference<Map<String, dynamic>> doc3 = collection.doc('doc3');

      await doc1.set({'value': 1});
      await doc2.set({'value': 2});
      await doc3.set({'value': 3});
      Stream<QuerySnapshot<Map<String, dynamic>>> stream =
          collection.orderBy('value').snapshots();

      int call = 0;
      StreamSubscription subscription = stream.listen(
        expectAsync1(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            call++;
            if (call == 1) {
              expect(snapshot.docs.length, equals(3));
              expect(snapshot.docChanges.length, equals(3));
              snapshot.docChanges.asMap().forEach(
                  (int index, DocumentChange<Map<String, dynamic>> change) {
                expect(change.oldIndex, equals(-1));
                expect(change.newIndex, equals(index));
                expect(change.type, equals(DocumentChangeType.added));
                expect(change.doc.data()!['value'], equals(index + 1));
              });
            } else if (call == 2) {
              expect(snapshot.docs.length, equals(3));
              expect(snapshot.docChanges.length, equals(1));
              DocumentChange<Map<String, dynamic>> change =
                  snapshot.docChanges[0];
              expect(change.oldIndex, equals(0));
              expect(change.newIndex, equals(2));
              expect(change.type, equals(DocumentChangeType.modified));
              expect(change.doc.id, equals('doc1'));
            } else {
              fail('Should not have been called');
            }
          },
          count: 2,
          reason: 'Stream should only have been called twice.',
        ),
      );

      await Future.delayed(const Duration(seconds: 1)); // Ensure listener fires
      await doc1.update({'value': 4});

      await subscription.cancel();
    });
  });
}
