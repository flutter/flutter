// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'package:googleapis_auth/auth_browser.dart' as auth;
import 'package:googleapis_auth/src/oauth2_flows/implicit.dart' as impl;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  impl.gapiUrl = resource('gapi_auth_immediate.js');

  test('gapi-auth-force', () async {
    final clientId = auth.ClientId('foo_client', 'foo_secret');
    final scopes = ['scope1', 'scope2'];

    final flow = await auth.createImplicitBrowserFlow(clientId, scopes);
    final credentials =
        await flow.obtainAccessCredentialsViaUserConsent(immediate: true);
    final date = DateTime.now().toUtc().add(const Duration(seconds: 3210));
    final difference = credentials.accessToken.expiry.difference(date);
    final seconds = difference.inSeconds;

    expect(seconds, inInclusiveRange(-3, 3));
    expect(credentials.accessToken.data, 'foo_token');
    expect(credentials.refreshToken, isNull);
    expect(credentials.scopes, hasLength(2));
    expect(credentials.scopes[0], 'scope1');
    expect(credentials.scopes[1], 'scope2');
  });
}
