// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

Map<String, dynamic> kMockParameters = {
  'orderBy': ['foo'],
  'limit': 1
};

class TestQuery extends QueryPlatform {
  TestQuery._() : super(FirebaseFirestorePlatform.instance, null);
}

class TestQueryWithParameters extends QueryPlatform {
  TestQueryWithParameters._(Map<String, dynamic> parameters)
      : super(FirebaseFirestorePlatform.instance, parameters);
}

void main() {
  initializeMethodChannel();

  group('$QueryPlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp(
        name: 'testApp',
        options: const FirebaseOptions(
          appId: '1:123:ios:123',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '123',
        ),
      );
    });

    test('constructor', () {
      final query = TestQuery._();
      expect(query, isInstanceOf<QueryPlatform>());
    });

    test('verify()', () {
      final query = TestQuery._();
      QueryPlatform.verify(query);
      expect(query, isInstanceOf<QueryPlatform>());
    });

    test('should have default parameters', () {
      _hasDefaultParameters(TestQuery._().parameters);
    });

    test('should set parameters', () {
      final query = TestQueryWithParameters._(kMockParameters);
      expect(query.parameters, equals(kMockParameters));
    });

    test('throws if .isCollectionGroupQuery', () {
      final query = TestQuery._();
      try {
        query.isCollectionGroupQuery;
      } on UnimplementedError catch (e) {
        expect(e.message, equals('isCollectionGroupQuery is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .endAtDocument', () {
      final query = TestQuery._();
      try {
        query.endAtDocument([], []);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('endAtDocument() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .endAt', () {
      final query = TestQuery._();
      try {
        query.endAt([]);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('endAt() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .endBeforeDocument', () {
      final query = TestQuery._();
      try {
        query.endBeforeDocument([], []);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('endBeforeDocument() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .endBefore', () {
      final query = TestQuery._();
      try {
        query.endBefore([]);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('endBefore() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .get', () async {
      final query = TestQuery._();
      try {
        await query.get();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('get() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .limit', () {
      final query = TestQuery._();
      try {
        query.limit(1);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('limit() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .limitToLast', () {
      final query = TestQuery._();
      try {
        query.limitToLast(1);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('limitToLast() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .snapshots', () {
      final query = TestQuery._();
      try {
        query.snapshots();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('snapshots() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .orderBy', () {
      final query = TestQuery._();
      try {
        query.orderBy([]);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('orderBy() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .startAfterDocument', () {
      final query = TestQuery._();
      try {
        query.startAfterDocument([], []);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('startAfterDocument() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .startAfter', () {
      final query = TestQuery._();
      try {
        query.startAfter([]);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('startAfter() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .startAtDocument', () {
      final query = TestQuery._();
      try {
        query.startAtDocument([], []);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('startAtDocument() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .startAt', () {
      final query = TestQuery._();
      try {
        query.startAt([]);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('startAt() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .where', () {
      final query = TestQuery._();
      try {
        query.where([]);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('where() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}

void _hasDefaultParameters(Map<String, dynamic> input) {
  expect(input['where'], equals([]));
  expect(input['orderBy'], equals([]));
}
