// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'access_token.dart';

/// OAuth2 Credentials.
class AccessCredentials {
  /// An access token.
  final AccessToken accessToken;

  /// A refresh token, which can be used to refresh the access credentials.
  final String? refreshToken;

  /// A JWT used in calls to Google APIs that accept an id_token param.
  final String? idToken;

  /// Scopes these credentials are valid for.
  final List<String> scopes;

  AccessCredentials(
    this.accessToken,
    this.refreshToken,
    this.scopes, {
    this.idToken,
  });

  factory AccessCredentials.fromJson(Map<String, dynamic> json) =>
      AccessCredentials(
        AccessToken.fromJson(json['accessToken'] as Map<String, dynamic>),
        json['refreshToken'] as String?,
        (json['scopes'] as List<dynamic>).map((e) => e as String).toList(),
        idToken: json['idToken'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'accessToken': accessToken,
        if (refreshToken != null) 'refreshToken': refreshToken,
        'idToken': idToken,
        'scopes': scopes,
      };
}
