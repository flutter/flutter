// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: comment_references

/// Contains common libraries used across the package.
///
/// In most cases, you'll want to import either
/// [auth_io] or [auth_browser] depending on your platform.
/// {@canonicalFor access_credentials.AccessCredentials}
/// {@canonicalFor access_token.AccessToken}
/// {@canonicalFor auth_client.AuthClient}
/// {@canonicalFor auth_client.AutoRefreshingAuthClient}
/// {@canonicalFor auth_functions.authenticatedClient}
/// {@canonicalFor auth_functions.autoRefreshingClient}
/// {@canonicalFor auth_functions.clientViaApiKey}
/// {@canonicalFor auth_functions.refreshCredentials}
/// {@canonicalFor client_id.ClientId}
/// {@canonicalFor exceptions.AccessDeniedException}
/// {@canonicalFor exceptions.ServerRequestFailedException}
/// {@canonicalFor exceptions.RefreshFailedException}
/// {@canonicalFor exceptions.UserConsentException}
/// {@canonicalFor response_type.ResponseType}
/// {@canonicalFor service_account_credentials.ServiceAccountCredentials}
library googleapis_auth;

export 'src/auth_client.dart';
export 'src/auth_functions.dart';
export 'src/client_id.dart';
export 'src/exceptions.dart';
export 'src/response_type.dart';
export 'src/service_account_credentials.dart';
