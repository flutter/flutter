// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9

@Tags(['e2e'])
@Timeout(Duration(seconds: 120))

library gcloud.test.db_all_test;

import 'dart:async';
import 'dart:io';

import 'package:gcloud/db.dart' as db;
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:http/http.dart';
import 'package:test/test.dart';

import 'common_e2e.dart';
import 'datastore/e2e/datastore_test_impl.dart' as datastore_test;
import 'db/e2e/db_test_impl.dart' as db_test;
import 'db/e2e/metamodel_test_impl.dart' as db_metamodel_test;

Future main() async {
  var scopes = datastore_impl.DatastoreImpl.scopes;
  var now = DateTime.now().millisecondsSinceEpoch;
  var namespace = '${Platform.operatingSystem}$now';

  datastore_impl.DatastoreImpl datastore;
  db.DatastoreDB datastoreDB;
  Client client;

  await withAuthClient(scopes, (String project, httpClient) {
    datastore = datastore_impl.DatastoreImpl(httpClient, project);
    datastoreDB = db.DatastoreDB(datastore);
    client = httpClient;
    return null;
  });

  tearDownAll(() async {
    client.close();
  });

  group('datastore_test', () {
    tearDown(() async {
      await datastore_test.cleanupDB(datastore, namespace);
    });

    datastore_test.runTests(datastore, namespace);
  });

  test('sleep-between-test-suites', () {
    expect(Future.delayed(const Duration(seconds: 10)), completes);
  });

  group('datastore_test', () {
    db_test.runTests(datastoreDB, namespace);
  });

  test('sleep-between-test-suites', () {
    expect(Future.delayed(const Duration(seconds: 10)), completes);
  });

  group('datastore_test', () {
    tearDown(() async {
      await datastore_test.cleanupDB(datastore, namespace);
    });

    db_metamodel_test.runTests(datastore, datastoreDB);
  });
}
