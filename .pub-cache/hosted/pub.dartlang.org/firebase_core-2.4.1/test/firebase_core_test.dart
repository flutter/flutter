// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$FirebaseApp', () {
    final mock = MockFirebaseCore();

    const FirebaseOptions testOptions = FirebaseOptions(
      apiKey: 'apiKey',
      appId: 'appId',
      messagingSenderId: 'messagingSenderId',
      projectId: 'projectId',
    );

    String testAppName = 'testApp';

    setUp(() async {
      clearInteractions(mock);
      Firebase.delegatePackingProperty = mock;

      final FirebaseAppPlatform platformApp =
          FirebaseAppPlatform(testAppName, testOptions);

      when(mock.apps).thenReturn([platformApp]);
      when(mock.app(testAppName)).thenReturn(platformApp);
      when(mock.initializeApp(name: testAppName, options: testOptions))
          .thenAnswer((_) {
        return Future.value(platformApp);
      });
    });

    test('.apps', () {
      List<FirebaseApp> apps = Firebase.apps;
      verify(mock.apps);
      expect(apps[0], Firebase.app(testAppName));
    });

    test('.app()', () {
      FirebaseApp app = Firebase.app(testAppName);
      verify(mock.app(testAppName));

      expect(app.name, testAppName);
      expect(app.options, testOptions);
    });

    test('.initializeApp()', () async {
      FirebaseApp initializedApp =
          await Firebase.initializeApp(name: testAppName, options: testOptions);
      FirebaseApp app = Firebase.app(testAppName);

      expect(initializedApp, app);
      verifyInOrder([
        mock.initializeApp(name: testAppName, options: testOptions),
        mock.app(testAppName),
      ]);
    });
  });
}

class MockFirebaseCore extends Mock
    with
        // ignore: prefer_mixin, plugin_platform_interface needs to migrate to use `mixin`
        MockPlatformInterfaceMixin
    implements
        FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return super.noSuchMethod(
      Invocation.method(#app, [name]),
      returnValue: FakeFirebaseAppPlatform(),
      returnValueForMissingStub: FakeFirebaseAppPlatform(),
    );
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #initializeApp,
        const [],
        {
          #name: name,
          #options: options,
        },
      ),
      returnValue: Future.value(FakeFirebaseAppPlatform()),
      returnValueForMissingStub: Future.value(FakeFirebaseAppPlatform()),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps {
    return super.noSuchMethod(
      Invocation.getter(#apps),
      returnValue: <FirebaseAppPlatform>[],
      returnValueForMissingStub: <FirebaseAppPlatform>[],
    );
  }
}

// ignore: avoid_implementing_value_types
class FakeFirebaseAppPlatform extends Fake implements FirebaseAppPlatform {}
