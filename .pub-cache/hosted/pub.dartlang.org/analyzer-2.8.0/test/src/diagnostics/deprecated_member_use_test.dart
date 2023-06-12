// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUse_BasicWorkspaceTest);
    defineReflectiveTests(
        DeprecatedMemberUse_BasicWorkspace_WithNullSafetyTest);
    defineReflectiveTests(DeprecatedMemberUse_BazelWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_GnWorkspaceTest);
    defineReflectiveTests(DeprecatedMemberUse_PackageBuildWorkspaceTest);

    defineReflectiveTests(
      DeprecatedMemberUseFromSamePackage_BasicWorkspaceTest,
    );
    defineReflectiveTests(
      DeprecatedMemberUseFromSamePackage_BazelWorkspaceTest,
    );
    defineReflectiveTests(
      DeprecatedMemberUseFromSamePackage_PackageBuildWorkspaceTest,
    );
  });
}

@reflectiveTest
class DeprecatedMemberUse_BasicWorkspace_WithNullSafetyTest
    extends PubPackageResolutionTest
    with DeprecatedMemberUse_BasicWorkspaceTestCases {
  test_instanceCreation_namedParameter_fromLegacy() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  A({@deprecated int a}) {}
}
''');

    await assertErrorsInCode(r'''
// @dart = 2.9
import 'package:aaa/a.dart';

void f() {
  A(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 60, 1),
    ]);
  }

  test_methodInvocation_namedParameter_ofFunction_fromLegacy() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
void foo({@deprecated int a}) {}
''');

    await assertErrorsInCode(r'''
// @dart = 2.9
import 'package:aaa/a.dart';

void f() {
  foo(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 62, 1),
    ]);
  }

  test_methodInvocation_namedParameter_ofMethod_fromLegacy() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  void foo({@deprecated int a}) {}
}
''');

    await assertErrorsInCode(r'''
// @dart = 2.9
import 'package:aaa/a.dart';

void f(A a) {
  a.foo(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 67, 1),
    ]);
  }

  test_superConstructorInvocation_namedParameter_fromLegacy() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  A({@deprecated int a}) {}
}
''');

    await assertErrorsInCode(r'''
// @dart = 2.9
import 'package:aaa/a.dart';

class B extends A {
  B() : super(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 79, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUse_BasicWorkspaceTest extends PubPackageResolutionTest
    with WithoutNullSafetyMixin, DeprecatedMemberUse_BasicWorkspaceTestCases {}

mixin DeprecatedMemberUse_BasicWorkspaceTestCases on PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );
  }

  test_export() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
@deprecated
library a;
''');

    await assertErrorsInCode('''
export 'package:aaa/a.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 0, 28),
    ]);
  }

  test_field_inDeprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  int x = 0;
}
''');

    await assertNoErrorsInCode(r'''
import 'package:aaa/a.dart';

class B extends A {
  @deprecated
  B() {
    x;
    x = 1;
  }
}
''');
  }

  test_fieldGet_implicitGetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  int foo = 0;
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_fieldSet_implicitSetter() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  int foo = 0;
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_import() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
@deprecated
library a;
''');

    await assertErrorsInCode(r'''
// ignore:unused_import
import 'package:aaa/a.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 24, 28,
          messageContains: ['package:aaa/a.dart']),
    ]);
  }

  test_method_inDeprecatedConstructor() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  void foo() {}
}
''');

    await assertNoErrorsInCode(r'''
import 'package:aaa/a.dart';

class B extends A {
  @deprecated
  B() {
    foo();
  }
}
''');
  }

  test_methodInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  test_methodInvocation_withMessage() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @Deprecated('0.9')
  void foo() {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo();
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE, 48, 3),
    ]);
  }

  test_parameter_named_ofFunction() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
void foo({@deprecated int a}) {}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f() {
  foo(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 47, 1),
    ]);
  }

  test_parameter_named_ofMethod() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  void foo({@deprecated int a}) {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 52, 1),
    ]);
  }

  test_setterInvocation() async {
    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
class A {
  @deprecated
  set foo(int _) {}
}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {
  a.foo = 0;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 48, 3),
    ]);
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertBasicWorkspaceFor(testFilePath);
  }
}

