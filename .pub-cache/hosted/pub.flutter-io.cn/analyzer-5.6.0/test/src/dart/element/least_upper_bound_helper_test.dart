// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/least_upper_bound.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathToObjectTest);
    defineReflectiveTests(SuperinterfaceSetTest);
  });
}

@reflectiveTest
class PathToObjectTest extends AbstractTypeSystemTest {
  void test_class_mixins1() {
    var M1 = mixin_(name: 'M1');
    expect(_longestPathToObject(M1), 1);

    var A = class_(name: 'A');
    expect(_longestPathToObject(A), 1);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class X extends _X&A&M1 {}
    //    length: 3
    var X = class_(
      name: 'X',
      superType: interfaceTypeNone(A),
      mixins: [
        interfaceTypeNone(M1),
      ],
    );

    expect(_longestPathToObject(X), 3);
  }

  void test_class_mixins2() {
    var M1 = mixin_(name: 'M1');
    var M2 = mixin_(name: 'M2');
    expect(_longestPathToObject(M1), 1);
    expect(_longestPathToObject(M2), 1);

    var A = class_(name: 'A');
    expect(_longestPathToObject(A), 1);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class _X&A&M1&M2 extends _X&A&M1 implements M2 {}
    //    length: 3
    // class X extends _X&A&M1&M2 {}
    //    length: 4
    var X = class_(
      name: 'X',
      superType: interfaceTypeNone(A),
      mixins: [
        interfaceTypeNone(M1),
        interfaceTypeNone(M2),
      ],
    );

    expect(_longestPathToObject(X), 4);
  }

  void test_class_mixins_longerViaSecondMixin() {
    var I1 = class_(name: 'I1');
    var I2 = class_(name: 'I2', superType: interfaceTypeNone(I1));
    var I3 = class_(name: 'I3', superType: interfaceTypeNone(I2));

    expect(_longestPathToObject(I1), 1);
    expect(_longestPathToObject(I2), 2);
    expect(_longestPathToObject(I3), 3);

    var M1 = mixin_(name: 'M1');
    var M2 = mixin_(
      name: 'M2',
      interfaces: [interfaceTypeNone(I3)],
    );
    expect(_longestPathToObject(M1), 1);
    expect(_longestPathToObject(M2), 4);

    var A = class_(name: 'A'); // length: 1
    expect(_longestPathToObject(A), 1);

    // class _X&A&M1 extends A implements M1 {}
    //    length: 2
    // class _X&A&M1&M2 extends _X&A&M1 implements M2 {}
    //    length: 5 = max(1 + _X&A&M1, 1 + M2)
    // class X extends _X&A&M1&M2 {}
    //    length: 6
    var X = class_(
      name: 'X',
      superType: interfaceTypeNone(A),
      mixins: [
        interfaceTypeNone(M1),
        interfaceTypeNone(M2),
      ],
    );

    expect(_longestPathToObject(X), 6);
  }

  void test_class_multipleInterfacePaths() {
    //
    //   Object
    //     |
    //     A
    //    / \
    //   B   C
    //   |   |
    //   |   D
    //    \ /
    //     E
    //
    ClassElementImpl classA = class_(name: "A");
    ClassElementImpl classB = class_(name: "B");
    ClassElementImpl classC = class_(name: "C");
    ClassElementImpl classD = class_(name: "D");
    ClassElementImpl classE = class_(name: "E");
    classB.interfaces = <InterfaceType>[interfaceTypeStar(classA)];
    classC.interfaces = <InterfaceType>[interfaceTypeStar(classA)];
    classD.interfaces = <InterfaceType>[interfaceTypeStar(classC)];
    classE.interfaces = <InterfaceType>[
      interfaceTypeStar(classB),
      interfaceTypeStar(classD)
    ];
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE implements typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(_longestPathToObject(classB), 2);
    expect(_longestPathToObject(classE), 4);
  }

