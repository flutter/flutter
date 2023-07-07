// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  // Store the initial instance before any tests change it.
  final GoogleSignInPlatform initialInstance = GoogleSignInPlatform.instance;

  group('$GoogleSignInPlatform', () {
    test('$MethodChannelGoogleSignIn is the default instance', () {
      expect(initialInstance, isA<MethodChannelGoogleSignIn>());
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        GoogleSignInPlatform.instance = ImplementsGoogleSignInPlatform();
        // In versions of `package:plugin_platform_interface` prior to fixing
        // https://github.com/flutter/flutter/issues/109339, an attempt to
        // implement a platform interface using `implements` would sometimes
        // throw a `NoSuchMethodError` and other times throw an
        // `AssertionError`.  After the issue is fixed, an `AssertionError` will
        // always be thrown.  For the purpose of this test, we don't really care
        // what exception is thrown, so just allow any exception.
      }, throwsA(anything));
    });

    test('Can be extended', () {
      GoogleSignInPlatform.instance = ExtendsGoogleSignInPlatform();
    });

    test('Can be mocked with `implements`', () {
      GoogleSignInPlatform.instance = ModernMockImplementation();
    });

    test('still supports legacy isMock', () {
      GoogleSignInPlatform.instance = LegacyIsMockImplementation();
    });
  });

  group('GoogleSignInTokenData', () {
    test('can be compared by == operator', () {
      final GoogleSignInTokenData firstInstance = GoogleSignInTokenData(
        accessToken: 'accessToken',
        idToken: 'idToken',
        serverAuthCode: 'serverAuthCode',
      );
      final GoogleSignInTokenData secondInstance = GoogleSignInTokenData(
        accessToken: 'accessToken',
        idToken: 'idToken',
        serverAuthCode: 'serverAuthCode',
      );
      expect(firstInstance == secondInstance, isTrue);
    });
  });

  group('GoogleSignInUserData', () {
    test('can be compared by == operator', () {
      final GoogleSignInUserData firstInstance = GoogleSignInUserData(
        email: 'email',
        id: 'id',
        displayName: 'displayName',
        photoUrl: 'photoUrl',
        idToken: 'idToken',
        serverAuthCode: 'serverAuthCode',
      );
      final GoogleSignInUserData secondInstance = GoogleSignInUserData(
        email: 'email',
        id: 'id',
        displayName: 'displayName',
        photoUrl: 'photoUrl',
        idToken: 'idToken',
        serverAuthCode: 'serverAuthCode',
      );
      expect(firstInstance == secondInstance, isTrue);
    });
  });
}

class LegacyIsMockImplementation extends Mock implements GoogleSignInPlatform {
  @override
  bool get isMock => true;
}

class ModernMockImplementation extends Mock
    with MockPlatformInterfaceMixin
    implements GoogleSignInPlatform {
  @override
  bool get isMock => false;
}

class ImplementsGoogleSignInPlatform extends Mock
    implements GoogleSignInPlatform {}

class ExtendsGoogleSignInPlatform extends GoogleSignInPlatform {}
