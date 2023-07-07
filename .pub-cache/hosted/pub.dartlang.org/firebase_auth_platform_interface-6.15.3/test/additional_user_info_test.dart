// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bool kMockIsNewUser = true;
  const String kMockDisplayName = 'test-name';
  final Map<String, dynamic> kMockProfile = <String, dynamic>{
    'displayName': kMockDisplayName
  };
  const String kMockProviderId = 'password';
  const String kMockUsername = 'username';

  group('$AdditionalUserInfo', () {
    AdditionalUserInfo additionalUserInfo = AdditionalUserInfo(
        isNewUser: kMockIsNewUser,
        profile: kMockProfile,
        providerId: kMockProviderId,
        username: kMockUsername);
    group('Constructor', () {
      test('returns an instance of [AdditionalUserInfo]', () {
        expect(additionalUserInfo, isA<AdditionalUserInfo>());

        expect(additionalUserInfo.providerId, equals(kMockProviderId));
        expect(additionalUserInfo.isNewUser, equals(kMockIsNewUser));
        expect(additionalUserInfo.username, equals(kMockUsername));
        expect(additionalUserInfo.profile, equals(kMockProfile));
      });
    });

    group('toString', () {
      test('returns expected string', () {
        final result = additionalUserInfo.toString();
        expect(result, isA<String>());
        expect(
            result,
            equals(
                '$AdditionalUserInfo(isNewUser: $kMockIsNewUser, profile: $kMockProfile, providerId: $kMockProviderId, username: $kMockUsername)'));
      });
    });
  });
}
