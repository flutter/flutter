// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/class_hierarchy.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassHierarchyTest);
    defineReflectiveTests(ClassHierarchyWithoutNullSafetyTest);
  });
}

@reflectiveTest
class ClassHierarchyTest extends AbstractTypeSystemTest
    with _AbstractClassHierarchyMixin {
  @override
  void setUp() {
    super.setUp();
    _createSharedElements();
  }

  test_invalid() {
    _checkA(
      typeArguments: [intNone, doubleNone],
      interfaces: ['A<int>'],
      errors: ['A<int> vs. A<double>'],
    );
  }

  test_valid_equal() {
    _checkA(
      typeArguments: [intNone, intNone],
      interfaces: ['A<int>'],
    );
  }

  test_valid_equal_neverNone() {
    _checkA(
      typeArguments: [neverNone, neverNone],
      interfaces: ['A<Never>'],
    );
  }

  test_valid_merge() {
    _checkA(
      typeArguments: [objectQuestion, dynamicNone],
      interfaces: ['A<Object?>'],
    );
  }
}

@reflectiveTest
class ClassHierarchyWithoutNullSafetyTest
    extends AbstractTypeSystemWithoutNullSafetyTest
    with _AbstractClassHierarchyMixin {
  @override
  void setUp() {
    super.setUp();
    _createSharedElements();
  }

  test_invalid() {
    _checkA(
      typeArguments: [intNone, doubleNone],
      interfaces: ['A<int*>'],
      errors: ['A<int*> vs. A<double*>'],
    );
  }

  test_valid() {
    _checkA(
      typeArguments: [intNone, intQuestion],
      interfaces: ['A<int*>'],
    );
  }
}

mixin _AbstractClassHierarchyMixin on ElementsTypesMixin {
  late ClassElementImpl A;

  void _assertErrors(List<ClassHierarchyError> errors, List<String> expected) {
    expect(
      errors.map((e) {
        if (e is IncompatibleInterfacesClassHierarchyError) {
          var firstStr = _interfaceString(e.first);
          var secondStr = _interfaceString(e.second);
          return '$firstStr vs. $secondStr';
        } else {
          throw UnimplementedError('${e.runtimeType}');
        }
      }).toList(),
      unorderedEquals(expected),
    );
  }

  void _assertInterfaces(
    List<InterfaceType> interfaces,
    List<String> expected,
  ) {
    var interfacesStr = interfaces.map(_interfaceString).toList();
    expect(interfacesStr, unorderedEquals(['Object', ...expected]));
  }

  void _checkA({
    required List<DartType> typeArguments,
    required List<String> interfaces,
    List<String> errors = const [],
  }) {
    var specifiedInterfaces = typeArguments
        .map((e) => interfaceTypeNone(A, typeArguments: [e]))
        .toList();
    var X = class_(name: 'X', interfaces: specifiedInterfaces);

    var classHierarchy = ClassHierarchy();

    var actualInterfaces = classHierarchy.implementedInterfaces(X);
    _assertInterfaces(actualInterfaces, interfaces);

    var actualErrors = classHierarchy.errors(X);
    _assertErrors(actualErrors, errors);
  }

  void _createSharedElements() {
    var T = typeParameter('T');
    A = class_(name: 'A', typeParameters: [T]);
  }

  String _interfaceString(InterfaceType interface) {
    return (interface as InterfaceTypeImpl)
        .withNullability(NullabilitySuffix.none)
        .getDisplayString(withNullability: true);
  }
}
