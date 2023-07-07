// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import './mock.dart';
import './test_firestore_message_codec.dart';

void main() {
  setupCloudFirestoreMocks();
  MethodChannelFirebaseFirestore.channel = const MethodChannel(
    'plugins.flutter.io/firebase_firestore',
    StandardMethodCodec(TestFirestoreMessageCodec()),
  )..setMockMethodCallHandler((call) async {
      return null;
    });
  late FirebaseFirestore firestore;
  late FirebaseFirestore firestoreSecondary;

  group('$DocumentReference', () {
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

    test('equality', () {
      DocumentReference ref = firestore.doc('foo/bar');
      DocumentReference ref2 = firestore.doc('foo/bar/baz/bert');

      expect(ref, equals(firestore.doc('foo/bar')));
      expect(ref2, equals(firestore.doc('foo/bar/baz/bert')));

      expect(ref == firestoreSecondary.doc('foo/bar'), isFalse);
      expect(ref2 == firestoreSecondary.doc('foo/bar/baz/bert'), isFalse);

      expect(ref.hashCode, ref.hashCode);
      expect(ref, ref);
      expect(ref.hashCode, isNot(ref2.hashCode));
      expect(ref, isNot(ref2));
    });

    test('toString', () async {
      expect(
        firestore.doc('foo/bar').toString(),
        'DocumentReference<Map<String, dynamic>>(foo/bar)',
      );
    });

    test('returns document() returns a $DocumentReference', () {
      DocumentReference ref = firestore.doc('foo/bar');
      DocumentReference ref2 = firestore.doc('foo/bar/baz/bert');

      expect(ref, isA<DocumentReference>());
      expect(ref2, isA<DocumentReference>());
    });

    test('returns the same firestore instance', () {
      DocumentReference ref = firestore.doc('foo/bar');
      DocumentReference ref2 = firestoreSecondary.doc('foo/bar');

      expect(ref.firestore, equals(firestore));
      expect(ref2.firestore, equals(firestoreSecondary));
    });

    test('returns the correct ID', () {
      DocumentReference ref = firestore.doc('foo/bar');
      DocumentReference ref2 = firestore.doc('foo/bar/baz/bert');

      expect(ref, isA<DocumentReference>());
      expect(ref.id, equals('bar'));
      expect(ref2.id, equals('bert'));
    });

    group('.parent', () {
      test('returns a $CollectionReference', () {
        DocumentReference ref = firestore.doc('foo/bar');

        expect(ref.parent, isA<CollectionReference>());
      });

      test('returns the correct $CollectionReference', () {
        DocumentReference ref = firestore.doc('foo/bar');
        CollectionReference colRef = firestore.collection('foo');

        expect(ref.parent, equals(colRef));
      });
    });

    test('path must be a non-empty string', () {
      CollectionReference ref = firestore.collection('foo');
      expect(() => firestore.doc(''), throwsAssertionError);
      expect(() => ref.doc(''), throwsAssertionError);
    });

    test('path must be even-length', () {
      CollectionReference ref = firestore.collection('foo');
      expect(() => firestore.doc('foo'), throwsAssertionError);
      expect(() => firestore.doc('foo/bar/baz'), throwsAssertionError);
      expect(() => ref.doc('/'), throwsAssertionError);
    });

    test('merge options', () {
      DocumentReference ref = firestore.collection('foo').doc();
      // can't specify both merge and mergeFields
      expect(
        () => ref.set({}, SetOptions(merge: true, mergeFields: [])),
        throwsAssertionError,
      );
      expect(
        () => ref.set({}, SetOptions(merge: false, mergeFields: [])),
        throwsAssertionError,
      );
      // all mergeFields to be a string or a FieldPath
      expect(
        () => ref.set({}, SetOptions(mergeFields: ['foo', false])),
        throwsAssertionError,
      );
    });

    group('withConverter', () {
      test('can use withConverter again', () {
        int fromFirestore(DocumentSnapshot snapshot, SnapshotOptions? _) => 42;
        Map<String, dynamic> toFirestore(Object value, SetOptions? _) => {};

        final foo = firestore.doc('foo/42');

        expect(
          foo
              .withConverter<String>(
                fromFirestore: (
                  DocumentSnapshot<Map<String, dynamic>> snapshot,
                  options,
                ) =>
                    '',
                toFirestore: (String value, options) => {},
              )
              .withConverter<int>(
                fromFirestore: fromFirestore,
                toFirestore: toFirestore,
              ),
          foo.withConverter<int>(
            fromFirestore: fromFirestore,
            toFirestore: toFirestore,
          ),
        );
      });

      test('implements ==', () {
        int fromFirestore(DocumentSnapshot snapshot, SnapshotOptions? _) => 42;
        Map<String, dynamic> toFirestore(Object value, SetOptions? _) => {};

        final foo = firestore.doc('foo/42');
        final bar = firestore.doc('bar/42');

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
        final foo = firestore.doc('foo/42');

        expect(
          foo
              .withConverter<int>(
                fromFirestore: (map, _) => 42,
                toFirestore: (value, _) => {},
              )
              .toString(),
          'DocumentReference<int>(foo/42)',
        );

        expect(
          foo
              .withConverter<double>(
                fromFirestore: (map, _) => 42,
                toFirestore: (value, _) => {},
              )
              .toString(),
          'DocumentReference<double>(foo/42)',
        );
      });

      test('id', () {
        final foo = firestore.doc('foo/42');

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
            firestore.collection('foo').doc('42').collection('bar').doc('21');

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
        int fromFirestore(DocumentSnapshot snapshot, SnapshotOptions? _) => 42;
        Map<String, dynamic> toFirestore(Object value, SetOptions? _) => {};

        final subCollection =
            firestore.collection('foo').doc('42').collection('bar').doc('21');

        expect(
          subCollection
              .withConverter(
                fromFirestore: fromFirestore,
                toFirestore: toFirestore,
              )
              .parent,
          subCollection.parent.withConverter(
            fromFirestore: fromFirestore,
            toFirestore: toFirestore,
          ),
        );
      });

      test('can encode _WithConverterDocumentReference', () async {
        final fooCollection = firestore.collection('foo').withConverter<int>(
              fromFirestore: (ds, _) => 42,
              toFirestore: (v, _) => {'key': 42},
            );

        await firestore
            .collection('bar')
            .doc()
            .set({'key': fooCollection.doc()});
      });
    });
  });
}
