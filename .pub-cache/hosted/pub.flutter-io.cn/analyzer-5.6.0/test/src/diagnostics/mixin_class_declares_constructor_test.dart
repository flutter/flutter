// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinClassDeclaresConstructorTest);
  });
}

@reflectiveTest
class MixinClassDeclaresConstructorTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}
class B extends Object with A {}
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 49, 1),
      ],
    );
  }

  test_classTypeAlias() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}
class B = Object with A;
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 43, 1),
      ],
    );
  }

  test_enum() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}

enum E with A {
  v
}
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 34, 1),
      ],
    );
  }

  test_mixinClass_factory() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  A.named();
  factory A.x() = A.named;
}
class B with A {}
''');
  }

  test_mixinClass_factory_body() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  A.named();
  factory A.x() { return A.named(); }
}
class B with A {}
''');
  }

  test_mixinClass_nonTrivial_body() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  A() {}
}
class B with A {}
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 18, 1),
      ],
    );
  }

  test_mixinClass_nonTrivial_external() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  external A();
}
class B with A {}
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 27, 1),
      ],
    );
  }

  test_mixinClass_nonTrivial_parameter() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  final int foo;
  A(this.foo);
}
class B with A {}
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 35, 1),
      ],
    );
  }

  test_mixinClass_nonTrivial_super() async {
    await assertErrorsInCode(
      r'''
mixin class A {
  A(): super();
}
class B with A {}
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 18, 1),
      ],
    );
  }

  test_mixinClass_trivial() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  A();
}
class B with A {}
''');
  }

  test_mixinClass_trivial_const() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  const A();
}
class B with A {}
''');
  }

  test_mixinClass_trivial_named() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  A.named();
}
class B with A {}
''');
  }

  test_mixinClass_trivial_named_const() async {
    await assertNoErrorsInCode(r'''
mixin class A {
  const A.named();
}
class B with A {}
''');
  }
}
