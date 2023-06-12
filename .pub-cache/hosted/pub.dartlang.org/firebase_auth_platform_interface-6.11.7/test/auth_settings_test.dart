// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/src/auth_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$AuthSettings', () {
    test('creates instance of [AuthSettings] ', () {
      const authSettings = AuthSettings();

      expect(authSettings, isA<AuthSettings>());
      expect(authSettings.appVerificationDisabledForTesting, isNull);
    });

    test('sets appVerificationDisabledForTesting with given value', () {
      // set appVerificationDisabledForTesting to true
      AuthSettings authSettings =
          const AuthSettings(appVerificationDisabledForTesting: true);
      expect(authSettings.appVerificationDisabledForTesting, isTrue);

      // set appVerificationDisabledForTesting to false
      authSettings =
          const AuthSettings(appVerificationDisabledForTesting: false);
      expect(authSettings.appVerificationDisabledForTesting, isFalse);
    });
  });
}
