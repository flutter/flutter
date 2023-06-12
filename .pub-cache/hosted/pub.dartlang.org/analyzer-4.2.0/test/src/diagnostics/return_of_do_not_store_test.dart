// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfDoNotStoreInTestsTest);
    defineReflectiveTests(ReturnOfDoNotStoreTest);
  });
}

@reflectiveTest
class ReturnOfDoNotStoreInTestsTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_noHintsInTestDir() async {
    // Code that is in a test dir (the default for PubPackageResolutionTests)
    // should not trigger the hint.
    // (See:https://github.com/dart-lang/sdk/issues/45594)
    await assertNoErrorsInCode(
      '''
import 'package:meta/meta.dart';

@doNotStore
String _v = '';

String f() {
  var v = () => _v;
  return v();
}

String g() {
  return _v;
}
''',
    );
  }
}

@reflectiveTest
class ReturnOfDoNotStoreTest extends PubPackageResolutionTest {
  /// Override the default which is in .../test and should not trigger hints.
  @override
  String get testPackageRootPath => '$workspaceRootPath/test_project';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_returnFromClosureInFunction() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String _v = '';

String f() {
  var v = () => _v;
  return v();
}
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 92, 2),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_returnFromFunction() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String v = '';

String getV() {
  return v;
}

String getV2() => v;

@doNotStore
String getV3() => v;
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 87, 1, messageContains: ['getV']),
      error(HintCode.RETURN_OF_DO_NOT_STORE, 111, 1,
          messageContains: ['getV2']),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_returnFromGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String _v = '';

String get v {
  return _v;
}

String get v2 => _v;

@doNotStore
String get v3 => _v;
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 87, 2, messageContains: ['v']),
      error(HintCode.RETURN_OF_DO_NOT_STORE, 111, 2, messageContains: ['v2']),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_returnFromGetter_binaryExpression() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String? _v = '';

@doNotStore
String? _v2 = '';

String? get v => _v ?? _v2;
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 112, 2, messageContains: ['_v']),
      error(HintCode.RETURN_OF_DO_NOT_STORE, 118, 3, messageContains: ['_v2']),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_returnFromGetter_ternary() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

@doNotStore
String _v = '';

@doNotStore
String _v2 = '';

var b = true;

String get v => b ? _v : _v2;
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 128, 2),
      error(HintCode.RETURN_OF_DO_NOT_STORE, 133, 3),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48476')
  test_returnFromMethod() async {
    await assertErrorsInCode('''
import 'package:meta/meta.dart';

class A {
  @doNotStore
  String _v = '';

  String getV() {
    return _v;
  }

  String getV2() => _v;

  @doNotStore
  String getV3() => _v;
}
''', [
      error(HintCode.RETURN_OF_DO_NOT_STORE, 106, 2, messageContains: ['getV']),
      error(HintCode.RETURN_OF_DO_NOT_STORE, 135, 2,
          messageContains: ['getV2']),
    ]);
  }
}
