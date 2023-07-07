// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_identity_services_web/oauth2.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;

/// Basic scopes for self-id
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/userinfo.profile',
  'https://www.googleapis.com/auth/userinfo.email',
];

/// People API to return my profile info...
const String MY_PROFILE = 'https://content-people.googleapis.com/v1/people/me'
    '?sources=READ_SOURCE_TYPE_PROFILE'
    '&personFields=photos%2Cnames%2CemailAddresses';

/// Requests user data from the People API using the given [tokenResponse].
Future<GoogleSignInUserData?> requestUserData(
  TokenResponse tokenResponse, {
  @visibleForTesting http.Client? overrideClient,
}) async {
  // Request my profile from the People API.
  final Map<String, Object?> person = await _doRequest(
    MY_PROFILE,
    tokenResponse,
    overrideClient: overrideClient,
  );

  // Now transform the Person response into a GoogleSignInUserData.
  return extractUserData(person);
}

/// Extracts user data from a Person resource.
///
/// See: https://developers.google.com/people/api/rest/v1/people#Person
GoogleSignInUserData? extractUserData(Map<String, Object?> json) {
  final String? userId = _extractUserId(json);
  final String? email = _extractPrimaryField(
    json['emailAddresses'] as List<Object?>?,
    'value',
  );

  assert(userId != null);
  assert(email != null);

  return GoogleSignInUserData(
    id: userId!,
    email: email!,
    displayName: _extractPrimaryField(
      json['names'] as List<Object?>?,
      'displayName',
    ),
    photoUrl: _extractPrimaryField(
      json['photos'] as List<Object?>?,
      'url',
    ),
    // Synthetic user data doesn't contain an idToken!
  );
}

/// Extracts the ID from a Person resource.
///
/// The User ID looks like this:
/// {
///   'resourceName': 'people/PERSON_ID',
///   ...
/// }
String? _extractUserId(Map<String, Object?> profile) {
  final String? resourceName = profile['resourceName'] as String?;
  return resourceName?.split('/').last;
}

/// Extracts the [fieldName] marked as 'primary' from a list of [values].
///
/// Values can be one of:
/// * `emailAddresses`
/// * `names`
/// * `photos`
///
/// From a Person object.
T? _extractPrimaryField<T>(List<Object?>? values, String fieldName) {
  if (values != null) {
    for (final Object? value in values) {
      if (value != null && value is Map<String, Object?>) {
        final bool isPrimary = _extractPath(
          value,
          path: <String>['metadata', 'primary'],
          defaultValue: false,
        );
        if (isPrimary) {
          return value[fieldName] as T?;
        }
      }
    }
  }

  return null;
}

/// Attempts to get the property in [path] of type `T` from a deeply nested [source].
///
/// Returns [default] if the property is not found.
T _extractPath<T>(
  Map<String, Object?> source, {
  required List<String> path,
  required T defaultValue,
}) {
  final String valueKey = path.removeLast();
  Object? data = source;
  for (final String key in path) {
    if (data != null && data is Map) {
      data = data[key];
    } else {
      break;
    }
  }
  if (data != null && data is Map) {
    return (data[valueKey] ?? defaultValue) as T;
  } else {
    return defaultValue;
  }
}

/// Gets from [url] with an authorization header defined by [token].
///
/// Attempts to [jsonDecode] the result.
Future<Map<String, Object?>> _doRequest(
  String url,
  TokenResponse token, {
  http.Client? overrideClient,
}) async {
  final Uri uri = Uri.parse(url);
  final http.Client client = overrideClient ?? http.Client();
  try {
    final http.Response response =
        await client.get(uri, headers: <String, String>{
      'Authorization': '${token.token_type} ${token.access_token}',
    });
    if (response.statusCode != 200) {
      throw http.ClientException(response.body, uri);
    }
    return jsonDecode(response.body) as Map<String, Object?>;
  } finally {
    client.close();
  }
}
