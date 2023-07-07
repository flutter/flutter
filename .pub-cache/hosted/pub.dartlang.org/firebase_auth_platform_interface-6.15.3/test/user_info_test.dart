// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/user_info.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  const String kMockProviderId = 'firebase';
  const String kMockUid = '12345';
  const String kMockDisplayName = 'Flutter Test User';
  const String kMockPhotoURL = 'http://www.example.com/';
  const String kMockEmail = 'test@example.com';

  const String kMockPhoneNumber = TEST_PHONE_NUMBER;
  const Map<String, String?> kMockData = <String, String?>{
    'providerId': kMockProviderId,
    'uid': kMockUid,
    'displayName': kMockDisplayName,
    'photoURL': kMockPhotoURL,
    'email': kMockEmail,
    'phoneNumber': kMockPhoneNumber
  };

  group('$UserInfo', () {
    final userInfo = UserInfo(kMockData);
    group('Constructor', () {
      test('returns an instance of [UserInfo]', () {
        expect(userInfo, isA<UserInfo>());

        expect(userInfo.displayName, equals(kMockDisplayName));
        expect(userInfo.email, equals(kMockEmail));
        expect(userInfo.phoneNumber, equals(kMockPhoneNumber));
        expect(userInfo.photoURL, equals(kMockPhotoURL));
        expect(userInfo.providerId, equals(kMockProviderId));
        expect(userInfo.uid, equals(kMockUid));
      });
    });

    test('toString()', () {
      expect(
        userInfo.toString(),
        '$UserInfo('
        'displayName: $kMockDisplayName, '
        'email: $kMockEmail, '
        'phoneNumber: $kMockPhoneNumber, '
        'photoURL: $kMockPhotoURL, '
        'providerId: $kMockProviderId, '
        'uid: $kMockUid)',
      );
    });
  });
}
