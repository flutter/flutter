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
  test_matchingClass_inPreviousMixin_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M1 implements A<B> {}
mixin M2<T> on A<T> {}
class C extends Object with M1, M2 {}
''');
  }

  test_matchingClass_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends A<int> with M {}
''');
  }

  test_noMatchingClass_namedMixinApplication_new_syntax() async {
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

  test_noMatchingClass_new_syntax() async {
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

  test_noMatchingClass_noSuperclassConstraint_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> {}
class C extends Object with M {}
''');
  }

  test_noMatchingClass_typeParametersSupplied_new_syntax() async {
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

  test_recursiveSubtypeCheck_new_syntax() async {
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
        result.unit.declaredElement!.getType('_LocalDirectory')!.mixins;
    assertType(mixins[0], 'ForwardingDirectory<_LocalDirectory>');
  }
}