@reflectiveTest
class DeprecatedMemberUse_BazelWorkspaceTest
    extends BazelWorkspaceResolutionTest {
  test_dart() async {
    newFile('$workspaceRootPath/foo/bar/lib/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'package:foo.bar/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 41, 1),
    ]);
  }

  test_thirdPartyDart() async {
    newFile('$workspaceThirdPartyDartPath/aaa/lib/a.dart', content: r'''
@deprecated
class A {}
''');

    assertBazelWorkspaceFor(testFilePath);

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUse_GnWorkspaceTest extends ContextResolutionTest {
  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/my';

  @override
  String get testFilePath => '$myPackageLibPath/my.dart';

  String get workspaceRootPath => '/workspace';

  @override
  void setUp() {
    super.setUp();
    newFolder('$workspaceRootPath/.jiri_root');
  }

  test_differentPackage() async {
    newPubspecYamlFile('$workspaceRootPath/my', '');
    newFile('$workspaceRootPath/my/BUILD.gn');

    newPubspecYamlFile('$workspaceRootPath/aaa', '');
    newFile('$workspaceRootPath/aaa/BUILD.gn');

    _writeWorkspacePackagesFile({
      'aaa': '$workspaceRootPath/aaa/lib',
      'my': myPackageLibPath,
    });

    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }

  test_samePackage() async {
    newPubspecYamlFile('$workspaceRootPath/my', '');
    newFile('$workspaceRootPath/my/BUILD.gn');

    _writeWorkspacePackagesFile({
      'my': myPackageLibPath,
    });

    newFile('$myPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'package:my/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 36, 1),
    ]);
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertGnWorkspaceFor(testFilePath);
  }

  void _writeWorkspacePackagesFile(Map<String, String> nameToLibPath) {
    var packages = nameToLibPath.entries.map((entry) => '''{
    "languageVersion": "2.2",
    "name": "${entry.key}",
    "packageUri": ".",
    "rootUri": "${toUriStr(entry.value)}"
  }''');

    var buildDir = 'out/debug-x87_128';
    var genPath = '$workspaceRootPath/$buildDir/dartlang/gen';
    newFile('$genPath/foo_package_config.json', content: '''{
  "configVersion": 2,
  "packages": [ ${packages.join(', ')} ]
}''');
  }
}

@reflectiveTest
class DeprecatedMemberUse_PackageBuildWorkspaceTest
    extends _PackageBuildWorkspaceBase {
  test_generated() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );

    newPubspecYamlFile(testPackageRootPath, 'name: test');
    _newTestPackageGeneratedFile(
      packageName: 'aaa',
      pathInLib: 'a.dart',
      content: r'''
@deprecated
class A {}
''',
    );

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }

  test_lib() async {
    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );

    newFile('$workspaceRootPath/aaa/lib/a.dart', content: r'''
@deprecated
class A {}
''');

    newPubspecYamlFile(testPackageRootPath, 'name: test');
    _createTestPackageBuildMarker();

    await assertErrorsInCode(r'''
import 'package:aaa/a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE, 37, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackage_BasicWorkspaceTest
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_assignmentExpression_compound_deprecatedGetter() async {
    await assertErrorsInCode(r'''
@deprecated
int get x => 0;

set x(int _) {}

void f() {
  x += 2;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
  }

  test_assignmentExpression_compound_deprecatedSetter() async {
    await assertErrorsInCode(r'''
int get x => 0;

@deprecated
set x(int _) {}

void f() {
  x += 2;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
  }

  test_assignmentExpression_simple_deprecatedGetter() async {
    await assertNoErrorsInCode(r'''
@deprecated
int get x => 0;

set x(int _) {}

void f() {
  x = 0;
}
''');
  }

  test_assignmentExpression_simple_deprecatedGetterSetter() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  x = 0;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 37, 1),
    ]);
  }

  test_assignmentExpression_simple_deprecatedSetter() async {
    await assertErrorsInCode(r'''
int get x => 0;

@deprecated
set x(int _) {}

void f() {
  x = 0;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
  }

  test_call() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  call() {}
  m() {
    A a = new A();
    a();
  }
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 67, 3),
    ]);
  }

  test_class() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 25, 1),
    ]);
  }

  test_compoundAssignment() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A operator+(A a) { return a; }
}
f(A a) {
  A b;
  a += b;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 77, 6),
    ]);
  }

  test_export() async {
    newFile('$testPackageLibPath/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');
    await assertErrorsInCode('''
export 'deprecated_library.dart';
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 33),
    ]);
  }

  test_extensionOverride() async {
    await assertErrorsInCode(r'''
@deprecated
extension E on int {
  int get foo => 0;
}

void f() {
  E(0).foo;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 69, 1),
    ]);
  }

  test_field() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  int x = 1;
}
f(A a) {
  return a.x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
  }

  test_field_inDeprecatedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  @deprecated
  int x = 1;

  @deprecated
  A() {
    x;
    x = 2;
  }
}
''');
  }

  test_field_inDeprecatedFunction() async {
    await assertNoErrorsInCode(r'''
