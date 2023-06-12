// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart';

import 'access_credentials.dart';

/// A authenticated HTTP client.
abstract class AuthClient implements Client {
  /// The credentials currently used for making HTTP requests.
  AccessCredentials get credentials;
}

/// A auto-refreshing, authenticated HTTP client.
abstract class AutoRefreshingAuthClient implements AuthClient {
  /// A broadcast stream of [AccessCredentials].
  ///
  /// A listener will get notified when new [AccessCredentials] were obtained.
  Stream<AccessCredentials> get credentialUpdates;
}
