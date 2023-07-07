// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTemplateMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForTemplateMemberTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    var angularMetaPath = '/packages/angular_meta';
    newFile('$angularMetaPath/lib/angular_meta.dart', r'''
library angular.meta;

const _VisibleForTemplate visibleForTemplate = const _VisibleForTemplate();

class _VisibleForTemplate {
  const _VisibleForTemplate();
}
''');

    writeTestPackageConfig(
      PackageConfigFileBuilder()
        ..add(name: 'angular_meta', rootPath: angularMetaPath),
      meta: true,
    );
  }

  test_export() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int fn0() => 1;
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
export 'lib1.dart' show fn0;
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_functionInExtension() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
extension E on List {
  @visibleForTemplate
  int m() => 1;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  E([]).m();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 42, 1),
    ]);
  }

  test_functionInExtension_fromTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
extension E on List {
  @visibleForTemplate
  int m() => 1;
}
''');
    newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';
void main() {
  E([]).m();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib1.template.dart');
  }

  test_method() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  void a(){ }
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 53, 1),
    ]);
  }

  test_method_fromTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  void a(){ }
}
''');
    newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';

class B {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib1.template.dart');
  }

  test_namedConstructor() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  int _x;

  @visibleForTemplate
  A.forTemplate(this._x);
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A.forTemplate(0);
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart', [
      error(HintCode.UNUSED_FIELD, 65, 2),
    ]);
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 41, 13),
    ]);
  }

  test_propertyAccess() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  @visibleForTemplate
  int get a => 7;

  @visibleForTemplate
  set b(_) => 7;
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A().a;
  new A().b = 6;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 45, 1),
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 58, 1),
    ]);
  }

  test_protectedAndForTemplate_usedAsProtected() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';
class B extends A {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart');
  }

  test_protectedAndForTemplate_usedAsTemplate() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTemplate
  void a(){ }
}
''');
    newFile('$testPackageLibPath/lib1.template.dart', r'''
import 'lib1.dart';
void main() {
  new A().a();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib1.template.dart');
  }

  test_topLevelFunction() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';

@visibleForTemplate
int fn0() => 1;
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void main() {
  fn0();
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 37, 3),
    ]);
  }

  test_topLevelVariable() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
@visibleForTemplate
int a = 7;
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void main() {
  a;
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart');
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 37, 1),
    ]);
  }

  test_unnamedConstructor() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
import 'package:angular_meta/angular_meta.dart';
class A {
  int _x;

  @visibleForTemplate
  A(this._x);
}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
import 'lib1.dart';

void main() {
  new A(0);
}
''');

    await _resolveFile('$testPackageLibPath/lib1.dart', [
      error(HintCode.UNUSED_FIELD, 65, 2),
    ]);
    await _resolveFile('$testPackageLibPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER, 41, 1),
    ]);
  }

  /// Resolve the file with the given [path].
  ///
  /// Similar to ResolutionTest.resolveTestFile, but a custom path is supported.
  Future<void> _resolveFile(
    String path, [
    List<ExpectedError> expectedErrors = const [],
  ]) async {
    result = await resolveFile(convertPath(path));
    assertErrorsInResolvedUnit(result, expectedErrors);
  }
}
