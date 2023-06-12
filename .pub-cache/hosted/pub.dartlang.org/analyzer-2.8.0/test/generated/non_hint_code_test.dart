// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonHintCodeTest);
  });
}

@reflectiveTest
class NonHintCodeTest extends PubPackageResolutionTest {
  test_issue20904BuggyTypePromotionAtIfJoin_1() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    await assertErrorsInCode(r'''
f(var message, var dynamic_) {
  if (message is Function) {
    message = dynamic_;
  }
  int s = message;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 94, 1),
    ]);
  }

  test_issue20904BuggyTypePromotionAtIfJoin_3() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    await assertErrorsInCode(r'''
f(var message) {
  var dynamic_;
  if (message is Function) {
    message = dynamic_;
  } else {
    return;
  }
  int s = message;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 119, 1),
    ]);
  }

  test_issue20904BuggyTypePromotionAtIfJoin_4() async {
    // https://code.google.com/p/dart/issues/detail?id=20904
    await assertErrorsInCode(r'''
f(var message) {
  if (message is Function) {
    message = '';
  } else {
    return;
  }
  String s = message;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 100, 1),
    ]);
  }

  test_propagatedFieldType() async {
    await assertNoErrorsInCode(r'''
class A { }
class X<T> {
  final x = <T>[];
}
class Z {
  final X<A> y = new X<A>();
  foo() {
    y.x.add(new A());
  }
}
''');
  }

  test_proxy_annotation_prefixed() async {
    await assertErrorsInCode(r'''
library L;
@proxy
class A {}
f(var a) {
  a = new A();
  a.m();
  var x = a.g;
  a.s = 1;
  var y = a + a;
  a++;
  ++a;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 70, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 96, 1),
    ]);
  }

  test_proxy_annotation_prefixed2() async {
    await assertErrorsInCode(r'''
library L;
@proxy
class A {}
class B {
  f(var a) {
    a = new A();
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 88, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 118, 1),
    ]);
  }

  test_proxy_annotation_prefixed3() async {
    await assertErrorsInCode(r'''
library L;
class B {
  f(var a) {
    a = new A();
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}
@proxy
class A {}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 70, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 100, 1),
    ]);
  }

  test_undefinedMethod_assignmentExpression_inSubtype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a, var a2) {
  a = new A();
  a2 = new A();
  a += a2;
}
''');
  }

  test_undefinedMethod_dynamic() async {
    await assertNoErrorsInCode(r'''
class D<T extends dynamic> {
  fieldAccess(T t) => t.abc;
  methodAccess(T t) => t.xyz(1, 2, 'three');
}
''');
  }

  test_undefinedMethod_unionType_all() async {
    await assertNoErrorsInCode(r'''
class A {
  int m(int x) => 0;
}
class B {
  String m() => '0';
}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m();
}
''');
  }

  test_undefinedMethod_unionType_some() async {
    await assertNoErrorsInCode(r'''
class A {
  int m(int x) => 0;
}
class B {}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m(0);
}
''');
  }
}

class PubSuggestionCodeTest extends PubPackageResolutionTest {
  // TODO(brianwilkerson) The tests in this class are not being run, and all but
  //  the first would fail. We should implement these checks and enable the
  //  tests.
  test_import_package() async {
    await assertErrorsInCode('''
import 'package:somepackage/other.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 0, 0),
    ]);
  }

  test_import_packageWithDotDot() async {
    await assertErrorsInCode('''
import 'package:somepackage/../other.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 0, 0),
      error(HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT, 0, 0),
    ]);
  }

  test_import_packageWithLeadingDotDot() async {
    await assertErrorsInCode('''
import 'package:../other.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 0, 0),
      error(HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT, 0, 0),
    ]);
  }

  test_import_referenceIntoLibDirectory() async {
    newFile("/myproj/pubspec.yaml", content: "");
    newFile("/myproj/lib/other.dart", content: "");
    await _assertErrorsInCodeInFile(
        "/myproj/web/test.dart", "import '../lib/other.dart';", [
      error(HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE, 0, 0),
    ]);
  }

  test_import_referenceIntoLibDirectory_no_pubspec() async {
    newFile("/myproj/lib/other.dart", content: "");
    await _assertErrorsInCodeInFile(
        "/myproj/web/test.dart", "import '../lib/other.dart';", []);
  }

  test_import_referenceOutOfLibDirectory() async {
    newFile("/myproj/pubspec.yaml", content: "");
    newFile("/myproj/web/other.dart", content: "");
    await _assertErrorsInCodeInFile(
        "/myproj/lib/test.dart", "import '../web/other.dart';", [
      error(HintCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE, 0, 0),
    ]);
  }

  test_import_referenceOutOfLibDirectory_no_pubspec() async {
    newFile("/myproj/web/other.dart", content: "");
    await _assertErrorsInCodeInFile(
        "/myproj/lib/test.dart", "import '../web/other.dart';", []);
  }

  test_import_valid_inside_lib1() async {
    newFile("/myproj/pubspec.yaml", content: "");
    newFile("/myproj/lib/other.dart", content: "");
    await _assertErrorsInCodeInFile(
        "/myproj/lib/test.dart", "import 'other.dart';", []);
  }

  test_import_valid_inside_lib2() async {
    newFile("/myproj/pubspec.yaml", content: "");
    newFile("/myproj/lib/bar/other.dart", content: "");
    await _assertErrorsInCodeInFile(
        "/myproj/lib/foo/test.dart", "import '../bar/other.dart';", []);
  }

  test_import_valid_outside_lib() async {
    newFile("/myproj/pubspec.yaml", content: "");
    newFile("/myproj/web/other.dart", content: "");
    await _assertErrorsInCodeInFile(
        "/myproj/lib2/test.dart", "import '../web/other.dart';", []);
  }

  Future<void> _assertErrorsInCodeInFile(
      String path, String content, List<ExpectedError> expectedErrors) async {
    path = convertPath(path);
    newFile(path, content: content);
    result = await resolveFile(path);

    var errorListener = GatheringErrorListener();
    errorListener.addAll(result.errors);
    errorListener.assertErrors(expectedErrors);
  }
}
