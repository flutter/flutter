// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides access to an authenticated HTTP client which can be used to access
/// Google APIs.
library gcloud.http;

import 'package:http/http.dart' as http;

import 'service_scope.dart' as ss;

const Symbol _authenticatedClientKey = #gcloud.http;

/// Access the [http.Client] object available in the current service scope.
///
/// The returned object will be the one which was previously registered with
/// [registerAuthClientService] within the current (or a parent) service
/// scope.
///
/// Accessing this getter outside of a service scope will result in an error.
/// See the `package:gcloud/service_scope.dart` library for more information.
http.Client get authClientService =>
    ss.lookup(_authenticatedClientKey) as http.Client;

/// Registers the [http.Client] object within the current service scope.
///
/// The provided `client` object will be available via the top-level
/// `authenticatedHttp` getter.
///
/// Calling this function outside of a service scope will result in an error.
/// Calling this function more than once inside the same service scope is not
/// allowed.
void registerAuthClientService(http.Client client, {bool close = true}) {
  ss.register(_authenticatedClientKey, client);
  if (close) {
    ss.registerScopeExitCallback(() {
      client.close();
      return null;
    });
  }
}