  void test_class_multipleSuperclassPaths() {
    //
    //   Object
    //     |
    //     A
    //    / \
    //   B   C
    //   |   |
    //   |   D
    //    \ /
    //     E
    //
    ClassElement classA = class_(name: "A");
    ClassElement classB =
        class_(name: "B", superType: interfaceTypeStar(classA));
    ClassElement classC =
        class_(name: "C", superType: interfaceTypeStar(classA));
    ClassElement classD =
        class_(name: "D", superType: interfaceTypeStar(classC));
    ClassElementImpl classE =
        class_(name: "E", superType: interfaceTypeStar(classB));
    classE.interfaces = <InterfaceType>[interfaceTypeStar(classD)];
    // assertion: even though the longest path to Object for typeB is 2, and
    // typeE extends typeB, the longest path for typeE is 4 since it also
    // implements typeD
    expect(_longestPathToObject(classB), 2);
    expect(_longestPathToObject(classE), 4);
  }

  void test_class_object() {
    expect(_longestPathToObject(typeProvider.objectType.element), 0);
  }

  void test_class_recursion() {
    ClassElementImpl classA = class_(name: "A");
    ClassElementImpl classB =
        class_(name: "B", superType: interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    expect(_longestPathToObject(classA), 2);
  }

  void test_class_singleInterfacePath() {
    //
    //   Object
    //     |
    //     A
    //     |
    //     B
    //     |
    //     C
    //
    ClassElementImpl classA = class_(name: "A");
    ClassElementImpl classB = class_(name: "B");
    ClassElementImpl classC = class_(name: "C");
    classB.interfaces = <InterfaceType>[interfaceTypeStar(classA)];
    classC.interfaces = <InterfaceType>[interfaceTypeStar(classB)];
    expect(_longestPathToObject(classA), 1);
    expect(_longestPathToObject(classB), 2);
    expect(_longestPathToObject(classC), 3);
  }

  void test_class_singleSuperclassPath() {
    //
    //   Object
    //     |
    //     A
    //     |
    //     B
    //     |
    //     C
    //
    ClassElement classA = class_(name: "A");
    ClassElement classB =
        class_(name: "B", superType: interfaceTypeStar(classA));
    ClassElement classC =
        class_(name: "C", superType: interfaceTypeStar(classB));
    expect(_longestPathToObject(classA), 1);
    expect(_longestPathToObject(classB), 2);
    expect(_longestPathToObject(classC), 3);
  }

  void test_mixin_constraints_interfaces_allSame() {
    var A = class_(name: 'A');
    var B = class_(name: 'B');
    var I = class_(name: 'I');
    var J = class_(name: 'J');
    expect(_longestPathToObject(A), 1);
    expect(_longestPathToObject(B), 1);
    expect(_longestPathToObject(I), 1);
    expect(_longestPathToObject(J), 1);

    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    var M = mixin_(
      name: 'M',
      constraints: [
        interfaceTypeNone(A),
        interfaceTypeNone(B),
      ],
      interfaces: [
        interfaceTypeNone(I),
        interfaceTypeNone(J),
      ],
    );
    expect(_longestPathToObject(M), 2);
  }

  void test_mixin_longerConstraint_1() {
    var A1 = class_(name: 'A1');
    var A = class_(
      name: 'A',
      superType: interfaceTypeNone(A1),
    );
    var B = class_(name: 'B');
    var I = class_(name: 'I');
    var J = class_(name: 'J');
    expect(_longestPathToObject(A), 2);
    expect(_longestPathToObject(B), 1);
    expect(_longestPathToObject(I), 1);
    expect(_longestPathToObject(J), 1);

    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    var M = mixin_(
      name: 'M',
      constraints: [
        interfaceTypeNone(A),
        interfaceTypeNone(B),
      ],
      interfaces: [
        interfaceTypeNone(I),
        interfaceTypeNone(J),
      ],
    );
    expect(_longestPathToObject(M), 3);
  }

  void test_mixin_longerConstraint_2() {
    var A = class_(name: 'A');
    var B1 = class_(name: 'B1');
    var B = class_(
      name: 'B',
      interfaces: [
        interfaceTypeNone(B1),
      ],
    );
    var I = class_(name: 'I');
    var J = class_(name: 'J');
    expect(_longestPathToObject(A), 1);
    expect(_longestPathToObject(B), 2);
    expect(_longestPathToObject(I), 1);
    expect(_longestPathToObject(J), 1);

    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    var M = mixin_(
      name: 'M',
      constraints: [
        interfaceTypeNone(A),
        interfaceTypeNone(B),
      ],
      interfaces: [
        interfaceTypeNone(I),
        interfaceTypeNone(J),
      ],
    );
    expect(_longestPathToObject(M), 3);
  }

  void test_mixin_longerInterface_1() {
    var A = class_(name: 'A');
    var B = class_(name: 'B');
    var I1 = class_(name: 'I1');
    var I = class_(
      name: 'I',
      interfaces: [
        interfaceTypeNone(I1),
      ],
    );
    var J = class_(name: 'J');
    expect(_longestPathToObject(A), 1);
    expect(_longestPathToObject(B), 1);
    expect(_longestPathToObject(I), 2);
    expect(_longestPathToObject(J), 1);

    // The interface of M is:
    // class _M&A&A implements A, B, I, J {}
    var M = mixin_(
      name: 'M',
      constraints: [
        interfaceTypeNone(A),
        interfaceTypeNone(B),
      ],
      interfaces: [
        interfaceTypeNone(I),
        interfaceTypeNone(J),
      ],
    );
    expect(_longestPathToObject(M), 3);
  }

  int _longestPathToObject(InterfaceElement element) {
    return InterfaceLeastUpperBoundHelper.computeLongestInheritancePathToObject(
        element);
  }
}

@reflectiveTest
class SuperinterfaceSetTest extends AbstractTypeSystemTest {
  void test_genericInterfacePath() {
    //
    //  A
    //  | implements
    //  B<T>
    //  | implements
    //  C<T>
    //
    //  D
    //

    var instObject = InstantiatedClass.of(typeProvider.objectType);

    ClassElementImpl classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var BT = typeParameter('T');
    var classB = class_(
      name: 'B',
      typeParameters: [BT],
      interfaces: [instA.withNullabilitySuffixNone],
    );

    var CT = typeParameter('T');
    var classC = class_(
      name: 'C',
      typeParameters: [CT],
      interfaces: [
        InstantiatedClass(
          classB,
          [typeParameterTypeStar(CT)],
        ).withNullabilitySuffixNone,
      ],
    );

    var classD = class_(name: 'D');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([instObject]),
    );

