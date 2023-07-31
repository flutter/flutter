// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidInternalAnnotationTest);
  });
}

@reflectiveTest
class InvalidInternalAnnotationTest extends PubPackageResolutionTest {
  String get testPackageLibSrcFilePath => '$testPackageLibPath/src/foo.dart';

  @override
  void setUp() async {
    super.setUp();
    writeTestPackageConfigWithMeta();
    newPubspecYamlFile(testPackageRootPath, r'''
name: test
version: 0.0.1
''');
  }

  void test_annotationInLib() async {
    await resolveFileCode('$testPackageLibPath/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
    ]);
  }

  void test_annotationInLib_onLibrary() async {
    await resolveFileCode('$testPackageLibPath/foo.dart', r'''
@internal
library foo;
import 'package:meta/meta.dart';
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 0, 9),
    ]);
  }

  void test_annotationInLibSrc() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertNoErrorsInResult();
  }

  void test_annotationInLibSrcSubdirectory() async {
    await resolveFileCode('$testPackageLibPath/src/foo/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertNoErrorsInResult();
  }

  void test_annotationInLibSubdirectory() async {
    await resolveFileCode('$testPackageLibPath/foo/foo.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
    ]);
  }

  void test_annotationInTest() async {
    await resolveFileCode('$testPackageRootPath/test/foo_test.dart', r'''
import 'package:meta/meta.dart';
@internal class One {}
''');

    assertNoErrorsInResult();
  }

  void test_privateClass() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal class _One {}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 49, 4),
    ]);
  }

  void test_privateClassConstructor_named() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal _C.named();
}
''');

    assertErrorsInResult([
      error(HintCode.UNUSED_ELEMENT, 39, 2),
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 46, 9),
    ]);
  }

  void test_privateClassConstructor_unnamed() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal _C();
}
''');

    assertErrorsInResult([
      error(HintCode.UNUSED_ELEMENT, 39, 2),
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 46, 9),
    ]);
  }

  void test_privateConstructor() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal C._f();
}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 45, 9),
    ]);
  }

  void test_privateEnum() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal enum _E {one}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 48, 2),
      error(HintCode.UNUSED_FIELD, 52, 3),
    ]);
  }

  void test_privateEnumValue() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
enum E {@internal _one}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 41, 9),
      error(HintCode.UNUSED_FIELD, 51, 4),
    ]);
  }

  void test_privateExtension() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal extension _One on String {}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
    ]);
  }

  void test_privateExtension_unnamed() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal extension on String {}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
    ]);
  }

  void test_privateField_instance() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal int _i = 0;
}
''');

    assertErrorsInResult([
      error(HintCode.UNUSED_FIELD, 59, 2),
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 59, 6),
    ]);
  }

  void test_privateField_static() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal static int _i = 0;
}
''');

    assertErrorsInResult([
      error(HintCode.UNUSED_FIELD, 66, 2),
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 66, 6),
    ]);
  }

  void test_privateGetter() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal int get _i => 0;
}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 45, 9),
      error(HintCode.UNUSED_ELEMENT, 63, 2),
    ]);
  }

  void test_privateMethod_instance() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal void _f() {}
}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 45, 9),
      error(HintCode.UNUSED_ELEMENT, 60, 2),
    ]);
  }

  void test_privateMethod_static() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class C {
  @internal static void _f() {}
}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 45, 9),
      error(HintCode.UNUSED_ELEMENT, 67, 2),
    ]);
  }

  void test_privateMixin() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal mixin _One {}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 49, 4),
    ]);
  }

  void test_privateTopLevelFunction() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal void _f() {}
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 48, 2),
    ]);
  }

  void test_privateTopLevelVariable() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal int _i = 1;
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 47, 6),
      error(HintCode.UNUSED_ELEMENT, 47, 2),
    ]);
  }

  void test_privateTypedef() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
@internal typedef _T = void Function();
''');

    assertErrorsInResult([
      error(HintCode.INVALID_INTERNAL_ANNOTATION, 33, 9),
      error(HintCode.UNUSED_ELEMENT, 51, 2),
    ]);
  }

  void test_publicMethod_privateClass() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal void f() {}
}
''');

    assertErrorsInResult([
      error(HintCode.UNUSED_ELEMENT, 39, 2),
    ]);
  }

  void test_publicMethod_privateClass_static() async {
    await resolveFileCode(testPackageLibSrcFilePath, r'''
import 'package:meta/meta.dart';
class _C {
  @internal static void f() {}
}
''');

    assertErrorsInResult([
      error(HintCode.UNUSED_ELEMENT, 39, 2),
      error(HintCode.UNUSED_ELEMENT, 68, 1),
    ]);
  }
}
