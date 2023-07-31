// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfStructClassInExtendsTest);
    defineReflectiveTests(SubtypeOfStructClassInImplementsTest);
    defineReflectiveTests(SubtypeOfStructClassInWithTest);
  });
}

@reflectiveTest
class SubtypeOfStructClassInExtendsTest extends PubPackageResolutionTest {
  test_extends_struct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Struct {
  external Pointer notEmpty;
}
class C extends S {}
''', [
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS, 91, 1),
    ]);
  }

  test_extends_union() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Union {
  external Pointer notEmpty;
}
class C extends S {}
''', [
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS, 90, 1),
    ]);
  }
}

@reflectiveTest
class SubtypeOfStructClassInImplementsTest extends PubPackageResolutionTest {
  test_implements_abi_specific_int() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
})
class AbiSpecificInteger1 extends AbiSpecificInteger {
  const AbiSpecificInteger1();
}
class AbiSpecificInteger4 implements AbiSpecificInteger1 {
  const AbiSpecificInteger4();
}
''', [
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 204, 19),
    ]);
  }

  test_implements_struct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Struct {}
class C implements S {}
''', [
      error(FfiCode.EMPTY_STRUCT, 25, 1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 64, 1,
          messageContains: ["class 'C'", "implement 'S'"]),
    ]);
  }

  test_implements_struct_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
import 'dart:ffi';
class S extends Struct {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as lib1;
class C implements lib1.S {}
''', [
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 47, 6,
          messageContains: ["class 'C'", "implement 'lib1.S'"]),
    ]);
  }

  test_implements_union() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Union {}
class C implements S {}
''', [
      error(FfiCode.EMPTY_STRUCT, 25, 1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 63, 1),
    ]);
  }
}

@reflectiveTest
class SubtypeOfStructClassInWithTest extends PubPackageResolutionTest {
  test_with_struct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Struct {}
class C with S {}
''', [
      error(FfiCode.EMPTY_STRUCT, 25, 1),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 58, 1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH, 58, 1,
          messageContains: ["class 'C'", "mix in 'S'"]),
    ]);
  }

  test_with_struct_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
import 'dart:ffi';
class S extends Struct {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as lib1;

class C with lib1.S {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 42, 6),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH, 42, 6,
          messageContains: ["class 'C'", "mix in 'lib1.S'"]),
    ]);
  }

  test_with_union() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class S extends Union {}
class C with S {}
''', [
      error(FfiCode.EMPTY_STRUCT, 25, 1),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 57, 1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH, 57, 1),
    ]);
  }
}
