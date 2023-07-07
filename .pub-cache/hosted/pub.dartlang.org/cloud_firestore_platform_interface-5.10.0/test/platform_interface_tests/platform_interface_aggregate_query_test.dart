// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_common.dart';

class AggregateQuery extends AggregateQueryPlatform {
  AggregateQuery(QueryPlatform query) : super(query);
}

class TestQuery extends QueryPlatform {
  TestQuery._() : super(FirebaseFirestorePlatform.instance, null);
}

late QueryPlatform query;
late AggregateQueryPlatform aggregateQuery;

void main() {
  initializeMethodChannel();
  group('$AggregateQueryPlatform()', () {
    setUpAll(() async {
      await Firebase.initializeApp();
      query = TestQuery._();
      aggregateQuery = AggregateQuery(query);
    });

    test('constructor', () {
      expect(aggregateQuery, isInstanceOf<AggregateQueryPlatform>());
      expect(aggregateQuery.query, isInstanceOf<TestQuery>());
    });

    test('throws if .get() is unimplemented ', () {
      expect(
        () => aggregateQuery.get(source: AggregateSource.server),
        throwsA(
          isA<UnimplementedError>().having(
            (e) => e.message,
            'message',
            'get() is not implemented',
          ),
        ),
      );
    });
  });
}
