// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String kMockBundleId = 'com.test.bundle';
  const String kMockPackageName = 'com.test.package';

  const String kMockDynamicLinkDomain = 'domain.com';
  const bool kMockHandleCodeInApp = true;
  const String kMockUrl = 'https://test.url';
  const String kMockMinimumVersion = '8.0';
  const bool kMockInstallApp = true;

  group('$ActionCodeSettings', () {
    ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        androidPackageName: kMockPackageName,
        androidMinimumVersion: kMockMinimumVersion,
        androidInstallApp: kMockInstallApp,
        dynamicLinkDomain: kMockDynamicLinkDomain,
        handleCodeInApp: kMockHandleCodeInApp,
        iOSBundleId: kMockBundleId,
        url: kMockUrl);

    group('Constructor', () {
      test('returns an instance of [ActionCodeInfo]', () {
        expect(actionCodeSettings, isA<ActionCodeSettings>());
        expect(actionCodeSettings.url, equals(kMockUrl));
        expect(actionCodeSettings.dynamicLinkDomain,
            equals(kMockDynamicLinkDomain));
        expect(
            actionCodeSettings.handleCodeInApp, equals(kMockHandleCodeInApp));
        expect(actionCodeSettings.androidPackageName, equals(kMockPackageName));
        expect(actionCodeSettings.androidMinimumVersion,
            equals(kMockMinimumVersion));
        expect(actionCodeSettings.androidInstallApp, equals(kMockInstallApp));
        expect(actionCodeSettings.iOSBundleId, equals(kMockBundleId));
      });

      group('asMap', () {
        test('returns the current instance as a [Map]', () {
          final result = actionCodeSettings.asMap();

          expect(result, isA<Map<String, dynamic>>());

          expect(result['url'], equals(kMockUrl));
          expect(result['dynamicLinkDomain'], equals(kMockDynamicLinkDomain));
          expect(result['handleCodeInApp'], equals(kMockHandleCodeInApp));
          expect(result['android']['packageName'], equals(kMockPackageName));
          expect(result['android']['installApp'], equals(kMockInstallApp));
          expect(
              result['android']['minimumVersion'], equals(kMockMinimumVersion));
          expect(result['iOS']['bundleId'], equals(kMockBundleId));
        });
      });

      test('toString', () {
        expect(actionCodeSettings.toString(),
            equals('$ActionCodeSettings(${actionCodeSettings.asMap})'));
      });
    });
  });
}
