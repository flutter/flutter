// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinApplicationNotImplementedInterfaceTest);
  });
}

@reflectiveTest
class MixinApplicationNotImplementedInterfaceTest
    extends PubPackageResolutionTest {
  test_class_matchingInterface() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends A<int> with M {}
''');
  }

  test_class_matchingInterface_inPreviousMixin() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M1 implements A<B> {}
mixin M2<T> on A<T> {}
class C extends Object with M1, M2 {}
''');
  }

  test_class_noMatchingInterface() async {
    await assertErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M {}
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          84, 1),
    ]);
  }

  test_class_noMatchingInterface_withTypeArguments() async {
    await assertErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M<int> {}
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          84, 1),
    ]);
  }

  test_class_noMemberErrors() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}

mixin M on A {
  void bar() {
    super.foo();
  }
}

class C {
  noSuchMethod(_) {}
}

class X = C with M;
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          134, 1),
    ]);
  }

  test_class_noSuperclassConstraint() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> {}
class C extends Object with M {}
''');
  }

  test_class_recursiveSubtypeCheck() async {
    // See dartbug.com/32353 for a detailed explanation.
    await assertErrorsInCode('''
class ioDirectory implements ioFileSystemEntity {}

class ioFileSystemEntity {}

abstract class _LocalDirectory
    extends _LocalFileSystemEntity<_LocalDirectory, ioDirectory>
    with ForwardingDirectory, DirectoryAddOnsMixin {}

abstract class _LocalFileSystemEntity<T extends FileSystemEntity,
  D extends ioFileSystemEntity> extends ForwardingFileSystemEntity<T, D> {}

abstract class FileSystemEntity implements ioFileSystemEntity {}

abstract class ForwardingFileSystemEntity<T extends FileSystemEntity,
  D extends ioFileSystemEntity> implements FileSystemEntity {}


mixin ForwardingDirectory<T extends Directory>
    on ForwardingFileSystemEntity<T, ioDirectory>
    implements Directory {}

abstract class Directory implements FileSystemEntity, ioDirectory {}

mixin DirectoryAddOnsMixin implements Directory {}
''', [
      error(HintCode.UNUSED_ELEMENT, 96, 15),
    ]);
    var mixins =
        result.unit.declaredElement!.getClass('_LocalDirectory')!.mixins;
    assertType(mixins[0], 'ForwardingDirectory<_LocalDirectory>');
  }

  test_classTypeAlias_generic() async {
    await assertErrorsInCode(r'''
class A<T> {}

mixin M on A<int> {}

class X = A<double> with M;
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          62, 1),
    ]);
  }

  test_classTypeAlias_noMatchingInterface() async {
    await assertErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C = Object with M;
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          78, 1),
    ]);
  }

  test_classTypeAlias_notGeneric() async {
    await assertErrorsInCode(r'''
class A {}

mixin M on A {}

class X = Object with M;
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          51, 1),
    ]);
  }

  test_classTypeAlias_OK_0() async {
    await assertNoErrorsInCode(r'''
mixin M {}

class X = Object with M;
''');
  }

  test_classTypeAlias_OK_1() async {
    await assertNoErrorsInCode(r'''
class A {}

mixin M on A {}

class X = A with M;
''');
  }

  test_classTypeAlias_OK_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}

mixin M<T> on A<T> {}

class B<T> implements A<T> {}

class C<T> = B<T> with M<T>;
''');
  }

  test_classTypeAlias_OK_previousMixin() async {
    await assertNoErrorsInCode(r'''
class A {}

mixin M1 implements A {}

mixin M2 on A {}

class X = Object with M1, M2;
''');
  }

  test_classTypeAlias_oneOfTwo() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class C {}

mixin M on A, B {}

class X = C with M;
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          71, 1),
    ]);
  }

  test_enum_matchingInterface_inPreviousMixin() async {
    await assertNoErrorsInCode('''
abstract class A {}

mixin M1 implements A {}

mixin M2 on A {}

enum E with M1, M2 {
  v
}
''');
  }

  test_enum_noMatchingInterface() async {
    await assertErrorsInCode('''
abstract class A {}

mixin M on A {}

enum E with M {
  v
}
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          50, 1),
    ]);
  }

  test_enum_noSuperclassConstraint() async {
    await assertNoErrorsInCode('''
mixin M {}

enum E with M {
  v;
}
''');
  }
}
