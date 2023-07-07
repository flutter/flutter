// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void runQueryTests() {
  group('$Query', () {
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
          (QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
        return documentSnapshot.reference.delete();
      });
      return collection;
    }

    group('equality', () {
      // testing == override using e2e tests as it is dependent on the platform
      test('handles deeply compares query parameters', () {
        final movies = firestore.collection('/movies');
        final starWarsComments =
            firestore.collection('/movies/star-wars/comments');

        expect(
          movies.where('genre', arrayContains: ['Flutter']),
          movies.where('genre', arrayContains: ['Flutter']),
        );
        expect(
          movies.where('genre', arrayContains: ['Flutter']),
          isNot(movies.where('genre', arrayContains: ['React'])),
        );
        expect(
          movies.where('genre', arrayContains: ['Flutter']),
          isNot(starWarsComments.where('genre', arrayContains: ['Flutter'])),
        );
      });

      test('differentiate queries from a different app instance', () async {
        final fooApp = await Firebase.initializeApp(
          name: 'foo',
          options: Firebase.app().options,
        );

        expect(
          FirebaseFirestore.instanceFor(app: fooApp)
              .collection('movies')
              .limit(42),
          FirebaseFirestore.instanceFor(app: fooApp)
              .collection('movies')
              .limit(42),
        );

        expect(
          FirebaseFirestore.instance.collection('movies').limit(42),
          isNot(
            FirebaseFirestore.instanceFor(app: fooApp)
                .collection('movies')
                .limit(42),
          ),
        );
      });

      test('differentiate collection group', () {
        expect(
          firestore.collectionGroup('comments').limit(42),
          firestore.collectionGroup('comments').limit(42),
        );
        expect(
          firestore.collectionGroup('comments').limit(42),
          isNot(firestore.collection('comments').limit(42)),
        );
      });
    });

    /**
     * collectionGroup
     */
    group('collectionGroup()', () {
      test('returns a data via a sub-collection', () async {
        CollectionReference<Map<String, dynamic>> collection =
            firestore.collection('flutter-tests/collection-group/group-test');
        QuerySnapshot<Map<String, dynamic>> snapshot = await collection.get();

        await Future.forEach(snapshot.docs,
            (DocumentSnapshot documentSnapshot) {
          return documentSnapshot.reference.delete();
        });

        await collection.doc('doc1').set({'foo': 1});
        await collection.doc('doc2').set({'foo': 2});

        QuerySnapshot<Map<String, dynamic>> groupSnapshot = await firestore
            .collectionGroup('group-test')
            .orderBy('foo', descending: true)
            .get();
        expect(groupSnapshot.size, equals(2));
        expect(groupSnapshot.docs[0].data()['foo'], equals(2));
        expect(groupSnapshot.docs[1].data()['foo'], equals(1));
      });
    });

    /**
     * get
     */
    group('Query.get()', () {
      test('returns a [QuerySnapshot]', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('get');
        QuerySnapshot<Map<String, dynamic>> qs = await collection.get();
        expect(qs, isA<QuerySnapshot<Map<String, dynamic>>>());
      });

      test('uses [GetOptions] cache', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('get');
        QuerySnapshot<Map<String, dynamic>> qs =
            await collection.get(const GetOptions(source: Source.cache));
        expect(qs, isA<QuerySnapshot<Map<String, dynamic>>>());
        expect(qs.metadata.isFromCache, isTrue);
      });

      test('uses [GetOptions] server', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('get');
        QuerySnapshot<Map<String, dynamic>> qs =
            await collection.get(const GetOptions(source: Source.server));
        expect(qs, isA<QuerySnapshot<Map<String, dynamic>>>());
        expect(qs.metadata.isFromCache, isFalse);
      });

      test('uses [GetOptions] serverTimestampBehavior previous', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('get');
        QuerySnapshot<Map<String, dynamic>> qs = await collection.get(
          const GetOptions(
            serverTimestampBehavior: ServerTimestampBehavior.previous,
          ),
        );
        expect(qs, isA<QuerySnapshot<Map<String, dynamic>>>());
      });

      test('uses [GetOptions] serverTimestampBehavior estimate', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('get');
        QuerySnapshot<Map<String, dynamic>> qs = await collection.get(
          const GetOptions(
            serverTimestampBehavior: ServerTimestampBehavior.estimate,
          ),
        );
        expect(qs, isA<QuerySnapshot<Map<String, dynamic>>>());
      });

      test('throws a [FirebaseException]', () async {
        CollectionReference<Map<String, dynamic>> collection =
            firestore.collection('not-allowed');

        try {
          await collection.get();
        } catch (error) {
          expect(error, isA<FirebaseException>());
          expect(
            (error as FirebaseException).code,
            equals('permission-denied'),
          );
          return;
        }
        fail('Should have thrown a [FirebaseException]');
      });
    });

    /**
     * snapshots
     */
    group('Query.snapshots()', () {
      test('returns a [Stream]', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('get');
        Stream<QuerySnapshot<Map<String, dynamic>>> stream =
            collection.snapshots();
        expect(stream, isA<Stream<QuerySnapshot<Map<String, dynamic>>>>());
      });

      test('listens to a single response', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('get-single');
        await collection.add({'foo': 'bar'});
        Stream<QuerySnapshot<Map<String, dynamic>>> stream =
            collection.snapshots();
        int call = 0;

        stream.listen(
          expectAsync1(
            (QuerySnapshot<Map<String, dynamic>> snapshot) {
              call++;
              if (call == 1) {
                expect(snapshot.docs.length, equals(1));

                expect(snapshot.docs[0], isA<QueryDocumentSnapshot>());
                QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot =
                    snapshot.docs[0];
                expect(documentSnapshot.data()['foo'], equals('bar'));
              } else {
                fail('Should not have been called');
              }
            },
            count: 1,
            reason: 'Stream should only have been called once.',
          ),
        );
      });

      test('listens to multiple queries', () async {
        CollectionReference<Map<String, dynamic>> collection1 =
            await initializeTest('document-snapshot-1');
        CollectionReference<Map<String, dynamic>> collection2 =
            await initializeTest('document-snapshot-2');

        await collection1.add({'test': 'value1'});
        await collection2.add({'test': 'value2'});

        final value1 = collection1
            .snapshots()
            .first
            .then((s) => s.docs.first.data()['test']);
        final value2 = collection2
            .snapshots()
            .first
            .then((s) => s.docs.first.data()['test']);

        await expectLater(value1, completion('value1'));
        await expectLater(value2, completion('value2'));
      });

      test('listens to a multiple changes response', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('get-multiple');
        await collection.add({'foo': 'bar'});

        Stream<QuerySnapshot<Map<String, dynamic>>> stream =
            collection.snapshots();
        int call = 0;

        StreamSubscription subscription = stream.listen(
          expectAsync1(
            (QuerySnapshot<Map<String, dynamic>> snapshot) {
              call++;
              if (call == 1) {
                expect(snapshot.docs.length, equals(1));
                QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot =
                    snapshot.docs[0];
                expect(documentSnapshot.data()['foo'], equals('bar'));
              } else if (call == 2) {
                expect(snapshot.docs.length, equals(2));
                QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot =
                    snapshot.docs.firstWhere((doc) => doc.id == 'doc1');
                expect(documentSnapshot.data()['bar'], equals('baz'));
              } else if (call == 3) {
                expect(snapshot.docs.length, equals(1));
                expect(
                  snapshot.docs.where((doc) => doc.id == 'doc1').isEmpty,
                  isTrue,
                );
              } else if (call == 4) {
                expect(snapshot.docs.length, equals(2));
                QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot =
                    snapshot.docs.firstWhere((doc) => doc.id == 'doc2');
                expect(documentSnapshot.data()['foo'], equals('bar'));
              } else if (call == 5) {
                expect(snapshot.docs.length, equals(2));
                QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot =
                    snapshot.docs.firstWhere((doc) => doc.id == 'doc2');
                expect(documentSnapshot.data()['foo'], equals('baz'));
              } else {
                fail('Should not have been called');
              }
            },
            count: 5,
            reason: 'Stream should only have been called five times.',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        await collection.doc('doc1').set({'bar': 'baz'});
        await collection.doc('doc1').delete();
        await collection.doc('doc2').set({'foo': 'bar'});
        await collection.doc('doc2').update({'foo': 'baz'});

        await subscription.cancel();
      });

      test('listeners throws a [FirebaseException]', () async {
        CollectionReference<Map<String, dynamic>> collection =
            firestore.collection('not-allowed');
        Stream<QuerySnapshot<Map<String, dynamic>>> stream =
            collection.snapshots();

        try {
          await stream.first;
        } catch (error) {
          expect(error, isA<FirebaseException>());
          expect(
            (error as FirebaseException).code,
            equals(
              'permission-denied',
            ),
          );
          return;
        }

        fail('Should have thrown a [FirebaseException]');
      });
    });

    /**
     * End At
     */

    group('Query.endAt{Document}()', () {
      test('ends at string field paths', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('endAt-string');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'foo': 2,
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'foo': 3,
            'bar': {'value': 3}
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy('bar.value', descending: true)
            .endAt([2]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc2'));

        QuerySnapshot<Map<String, dynamic>> snapshot2 =
            await collection.orderBy('foo').endAt([2]).get();

        expect(snapshot2.docs.length, equals(2));
        expect(snapshot2.docs[0].id, equals('doc1'));
        expect(snapshot2.docs[1].id, equals('doc2'));
      });

      test('ends at field paths', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('endAt-field-path');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'foo': 2,
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'foo': 3,
            'bar': {'value': 3}
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy(FieldPath(const ['bar', 'value']), descending: true)
            .endAt([2]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc2'));

        QuerySnapshot<Map<String, dynamic>> snapshot2 =
            await collection.orderBy(FieldPath(const ['foo'])).endAt([2]).get();

        expect(snapshot2.docs.length, equals(2));
        expect(snapshot2.docs[0].id, equals('doc1'));
        expect(snapshot2.docs[1].id, equals('doc2'));
      });

      test('endAtDocument() ends at a document field value', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('endAt-document');
        await Future.wait([
          collection.doc('doc1').set({
            'bar': {'value': 3}
          }),
          collection.doc('doc2').set({
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'bar': {'value': 1}
          }),
        ]);

        DocumentSnapshot endAtSnapshot = await collection.doc('doc2').get();

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy('bar.value')
            .endAtDocument(endAtSnapshot)
            .get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc2'));
      });

      test('endAtDocument() ends at a document', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('endAt-document');
        await Future.wait([
          collection.doc('doc1').set({
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'bar': {'value': 3}
          }),
          collection.doc('doc4').set({
            'bar': {'value': 4}
          }),
        ]);

        DocumentSnapshot endAtSnapshot = await collection.doc('doc3').get();

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.endAtDocument(endAtSnapshot).get();

        expect(snapshot.docs.length, equals(3));
        expect(snapshot.docs[0].id, equals('doc1'));
        expect(snapshot.docs[1].id, equals('doc2'));
        expect(snapshot.docs[2].id, equals('doc3'));
      });
    });

    /**
     * Start At
     */

    group('Query.startAt{Document}()', () {
      test('starts at string field paths', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('startAt-string');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'foo': 2,
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'foo': 3,
            'bar': {'value': 3}
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy('bar.value', descending: true)
            .startAt([2]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc2'));
        expect(snapshot.docs[1].id, equals('doc1'));

        QuerySnapshot<Map<String, dynamic>> snapshot2 =
            await collection.orderBy('foo').startAt([2]).get();

        expect(snapshot2.docs.length, equals(2));
        expect(snapshot2.docs[0].id, equals('doc2'));
        expect(snapshot2.docs[1].id, equals('doc3'));
      });

      test('starts at field paths', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('startAt-field-path');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'foo': 2,
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'foo': 3,
            'bar': {'value': 3}
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy(FieldPath(const ['bar', 'value']), descending: true)
            .startAt([2]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc2'));
        expect(snapshot.docs[1].id, equals('doc1'));

        QuerySnapshot<Map<String, dynamic>> snapshot2 = await collection
            .orderBy(FieldPath(const ['foo']))
            .startAt([2]).get();

        expect(snapshot2.docs.length, equals(2));
        expect(snapshot2.docs[0].id, equals('doc2'));
        expect(snapshot2.docs[1].id, equals('doc3'));
      });

      test('startAtDocument() starts at a document field value', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('startAt-document-field-value');
        await Future.wait([
          collection.doc('doc1').set({
            'bar': {'value': 3}
          }),
          collection.doc('doc2').set({
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'bar': {'value': 1}
          }),
        ]);

        DocumentSnapshot startAtSnapshot = await collection.doc('doc2').get();

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy('bar.value')
            .startAtDocument(startAtSnapshot)
            .get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc2'));
        expect(snapshot.docs[1].id, equals('doc1'));
      });

      test('startAtDocument() starts at a document', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('startAt-document');
        await Future.wait([
          collection.doc('doc1').set({
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'bar': {'value': 3}
          }),
          collection.doc('doc4').set({
            'bar': {'value': 4}
          }),
        ]);

        DocumentSnapshot startAtSnapshot = await collection.doc('doc3').get();

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.startAtDocument(startAtSnapshot).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc4'));
      });
    });

    /**
     * End Before
     */

    group('Query.endBefore{Document}()', () {
      test('ends before string field paths', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('endBefore-string');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'foo': 2,
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'foo': 3,
            'bar': {'value': 3}
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy('bar.value', descending: true)
            .endBefore([1]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc2'));

        QuerySnapshot<Map<String, dynamic>> snapshot2 =
            await collection.orderBy('foo').endBefore([3]).get();

        expect(snapshot2.docs.length, equals(2));
        expect(snapshot2.docs[0].id, equals('doc1'));
        expect(snapshot2.docs[1].id, equals('doc2'));
      });

      test('ends before field paths', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('endBefore-field-path');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'foo': 2,
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'foo': 3,
            'bar': {'value': 3}
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy(FieldPath(const ['bar', 'value']), descending: true)
            .endBefore([1]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc2'));

        QuerySnapshot<Map<String, dynamic>> snapshot2 = await collection
            .orderBy(FieldPath(const ['foo']))
            .endBefore([3]).get();

        expect(snapshot2.docs.length, equals(2));
        expect(snapshot2.docs[0].id, equals('doc1'));
        expect(snapshot2.docs[1].id, equals('doc2'));
      });

      test('endbeforeDocument() ends before a document field value', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('endBefore-document-field-value');
        await Future.wait([
          collection.doc('doc1').set({
            'bar': {'value': 3}
          }),
          collection.doc('doc2').set({
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'bar': {'value': 1}
          }),
        ]);

        DocumentSnapshot endAtSnapshot = await collection.doc('doc1').get();

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .orderBy('bar.value')
            .endBeforeDocument(endAtSnapshot)
            .get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc2'));
      });

      test('endBeforeDocument() ends before a document', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('endBefore-document');
        await Future.wait([
          collection.doc('doc1').set({
            'bar': {'value': 1}
          }),
          collection.doc('doc2').set({
            'bar': {'value': 2}
          }),
          collection.doc('doc3').set({
            'bar': {'value': 3}
          }),
          collection.doc('doc4').set({
            'bar': {'value': 4}
          }),
        ]);

        DocumentSnapshot endAtSnapshot = await collection.doc('doc4').get();

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.endBeforeDocument(endAtSnapshot).get();

        expect(snapshot.docs.length, equals(3));
        expect(snapshot.docs[0].id, equals('doc1'));
        expect(snapshot.docs[1].id, equals('doc2'));
        expect(snapshot.docs[2].id, equals('doc3'));
      });
    });

    /**
     * Start & End
     */

    group('Query.startAt/endAt', () {
      test('starts at & ends at a document', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('start-end-string');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
          }),
          collection.doc('doc2').set({
            'foo': 2,
          }),
          collection.doc('doc3').set({
            'foo': 3,
          }),
          collection.doc('doc4').set({
            'foo': 4,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.orderBy('foo').startAt([2]).endAt([3]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc2'));
        expect(snapshot.docs[1].id, equals('doc3'));
      });

      test('starts at & ends before a document', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('start-end-string');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
          }),
          collection.doc('doc2').set({
            'foo': 2,
          }),
          collection.doc('doc3').set({
            'foo': 3,
          }),
          collection.doc('doc4').set({
            'foo': 4,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.orderBy('foo').startAt([2]).endBefore([4]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc2'));
        expect(snapshot.docs[1].id, equals('doc3'));
      });

      test('starts after & ends at a document', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('start-end-field-path');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
          }),
          collection.doc('doc2').set({
            'foo': 2,
          }),
          collection.doc('doc3').set({
            'foo': 3,
          }),
          collection.doc('doc4').set({
            'foo': 4,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.orderBy('foo').startAfter([1]).endAt([3]).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc2'));
        expect(snapshot.docs[1].id, equals('doc3'));
      });

      test('starts a document and ends before document', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('start-end-document');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
          }),
          collection.doc('doc2').set({
            'foo': 2,
          }),
          collection.doc('doc3').set({
            'foo': 3,
          }),
          collection.doc('doc4').set({
            'foo': 4,
          }),
        ]);

        DocumentSnapshot startAtSnapshot = await collection.doc('doc2').get();
        DocumentSnapshot endBeforeSnapshot = await collection.doc('doc4').get();

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .startAtDocument(startAtSnapshot)
            .endBeforeDocument(endBeforeSnapshot)
            .get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc2'));
        expect(snapshot.docs[1].id, equals('doc3'));
      });
    });

    /**
     * Limit
     */

    group('Query.limit{toLast}()', () {
      test('limits documents', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('limit');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
          }),
          collection.doc('doc2').set({
            'foo': 2,
          }),
          collection.doc('doc3').set({
            'foo': 3,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.limit(2).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc1'));
        expect(snapshot.docs[1].id, equals('doc2'));

        QuerySnapshot<Map<String, dynamic>> snapshot2 =
            await collection.orderBy('foo', descending: true).limit(2).get();

        expect(snapshot2.docs.length, equals(2));
        expect(snapshot2.docs[0].id, equals('doc3'));
        expect(snapshot2.docs[1].id, equals('doc2'));
      });

      test('limits to last documents', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('limitToLast');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
          }),
          collection.doc('doc2').set({
            'foo': 2,
          }),
          collection.doc('doc3').set({
            'foo': 3,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.orderBy('foo').limitToLast(2).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc2'));
        expect(snapshot.docs[1].id, equals('doc3'));

        QuerySnapshot<Map<String, dynamic>> snapshot2 = await collection
            .orderBy('foo', descending: true)
            .limitToLast(2)
            .get();

        expect(snapshot2.docs.length, equals(2));
        expect(snapshot2.docs[0].id, equals('doc2'));
        expect(snapshot2.docs[1].id, equals('doc1'));
      });
    });

    /**
     * Order
     */
    group('Query.orderBy()', () {
      test('allows ordering by documentId', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('order-document-id');

        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
          }),
          collection.doc('doc2').set({
            'foo': 1,
          }),
          collection.doc('doc3').set({
            'foo': 1,
          }),
          collection.doc('doc4').set({
            'bar': 1,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.orderBy('foo').orderBy(FieldPath.documentId).get();

        expect(snapshot.docs.length, equals(3));
        expect(snapshot.docs[0].id, equals('doc1'));
        expect(snapshot.docs[1].id, equals('doc2'));
        expect(snapshot.docs[2].id, equals('doc3'));
      });

      test('orders async by default', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('order-asc');

        await Future.wait([
          collection.doc('doc1').set({
            'foo': 3,
          }),
          collection.doc('doc2').set({
            'foo': 2,
          }),
          collection.doc('doc3').set({
            'foo': 1,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.orderBy('foo').get();

        expect(snapshot.docs.length, equals(3));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc2'));
        expect(snapshot.docs[2].id, equals('doc1'));
      });

      test('orders descending', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('order-desc');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 1,
          }),
          collection.doc('doc2').set({
            'foo': 2,
          }),
          collection.doc('doc3').set({
            'foo': 3,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.orderBy('foo', descending: true).get();

        expect(snapshot.docs.length, equals(3));
        expect(snapshot.docs[0].id, equals('doc3'));
        expect(snapshot.docs[1].id, equals('doc2'));
        expect(snapshot.docs[2].id, equals('doc1'));
      });
    });

    /**
     * Where filters
     */

    group('Query.where()', () {
      test('returns documents when querying for properties that are not null',
          () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('not-null');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 'bar',
          }),
          collection.doc('doc2').set({
            'foo': 'bar',
          }),
          collection.doc('doc3').set({
            'foo': null,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', isNull: false).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].id, equals('doc1'));
        expect(snapshot.docs[1].id, equals('doc2'));
      });

      test('returns documents when querying properties that are equal to null',
          () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('not-null');
        await Future.wait([
          collection.doc('doc1').set({
            'foo': 'bar',
          }),
          collection.doc('doc2').set({
            'foo': 'bar',
          }),
          collection.doc('doc3').set({
            'foo': null,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', isNull: true).get();

        expect(snapshot.docs.length, equals(1));
        expect(snapshot.docs[0].id, equals('doc3'));
      });

      test('returns with equal checks', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-equal');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.doc('doc1').set({
            'foo': rand,
          }),
          collection.doc('doc2').set({
            'foo': rand,
          }),
          collection.doc('doc3').set({
            'foo': rand + 1,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', isEqualTo: rand).get();

        expect(snapshot.docs.length, equals(2));
        snapshot.docs.forEach((doc) {
          expect(doc.data()['foo'], equals(rand));
        });
      });

      test('returns with not equal checks', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-not-equal');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.doc('doc1').set({
            'foo': rand,
          }),
          collection.doc('doc2').set({
            'foo': rand,
          }),
          collection.doc('doc3').set({
            'foo': rand + 1,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', isNotEqualTo: rand).get();

        expect(snapshot.docs.length, equals(1));
        snapshot.docs.forEach((doc) {
          expect(doc.data()['foo'], equals(rand + 1));
        });
      });

      test('returns with greater than checks', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-greater-than');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.doc('doc1').set({
            'foo': rand - 1,
          }),
          collection.doc('doc2').set({
            'foo': rand,
          }),
          collection.doc('doc3').set({
            'foo': rand + 1,
          }),
          collection.doc('doc4').set({
            'foo': rand + 2,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', isGreaterThan: rand).get();

        expect(snapshot.docs.length, equals(2));
        snapshot.docs.forEach((doc) {
          expect(doc.data()['foo'] > rand, isTrue);
        });
      });

      test('returns with greater than or equal to checks', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-greater-than-equal');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.doc('doc1').set({
            'foo': rand - 1,
          }),
          collection.doc('doc2').set({
            'foo': rand,
          }),
          collection.doc('doc3').set({
            'foo': rand + 1,
          }),
          collection.doc('doc4').set({
            'foo': rand + 2,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', isGreaterThanOrEqualTo: rand).get();

        expect(snapshot.docs.length, equals(3));
        snapshot.docs.forEach((doc) {
          expect(doc.data()['foo'] >= rand, isTrue);
        });
      });

      test('returns with less than checks', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-less-than');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.doc('doc1').set({
            'foo': -rand + 1,
          }),
          collection.doc('doc2').set({
            'foo': -rand + 2,
          }),
          collection.doc('doc3').set({
            'foo': rand,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', isLessThan: rand).get();

        expect(snapshot.docs.length, equals(2));
        snapshot.docs.forEach((doc) {
          expect(doc.data()['foo'] < rand, isTrue);
        });
      });

      test('returns with less than equal checks', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-less-than');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.doc('doc1').set({
            'foo': -rand + 1,
          }),
          collection.doc('doc2').set({
            'foo': -rand + 2,
          }),
          collection.doc('doc3').set({
            'foo': rand,
          }),
          collection.doc('doc4').set({
            'foo': rand + 1,
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', isLessThanOrEqualTo: rand).get();

        expect(snapshot.docs.length, equals(3));
        snapshot.docs.forEach((doc) {
          expect(doc.data()['foo'] <= rand, isTrue);
        });
      });

      test('returns with array-contains filter', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-array-contains');
        int rand = Random().nextInt(9999);

        await Future.wait([
          collection.doc('doc1').set({
            'foo': [1, '2', rand],
          }),
          collection.doc('doc2').set({
            'foo': [1, '2', '$rand'],
          }),
          collection.doc('doc3').set({
            'foo': [1, '2', '$rand'],
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where('foo', arrayContains: '$rand').get();

        expect(snapshot.docs.length, equals(2));
        snapshot.docs.forEach((doc) {
          expect(doc.data()['foo'], equals([1, '2', '$rand']));
        });
      });

      test('returns with in filter', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-in');

        await Future.wait([
          collection.doc('doc1').set({
            'status': 'Ordered',
          }),
          collection.doc('doc2').set({
            'status': 'Ready to Ship',
          }),
          collection.doc('doc3').set({
            'status': 'Ready to Ship',
          }),
          collection.doc('doc4').set({
            'status': 'Incomplete',
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .where('status', whereIn: ['Ready to Ship', 'Ordered']).get();

        expect(snapshot.docs.length, equals(3));
        snapshot.docs.forEach((doc) {
          String status = doc.data()['status'];
          expect(status == 'Ready to Ship' || status == 'Ordered', isTrue);
        });
      });

      test('returns with in filter', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-in');

        await Future.wait([
          collection.doc('doc1').set({
            'status': 'Ordered',
          }),
          collection.doc('doc2').set({
            'status': 'Ready to Ship',
          }),
          collection.doc('doc3').set({
            'status': 'Ready to Ship',
          }),
          collection.doc('doc4').set({
            'status': 'Incomplete',
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .where('status', whereIn: ['Ready to Ship', 'Ordered']).get();

        expect(snapshot.docs.length, equals(3));
        snapshot.docs.forEach((doc) {
          String status = doc.data()['status'];
          expect(status == 'Ready to Ship' || status == 'Ordered', isTrue);
        });
      });

      test('returns with not-in filter', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-not-in');

        await Future.wait([
          collection.doc('doc1').set({
            'status': 'Ordered',
          }),
          collection.doc('doc2').set({
            'status': 'Ready to Ship',
          }),
          collection.doc('doc3').set({
            'status': 'Ready to Ship',
          }),
          collection.doc('doc4').set({
            'status': 'Incomplete',
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .where('status', whereNotIn: ['Ready to Ship', 'Ordered']).get();

        expect(snapshot.docs.length, equals(1));
        snapshot.docs.forEach((doc) {
          String status = doc.data()['status'];
          expect(status == 'Incomplete', isTrue);
        });
      });

      test('returns with array-contains-any filter', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-array-contains-any');

        await Future.wait([
          collection.doc('doc1').set({
            'category': ['Appliances', 'Housewares', 'Cooking'],
          }),
          collection.doc('doc2').set({
            'category': ['Appliances', 'Electronics', 'Nursery'],
          }),
          collection.doc('doc3').set({
            'category': ['Audio/Video', 'Electronics'],
          }),
          collection.doc('doc4').set({
            'category': ['Beauty'],
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection.where(
          'category',
          arrayContainsAny: ['Appliances', 'Electronics'],
        ).get();

        // 2nd record should only be returned once
        expect(snapshot.docs.length, equals(3));
      });

      // When documents have a key with a '.' in them, only a [FieldPath]
      // can access the value, rather than a raw string
      test('returns where FieldPath', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-field-path');

        FieldPath fieldPath = FieldPath(const ['nested', 'foo.bar@gmail.com']);

        await Future.wait([
          collection.doc('doc1').set({
            'nested': {
              'foo.bar@gmail.com': true,
            }
          }),
          collection.doc('doc2').set({
            'nested': {
              'foo.bar@gmail.com': true,
            },
            'foo': 'bar',
          }),
          collection.doc('doc3').set({
            'nested': {
              'foo.bar@gmail.com': false,
            }
          }),
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot =
            await collection.where(fieldPath, isEqualTo: true).get();

        expect(snapshot.docs.length, equals(2));
        expect(snapshot.docs[0].get(fieldPath), isTrue);
        expect(snapshot.docs[1].get(fieldPath), isTrue);
        expect(snapshot.docs[1].get('foo'), equals('bar'));
      });

      test('returns results using FieldPath.documentId', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-field-path-document-id');

        DocumentReference<Map<String, dynamic>> docRef = await collection.add({
          'foo': 'bar',
        });

        // Add secondary document for sanity check
        await collection.add({
          'bar': 'baz',
        });

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .where(FieldPath.documentId, isEqualTo: docRef.id)
            .get();

        expect(snapshot.docs.length, equals(1));
        expect(snapshot.docs[0].get('foo'), equals('bar'));
      });

      test('returns an encoded DocumentReference', () async {
        CollectionReference<Map<String, dynamic>> collection =
            await initializeTest('where-document-reference');

        DocumentReference<Map<String, dynamic>> ref =
            FirebaseFirestore.instance.doc('foo/bar');

        await Future.wait([
          collection.add({
            'foo': ref,
          }),
          collection.add({
            'foo': FirebaseFirestore.instance.doc('bar/baz'),
          }),
          collection.add({
            'foo': 'foo/bar',
          })
        ]);

        QuerySnapshot<Map<String, dynamic>> snapshot = await collection
            .where('foo', isEqualTo: FirebaseFirestore.instance.doc('foo/bar'))
            .get();

        expect(snapshot.docs.length, equals(1));
        expect(snapshot.docs[0].get('foo'), equals(ref));
      });
    });

    group('withConverter', () {
      test(
        'from a query instead of collection',
        () async {
          final collection = await initializeTest('foo');

          final query = collection //
              .where('value', isGreaterThan: 0)
              .withConverter<int>(
                fromFirestore: (snapshots, _) =>
                    snapshots.data()!['value']! as int,
                toFirestore: (value, _) => {'value': value},
              );

          await collection.add({'value': 42});
          await collection.add({'value': -1});

          final snapshot = query.snapshots();

          await expectLater(
            snapshot,
            emits(
              isA<QuerySnapshot<int>>().having((e) => e.docs, 'docs', [
                isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 42)
              ]),
            ),
          );

          await collection.add({'value': 21});

          await expectLater(
            snapshot,
            emits(
              isA<QuerySnapshot<int>>().having(
                (e) => e.docs,
                'docs',
                unorderedEquals(
                  [
                    isA<DocumentSnapshot<int>>()
                        .having((e) => e.data(), 'data', 42),
                    isA<DocumentSnapshot<int>>()
                        .having((e) => e.data(), 'data', 21)
                  ],
                ),
              ),
            ),
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'snapshots',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(42);
          await converted.add(-1);

          final snapshot =
              converted.where('value', isGreaterThan: 0).snapshots();

          await expectLater(
            snapshot,
            emits(
              isA<QuerySnapshot<int>>().having((e) => e.docs, 'docs', [
                isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 42)
              ]),
            ),
          );

          await converted.add(21);

          await expectLater(
            snapshot,
            emits(
              isA<QuerySnapshot<int>>().having(
                (e) => e.docs,
                'docs',
                unorderedEquals([
                  isA<DocumentSnapshot<int>>()
                      .having((e) => e.data(), 'data', 42),
                  isA<DocumentSnapshot<int>>()
                      .having((e) => e.data(), 'data', 21)
                ]),
              ),
            ),
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'get',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(42);
          await converted.add(-1);

          expect(
            await converted
                .where('value', isGreaterThan: 0)
                .get()
                .then((d) => d.docs),
            [isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 42)],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'orderBy',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(42);
          await converted.add(21);

          expect(
            await converted.orderBy('value').get().then((d) => d.docs),
            [
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 21),
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 42)
            ],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'limit',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(42);
          await converted.add(21);

          expect(
            await converted.orderBy('value').limit(1).get().then((d) => d.docs),
            [
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 21),
            ],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'limitToLast',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(42);
          await converted.add(21);

          expect(
            await converted
                .orderBy('value')
                .limitToLast(1)
                .get()
                .then((d) => d.docs),
            [
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 42),
            ],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test('endAt', () async {
        final collection = await initializeTest('foo');

        final converted = collection.withConverter<int>(
          fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
          toFirestore: (value, _) => {'value': value},
        );

        await converted.add(1);
        await converted.add(2);
        await converted.add(3);

        expect(
          await converted.orderBy('value').endAt([2]).get().then((d) => d.docs),
          [
            isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 1),
            isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 2),
          ],
        );
      });

      test(
        'endAtDocument',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(1);
          final doc2 = await converted.add(2);
          await converted.add(3);

          expect(
            await converted
                .orderBy('value')
                .endAtDocument(await doc2.get())
                .get()
                .then((d) => d.docs),
            [
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 1),
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 2),
            ],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test('endBefore', () async {
        final collection = await initializeTest('foo');

        final converted = collection.withConverter<int>(
          fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
          toFirestore: (value, _) => {'value': value},
        );

        await converted.add(1);
        await converted.add(2);
        await converted.add(3);

        expect(
          await converted
              .orderBy('value')
              .endBefore([2])
              .get()
              .then((d) => d.docs),
          [isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 1)],
        );
      });

      test(
        'endBeforeDocument',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(1);
          final doc2 = await converted.add(2);
          await converted.add(3);

          expect(
            await converted
                .orderBy('value')
                .endBeforeDocument(await doc2.get())
                .get()
                .then((d) => d.docs),
            [isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 1)],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'startAt',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(1);
          await converted.add(2);
          await converted.add(3);

          expect(
            await converted
                .orderBy('value')
                .startAt([2])
                .get()
                .then((d) => d.docs),
            [
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 2),
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 3),
            ],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'startAtDocument',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(1);
          final doc2 = await converted.add(2);
          await converted.add(3);

          expect(
            await converted
                .orderBy('value')
                .startAtDocument(await doc2.get())
                .get()
                .then((d) => d.docs),
            [
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 2),
              isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 3),
            ],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'startAfter',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(1);
          await converted.add(2);
          await converted.add(3);

          expect(
            await converted
                .orderBy('value')
                .startAfter([2])
                .get()
                .then((d) => d.docs),
            [isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 3)],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'startAfterDocument',
        () async {
          final collection = await initializeTest('foo');

          final converted = collection.withConverter<int>(
            fromFirestore: (snapshots, _) => snapshots.data()!['value']! as int,
            toFirestore: (value, _) => {'value': value},
          );

          await converted.add(1);
          final doc2 = await converted.add(2);
          await converted.add(3);

          expect(
            await converted
                .orderBy('value')
                .startAfterDocument(await doc2.get())
                .get()
                .then((d) => d.docs),
            [isA<DocumentSnapshot<int>>().having((e) => e.data(), 'data', 3)],
          );
        },
        timeout: const Timeout.factor(3),
      );

      test(
        'count()',
        () async {
          final collection = await initializeTest('count');

          await Future.wait([
            collection.add({'foo': 'bar'}),
            collection.add({'bar': 'baz'})
          ]);

          AggregateQuery query = collection.count();

          AggregateQuerySnapshot snapshot = await query.get();

          expect(
            snapshot.count,
            2,
          );
        },
      );

      test(
        'count() with query',
        () async {
          final collection = await initializeTest('count');

          await Future.wait([
            collection.add({'foo': 'bar'}),
            collection.add({'foo': 'baz'})
          ]);

          AggregateQuery query =
              collection.where('foo', isEqualTo: 'bar').count();

          AggregateQuerySnapshot snapshot = await query.get();

          expect(
            snapshot.count,
            1,
          );
        },
      );
    });
  });
}
