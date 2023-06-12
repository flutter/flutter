// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:test/test.dart';

void main() {
  test('AccessToken & AccessCredentials', () {
    final credentials = AccessCredentials(
      AccessToken('type', 'data', DateTime.now().toUtc()),
      'refreshToken',
      ['scope1'],
      idToken: 'idToken',
    );

    final encoded = jsonEncode(credentials);

    final decoded = AccessCredentials.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );

    expect(decoded.refreshToken, 'refreshToken');
    expect(decoded.idToken, 'idToken');
    expect(decoded.scopes, ['scope1']);
    expect(decoded.accessToken.expiry, credentials.accessToken.expiry);
    expect(decoded.accessToken.data, credentials.accessToken.data);
    expect(decoded.accessToken.type, credentials.accessToken.type);

    expect(jsonEncode(decoded), encoded);
  });

  test('ClientId', () {
    final clientId = ClientId('identifier', 'secret');

    final encoded = jsonEncode(clientId);

    final decoded = ClientId.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );

    expect(decoded.identifier, clientId.identifier);
    expect(decoded.secret, clientId.secret);

    expect(jsonEncode(decoded), encoded);
  });
}