    // B<D>
    expect(
      _superInterfaces(
        InstantiatedClass(classB, [interfaceTypeStar(classD)]),
      ),
      unorderedEquals([instObject, instA]),
    );

    // C<D>
    expect(
      _superInterfaces(
        InstantiatedClass(classC, [interfaceTypeStar(classD)]),
      ),
      unorderedEquals([
        instObject,
        instA,
        InstantiatedClass(classB, [interfaceTypeStar(classD)]),
      ]),
    );
  }

  void test_genericSuperclassPath() {
    //
    //  A
    //  |
    //  B<T>
    //  |
    //  C<T>
    //
    //  D
    //

    var instObject = InstantiatedClass.of(typeProvider.objectType);

    ClassElementImpl classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = class_(
      name: 'B',
      typeParameters: [typeParameter('T')],
      superType: instA.withNullabilitySuffixNone,
    );

    var typeParametersC = ElementFactory.typeParameters(['T']);
    var classC = class_(
      name: 'B',
      typeParameters: typeParametersC,
      superType: InstantiatedClass(
        classB,
        [typeParameterTypeStar(typeParametersC[0])],
      ).withNullabilitySuffixNone,
    );

    var classD = class_(name: 'D');

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([instObject]),
    );

    // B<D>
    expect(
      _superInterfaces(
        InstantiatedClass(classB, [interfaceTypeStar(classD)]),
      ),
      unorderedEquals([instObject, instA]),
    );

