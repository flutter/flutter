// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_credential.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String kMockProviderId = 'id-1';
  const String kMockSignInMethod = 'password';
  const int kMockToken = 123;
  group('$AuthCredential', () {
    late AuthCredential authCredential;

    setUpAll(() {
      authCredential = const AuthCredential(
          providerId: kMockProviderId,
          signInMethod: kMockSignInMethod,
          token: kMockToken);
    });

    group('Constructor', () {
      test('creates instance of [AuthCredential] and sets required values', () {
        const result = AuthCredential(
          providerId: kMockProviderId,
          signInMethod: kMockSignInMethod,
        );

        expect(result, isA<AuthCredential>());
        expect(result.providerId, kMockProviderId);
        expect(result.signInMethod, kMockSignInMethod);
      });

      test('sets token with given value', () {
        expect(authCredential.providerId, equals(kMockProviderId));
        expect(authCredential.signInMethod, equals(kMockSignInMethod));
        expect(authCredential.token, equals(kMockToken));
      });
    });

    test('asMap()', () {
      final result = authCredential.asMap();

      expect(result, isA<Map<String, dynamic>>());
      expect(result['providerId'], equals(kMockProviderId));
      expect(result['signInMethod'], equals(kMockSignInMethod));
      expect(result['token'], equals(kMockToken));
    });

    test('toString()', () {
      final result = authCredential.toString();

      expect(
        result,
        'AuthCredential(providerId: $kMockProviderId, signInMethod: $kMockSignInMethod, token: $kMockToken, accessToken: null)',
      );
    });
  });
}
