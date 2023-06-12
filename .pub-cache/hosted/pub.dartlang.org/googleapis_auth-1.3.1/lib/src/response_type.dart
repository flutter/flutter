// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Available response types that can be requested when using the implicit
/// browser login flow.
///
/// More information about these values can be found here:
/// https://developers.google.com/identity/protocols/oauth2/openid-connect#response-type
enum ResponseType {
  /// Requests an access code.  This triggers the basic rather than the implicit
  /// flow.
  code,

  /// Requests the user's identity token when running the implicit flow.
  idToken,

  /// Requests the user's current permissions.
  permission,

  /// Requests the user's access token when running the implicit flow.
  token,
}
