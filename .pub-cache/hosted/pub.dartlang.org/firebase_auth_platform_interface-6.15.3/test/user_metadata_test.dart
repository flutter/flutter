// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/user_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const int kMockCreationTimestamp = 12345677;
  const int kMockLastSignInTimeTimestamp = 12345678;
  group('$UserMetadata', () {
    final userMetadata =
        UserMetadata(kMockCreationTimestamp, kMockLastSignInTimeTimestamp);
    group('Constructor', () {
      test('returns an instance of [UserMetadata]', () {
        expect(userMetadata, isA<UserMetadata>());
        expect(userMetadata.creationTime!.millisecondsSinceEpoch,
            kMockCreationTimestamp);
        expect(userMetadata.lastSignInTime!.millisecondsSinceEpoch,
            kMockLastSignInTimeTimestamp);
      });
    });

    group('creationTime', () {
      test('returns an instance of [DateTime]', () {
        expect(userMetadata.creationTime, isA<DateTime>());
        expect(userMetadata.creationTime!.millisecondsSinceEpoch,
            kMockCreationTimestamp);
      });

      test('returns null', () {
        UserMetadata testUserMetadata =
            UserMetadata(null, kMockLastSignInTimeTimestamp);

        expect(testUserMetadata.creationTime, isNull);
      });
    });

    group('lastSignInTime', () {
      test('returns an instance of [DateTime]', () {
        expect(userMetadata.lastSignInTime, isA<DateTime>());
        expect(userMetadata.lastSignInTime!.millisecondsSinceEpoch,
            kMockLastSignInTimeTimestamp);
      });
      test('returns null', () {
        UserMetadata testUserMetadata =
            UserMetadata(kMockCreationTimestamp, null);

        expect(testUserMetadata.lastSignInTime, isNull);
      });
    });

    test('toString()', () {
      expect(userMetadata.toString(),
          'UserMetadata(creationTime: ${userMetadata.creationTime}, lastSignInTime: ${userMetadata.lastSignInTime})');
    });
  });
}
