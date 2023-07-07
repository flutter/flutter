// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_platform_interface/src/utils.dart';

const Map<String, String> kUserData = <String, String>{
  'email': 'john.doe@gmail.com',
  'id': '8162538176523816253123',
  'photoUrl': 'https://lh5.googleusercontent.com/photo.jpg',
  'displayName': 'John Doe',
  'idToken': '123',
  'serverAuthCode': '789',
};

const Map<dynamic, dynamic> kTokenData = <String, dynamic>{
  'idToken': '123',
  'accessToken': '456',
  'serverAuthCode': '789',
};

const Map<String, dynamic> kDefaultResponses = <String, dynamic>{
  'init': null,
  'signInSilently': kUserData,
  'signIn': kUserData,
  'signOut': null,
  'disconnect': null,
  'isSignedIn': true,
  'getTokens': kTokenData,
  'requestScopes': true,
};

final GoogleSignInUserData? kUser = getUserDataFromMap(kUserData);
final GoogleSignInTokenData kToken =
    getTokenDataFromMap(kTokenData as Map<String, dynamic>);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$MethodChannelGoogleSignIn', () {
    final MethodChannelGoogleSignIn googleSignIn = MethodChannelGoogleSignIn();
    final MethodChannel channel = googleSignIn.channel;

    final List<MethodCall> log = <MethodCall>[];
    late Map<String, dynamic>
        responses; // Some tests mutate some kDefaultResponses

    setUp(() {
      responses = Map<String, dynamic>.from(kDefaultResponses);
      _ambiguate(TestDefaultBinaryMessengerBinding.instance)!
          .defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) {
        log.add(methodCall);
        final dynamic response = responses[methodCall.method];
        if (response != null && response is Exception) {
          return Future<dynamic>.error('$response');
        }
        return Future<dynamic>.value(response);
      });
      log.clear();
    });

    test('signInSilently transforms platform data to GoogleSignInUserData',
        () async {
      final dynamic response = await googleSignIn.signInSilently();
      expect(response, kUser);
    });
    test('signInSilently Exceptions -> throws', () async {
      responses['signInSilently'] = Exception('Not a user');
      expect(googleSignIn.signInSilently(),
          throwsA(isInstanceOf<PlatformException>()));
    });

    test('signIn transforms platform data to GoogleSignInUserData', () async {
      final dynamic response = await googleSignIn.signIn();
      expect(response, kUser);
    });
    test('signIn Exceptions -> throws', () async {
      responses['signIn'] = Exception('Not a user');
      expect(googleSignIn.signIn(), throwsA(isInstanceOf<PlatformException>()));
    });

    test('getTokens transforms platform data to GoogleSignInTokenData',
        () async {
      final dynamic response = await googleSignIn.getTokens(
          email: 'example@example.com', shouldRecoverAuth: false);
      expect(response, kToken);
      expect(
          log[0],
          isMethodCall('getTokens', arguments: <String, dynamic>{
            'email': 'example@example.com',
            'shouldRecoverAuth': false,
          }));
    });

    test('Other functions pass through arguments to the channel', () async {
      final Map<void Function(), Matcher> tests = <void Function(), Matcher>{
        () {
          googleSignIn.init(
              hostedDomain: 'example.com',
              scopes: <String>['two', 'scopes'],
              signInOption: SignInOption.games,
              clientId: 'fakeClientId');
        }: isMethodCall('init', arguments: <String, dynamic>{
          'hostedDomain': 'example.com',
          'scopes': <String>['two', 'scopes'],
          'signInOption': 'SignInOption.games',
          'clientId': 'fakeClientId',
          'serverClientId': null,
          'forceCodeForRefreshToken': false,
        }),
        () {
          googleSignIn.getTokens(
              email: 'example@example.com', shouldRecoverAuth: false);
        }: isMethodCall('getTokens', arguments: <String, dynamic>{
          'email': 'example@example.com',
          'shouldRecoverAuth': false,
        }),
        () {
          googleSignIn.clearAuthCache(token: 'abc');
        }: isMethodCall('clearAuthCache', arguments: <String, dynamic>{
          'token': 'abc',
        }),
        () {
          googleSignIn.requestScopes(<String>['newScope', 'anotherScope']);
        }: isMethodCall('requestScopes', arguments: <String, dynamic>{
          'scopes': <String>['newScope', 'anotherScope'],
        }),
        googleSignIn.signOut: isMethodCall('signOut', arguments: null),
        googleSignIn.disconnect: isMethodCall('disconnect', arguments: null),
        googleSignIn.isSignedIn: isMethodCall('isSignedIn', arguments: null),
      };

      for (final void Function() f in tests.keys) {
        f();
      }

      expect(log, tests.values);
    });

    test('canAccessScopes is unimplemented', () async {
      expect(() async {
        await googleSignIn
            .canAccessScopes(<String>['someScope'], accessToken: 'token');
      }, throwsUnimplementedError);
    });

    test('userDataEvents returns null', () async {
      expect(googleSignIn.userDataEvents, isNull);
    });

    test('initWithParams passes through arguments to the channel', () async {
      await googleSignIn.initWithParams(const SignInInitParameters(
          hostedDomain: 'example.com',
          scopes: <String>['two', 'scopes'],
          signInOption: SignInOption.games,
          clientId: 'fakeClientId',
          serverClientId: 'fakeServerClientId',
          forceCodeForRefreshToken: true));
      expect(log, <Matcher>[
        isMethodCall('init', arguments: <String, dynamic>{
          'hostedDomain': 'example.com',
          'scopes': <String>['two', 'scopes'],
          'signInOption': 'SignInOption.games',
          'clientId': 'fakeClientId',
          'serverClientId': 'fakeServerClientId',
          'forceCodeForRefreshToken': true,
        }),
      ]);
    });
  });
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
T? _ambiguate<T>(T? value) => value;
