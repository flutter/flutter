// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import './mock.dart';
import './test_firestore_message_codec.dart';

void main() {
  setupCloudFirestoreMocks();
  MethodChannelFirebaseFirestore.channel = const MethodChannel(
    'plugins.flutter.io/firebase_firestore',
    StandardMethodCodec(TestFirestoreMessageCodec()),
  );

  MethodChannelFirebaseFirestore.channel.setMockMethodCallHandler((call) async {
    DocumentReferencePlatform ref = call.arguments['reference'];
    if (call.method == 'DocumentReference#get' && ref.path == 'doc/exists') {
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

    if (call.method == 'DocumentReference#get' &&
        ref.path == 'doc/not-exists') {
      return {
        'data': null,
        'metadata': {
          'hasPendingWrites': false,
          'isFromCache': false,
        }
      };
    }

    if (call.method == 'DocumentReference#get' && ref.path == 'doc/get-test') {
      return {
        'data': {
          'foo': {
            'bar': 'baz',
          },
          'baz': [123, '456'],
          'ben': {
            'foo': {
              'bar': 'baz',
            }
          },
          'dot.field': true,
        },
        'metadata': {
          'hasPendingWrites': false,
          'isFromCache': false,
        }
      };
    }

    return null;
  });

  FirebaseFirestore? firestore;

  group('$DocumentSnapshot', () {
    setUpAll(() async {
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
    });

    test('returns correct id', () async {
      DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
      expect(ds.id, equals('exists'));
    });

    test('reference returns correct $DocumentReference', () async {
      DocumentReference expectedRef = firestore!.doc('doc/exists');
      DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
      expect(ds.reference, isA<DocumentReference>());
      expect(ds.reference, equals(expectedRef));
    });

    test('exists returns correct bool', () async {
      DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
      DocumentSnapshot ds2 = await firestore!.doc('doc/not-exists').get();
      expect(ds.exists, isTrue);
      expect(ds2.exists, isFalse);
    });

    test('data returns correct result', () async {
      DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
      expect(
        ds.data(),
        equals(<String, dynamic>{
          'foo': 'bar',
        }),
      );

      DocumentSnapshot ds2 = await firestore!.doc('doc/not-exists').get();
      expect(ds2.data(), isNull);
    });

    group('.get()', () {
      test('throws if field is invalid', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        expect(() => ds.get(123), throwsAssertionError);
        expect(() => ds.get({}), throwsAssertionError);
      });

      test('gets a top-level field by [String]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        expect(ds.get('foo'), equals('bar'));
      });

      test('gets a top-level field by [FieldPath]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        expect(ds.get(FieldPath(const ['foo'])), equals('bar'));
      });

      test('throws a [StateError] if document does not exist', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/not-exists').get();
        try {
          ds.get('foo');
        } on StateError {
          return;
        }
        fail('Did not throw a StateError');
      });

      test('throws a [StateError] if a top-level field was not found',
          () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        try {
          ds.get('bar');
        } on StateError {
          return;
        }
        fail('Did not throw a StateError');
      });

      test('gets a nested Map field by [String]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds.get('foo.bar'), equals('baz'));
      });

      test('gets a nested Map field by [FieldPath]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds.get(FieldPath(const ['foo', 'bar'])), equals('baz'));
      });

      test('gets a Map field', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds.get('foo'), equals({'bar': 'baz'}));
      });

      test('gets a List field', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds.get('baz'), equals([123, '456']));
      });

      test('gets a deep Map field', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds.get('ben.foo.bar'), equals('baz'));
      });

      test('gets a field containing a "." using [FieldPath]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();

        expect(ds.get(FieldPath(const ['dot.field'])), isTrue);
      });

      test('throws when getting a field containing a "." using [String]',
          () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        try {
          ds.get('dot.field');
        } on StateError {
          return;
        }
        fail('Did not throw a StateError');
      });
    });

    group('[]', () {
      test('throws if field is invalid', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        expect(() => ds[123], throwsAssertionError);
        expect(() => ds[{}], throwsAssertionError);
      });

      test('gets a top-level field by [String]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        expect(ds['foo'], equals('bar'));
      });

      test('gets a top-level field by [FieldPath]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        expect(ds[FieldPath(const ['foo'])], equals('bar'));
      });

      test('throws a [StateError] if document does not exist', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/not-exists').get();
        try {
          // ignore: unnecessary_statements
          ds['foo'];
        } on StateError {
          return;
        }
        fail('Did not throw a StateError');
      });

      test('throws a [StateError] if a top-level field was not found',
          () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        try {
          // ignore: unnecessary_statements
          ds['bar'];
        } on StateError {
          return;
        }
        fail('Did not throw a StateError');
      });

      test('gets a nested Map field by [String]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds['foo.bar'], equals('baz'));
      });

      test('gets a nested Map field by [FieldPath]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds[FieldPath(const ['foo', 'bar'])], equals('baz'));
      });

      test('gets a Map field', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds['foo'], equals({'bar': 'baz'}));
      });

      test('gets a List field', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds['baz'], equals([123, '456']));
      });

      test('gets a deep Map field', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        expect(ds['ben.foo.bar'], equals('baz'));
      });

      test('gets a field containing a "." using [FieldPath]', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();

        expect(ds[FieldPath(const ['dot.field'])], isTrue);
      });

      test('throws when getting a field containing a "." using [String]',
          () async {
        DocumentSnapshot ds = await firestore!.doc('doc/get-test').get();
        try {
          // ignore: unnecessary_statements
          ds['dot.field'];
        } on StateError {
          return;
        }
        fail('Did not throw a StateError');
      });
    });

    group('$SnapshotMetadata', () {
      test('a non-existing document returns `false` metadata fields', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/not-exists').get();
        expect(ds.metadata, isA<SnapshotMetadata>());
        expect(ds.metadata.isFromCache, isFalse);
        expect(ds.metadata.hasPendingWrites, isFalse);
      });

      test('a document returns correct metadata fields', () async {
        DocumentSnapshot ds = await firestore!.doc('doc/exists').get();
        expect(ds.metadata, isA<SnapshotMetadata>());
        expect(ds.metadata.isFromCache, isTrue);
        expect(ds.metadata.hasPendingWrites, isTrue);
      });
    });
  });
}
