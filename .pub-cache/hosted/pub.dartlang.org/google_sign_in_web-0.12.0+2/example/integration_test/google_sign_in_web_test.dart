// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:google_sign_in_web/src/gis_client.dart';
import 'package:google_sign_in_web/src/people.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;

import 'google_sign_in_web_test.mocks.dart';
import 'src/dom.dart';
import 'src/person.dart';

// Mock GisSdkClient so we can simulate any response from the JS side.
@GenerateMocks(<Type>[], customMocks: <MockSpec<dynamic>>[
  MockSpec<GisSdkClient>(onMissingStub: OnMissingStub.returnDefault),
])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Constructor', () {
    const String expectedClientId = '3xp3c73d_c113n7_1d';

    testWidgets('Loads clientId when set in a meta', (_) async {
      final GoogleSignInPlugin plugin = GoogleSignInPlugin(
        debugOverrideLoader: true,
      );

      expect(plugin.autoDetectedClientId, isNull);

      // Add it to the test page now, and try again
      final DomHtmlMetaElement meta =
          document.createElement('meta') as DomHtmlMetaElement
            ..name = clientIdMetaName
            ..content = expectedClientId;

      document.head.appendChild(meta);

      final GoogleSignInPlugin another = GoogleSignInPlugin(
        debugOverrideLoader: true,
      );

      expect(another.autoDetectedClientId, expectedClientId);

      // cleanup
      meta.remove();
    });
  });

  group('initWithParams', () {
    late GoogleSignInPlugin plugin;
    late MockGisSdkClient mockGis;

    setUp(() {
      mockGis = MockGisSdkClient();
      plugin = GoogleSignInPlugin(
        debugOverrideLoader: true,
        debugOverrideGisSdkClient: mockGis,
      );
    });

    testWidgets('initializes if all is OK', (_) async {
      await plugin.initWithParams(
        const SignInInitParameters(
          clientId: 'some-non-null-client-id',
          scopes: <String>['ok1', 'ok2', 'ok3'],
        ),
      );

      expect(plugin.initialized, completes);
    });

    testWidgets('asserts clientId is not null', (_) async {
      expect(() async {
        await plugin.initWithParams(
          const SignInInitParameters(),
        );
      }, throwsAssertionError);
    });

    testWidgets('asserts serverClientId must be null', (_) async {
      expect(() async {
        await plugin.initWithParams(
          const SignInInitParameters(
            clientId: 'some-non-null-client-id',
            serverClientId: 'unexpected-non-null-client-id',
          ),
        );
      }, throwsAssertionError);
    });

    testWidgets('asserts no scopes have any spaces', (_) async {
      expect(() async {
        await plugin.initWithParams(
          const SignInInitParameters(
            clientId: 'some-non-null-client-id',
            scopes: <String>['ok1', 'ok2', 'not ok', 'ok3'],
          ),
        );
      }, throwsAssertionError);
    });

    testWidgets('must be called for most of the API to work', (_) async {
      expect(() async {
        await plugin.signInSilently();
      }, throwsStateError);

      expect(() async {
        await plugin.signIn();
      }, throwsStateError);

      expect(() async {
        await plugin.getTokens(email: '');
      }, throwsStateError);

      expect(() async {
        await plugin.signOut();
      }, throwsStateError);

      expect(() async {
        await plugin.disconnect();
      }, throwsStateError);

      expect(() async {
        await plugin.isSignedIn();
      }, throwsStateError);

      expect(() async {
        await plugin.clearAuthCache(token: '');
      }, throwsStateError);

      expect(() async {
        await plugin.requestScopes(<String>[]);
      }, throwsStateError);

      expect(() async {
        await plugin.canAccessScopes(<String>[]);
      }, throwsStateError);
    });
  });

  group('(with mocked GIS)', () {
    late GoogleSignInPlugin plugin;
    late MockGisSdkClient mockGis;
    const SignInInitParameters options = SignInInitParameters(
      clientId: 'some-non-null-client-id',
      scopes: <String>['ok1', 'ok2', 'ok3'],
    );

    setUp(() {
      mockGis = MockGisSdkClient();
      plugin = GoogleSignInPlugin(
        debugOverrideLoader: true,
        debugOverrideGisSdkClient: mockGis,
      );
    });

    group('signInSilently', () {
      setUp(() {
        plugin.initWithParams(options);
      });

      testWidgets('returns the GIS response', (_) async {
        final GoogleSignInUserData someUser = extractUserData(person)!;

        mockito
            .when(mockGis.signInSilently())
            .thenAnswer((_) => Future<GoogleSignInUserData?>.value(someUser));

        expect(await plugin.signInSilently(), someUser);

        mockito
            .when(mockGis.signInSilently())
            .thenAnswer((_) => Future<GoogleSignInUserData?>.value());

        expect(await plugin.signInSilently(), isNull);
      });
    });

    group('signIn', () {
      setUp(() {
        plugin.initWithParams(options);
      });

      testWidgets('returns the signed-in user', (_) async {
        final GoogleSignInUserData someUser = extractUserData(person)!;

        mockito
            .when(mockGis.signIn())
            .thenAnswer((_) => Future<GoogleSignInUserData>.value(someUser));

        expect(await plugin.signIn(), someUser);
      });

      testWidgets('returns null if no user is signed in', (_) async {
        mockito
            .when(mockGis.signIn())
            .thenAnswer((_) => Future<GoogleSignInUserData?>.value());

        expect(await plugin.signIn(), isNull);
      });

      testWidgets('converts inner errors to PlatformException', (_) async {
        mockito.when(mockGis.signIn()).thenThrow('popup_closed');

        try {
          await plugin.signIn();
          fail('signIn should have thrown an exception');
        } catch (exception) {
          expect(exception, isA<PlatformException>());
          expect((exception as PlatformException).code, 'popup_closed');
        }
      });
    });

    group('canAccessScopes', () {
      const String someAccessToken = '50m3_4cc35_70k3n';
      const List<String> scopes = <String>['scope1', 'scope2'];

      setUp(() {
        plugin.initWithParams(options);
      });

      testWidgets('passes-through call to gis client', (_) async {
        mockito
            .when(
              mockGis.canAccessScopes(mockito.captureAny, mockito.captureAny),
            )
            .thenAnswer((_) => Future<bool>.value(true));

        final bool canAccess =
            await plugin.canAccessScopes(scopes, accessToken: someAccessToken);

        final List<Object?> arguments = mockito
            .verify(
              mockGis.canAccessScopes(mockito.captureAny, mockito.captureAny),
            )
            .captured;

        expect(canAccess, isTrue);

        expect(arguments.first, scopes);
        expect(arguments.elementAt(1), someAccessToken);
      });
    });
  });

  group('userDataEvents', () {
    final StreamController<GoogleSignInUserData?> controller =
        StreamController<GoogleSignInUserData?>.broadcast();
    late GoogleSignInPlugin plugin;

    setUp(() {
      plugin = GoogleSignInPlugin(
        debugOverrideLoader: true,
        debugOverrideUserDataController: controller,
      );
    });

    testWidgets('accepts async user data events from GIS.', (_) async {
      final Future<GoogleSignInUserData?> data = plugin.userDataEvents!.first;

      final GoogleSignInUserData expected = extractUserData(person)!;
      controller.add(expected);

      expect(await data, expected,
          reason: 'Sign-in events should be propagated');

      final Future<GoogleSignInUserData?> more = plugin.userDataEvents!.first;
      controller.add(null);

      expect(await more, isNull,
          reason: 'Sign-out events can also be propagated');
    });
  });
}
