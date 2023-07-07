// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import './mock.dart';

void main() {
  setupCloudFirestoreMocks();
  late FirebaseFirestore firestore;
  late FirebaseFirestore firestoreSecondary;

  group('$CollectionReference', () {
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

    test('extends $Query', () {
      // The `firestore` property is publically accessible via Query.
      // Is there a better way to test this?
      CollectionReference ref = firestore.collection('foo');

      expect(ref.firestore, equals(firestore));
    });

    test('toString', () async {
      expect(
        firestore.collection('foo').toString(),
        'CollectionReference<Map<String, dynamic>>(foo)',
      );
    });

    test('equality', () {
      CollectionReference ref = firestore.collection('foo');
      CollectionReference ref2 = firestoreSecondary.collection('foo');
      CollectionReference ref3 = firestore.collection('bar');

      expect(ref == firestore.collection('foo'), isTrue);
      expect(ref2 == firestoreSecondary.collection('foo'), isTrue);
      expect(ref3 == ref, isFalse);

      DocumentReference docRef = firestore.collection('foo').doc('bar');
      DocumentReference docRef2 =
          firestoreSecondary.collection('foo').doc('bar');

      expect(docRef, firestore.collection('foo').doc('bar'));
      expect(docRef2, firestoreSecondary.collection('foo').doc('bar'));
      expect(docRef == docRef2, isFalse);
    });

    test('returns the correct id', () {
      CollectionReference ref = firestore.collection('foo');
      CollectionReference ref2 = firestore.collection('foo/bar/baz');

      expect(ref.id, equals('foo'));
      expect(ref2.id, equals('baz'));
    });

    test('returns the correct parent', () {
      CollectionReference ref = firestore.collection('foo');
      CollectionReference ref2 = firestore.collection('foo/bar/baz');

      expect(ref.parent, isNull);
      expect(ref2.parent, isA<DocumentReference>());

      DocumentReference docRef = firestore.doc('foo/bar');
      expect(ref2.parent, equals(docRef));
    });

    test('returns the correct path', () {
      CollectionReference ref = firestore.collection('foo');
      CollectionReference ref2 = firestore.collection('foo/bar/baz');

      expect(ref.path, equals('foo'));
      expect(ref2.path, equals('foo/bar/baz'));
    });

    test('doc() returns the correct $DocumentReference', () {
      CollectionReference ref = firestore.collection('foo');

      expect(ref.doc('bar'), firestore.doc('foo/bar'));
    });

    test('path must be non-empty strings', () {
      DocumentReference docRef = firestore.doc('foo/bar');
      expect(() => firestore.collection(''), throwsAssertionError);
      expect(() => docRef.collection(''), throwsAssertionError);
    });

    test('path must be odd length', () {
      DocumentReference docRef = firestore.doc('foo/bar');
      expect(() => firestore.collection('foo/bar'), throwsAssertionError);
      expect(
        () => firestore.collection('foo/bar/baz/quu'),
        throwsAssertionError,
      );
      expect(() => docRef.collection('foo/bar'), throwsAssertionError);
      expect(() => docRef.collection('foo/bar/baz/quu'), throwsAssertionError);
    });

    test('must not have empty segments', () {
      // NOTE: Leading / trailing slashes are okay.
      firestore.collection('/foo/');
      firestore.collection('/foo');
      firestore.collection('foo/');

      const badPaths = ['foo//bar//baz', '//foo', 'foo//'];
      CollectionReference colRef = firestore.collection('test-collection');
      DocumentReference docRef = colRef.doc('test-document');

      for (final path in badPaths) {
        expect(() => firestore.collection(path), throwsAssertionError);
        expect(() => firestore.doc(path), throwsAssertionError);
        expect(() => colRef.doc(path), throwsAssertionError);
        expect(() => docRef.collection(path), throwsAssertionError);
      }
    });

    group('validate', () {
      test('path must be non-empty strings', () {
        DocumentReference docRef = firestore.doc('foo/bar');
        expect(() => firestore.collection(''), throwsAssertionError);
        expect(() => docRef.collection(''), throwsAssertionError);
      });

      test('path must be odd length', () {
        DocumentReference docRef = firestore.doc('foo/bar');
        expect(() => firestore.collection('foo/bar'), throwsAssertionError);
        expect(
          () => firestore.collection('foo/bar/baz/quu'),
          throwsAssertionError,
        );
        expect(() => docRef.collection('foo/bar'), throwsAssertionError);
        expect(
          () => docRef.collection('foo/bar/baz/quu'),
          throwsAssertionError,
        );
      });

      test('must not have empty segments', () {
        // NOTE: Leading / trailing slashes are okay.
        firestore.collection('/foo/');
        firestore.collection('/foo');
        firestore.collection('foo/');

        final badPaths = ['foo//bar//baz', '//foo', 'foo//'];
        CollectionReference colRef = firestore.collection('test-collection');
        DocumentReference docRef = colRef.doc('test-document');

        for (final String path in badPaths) {
          expect(() => firestore.collection(path), throwsAssertionError);
          expect(() => firestore.doc(path), throwsAssertionError);
          expect(() => colRef.doc(path), throwsAssertionError);
          expect(() => docRef.collection(path), throwsAssertionError);
        }
      });
    });

    group('withConverter', () {
      test('implements ==', () {
        int fromFirestore(
          DocumentSnapshot snapshot,
          SnapshotOptions? options,
        ) =>
            42;
        Map<String, dynamic> toFirestore(Object value, SetOptions? options) =>
            {};

        final foo = firestore.collection('foo');
        final bar = firestore.collection('bar');

        final intFoo = foo.withConverter<int>(
          fromFirestore: fromFirestore,
          toFirestore: toFirestore,
        );

        // utilities to check == in both directions as it is possible that
        // a == b is true but b == a is false since the former invoke a's == operator
        // while the latter invoke b's == operator
        void expectEqual(Object? a, Object? b) {
          expect(a, b);
          expect(b, a);
        }

        void expectNotEqual(Object? a, Object? b) {
          expect(a, isNot(b));
          expect(b, isNot(a));
        }

        expectEqual(
          foo.withConverter<int>(
            fromFirestore: fromFirestore,
            toFirestore: toFirestore,
          ),
          intFoo,
        );

        expectNotEqual(
          bar.withConverter<int>(
            fromFirestore: fromFirestore,
            toFirestore: toFirestore,
          ),
          intFoo,
        );

        expectNotEqual(
          foo.withConverter<Object>(
            fromFirestore: fromFirestore,
            toFirestore: toFirestore,
          ),
          intFoo,
        );

        expectNotEqual(
          foo.withConverter<int>(
            fromFirestore: (_, __) => 42,
            toFirestore: toFirestore,
          ),
          intFoo,
        );

        expectNotEqual(
          foo.withConverter<int>(
            fromFirestore: fromFirestore,
            toFirestore: (_, __) => {},
          ),
          intFoo,
        );
      });

      test('toString', () {
        final foo = firestore.collection('foo');

        expect(
          foo
              .withConverter<int>(
                fromFirestore: (map, _) => 42,
                toFirestore: (value, _) => {},
              )
              .toString(),
          'CollectionReference<int>(foo)',
        );

        expect(
          foo
              .withConverter<double>(
                fromFirestore: (map, _) => 42,
                toFirestore: (value, _) => {},
              )
              .toString(),
          'CollectionReference<double>(foo)',
        );
      });

      test('id', () {
        final foo = firestore.collection('foo');

        expect(
          foo
              .withConverter(
                fromFirestore: (_, __) => 42,
                toFirestore: (_, __) => {},
              )
              .id,
          foo.id,
        );
      });

      test('path', () {
        final subCollection =
            firestore.collection('foo').doc('42').collection('bar');

        expect(
          subCollection
              .withConverter(
                fromFirestore: (_, __) => 42,
                toFirestore: (_, __) => {},
              )
              .path,
          subCollection.path,
        );
      });

      test('parent', () {
        final subCollection =
            firestore.collection('foo').doc('42').collection('bar');

        expect(
          subCollection
              .withConverter(
                fromFirestore: (_, __) => 42,
                toFirestore: (_, __) => {},
              )
              .parent,
          subCollection.parent,
        );
      });

      test('doc', () {
        final foo = firestore.collection('foo');

        int fromFirestore(
          DocumentSnapshot snapshot,
          SnapshotOptions? options,
        ) =>
            42;
        Map<String, dynamic> toFirestore(Object value, SetOptions? options) =>
            {};

        expect(
          foo
              .withConverter(
                fromFirestore: fromFirestore,
                toFirestore: toFirestore,
              )
              .doc('42'),
          foo.doc('42').withConverter(
                fromFirestore: fromFirestore,
                toFirestore: toFirestore,
              ),
        );
      });
    });
  });
}
