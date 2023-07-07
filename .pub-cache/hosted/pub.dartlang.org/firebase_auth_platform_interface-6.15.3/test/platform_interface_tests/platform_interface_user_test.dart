// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mock.dart';
import 'platform_interface_user_credential_test.dart';

void main() {
  setupFirebaseAuthMocks();

  late TestUserPlatform userPlatform;
  late FirebaseAuthPlatform auth;
  const String kMockProviderId = 'firebase';
  const String kMockUid = '12345';
  const String kMockDisplayName = 'Flutter Test User';
  const String kMockPhotoURL = 'http://www.example.com/';
  const String kMockEmail = 'test@example.com';
  const String kMockPhoneNumber = TEST_PHONE_NUMBER;
  const String kMockRefreshToken = 'test';
  const String kMockTenantId = 'test-tenant-id';
  final int kMockCreationTimestamp =
      DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch;
  final int kMockLastSignInTimestamp =
      DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
  final List kMockInitialProviderData = [
    <String, String>{
      'providerId': kMockProviderId,
      'uid': kMockUid,
      'displayName': kMockDisplayName,
      'photoURL': kMockPhotoURL,
      'email': kMockEmail,
      'phoneNumber': kMockPhoneNumber,
    },
  ];
  group('$UserPlatform()', () {
    Map<String, dynamic> kMockUser;
    setUpAll(() async {
      await Firebase.initializeApp();
      auth = FirebaseAuthPlatform.instance;

      kMockUser = <String, dynamic>{
        'uid': kMockUid,
        'isAnonymous': true,
        'email': kMockEmail,
        'displayName': kMockDisplayName,
        'emailVerified': false,
        'phoneNumber': kMockPhoneNumber,
        'metadata': <String, int>{
          'creationTime': kMockCreationTimestamp,
          'lastSignInTime': kMockLastSignInTimestamp,
        },
        'photoURL': kMockPhotoURL,
        'providerData': kMockInitialProviderData,
        'refreshToken': kMockRefreshToken,
        'tenantId': kMockTenantId,
      };
      userPlatform =
          TestUserPlatform(auth, TestMultiFactorPlatform(auth), kMockUser);
    });

    group('Constructor', () {
      test('creates a new instance of [UserPlatform]', () {
        expect(userPlatform, isA<UserPlatform>());
      });
    });

    group('verify()', () {
      test('calls successfully', () {
        try {
          UserPlatform.verify(userPlatform);
          return;
        } catch (_) {
          fail('thrown an unexpected exception');
        }
      });
    });

    test('UserPlatform.auth', () {
      expect(userPlatform.auth, isA<FirebaseAuthPlatform>());
      expect(userPlatform.auth, equals(auth));
    });

    test('UserPlatform.displayName', () {
      expect(userPlatform.displayName, kMockDisplayName);
    });

    test('UserPlatform.email', () {
      expect(userPlatform.email, kMockEmail);
    });
    test('UserPlatform.emailVerified', () {
      expect(userPlatform.emailVerified, false);
    });
    test('UserPlatform.isAnonymous', () {
      expect(userPlatform.isAnonymous, true);
    });

    test('UserPlatform.metadata', () {
      expect(userPlatform.metadata, isA<UserMetadata>());
      expect(userPlatform.metadata.creationTime!.millisecondsSinceEpoch,
          equals(kMockCreationTimestamp));
      expect(userPlatform.metadata.lastSignInTime!.millisecondsSinceEpoch,
          equals(kMockLastSignInTimestamp));
    });
    test('UserPlatform.phoneNumber', () {
      expect(userPlatform.phoneNumber, equals(kMockPhoneNumber));
    });

    test('UserPlatform.photoURL', () {
      expect(userPlatform.photoURL, equals(kMockPhotoURL));
    });

    test('UserPlatform.providerData', () {
      expect(userPlatform.providerData, isA<List<UserInfo>>());
      final UserInfo userInfo = userPlatform.providerData[0];
      expect(userInfo.displayName, equals(kMockDisplayName));
      expect(userInfo.email, equals(kMockEmail));
      expect(userInfo.photoURL, equals(kMockPhotoURL));
      expect(userInfo.phoneNumber, equals(kMockPhoneNumber));
      expect(userInfo.uid, equals(kMockUid));
      expect(userInfo.providerId, equals(kMockProviderId));
    });

    test('UserPlatform.refreshToken', () {
      expect(userPlatform.refreshToken, equals(kMockRefreshToken));
    });

    test('UserPlatform.tenantId', () {
      expect(userPlatform.tenantId, equals(kMockTenantId));
    });

    test('UserPlatform.uid', () {
      expect(userPlatform.uid, equals(kMockUid));
    });

    test('throws if .delete', () async {
      try {
        await userPlatform.delete();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('delete() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .getIdToken', () async {
      try {
        await userPlatform.getIdToken(true);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('getIdToken() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .getIdTokenResult', () async {
      try {
        await userPlatform.getIdTokenResult(true);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('getIdTokenResult() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .linkWithCredential', () async {
      AuthCredential credential = EmailAuthProvider.credential(
          email: 'test@email.com', password: 'testPassword');
      try {
        await userPlatform.linkWithCredential(credential);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('linkWithCredential() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .reauthenticateWithCredential', () async {
      AuthCredential credential = EmailAuthProvider.credential(
          email: 'test@email.com', password: 'testPassword');
      try {
        await userPlatform.reauthenticateWithCredential(credential);
      } on UnimplementedError catch (e) {
        expect(e.message,
            equals('reauthenticateWithCredential() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .reload', () async {
      try {
        await userPlatform.reload();
      } on UnimplementedError catch (e) {
        expect(e.message, equals('reload() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .sendEmailVerification', () async {
      ActionCodeSettings actionCodeSettings =
          ActionCodeSettings(url: 'www.test.com');
      try {
        await userPlatform.sendEmailVerification(actionCodeSettings);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('sendEmailVerification() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .unlink', () async {
      try {
        await userPlatform.unlink('providerId');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('unlink() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .updateEmail', () async {
      try {
        await userPlatform.updateEmail('test@email.com');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('updateEmail() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .updatePassword', () async {
      try {
        await userPlatform.updatePassword('updatePassword');
      } on UnimplementedError catch (e) {
        expect(e.message, equals('updatePassword() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .updatePhoneNumber', () async {
      PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: 'verificationId',
        smsCode: '12345',
      );
      try {
        await userPlatform.updatePhoneNumber(phoneCredential);
      } on UnimplementedError catch (e) {
        expect(e.message, equals('updatePhoneNumber() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .updateProfile', () async {
      try {
        await userPlatform.updateProfile(<String, String>{});
      } on UnimplementedError catch (e) {
        expect(e.message, equals('updateProfile() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if .verifyBeforeUpdateEmail', () async {
      ActionCodeSettings actionCodeSettings =
          ActionCodeSettings(url: 'www.test.com');
      try {
        await userPlatform.verifyBeforeUpdateEmail(
            'test@email.com', actionCodeSettings);
      } on UnimplementedError catch (e) {
        expect(
            e.message, equals('verifyBeforeUpdateEmail() is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });
  });
}

class TestUserPlatform extends UserPlatform {
  TestUserPlatform(FirebaseAuthPlatform auth, MultiFactorPlatform multiFactor,
      Map<String, dynamic> data)
      : super(auth, multiFactor, data);
}
