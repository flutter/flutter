// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedExportUseTest);
  });
}

@reflectiveTest
class DeprecatedExportUseTest extends PubPackageResolutionTest {
  test_deprecated_augmentation_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library augment 'c.dart';

@deprecated
export 'a.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
import augment 'b.dart';
''');

    await assertErrorsInCode('''
import 'c.dart';

void f() {
  foo();
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 31, 3),
    ]);
  }

  test_deprecated_class_asExpression() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertErrorsInCode('''
import 'b.dart';

void f() {
  A;
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 31, 1),
    ]);
  }

  test_deprecated_class_asExpression_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertErrorsInCode('''
import 'b.dart' as prefix;

void f() {
  prefix.A;
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 48, 1),
    ]);
  }

  test_deprecated_class_asType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertErrorsInCode('''
import 'b.dart';

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 25, 1),
    ]);
  }

  test_deprecated_class_asType_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertErrorsInCode('''
import 'b.dart' as prefix;

void f(prefix.A a) {}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 42, 1),
    ]);
  }

  test_deprecated_class_import_show() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertErrorsInCode('''
import 'b.dart' show A;

void f(A a) {}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 32, 1),
    ]);
  }

  test_deprecated_function() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertErrorsInCode('''
import 'b.dart';

void f() {
  foo();
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 31, 3),
    ]);
  }

  test_deprecated_function_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertErrorsInCode('''
import 'b.dart' as prefix;

void f() {
  prefix.foo();
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 48, 3),
    ]);
  }

  test_deprecated_getter() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

/// Does not prevent the hint.
set foo(int _) {}
''');

    await assertErrorsInCode('''
import 'b.dart';

void f() {
  foo;
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 31, 3),
    ]);
  }

  test_deprecated_getter_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

/// Does not prevent the hint.
set foo(int _) {}
''');

    await assertErrorsInCode('''
import 'b.dart' as prefix;

void f() {
  prefix.foo;
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 48, 3),
    ]);
  }

  /// While linking `b.dart` and `c.dart` library cycle, we build their
  /// import scopes, and while doing this we access `hasDeprecated` on the
  /// `export a.dart` in `b.dart`. But because the metadata is not resolved
  /// yet (we are still linking!), we cache metadata flags that don't
  /// reflect the actual state. So, we need to reset them after linking.
  /// If we don't, we will fail to report the hint.
  test_deprecated_libraryCycle() async {
    newFile('$testPackageLibPath/a.dart', r'''
void foo() {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'c.dart';

@deprecated
export 'a.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
import 'b.dart';
''');

    await assertErrorsInCode('''
import 'b.dart';

void f() {
  foo();
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 31, 3),
    ]);
  }

  test_deprecated_setter() async {
    newFile('$testPackageLibPath/a.dart', r'''
void set foo(int _) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

/// Does not prevent the hint.
int get foo => 0;
''');

    await assertErrorsInCode('''
import 'b.dart';

void f() {
  foo = 0;
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 31, 3),
    ]);
  }

  test_deprecated_setter_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
void set foo(int _) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

/// Does not prevent the hint.
int get foo => 0;
''');

    await assertErrorsInCode('''
import 'b.dart' as prefix;

void f() {
  prefix.foo = 0;
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 48, 3),
    ]);
  }

  test_deprecated_variable() async {
    newFile('$testPackageLibPath/a.dart', r'''
var foo = 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertErrorsInCode('''
import 'b.dart';

void f() {
  foo;
}
''', [
      error(HintCode.DEPRECATED_EXPORT_USE, 31, 3),
    ]);
  }

  test_notDeprecated_class_hasDirectImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';
''');

    await assertNoErrorsInCode('''
import 'a.dart';
import 'b.dart';

void f(A a) {}
''');
  }

  test_notDeprecated_class_hasNotDeprecatedExport() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

// Not deprecated.
export 'a.dart';
''');

    await assertNoErrorsInCode('''
import 'b.dart';

void f(A a) {}
''');
  }

  test_notDeprecated_class_import_hide() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

class B {}
''');

    await assertNoErrorsInCode('''
import 'a.dart';
import 'b.dart' hide A;

void f(A a, B b) {}
''');
  }

  test_notDeprecated_class_onlyNotDeprecatedExport() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
export 'a.dart';
''');

    await assertNoErrorsInCode('''
import 'b.dart';

void f(A a) {}
''');
  }

  test_notDeprecated_getter_useSetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

set foo(int _) {}
''');

    await assertNoErrorsInCode('''
import 'b.dart';

void f() {
  foo = 0;
}
''');
  }

  test_notDeprecated_getter_useSetter_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
int get foo => 0;
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

set foo(int _) {}
''');

    await assertNoErrorsInCode('''
import 'b.dart' as prefix;

void f() {
  prefix.foo = 0;
}
''');
  }

  test_notDeprecated_setter_useGetter() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

int get foo => 0;
''');

    await assertNoErrorsInCode('''
import 'b.dart';

void f() {
  foo;
}
''');
  }

  test_notDeprecated_setter_useGetter_prefixed() async {
    newFile('$testPackageLibPath/a.dart', r'''
set foo(int _) {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library b;

@deprecated
export 'a.dart';

int get foo => 0;
''');

    await assertNoErrorsInCode('''
import 'b.dart' as prefix;

void f() {
  prefix.foo;
}
''');
  }
}
