// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(YieldStatementResolutionTest);
  });
}

@reflectiveTest
class YieldStatementResolutionTest extends PubPackageResolutionTest {
  @override
  setUp() {
    super.setUp();

    newFile('$testPackageLibPath/my_stream.dart', r'''
import 'dart:async';

export 'dart:async';

class MyStream<T> implements Stream<T> {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
''');
  }

  test_downInference_function_asyncStar() async {
    await assertNoErrorsInCode(r'''
import 'my_stream.dart';

Stream f1() async* {
  yield []; // 1
  yield* MyStream(); // 2
}

Stream<List<int>> f2() async* {
  yield []; // 3
  yield* MyStream(); // 4
}
''');
    assertType(
      findNode.listLiteral('[]; // 1'),
      'List<dynamic>',
    );

    assertType(
      findNode.instanceCreation('MyStream(); // 2'),
      'MyStream<dynamic>',
    );

    assertType(
      findNode.listLiteral('[]; // 3'),
      'List<int>',
    );

    assertType(
      findNode.instanceCreation('MyStream(); // 4'),
      'MyStream<List<int>>',
    );
  }

  test_downInference_function_syncStar() async {
    await assertNoErrorsInCode(r'''
Iterable f1() sync* {
  yield []; // 1
  yield* List.empty(); // 2
}

Iterable<List<int>> f2() sync* {
  yield []; // 3
  yield* List.empty(); // 4
}
''');
    assertType(
      findNode.listLiteral('[]; // 1'),
      'List<dynamic>',
    );

    assertType(
      findNode.instanceCreation('List.empty(); // 2'),
      'List<dynamic>',
    );

    assertType(
      findNode.listLiteral('[]; // 3'),
      'List<int>',
    );

    assertType(
      findNode.instanceCreation('List.empty(); // 4'),
      'List<List<int>>',
    );
  }

  test_downInference_functionExpression_asyncStar() async {
    await assertNoErrorsInCode(r'''
import 'my_stream.dart';

main() {
  Stream Function() f1 = () async* {
    yield []; // 1
    yield* MyStream(); // 2
  };
  f1;

  Stream<List<int>> Function() f2 = () async* {
    yield []; // 3
    yield* MyStream(); // 4
  };
  f2;
}
''');
    assertType(
      findNode.listLiteral('[]; // 1'),
      'List<dynamic>',
    );

    assertType(
      findNode.instanceCreation('MyStream(); // 2'),
      'MyStream<dynamic>',
    );

    assertType(
      findNode.listLiteral('[]; // 3'),
      'List<int>',
    );

    assertType(
      findNode.instanceCreation('MyStream(); // 4'),
      'MyStream<List<int>>',
    );
  }

  test_downInference_functionExpression_syncStar() async {
    await assertNoErrorsInCode(r'''
main() {
  Iterable Function() f1 = () sync* {
    yield []; // 1
    yield* List.empty(); // 2
  };
  f1;

  Iterable<List<int>> Function() f2 = () sync* {
    yield []; // 3
    yield* List.empty(); // 4
  };
  f2;
}
''');
    assertType(
      findNode.listLiteral('[]; // 1'),
      'List<dynamic>',
    );

    assertType(
      findNode.instanceCreation('List.empty(); // 2'),
      'List<dynamic>',
    );

    assertType(
      findNode.listLiteral('[]; // 3'),
      'List<int>',
    );

    assertType(
      findNode.instanceCreation('List.empty(); // 4'),
      'List<List<int>>',
    );
  }

  test_downInference_method_asyncStar() async {
    await assertNoErrorsInCode(r'''
import 'my_stream.dart';

class A {
  Stream m1() async* {
    yield []; // 1
    yield* MyStream(); // 2
  }

  Stream<List<int>> m2() async* {
    yield []; // 3
    yield* MyStream(); // 4
  }
}
''');
    assertType(
      findNode.listLiteral('[]; // 1'),
      'List<dynamic>',
    );

    assertType(
      findNode.instanceCreation('MyStream(); // 2'),
      'MyStream<dynamic>',
    );

    assertType(
      findNode.listLiteral('[]; // 3'),
      'List<int>',
    );

    assertType(
      findNode.instanceCreation('MyStream(); // 4'),
      'MyStream<List<int>>',
    );
  }

  test_downInference_method_syncStar() async {
    await assertNoErrorsInCode(r'''
class A {
  Iterable m1() sync* {
    yield []; // 1
    yield* List.empty(); // 2
  }

  Iterable<List<int>> m2() sync* {
    yield []; // 3
    yield* List.empty(); // 4
  }
}
''');
    assertType(
      findNode.listLiteral('[]; // 1'),
      'List<dynamic>',
    );

    assertType(
      findNode.instanceCreation('List.empty(); // 2'),
      'List<dynamic>',
    );

    assertType(
      findNode.listLiteral('[]; // 3'),
      'List<int>',
    );

    assertType(
      findNode.instanceCreation('List.empty(); // 4'),
      'List<List<int>>',
    );
  }
}