class A {
  @deprecated
  int x = 1;
}

@deprecated
void f(A a) {
  a.x;
  a.x = 2;
}
''');
  }

  test_getter() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  get m => 1;
}
f(A a) {
  return a.m;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 60, 1),
    ]);
  }

  test_hideCombinator() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');
    await assertErrorsInCode('''
import 'a.dart' hide A;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 8),
    ]);
  }

  test_import() async {
    newFile('$testPackageLibPath/deprecated_library.dart', content: r'''
@deprecated
library deprecated_library;
class A {}
''');

    await assertErrorsInCode(r'''
import 'deprecated_library.dart';
f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 0, 33),
    ]);
  }

  test_inDeprecatedClass() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
class C {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedField() async {
    await assertNoErrorsInCode(r'''
@deprecated
class C {}

class X {
  @deprecated
  C f;
}
''');
  }

  test_inDeprecatedFunction() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
g() {
  f();
}
''');
  }

  test_inDeprecatedLibrary() async {
    await assertNoErrorsInCode(r'''
@deprecated
library lib;

@deprecated
f() {}

class C {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMethod() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

class C {
  @deprecated
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMethod_inDeprecatedClass() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
class C {
  @deprecated
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMixin() async {
    await assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
mixin M {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedTopLevelVariable() async {
    await assertNoErrorsInCode(r'''
@deprecated
class C {}

@deprecated
C v;
''');
  }

  test_indexExpression() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  operator[](int i) {}
}
f(A a) {
  return a[1];
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 67, 4),
    ]);
  }

  test_instanceCreation_namedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A.named(int i) {}
}
f() {
  return new A.named(1);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 65, 7),
    ]);
  }

  test_instanceCreation_unnamedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A(int i) {}
}
f() {
  return new A(1);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
  }

  test_method_inDeprecatedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  @deprecated
  A() {
    foo();
  }

  @deprecated
  void foo() {}
}
''');
  }

  test_methodInvocation_constant() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  m() {}
  n() {
    m();
  }
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 45, 1),
    ]);
  }

  test_methodInvocation_constructor() async {
    await assertErrorsInCode(r'''
class A {
  @Deprecated('0.9')
  m() {}
  n() {m();}
}
''', [
      error(
          HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE, 47, 1),
    ]);
  }

  test_operator() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  operator+(A a) {}
}
f(A a, A b) {
  return a + b;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 69, 5),
    ]);
  }

  test_parameter_named() async {
    await assertErrorsInCode(r'''
class A {
  m({@deprecated int x}) {}
  n() {m(x: 1);}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 47, 1),
    ]);
  }

  test_parameter_named_inDefiningConstructor_asFieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C({@deprecated this.x});
}
''');
  }

  test_parameter_named_inDefiningConstructor_assertInitializer() async {
    await assertNoErrorsInCode(r'''
class C {
  C({@deprecated int y}) : assert(y > 0);
}
''');
  }

  test_parameter_named_inDefiningConstructor_fieldInitializer() async {
    await assertNoErrorsInCode(r'''
class C {
  int x;
  C({@deprecated int y}) : x = y;
}
''');
  }

  test_parameter_named_inDefiningConstructor_inFieldFormalParameter_notName() async {
    await assertErrorsInCode(r'''
class A {}

@deprecated
class B extends A {}

class C {
  A a;
  C({B this.a});
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 68, 1),
    ]);
  }

  test_parameter_named_inDefiningFunction() async {
    await assertNoErrorsInCode(r'''
f({@deprecated int x}) => x;
''');
  }

  test_parameter_named_inDefiningLocalFunction() async {
    await assertNoErrorsInCode(r'''
class C {
  m() {
    f({@deprecated int x}) {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_named_inDefiningMethod() async {
    await assertNoErrorsInCode(r'''
class C {
  m({@deprecated int x}) {
    return x;
  }
}
''');
  }

  test_parameter_named_inNestedLocalFunction() async {
    await assertNoErrorsInCode(r'''
class C {
  m({@deprecated int x}) {
    f() {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_positionalOptional() async {
    await assertErrorsInCode(r'''
class A {
  void foo([@deprecated int x]) {}
}

void f(A a) {
  a.foo(0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 70, 1),
    ]);
  }

  test_parameter_positionalOptional_inDeprecatedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  @deprecated
  A() {
    foo(0);
  }

  void foo([@deprecated int x]) {}
}
''');
  }

  test_parameter_positionalOptional_inDeprecatedFunction() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo([@deprecated int x]) {}
}

@deprecated
void f(A a) {
  a.foo(0);
}
''');
  }

  test_parameter_positionalRequired() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo(@deprecated int x) {}
}

void f(A a) {
  a.foo(0);
}
''');
  }

  test_postfixExpression_deprecatedGetter() async {
    await assertErrorsInCode(r'''
@deprecated
int get x => 0;

set x(int _) {}

void f() {
  x++;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
  }

  test_postfixExpression_deprecatedNothing() async {
    await assertNoErrorsInCode(r'''
int get x => 0;

set x(int _) {}

void f() {
  x++;
}
''');
  }

  test_postfixExpression_deprecatedSetter() async {
    await assertErrorsInCode(r'''
int get x => 0;

@deprecated
set x(int _) {}

void f() {
  x++;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 59, 1),
    ]);
  }

  test_prefixedIdentifier_identifier() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  static const foo = 0;
}

void f() {
  A.foo;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 66, 3),
    ]);
  }

  test_prefixedIdentifier_prefix() async {
    await assertErrorsInCode(r'''
@deprecated
class A {
  static const foo = 0;
}

void f() {
  A.foo;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 62, 1),
    ]);
  }

  test_prefixExpression_deprecatedGetter() async {
    await assertErrorsInCode(r'''
@deprecated
int get x => 0;

set x(int _) {}

void f() {
  ++x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 61, 1),
    ]);
  }

  test_prefixExpression_deprecatedSetter() async {
    await assertErrorsInCode(r'''
int get x => 0;

@deprecated
set x(int _) {}

void f() {
  ++x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 61, 1),
    ]);
  }

  test_propertyAccess_super() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  int get foo => 0;
}

