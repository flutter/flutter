// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitInLateLocalVariableInitializerTest);
  });
}

@reflectiveTest
class AwaitInLateLocalVariableInitializerTest extends PubPackageResolutionTest {
  static const _errorCode =
      CompileTimeErrorCode.AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER;

  test_closure_late_await() async {
    await assertErrorsInCode('''
main() {
  var v = () async {
    late var v2 = await 42;
    print(v2);
  };
  print(v);
}
''', [
      error(_errorCode, 48, 5),
    ]);
  }

  test_late_await() async {
    await assertErrorsInCode('''
main() async {
  late var v = await 42;
  print(v);
}
''', [
      error(_errorCode, 30, 5),
    ]);
  }

  test_late_await_inClosure_blockBody() async {
    await assertNoErrorsInCode('''
main() async {
  late var v = () async {
    await 42;
  };
  print(v);
}
''');
  }

  test_late_await_inClosure_expressionBody() async {
    await assertNoErrorsInCode('''
main() async {
  late var v = () async => await 42;
  print(v);
}
''');
  }

  test_no_await() async {
    await assertNoErrorsInCode('''
main() async {
  late var v = 42;
  print(v);
}
''');
  }

  test_not_late() async {
    await assertNoErrorsInCode('''
main() async {
  var v = await 42;
  print(v);
}
''');
  }
}
