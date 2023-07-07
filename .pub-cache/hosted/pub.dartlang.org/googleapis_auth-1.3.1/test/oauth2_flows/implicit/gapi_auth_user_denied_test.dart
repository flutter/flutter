// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'package:googleapis_auth/auth_browser.dart' as auth;
import 'package:googleapis_auth/src/oauth2_flows/implicit.dart' as impl;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  impl.gapiUrl = resource('gapi_auth_user_denied.js');

  test('gapi-auth-user-denied', () async {
    final clientId = auth.ClientId('foo_client', 'foo_secret');
    final scopes = ['scope1', 'scope2'];

    final flow = await auth.createImplicitBrowserFlow(clientId, scopes);
    try {
      await flow.obtainAccessCredentialsViaUserConsent();
      fail('expected error');
    } catch (error) {
      expect(error is auth.UserConsentException, isTrue);
    }
  });
}
