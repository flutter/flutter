// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForOverridingMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForOverridingMemberTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_differentLibrary_invalid() async {
    newFile('$testPackageLibPath/a.dart', content: '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');
    await assertErrorsInCode('''
import 'a.dart';

class Child extends Parent {
  Child() {
    foo();
  }
}
''', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER, 63, 3),
    ]);
  }

  test_differentLibrary_valid_onlyOverride() async {
    newFile('$testPackageLibPath/a.dart', content: '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class Child extends Parent {
  @override
  void foo() {}
}
''');
  }

  test_differentLibrary_valid_overrideAndUse() async {
    newFile('$testPackageLibPath/a.dart', content: '''
import 'package:meta/meta.dart';

class Parent {
  @visibleForOverriding
  void foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class Child extends Parent {
  @override
  void foo() {}

  void bar() {
    foo();
  }
}
''');
  }

  test_sameLibrary() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
class Parent {
  @visibleForOverriding
  void foo() {}
}

class Child extends Parent {
  Child() {
    foo();
  }
}
''');
  }
}
