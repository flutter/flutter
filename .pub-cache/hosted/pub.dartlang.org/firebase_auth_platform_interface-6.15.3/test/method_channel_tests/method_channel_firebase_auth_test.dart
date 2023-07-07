// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_firebase_auth.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_multi_factor.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mock.dart';

void main() {
  setupFirebaseAuthMocks();

  late MultiFactorPlatform multiFactor;

  late FirebaseAuthPlatform auth;
  final List<MethodCall> log = <MethodCall>[];
  const String regularTestEmail = 'test@email.com';
  const String testPassword = 'testPassword';

  // mock props
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;
  const String kMockUid = '12345';
  const String kMockProviderId = 'firebase';
  const String kMockDisplayName = 'Flutter Test User';
  const String kMockEmail = 'test@example.com';
  const String kMockPhotoURL = 'http://www.example.com/';
  final int kMockCreationTimestamp =
      DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch;
  final int kMockLastSignInTimestamp =
      DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
  Map<String, dynamic> kMockUser = <String, dynamic>{
    'uid': kMockUid,
    'isAnonymous': false,
    'emailVerified': false,
    'metadata': <String, int>{
      'creationTime': kMockCreationTimestamp,
      'lastSignInTime': kMockLastSignInTimestamp,
    },
    'photoURL': kMockPhotoURL,
    'providerData': <Map<String, String>>[
      <String, String>{
        'providerId': kMockProviderId,
        'uid': kMockUid,
        'displayName': kMockDisplayName,
        'photoURL': kMockPhotoURL,
        'email': kMockEmail,
      },
    ],
  };

  final Map<String, dynamic> kMockInitialProviders = <String, dynamic>{
    'providers': ['facebook']
  };

  const Map<String, dynamic> kMockActionCodeInfoData = <String, dynamic>{
    'email': regularTestEmail,
    'previousEmail': 'previous@email.com'
  };

  final ActionCodeInfo kMockActionCodeInfo = ActionCodeInfo(
    operation: 1,
    data: kMockActionCodeInfoData,
  );

  const Map<String, dynamic> kMockAdditionalUserInfo = <String, dynamic>{
    'isNewUser': false,
    'username': 'flutterUser',
    'providerId': 'testProvider',
    'profile': <String, dynamic>{'foo': 'bar'},
  };

  Future<void> mockSignIn() async {
    await auth.signInAnonymously();
  }

  void verifyUser(UserPlatform user) {
    expect(user, isA<Object>());
    expect(user.uid, isA<String>());
    expect(user.email, equals(regularTestEmail));
    expect(user.isAnonymous, isFalse);
    expect(user.uid, equals(auth.currentUser!.uid));
  }

  void verifyUserCredential(UserCredentialPlatform result) {
    verifyUser(result.user!);
    var additionalUserInfo = result.additionalUserInfo!;
    expect(additionalUserInfo, isA<Object>());
    expect(additionalUserInfo.isNewUser, isFalse);
  }

  group('$MethodChannelFirebaseAuth', () {
    late Map<String, dynamic> user;

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
            user = generateUser(user, <String, dynamic>{
              'isAnonymous': true,
            });
            return <String, dynamic>{'user': user};
          case 'Auth#signInWithEmailLink':
          case 'Auth#signInWithEmailAndPassword':
            user = generateUser(
                user, <String, dynamic>{'email': call.arguments['email']});
            return <String, dynamic>{
              'user': user,
              'additionalUserInfo': kMockAdditionalUserInfo
            };
          case 'Auth#signInWithCustomToken':
            user = generateUser(user, <String, dynamic>{
              'email': regularTestEmail,
            });
            return <String, dynamic>{
              'user': user,
              'additionalUserInfo': kMockAdditionalUserInfo
            };
          case 'Auth#signInWithCredential':
            user = generateUser(user, <String, dynamic>{
              'email': call.arguments['credential']['email'],
            });
            return <String, dynamic>{
              'user': user,
              'additionalUserInfo': kMockAdditionalUserInfo
            };
          case 'Auth#verifyPasswordResetCode':
            return <String, dynamic>{'email': call.arguments['code']};
          case 'Auth#verifyPhoneNumber':
            const String name = 'phoneNumberVerifier';
            handleEventChannel(name, log);
            return name;
          case 'Auth#checkActionCode':
            return <String, dynamic>{
              'operation': 2,
              'data': kMockActionCodeInfoData,
            };
          case 'Auth#setLanguageCode':
            return <String, dynamic>{
              'languageCode': call.arguments['languageCode']
            };
          case 'Auth#setSettings':
            return null;
          case 'Auth#fetchSignInMethodsForEmail':
            return kMockInitialProviders;

          default:
            return <String, dynamic>{'user': kMockUser};
        }
      });

      auth = MethodChannelFirebaseAuth.instance.delegateFor(app: app);
      // TODO(Lyokone): mock properly
      multiFactor = MethodChannelMultiFactor(auth);

      user = kMockUser;
    });

    setUp(() async {
      user = kMockUser;
      log.clear();
    });

    tearDown(() async {
      mockPlatformExceptionThrown = false;
      mockExceptionThrown = false;
      await auth.signOut();
    });

    test('currentUser', () async {
      await mockSignIn();
      expect(auth.currentUser, isA<UserPlatform>());
    });

    test('setCurrentUser()', () async {
      expect(auth.currentUser, isNull);
      MockUserPlatform userPlatform = MockUserPlatform(auth, multiFactor, user);
      auth.currentUser = userPlatform;
      expect(auth.currentUser, isA<UserPlatform>());
      expect(auth.currentUser!.uid, equals(kMockUid));
    });

    test('delegateFor()', () {
      final testAuth = TestMethodChannelFirebaseAuth(Firebase.app());
      final result = testAuth.delegateFor(app: Firebase.app());

      expect(result, isA<FirebaseAuthPlatform>());
      expect(result.app, isA<FirebaseApp>());
    });

    group('setInitialValues()', () {
      test('when currentUser arg is not null', () {
        final testAuth = TestMethodChannelFirebaseAuth(Firebase.app());
        final result = testAuth.setInitialValues(
            currentUser: kMockUser, languageCode: 'en');
        expect(result, isA<FirebaseAuthPlatform>());
        expect(result.languageCode, equals('en'));
        expect(result.currentUser, isA<MethodChannelUser>());
        expect(testAuth.currentUser, isA<MethodChannelUser>());
      });

      test('when currentUser arg is null', () {
        final testAuth = TestMethodChannelFirebaseAuth(Firebase.app());
        final result = testAuth.setInitialValues(languageCode: 'en');
        expect(result, isA<FirebaseAuthPlatform>());
        expect(result.languageCode, equals('en'));
        expect(result.currentUser, isNull);
        expect(testAuth.currentUser, isNull);
      });
    });

    group('applyActionCode()', () {
      const String code = '12345';
      test('invokes native method with correct args', () async {
        await auth.applyActionCode(code);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#applyActionCode',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'code': code,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() => auth.applyActionCode(code);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() => auth.applyActionCode(code);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('checkActionCode()', () {
      const String code = '12345';

      test('invokes native method with correct args and returns correct result',
          () async {
        final result = await auth.checkActionCode(code);

        // check result
        expect(result, isA<ActionCodeInfo>());
        expect(result.operation, equals(ActionCodeInfoOperation.verifyEmail));
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data['email'], equals(kMockActionCodeInfo.data['email']));
        expect(
          result.data['previousEmail'],
          equals(kMockActionCodeInfo.data['previousEmail']),
        );

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#checkActionCode',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'code': code,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() => auth.checkActionCode(code);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() => auth.checkActionCode(code);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('confirmPasswordReset()', () {
      const String code = '12345';
      const String newPassword = 'newPassword';
      test('invokes native method with correct args', () async {
        await auth.confirmPasswordReset(code, newPassword);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#confirmPasswordReset',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'code': code,
              'newPassword': newPassword,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() => auth.confirmPasswordReset(code, newPassword);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() => auth.confirmPasswordReset(code, newPassword);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('createUserWithEmailAndPassword()', () {
      test('invokes native method with correct args', () async {
        await auth.createUserWithEmailAndPassword(
            regularTestEmail, testPassword);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#createUserWithEmailAndPassword',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'email': regularTestEmail,
              'password': testPassword,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() =>
            auth.createUserWithEmailAndPassword(regularTestEmail, testPassword);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() =>
            auth.createUserWithEmailAndPassword(regularTestEmail, testPassword);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('fetchSignInMethodsForEmail()', () {
      test('invokes native method with correct args', () async {
        await auth.fetchSignInMethodsForEmail(regularTestEmail);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#fetchSignInMethodsForEmail',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'email': regularTestEmail,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() => auth.fetchSignInMethodsForEmail(regularTestEmail);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() => auth.fetchSignInMethodsForEmail(regularTestEmail);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('signInAnonymously()', () {
      test('returns result of a successful sign in', () async {
        final result = await auth.signInAnonymously();

        // check result
        expect(result, isA<UserCredentialPlatform>());
        expect(result.user, isA<UserPlatform>());

        final userResult = result.user!;
        expect(userResult.uid, isA<String>());
        expect(userResult.email, isNull);
        expect(userResult.isAnonymous, isTrue);
        expect(userResult.uid, equals(auth.currentUser!.uid));

        final additionalUserInfo = result.additionalUserInfo;
        expect(additionalUserInfo, isNull);

        // check currentUser was set
        expect(auth.currentUser, isA<UserPlatform>());
        expect(auth.currentUser!.isAnonymous, isTrue);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#signInAnonymously',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.signInAnonymously();
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;

        void callMethod() => auth.signInAnonymously();
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('signInWithCredential()', () {
      test('returns result of a successful sign in', () async {
        final credential = EmailAuthProvider.credential(
            email: regularTestEmail, password: testPassword);
        final result = await auth.signInWithCredential(credential);

        // check result
        expect(result, isA<UserCredentialPlatform>());
        verifyUserCredential(result);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#signInWithCredential',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'credential': credential.asMap()
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        final credential = EmailAuthProvider.credential(
            email: 'disabled@account.com', password: testPassword);

        void callMethod() => auth.signInWithCredential(credential);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        final credential = EmailAuthProvider.credential(
            email: 'unknown', password: testPassword);

        void callMethod() => auth.signInWithCredential(credential);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('signInWithCustomToken()', () {
      test('returns result of a successful sign in', () async {
        const String token = 'testToken';
        final result = await auth.signInWithCustomToken(token);

        // check result
        expect(result, isA<UserCredentialPlatform>());
        verifyUserCredential(result);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#signInWithCustomToken',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'token': token
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        const String token = 'testToken';
        void callMethod() => auth.signInWithCustomToken(token);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        const String token = 'testToken';
        void callMethod() => auth.signInWithCustomToken(token);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('signInWithEmailAndPassword()', () {
      test('returns result of a successful sign in', () async {
        final result = await auth.signInWithEmailAndPassword(
            regularTestEmail, testPassword);

        // check result
        expect(result, isA<UserCredentialPlatform>());
        verifyUserCredential(result);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#signInWithEmailAndPassword',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'email': regularTestEmail,
              'password': testPassword
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() =>
            auth.signInWithEmailAndPassword(regularTestEmail, testPassword);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;

        void callMethod() =>
            auth.signInWithEmailAndPassword(regularTestEmail, testPassword);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('signInWithEmailLink()', () {
      test('returns result of a successful sign in', () async {
        const String emailLink = 'testEmailLink';
        final result =
            await auth.signInWithEmailLink(regularTestEmail, emailLink);

        // check result
        expect(result, isA<UserCredentialPlatform>());
        verifyUserCredential(result);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#signInWithEmailLink',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'email': regularTestEmail,
              'emailLink': emailLink
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() =>
            auth.signInWithEmailAndPassword(regularTestEmail, testPassword);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() =>
            auth.signInWithEmailAndPassword(regularTestEmail, testPassword);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('sendPasswordResetEmail()', () {
      final ActionCodeSettings actionCodeSettings =
          ActionCodeSettings(url: 'test');
      test('invokes native method with correct args', () async {
        await auth.sendPasswordResetEmail(regularTestEmail, actionCodeSettings);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#sendPasswordResetEmail',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'email': regularTestEmail,
              'actionCodeSettings': actionCodeSettings.asMap(),
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() =>
            auth.sendPasswordResetEmail(regularTestEmail, actionCodeSettings);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() =>
            auth.sendPasswordResetEmail(regularTestEmail, actionCodeSettings);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('sendSignInLinkToEmail()', () {
      final ActionCodeSettings actionCodeSettings =
          ActionCodeSettings(url: 'test');

      test('invokes native method with correct args', () async {
        await auth.sendSignInLinkToEmail(regularTestEmail, actionCodeSettings);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#sendSignInLinkToEmail',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'email': regularTestEmail,
              'actionCodeSettings': actionCodeSettings.asMap(),
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() =>
            auth.sendSignInLinkToEmail(regularTestEmail, actionCodeSettings);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() =>
            auth.sendPasswordResetEmail(regularTestEmail, actionCodeSettings);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('setLanguageCode()', () {
      const String languageCode = 'en';
      test('invokes native method with correct args', () async {
        await auth.setLanguageCode(languageCode);

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#setLanguageCode',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'languageCode': languageCode,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() => auth.setLanguageCode(languageCode);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() => auth.setLanguageCode(languageCode);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('setSettings()', () {
      const bool isDisabled = true;
      test('invokes native method with correct args', () async {
        String groupId = 'group-id';
        String phoneNumber = '555-5555';
        String smsCode = '123456';
        bool forceRecaptchaFlow = true;

        await auth.setSettings(
          appVerificationDisabledForTesting: isDisabled,
          userAccessGroup: groupId,
          phoneNumber: phoneNumber,
          smsCode: smsCode,
          forceRecaptchaFlow: forceRecaptchaFlow,
        );

        if (Platform.isIOS || Platform.isMacOS) {
          expect(log, <Matcher>[
            isMethodCall(
              'Auth#setSettings',
              arguments: <String, dynamic>{
                'appName': defaultFirebaseAppName,
                'tenantId': null,
                'appVerificationDisabledForTesting': isDisabled,
                'userAccessGroup': groupId,
              },
            ),
          ]);
        }
        if (Platform.isAndroid) {
          expect(log, <Matcher>[
            isMethodCall(
              'Auth#setSettings',
              arguments: <String, dynamic>{
                'appName': defaultFirebaseAppName,
                'tenantId': null,
                'appVerificationDisabledForTesting': isDisabled,
                'phoneNumber': phoneNumber,
                'smsCode': smsCode,
                'forceRecaptchaFlow': forceRecaptchaFlow,
              },
            ),
          ]);
        }
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() =>
            auth.setSettings(appVerificationDisabledForTesting: isDisabled);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() =>
            auth.setSettings(appVerificationDisabledForTesting: isDisabled);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('setPersistence()', () {
      test('throw [UnimplementedError]', () async {
        const Persistence persistence = Persistence.LOCAL;
        try {
          await auth.setPersistence(persistence);
        } on UnimplementedError catch (e) {
          expect(
              e.message,
              equals(
                  'setPersistence() is only supported on web based platforms'));
        } catch (e) {
          fail('should have thrown an UnimplementedError');
        }
      });
    });

    group('signInWithPopup()', () {
      test('throw [UnimplementedError]', () async {
        final FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        try {
          await auth.signInWithPopup(facebookProvider);
        } on UnimplementedError catch (e) {
          expect(
              e.message,
              equals(
                  'signInWithPopup() is only supported on web based platforms'));
        } catch (e) {
          fail('should have thrown an UnimplementedError');
        }
      });
    });

    group('signInWithRedirect()', () {
      test('throw [UnimplementedError]', () async {
        final FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        try {
          await auth.signInWithRedirect(facebookProvider);
        } on UnimplementedError catch (e) {
          expect(
              e.message,
              equals(
                  'signInWithRedirect() is only supported on web based platforms'));
        } catch (e) {
          fail('should have thrown an UnimplementedError');
        }
      });
    });

    group('signOut()', () {
      test('logs user out correctly', () async {
        await auth.signOut();

        expect(auth.currentUser, isNull);
        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#signOut',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;

        void callMethod() => auth.signOut();
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;

        void callMethod() => auth.signOut();
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('useEmulator()', () {
      test('calls useEmulator correctly', () async {
        await auth.useAuthEmulator('example.com', 31337);
        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#useEmulator',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'host': 'example.com',
              'port': 31337,
            },
          ),
        ]);
      });
    });

    group('verifyPasswordResetCode()', () {
      const String testCode = 'testCode';
      test('returns a successful result', () async {
        final result = await auth.verifyPasswordResetCode(testCode);

        expect(result, isA<String>());
        expect(result, equals(testCode));

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#verifyPasswordResetCode',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'code': testCode,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() => auth.verifyPasswordResetCode(testCode);
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;

        void callMethod() => auth.verifyPasswordResetCode(testCode);
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('verifyPhoneNumber()', () {
      const String testPhoneNumber = '+1 555 555 555';
      const String testSmsCode = '12345';
      const Duration testTimeout = Duration(seconds: 5);

      test('returns a successful result', () async {
        await auth.verifyPhoneNumber(
          phoneNumber: testPhoneNumber,
          verificationCompleted: (PhoneAuthCredential phoneAuthCredential) {},
          verificationFailed: (_) {},
          codeSent: (_, __) {},
          codeAutoRetrievalTimeout: (_) {},
          timeout: testTimeout,
          autoRetrievedSmsCodeForTesting: testSmsCode,
        );

        // check native method was called
        expect(log, <Matcher>[
          isMethodCall(
            'Auth#verifyPhoneNumber',
            arguments: <String, dynamic>{
              'appName': defaultFirebaseAppName,
              'tenantId': null,
              'phoneNumber': testPhoneNumber,
              'timeout': testTimeout.inMilliseconds,
              'forceResendingToken': null,
              'autoRetrievedSmsCodeForTesting': testSmsCode,
            },
          ),
          isMethodCall('listen', arguments: null),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseAuthException] error',
          () async {
        mockPlatformExceptionThrown = true;
        void callMethod() => auth.verifyPhoneNumber(
              phoneNumber: testPhoneNumber,
              verificationCompleted: (_) {},
              verificationFailed: (_) {},
              codeSent: (_, __) {},
              codeAutoRetrievalTimeout: (_) {},
              timeout: testTimeout,
              autoRetrievedSmsCodeForTesting: testSmsCode,
            );
        await testExceptionHandling('PLATFORM', callMethod);
      });

      test('throws an [Exception] error', () async {
        mockExceptionThrown = true;
        void callMethod() => auth.verifyPhoneNumber(
              phoneNumber: testPhoneNumber,
              verificationCompleted: (_) {},
              verificationFailed: (_) {},
              codeSent: (_, __) {},
              codeAutoRetrievalTimeout: (_) {},
              timeout: testTimeout,
              autoRetrievedSmsCodeForTesting: testSmsCode,
            );
        await testExceptionHandling('EXCEPTION', callMethod);
      });
    });

    group('authStateChanges()', () {
      test('returns [Stream<UserPlatform>]', () async {
        // Checks that `authStateChanges` does not throw UnimplementedError
        expect(auth.authStateChanges(), isNotNull);
      });

      test('listens to incoming changes', () async {
        Stream<UserPlatform?> stream =
            auth.authStateChanges().asBroadcastStream();

        await expectLater(stream, emits(isNull));
        expect(auth.currentUser, equals(isNull));

        await injectEventChannelResponse('authStateChannel', {'user': user});

        await expectLater(
          stream,
          emits(isA<UserPlatform>().having((e) => e.uid, 'uid', kMockUid)),
        );
        expect(auth.currentUser!.uid, equals(kMockUid));

        expect(log, isEmpty);
      });

      test('emits the latest user available', () async {
        Stream<UserPlatform?> stream = auth.authStateChanges();

        await injectEventChannelResponse('authStateChannel', {'user': user});

        await expectLater(
          stream,
          emits(isA<UserPlatform>().having((e) => e.uid, 'uid', kMockUid)),
        );

        expect(auth.currentUser!.uid, equals(kMockUid));
        expect(log, isEmpty);
      });
    });

    group('idTokenChanges()', () {
      test('returns [Stream<UserPlatform>]', () async {
        // Checks that `idTokenChanges` does not throw UnimplementedError
        expect(auth.idTokenChanges(), isNotNull);
      });

      test('listens to incoming changes', () async {
        Stream<UserPlatform?> stream =
            auth.idTokenChanges().asBroadcastStream();

        await expectLater(stream, emits(isNull));
        expect(auth.currentUser, equals(isNull));

        await injectEventChannelResponse('idTokenChannel', {'user': user});

        await expectLater(
          stream,
          emits(isA<UserPlatform>().having((e) => e.uid, 'uid', kMockUid)),
        );
        expect(auth.currentUser!.uid, equals(kMockUid));

        expect(log, isEmpty);
      });

      test('emits the latest user available', () async {
        Stream<UserPlatform?> stream = auth.idTokenChanges();

        await injectEventChannelResponse('idTokenChannel', {'user': null});
        await injectEventChannelResponse('idTokenChannel', {'user': user});

        await expectLater(
          stream,
          emits(isA<UserPlatform>().having((e) => e.uid, 'uid', kMockUid)),
        );

        expect(auth.currentUser!.uid, equals(kMockUid));
        expect(log, isEmpty);
      });
    });

    group('userChanges()', () {
      test('returns [Stream<UserPlatform>]', () async {
        // Checks that `userChanges` does not throw UnimplementedError
        expect(auth.userChanges(), isNotNull);
      });

      test('listens to incoming changes', () async {
        Stream<UserPlatform?> stream = auth.userChanges().asBroadcastStream();

        await expectLater(stream, emits(isNull));
        expect(auth.currentUser, equals(isNull));

        await injectEventChannelResponse('idTokenChannel', {'user': user});

        await expectLater(
          stream,
          emits(isA<UserPlatform>().having((e) => e.uid, 'uid', kMockUid)),
        );
        expect(auth.currentUser!.uid, equals(kMockUid));

        expect(log, isEmpty);
      });

      test('emits the latest user available', () async {
        Stream<UserPlatform?> stream = auth.userChanges();
        // id token change events will trigger setCurrentUser()
        // and hence userChange events
        await injectEventChannelResponse('idTokenChannel', {'user': null});
        await injectEventChannelResponse('idTokenChannel', {'user': user});

        await expectLater(
          stream,
          emits(isA<UserPlatform>().having((e) => e.uid, 'uid', kMockUid)),
        );

        expect(auth.currentUser!.uid, equals(kMockUid));
        expect(log, isEmpty);
      });
    });
  });
}

class MockUserPlatform extends UserPlatform {
  MockUserPlatform(FirebaseAuthPlatform auth, MultiFactorPlatform multiFactor,
      Map<String, dynamic> user)
      : super(auth, multiFactor, user);
}

class TestMethodChannelFirebaseAuth extends MethodChannelFirebaseAuth {
  TestMethodChannelFirebaseAuth(FirebaseApp app) : super(app: app);
}
