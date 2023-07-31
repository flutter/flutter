// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TryStatementTest);
  });
}

@reflectiveTest
class TryStatementTest extends PubPackageResolutionTest {
  test_catch_withoutType() async {
    await assertNoErrorsInCode(r'''
main() {
  try {} catch (e, st) {
    st;
  }
}
''');

    var e = findElement.localVar('e');
    expect(e.isFinal, isTrue);
    assertType(
      e.type,
      typeStringByNullability(nullable: 'Object', legacy: 'dynamic'),
    );

    var st = findElement.localVar('st');
    expect(st.isFinal, isTrue);
    assertType(st.type, 'StackTrace');

    var node = findNode.catchClause('catch');
    expect(node.exceptionParameter!.declaredElement, e);
    expect(node.stackTraceParameter!.declaredElement, st);
  }

  test_catch_withType() async {
    await assertNoErrorsInCode(r'''
main() {
  try {} on int catch (e, st) {
    st;
  }
}
''');

    var e = findElement.localVar('e');
    expect(e.isFinal, isTrue);
    assertType(e.type, 'int');

    var st = findElement.localVar('st');
    expect(st.isFinal, isTrue);
    assertType(st.type, 'StackTrace');

    var node = findNode.catchClause('catch');
    expect(node.exceptionParameter!.declaredElement, e);
    expect(node.stackTraceParameter!.declaredElement, st);
  }
}
