// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImplicitDynamicFieldTest);
    defineReflectiveTests(ImplicitDynamicFieldWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ImplicitDynamicFieldTest extends PubPackageResolutionTest
    with ImplicitDynamicFieldTestCases {}

mixin ImplicitDynamicFieldTestCases on PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(implicitDynamic: false),
    );
  }

  test_instance_explicitDynamic_initialized() async {
    await assertNoErrorsInCode('''
class C {
  dynamic f = (<dynamic>[])[0];
}
''');
  }

  test_instance_explicitDynamic_uninitialized() async {
    await assertNoErrorsInCode('''
class C {
  dynamic f;
}
''');
  }

  test_instance_final_initialized() async {
    await assertErrorsInCode('''
class C {
  final f = (<dynamic>[])[0];
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 18, 20,
          messageContains: ["'f'"]),
    ]);
  }

  test_instance_final_uninitialized() async {
    await assertErrorsInCode('''
class C {
  final f;
  C(this.f);
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 18, 1),
    ]);
  }

  test_instance_var_initialized() async {
    await assertErrorsInCode('''
class C {
  var f = (<dynamic>[])[0];
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 16, 20),
    ]);
  }

  test_instance_var_initialized_inference() async {
    await assertNoErrorsInCode('''
class C {
  var f = 0;
}
''');
  }

  test_instance_var_uninitialized() async {
    await assertErrorsInCode('''
class C {
  var f;
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 16, 1),
    ]);
  }

  test_instance_var_uninitialized_multiple() async {
    await assertErrorsInCode('''
class C {
  var f, g = 42, h;
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 16, 1),
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 27, 1),
    ]);
  }

  test_static_var_initialized() async {
    await assertErrorsInCode('''
class C {
  static var f = (<dynamic>[])[0];
}
''', [
      error(LanguageCode.IMPLICIT_DYNAMIC_FIELD, 23, 20),
    ]);
  }
}

@reflectiveTest
class ImplicitDynamicFieldWithoutNullSafetyTest extends PubPackageResolutionTest
    with ImplicitDynamicFieldTestCases, WithoutNullSafetyMixin {}
