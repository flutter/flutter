// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeNameResolutionTest);
    defineReflectiveTests(TypeNameResolutionWithoutNullSafetyTest);
  });
}

@reflectiveTest
class TypeNameResolutionTest extends PubPackageResolutionTest
    with TypeNameResolutionTestCases {
  ImportFindElement get import_a {
    return findElement.importFind('package:test/a.dart');
  }

  test_optIn_fromOptOut_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    assertNamedType(
      findNode.namedType('A a'),
      import_a.class_('A'),
      'A*',
    );
  }

  test_optIn_fromOptOut_class_generic_toBounds() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T extends num> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    assertNamedType(
      findNode.namedType('A a'),
      import_a.class_('A'),
      'A<num*>*',
    );
  }

  test_optIn_fromOptOut_class_generic_toBounds_dynamic() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {}
''');

    assertNamedType(
      findNode.namedType('A a'),
      import_a.class_('A'),
      'A<dynamic>*',
    );
  }

  test_optIn_fromOptOut_class_generic_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A<T> {}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A<int> a) {}
''');

    assertNamedType(
      findNode.namedType('A<int> a'),
      import_a.class_('A'),
      'A<int*>*',
    );
  }

  test_optIn_fromOptOut_functionTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F = int Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    var element = import_a.typeAlias('F');

    var typeName = findNode.namedType('F a');
    assertNamedType(typeName, element, 'int* Function(bool*)*');

    assertTypeAlias(
      typeName.typeOrThrow,
      element: element,
      typeArguments: [],
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_dynamic() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F<T> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    var element = import_a.typeAlias('F');

    var typeName = findNode.namedType('F a');
    assertNamedType(typeName, element, 'dynamic Function(bool*)*');

    assertTypeAlias(
      typeName.typeOrThrow,
      element: element,
      typeArguments: ['dynamic'],
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_toBounds() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F<T extends num> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F a) {}
''');

    var element = import_a.typeAlias('F');

    var typeName = findNode.namedType('F a');
    assertNamedType(typeName, element, 'num* Function(bool*)*');

    assertTypeAlias(
      typeName.typeOrThrow,
      element: element,
      typeArguments: ['num*'],
    );
  }

  test_optIn_fromOptOut_functionTypeAlias_generic_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef F<T> = T Function(bool);
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(F<int> a) {}
''');

    var element = import_a.typeAlias('F');

    var typeName = findNode.namedType('F<int> a');
    assertNamedType(typeName, element, 'int* Function(bool*)*');

    assertTypeAlias(
      typeName.typeOrThrow,
      element: element,
      typeArguments: ['int*'],
    );
  }

  test_optOut_fromOptIn_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertNamedType(
      findNode.namedType('A a'),
      import_a.class_('A'),
      'A',
    );
  }

  test_optOut_fromOptIn_class_generic_toBounds() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A<T extends num> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertNamedType(
      findNode.namedType('A a'),
      import_a.class_('A'),
      'A<num*>',
    );
  }

  test_optOut_fromOptIn_class_generic_toBounds_dynamic() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A<T> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertNamedType(
      findNode.namedType('A a'),
      import_a.class_('A'),
      'A<dynamic>',
    );
  }

  test_optOut_fromOptIn_class_generic_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
class A<T> {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(A<int> a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertNamedType(
      findNode.namedType('A<int> a'),
      import_a.class_('A'),
      'A<int>',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
typedef F = int Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertNamedType(
      findNode.namedType('F a'),
      import_a.typeAlias('F'),
      'int* Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_toBounds() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
typedef F<T extends num> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertNamedType(
      findNode.namedType('F a'),
      import_a.typeAlias('F'),
      'num* Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_toBounds_dynamic() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
typedef F<T> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertNamedType(
      findNode.namedType('F a'),
      import_a.typeAlias('F'),
      'dynamic Function()',
    );
  }

  test_optOut_fromOptIn_functionTypeAlias_generic_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
typedef F<T> = T Function();
''');

    await assertErrorsInCode(r'''
import 'a.dart';

f(F<int> a) {}
''', [
      error(HintCode.IMPORT_OF_LEGACY_LIBRARY_INTO_NULL_SAFE, 7, 8),
    ]);

    assertNamedType(
      findNode.namedType('F<int> a'),
      import_a.typeAlias('F'),
      'int* Function()',
    );
  }

  test_typeAlias_asInstanceCreation_explicitNew_typeArguments_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X<T> = A<T>;

void f() {
  new X<int>();
}
''');

    assertNamedType(
      findNode.namedType('X<int>()'),
      findElement.typeAlias('X'),
      'A<int>',
    );
  }

  test_typeAlias_asInstanceCreation_implicitNew_toBounds_noTypeParameters_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X = A<int>;

void f() {
  X();
}
''');

    assertNamedType(
      findNode.namedType('X()'),
      findElement.typeAlias('X'),
      'A<int>',
    );
  }

  test_typeAlias_asInstanceCreation_implicitNew_typeArguments_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

typedef X<T> = A<T>;

void f() {
  X<int>();
}
''');

