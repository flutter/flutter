// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// import './user_test.mocks.dart';
import './mock.dart';
import 'firebase_auth_test.dart';

Map<String, dynamic> kMockUser1 = <String, dynamic>{
  'isAnonymous': true,
  'emailVerified': false,
  'displayName': 'displayName',
};

// @GenerateMocks([], customMocks: [
//   MockSpec<MockFirebaseAuthPlatformBase>(as: #MockFirebaseAuthPlatform),
//   MockSpec<MockUserPlatformBase>(as: #MockUserPlatform),
// ])
void main() {
  setupFirebaseAuthMocks();

  FirebaseAuth? auth;

  const Map<String, dynamic> kMockIdTokenResult = <String, dynamic>{
    'token': '12345',
    'expirationTimestamp': 123456,
    'authTimestamp': 1234567,
    'issuedAtTimestamp': 12345678,
    'signInProvider': 'password',
    'claims': <dynamic, dynamic>{
      'claim1': 'value1',
    },
  };

  final int kMockCreationTimestamp =
      DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch;
  final int kMockLastSignInTimestamp =
      DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;

  Map<String, dynamic> kMockUser = <String, dynamic>{
    'isAnonymous': true,
    'emailVerified': false,
    'uid': '42',
    'displayName': 'displayName',
    'metadata': <String, int>{
      'creationTime': kMockCreationTimestamp,
      'lastSignInTime': kMockLastSignInTimestamp,
    },
    'providerData': <Map<String, String>>[
      <String, String>{
        'providerId': 'firebase',
        'uid': '12345',
        'displayName': 'Flutter Test User',
        'photoURL': 'http://www.example.com/',
        'email': 'test@example.com',
      },
    ],
  };

  MockUserPlatform? mockUserPlatform;
  MockUserCredentialPlatform? mockUserCredPlatform;

  AdditionalUserInfo mockAdditionalInfo = AdditionalUserInfo(
    isNewUser: false,
    username: 'flutterUser',
    providerId: 'testProvider',
    profile: <String, dynamic>{'foo': 'bar'},
  );

  EmailAuthCredential mockCredential =
      EmailAuthProvider.credential(email: 'test', password: 'test')
          as EmailAuthCredential;

  var mockAuthPlatform = MockFirebaseAuth();

  group('$User', () {
    Map<String, dynamic>? user;

    // used to generate a unique application name for each test
    var testCount = 0;

    setUp(() async {
      FirebaseAuthPlatform.instance = mockAuthPlatform = MockFirebaseAuth();

      // Each test uses a unique FirebaseApp instance to avoid sharing state
      final app = await Firebase.initializeApp(
        name: '$testCount',
        options: const FirebaseOptions(
          apiKey: '',
          appId: '',
          messagingSenderId: '',
          projectId: '',
        ),
      );

      auth = FirebaseAuth.instanceFor(app: app);

      user = kMockUser;

      mockUserPlatform = MockUserPlatform(mockAuthPlatform, user!);

      mockUserCredPlatform = MockUserCredentialPlatform(
        FirebaseAuthPlatform.instance,
        mockAdditionalInfo,
        mockCredential,
        mockUserPlatform!,
      );

      when(mockAuthPlatform.signInAnonymously()).thenAnswer(
          (_) => Future<UserCredentialPlatform>.value(mockUserCredPlatform));

      when(mockAuthPlatform.currentUser).thenReturn(mockUserPlatform);

      when(mockAuthPlatform.delegateFor(
        app: anyNamed('app'),
      )).thenAnswer((_) => mockAuthPlatform);

      when(mockAuthPlatform.setInitialValues(
        currentUser: anyNamed('currentUser'),
        languageCode: anyNamed('languageCode'),
      )).thenAnswer((_) => mockAuthPlatform);

      MethodChannelFirebaseAuth.channel.setMockMethodCallHandler((call) async {
        switch (call.method) {
          default:
            return <String, dynamic>{'user': user};
        }
      });
    });

    tearDown(() => testCount++);

    setUp(() async {
      user = kMockUser;
      await auth!.signInAnonymously();
    });

    test('delete()', () async {
      // Necessary as we otherwise get a "null is not a Future<void>" error
      when(mockUserPlatform!.delete()).thenAnswer((i) async {});

      await auth!.currentUser!.delete();

      verify(mockUserPlatform!.delete());
    });

    test('getIdToken()', () async {
      // Necessary as we otherwise get a "null is not a Future<void>" error
      when(mockUserPlatform!.getIdToken(any)).thenAnswer((_) async => 'token');

      final token = await auth!.currentUser!.getIdToken(true);

      verify(mockUserPlatform!.getIdToken(true));
      expect(token, isA<String>());
    });

    test('getIdTokenResult()', () async {
      when(mockUserPlatform!.getIdTokenResult(any))
          .thenAnswer((_) async => IdTokenResult(kMockIdTokenResult));

      final idTokenResult = await auth!.currentUser!.getIdTokenResult(true);

      verify(mockUserPlatform!.getIdTokenResult(true));
      expect(idTokenResult, isA<IdTokenResult>());
    });

    group('linkWithCredential()', () {
      setUp(() {
        when(mockUserPlatform!.linkWithCredential(any))
            .thenAnswer((_) async => mockUserCredPlatform!);
      });

      test('should call linkWithCredential()', () async {
        String newEmail = 'new@email.com';
        EmailAuthCredential credential =
            EmailAuthProvider.credential(email: newEmail, password: 'test')
                as EmailAuthCredential;

        await auth!.currentUser!.linkWithCredential(credential);

        verify(mockUserPlatform!.linkWithCredential(credential));
      });
    });

    group('reauthenticateWithCredential()', () {
      setUp(() {
        when(mockUserPlatform!.reauthenticateWithCredential(any))
            .thenAnswer((_) => Future.value(mockUserCredPlatform));
      });
      test('should call reauthenticateWithCredential()', () async {
        String newEmail = 'new@email.com';
        EmailAuthCredential credential =
            EmailAuthProvider.credential(email: newEmail, password: 'test')
                as EmailAuthCredential;

        await auth!.currentUser!.reauthenticateWithCredential(credential);

        verify(mockUserPlatform!.reauthenticateWithCredential(credential));
      });
    });

    test('reload()', () async {
      // Necessary as we otherwise get a "null is not a Future<void>" error
      when(mockUserPlatform!.reload()).thenAnswer((i) async {});

      await auth!.currentUser!.reload();

      verify(mockUserPlatform!.reload());
    });

    test('sendEmailVerification()', () async {
      // Necessary as we otherwise get a "null is not a Future<void>" error
      when(mockUserPlatform!.sendEmailVerification(any))
          .thenAnswer((i) async {});

      final ActionCodeSettings actionCodeSettings =
          ActionCodeSettings(url: 'test');

      await auth!.currentUser!.sendEmailVerification(actionCodeSettings);

      verify(mockUserPlatform!.sendEmailVerification(actionCodeSettings));
    });

    group('unlink()', () {
      setUp(() {
        when(mockUserPlatform!.unlink(any))
            .thenAnswer((_) => Future.value(mockUserPlatform));
      });
      test('should call unlink()', () async {
        const String providerId = 'providerId';

        await auth!.currentUser!.unlink(providerId);

        verify(mockUserPlatform!.unlink(providerId));
      });
    });
    group('updateEmail()', () {
      test('should call updateEmail()', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockUserPlatform!.updateEmail(any)).thenAnswer((i) async {});

        const String newEmail = 'newEmail';

        await auth!.currentUser!.updateEmail(newEmail);

        verify(mockUserPlatform!.updateEmail(newEmail));
      });
    });

    group('updatePassword()', () {
      test('should call updatePassword()', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockUserPlatform!.updatePassword(any)).thenAnswer((i) async {});

        const String newPassword = 'newPassword';

        await auth!.currentUser!.updatePassword(newPassword);

        verify(mockUserPlatform!.updatePassword(newPassword));
      });
    });
    group('updatePhoneNumber()', () {
      test('should call updatePhoneNumber()', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockUserPlatform!.updatePhoneNumber(any)).thenAnswer((i) async {});

        PhoneAuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
          verificationId: 'test',
          smsCode: 'test',
        );

        await auth!.currentUser!.updatePhoneNumber(phoneAuthCredential);

        verify(mockUserPlatform!.updatePhoneNumber(phoneAuthCredential));
      });
    });

    test('updateProfile()', () async {
      // Necessary as we otherwise get a "null is not a Future<void>" error
      when(mockUserPlatform!.updateProfile(any)).thenAnswer((i) async {});

      const String displayName = 'updatedName';
      const String photoURL = 'testUrl';
      Map<String, String> data = <String, String>{
        'displayName': displayName,
        'photoURL': photoURL
      };

      await auth!.currentUser!
          // ignore: deprecated_member_use_from_same_package
          .updateProfile(displayName: displayName, photoURL: photoURL);

      verify(mockUserPlatform!.updateProfile(data));
    });

    group('verifyBeforeUpdateEmail()', () {
      test('should call verifyBeforeUpdateEmail()', () async {
        // Necessary as we otherwise get a "null is not a Future<void>" error
        when(mockUserPlatform!.verifyBeforeUpdateEmail(any, any))
            .thenAnswer((i) async {});

        const newEmail = 'new@email.com';
        ActionCodeSettings actionCodeSettings = ActionCodeSettings(url: 'test');

        await auth!.currentUser!
            .verifyBeforeUpdateEmail(newEmail, actionCodeSettings);

        verify(mockUserPlatform!
            .verifyBeforeUpdateEmail(newEmail, actionCodeSettings));
      });
    });

    test('toString()', () async {
      when(mockAuthPlatform.currentUser).thenReturn(TestUserPlatform(
          mockAuthPlatform, TestMultiFactorPlatform(mockAuthPlatform), user!));

      const userInfo = 'UserInfo('
          'displayName: Flutter Test User, '
          'email: test@example.com, '
          'phoneNumber: null, '
          'photoURL: http://www.example.com/, '
          'providerId: firebase, '
          'uid: 12345)';

      final userMetadata = 'UserMetadata('
          'creationTime: ${DateTime.fromMillisecondsSinceEpoch(kMockCreationTimestamp, isUtc: true)}, '
          'lastSignInTime: ${DateTime.fromMillisecondsSinceEpoch(kMockLastSignInTimestamp, isUtc: true)})';

      expect(
        auth!.currentUser.toString(),
        'User('
        'displayName: displayName, '
        'email: null, '
        'emailVerified: false, '
        'isAnonymous: true, '
        'metadata: $userMetadata, '
        'phoneNumber: null, '
        'photoURL: null, '
        'providerData, '
        '[$userInfo], '
        'refreshToken: null, '
        'tenantId: null, '
        'uid: 42)',
      );
    });
  });
}

