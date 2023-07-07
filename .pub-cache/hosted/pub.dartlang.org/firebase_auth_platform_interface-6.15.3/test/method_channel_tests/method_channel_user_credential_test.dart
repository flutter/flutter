// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user_credential.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mock.dart';

void main() {
  setupFirebaseAuthMocks();

  late FirebaseAuthPlatform auth;
  const String kMockUid = '12345';
  const String kMockUsername = 'fluttertestuser';
  const String kMockEmail = 'test@example.com';
  const String kMockProviderId = 'provider-id';
  const String kMockSignInMethod = 'password';

  final Map<String, dynamic> kMockInitialUserData = <String, dynamic>{
    'user': <String, dynamic>{
      'uid': kMockUid,
      'email': kMockEmail,
    },
    'additionalUserInfo': <String, dynamic>{
      'profile': <String, dynamic>{'foo': 'bar'},
      'isNewUser': true,
      'providerId': 'info$kMockProviderId',
      'username': 'info$kMockUsername',
    },
    'authCredential': <String, dynamic>{
      'providerId': 'auth$kMockProviderId',
      'signInMethod': kMockSignInMethod,
    },
  };

  group('$MethodChannelUserCredential()', () {
    late MethodChannelUserCredential userCredential;
    late Map<String, dynamic> userData = kMockInitialUserData;

    setUpAll(() async {
      await Firebase.initializeApp();
      auth = FirebaseAuthPlatform.instance;

      userCredential = MethodChannelUserCredential(auth, userData);
    });

    setUp(() {
      userData = Map<String, dynamic>.from(kMockInitialUserData);
    });

    group('Constructor', () {
      test('creates an instance of [MethodChannelUserCredential]', () {
        expect(userCredential, isA<MethodChannelUserCredential>());
        expect(userCredential, isA<UserCredentialPlatform>());
      });

      test('sets values correctly', () {
        expect(userCredential.auth, isA<FirebaseAuthPlatform>());

        final additionalUserInfo = userCredential.additionalUserInfo!;
        final credential = userCredential.credential!;
        final user = userCredential.user!;

        expect(additionalUserInfo, isA<AdditionalUserInfo>());

        expect(additionalUserInfo.isNewUser, isTrue);
        expect(additionalUserInfo.profile, isA<Map<String, dynamic>>());
        expect(additionalUserInfo.profile!['foo'], equals('bar'));
        expect(additionalUserInfo.username, equals('info$kMockUsername'));
        expect(additionalUserInfo.providerId, equals('info$kMockProviderId'));

        expect(credential, isA<AuthCredential>());
        expect(credential.providerId, equals('auth$kMockProviderId'));
        expect(credential.signInMethod, equals(kMockSignInMethod));

        expect(user, isA<MethodChannelUser>());
        expect(user.uid, equals(kMockUid));
        expect(user.email, equals(kMockEmail));
      });

      test('set additionalUserInfo to null', () {
        userData['additionalUserInfo'] = null;
        MethodChannelUserCredential testUser =
            MethodChannelUserCredential(auth, userData);

        expect(testUser.additionalUserInfo, isNull);
      });

      test('set additionalUserInfo.profile to empty map', () {
        userData['additionalUserInfo']['profile'] = null;
        MethodChannelUserCredential testUser =
            MethodChannelUserCredential(auth, userData);

        expect(testUser.additionalUserInfo, isA<AdditionalUserInfo>());
        expect(
            testUser.additionalUserInfo!.profile, isA<Map<String, dynamic>>());
        expect(testUser.additionalUserInfo!.profile, isEmpty);
      });

      test('set authCredential to null', () {
        userData['authCredential'] = null;
        MethodChannelUserCredential testUser =
            MethodChannelUserCredential(auth, userData);

        expect(testUser.credential, isNull);
      });

      test('set user to null', () {
        userData['user'] = null;
        MethodChannelUserCredential testUser =
            MethodChannelUserCredential(auth, userData);

        expect(testUser.user, isNull);
      });
    });
  });
}
