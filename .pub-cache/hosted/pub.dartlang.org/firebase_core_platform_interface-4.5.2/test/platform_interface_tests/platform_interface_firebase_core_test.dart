// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$FirebasePlatform', () {
    // should allow read of default app from native
    test('$MethodChannelFirebase is the default instance', () {
      expect(FirebasePlatform.instance, isA<MethodChannelFirebase>());
    });

    test('Can be extended', () {
      FirebasePlatform.instance = ExtendsFirebasePlatform();
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        FirebasePlatform.instance = ImplementsFirebasePlatform();
        // In versions of `package:plugin_platform_interface` prior to fixing
        // https://github.com/flutter/flutter/issues/109339, an attempt to
        // implement a platform interface using `implements` would sometimes
        // throw a `NoSuchMethodError` and other times throw an
        // `AssertionError`.  After the issue is fixed, an `AssertionError` will
        // always be thrown.  For the purpose of this test, we don't really care
        // what exception is thrown, so just allow any exception.
      }, throwsA(anything));
    });

    test('Can be mocked with `implements`', () {
      final FirebaseCoreMockPlatform mock = FirebaseCoreMockPlatform();
      FirebasePlatform.instance = mock;
    });
  });
}

class ImplementsFirebasePlatform implements FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FakeFirebaseAppPlatform();
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return FakeFirebaseAppPlatform();
  }

  @override
  List<FirebaseAppPlatform> get apps => [];
}

// ignore: avoid_implementing_value_types
class FakeFirebaseAppPlatform extends Fake implements FirebaseAppPlatform {}

class ExtendsFirebasePlatform extends FirebasePlatform {}

class FirebaseCoreMockPlatform extends Mock
    with
        // ignore: prefer_mixin, plugin_platform_interface needs to migrate to use `mixin`
        MockPlatformInterfaceMixin
    implements
        FirebasePlatform {}
