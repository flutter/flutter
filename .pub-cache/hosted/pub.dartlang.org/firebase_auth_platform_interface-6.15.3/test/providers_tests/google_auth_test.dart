// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

void main() {
  late TestGoogleAuthProvider googleAuthProvider;
  const String kMockProviderId = 'google.com';
  setUpAll(() {
    googleAuthProvider = TestGoogleAuthProvider();
  });

  group('$GoogleAuthProvider', () {
    test('Constructor', () {
      expect(googleAuthProvider, isA<GoogleAuthProvider>());
      expect(googleAuthProvider, isA<AuthProvider>());
    });

    test('GoogleAuthProvider.GOOGLE_SIGN_IN_METHOD', () {
      expect(GoogleAuthProvider.GOOGLE_SIGN_IN_METHOD, isA<String>());
      expect(GoogleAuthProvider.GOOGLE_SIGN_IN_METHOD, equals(kMockProviderId));
    });

    test('GithubAuthProvider.PROVIDER_ID', () {
      expect(GoogleAuthProvider.PROVIDER_ID, isA<String>());
      expect(GoogleAuthProvider.PROVIDER_ID, equals(kMockProviderId));
    });

    test('scopes', () {
      expect(googleAuthProvider.scopes, isA<List<String>>());
      expect(googleAuthProvider.scopes.length, 0);
    });

    test('parameters', () {
      expect(googleAuthProvider.parameters, isA<Object>());
    });

    group('addScope()', () {
      test('adds a new scope', () {
        String kMockScope = 'repo';
        final result = googleAuthProvider.addScope(kMockScope);

        expect(result, isA<GoogleAuthProvider>());
        expect(result.scopes, isA<List<String>>());
        expect(result.scopes.length, 1);
        expect(result.scopes[0], equals(kMockScope));
      });
    });

    group('setCustomParameters()', () {
      test('sets custom parameters', () {
        final Map<dynamic, dynamic> kCustomOAuthParameters = <dynamic, dynamic>{
          'login_hint': 'user@example.com'
        };
        final result =
            googleAuthProvider.setCustomParameters(kCustomOAuthParameters);
        expect(result, isA<GoogleAuthProvider>());
        expect(result.parameters['login_hint'], isA<String>());
        expect(result.parameters['login_hint'], equals('user@example.com'));
      });
    });

    group('GoogleAuthProvider.credential()', () {
      const String kMockAccessToken = 'test-access-token';
      const String kMockIdToken = 'test-id-token';
      test('creates a new [GoogleAuthCredential]', () {
        final result =
            GoogleAuthProvider.credential(accessToken: kMockAccessToken);
        expect(result, isA<OAuthCredential>());
        expect(result.token, isNull);
        expect(result.idToken, isNull);
        expect(result.accessToken, kMockAccessToken);
        expect(result.providerId, equals(kMockProviderId));
        expect(result.signInMethod, equals(kMockProviderId));
      });

      test('allows accessToken to be null', () {
        expect(
            GoogleAuthProvider.credential(
              idToken: kMockIdToken,
            ),
            isA<OAuthCredential>());
      });

      test('allows idToken to be null', () {
        expect(
            GoogleAuthProvider.credential(
              accessToken: kMockAccessToken,
            ),
            isA<OAuthCredential>());
      });

      test('throws [AssertionError] when accessToken and idTokenResult is null',
          () {
        expect(GoogleAuthProvider.credential, throwsAssertionError);
      });
    });
  });
}

class TestGoogleAuthProvider extends GoogleAuthProvider {
  TestGoogleAuthProvider() : super();
}
