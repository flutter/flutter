// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexExpressionTest);
  });
}

@reflectiveTest
class IndexExpressionTest extends PubPackageResolutionTest {
  test_invalid_inDefaultValue_nullAware() async {
    await assertInvalidTestCode(r'''
void f({a = b?[0]}) {}
''');

    assertIndexExpression(
      findNode.index('[0]'),
      readElement: null,
      writeElement: null,
      type: 'dynamic',
    );
  }

  test_invalid_inDefaultValue_nullAware2() async {
    await assertInvalidTestCode(r'''
typedef void F({a = b?[0]});
''');

    assertIndexExpression(
      findNode.index('[0]'),
      readElement: null,
      writeElement: null,
      type: 'dynamic',
    );
  }

  test_read() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

void f(A a) {
  a[0];
}
''');

    var indexElement = findElement.method('[]');

    var indexExpression = findNode.index('a[0]');
    assertIndexExpression(
      indexExpression,
      readElement: indexElement,
      writeElement: null,
      type: 'bool',
    );
    assertParameterElement(
      indexExpression.index,
      indexElement.parameters[0],
    );
  }

  test_read_cascade_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

void f(A? a) {
  a?..[0]..[1];
}
''');

    var indexElement = findElement.method('[]');

    assertIndexExpression(
      findNode.index('..[0]'),
      readElement: indexElement,
      writeElement: null,
      type: 'bool',
    );

    assertIndexExpression(
      findNode.index('..[1]'),
      readElement: indexElement,
      writeElement: null,
      type: 'bool',
    );

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_read_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  T operator[](int index) => throw 42;
}

void f(A<double> a) {
  a[0];
}
''');

    var indexElement = findElement.method('[]');

    var indexExpression = findNode.index('a[0]');
    assertIndexExpression(
      indexExpression,
      readElement: elementMatcher(
        indexElement,
        substitution: {'T': 'double'},
      ),
      writeElement: null,
      type: 'double',
    );
    assertParameterElement(
      indexExpression.index,
      indexElement.parameters[0],
    );
  }

  test_read_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  bool operator[](int index) => false;
}

void f(A? a) {
  a?[0];
}
''');

    var indexElement = findElement.method('[]');

    var indexExpression = findNode.index('a?[0]');
    assertIndexExpression(
      indexExpression,
      readElement: indexElement,
      writeElement: null,
      type: 'bool?',
    );
  }

  test_readWrite_assignment() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
}

void f(A a) {
  a[0] += 1.2;
}
''');

    var indexElement = findElement.method('[]');
    var indexEqElement = findElement.method('[]=');
    var numPlusElement = numElement.getMethod('+')!;

    var indexExpression = findNode.index('a[0]');
    if (hasAssignmentLeftResolution) {
      assertIndexExpression(
        indexExpression,
        readElement: indexElement,
        writeElement: indexEqElement,
        type: 'num',
      );
    }
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      readElement: indexElement,
      readType: 'num',
      writeElement: indexEqElement,
      writeType: 'num',
      operatorElement: elementMatcher(
        numPlusElement,
        isLegacy: isLegacyLibrary,
      ),
      type: typeStringByNullability(nullable: 'double', legacy: 'num'),
    );
    assertParameterElement(
      assignment.rightHandSide,
      numPlusElement.parameters[0],
    );
  }

  test_readWrite_assignment_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  T operator[](int index) => throw 42;
  void operator[]=(int index, T value) {}
}

void f(A<double> a) {
  a[0] += 1.2;
}
''');

    var indexElement = findElement.method('[]');
    var indexEqElement = findElement.method('[]=');
    var doublePlusElement = doubleElement.getMethod('+')!;

    var indexExpression = findNode.index('a[0]');
    if (hasAssignmentLeftResolution) {
      assertIndexExpression(
        indexExpression,
        readElement: elementMatcher(
          indexElement,
          substitution: {'T': 'double'},
        ),
        writeElement: elementMatcher(
          indexEqElement,
          substitution: {'T': 'double'},
        ),
        type: 'double',
      );
    }
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      readElement: elementMatcher(
        indexElement,
        substitution: {'T': 'double'},
      ),
      readType: 'double',
      writeElement: elementMatcher(
        indexEqElement,
        substitution: {'T': 'double'},
      ),
      writeType: 'double',
      operatorElement: elementMatcher(
        doublePlusElement,
        isLegacy: isLegacyLibrary,
      ),
      type: 'double',
    );
    assertParameterElement(
      assignment.rightHandSide,
      doublePlusElement.parameters[0],
    );
  }

  test_readWrite_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  num operator[](int index) => 0;
  void operator[]=(int index, num value) {}
}

