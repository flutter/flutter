// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_identity_services_web/oauth2.dart';
import 'package:integration_test/integration_test.dart';
import 'package:js/js.dart';

import 'utils.dart' as utils;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load web/mock-gis.js in the page
    await utils.installGisMock();
  });

  group('initTokenClient', () {
    testWidgets('returns a tokenClient', (_) async {
      final TokenClient client = oauth2.initTokenClient(TokenClientConfig(
        client_id: 'for-tests',
        callback: null,
        scope: 'some_scope for_tests not_real',
      ));

      expect(client, isNotNull);
    });
  });

  group('requestAccessToken', () {
    testWidgets('passes through configuration', (_) async {
      final StreamController<TokenResponse> controller =
          StreamController<TokenResponse>();

      final List<String> scopes = <String>['some_scope', 'another', 'more'];

      final TokenClient client = oauth2.initTokenClient(TokenClientConfig(
        client_id: 'for-tests',
        callback: allowInterop(controller.add),
        scope: scopes.join(' '),
      ));

      utils.setMockTokenResponse(client, 'some-non-null-auth-token-value');

      client.requestAccessToken();

      final TokenResponse response = await controller.stream.first;

      expect(response, isNotNull);
      expect(response.error, isNull);
      expect(response.scope, scopes.join(' '));
    });

    testWidgets('configuration can be overridden', (_) async {
      final StreamController<TokenResponse> controller =
          StreamController<TokenResponse>();

      final List<String> scopes = <String>['some_scope', 'another', 'more'];

      final TokenClient client = oauth2.initTokenClient(TokenClientConfig(
        client_id: 'for-tests',
        callback: allowInterop(controller.add),
        scope: 'blank',
      ));

      utils.setMockTokenResponse(client, 'some-non-null-auth-token-value');

      client.requestAccessToken(OverridableTokenClientConfig(
        scope: scopes.join(' '),
      ));

      final TokenResponse response = await controller.stream.first;

      expect(response, isNotNull);
      expect(response.error, isNull);
      expect(response.scope, scopes.join(' '));
    });
  });

  group('hasGranted...Scopes', () {
    // mock-gis.js returns false for scopes that start with "not-granted-".
    const String notGranted = 'not-granted-scope';

    testWidgets('all scopes granted', (_) async {
      final List<String> scopes = <String>['some_scope', 'another', 'more'];

      final TokenResponse response = await utils.fakeAuthZWithScopes(scopes);

      final bool all = oauth2.hasGrantedAllScopes(response, scopes);
      final bool any = oauth2.hasGrantedAnyScopes(response, scopes);

      expect(all, isTrue);
      expect(any, isTrue);
    });

    testWidgets('some scopes granted', (_) async {
      final List<String> scopes = <String>['some_scope', notGranted, 'more'];

      final TokenResponse response = await utils.fakeAuthZWithScopes(scopes);

      final bool all = oauth2.hasGrantedAllScopes(response, scopes);
      final bool any = oauth2.hasGrantedAnyScopes(response, scopes);

      expect(all, isFalse, reason: 'Scope: $notGranted should not be granted!');
      expect(any, isTrue);
    });

    testWidgets('no scopes granted', (_) async {
      final List<String> scopes = <String>[notGranted, '$notGranted-2'];

      final TokenResponse response = await utils.fakeAuthZWithScopes(scopes);

      final bool all = oauth2.hasGrantedAllScopes(response, scopes);
      final bool any = oauth2.hasGrantedAnyScopes(response, scopes);

      expect(all, isFalse);
      expect(any, isFalse, reason: 'No scopes were granted.');
    });
  });
}
