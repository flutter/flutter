// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../mock.dart';
import '../providers_tests/email_auth_test.dart';

void main() {
  setupFirebaseAuthMocks();

  late TestFirebaseAuthPlatform firebaseAuthPlatform;

  late FirebaseApp app;
  late FirebaseApp secondaryApp;
  group('$FirebaseAuthPlatform()', () {
    setUpAll(() async {
      app = await Firebase.initializeApp();
      secondaryApp = await Firebase.initializeApp(
        name: 'testApp2',
        options: const FirebaseOptions(
          appId: '1:1234567890:ios:42424242424242',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '1234567890',
        ),
      );

      firebaseAuthPlatform = TestFirebaseAuthPlatform(
        app,
      );
      handleMethodCall((call) async {
        switch (call.method) {
          case 'Auth#registerIdTokenListener':
            const String name = 'idTokenChannel';
            handleEventChannel(name);
            return name;
          case 'Auth#registerAuthStateListener':
            const String name = 'authStateChannel';
            handleEventChannel(name);
            return name;
          default:
            return null;
        }
      });
    });

    test('Constructor', () {
      expect(firebaseAuthPlatform, isA<FirebaseAuthPlatform>());
      expect(firebaseAuthPlatform, isA<PlatformInterface>());
    });

    test('FirebaseAuthPlatform.instanceFor', () {
      final result = FirebaseAuthPlatform.instanceFor(
          app: app,
          pluginConstants: <dynamic, dynamic>{
            'APP_LANGUAGE_CODE': 'en',
            'APP_CURRENT_USER': <dynamic, dynamic>{'uid': '1234'}
          });
      expect(result, isA<FirebaseAuthPlatform>());
      expect(result.currentUser, isA<UserPlatform>());
      expect(result.currentUser!.uid, '1234');
      expect(result.languageCode, equals('en'));
    });

    test('get.instance', () {
      expect(FirebaseAuthPlatform.instance, isA<FirebaseAuthPlatform>());
      expect(FirebaseAuthPlatform.instance.app.name,
          equals(defaultFirebaseAppName));
    });

    group('set.instance', () {
      test('sets the current instance', () {
        FirebaseAuthPlatform.instance = TestFirebaseAuthPlatform(secondaryApp);

        expect(FirebaseAuthPlatform.instance, isA<FirebaseAuthPlatform>());
        expect(FirebaseAuthPlatform.instance.app.name, equals('testApp2'));
      });
    });

    test('throws if .delegateFor', () {
      expect(
        () => firebaseAuthPlatform.testDelegateFor(app: Firebase.app()),
        throwsUnimplementedError,
      );
    });

    test('throws if .setInitialValues', () {
      expect(
        () => firebaseAuthPlatform.testSetInitialValues(),
        throwsUnimplementedError,
      );
    });

    test('throws if get.currentUser', () {
      expect(
        () => firebaseAuthPlatform.currentUser,
        throwsUnimplementedError,
      );
    });

    test('throws if set.currentUser', () {
      expect(
        () => firebaseAuthPlatform.sendAuthChangesEvent(
            defaultFirebaseAppName, null),
        throwsUnimplementedError,
      );
      try {
        firebaseAuthPlatform.currentUser = null;
      } on UnimplementedError catch (e) {
        expect(e.message, equals('set.currentUser is not implemented'));
        return;
      }
      fail('Should have thrown an [UnimplementedError]');
    });

    test('throws if languageCode', () {
      expect(
        () => firebaseAuthPlatform.languageCode,
        throwsUnimplementedError,
      );
    });

    test('throws if sendAuthChangesEvent()', () {
      expect(
        () => firebaseAuthPlatform.sendAuthChangesEvent(
          defaultFirebaseAppName,
          null,
        ),
        throwsUnimplementedError,
      );
    });

    test('throws if applyActionCode()', () async {
      await expectLater(
        () => firebaseAuthPlatform.applyActionCode('test'),
        throwsUnimplementedError,
      );
    });

    test('throws if checkActionCode()', () async {
      await expectLater(
        () => firebaseAuthPlatform.checkActionCode('test'),
        throwsUnimplementedError,
      );
    });

    test('throws if confirmPasswordReset()', () async {
      await expectLater(
        () => firebaseAuthPlatform.confirmPasswordReset('test', 'new-password'),
        throwsUnimplementedError,
      );
    });

    test('throws if createUserWithEmailAndPassword()', () async {
      await expectLater(
        () => firebaseAuthPlatform.createUserWithEmailAndPassword(
          'test@email.com',
          'password',
        ),
        throwsUnimplementedError,
      );
    });

    test('throws if fetchSignInMethodsForEmail()', () async {
      await expectLater(
        () => firebaseAuthPlatform.fetchSignInMethodsForEmail('test@email.com'),
        throwsUnimplementedError,
      );
    });

    test('throws if getRedirectResult()', () async {
      await expectLater(
        () => firebaseAuthPlatform.getRedirectResult(),
        throwsUnimplementedError,
      );
    });

    group('isSignInWithEmailLink()', () {
      test('returns correct result', () {
        String testEmail = 'test@email.com?';
        String mode1 = 'mode=signIn';
        String mode2 = 'mode%3DsignIn';
        String code1 = 'oobCode=';
        String code2 = 'oobCode%3D';
        List options = [
          {'email': testEmail, 'expected': false},
          {'email': '$testEmail$mode1', 'expected': false},
          {'email': '$testEmail$mode2', 'expected': false},
          {'email': '$testEmail$mode1&$mode2', 'expected': false},
          {'email': '$testEmail$code1', 'expected': false},
          {'email': '$testEmail$code2', 'expected': false},
          {'email': '$testEmail$code1&$code2', 'expected': false},
          {'email': '$testEmail$mode1&$code1', 'expected': true},
          {'email': '$testEmail$mode1&$code2', 'expected': true},
          {'email': '$testEmail$mode2&$code1', 'expected': true},
          {'email': '$testEmail$mode2&$code2', 'expected': true},
        ];

        for (final element in options) {
          expect(
            firebaseAuthPlatform.isSignInWithEmailLink(element['email']),
            equals(element['expected']),
          );
        }
      });
    });

    test('throws if authStateChanges()', () {
      expect(
        () => firebaseAuthPlatform.authStateChanges(),
        throwsUnimplementedError,
      );
    });

    test('throws if idTokenChanges()', () {
      expect(
        () => firebaseAuthPlatform.idTokenChanges(),
        throwsUnimplementedError,
      );
    });

    test('throws if userChanges()', () {
      expect(
        () => firebaseAuthPlatform.sendPasswordResetEmail('test@email.com'),
        throwsUnimplementedError,
      );
    });

    test('throws if sendPasswordResetEmail()', () async {
      await expectLater(
        () => firebaseAuthPlatform.sendPasswordResetEmail('test@email.com'),
        throwsUnimplementedError,
      );
    });

    test('throws if sendSignInLinkToEmail()', () async {
      await expectLater(
        () => firebaseAuthPlatform.sendSignInLinkToEmail(
          'test@email.com',
          ActionCodeSettings(url: '/'),
        ),
        throwsUnimplementedError,
      );
    });

    test('throws if setLanguageCode()', () async {
      await expectLater(
        () => firebaseAuthPlatform.setLanguageCode('en'),
        throwsUnimplementedError,
      );
    });

    test('throws if setSettings()', () async {
      await expectLater(
        () => firebaseAuthPlatform.setSettings(),
        throwsUnimplementedError,
      );
    });

    test('throws if setPersistence()', () async {
      await expectLater(
        () => firebaseAuthPlatform.setPersistence(Persistence.LOCAL),
        throwsUnimplementedError,
      );
    });

    test('throws if signInAnonymously()', () async {
      await expectLater(
        firebaseAuthPlatform.signInAnonymously,
        throwsUnimplementedError,
      );
    });

    test('throws if signInWithCredential()', () async {
      await expectLater(
        () => firebaseAuthPlatform.signInWithCredential(
          const AuthCredential(
            providerId: 'provider',
            signInMethod: 'method',
          ),
        ),
        throwsUnimplementedError,
      );
    });

    test('throws if signInWithEmailAndPassword()', () async {
      await expectLater(
        () => firebaseAuthPlatform.signInWithEmailAndPassword(
          'test@email.com',
          'password',
        ),
        throwsUnimplementedError,
      );
    });

    test('throws if signInWithEmailLink()', () async {
      await expectLater(
        () => firebaseAuthPlatform.signInWithEmailLink(
          'test@email.com',
          'test.com',
        ),
        throwsUnimplementedError,
      );
    });

    test('throws if signInWithPhoneNumber()', () async {
      await expectLater(
        () => firebaseAuthPlatform.signInWithPhoneNumber(
          TEST_PHONE_NUMBER,
          FakeRecaptchaVerifierFactoryPlatform(),
        ),
        throwsUnimplementedError,
      );
    });

    test('throws if signInWithPopup()', () async {
      await expectLater(
        () => firebaseAuthPlatform.signInWithPopup(TestEmailAuthProvider()),
        throwsUnimplementedError,
      );
    });

    test('throws if signInWithRedirect()', () async {
      await expectLater(
        () => firebaseAuthPlatform.signInWithRedirect(TestEmailAuthProvider()),
        throwsUnimplementedError,
      );
    });

    test('throws if signOut()', () async {
      await expectLater(
        () => firebaseAuthPlatform.signOut(),
        throwsUnimplementedError,
      );
    });

    test('throws if useEmulator', () async {
      await expectLater(
        () => firebaseAuthPlatform.useAuthEmulator('http://localhost', 9099),
        throwsUnimplementedError,
      );
    });

    test('throws if verifyPasswordResetCode()', () async {
      await expectLater(
        () => firebaseAuthPlatform.verifyPasswordResetCode('test'),
        throwsUnimplementedError,
      );
    });

    test('throws if verifyPhoneNumber()', () async {
      await expectLater(
        () => firebaseAuthPlatform.verifyPhoneNumber(
          phoneNumber: '',
          verificationCompleted: (_) {},
          verificationFailed: (_) {},
          codeAutoRetrievalTimeout: (_) {},
          codeSent: (_, __) {},
        ),
        throwsUnimplementedError,
      );
    });
  });
}

class TestFirebaseAuthPlatform extends FirebaseAuthPlatform {
  TestFirebaseAuthPlatform(FirebaseApp app) : super(appInstance: app);
  FirebaseAuthPlatform testDelegateFor({required FirebaseApp app}) {
    return delegateFor(app: app);
  }

  FirebaseAuthPlatform testSetInitialValues() {
    return setInitialValues();
  }
}

class FakeRecaptchaVerifierFactoryPlatform extends Fake
    implements RecaptchaVerifierFactoryPlatform {}
