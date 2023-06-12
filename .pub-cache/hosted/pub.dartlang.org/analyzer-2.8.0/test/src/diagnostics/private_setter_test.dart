// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateSetterTest);
  });
}

@reflectiveTest
class PrivateSetterTest extends PubPackageResolutionTest {
  test_typeLiteral_privateField_differentLibrary() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static int _foo = 0;
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

main() {
  A._foo = 0;
}
''', [
      error(CompileTimeErrorCode.PRIVATE_SETTER, 31, 4),
    ]);

    var aImport = findElement.importFind('package:test/a.dart');

    assertAssignment(
      findNode.assignment('_foo ='),
      readElement: null,
      readType: null,
      writeElement: aImport.setter('_foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    if (hasAssignmentLeftResolution) {
      assertElement(
        findNode.simple('_foo = 0'),
        aImport.setter('_foo'),
      );
    }
  }

  test_typeLiteral_privateField_sameLibrary() async {
    await assertNoErrorsInCode(r'''
class A {
  // ignore:unused_field
  static int _foo = 0;
}

main() {
  A._foo = 0;
}
''');
  }

  test_typeLiteral_privateSetter_differentLibrary_hasGetter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static set _foo(int _) {}

  static int get _foo => 0;
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

main() {
  A._foo = 0;
}
''', [
      error(CompileTimeErrorCode.PRIVATE_SETTER, 31, 4),
    ]);

    var aImport = findElement.importFind('package:test/a.dart');

    assertAssignment(
      findNode.assignment('_foo ='),
      readElement: null,
      readType: null,
      writeElement: aImport.setter('_foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    if (hasAssignmentLeftResolution) {
      assertElement(
        findNode.simple('_foo = 0'),
        aImport.setter('_foo'),
      );
    }
  }

  test_typeLiteral_privateSetter_differentLibrary_noGetter() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static set _foo(int _) {}
}
''');
    await assertErrorsInCode(r'''
import 'a.dart';

main() {
  A._foo = 0;
}
''', [
      error(CompileTimeErrorCode.PRIVATE_SETTER, 31, 4),
    ]);

    var aImport = findElement.importFind('package:test/a.dart');

    assertAssignment(
      findNode.assignment('_foo ='),
      readElement: null,
      readType: null,
      writeElement: aImport.setter('_foo'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    if (hasAssignmentLeftResolution) {
      assertElement(
        findNode.simple('_foo = 0'),
        aImport.setter('_foo'),
      );
    }
  }

  test_typeLiteral_privateSetter_sameLibrary() async {
    await assertNoErrorsInCode(r'''
class A {
  static set _foo(int _) {}
}

main() {
  A._foo = 0;
}
''');
  }
}
