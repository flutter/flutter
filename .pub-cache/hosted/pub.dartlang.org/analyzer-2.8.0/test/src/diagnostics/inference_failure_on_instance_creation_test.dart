// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InferenceFailureOnInstanceCreationTest);
  });
}

@reflectiveTest
class InferenceFailureOnInstanceCreationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictInference: true,
      ),
    );
  }

  test_constructorNames_named() async {
    await assertErrorsInCode('''
import 'dart:collection';
void f() {
  HashMap.from({1: 1, 2: 2, 3: 3});
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 39, 12),
    ]);
    expect(result.errors[0].message, contains("'HashMap.from'"));
  }

  test_constructorNames_named_importPrefix() async {
    await assertErrorsInCode('''
import 'dart:collection' as c;
void f() {
  c.HashMap.from({1: 1, 2: 2, 3: 3});
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 44, 14),
    ]);
    expect(result.errors[0].message, contains("'c.HashMap.from'"));
  }

  test_constructorNames_unnamed() async {
    await assertErrorsInCode('''
import 'dart:collection';
void f() {
  HashMap();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 39, 7),
    ]);
    expect(result.errors[0].message, contains("'HashMap'"));
  }

  test_constructorNames_unnamed_importPrefix() async {
    await assertErrorsInCode('''
import 'dart:collection' as c;
void f() {
  c.HashMap();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 44, 9),
    ]);
    expect(result.errors[0].message, contains("'c.HashMap'"));
  }

  test_explicitTypeArgument() async {
    await assertNoErrorsInCode(r'''
import 'dart:collection';
void f() {
  HashMap<int, int>();
}
''');
  }

  test_genericMetadata_missingTypeArg() async {
    await assertErrorsInCode(r'''
class C<T> {
  const C();
}

@C()
void f() {}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 29, 4),
    ]);
  }

  test_genericMetadata_missingTypeArg_withoutGenericMetadata() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.12');
    await assertNoErrorsInCode(r'''
class C<T> {
  const C();
}

@C()
void f() {}
''');
  }

  test_genericMetadata_upwardsInference() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  final T f;
  const C(this.f);
}

@C(7)
void g() {}
''');
  }

  test_genericMetadata_withTypeArg() async {
    await assertNoErrorsInCode(r'''
class C<T> {
  const C();
}

@C<int>()
void f() {}
''');
  }

  test_missingTypeArgument_downwardInference() async {
    await assertNoErrorsInCode(r'''
import 'dart:collection';
HashMap<int, int> f() {
  return HashMap();
}
''');
  }

  test_missingTypeArgument_interfaceTypeTypedef_noInference() async {
    // `typedef A = HashMap;` means `typedef A = HashMap<dynamic, dynamic>;`.
    // So, there is no inference failure on `new A();`.
    await assertNoErrorsInCode(r'''
import 'dart:collection';
typedef A = HashMap;
void f() {
  A();
}
''');
  }

  test_missingTypeArgument_noInference() async {
    await assertErrorsInCode(r'''
import 'dart:collection';
void f() {
  HashMap();
}
''', [
      error(HintCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION, 39, 7),
    ]);
  }

  test_missingTypeArgument_noInference_optionalTypeArgs() async {
    writeTestPackageConfigWithMeta();
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';
@optionalTypeArgs
class C<T> {}
void f() {
  C();
}
''');
  }

  test_missingTypeArgument_upwardInference() async {
    await assertNoErrorsInCode(r'''
import 'dart:collection';
void f() {
  HashMap.of({1: 1, 2: 2, 3: 3});
}
''');
  }
}