class B extends A {
  void bar() {
    super.foo;
  }
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 92, 3),
    ]);
  }

  test_redirectingConstructorInvocation_namedParameter() async {
    await assertErrorsInCode(r'''
class A {
  A({@deprecated int a}) {}
  A.named() : this(a: 0);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 57, 1),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  set s(v) {}
}
f(A a) {
  return a.s = 1;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 60, 1),
    ]);
  }

  test_showCombinator() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');
    await assertErrorsInCode('''
import 'a.dart' show A;
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 21, 1),
      error(HintCode.UNUSED_IMPORT, 7, 8),
    ]);
  }

  test_superConstructor_namedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A.named() {}
}
class B extends A {
  B() : super.named() {}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 69, 13),
    ]);
  }

  test_superConstructor_unnamedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  @deprecated
  A() {}
}
class B extends A {
  B() : super() {}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 63, 7),
    ]);
  }

  test_topLevelVariable_argument() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  print(x);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 43, 1),
    ]);
  }

  test_topLevelVariable_assignment_right() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f(int a) {
  a = x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 46, 1),
    ]);
  }

  test_topLevelVariable_binaryExpression() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  x + 1;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 37, 1),
    ]);
  }

  test_topLevelVariable_constructorFieldInitializer() async {
    await assertErrorsInCode(r'''
@deprecated
const int x = 1;

class A {
  final int f;
  A() : f = x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 67, 1),
    ]);
  }

  test_topLevelVariable_expressionFunctionBody() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

int f() => x;
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 35, 1),
    ]);
  }

  test_topLevelVariable_expressionStatement() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 37, 1),
    ]);
  }

  test_topLevelVariable_forElement_condition() async {
    await assertErrorsInCode(r'''
@deprecated
var x = true;

void f() {
  [for (;x;) 0];
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 47, 1),
    ]);
  }

  test_topLevelVariable_forStatement_condition() async {
    await assertErrorsInCode(r'''
@deprecated
var x = true;

void f() {
  for (;x;) {}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 46, 1),
    ]);
  }

  test_topLevelVariable_ifElement_condition() async {
    await assertErrorsInCode(r'''
@deprecated
var x = true;

void f() {
  [if (x) 0];
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 45, 1),
    ]);
  }

  test_topLevelVariable_ifStatement_condition() async {
    await assertErrorsInCode(r'''
@deprecated
var x = true;

void f() {
  if (x) {}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 44, 1),
    ]);
  }

  test_topLevelVariable_listLiteral() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  [x];
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 38, 1),
    ]);
  }

  test_topLevelVariable_mapLiteralEntry() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  ({0: x, x: 0});
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 42, 1),
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 45, 1),
    ]);
  }

  test_topLevelVariable_namedExpression() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void g({int a = 0}) {}

void f() {
  g(a: x);
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 66, 1),
    ]);
  }

  test_topLevelVariable_returnStatement() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

int f() {
  return x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 43, 1),
    ]);
  }

  test_topLevelVariable_setLiteral() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  ({x});
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 39, 1),
    ]);
  }

  test_topLevelVariable_spreadElement() async {
    await assertErrorsInCode(r'''
@deprecated
var x = [0];

void f() {
  [...x];
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 43, 1),
    ]);
  }

  test_topLevelVariable_switchCase() async {
    await assertErrorsInCode(r'''
@deprecated
const int x = 1;

void f(int a) {
  switch (a) {
    case x:
      break;
  }
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 70, 1),
    ]);
  }

  test_topLevelVariable_switchStatement() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  switch (x) {}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 45, 1),
    ]);
  }

  test_topLevelVariable_unaryExpression() async {
    await assertErrorsInCode(r'''
@deprecated
int x = 1;

void f() {
  -x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 38, 1),
    ]);
  }

  test_topLevelVariable_variableDeclaration_initializer() async {
    await assertErrorsInCode(r'''
@deprecated
var x = 1;

void f() {
  // ignore:unused_local_variable
  var v = x;
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 79, 1),
    ]);
  }

  test_topLevelVariable_whileStatement_condition() async {
    await assertErrorsInCode(r'''
@deprecated
var x = true;

void f() {
  while (x) {}
}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 47, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackage_BazelWorkspaceTest
    extends BazelWorkspaceResolutionTest {
  test_it() async {
    newFile('$myPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 25, 1),
    ]);
  }
}

@reflectiveTest
class DeprecatedMemberUseFromSamePackage_PackageBuildWorkspaceTest
    extends _PackageBuildWorkspaceBase {
  test_generated() async {
    newPubspecYamlFile(testPackageRootPath, 'name: test');

    _newTestPackageGeneratedFile(
      packageName: 'test',
      pathInLib: 'a.dart',
      content: r'''
@deprecated
class A {}
''',
    );

    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 25, 1),
    ]);
  }

  test_lib() async {
    newPubspecYamlFile(testPackageRootPath, 'name: test');
    _createTestPackageBuildMarker();

    newFile('$testPackageLibPath/a.dart', content: r'''
@deprecated
class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE, 25, 1),
    ]);
  }
}

class _PackageBuildWorkspaceBase extends PubPackageResolutionTest {
  String get testPackageGeneratedPath {
    return '$testPackageRootPath/.dart_tool/build/generated';
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertPackageBuildWorkspaceFor(testFilePath);
  }

  void _createTestPackageBuildMarker() {
    newFolder(testPackageGeneratedPath);
  }

  void _newTestPackageGeneratedFile({
    required String packageName,
    required String pathInLib,
    required String content,
  }) {
    newFile(
      '$testPackageGeneratedPath/$packageName/lib/$pathInLib',
      content: content,
    );
  }
}
