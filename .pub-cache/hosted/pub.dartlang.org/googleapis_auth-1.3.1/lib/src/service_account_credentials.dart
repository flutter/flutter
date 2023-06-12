// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'client_id.dart';
import 'crypto/pem.dart';
import 'crypto/rsa.dart';

export 'access_credentials.dart' show AccessCredentials;
export 'access_token.dart' show AccessToken;
export 'auth_client.dart';
export 'client_id.dart';
export 'exceptions.dart';
export 'response_type.dart';

/// Represents credentials for a service account.
class ServiceAccountCredentials {
  /// The email address of this service account.
  final String email;

  /// The clientId.
  final ClientId clientId;

  /// Private key.
  final String privateKey;

  /// Impersonated user, if any. If not impersonating any user this is `null`.
  final String? impersonatedUser;

  /// Private key as an [RSAPrivateKey].
  final RSAPrivateKey privateRSAKey;

  /// Creates a new [ServiceAccountCredentials] from JSON.
  ///
  /// [json] can be either a [Map] or a JSON map encoded as a [String].
  ///
  /// The optional named argument [impersonatedUser] is used to set the user
  /// to impersonate if impersonating a user.
  factory ServiceAccountCredentials.fromJson(json, {String? impersonatedUser}) {
    if (json is String) {
      json = jsonDecode(json);
    }
    if (json is! Map) {
      throw ArgumentError('json must be a Map or a String encoding a Map.');
    }
    final identifier = json['client_id'] as String?;
    final privateKey = json['private_key'] as String?;
    final email = json['client_email'] as String?;
    final type = json['type'];

    if (type != 'service_account') {
      throw ArgumentError(
        'The given credentials are not of type '
        'service_account (was: $type).',
      );
    }

    if (identifier == null || privateKey == null || email == null) {
      throw ArgumentError(
        'The given credentials do not contain all the '
        'fields: client_id, private_key and client_email.',
      );
    }

    final clientId = ClientId(identifier);
    return ServiceAccountCredentials(
      email,
      clientId,
      privateKey,
      impersonatedUser: impersonatedUser,
    );
  }

  /// Creates a new [ServiceAccountCredentials].
  ///
  /// [email] is the e-mail address of the service account.
  ///
  /// [clientId] is the client ID for the service account.
  ///
  /// [privateKey] is the base 64 encoded, unencrypted private key, including
  /// the '-----BEGIN PRIVATE KEY-----' and '-----END PRIVATE KEY-----'
  /// boundaries.
  ///
  /// The optional named argument [impersonatedUser] is used to set the user
  /// to impersonate if impersonating a user is needed.
  ServiceAccountCredentials(
    this.email,
    this.clientId,
    this.privateKey, {
    this.impersonatedUser,
  }) : privateRSAKey = keyFromString(privateKey);
}
