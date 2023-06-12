// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async' show Future;
import 'dart:convert' show utf8;

import 'package:gcloud/storage.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

// Note: The README.md contains more details on how to use this package.

Future<void> main() async {
  // When running on Google Computer Engine, AppEngine or GKE credentials can
  // be obtained from a meta-data server as follows.
  final client = await auth.clientViaMetadataServer();
  try {
    final storage = Storage(client, 'my_gcp_project');
    final b = storage.bucket('test-bucket');
    await b.writeBytes('my-file.txt', utf8.encode('hello world'));
    print('Wrote "hello world" to "my-file.txt" in "test-bucket"');
  } finally {
    client.close();
  }
}