    // C<D>
    expect(
      _superInterfaces(
        InstantiatedClass(classC, [interfaceTypeStar(classD)]),
      ),
      unorderedEquals([
        instObject,
        instA,
        InstantiatedClass(classB, [interfaceTypeStar(classD)]),
      ]),
    );
  }

  void test_mixin_constraints() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = class_(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = class_(name: 'C');
    var instC = InstantiatedClass(classC, const []);

    var mixinM = mixin_(
      name: 'M',
      constraints: [
        instB.withNullabilitySuffixNone,
        instC.withNullabilitySuffixNone,
      ],
    );
    var instM = InstantiatedClass(mixinM, const []);

    expect(
      _superInterfaces(instM),
      unorderedEquals([instObject, instA, instB, instC]),
    );
  }

  void test_mixin_constraints_object() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var mixinM = mixin_(name: 'M');
    var instM = InstantiatedClass(mixinM, const []);

    expect(
      _superInterfaces(instM),
      unorderedEquals([instObject]),
    );
  }

  void test_mixin_interfaces() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = class_(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = class_(name: 'C');
    var instC = InstantiatedClass(classC, const []);

    var mixinM = mixin_(
      name: 'M',
      interfaces: [
        instB.withNullabilitySuffixNone,
        instC.withNullabilitySuffixNone,
      ],
    );
    var instM = InstantiatedClass(mixinM, const []);

    expect(
      _superInterfaces(instM),
      unorderedEquals([instObject, instA, instB, instC]),
    );
  }

  void test_multipleInterfacePaths() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = class_(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = class_(
      name: 'C',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instC = InstantiatedClass(classC, const []);

    var classD = class_(
      name: 'D',
      interfaces: [instC.withNullabilitySuffixNone],
    );
    var instD = InstantiatedClass(classD, const []);

    var classE = class_(
      name: 'E',
      interfaces: [
        instB.withNullabilitySuffixNone,
        instD.withNullabilitySuffixNone,
      ],
    );
    var instE = InstantiatedClass(classE, const []);

    // D
    expect(
      _superInterfaces(instD),
      unorderedEquals([instObject, instA, instC]),
    );

    // E
    expect(
      _superInterfaces(instE),
      unorderedEquals([instObject, instA, instB, instC, instD]),
    );
  }

  void test_multipleSuperclassPaths() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = class_(
      name: 'B',
      superType: instA.withNullabilitySuffixNone,
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = class_(
      name: 'C',
      superType: instA.withNullabilitySuffixNone,
    );
    var instC = InstantiatedClass(classC, const []);

    var classD = class_(
      name: 'D',
      superType: instC.withNullabilitySuffixNone,
    );
    var instD = InstantiatedClass(classD, const []);

    var classE = class_(
      name: 'E',
      superType: instB.withNullabilitySuffixNone,
      interfaces: [
        instD.withNullabilitySuffixNone,
      ],
    );
    var instE = InstantiatedClass(classE, const []);

    // D
    expect(
      _superInterfaces(instD),
      unorderedEquals([instObject, instA, instC]),
    );

    // E
    expect(
      _superInterfaces(instE),
      unorderedEquals([instObject, instA, instB, instC, instD]),
    );
  }

  void test_recursion() {
    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = class_(
      name: 'B',
      superType: instA.withNullabilitySuffixNone,
    );
    var instB = InstantiatedClass(classB, const []);

    classA.supertype = instB.withNullabilitySuffixNone;

    expect(
      _superInterfaces(instB),
      unorderedEquals([instA, instB]),
    );

    expect(
      _superInterfaces(instA),
      unorderedEquals([instA, instB]),
    );
  }

  void test_singleInterfacePath() {
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = class_(
      name: 'B',
      interfaces: [instA.withNullabilitySuffixNone],
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = class_(
      name: 'C',
      interfaces: [instB.withNullabilitySuffixNone],
    );
    var instC = InstantiatedClass(classC, const []);

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([instObject]),
    );

    // B
    expect(
      _superInterfaces(instB),
      unorderedEquals([instObject, instA]),
    );

    // C
    expect(
      _superInterfaces(instC),
      unorderedEquals([instObject, instA, instB]),
    );
  }

  void test_singleSuperclassPath() {
    //
    //  A
    //  |
    //  B
    //  |
    //  C
    //
    var instObject = InstantiatedClass.of(typeProvider.objectType);

    var classA = class_(name: 'A');
    var instA = InstantiatedClass(classA, const []);

    var classB = class_(
      name: 'B',
      superType: instA.withNullabilitySuffixNone,
    );
    var instB = InstantiatedClass(classB, const []);

    var classC = class_(
      name: 'C',
      superType: instB.withNullabilitySuffixNone,
    );
    var instC = InstantiatedClass(classC, const []);

    // A
    expect(
      _superInterfaces(instA),
      unorderedEquals([instObject]),
    );

    // B
    expect(
      _superInterfaces(instB),
      unorderedEquals([instObject, instA]),
    );

    // C
    expect(
      _superInterfaces(instC),
      unorderedEquals([instObject, instA, instB]),
    );
  }

  Set<InstantiatedClass> _superInterfaces(InstantiatedClass type) {
    var helper = InterfaceLeastUpperBoundHelper(typeSystem);
    return helper.computeSuperinterfaceSet(type);
  }
}
