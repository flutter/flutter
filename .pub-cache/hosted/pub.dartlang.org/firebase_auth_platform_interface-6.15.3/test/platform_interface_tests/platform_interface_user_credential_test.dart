// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../mock.dart';

void main() {
  setupFirebaseAuthMocks();

  late FirebaseAuthPlatform auth;
  const String kMockUid = '12345';
  const String kMockUsername = 'fluttertestuser';
  const String kMockEmail = 'test@example.com';
  const String kMockPassword = 'test-password';

  final kMockUserData = <String, dynamic>{
    'uid': kMockUid,
    'email': kMockEmail,
  };
  group('$UserCredentialPlatform()', () {
    late AdditionalUserInfo kMockAdditionalUserInfo;
    late AuthCredential kMockCredential;
    late UserPlatform kMockUser;
    late TestUserCredentialPlatform userCredentialPlatform;

    setUpAll(() async {
      await Firebase.initializeApp();
      auth = FirebaseAuthPlatform.instance;

      kMockAdditionalUserInfo = AdditionalUserInfo(
        username: kMockUsername,
        profile: {},
        isNewUser: false,
      );
      kMockUser =
          TestUserPlatform(auth, TestMultiFactorPlatform(auth), kMockUserData);
      kMockCredential = EmailAuthProvider.credential(
          email: kMockEmail, password: kMockPassword);

      userCredentialPlatform = TestUserCredentialPlatform(
          auth, kMockAdditionalUserInfo, kMockCredential, kMockUser);
    });

    group('Constructor', () {
      test('creates an instance of [UserCredentialPlatform]', () {
        expect(userCredentialPlatform, isA<UserCredentialPlatform>());
        expect(userCredentialPlatform, isA<PlatformInterface>());
      });

      test('sets correct values', () {
        expect(
          userCredentialPlatform.additionalUserInfo.toString(),
          equals(kMockAdditionalUserInfo.toString()),
        );

        expect(userCredentialPlatform.auth, isA<FirebaseAuthPlatform>());
        expect(userCredentialPlatform.auth.app, isA<FirebaseApp>());

        expect(
          userCredentialPlatform.additionalUserInfo,
          isA<AdditionalUserInfo>(),
        );
        expect(
          userCredentialPlatform.additionalUserInfo.toString(),
          equals(kMockAdditionalUserInfo.toString()),
        );

        expect(userCredentialPlatform.credential, isA<AuthCredential>());
        expect(
          userCredentialPlatform.credential.toString(),
          equals(kMockCredential.toString()),
        );

        expect(userCredentialPlatform.user, isA<UserPlatform>());
        expect(userCredentialPlatform.user!.email, equals(kMockEmail));
      });
    });

    group('verify()', () {
      test('calls successfully', () {
        try {
          UserCredentialPlatform.verify(userCredentialPlatform);
          return;
        } catch (_) {
          fail('thrown an unexpected exception');
        }
      });
    });
  });
}

class TestUserPlatform extends UserPlatform {
  TestUserPlatform(FirebaseAuthPlatform auth,
      MultiFactorPlatform multiFactorPlatform, Map<String, dynamic> data)
      : super(auth, multiFactorPlatform, data);
}

class TestMultiFactorPlatform extends MultiFactorPlatform {
  TestMultiFactorPlatform(FirebaseAuthPlatform auth)
      : super(
          auth,
        );
}

class TestUserCredentialPlatform extends UserCredentialPlatform {
  TestUserCredentialPlatform(
      FirebaseAuthPlatform auth,
      AdditionalUserInfo additionalUserInfo,
      AuthCredential credential,
      UserPlatform user)
      : super(
            auth: auth,
            additionalUserInfo: additionalUserInfo,
            credential: credential,
            user: user);
}
