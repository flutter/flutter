// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_firebase_auth.dart';
import '../mock.dart';
import 'package:flutter/services.dart';

void main() {
  setupFirebaseAuthMocks();

  final List<MethodCall> log = <MethodCall>[];
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;
  late FirebaseAuthPlatform auth;
  const String kMockProviderId = 'firebase';
  const String kMockUid = '12345';
  const String kMockDisplayName = 'Flutter Test User';
  const String kMockPhotoURL = 'http://www.example.com/';
  const String kMockEmail = 'test@example.com';
  const String kMockIdToken = '12345';
  const String kMockNewPhoneNumber = '5555555556';
  const String kMockIdTokenResultSignInProvider = 'password';
  const String kMockIdTokenResultSignInFactor = 'test';
  const Map<dynamic, dynamic> kMockIdTokenResultClaims = <dynamic, dynamic>{
    'claim1': 'value1',
  };
  const String kMockPhoneNumber = TEST_PHONE_NUMBER;
  final int kMockIdTokenResultExpirationTimestamp =
      DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
  final int kMockIdTokenResultAuthTimestamp =
      DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
  final int kMockIdTokenResultIssuedAtTimestamp =
      DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
  final Map<String, dynamic> kMockIdTokenResult = <String, dynamic>{
    'token': kMockIdToken,
    'expirationTimestamp': kMockIdTokenResultExpirationTimestamp,
    'authTimestamp': kMockIdTokenResultAuthTimestamp,
    'issuedAtTimestamp': kMockIdTokenResultIssuedAtTimestamp,
    'signInProvider': kMockIdTokenResultSignInProvider,
    'claims': kMockIdTokenResultClaims,
    'signInSecondFactor': kMockIdTokenResultSignInFactor
  };

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

  Map<String, dynamic> kMockUser = <String, dynamic>{
    'uid': kMockUid,
    'isAnonymous': true,
    'emailVerified': false,
    'metadata': <String, int>{
      'creationTime': kMockCreationTimestamp,
      'lastSignInTime': kMockLastSignInTimestamp,
    },
    'photoURL': kMockPhotoURL,
    'providerData': kMockInitialProviderData,
  };

  Future<void> mockSignIn() async {
    await auth.signInAnonymously();
  }

  group('$MethodChannelUser', () {
    late Map<String, dynamic> user;
    late List kMockProviderData;

    setUpAll(() async {
      FirebaseApp app = await Firebase.initializeApp();

      handleMethodCall((call) async {
        log.add(call);

        if (mockExceptionThrown) {
          throw Exception();
        } else if (mockPlatformExceptionThrown) {
          throw PlatformException(code: 'UNKNOWN');
        }

        switch (call.method) {
          case 'Auth#registerIdTokenListener':
            const String name = 'idTokenChannel';
            handleEventChannel(name, log);
            return name;
          case 'Auth#registerAuthStateListener':
            const String name = 'authStateChannel';
            handleEventChannel(name, log);
            return name;
          case 'Auth#signInAnonymously':
            return <String, dynamic>{'user': user};
          case 'Auth#signInWithEmailAndPassword':
            user = generateUser(
                user, <String, dynamic>{'email': call.arguments['email']});
            return <String, dynamic>{'user': user};
          case 'User#updateProfile':
            Map<String, dynamic> previousUser = user;
            user = generateUser(
                user, Map<String, dynamic>.from(call.arguments['profile']));
            return previousUser;
          case 'User#updatePhoneNumber':
            Map<String, dynamic> previousUser = user;
            user = generateUser(
                user, <String, dynamic>{'phoneNumber': kMockNewPhoneNumber});
            return previousUser;
          case 'User#updatePassword':
          case 'User#updateEmail':
          case 'User#sendLinkToEmail':
          case 'User#sendPasswordResetEmail':
            Map<String, dynamic> previousUser = user;
            user = generateUser(
                user, <String, dynamic>{'email': call.arguments['newEmail']});
            return previousUser;
          case 'User#getIdToken':
            if (call.arguments['tokenOnly'] == false) {
              return kMockIdTokenResult;
            }
            return <String, dynamic>{'token': kMockIdToken};
          case 'User#reload':
            return user;
          case 'User#reauthenticateUserWithCredential':
          case 'User#linkWithCredential':
            user = generateUser(
                user, <String, dynamic>{'providerData': kMockProviderData});
            return <String, dynamic>{'user': user};
          case 'User#unlink':
            user = generateUser(user, <String, dynamic>{'providerData': []});
            return <String, dynamic>{'user': user};
          default:
            return <String, dynamic>{'user': user};
        }
      });

      auth = MethodChannelFirebaseAuth(app: app);
      user = kMockUser;
    });

    setUp(() async {
      user = kMockUser;

      mockPlatformExceptionThrown = false;
      mockExceptionThrown = false;
      kMockProviderData = List.from(kMockInitialProviderData);
      await mockSignIn();

      log.clear();
    });
    group('User.displayName', () {
      test('should return null', () async {
        expect(auth.currentUser!.displayName, isNull);
      });
      test('should return correct value', () async {
        // Setup
        user =
            generateUser(user, <String, dynamic>{'displayName': 'updatedName'});
        await auth.currentUser!.reload();

        expect(auth.currentUser!.displayName, equals('updatedName'));
      });
    });

    group('User.email', () {
      test('should return null', () async {
        expect(auth.currentUser!.email, isNull);
      });
      test('should return correct value', () async {
        const updatedEmail = 'updated@email.com';
        user = generateUser(user, <String, dynamic>{'email': updatedEmail});
        await auth.currentUser!.reload();

        expect(auth.currentUser!.email, equals(updatedEmail));
      });
    });

    group('User.emailVerified', () {
      test('should return false', () async {
        expect(auth.currentUser!.emailVerified, isFalse);
      });
      test('should return true', () async {
        user = generateUser(user, <String, dynamic>{'emailVerified': true});
        await auth.currentUser!.reload();

        expect(auth.currentUser!.emailVerified, isTrue);
      });
    });

    group('User.isAnonymous', () {
      test('should return true', () async {
        expect(auth.currentUser!.isAnonymous, isTrue);
      });
      test('should return false', () async {
        user = generateUser(user, <String, dynamic>{'isAnonymous': false});
        await auth.currentUser!.reload();

        expect(auth.currentUser!.isAnonymous, isFalse);
      });
    });

    test('User.metadata', () async {
      final metadata = auth.currentUser!.metadata;

      expect(metadata, isA<UserMetadata>());
      expect(metadata.creationTime!.millisecondsSinceEpoch,
          kMockCreationTimestamp);
      expect(metadata.lastSignInTime!.millisecondsSinceEpoch,
          kMockLastSignInTimestamp);
    });

    test('User.photoURL', () async {
      expect(auth.currentUser!.photoURL, equals(kMockPhotoURL));
    });

    test('User.providerData', () async {
      final providerData = auth.currentUser!.providerData;
      expect(providerData, isA<List<UserInfo>>());

      expect(providerData[0].displayName, equals(kMockDisplayName));
      expect(providerData[0].email, equals(kMockEmail));
      expect(providerData[0].photoURL, equals(kMockPhotoURL));
      expect(providerData[0].phoneNumber, equals(kMockPhoneNumber));
      expect(providerData[0].uid, equals(kMockUid));
      expect(providerData[0].providerId, equals(kMockProviderId));
    });

    test('User.refreshToken', () async {
      expect(auth.currentUser!.refreshToken, isNull);
    });

    test('User.tenantId', () async {
      expect(auth.currentUser!.tenantId, isNull);
    });

    test('User.uid', () async {
      expect(auth.currentUser!.uid, equals(kMockUid));
    });

    group('delete()', () {
      test('should run successfully', () async {
        await auth.currentUser!.delete();

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#delete',
              arguments: <String, String?>{
                'appName': '[DEFAULT]',
                'tenantId': null
              },
            ),
          ],
        );
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.delete();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('getIdToken()', () {
      test('should run successfully', () async {
        final token = await auth.currentUser!.getIdToken(true);

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#getIdToken',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'forceRefresh': true,
                'tokenOnly': true
              },
            ),
          ],
        );
        expect(token, isA<String>());
        expect(token, equals(kMockIdToken));
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.getIdToken(true);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });
    group('getIdTokenResult()', () {
      test('should run successfully', () async {
        final idTokenResult = await auth.currentUser!.getIdTokenResult(true);

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#getIdToken',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'forceRefresh': true,
                'tokenOnly': false
              },
            ),
          ],
        );
        expect(idTokenResult, isA<IdTokenResult>());
        expect(idTokenResult.authTime!.millisecondsSinceEpoch,
            equals(kMockIdTokenResultAuthTimestamp));
        expect(idTokenResult.claims, equals(kMockIdTokenResultClaims));
        expect(idTokenResult.expirationTime!.millisecondsSinceEpoch,
            equals(kMockIdTokenResultExpirationTimestamp));
        expect(idTokenResult.issuedAtTime!.millisecondsSinceEpoch,
            equals(kMockIdTokenResultIssuedAtTimestamp));
        expect(idTokenResult.token, equals(kMockIdToken));
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.getIdTokenResult(true);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('linkWithCredential()', () {
      String newEmail = 'new@email.com';
      EmailAuthCredential credential =
          EmailAuthProvider.credential(email: newEmail, password: 'test')
              as EmailAuthCredential;

      test('should run successfully', () async {
        kMockProviderData.add(<String, String>{
          'email': newEmail,
          'providerId': 'email',
          'uid': kMockUid,
          'displayName': kMockDisplayName,
          'photoURL': kMockPhotoURL,
        });
        final result = await auth.currentUser!.linkWithCredential(credential);

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#linkWithCredential',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'credential': credential.asMap()
              },
            ),
          ],
        );
        expect(result, isA<UserCredentialPlatform>());
        expect(result.user!.providerData.length, equals(2));

        // check currentUser updated
        expect(auth.currentUser!.providerData.length, equals(2));
        expect(auth.currentUser!.providerData[1].email, equals(newEmail));
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.linkWithCredential(credential);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('reauthenticateWithCredential()', () {
      String newEmail = 'new@email.com';
      EmailAuthCredential credential =
          EmailAuthProvider.credential(email: newEmail, password: 'test')
              as EmailAuthCredential;

      test('should run successfully', () async {
        kMockProviderData.add(<String, String>{
          'email': newEmail,
          'providerId': 'email',
          'uid': kMockUid,
          'displayName': kMockDisplayName,
          'photoURL': kMockPhotoURL,
        });
        final result =
            await auth.currentUser!.reauthenticateWithCredential(credential);

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#reauthenticateUserWithCredential',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'credential': credential.asMap()
              },
            ),
          ],
        );
        expect(result, isA<UserCredentialPlatform>());
        expect(result.user!.providerData.length, equals(2));

        // check currentUser updated
        expect(auth.currentUser!.providerData.length, equals(2));
        expect(auth.currentUser!.providerData[1].email, equals(newEmail));
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() =>
            auth.currentUser!.reauthenticateWithCredential(credential);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('reload()', () {
      test('should run successfully', () async {
        // Setup
        expect(auth.currentUser!.displayName, isNull);
        user = generateUser(
            user, <String, dynamic>{'displayName': 'test'}); // change mock user

        // Test
        await auth.currentUser!.reload();

        // Assumptions
        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#reload',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
              },
            )
          ],
        );
        expect(auth.currentUser!.displayName, 'test');
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.reload();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });
    group('sendEmailVerification()', () {
      ActionCodeSettings actionCodeSettings = ActionCodeSettings(url: 'test');

      test('should run successfully', () async {
        // Test
        await auth.currentUser!.sendEmailVerification(actionCodeSettings);

        // Assumptions
        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#sendEmailVerification',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'actionCodeSettings': actionCodeSettings.asMap()
              },
            )
          ],
        );
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() =>
            auth.currentUser!.sendEmailVerification(actionCodeSettings);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('unlink()', () {
      test('should run successfully', () async {
        expect(auth.currentUser!.providerData.length, equals(1));
        final unlinkedUser = await auth.currentUser!.unlink(kMockProviderId);

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#unlink',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'providerId': kMockProviderId
              },
            )
          ],
        );

        expect(unlinkedUser, isA<UserPlatform>());
        expect(unlinkedUser.providerData.length, equals(0));

        // check currentUser updated
        expect(auth.currentUser!.providerData.length, equals(0));
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.unlink(kMockProviderId);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('updateEmail()', () {
      const newEmail = 'new@email.com';

      test('should run successfully', () async {
        await auth.currentUser!.updateEmail(newEmail);

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#updateEmail',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'newEmail': newEmail
              },
            )
          ],
        );

        await auth.currentUser!.reload();
        expect(auth.currentUser!.email, equals(newEmail));
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.updateEmail(newEmail);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('updatePassword()', () {
      const newPassword = 'newPassword';

      test('gets result successfully', () async {
        await auth.currentUser!.updatePassword(newPassword);

        expect(
          log[0],
          isMethodCall(
            'User#updatePassword',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'tenantId': null,
              'newPassword': newPassword
            },
          ),
        );
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.updatePassword(newPassword);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('updatePhoneNumber()', () {
      PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
        verificationId: 'test',
        smsCode: 'test',
      );

      test('gets result successfully', () async {
        await auth.currentUser!.updatePhoneNumber(phoneAuthCredential);

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#updatePhoneNumber',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'credential': <String, dynamic>{
                  'providerId': 'phone',
                  'signInMethod': 'phone',
                  'verificationId': 'test',
                  'smsCode': 'test',
                  'token': null
                }
              },
            )
          ],
        );

        await auth.currentUser!.reload();
        expect(auth.currentUser!.phoneNumber, kMockNewPhoneNumber);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() =>
            auth.currentUser!.updatePhoneNumber(phoneAuthCredential);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('updateProfile()', () {
      String newDisplayName = 'newDisplayName';
      String newPhotoURL = 'newPhotoURL';
      Map<String, String> data = <String, String>{
        'displayName': newDisplayName,
        'photoURL': newPhotoURL
      };
      test('updateProfile()', () async {
        await auth.currentUser!.updateProfile(data);

        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#updateProfile',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'profile': <String, dynamic>{
                  'displayName': newDisplayName,
                  'photoURL': newPhotoURL,
                }
              },
            )
          ],
        );

        await auth.currentUser!.reload();
        expect(auth.currentUser!.displayName, equals(newDisplayName));
        expect(auth.currentUser!.photoURL, equals(newPhotoURL));
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!.updateProfile(data);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('verifyBeforeUpdateEmail()', () {
      final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: 'test',
      );
      const newEmail = 'new@email.com';
      test('verifyBeforeUpdateEmail()', () async {
        await auth.currentUser!
            .verifyBeforeUpdateEmail(newEmail, actionCodeSettings);
        expect(
          log,
          <Matcher>[
            isMethodCall(
              'User#verifyBeforeUpdateEmail',
              arguments: <String, dynamic>{
                'appName': '[DEFAULT]',
                'tenantId': null,
                'newEmail': newEmail,
                'actionCodeSettings': actionCodeSettings.asMap(),
              },
            )
          ],
        );
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.currentUser!
            .verifyBeforeUpdateEmail(newEmail, actionCodeSettings);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });
  });
}
