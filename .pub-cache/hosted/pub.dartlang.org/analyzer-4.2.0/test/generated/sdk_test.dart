// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartSdkManagerTest);
    defineReflectiveTests(SdkDescriptionTest);
  });
}

@reflectiveTest
class DartSdkManagerTest with ResourceProviderMixin {
  void test_anySdk() {
    DartSdkManager manager = DartSdkManager('/a/b/c');
    expect(manager.anySdk, isNull);

    SdkDescription description = SdkDescription('/c/d');
    DartSdk sdk = _DartSdkMock();
    manager.getSdk(description, () => sdk);

    expect(manager.anySdk, same(sdk));
  }

  void test_getSdk_differentDescriptors() {
    DartSdkManager manager = DartSdkManager('/a/b/c');

    SdkDescription description1 = SdkDescription('/c/d');
    DartSdk sdk1 = _DartSdkMock();
    DartSdk result1 = manager.getSdk(description1, () => sdk1);
    expect(result1, same(sdk1));

    SdkDescription description2 = SdkDescription('/e/f');
    DartSdk sdk2 = _DartSdkMock();
    DartSdk result2 = manager.getSdk(description2, () => sdk2);
    expect(result2, same(sdk2));

    manager.getSdk(description1, _failIfAbsent);
    manager.getSdk(description2, _failIfAbsent);
  }

  void test_getSdk_sameDescriptor() {
    DartSdkManager manager = DartSdkManager('/a/b/c');

    SdkDescription description = SdkDescription('/c/d');
    DartSdk sdk = _DartSdkMock();
    DartSdk result = manager.getSdk(description, () => sdk);
    expect(result, same(sdk));

    manager.getSdk(description, _failIfAbsent);
  }

  DartSdk _failIfAbsent() {
    fail('Use of ifAbsent function');
  }
}

@reflectiveTest
class SdkDescriptionTest {
  void test_equals_differentPaths_nested() {
    SdkDescription left = SdkDescription('/a/b/c');
    SdkDescription right = SdkDescription('/a/b');
    expect(left == right, isFalse);
  }

  void test_equals_differentPaths_unrelated() {
    SdkDescription left = SdkDescription('/a/b/c');
    SdkDescription right = SdkDescription('/d/e');
    expect(left == right, isFalse);
  }

  void test_equals_samePaths_sameOptions_single() {
    String path = '/a/b/c';
    SdkDescription left = SdkDescription(path);
    SdkDescription right = SdkDescription(path);
    expect(left == right, isTrue);
  }
}

class _DartSdkMock implements DartSdk {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