    assertNamedType(
      findNode.namedType('X<int>()'),
      findElement.typeAlias('X'),
      'A<int>',
    );
  }

  test_typeAlias_asParameterType_interfaceType_none() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = Map<int, T>;
void f(X<String> a, X<String?> b) {}
''');

    assertNamedType(
      findNode.namedType('X<String>'),
      findElement.typeAlias('X'),
      'Map<int, String>',
    );

    assertNamedType(
      findNode.namedType('X<String?>'),
      findElement.typeAlias('X'),
      'Map<int, String?>',
    );
  }

  test_typeAlias_asParameterType_interfaceType_none_inLegacy() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef X<T> = Map<int, T>;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X<String> a) {}
''');

    assertNamedType(
      findNode.namedType('X<String>'),
      findElement.importFind('package:test/a.dart').typeAlias('X'),
      'Map<int*, String*>*',
    );
  }

  test_typeAlias_asParameterType_interfaceType_question() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = List<T?>;
void f(X<int> a, X<int?> b) {}
''');

    assertNamedType(
      findNode.namedType('X<int>'),
      findElement.typeAlias('X'),
      'List<int?>',
    );

    assertNamedType(
      findNode.namedType('X<int?>'),
      findElement.typeAlias('X'),
      'List<int?>',
    );
  }

  test_typeAlias_asParameterType_interfaceType_question_inLegacy() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef X<T> = List<T?>;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X<int> a) {}
''');

    assertNamedType(
      findNode.namedType('X<int>'),
      findElement.importFind('package:test/a.dart').typeAlias('X'),
      'List<int*>*',
    );
  }

  test_typeAlias_asParameterType_Never_none() async {
    await assertNoErrorsInCode(r'''
typedef X = Never;
void f(X a, X? b) {}
''');

    assertNamedType(
      findNode.namedType('X a'),
      findElement.typeAlias('X'),
      'Never',
    );

    assertNamedType(
      findNode.namedType('X? b'),
      findElement.typeAlias('X'),
      'Never?',
    );
  }

  test_typeAlias_asParameterType_Never_none_inLegacy() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
typedef X = Never;
''');
    await assertNoErrorsInCode(r'''
// @dart = 2.9
import 'a.dart';
void f(X a) {}
''');

    assertNamedType(
      findNode.namedType('X a'),
      findElement.importFind('package:test/a.dart').typeAlias('X'),
      'Null*',
    );
  }

  test_typeAlias_asParameterType_Never_question() async {
    await assertNoErrorsInCode(r'''
typedef X = Never?;
void f(X a, X? b) {}
''');

    assertNamedType(
      findNode.namedType('X a'),
      findElement.typeAlias('X'),
      'Never?',
    );

    assertNamedType(
      findNode.namedType('X? b'),
      findElement.typeAlias('X'),
      'Never?',
    );
  }

  test_typeAlias_asParameterType_question() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = T?;
void f(X<int> a) {}
''');

    assertNamedType(
      findNode.namedType('X<int>'),
      findElement.typeAlias('X'),
      'int?',
    );
  }

  test_typeAlias_asReturnType_interfaceType() async {
    await assertNoErrorsInCode(r'''
typedef X<T> = Map<int, T>;
X<String> f() => {};
''');

    assertNamedType(
      findNode.namedType('X<String>'),
      findElement.typeAlias('X'),
      'Map<int, String>',
    );
  }

  test_typeAlias_asReturnType_void() async {
    await assertNoErrorsInCode(r'''
typedef Nothing = void;
Nothing f() {}
''');

    assertNamedType(
      findNode.namedType('Nothing f()'),
      findElement.typeAlias('Nothing'),
      'void',
    );
  }
}

mixin TypeNameResolutionTestCases on PubPackageResolutionTest {
  test_class() async {
    await assertNoErrorsInCode(r'''
class A {}

f(A a) {}
''');

    assertNamedType(
      findNode.namedType('A a'),
      findElement.class_('A'),
      typeStr('A', 'A*'),
    );
  }

  test_class_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {}

f(A a) {}
''');

    assertNamedType(
      findNode.namedType('A a'),
      findElement.class_('A'),
      typeStr('A<num>', 'A<num*>*'),
    );
  }

  test_class_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

f(A a) {}
''');

    assertNamedType(
      findNode.namedType('A a'),
      findElement.class_('A'),
      typeStr('A<dynamic>', 'A<dynamic>*'),
    );
  }

  test_class_generic_typeArguments() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

