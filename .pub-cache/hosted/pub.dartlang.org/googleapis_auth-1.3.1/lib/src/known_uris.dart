// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// token_endpoint
/// via https://accounts.google.com/.well-known/openid-configuration
final googleOauth2TokenEndpoint = Uri.https('oauth2.googleapis.com', 'token');

/// authorization_endpoint
/// via https://accounts.google.com/.well-known/openid-configuration
final googleOauth2AuthorizationEndpoint =
    Uri.https('accounts.google.com', 'o/oauth2/v2/auth');
