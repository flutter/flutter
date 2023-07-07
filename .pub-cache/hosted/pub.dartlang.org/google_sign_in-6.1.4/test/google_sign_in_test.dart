// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'google_sign_in_test.mocks.dart';

/// Verify that [GoogleSignInAccount] can be mocked even though it's unused
// ignore: avoid_implementing_value_types, must_be_immutable
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

@GenerateMocks(<Type>[GoogleSignInPlatform])
void main() {
  late MockGoogleSignInPlatform mockPlatform;

  group('GoogleSignIn', () {
    final GoogleSignInUserData kDefaultUser = GoogleSignInUserData(
        email: 'john.doe@gmail.com',
        id: '8162538176523816253123',
        photoUrl: 'https://lh5.googleusercontent.com/photo.jpg',
        displayName: 'John Doe',
        serverAuthCode: '789');

    setUp(() {
      mockPlatform = MockGoogleSignInPlatform();
      when(mockPlatform.isMock).thenReturn(true);
      when(mockPlatform.userDataEvents).thenReturn(null);
      when(mockPlatform.signInSilently())
          .thenAnswer((Invocation _) async => kDefaultUser);
      when(mockPlatform.signIn())
          .thenAnswer((Invocation _) async => kDefaultUser);

      GoogleSignInPlatform.instance = mockPlatform;
    });

    test('signInSilently', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      await googleSignIn.signInSilently();

      expect(googleSignIn.currentUser, isNotNull);
      _verifyInit(mockPlatform);
      verify(mockPlatform.signInSilently());
    });

    test('signIn', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      await googleSignIn.signIn();

      expect(googleSignIn.currentUser, isNotNull);
      _verifyInit(mockPlatform);
      verify(mockPlatform.signIn());
    });

    test('clientId parameter is forwarded to implementation', () async {
      const String fakeClientId = 'fakeClientId';
      final GoogleSignIn googleSignIn = GoogleSignIn(clientId: fakeClientId);

      await googleSignIn.signIn();

      _verifyInit(mockPlatform, clientId: fakeClientId);
      verify(mockPlatform.signIn());
    });

    test('serverClientId parameter is forwarded to implementation', () async {
      const String fakeServerClientId = 'fakeServerClientId';
      final GoogleSignIn googleSignIn =
          GoogleSignIn(serverClientId: fakeServerClientId);

      await googleSignIn.signIn();

      _verifyInit(mockPlatform, serverClientId: fakeServerClientId);
      verify(mockPlatform.signIn());
    });

    test('forceCodeForRefreshToken sent with init method call', () async {
      final GoogleSignIn googleSignIn =
          GoogleSignIn(forceCodeForRefreshToken: true);

      await googleSignIn.signIn();

      _verifyInit(mockPlatform, forceCodeForRefreshToken: true);
      verify(mockPlatform.signIn());
    });

    test('signOut', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      await googleSignIn.signOut();

      _verifyInit(mockPlatform);
      verify(mockPlatform.signOut());
    });

    test('disconnect; null response', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      await googleSignIn.disconnect();

      expect(googleSignIn.currentUser, isNull);
      _verifyInit(mockPlatform);
      verify(mockPlatform.disconnect());
    });

    test('isSignedIn', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      when(mockPlatform.isSignedIn()).thenAnswer((Invocation _) async => true);

      final bool result = await googleSignIn.isSignedIn();

      expect(result, isTrue);
      _verifyInit(mockPlatform);
      verify(mockPlatform.isSignedIn());
    });

    test('signIn works even if a previous call throws error in other zone',
        () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      when(mockPlatform.signInSilently()).thenThrow(Exception('Not a user'));
      await runZonedGuarded(() async {
        expect(await googleSignIn.signInSilently(), isNull);
      }, (Object e, StackTrace st) {});
      expect(await googleSignIn.signIn(), isNotNull);
      _verifyInit(mockPlatform);
      verify(mockPlatform.signInSilently());
      verify(mockPlatform.signIn());
    });

    test('concurrent calls of the same method trigger sign in once', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final List<Future<GoogleSignInAccount?>> futures =
          <Future<GoogleSignInAccount?>>[
        googleSignIn.signInSilently(),
        googleSignIn.signInSilently(),
      ];

      expect(futures.first, isNot(futures.last),
          reason: 'Must return new Future');

      final List<GoogleSignInAccount?> users = await Future.wait(futures);

      expect(googleSignIn.currentUser, isNotNull);
      expect(users, <GoogleSignInAccount?>[
        googleSignIn.currentUser,
        googleSignIn.currentUser
      ]);
      _verifyInit(mockPlatform);
      verify(mockPlatform.signInSilently()).called(1);
    });

    test('can sign in after previously failed attempt', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      when(mockPlatform.signInSilently()).thenThrow(Exception('Not a user'));

      expect(await googleSignIn.signInSilently(), isNull);
      expect(await googleSignIn.signIn(), isNotNull);

      _verifyInit(mockPlatform);
      verify(mockPlatform.signInSilently());
      verify(mockPlatform.signIn());
    });

    test('concurrent calls of different signIn methods', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final List<Future<GoogleSignInAccount?>> futures =
          <Future<GoogleSignInAccount?>>[
        googleSignIn.signInSilently(),
        googleSignIn.signIn(),
      ];
      expect(futures.first, isNot(futures.last));

      final List<GoogleSignInAccount?> users = await Future.wait(futures);

      expect(users.first, users.last, reason: 'Must return the same user');
      expect(googleSignIn.currentUser, users.last);
      _verifyInit(mockPlatform);
      verify(mockPlatform.signInSilently());
      verifyNever(mockPlatform.signIn());
    });

    test('can sign in after aborted flow', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      when(mockPlatform.signIn()).thenAnswer((Invocation _) async => null);
      expect(await googleSignIn.signIn(), isNull);

      when(mockPlatform.signIn())
          .thenAnswer((Invocation _) async => kDefaultUser);
      expect(await googleSignIn.signIn(), isNotNull);
    });

    test('signOut/disconnect methods always trigger native calls', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final List<Future<GoogleSignInAccount?>> futures =
          <Future<GoogleSignInAccount?>>[
        googleSignIn.signOut(),
        googleSignIn.signOut(),
        googleSignIn.disconnect(),
        googleSignIn.disconnect(),
      ];

      await Future.wait(futures);

      _verifyInit(mockPlatform);
      verify(mockPlatform.signOut()).called(2);
      verify(mockPlatform.disconnect()).called(2);
    });

    test('queue of many concurrent calls', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final List<Future<GoogleSignInAccount?>> futures =
          <Future<GoogleSignInAccount?>>[
        googleSignIn.signInSilently(),
        googleSignIn.signOut(),
        googleSignIn.signIn(),
        googleSignIn.disconnect(),
      ];

      await Future.wait(futures);

      _verifyInit(mockPlatform);
      verifyInOrder(<Object>[
        mockPlatform.signInSilently(),
        mockPlatform.signOut(),
        mockPlatform.signIn(),
        mockPlatform.disconnect(),
      ]);
    });

    test('signInSilently suppresses errors by default', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      when(mockPlatform.signInSilently()).thenThrow(Exception('I am an error'));
      expect(await googleSignIn.signInSilently(), isNull); // should not throw
    });

    test('signInSilently forwards exceptions', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      when(mockPlatform.signInSilently()).thenThrow(Exception('I am an error'));
      expect(googleSignIn.signInSilently(suppressErrors: false),
          throwsA(isInstanceOf<Exception>()));
    });

    test('signInSilently allows re-authentication to be requested', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signInSilently();
      expect(googleSignIn.currentUser, isNotNull);

      await googleSignIn.signInSilently(reAuthenticate: true);

      _verifyInit(mockPlatform);
      verify(mockPlatform.signInSilently()).called(2);
    });

    test('can sign in after init failed before', () async {
      // Web eagerly `initWithParams` when GoogleSignIn is created, so make sure
      // the initWithParams is throwy ASAP.
      when(mockPlatform.initWithParams(any))
          .thenThrow(Exception('First init fails'));

      final GoogleSignIn googleSignIn = GoogleSignIn();

      expect(googleSignIn.signIn(), throwsA(isInstanceOf<Exception>()));

      when(mockPlatform.initWithParams(any))
          .thenAnswer((Invocation _) async {});
      expect(await googleSignIn.signIn(), isNotNull);
    });

    test('created with standard factory uses correct options', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn.standard();

      await googleSignIn.signInSilently();
      expect(googleSignIn.currentUser, isNotNull);
      _verifyInit(mockPlatform);
      verify(mockPlatform.signInSilently());
    });

    test('created with defaultGamesSignIn factory uses correct options',
        () async {
      final GoogleSignIn googleSignIn = GoogleSignIn.games();

      await googleSignIn.signInSilently();
      expect(googleSignIn.currentUser, isNotNull);
      _verifyInit(mockPlatform, signInOption: SignInOption.games);
      verify(mockPlatform.signInSilently());
    });

    test('authentication', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      when(mockPlatform.getTokens(
              email: anyNamed('email'),
              shouldRecoverAuth: anyNamed('shouldRecoverAuth')))
          .thenAnswer((Invocation _) async => GoogleSignInTokenData(
                idToken: '123',
                accessToken: '456',
                serverAuthCode: '789',
              ));

      await googleSignIn.signIn();

      final GoogleSignInAccount user = googleSignIn.currentUser!;
      final GoogleSignInAuthentication auth = await user.authentication;

      expect(auth.accessToken, '456');
      expect(auth.idToken, '123');
      verify(mockPlatform.getTokens(
          email: 'john.doe@gmail.com', shouldRecoverAuth: true));
    });

    test('requestScopes returns true once new scope is granted', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      when(mockPlatform.requestScopes(any))
          .thenAnswer((Invocation _) async => true);

      await googleSignIn.signIn();
      final bool result =
          await googleSignIn.requestScopes(<String>['testScope']);

      expect(result, isTrue);
      _verifyInit(mockPlatform);
      verify(mockPlatform.signIn());
      verify(mockPlatform.requestScopes(<String>['testScope']));
    });

    test('canAccessScopes forwards calls to platform', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      when(mockPlatform.canAccessScopes(
        any,
        accessToken: anyNamed('accessToken'),
      )).thenAnswer((Invocation _) async => true);

      await googleSignIn.signIn();
      final bool result = await googleSignIn.canAccessScopes(
        <String>['testScope'],
        accessToken: 'xyz',
      );

      expect(result, isTrue);
      _verifyInit(mockPlatform);
      verify(mockPlatform.canAccessScopes(
        <String>['testScope'],
        accessToken: 'xyz',
      ));
    });

    test('userDataEvents are forwarded through the onUserChanged stream',
        () async {
      final StreamController<GoogleSignInUserData?> userDataController =
          StreamController<GoogleSignInUserData?>();

      when(mockPlatform.userDataEvents)
          .thenAnswer((Invocation _) => userDataController.stream);
      when(mockPlatform.isSignedIn()).thenAnswer((Invocation _) async => false);

      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.isSignedIn();

      // This is needed to ensure `_ensureInitialized` is called!
      final Future<List<GoogleSignInAccount?>> nextTwoEvents =
          googleSignIn.onCurrentUserChanged.take(2).toList();

      // Dispatch two events
      userDataController.add(kDefaultUser);
      userDataController.add(null);

      final List<GoogleSignInAccount?> events = await nextTwoEvents;

      expect(events.first, isNotNull);

      final GoogleSignInAccount user = events.first!;

      expect(user.displayName, equals(kDefaultUser.displayName));
      expect(user.email, equals(kDefaultUser.email));
      expect(user.id, equals(kDefaultUser.id));
      expect(user.photoUrl, equals(kDefaultUser.photoUrl));
      expect(user.serverAuthCode, equals(kDefaultUser.serverAuthCode));

      // The second event was a null...
      expect(events.last, isNull);
    });

    test('user starts as null', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      expect(googleSignIn.currentUser, isNull);
    });

    test('can sign in and sign out', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signIn();

      final GoogleSignInAccount user = googleSignIn.currentUser!;

      expect(user.displayName, equals(kDefaultUser.displayName));
      expect(user.email, equals(kDefaultUser.email));
      expect(user.id, equals(kDefaultUser.id));
      expect(user.photoUrl, equals(kDefaultUser.photoUrl));
      expect(user.serverAuthCode, equals(kDefaultUser.serverAuthCode));

      await googleSignIn.disconnect();
      expect(googleSignIn.currentUser, isNull);
    });

    test('disconnect when signout already succeeds', () async {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect();
      expect(googleSignIn.currentUser, isNull);
    });
  });
}

void _verifyInit(
  MockGoogleSignInPlatform mockSignIn, {
  List<String> scopes = const <String>[],
  SignInOption signInOption = SignInOption.standard,
  String? hostedDomain,
  String? clientId,
  String? serverClientId,
  bool forceCodeForRefreshToken = false,
}) {
  verify(mockSignIn.initWithParams(argThat(
    isA<SignInInitParameters>()
        .having(
          (SignInInitParameters p) => p.scopes,
          'scopes',
          scopes,
        )
        .having(
          (SignInInitParameters p) => p.signInOption,
          'signInOption',
          signInOption,
        )
        .having(
          (SignInInitParameters p) => p.hostedDomain,
          'hostedDomain',
          hostedDomain,
        )
        .having(
          (SignInInitParameters p) => p.clientId,
          'clientId',
          clientId,
        )
        .having(
          (SignInInitParameters p) => p.serverClientId,
          'serverClientId',
          serverClientId,
        )
        .having(
          (SignInInitParameters p) => p.forceCodeForRefreshToken,
          'forceCodeForRefreshToken',
          forceCodeForRefreshToken,
        ),
  )));
}
