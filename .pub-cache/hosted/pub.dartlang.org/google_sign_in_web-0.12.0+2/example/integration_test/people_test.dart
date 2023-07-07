// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_identity_services_web/oauth2.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/src/people.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_test;
import 'package:integration_test/integration_test.dart';

import 'src/jsify_as.dart';
import 'src/person.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('requestUserData', () {
    const String expectedAccessToken = '3xp3c73d_4cc355_70k3n';

    final TokenResponse fakeToken = jsifyAs(<String, Object?>{
      'token_type': 'Bearer',
      'access_token': expectedAccessToken,
    });

    testWidgets('happy case', (_) async {
      final Completer<String> accessTokenCompleter = Completer<String>();

      final http.Client mockClient = http_test.MockClient(
        (http.Request request) async {
          accessTokenCompleter.complete(request.headers['Authorization']);

          return http.Response(
            jsonEncode(person),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        },
      );

      final GoogleSignInUserData? user = await requestUserData(
        fakeToken,
        overrideClient: mockClient,
      );

      expect(user, isNotNull);
      expect(user!.email, expectedPersonEmail);
      expect(user.id, expectedPersonId);
      expect(user.displayName, expectedPersonName);
      expect(user.photoUrl, expectedPersonPhoto);
      expect(user.idToken, isNull);
      expect(
        accessTokenCompleter.future,
        completion('Bearer $expectedAccessToken'),
      );
    });

    testWidgets('Unauthorized request - throws exception', (_) async {
      final http.Client mockClient = http_test.MockClient(
        (http.Request request) async {
          return http.Response(
            'Unauthorized',
            403,
          );
        },
      );

      expect(() async {
        await requestUserData(
          fakeToken,
          overrideClient: mockClient,
        );
      }, throwsA(isA<http.ClientException>()));
    });
  });

  group('extractUserData', () {
    testWidgets('happy case', (_) async {
      final GoogleSignInUserData? user = extractUserData(person);

      expect(user, isNotNull);
      expect(user!.email, expectedPersonEmail);
      expect(user.id, expectedPersonId);
      expect(user.displayName, expectedPersonName);
      expect(user.photoUrl, expectedPersonPhoto);
      expect(user.idToken, isNull);
    });

    testWidgets('no name/photo - keeps going', (_) async {
      final Map<String, Object?> personWithoutSomeData =
          mapWithoutKeys(person, <String>{
        'names',
        'photos',
      });

      final GoogleSignInUserData? user = extractUserData(personWithoutSomeData);

      expect(user, isNotNull);
      expect(user!.email, expectedPersonEmail);
      expect(user.id, expectedPersonId);
      expect(user.displayName, isNull);
      expect(user.photoUrl, isNull);
      expect(user.idToken, isNull);
    });

    testWidgets('no userId - throws assertion error', (_) async {
      final Map<String, Object?> personWithoutId =
          mapWithoutKeys(person, <String>{
        'resourceName',
      });

      expect(() {
        extractUserData(personWithoutId);
      }, throwsAssertionError);
    });

    testWidgets('no email - throws assertion error', (_) async {
      final Map<String, Object?> personWithoutEmail =
          mapWithoutKeys(person, <String>{
        'emailAddresses',
      });

      expect(() {
        extractUserData(personWithoutEmail);
      }, throwsAssertionError);
    });
  });
}
