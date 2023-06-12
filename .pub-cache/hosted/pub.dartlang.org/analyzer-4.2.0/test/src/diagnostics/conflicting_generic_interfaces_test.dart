// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingGenericInterfacesTest);
  });
}

@reflectiveTest
class ConflictingGenericInterfacesTest extends PubPackageResolutionTest {
  test_class_extends_implements() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A implements B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 81, 1),
    ]);
  }

  test_class_extends_implements_never() async {
    await assertNoErrorsInCode('''
class I<T> {}
class A implements I<Never> {}
class B implements I<Never> {}
class C extends A implements B {}
''');
  }

  test_class_extends_implements_nullability() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<int?> {}
class C extends A implements B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 79, 1),
    ]);
  }

  test_class_extends_implements_optOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
class I<T> {}
class A implements I<int> {}
class B implements I<int?> {}
''');
    await assertNoErrorsInCode('''
// @dart = 2.5
import 'a.dart';

class C extends A implements B {}
''');
  }

  test_class_extends_optIn_implements_optOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}

class B extends A<int> {}
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.5
import 'a.dart';

class C extends B implements A<int> {}
''');
  }

  test_class_extends_with() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
class C extends A with B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 81, 1),
    ]);
  }

  test_class_mixed_viaLegacy() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}

class Bi implements A<int> {}

class Biq implements A<int?> {}
''');

    // Both `Bi` and `Biq` implement `A<int*>` in legacy, so identical.
    newFile('$testPackageLibPath/b.dart', r'''
// @dart = 2.7
import 'a.dart';

class C extends Bi implements Biq {}
''');

    await assertErrorsInCode(r'''
import 'b.dart';

abstract class D implements C {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);
  }

  test_class_topMerge() async {
    await assertNoErrorsInCode('''
import 'dart:async';

class A<T> {}

class B extends A<FutureOr<Object>> {}

class C extends B implements A<Object> {}
''');
  }

  test_class_topMerge_optIn_optOut() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
// @dart = 2.5
import 'a.dart';

class B extends A<int> {}
''');

    await assertErrorsInCode('''
import 'a.dart';
import 'b.dart';

class C extends B implements A<int> {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 24, 8),
    ]);
  }

  test_classTypeAlias_extends_nonFunctionTypedef_with() async {
    await assertErrorsInCode('''
class I<T> {}
typedef A = I<int>;
mixin M implements I<String> {}
class C = A with M;
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 72, 1),
    ]);
  }

  test_classTypeAlias_extends_nonFunctionTypedef_with_ok() async {
    await assertNoErrorsInCode('''
class I<T> {}
typedef A = I<String>;
mixin M implements I<String> {}
class C = A with M;
''');
  }

  test_classTypeAlias_extends_with() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
mixin M implements I<String> {}
class C = A with M;
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 81, 1),
    ]);
  }

  test_enum_implements() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
enum E implements A, B {
  v
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 80, 1),
    ]);
  }

  test_enum_with() async {
    await assertErrorsInCode('''
class I<T> {}
mixin M1 implements I<int> {}
mixin M2 implements I<String> {}
enum E with M1, M2 {
  v
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 82, 1),
    ]);
  }

  test_mixin_on_implements() async {
    await assertErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<String> {}
mixin M on A implements B {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 81, 1),
    ]);
  }

  test_noConflict() async {
    await assertNoErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<int> {}
class C extends A implements B {}
''');
  }
}
