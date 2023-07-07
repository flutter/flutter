// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidUseOfVisibleForTestingMemberTest);
  });
}

@reflectiveTest
class InvalidUseOfVisibleForTestingMemberTest extends PubPackageResolutionTest {
  @override
  String get testPackageRootPath => '/home/my';

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_export_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart' hide A;
''');

    await _resolveFile('$testPackageLibPath/a.dart');
    await _resolveFile('$testPackageLibPath/b.dart');
  }

  test_export_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart' show A;
''');

    await _resolveFile('$testPackageLibPath/a.dart');
    await _resolveFile('$testPackageLibPath/b.dart');
  }

  test_fromIntegrationTestDirectory() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    newFile('$testPackageRootPath/integration_test/test.dart', r'''
import '../lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/integration_test/test.dart');
  }

  test_fromTestDirectory() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    newFile('$testPackageRootPath/test/test.dart', r'''
import '../lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/test/test.dart');
  }

  test_fromTestDriverDirectory() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    newFile('$testPackageRootPath/test_driver/test.dart', r'''
import '../lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/test_driver/test.dart');
  }

  test_fromTestingDirectory() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    newFile('$testPackageRootPath/testing/lib1.dart', r'''
import '../lib1.dart';
class C {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/testing/lib1.dart');
  }

  test_functionInExtension() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  E([]).m();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 42, 1),
    ]);
  }

  test_functionInExtension_fromTestDirectory() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
extension E on List {
  @visibleForTesting
  int m() => 1;
}
''');
    newFile('$testPackageRootPath/test/test.dart', r'''
import '../lib1.dart';
void main() {
  E([]).m();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/test/test.dart');
  }

  test_getter() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  int get a => 7;
}
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  new A().a;
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 44, 1),
    ]);
  }

  test_import_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' hide A;

void f(B _) {}
''');

    await _resolveFile('$testPackageLibPath/a.dart');
    await _resolveFile('$testPackageLibPath/b.dart');
  }

  test_import_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:meta/meta.dart';

@visibleForTesting
class A {}

class B {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart' show A;

void f(A _) {}
''');

    await _resolveFile('$testPackageLibPath/a.dart');
    await _resolveFile('$testPackageLibPath/b.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 21, 1),
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 32, 1),
    ]);
  }

  test_method() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  void a(){ }
}
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
class B {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 52, 1),
    ]);
  }

  test_mixin() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
mixin M {
  @visibleForTesting
  int m() => 1;
}
class C with M {}
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  C().m();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 1),
    ]);
  }

  test_namedConstructor() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  int _x;

  @visibleForTesting
  A.forTesting(this._x);
}
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  new A.forTesting(0);
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart', [
      error(HintCode.UNUSED_FIELD, 49, 2),
    ]);
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 12,
          messageContains: ['A.forTesting']),
    ]);
  }

  test_protectedAndForTesting_usedAsProtected() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
class B extends A {
  void b() => new A().a();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/lib2.dart');
  }

  test_protectedAndForTesting_usedAsTesting() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @protected
  @visibleForTesting
  void a(){ }
}
''');
    newFile('$testPackageRootPath/test/test1.dart', r'''
import '../lib1.dart';
void main() {
  new A().a();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/test/test1.dart');
  }

  test_setter() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  @visibleForTesting
  set b(_) => 7;
}
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  new A().b = 6;
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 44, 1),
    ]);
  }

  test_topLevelFunction() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@visibleForTesting
int fn0() => 1;
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  fn0();
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 36, 3),
    ]);
  }

  test_topLevelVariable() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
@visibleForTesting
int a = 7;
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  a;
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart');
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 36, 1),
    ]);
  }

  test_unnamedConstructor() async {
    newFile('$testPackageRootPath/lib1.dart', r'''
import 'package:meta/meta.dart';
class A {
  int _x;

  @visibleForTesting
  A(this._x);
}
''');
    newFile('$testPackageRootPath/lib2.dart', r'''
import 'lib1.dart';
void main() {
  new A(0);
}
''');

    await _resolveFile('$testPackageRootPath/lib1.dart', [
      error(HintCode.UNUSED_FIELD, 49, 2),
    ]);
    await _resolveFile('$testPackageRootPath/lib2.dart', [
      error(HintCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER, 40, 1),
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
