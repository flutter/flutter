// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.test.common_e2e;

import 'dart:async';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import 'common.dart';

const testProject = 'test-project';

// Environment variables for specifying the cloud project to use and the
// location of the service account key for that project.
const projectEnv = 'GCLOUD_E2E_TEST_PROJECT';

// Used for storage e2e tests:
//
// List operations on buckets are eventually consistent. Bucket deletion is
// also dependent on list operations to ensure the bucket is empty before
// deletion.
//
// So this can make tests flaky. The following delay is introduced as an
// attempt to account for that.
const storageListDelay = Duration(seconds: 5);

Future<T> withAuthClient<T>(
  List<String> scopes,
  Future<T> Function(String project, http.Client client) callback, {
  bool trace = false,
}) async {
  var project = Platform.environment[projectEnv];

  if (project == null) {
    throw StateError('Environment variables $projectEnv ');
  }

  http.Client client = await auth.clientViaApplicationDefaultCredentials(
    scopes: scopes,
  );
  if (trace) {
    client = TraceClient(client);
  }
  return await callback(project, client);
}