f(A<int> a) {}
''');

    assertNamedType(
      findNode.namedType('A<int> a'),
      findElement.class_('A'),
      typeStr('A<int>', 'A<int*>*'),
    );
  }

  test_dynamic_explicitCore() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';

dynamic a;
''');

    assertNamedType(
      findNode.namedType('dynamic a;'),
      dynamicElement,
      'dynamic',
    );
  }

  test_dynamic_explicitCore_withPrefix() async {
    await assertNoErrorsInCode(r'''
import 'dart:core' as mycore;

mycore.dynamic a;
''');

    assertNamedType(
      findNode.namedType('mycore.dynamic a;'),
      dynamicElement,
      'dynamic',
      expectedPrefix: findElement.import('dart:core').prefix,
    );
  }

  test_dynamic_explicitCore_withPrefix_referenceWithout() async {
    await assertErrorsInCode(r'''
import 'dart:core' as mycore;

dynamic a;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 31, 7),
    ]);

    assertNamedType(
      findNode.namedType('dynamic a;'),
      null,
      'dynamic',
    );
  }

  test_dynamic_implicitCore() async {
    await assertNoErrorsInCode(r'''
dynamic a;
''');

    assertNamedType(
      findNode.namedType('dynamic a;'),
      dynamicElement,
      'dynamic',
    );
  }

  test_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef F = int Function();

f(F a) {}
''');

    assertNamedType(
      findNode.namedType('F a'),
      findElement.typeAlias('F'),
      typeStr('int Function()', 'int* Function()*'),
    );
  }

  test_functionTypeAlias_generic_toBounds() async {
    await assertNoErrorsInCode(r'''
typedef F<T extends num> = T Function();

f(F a) {}
''');

    assertNamedType(
      findNode.namedType('F a'),
      findElement.typeAlias('F'),
      typeStr('num Function()', 'num* Function()*'),
    );
  }

  test_functionTypeAlias_generic_toBounds_dynamic() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = T Function();

f(F a) {}
''');

    assertNamedType(
      findNode.namedType('F a'),
      findElement.typeAlias('F'),
      typeStr('dynamic Function()', 'dynamic Function()*'),
    );
  }

  test_functionTypeAlias_generic_typeArguments() async {
    await assertNoErrorsInCode(r'''
typedef F<T> = T Function();

f(F<int> a) {}
''');

    assertNamedType(
      findNode.namedType('F<int> a'),
      findElement.typeAlias('F'),
      typeStr('int Function()', 'int* Function()*'),
    );
  }

  test_instanceCreation_explicitNew_prefix_unresolvedClass() async {
    await assertErrorsInCode(r'''
import 'dart:math' as math;

main() {
  new math.A();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 49, 1),
    ]);

    assertNamedType(
      findNode.namedType('A();'),
      null,
      'dynamic',
      expectedPrefix: findElement.prefix('math'),
    );
  }

  test_instanceCreation_explicitNew_resolvedClass() async {
    await assertNoErrorsInCode(r'''
class A {}

main() {
  new A();
}
''');

    assertNamedType(
      findNode.namedType('A();'),
      findElement.class_('A'),
      typeStr('A', 'A*'),
    );
  }

  test_instanceCreation_explicitNew_unresolvedClass() async {
    await assertErrorsInCode(r'''
main() {
  new A();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 15, 1),
    ]);

    assertNamedType(
      findNode.namedType('A();'),
      null,
      'dynamic',
    );
  }

  test_invalid_prefixedIdentifier_instanceCreation() async {
    await assertErrorsInCode(r'''
void f() {
  new int.double.other();
}
''', [
      error(CompileTimeErrorCode.NEW_WITH_NON_TYPE, 17, 10),
    ]);

    assertNamedType(
      findNode.namedType('int.double'),
      null,
      'dynamic',
      expectedPrefix: intElement,
    );
  }

  test_invalid_prefixedIdentifier_literal() async {
    await assertErrorsInCode(r'''
void f() {
  0 as int.double;
}
''', [
      error(CompileTimeErrorCode.NOT_A_TYPE, 18, 10),
    ]);

    assertNamedType(
      findNode.namedType('int.double'),
      null,
      'dynamic',
      expectedPrefix: intElement,
    );
  }

  test_never() async {
    await assertNoErrorsInCode(r'''
f(Never a) {}
''');

    assertNamedType(
      findNode.namedType('Never a'),
      neverElement,
      typeStr('Never', 'Null*'),
    );
  }
}

@reflectiveTest
class TypeNameResolutionWithoutNullSafetyTest extends PubPackageResolutionTest
    with TypeNameResolutionTestCases, WithoutNullSafetyMixin {
  @override
  bool get typeToStringWithNullability => true;
}
