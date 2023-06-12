// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfInternalMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfInternalMemberTest extends PubPackageResolutionTest {
  String get fooPackageRootPath => '$workspaceRootPath/foo';

  @override
  String get testPackageRootPath => '/home/my';

  @override
  void setUp() {
    super.setUp();
    writeTestPackagePubspecYamlFile(PubspecYamlFileConfig());
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(
          name: 'foo',
          rootPath: fooPackageRootPath,
          languageVersion: '2.9',
        ),
      languageVersion: '2.9',
      meta: true,
    );
  }

  test_insidePackage() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');
    newFile('$fooPackageRootPath/lib/a.dart', '''
import 'src/a.dart';

A a = A();
''');
    await resolveFile2('$fooPackageRootPath/lib/a.dart');

    assertNoErrorsInResult();
  }

  test_outsidePackage_class() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
class A {}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

A a = A();
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 34, 1),
    ]);
  }

  test_outsidePackage_constructor_named() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  C.named();
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

C a = C.named();
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 40, 7),
    ]);
  }

  test_outsidePackage_constructor_unnamed() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  C();
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

C a = C();
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 40, 1),
    ]);
  }

  test_outsidePackage_enum() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
enum E {one}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

void f(E value) {}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 41, 1),
    ]);
  }

  test_outsidePackage_enumValue() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
enum E {@internal one}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

E f() => E.one;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 45, 3),
    ]);
  }

  test_outsidePackage_extensionMethod() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
extension E on String {
  @internal
  int f() => 1;
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int a = 'hello'.f();
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 50, 1),
    ]);
  }

  test_outsidePackage_function() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a() => 1;
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int b = a() + 1;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 42, 1),
    ]);
  }

  test_outsidePackage_function_generic() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a<T>() => 1;
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int b = a<void>() + 1;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 42, 1),
    ]);
  }

  test_outsidePackage_function_generic_tearoff() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a<T>() => 1;
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int Function() b = a;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 53, 1),
    ]);
  }

  test_outsidePackage_function_tearoff() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a() => 1;
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int Function() b = a;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 53, 1),
    ]);
  }

  test_outsidePackage_functionLiteralForInternalTypedef() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
@internal
typedef IntFunc = int Function(int);
int foo(IntFunc f, int x) => f(x);
''');

    await assertNoErrorsInCode('''
import 'package:foo/src/a.dart';

int g() => foo((x) => 2*x, 7);
''');
  }

  test_outsidePackage_inCommentReference() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int get a => 1;
''');

    await assertNoErrorsInCode('''
import 'package:foo/src/a.dart';

/// This is quite similar to [a].
int b = 1;
''');
  }

  test_outsidePackage_library() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
@internal
library a;
import 'package:meta/meta.dart';
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 0, 32),
      error(HintCode.UNUSED_IMPORT, 7, 24),
    ]);
  }

  test_outsidePackage_method() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  int m() => 1;
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int a = C().m();
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 46, 1),
    ]);
  }

  test_outsidePackage_method_generic() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  int m<T>() => 1;
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int a = C().m<void>();
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 46, 1),
    ]);
  }

  test_outsidePackage_method_subclassed() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal int f() => 1;
}

class D extends C {}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int a = D().f();
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 46, 1),
    ]);
  }

  test_outsidePackage_method_subclassed_overridden() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal int f() => 1;
}

class D extends C {
  int f() => 2;
}
''');

    await assertNoErrorsInCode('''
import 'package:foo/src/a.dart';

int a = D().f();
''');
  }

  test_outsidePackage_method_tearoff() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  int m() => 1;
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int Function() a = C().m;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 57, 1),
    ]);
  }

  test_outsidePackage_methodParameter_named() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  int m({@internal int a = 0}) => 1;
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int a = C().m(a: 5);
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 48, 1),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/28066')
  test_outsidePackage_methodParameter_positional() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  int m([@internal int a = 0]) => 1;
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int a = C().m(5);
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 48, 1),
    ]);
  }

  test_outsidePackage_mixin() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
mixin A {}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

class C with A {}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 47, 1),
    ]);
  }

  test_outsidePackage_pairedWithProtected() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  @protected
  void f() {}
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

class D extends C {
  void g() => f();
}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 68, 1),
    ]);
  }

  test_outsidePackage_redirectingFactoryConstructor() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
import 'package:test/test.dart';
class D implements C {
  @internal D();
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

class C {
  factory C() = D;
}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 60, 1),
    ]);
  }

  test_outsidePackage_setter() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal
  set s(int value) {}
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

f() {
  C().s = 7;
}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 46, 1),
    ]);
  }

  test_outsidePackage_setter_compound() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  int get s() => 1;

  @internal
  set s(int value) {}
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

f() {
  C().s += 7;
}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 46, 1),
    ]);
  }

  test_outsidePackage_setter_questionQuestion() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  int get s() => 1;

  @internal
  set s(int value) {}
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

f() {
  C().s ??= 7;
}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 46, 1),
    ]);
  }

  test_outsidePackage_superConstructor() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal C();
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

class D extends C {
  D() : super();
}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 62, 7),
    ]);
  }

  test_outsidePackage_superConstructor_named() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
class C {
  @internal C.named();
}
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

class D extends C {
  D() : super.named();
}
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 68, 5),
    ]);
  }

  test_outsidePackage_topLevelGetter() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int get a => 1;
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int b = a + 1;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 42, 1),
    ]);
  }

  test_outsidePackage_typedef() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
typedef t = void Function();
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

t func = () {};
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 34, 1),
    ]);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/28066')
  test_outsidePackage_typedefParameter() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
typedef T = void Function({@internal int a = 1});
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

void f(T t) => t(a: 5);
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 42, 1),
    ]);
  }

  test_outsidePackage_variable() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a = 1;
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart';

int b = a + 1;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 42, 1),
    ]);
  }

  test_outsidePackage_variable_prefixed() async {
    newFile('$fooPackageRootPath/lib/src/a.dart', '''
import 'package:meta/meta.dart';
@internal
int a = 1;
''');

    await assertErrorsInCode('''
import 'package:foo/src/a.dart' as foo;

int b = foo.a + 1;
''', [
      error(HintCode.INVALID_USE_OF_INTERNAL_MEMBER, 53, 1),
    ]);
  }
}
