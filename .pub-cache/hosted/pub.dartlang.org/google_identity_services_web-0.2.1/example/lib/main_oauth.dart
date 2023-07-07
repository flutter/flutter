// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:google_identity_services_web/id.dart';
import 'package:google_identity_services_web/loader.dart' as gis;
import 'package:google_identity_services_web/oauth2.dart';
import 'package:http/http.dart' as http;
import 'package:js/js.dart' show allowInterop;
import 'package:js/js_util.dart' show getProperty;

/// People API to return my profile info...
const String MY_PROFILE =
    'https://content-people.googleapis.com/v1/people/me?personFields=photos%2Cnames%2CemailAddresses';

/// People API to return all my connections.
const String MY_CONNECTIONS =
    'https://people.googleapis.com/v1/people/me/connections?requestMask.includeField=person.names';

/// Basic scopes for self-id
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/userinfo.profile',
  'https://www.googleapis.com/auth/userinfo.email',
];

/// Scopes for the people API (read contacts)
const List<String> myConnectionsScopes = <String>[
  'https://www.googleapis.com/auth/contacts.readonly',
];

void main() async {
  await gis.loadWebSdk(); // Load the GIS SDK

  id.setLogLevel('debug');

  final TokenClientConfig config = TokenClientConfig(
    client_id: 'your-client_id.apps.googleusercontent.com',
    scope: scopes.join(' '),
    callback: allowInterop(onTokenResponse),
    error_callback: allowInterop(onError),
  );

  final OverridableTokenClientConfig overridableCfg =
      OverridableTokenClientConfig(
    scope: (scopes + myConnectionsScopes).join(' '),
  );

  final TokenClient client = oauth2.initTokenClient(config);

  // Disable the Popup Blocker for this to work, or move this to a Button press.
  client.requestAccessToken(overridableCfg);
}

/// Triggers when there's an error with the OAuth2 popup.
///
/// We cannot use the proper type for `error` here yet, because of:
/// https://github.com/dart-lang/sdk/issues/50899
Future<void> onError(Object? error) async {
  print('Error! ${getProperty(error!, "type")}');
}

/// Handles the returned (auth) token response.
/// See: https://developers.google.com/identity/oauth2/web/reference/js-reference#TokenResponse
Future<void> onTokenResponse(TokenResponse token) async {
  if (token.error != null) {
    print('Authorization error!');
    print(token.error);
    print(token.error_description);
    print(token.error_uri);
    return;
  }

  // Attempt to do a request to the `people` API
  final Object? profile = await get(token, MY_PROFILE);
  print(profile);

  // Has granted all the scopes?
  if (!oauth2.hasGrantedAllScopes(token, myConnectionsScopes)) {
    print('The user has NOT granted all the required scopes!');
    print('The next get will probably throw an exception!');
  }

  final Object? contacts = await get(token, MY_CONNECTIONS);
  print(contacts);

  print('Revoking token...');
  oauth2.revoke(token.access_token,
      allowInterop((TokenRevocationResponse response) {
    print(response.successful);
    print(response.error);
    print(response.error_description);
  }));
}

/// Gets from [url] with an authorization header defined by [token].
///
/// Attempts to [jsonDecode] the result.
Future<Object?> get(TokenResponse token, String url) async {
  final Uri uri = Uri.parse(url);
  final http.Response response = await http.get(uri, headers: <String, String>{
    'Authorization': '${token.token_type} ${token.access_token}',
  });

  if (response.statusCode != 200) {
    throw http.ClientException(response.body, uri);
  }

  return jsonDecode(response.body) as Object?;
}