class MockFirebaseAuthPlatformBase = TestFirebaseAuthPlatform
    with MockPlatformInterfaceMixin;

class MockUserPlatformBase = TestUserPlatform with MockPlatformInterfaceMixin;

class MockFirebaseAuth extends Mock
    with MockPlatformInterfaceMixin
    implements TestFirebaseAuthPlatform {
  @override
  Future<UserCredentialPlatform> signInAnonymously() {
    return super.noSuchMethod(
      Invocation.method(#signInAnonymously, const []),
      returnValue: neverEndingFuture<UserCredentialPlatform>(),
      returnValueForMissingStub: neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  FirebaseAuthPlatform delegateFor(
      {FirebaseApp? app, Persistence? persistence}) {
    return super.noSuchMethod(
      Invocation.method(#delegateFor, const [], {#app: app}),
      returnValue: TestFirebaseAuthPlatform(),
      returnValueForMissingStub: TestFirebaseAuthPlatform(),
    );
  }

  @override
  FirebaseAuthPlatform setInitialValues({
    Map<String, dynamic>? currentUser,
    String? languageCode,
  }) {
    return super.noSuchMethod(
      Invocation.method(#setInitialValues, const [], {
        #currentUser: currentUser,
        #languageCode: languageCode,
      }),
      returnValue: TestFirebaseAuthPlatform(),
      returnValueForMissingStub: TestFirebaseAuthPlatform(),
    );
  }
}

class MockUserPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TestUserPlatform {
  MockUserPlatform(FirebaseAuthPlatform auth, Map<String, dynamic> _user) {
    TestUserPlatform(auth, TestMultiFactorPlatform(auth), _user);
  }

  @override
  Future<void> delete() {
    return super.noSuchMethod(
      Invocation.method(#delete, []),
      returnValue: neverEndingFuture<void>(),
      returnValueForMissingStub: neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> reload() {
    return super.noSuchMethod(
      Invocation.method(#reload, []),
      returnValue: neverEndingFuture<void>(),
      returnValueForMissingStub: neverEndingFuture<void>(),
    );
  }

  @override
  Future<String> getIdToken(bool? forceRefresh) {
    return super.noSuchMethod(
      Invocation.method(#getIdToken, [forceRefresh]),
      returnValue: neverEndingFuture<String>(),
      returnValueForMissingStub: neverEndingFuture<String>(),
    );
  }

  @override
  Future<UserPlatform> unlink(String? providerId) {
    return super.noSuchMethod(
      Invocation.method(#unlink, [providerId]),
      returnValue: neverEndingFuture<UserPlatform>(),
      returnValueForMissingStub: neverEndingFuture<UserPlatform>(),
    );
  }

  @override
  Future<IdTokenResult> getIdTokenResult(bool? forceRefresh) {
    return super.noSuchMethod(
      Invocation.method(#getIdTokenResult, [forceRefresh]),
      returnValue: neverEndingFuture<IdTokenResult>(),
      returnValueForMissingStub: neverEndingFuture<IdTokenResult>(),
    );
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
    AuthCredential? credential,
  ) {
    return super.noSuchMethod(
      Invocation.method(#reauthenticateWithCredential, [credential]),
      returnValue: neverEndingFuture<UserCredentialPlatform>(),
      returnValueForMissingStub: neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<UserCredentialPlatform> linkWithCredential(
    AuthCredential? credential,
  ) {
    return super.noSuchMethod(
      Invocation.method(#linkWithCredential, [credential]),
      returnValue: neverEndingFuture<UserCredentialPlatform>(),
      returnValueForMissingStub: neverEndingFuture<UserCredentialPlatform>(),
    );
  }

  @override
  Future<void> sendEmailVerification(ActionCodeSettings? actionCodeSettings) {
    return super.noSuchMethod(
      Invocation.method(#sendEmailVerification, [actionCodeSettings]),
      returnValue: neverEndingFuture<void>(),
      returnValueForMissingStub: neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> updateEmail(String? newEmail) {
    return super.noSuchMethod(
      Invocation.method(#updateEmail, [newEmail]),
      returnValue: neverEndingFuture<void>(),
      returnValueForMissingStub: neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> updatePassword(String? newPassword) {
    return super.noSuchMethod(
      Invocation.method(#updatePassword, [newPassword]),
      returnValue: neverEndingFuture<void>(),
      returnValueForMissingStub: neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential? phoneCredential) {
    return super.noSuchMethod(
      Invocation.method(#updatePhoneNumber, [phoneCredential]),
      returnValue: neverEndingFuture<void>(),
      returnValueForMissingStub: neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> updateProfile(Map<String, String?>? profile) {
    return super.noSuchMethod(
      Invocation.method(#updateProfile, [profile]),
      returnValue: neverEndingFuture<void>(),
      returnValueForMissingStub: neverEndingFuture<void>(),
    );
  }

  @override
  Future<void> verifyBeforeUpdateEmail(
    String? newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) {
    return super.noSuchMethod(
      Invocation.method(#verifyBeforeUpdateEmail, [
        newEmail,
        actionCodeSettings,
      ]),
      returnValue: neverEndingFuture<void>(),
      returnValueForMissingStub: neverEndingFuture<void>(),
    );
  }
}

class MockUserCredentialPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TestUserCredentialPlatform {
  MockUserCredentialPlatform(
    FirebaseAuthPlatform auth,
    AdditionalUserInfo additionalUserInfo,
    AuthCredential credential,
    UserPlatform userPlatform,
  ) {
    TestUserCredentialPlatform(
      auth,
      additionalUserInfo,
      credential,
      userPlatform,
    );
  }
}

class TestFirebaseAuthPlatform extends FirebaseAuthPlatform {
  TestFirebaseAuthPlatform() : super();

  @override
  FirebaseAuthPlatform delegateFor(
          {FirebaseApp? app, Persistence? persistence}) =>
      this;

  @override
  FirebaseAuthPlatform setInitialValues({
    Map<String, dynamic>? currentUser,
    String? languageCode,
  }) {
    return this;
  }
}

class TestUserPlatform extends UserPlatform {
  TestUserPlatform(FirebaseAuthPlatform auth, MultiFactorPlatform multiFactor,
      Map<String, dynamic> data)
      : super(auth, multiFactor, data);
}

class TestUserCredentialPlatform extends UserCredentialPlatform {
  TestUserCredentialPlatform(
    FirebaseAuthPlatform auth,
    AdditionalUserInfo additionalUserInfo,
    AuthCredential credential,
    UserPlatform userPlatform,
  ) : super(
            auth: auth,
            additionalUserInfo: additionalUserInfo,
            credential: credential,
            user: userPlatform);
}
