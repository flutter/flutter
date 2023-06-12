// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(SharedPreferencesStorePlatform, () {
    test('disallows implementing interface', () {
      expect(() {
        SharedPreferencesStorePlatform.instance = IllegalImplementation();
      },
          // In versions of `package:plugin_platform_interface` prior to fixing
          // https://github.com/flutter/flutter/issues/109339, an attempt to
          // implement a platform interface using `implements` would sometimes
          // throw a `NoSuchMethodError` and other times throw an
          // `AssertionError`. After the issue is fixed, an `AssertionError` will
          // always be thrown. For the purpose of this test, we don't really care
          // what exception is thrown, so just allow any exception.
          throwsA(anything));
    });

    test('supports MockPlatformInterfaceMixin', () {
      SharedPreferencesStorePlatform.instance = ModernMockImplementation();
    });

    test('still supports legacy isMock', () {
      SharedPreferencesStorePlatform.instance = LegacyIsMockImplementation();
    });
  });
}

/// An implementation using `implements` that isn't a mock, which isn't allowed.
class IllegalImplementation implements SharedPreferencesStorePlatform {
  // Intentionally declare self as not a mock to trigger the
  // compliance check.
  @override
  bool get isMock => false;

  @override
  Future<bool> clear() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, Object>> getAll() {
    throw UnimplementedError();
  }

  @override
  Future<bool> remove(String key) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    throw UnimplementedError();
  }
}

class LegacyIsMockImplementation implements SharedPreferencesStorePlatform {
  @override
  bool get isMock => true;

  @override
  Future<bool> clear() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, Object>> getAll() {
    throw UnimplementedError();
  }

  @override
  Future<bool> remove(String key) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    throw UnimplementedError();
  }
}

class ModernMockImplementation
    with MockPlatformInterfaceMixin
    implements SharedPreferencesStorePlatform {
  @override
  bool get isMock => false;

  @override
  Future<bool> clear() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, Object>> getAll() {
    throw UnimplementedError();
  }

  @override
  Future<bool> remove(String key) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    throw UnimplementedError();
  }
}
