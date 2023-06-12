// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../summary/macros_environment.dart';
import 'context_collection_resolution.dart';

main() {
  try {
    MacrosEnvironment.instance;
  } catch (_) {
    print('Cannot initialize environment. Skip macros tests.');
    return;
  }

  defineReflectiveSuite(() {
    defineReflectiveTests(MacroResolutionTest);
  });
}

@reflectiveTest
class MacroResolutionTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      macrosEnvironment: MacrosEnvironment.instance,
    );
  }

  test_0() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'dart:async';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class EmptyMacro implements ClassTypesMacro {
  const EmptyMacro();

  FutureOr<void> buildTypesForClass(clazz, builder) {
    var targetName = clazz.identifier.name;
    builder.declareType(
      '${targetName}_Macro',
      DeclarationCode.fromString('class ${targetName}_Macro {}'),
    );
  }
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

@EmptyMacro()
class A {}

void f(A_Macro a) {}
''');
  }

  test_macroExecutionException_compileTimeError() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    unresolved;
  }
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [error(CompileTimeErrorCode.MACRO_EXECUTION_EXCEPTION, 18, 10)]);
  }

  test_macroExecutionException_throwsException() async {
    newFile('$testPackageLibPath/a.dart', r'''
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class MyMacro implements ClassTypesMacro {
  const MyMacro();

  buildTypesForClass(clazz, builder) {
    throw 42;
  }
}
''');

    await assertErrorsInCode('''
import 'a.dart';

@MyMacro()
class A {}
''', [error(CompileTimeErrorCode.MACRO_EXECUTION_EXCEPTION, 18, 10)]);
  }
}
