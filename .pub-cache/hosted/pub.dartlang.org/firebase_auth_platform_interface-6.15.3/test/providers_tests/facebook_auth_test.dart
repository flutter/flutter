// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

void main() {
  late TestFacebookAuthProvider facebookAuthProvider;
  const String kMockProviderId = 'facebook.com';
  setUpAll(() {
    facebookAuthProvider = TestFacebookAuthProvider();
  });

  group('$FacebookAuthProvider', () {
    test('Constructor', () {
      expect(facebookAuthProvider, isA<FacebookAuthProvider>());
    });

    test('FacebookAuthProvider.FACEBOOK_SIGN_IN_METHOD', () {
      expect(FacebookAuthProvider.FACEBOOK_SIGN_IN_METHOD, isA<String>());
      expect(FacebookAuthProvider.FACEBOOK_SIGN_IN_METHOD,
          equals(kMockProviderId));
    });

    test('FacebookAuthProvider.PROVIDER_ID', () {
      expect(FacebookAuthProvider.PROVIDER_ID, isA<String>());
      expect(FacebookAuthProvider.PROVIDER_ID, equals(kMockProviderId));
    });

    test('scopes', () {
      expect(facebookAuthProvider.scopes, isA<List<String>>());
      expect(facebookAuthProvider.scopes.length, 0);
    });

    test('parameters', () {
      expect(facebookAuthProvider.parameters, isA<Object>());
    });

    group('addScope()', () {
      test('adds a new scope', () {
        String kMockScope = 'user_birthday';
        final result = facebookAuthProvider.addScope(kMockScope);

        expect(result, isA<FacebookAuthProvider>());
        expect(result.scopes, isA<List<String>>());
        expect(result.scopes.length, 1);
        expect(result.scopes[0], equals(kMockScope));
      });
    });

    group('setCustomParameters()', () {
      test('sets custom parameters', () {
        final Map<dynamic, dynamic> kCustomOAuthParameters = <dynamic, dynamic>{
          'display': 'popup',
        };
        final result =
            facebookAuthProvider.setCustomParameters(kCustomOAuthParameters);
        expect(result, isA<FacebookAuthProvider>());
        expect(result.parameters['display'], isA<String>());
        expect(result.parameters['display'], equals('popup'));
      });
    });

    group('FacebookAuthProvider.credential()', () {
      const String kMockAccessToken = 'test-token';
      test('creates a new [FacebookAuthCredential]', () {
        final result = FacebookAuthProvider.credential(kMockAccessToken);
        expect(result, isA<OAuthCredential>());
        expect(result.token, isNull);
        expect(result.idToken, isNull);
        expect(result.accessToken, kMockAccessToken);
        expect(result.providerId, equals(kMockProviderId));
        expect(result.signInMethod, equals(kMockProviderId));
      });
    });
  });
}

class TestFacebookAuthProvider extends FacebookAuthProvider {
  TestFacebookAuthProvider() : super();
}