void f(A? a) {
  a?[0] += 1.2;
}
''');

    var indexElement = findElement.method('[]');
    var indexEqElement = findElement.method('[]=');
    var numPlusElement = numElement.getMethod('+')!;

    var indexExpression = findNode.index('a?[0]');
    if (hasAssignmentLeftResolution) {
      assertIndexExpression(
        indexExpression,
        readElement: indexElement,
        writeElement: indexEqElement,
        type: 'num',
      );
    }
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      readElement: indexElement,
      readType: 'num',
      writeElement: indexEqElement,
      writeType: 'num',
      operatorElement: numPlusElement,
      type: 'double?',
    );
    assertParameterElement(
      assignment.rightHandSide,
      numPlusElement.parameters[0],
    );
  }

  test_write() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, num value) {}
}

void f(A a) {
  a[0] = 1.2;
}
''');

    var indexEqElement = findElement.method('[]=');

    var indexExpression = findNode.index('a[0]');
    if (hasAssignmentLeftResolution) {
      assertIndexExpression(
        indexExpression,
        readElement: null,
        writeElement: indexEqElement,
        type: null,
      );
    }
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: indexEqElement,
      writeType: 'num',
      operatorElement: null,
      type: 'double',
    );
    assertParameterElement(
      assignment.rightHandSide,
      indexEqElement.parameters[1],
    );
  }

  test_write_cascade_nullShorting() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, A a) {}
}

void f(A? a) {
  a?..[0] = a..[1] = a;
}
''');

    var indexEqElement = findElement.method('[]=');

    assertAssignment(
      findNode.assignment('[0]'),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]='),
      writeType: 'A',
      operatorElement: null,
      type: 'A',
    );

    assertAssignment(
      findNode.assignment('[1]'),
      readElement: null,
      readType: null,
      writeElement: findElement.method('[]='),
      writeType: 'A',
      operatorElement: null,
      type: 'A',
    );

    if (hasAssignmentLeftResolution) {
      assertIndexExpression(
        findNode.index('..[0]'),
        readElement: null,
        writeElement: indexEqElement,
        type: null,
      );

      assertIndexExpression(
        findNode.index('..[1]'),
        readElement: null,
        writeElement: indexEqElement,
        type: null,
      );
    }

    assertType(findNode.cascade('a?'), 'A?');
  }

  test_write_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  void operator[]=(int index, T value) {}
}

void f(A<double> a) {
  a[0] = 1.2;
}
''');

    var indexEqElement = findElement.method('[]=');

    var indexExpression = findNode.index('a[0]');
    if (hasAssignmentLeftResolution) {
      assertIndexExpression(
        indexExpression,
        readElement: null,
        writeElement: elementMatcher(
          indexEqElement,
          substitution: {'T': 'double'},
        ),
        type: null,
      );
    }
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: elementMatcher(
        indexEqElement,
        substitution: {'T': 'double'},
      ),
      writeType: 'double',
      operatorElement: null,
      type: 'double',
    );
    assertParameterElement(
      assignment.rightHandSide,
      indexEqElement.parameters[1],
    );
  }

  test_write_nullable() async {
    await assertNoErrorsInCode(r'''
class A {
  void operator[]=(int index, num value) {}
}

void f(A? a) {
  a?[0] = 1.2;
}
''');

    var indexEqElement = findElement.method('[]=');

    var indexExpression = findNode.index('a?[0]');
    if (hasAssignmentLeftResolution) {
      assertIndexExpression(
        indexExpression,
        readElement: null,
        writeElement: indexEqElement,
        type: null,
      );
    }
    assertParameterElement(
      indexExpression.index,
      indexEqElement.parameters[0],
    );

    var assignment = indexExpression.parent as AssignmentExpression;
    assertAssignment(
      assignment,
      readElement: null,
      readType: null,
      writeElement: indexEqElement,
      writeType: 'num',
      operatorElement: null,
      type: 'double?',
    );
    assertParameterElement(
      assignment.rightHandSide,
      indexEqElement.parameters[1],
    );
  }
}
