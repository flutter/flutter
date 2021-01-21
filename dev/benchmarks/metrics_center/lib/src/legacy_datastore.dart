// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(liyuqian): Remove this file once the migration is fully done and we no
// longer need to fall back to the datastore.

import 'package:gcloud/db.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';

// The official pub.dev/packages/gcloud documentation uses datastore_impl
// so we have to ignore implementation_imports here.
// ignore: implementation_imports
import 'package:gcloud/src/datastore_impl.dart';

import 'common.dart';

Future<DatastoreDB> datastoreFromCredentialsJson(
    Map<String, dynamic> json) async {
  final AutoRefreshingAuthClient client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(json), DatastoreImpl.SCOPES);
  return DatastoreDB(DatastoreImpl(client, json[kProjectId] as String));
}

DatastoreDB datastoreFromAccessToken(String token, String projectId) {
  final AuthClient client =
      authClientFromAccessToken(token, DatastoreImpl.SCOPES);
  return DatastoreDB(DatastoreImpl(client, projectId));
}
