// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';
import '../../../util/feature_sets.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementAnnotationImplTest);
    defineReflectiveTests(FieldElementImplTest);
    defineReflectiveTests(FunctionTypeImplTest);
    defineReflectiveTests(InterfaceTypeImplTest);
    defineReflectiveTests(MethodElementImplTest);
    defineReflectiveTests(TypeParameterTypeImplTest);
    defineReflectiveTests(VoidTypeImplTest);
    defineReflectiveTests(ClassElementImplTest);
    defineReflectiveTests(MixinElementImplTest);
    defineReflectiveTests(ElementLocationImplTest);
    defineReflectiveTests(ElementImplTest);
    defineReflectiveTests(TopLevelVariableElementImplTest);
    defineReflectiveTests(UniqueLocationTest);
  });
}

@reflectiveTest
class ClassElementImplTest extends AbstractTypeSystemTest {
  void test_getField() {
    var classA = class_(name: 'A');
    String fieldName = "f";
    FieldElementImpl field =
        ElementFactory.fieldElement(fieldName, false, false, false, intNone);
    classA.fields = [field];
    expect(classA.getField(fieldName), same(field));
    expect(field.isEnumConstant, false);
    // no such field
    expect(classA.getField("noSuchField"), isNull);
  }

  void test_getMethod_declared() {
    var classA = class_(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    expect(classA.getMethod(methodName), same(method));
  }

  void test_getMethod_undeclared() {
    var classA = class_(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    expect(classA.getMethod("${methodName}x"), isNull);
  }

  void test_hasNonFinalField_false_const() {
    var classA = class_(name: 'A');
    classA.fields = [
      ElementFactory.fieldElement(
          "f", false, false, true, interfaceTypeStar(classA))
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_final() {
    var classA = class_(name: 'A');
    classA.fields = [
      ElementFactory.fieldElement(
          "f", false, true, false, interfaceTypeStar(classA))
    ];
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_false_recursive() {
    var classA = class_(name: 'A');
    ClassElementImpl classB = class_(
      name: 'B',
      superType: interfaceTypeStar(classA),
    );
    classA.supertype = interfaceTypeStar(classB);
    expect(classA.hasNonFinalField, isFalse);
  }

  void test_hasNonFinalField_true_immediate() {
    var classA = class_(name: 'A');
    classA.fields = [
      ElementFactory.fieldElement(
          "f", false, false, false, interfaceTypeStar(classA))
    ];
    expect(classA.hasNonFinalField, isTrue);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  void test_hasNonFinalField_true_inherited() {
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.fields = [
      ElementFactory.fieldElement(
          "f", false, false, false, interfaceTypeStar(classA))
    ];
    expect(classB.hasNonFinalField, isTrue);
  }

  void test_isExhaustive() {
    var element = ElementFactory.classElement2("C");
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_base() {
    var element = ElementFactory.classElement4("C", isBase: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_final() {
    var element = ElementFactory.classElement4("C", isFinal: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_interface() {
    var element = ElementFactory.classElement4("C", isInterface: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_mixinClass() {
    var element = ElementFactory.classElement4("C", isMixinClass: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_sealed() {
    var element = ElementFactory.classElement4("C", isSealed: true);
    expect(element.isExhaustive, isTrue);
  }

  void test_isExtendableIn_base_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isBase: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isTrue);
  }

  void test_isExtendableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isBase: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement2("C");
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isTrue);
  }

  void test_isExtendableIn_final_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isFalse);
  }

  void test_isExtendableIn_final_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_interface_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isFalse);
  }

  void test_isExtendableIn_interface_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_mixinClass_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isTrue);
  }

  void test_isExtendableIn_mixinClass_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement2("C");
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isExtendableIn_sealed_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isExtendableIn(library2), isFalse);
  }

  void test_isExtendableIn_sealed_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isExtendableIn(library), isTrue);
  }

  void test_isImplementableIn_base_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isBase: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isBase: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement2("C");
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_final_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_final_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_interface_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_interface_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_mixinClass_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_mixinClass_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement2("C");
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_sealed_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_sealed_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isImplementableIn(library), isTrue);
  }

  void test_isMixableIn_base_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isBase: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isBase: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement2("C");
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_differentLibrary_oldVersion() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.language_2_19);
    var classElement = ElementFactory.classElement2("C");
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isTrue);
  }

  void test_isMixableIn_final_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_final_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isFinal: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_interface_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_interface_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isInterface: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_mixinClass_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isTrue);
  }

  void test_isMixableIn_mixinClass_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isMixinClass: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement2("C");
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_sealed_differentLibrary() {
    LibraryElementImpl library1 = ElementFactory.library(
        analysisContext, "lib1",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_sealed_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib",
        featureSet: FeatureSets.latestWithExperiments);
    var classElement = ElementFactory.classElement4("C", isSealed: true);
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isMixableIn(library), isTrue);
  }

  void test_lookUpConcreteMethod_declared() {
    // class A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_declaredAbstract() {
    // class A {
    //   m();
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElementImpl method =
        ElementFactory.methodElement(methodName, intNone);
    method.isAbstract = true;
    classA.methods = [method];
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpConcreteMethod(methodName, library), isNull);
  }

  void test_lookUpConcreteMethod_declaredAbstractAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m();
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    var inheritedMethod = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    MethodElementImpl method =
        ElementFactory.methodElement(methodName, intNone);
    method.isAbstract = true;
    classB.methods = [method];
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpConcreteMethod_declaredAndInherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    var inheritedMethod = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    var method = ElementFactory.methodElement(methodName, intNone);
    classB.methods = [method];
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_declaredAndInheritedAbstract() {
    // abstract class A {
    //   m();
    // }
    // class B extends A {
    //   m() {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    classA.isAbstract = true;
    String methodName = "m";
    MethodElementImpl inheritedMethod =
        ElementFactory.methodElement(methodName, intNone);
    inheritedMethod.isAbstract = true;
    classA.methods = [inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    var method = ElementFactory.methodElement(methodName, intNone);
    classB.methods = [method];
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library), same(method));
  }

  void test_lookUpConcreteMethod_inherited() {
    // class A {
    //   m() {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    var inheritedMethod = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [inheritedMethod];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classB.lookUpConcreteMethod(methodName, library),
        same(inheritedMethod));
  }

  void test_lookUpConcreteMethod_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpConcreteMethod("m", library), isNull);
  }

  void test_lookUpGetter_declared() {
    // class A {
    //   get g {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String getterName = "g";
    var getter = ElementFactory.getterElement(getterName, false, intNone);
    classA.accessors = [getter];
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_inherited() {
    // class A {
    //   get g {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String getterName = "g";
    var getter = ElementFactory.getterElement(getterName, false, intNone);
    classA.accessors = [getter];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classB.lookUpGetter(getterName, library), same(getter));
  }

  void test_lookUpGetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpGetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classA.lookUpGetter("g", library), isNull);
  }

  void test_lookUpMethod_declared() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_inherited() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String methodName = "m";
    var method = ElementFactory.methodElement(methodName, intNone);
    classA.methods = [method];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classB.lookUpMethod(methodName, library), same(method));
  }

  void test_lookUpMethod_undeclared() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpMethod_undeclared_recursive() {
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classA.lookUpMethod("m", library), isNull);
  }

  void test_lookUpSetter_declared() {
    // class A {
    //   set g(x) {}
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String setterName = "s";
    var setter = ElementFactory.setterElement(setterName, false, intNone);
    classA.accessors = [setter];
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_inherited() {
    // class A {
    //   set g(x) {}
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    String setterName = "s";
    var setter = ElementFactory.setterElement(setterName, false, intNone);
    classA.accessors = [setter];
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classB.lookUpSetter(setterName, library), same(setter));
  }

  void test_lookUpSetter_undeclared() {
    // class A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    (library.definingCompilationUnit).classes = [classA];
    expect(classA.lookUpSetter("s", library), isNull);
  }

  void test_lookUpSetter_undeclared_recursive() {
    // class A extends B {
    // }
    // class B extends A {
    // }
    LibraryElementImpl library = _newLibrary();
    var classA = class_(name: 'A');
    ClassElementImpl classB =
        ElementFactory.classElement("B", interfaceTypeStar(classA));
    classA.supertype = interfaceTypeStar(classB);
    (library.definingCompilationUnit).classes = [classA, classB];
    expect(classA.lookUpSetter("s", library), isNull);
  }

  LibraryElementImpl _newLibrary() =>
      ElementFactory.library(analysisContext, 'lib');
}

@reflectiveTest
class ElementAnnotationImplTest extends PubPackageResolutionTest {
  test_computeConstantValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final String f;
  const A(this.f);
}
void f(@A('x') int p) {}
''');
    await resolveTestCode(r'''
import 'a.dart';
main() {
  f(3);
}
''');
    var argument = findNode.integerLiteral('3');
    ParameterElement parameter = argument.staticParameterElement!;

    ElementAnnotation annotation = parameter.metadata[0];

    DartObject value = annotation.computeConstantValue()!;
    expect(value.getField('f')!.toStringValue(), 'x');
  }
}

@reflectiveTest
class ElementImplTest extends AbstractTypeSystemTest {
  void test_equals() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    ClassElementImpl classElement = ElementFactory.classElement2("C");
    (library.definingCompilationUnit).classes = [classElement];
    var field = ElementFactory.fieldElement(
      "next",
      false,
      false,
      false,
      classElement.instantiate(
        typeArguments: [],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
    classElement.fields = [field];
    expect(field == field, isTrue);
    // ignore: unrelated_type_equality_checks
    expect(field == field.getter, isFalse);
    // ignore: unrelated_type_equality_checks
    expect(field == field.setter, isFalse);
    expect(field.getter == field.setter, isFalse);
  }

  void test_isAccessibleIn_private_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement2("_C");
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isAccessibleIn(library2), isFalse);
  }

  void test_isAccessibleIn_private_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement2("_C");
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isAccessibleIn_public_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var classElement = ElementFactory.classElement2("C");
    (library1.definingCompilationUnit).classes = [classElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(classElement.isAccessibleIn(library2), isTrue);
  }

  void test_isAccessibleIn_public_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var classElement = ElementFactory.classElement2("C");
    (library.definingCompilationUnit).classes = [classElement];
    expect(classElement.isAccessibleIn(library), isTrue);
  }

  void test_isPrivate_false() {
    Element element = ElementFactory.classElement2("C");
    expect(element.isPrivate, isFalse);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  void test_isPrivate_null() {
    Element element = ElementFactory.classElement2('A');
    expect(element.isPrivate, isTrue);
  }

  void test_isPrivate_true() {
    Element element = ElementFactory.classElement2("_C");
    expect(element.isPrivate, isTrue);
  }

  void test_isPublic_false() {
    Element element = ElementFactory.classElement2("_C");
    expect(element.isPublic, isFalse);
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  void test_isPublic_null() {
    Element element = ElementFactory.classElement2('A');
    expect(element.isPublic, isFalse);
  }

  void test_isPublic_true() {
    Element element = ElementFactory.classElement2("C");
    expect(element.isPublic, isTrue);
  }
}

@reflectiveTest
class ElementLocationImplTest {
  void test_create_encoding() {
    String encoding = "a;b;c";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  /// For example unnamed constructor.
  void test_create_encoding_emptyLast() {
    String encoding = "a;b;c;";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  void test_equals_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = ElementLocationImpl.con2(encoding);
    expect(first == second, isTrue);
  }

  void test_equals_notEqual_differentLengths() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = ElementLocationImpl.con2("a;b;c;d");
    expect(first == second, isFalse);
  }

  void test_equals_notEqual_notLocation() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    // ignore: unrelated_type_equality_checks
    expect(first == "a;b;d", isFalse);
  }

  void test_equals_notEqual_sameLengths() {
    ElementLocationImpl first = ElementLocationImpl.con2("a;b;c");
    ElementLocationImpl second = ElementLocationImpl.con2("a;b;d");
    expect(first == second, isFalse);
  }

  void test_getComponents() {
    String encoding = "a;b;c";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    List<String> components = location.components;
    expect(components, hasLength(3));
    expect(components[0], "a");
    expect(components[1], "b");
    expect(components[2], "c");
  }

  void test_getEncoding() {
    String encoding = "a;b;c;;d";
    ElementLocationImpl location = ElementLocationImpl.con2(encoding);
    expect(location.encoding, encoding);
  }

  void test_hashCode_equal() {
    String encoding = "a;b;c";
    ElementLocationImpl first = ElementLocationImpl.con2(encoding);
    ElementLocationImpl second = ElementLocationImpl.con2(encoding);
    expect(first.hashCode == second.hashCode, isTrue);
  }
}

@reflectiveTest
class FieldElementImplTest extends PubPackageResolutionTest {
  test_isEnumConstant() async {
    await resolveTestCode(r'''
enum B {B1, B2, B3}
''');
    var B = findElement.enum_('B');

    FieldElement b2Element = B.getField('B2')!;
    expect(b2Element.isEnumConstant, isTrue);

    FieldElement valuesElement = B.getField('values')!;
    expect(valuesElement.isEnumConstant, isFalse);
  }
}

@reflectiveTest
class FunctionTypeImplTest extends AbstractTypeSystemTest {
  void assertType(DartType type, String expected) {
    var typeStr = type.getDisplayString(withNullability: false);
    expect(typeStr, expected);
  }

  void test_getNamedParameterTypes_namedParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(name: 'a', type: intNone),
        namedParameter(name: 'b', type: doubleNone),
        namedParameter(name: 'c', type: stringNone),
      ],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(2));
    expect(types['b'], doubleNone);
    expect(types['c'], stringNone);
  }

  void test_getNamedParameterTypes_noNamedParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNamedParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [],
      returnType: voidNone,
    );
    Map<String, DartType> types = type.namedParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noNormalParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        positionalParameter(type: intNone),
        positionalParameter(type: doubleNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getNormalParameterTypes_normalParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(type: intNone),
        requiredParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.normalParameterTypes;
    expect(types, hasLength(2));
    expect(types[0], intNone);
    expect(types[1], doubleNone);
  }

  void test_getOptionalParameterTypes_noOptionalParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(name: 'a', type: intNone),
        namedParameter(name: 'b', type: doubleNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_noParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(0));
  }

  void test_getOptionalParameterTypes_optionalParameters() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [
        requiredParameter(type: intNone),
        positionalParameter(type: doubleNone),
        positionalParameter(type: stringNone),
      ],
      returnType: voidNone,
    );
    List<DartType> types = type.optionalParameterTypes;
    expect(types, hasLength(2));
    expect(types[0], doubleNone);
    expect(types[1], stringNone);
  }

  @deprecated
  void test_resolveToBound() {
    var type = functionTypeNone(
      typeFormals: [],
      parameters: [],
      returnType: voidNone,
    );

    // Returns this.
    expect(type.resolveToBound(objectNone), same(type));
  }
}

@reflectiveTest
class InterfaceTypeImplTest extends AbstractTypeSystemTest {
  void test_allSupertypes() {
    void check(InterfaceType type, List<String> expected) {
      var actual = type.allSupertypes.map((e) {
        return e.getDisplayString(
          withNullability: true,
        );
      }).toList()
        ..sort();
      expect(actual, expected);
    }

    check(objectNone, []);
    check(numNone, ['Comparable<num>', 'Object']);
    check(intNone, ['Comparable<num>', 'Object', 'num']);
    check(intQuestion, ['Comparable<num>?', 'Object?', 'num?']);
    check(intStar, ['Comparable<num>*', 'Object*', 'num*']);
    check(listNone(intQuestion), ['Iterable<int?>', 'Object']);
  }

  test_asInstanceOf_explicitGeneric() {
    // class A<E> {}
    // class B implements A<C> {}
    // class C {}
    var A = class_(name: 'A', typeParameters: [
      typeParameter('E'),
    ]);
    var B = class_(name: 'B');
    var C = class_(name: 'C');

    var AofC = A.instantiate(
      typeArguments: [
        interfaceTypeStar(C),
      ],
      nullabilitySuffix: NullabilitySuffix.star,
    );

    B.interfaces = <InterfaceType>[AofC];

    var targetType = interfaceTypeStar(B);
    var result = targetType.asInstanceOf(A);
    expect(result, AofC);
  }

  test_asInstanceOf_passThroughGeneric() {
    // class A<E> {}
    // class B<E> implements A<E> {}
    // class C {}
    var AE = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [AE]);

    var BE = typeParameter('E');
    var B = class_(
      name: 'B',
      typeParameters: [BE],
      interfaces: [
        A.instantiate(
          typeArguments: [typeParameterTypeStar(BE)],
          nullabilitySuffix: NullabilitySuffix.star,
        ),
      ],
    );

    var C = class_(name: 'C');

    var targetType = B.instantiate(
      typeArguments: [interfaceTypeStar(C)],
      nullabilitySuffix: NullabilitySuffix.star,
    );
    var result = targetType.asInstanceOf(A);
    expect(
      result,
      A.instantiate(
        typeArguments: [interfaceTypeStar(C)],
        nullabilitySuffix: NullabilitySuffix.star,
      ),
    );
  }

  void test_creation() {
    expect(interfaceTypeStar(class_(name: 'A')), isNotNull);
  }

  void test_getAccessors() {
    ClassElementImpl typeElement = class_(name: 'A');
    var getterG = ElementFactory.getterElement("g", false, intNone);
    var getterH = ElementFactory.getterElement("h", false, intNone);
    typeElement.accessors = [getterG, getterH];
    InterfaceType type = interfaceTypeStar(typeElement);
    expect(type.accessors.length, 2);
  }

  void test_getAccessors_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceType type = interfaceTypeStar(typeElement);
    expect(type.accessors.length, 0);
  }

  void test_getConstructors() {
    ClassElementImpl typeElement = class_(name: 'A');
    ConstructorElementImpl constructorOne =
        ElementFactory.constructorElement(typeElement, 'one', false);
    ConstructorElementImpl constructorTwo =
        ElementFactory.constructorElement(typeElement, 'two', false);
    typeElement.constructors = [constructorOne, constructorTwo];
    InterfaceType type = interfaceTypeStar(typeElement);
    expect(type.constructors, hasLength(2));
  }

  void test_getConstructors_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    typeElement.constructors = const <ConstructorElementImpl>[];
    InterfaceType type = interfaceTypeStar(typeElement);
    expect(type.constructors, isEmpty);
  }

  void test_getElement() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceType type = interfaceTypeStar(typeElement);
    expect(type.element, typeElement);
  }

  void test_getGetter_implemented() {
    //
    // class A { g {} }
    //
    var classA = class_(name: 'A');
    String getterName = "g";
    var getterG = ElementFactory.getterElement(getterName, false, intNone);
    classA.accessors = [getterG];
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getGetter(getterName), same(getterG));
  }

  void test_getGetter_parameterized() {
    //
    // class A<E> { E get g {} }
    //
    var AE = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [AE]);

    DartType typeAE = typeParameterTypeStar(AE);
    String getterName = "g";
    PropertyAccessorElementImpl getterG =
        ElementFactory.getterElement(getterName, false, typeAE);
    A.accessors = [getterG];
    //
    // A<I>
    //
    var I = interfaceTypeStar(class_(name: 'I'));
    var AofI = A.instantiate(
      typeArguments: [I],
      nullabilitySuffix: NullabilitySuffix.star,
    );

    PropertyAccessorElement getter = AofI.getGetter(getterName)!;
    expect(getter, isNotNull);
    FunctionType getterType = getter.type;
    expect(getterType.returnType, same(I));
  }

  void test_getGetter_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getGetter("g"), isNull);
  }

  void test_getInterfaces_nonParameterized() {
    //
    // class C implements A, B
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement2("B");
    InterfaceType typeB = interfaceTypeStar(classB);
    var classC = ElementFactory.classElement2("C");
    classC.interfaces = <InterfaceType>[typeA, typeB];
    List<InterfaceType> interfaces = interfaceTypeStar(classC).interfaces;
    expect(interfaces, hasLength(2));
    if (identical(interfaces[0], typeA)) {
      expect(interfaces[1], same(typeB));
    } else {
      expect(interfaces[0], same(typeB));
      expect(interfaces[1], same(typeA));
    }
  }

  void test_getInterfaces_parameterized() {
    //
    // class A<E>
    // class B<F> implements A<F>
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    var F = typeParameter('F');
    var B = class_(
      name: 'B',
      typeParameters: [F],
      interfaces: [
        A.instantiate(
          typeArguments: [typeParameterTypeStar(F)],
          nullabilitySuffix: NullabilitySuffix.star,
        )
      ],
    );
    //
    // B<I>
    //
    var typeI = interfaceTypeStar(class_(name: 'I'));
    var typeBI = interfaceTypeStar(B, typeArguments: [typeI]);

    List<InterfaceType> interfaces = typeBI.interfaces;
    expect(interfaces, hasLength(1));
    InterfaceType result = interfaces[0];
    expect(result.element, same(A));
    expect(result.typeArguments[0], same(typeI));
  }

  void test_getMethod_implemented() {
    //
    // class A { m() {} }
    //
    var classA = class_(name: 'A');
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, intNone);
    classA.methods = [methodM];
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getMethod(methodName), same(methodM));
  }

  void test_getMethod_parameterized_usesTypeParameter() {
    //
    // class A<E> { E m(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterTypeStar(E);
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, typeE, [typeE]);
    A.methods = [methodM];
    //
    // A<I>
    //
    var typeI = interfaceTypeStar(class_(name: 'I'));
    var typeAI = interfaceTypeStar(A, typeArguments: <DartType>[typeI]);
    var method = typeAI.getMethod(methodName)!;
    expect(method, isNotNull);
    FunctionType methodType = method.type;
    expect(methodType.returnType, same(typeI));
    List<DartType> parameterTypes = methodType.normalParameterTypes;
    expect(parameterTypes, hasLength(1));
    expect(parameterTypes[0], same(typeI));
  }

  void test_getMethod_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getMethod("m"), isNull);
  }

  void test_getMethods() {
    ClassElementImpl typeElement = class_(name: 'A');
    MethodElementImpl methodOne = ElementFactory.methodElement("one", intNone);
    MethodElementImpl methodTwo = ElementFactory.methodElement("two", intNone);
    typeElement.methods = [methodOne, methodTwo];
    InterfaceType type = interfaceTypeStar(typeElement);
    expect(type.methods.length, 2);
  }

  void test_getMethods_empty() {
    ClassElementImpl typeElement = class_(name: 'A');
    InterfaceType type = interfaceTypeStar(typeElement);
    expect(type.methods.length, 0);
  }

  void test_getMixins_nonParameterized() {
    //
    // class C extends Object with A, B
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement2("B");
    InterfaceType typeB = interfaceTypeStar(classB);
    var classC = ElementFactory.classElement2("C");
    classC.mixins = <InterfaceType>[typeA, typeB];
    List<InterfaceType> interfaces = interfaceTypeStar(classC).mixins;
    expect(interfaces, hasLength(2));
    if (identical(interfaces[0], typeA)) {
      expect(interfaces[1], same(typeB));
    } else {
      expect(interfaces[0], same(typeB));
      expect(interfaces[1], same(typeA));
    }
  }

  void test_getMixins_parameterized() {
    //
    // class A<E>
    // class B<F> extends Object with A<F>
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);

    var F = typeParameter('F');
    var B = class_(
      name: 'B',
      typeParameters: [F],
      mixins: [
        interfaceTypeStar(A, typeArguments: [
          typeParameterTypeStar(F),
        ]),
      ],
    );
    //
    // B<I>
    //
    InterfaceType typeI = interfaceTypeStar(class_(name: 'I'));
    var typeBI = interfaceTypeStar(B, typeArguments: <DartType>[typeI]);
    List<InterfaceType> interfaces = typeBI.mixins;
    expect(interfaces, hasLength(1));
    InterfaceType result = interfaces[0];
    expect(result.element, same(A));
    expect(result.typeArguments[0], same(typeI));
  }

  void test_getSetter_implemented() {
    //
    // class A { s() {} }
    //
    var classA = class_(name: 'A');
    String setterName = "s";
    var setterS = ElementFactory.setterElement(setterName, false, intNone);
    classA.accessors = [setterS];
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getSetter(setterName), same(setterS));
  }

  void test_getSetter_parameterized() {
    //
    // class A<E> { set s(E p) {} }
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);
    DartType typeE = typeParameterTypeStar(E);
    String setterName = "s";
    PropertyAccessorElementImpl setterS =
        ElementFactory.setterElement(setterName, false, typeE);
    A.accessors = [setterS];
    //
    // A<I>
    //
    var typeI = interfaceTypeStar(class_(name: 'I'));
    var typeAI = interfaceTypeStar(A, typeArguments: <DartType>[typeI]);
    PropertyAccessorElement setter = typeAI.getSetter(setterName)!;
    expect(setter, isNotNull);
    FunctionType setterType = setter.type;
    List<DartType> parameterTypes = setterType.normalParameterTypes;
    expect(parameterTypes, hasLength(1));
    expect(parameterTypes[0], same(typeI));
  }

  void test_getSetter_unimplemented() {
    //
    // class A {}
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(typeA.getSetter("s"), isNull);
  }

  void test_getSuperclass_nonParameterized() {
    //
    // class B extends A
    //
    var classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    var classB = ElementFactory.classElement("B", typeA);
    InterfaceType typeB = interfaceTypeStar(classB);
    expect(typeB.superclass, same(typeA));
  }

  void test_getSuperclass_parameterized() {
    //
    // class A<E>
    // class B<F> extends A<F>
    //
    var E = typeParameter('E');
    var A = class_(name: 'A', typeParameters: [E]);

    var F = typeParameter('F');
    var typeF = typeParameterTypeStar(F);

    var B = class_(
      name: 'B',
      typeParameters: [F],
      superType: interfaceTypeStar(A, typeArguments: [typeF]),
    );

    var classB = B;
    //
    // B<I>
    //
    var typeI = interfaceTypeStar(class_(name: 'I'));
    var typeBI = interfaceTypeStar(classB, typeArguments: <DartType>[typeI]);
    InterfaceType superclass = typeBI.superclass!;
    expect(superclass.element, same(A));
    expect(superclass.typeArguments[0], same(typeI));
  }

  void test_getTypeArguments_empty() {
    InterfaceType type = interfaceTypeStar(ElementFactory.classElement2('A'));
    expect(type.typeArguments, hasLength(0));
  }

  void test_hashCode() {
    ClassElement classA = class_(name: 'A');
    InterfaceType typeA = interfaceTypeStar(classA);
    expect(0 == typeA.hashCode, isFalse);
  }

  @deprecated
  void test_resolveToBound() {
    var type = interfaceTypeStar(ElementFactory.classElement2('A'));

    // Returns this.
    expect(type.resolveToBound(objectNone), same(type));
  }
}

@reflectiveTest
class MethodElementImplTest extends AbstractTypeSystemTest {
  void test_equal() {
    var foo = method('foo', intNone);
    var T = typeParameter('T');
    var A = class_(
      name: 'A',
      typeParameters: [T],
      methods: [foo],
    );

    // MethodElementImpl is equal to itself.
    expect(foo == foo, isTrue);

    // MethodMember is not equal to MethodElementImpl.
    var foo_int = A.instantiate(
      typeArguments: [intNone],
      nullabilitySuffix: NullabilitySuffix.none,
    ).getMethod('foo')!;
    expect(foo == foo_int, isFalse);
    expect(foo_int == foo, isFalse);
  }
}

@reflectiveTest
class MixinElementImplTest extends AbstractTypeSystemTest {
  void test_isExhaustive() {
    var element = ElementFactory.mixinElement2("C");
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_base() {
    var element = ElementFactory.mixinElement2("C", isBase: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_final() {
    var element = ElementFactory.mixinElement2("C", isFinal: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_interface() {
    var element = ElementFactory.mixinElement2("C", isInterface: true);
    expect(element.isExhaustive, isFalse);
  }

  void test_isExhaustive_sealed() {
    var element = ElementFactory.mixinElement2("C", isSealed: true);
    expect(element.isExhaustive, isTrue);
  }

  void test_isImplementableIn_base_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C", isBase: true);
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C", isBase: true);
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C");
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_final_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C", isFinal: true);
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_final_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C", isFinal: true);
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_interface_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C", isInterface: true);
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isImplementableIn(library2), isTrue);
  }

  void test_isImplementableIn_interface_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C", isInterface: true);
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C");
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isImplementableIn(library), isTrue);
  }

  void test_isImplementableIn_sealed_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C", isSealed: true);
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isImplementableIn(library2), isFalse);
  }

  void test_isImplementableIn_sealed_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C", isSealed: true);
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isImplementableIn(library), isTrue);
  }

  void test_isMixableIn_base_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C", isBase: true);
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isMixableIn(library2), isTrue);
  }

  void test_isMixableIn_base_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C", isBase: true);
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement(name: "C");
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isMixableIn(library2), isTrue);
  }

  void test_isMixableIn_final_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C", isFinal: true);
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_final_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C", isFinal: true);
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_interface_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C", isInterface: true);
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_interface_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C", isInterface: true);
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement(name: "C");
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isMixableIn(library), isTrue);
  }

  void test_isMixableIn_sealed_differentLibrary() {
    LibraryElementImpl library1 =
        ElementFactory.library(analysisContext, "lib1");
    var mixinElement = ElementFactory.mixinElement2("C", isSealed: true);
    (library1.definingCompilationUnit).mixins = [mixinElement];
    LibraryElementImpl library2 =
        ElementFactory.library(analysisContext, "lib2");
    expect(mixinElement.isMixableIn(library2), isFalse);
  }

  void test_isMixableIn_sealed_sameLibrary() {
    LibraryElementImpl library = ElementFactory.library(analysisContext, "lib");
    var mixinElement = ElementFactory.mixinElement2("C", isSealed: true);
    (library.definingCompilationUnit).mixins = [mixinElement];
    expect(mixinElement.isMixableIn(library), isTrue);
  }
}

@reflectiveTest
class TopLevelVariableElementImplTest extends PubPackageResolutionTest {
  test_computeConstantValue() async {
    newFile('$testPackageLibPath/a.dart', r'''
const int C = 42;
''');
    await resolveTestCode(r'''
import 'a.dart';
main() {
  print(C);
}
''');
    SimpleIdentifier argument = findNode.simple('C);');
    var getter = argument.staticElement as PropertyAccessorElementImpl;
    var constant = getter.variable as TopLevelVariableElement;

    DartObject value = constant.computeConstantValue()!;
    expect(value, isNotNull);
    expect(value.toIntValue(), 42);
  }
}

@reflectiveTest
class TypeParameterTypeImplTest extends AbstractTypeSystemTest {
  void test_asInstanceOf_hasBound_element() {
    var T = typeParameter('T', bound: listNone(intNone));
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement,
      'Iterable<int>',
    );
  }

  void test_asInstanceOf_hasBound_element_noMatch() {
    var T = typeParameter('T', bound: numNone);
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement,
      null,
    );
  }

  void test_asInstanceOf_hasBound_promoted() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(
        T,
        promotedBound: listNone(intNone),
      ),
      typeProvider.iterableElement,
      'Iterable<int>',
    );
  }

  void test_asInstanceOf_hasBound_promoted_noMatch() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(
        T,
        promotedBound: numNone,
      ),
      typeProvider.iterableElement,
      null,
    );
  }

  void test_asInstanceOf_noBound() {
    var T = typeParameter('T');
    _assert_asInstanceOf(
      typeParameterTypeNone(T),
      typeProvider.iterableElement,
      null,
    );
  }

  void test_creation() {
    expect(typeParameterTypeStar(TypeParameterElementImpl('E', -1)), isNotNull);
  }

  void test_getElement() {
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    TypeParameterTypeImpl type = typeParameterTypeStar(element);
    expect(type.element, element);
  }

  @deprecated
  void test_resolveToBound_bound() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeStar(classS);
    TypeParameterTypeImpl type = typeParameterTypeStar(element);
    expect(type.resolveToBound(objectNone), interfaceTypeStar(classS));
  }

  @deprecated
  void test_resolveToBound_bound_nullableInner() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeQuestion(classS);
    TypeParameterTypeImpl type = typeParameterTypeStar(element);
    expect(type.resolveToBound(objectNone), same(element.bound));
  }

  @deprecated
  void test_resolveToBound_bound_nullableInnerOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeQuestion(classS);
    var type = typeParameterTypeStar(element)
        .withNullability(NullabilitySuffix.question);
    expect(type.resolveToBound(objectNone), same(element.bound));
  }

  @deprecated
  void test_resolveToBound_bound_nullableInnerStarOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeQuestion(classS);
    var type = typeParameterTypeStar(element)
        .withNullability(NullabilitySuffix.question);
    expect(
        type.resolveToBound(objectNone), equals(interfaceTypeQuestion(classS)));
  }

  @deprecated
  void test_resolveToBound_bound_nullableOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeStar(classS);
    var type = typeParameterTypeStar(element)
        .withNullability(NullabilitySuffix.question);
    expect(
        type.resolveToBound(objectNone), equals(interfaceTypeQuestion(classS)));
  }

  @deprecated
  void test_resolveToBound_bound_starInner() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeStar(classS);
    var type = typeParameterTypeStar(element);
    expect(type.resolveToBound(objectNone), same(element.bound));
  }

  @deprecated
  void test_resolveToBound_bound_starInnerNullableOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeQuestion(classS);
    var type =
        typeParameterTypeStar(element).withNullability(NullabilitySuffix.star);
    expect(type.resolveToBound(objectNone), same(element.bound));
  }

  @deprecated
  void test_resolveToBound_bound_starOuter() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl element = TypeParameterElementImpl('E', -1);
    element.bound = interfaceTypeStar(classS);
    var type =
        typeParameterTypeStar(element).withNullability(NullabilitySuffix.star);
    expect(type.resolveToBound(objectNone), interfaceTypeStar(classS));
  }

  @deprecated
  void test_resolveToBound_nestedBound() {
    ClassElementImpl classS = class_(name: 'A');
    TypeParameterElementImpl elementE = TypeParameterElementImpl('E', -1);
    elementE.bound = interfaceTypeStar(classS);
    TypeParameterTypeImpl typeE = typeParameterTypeStar(elementE);
    TypeParameterElementImpl elementF = TypeParameterElementImpl('F', -1);
    elementF.bound = typeE;
    TypeParameterTypeImpl typeF = typeParameterTypeStar(elementE);
    expect(typeF.resolveToBound(objectNone), interfaceTypeStar(classS));
  }

  @deprecated
  void test_resolveToBound_promotedBound_interfaceType() {
    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var T = typeParameter('T');
    var T_A = typeParameterTypeNone(T, promotedBound: A_none);
    expect(T_A.resolveToBound(objectQuestion), A_none);
  }

  @deprecated
  void test_resolveToBound_promotedBound_typeParameterType_interfaceType() {
    var A = class_(name: 'A');
    var A_none = interfaceTypeNone(A);

    var T = typeParameter('T', bound: A_none);
    var T_none = typeParameterTypeNone(T);

    var U = typeParameter('U');
    var U_T = typeParameterTypeNone(U, promotedBound: T_none);
    expect(U_T.resolveToBound(objectQuestion), A_none);
  }

  @deprecated
  void test_resolveToBound_unbound() {
    TypeParameterTypeImpl type =
        typeParameterTypeStar(TypeParameterElementImpl('E', -1));
    // Returns whatever type is passed to resolveToBound().
    expect(type.resolveToBound(VoidTypeImpl.instance),
        same(VoidTypeImpl.instance));
  }

  void _assert_asInstanceOf(
    DartType type,
    ClassElement element,
    String? expected,
  ) {
    var result = (type as TypeImpl).asInstanceOf(element);
    expect(
      result?.getDisplayString(withNullability: true),
      expected,
    );
  }
}

@reflectiveTest
class UniqueLocationTest extends PubPackageResolutionTest {
  test_ambiguous_closure_in_executable() async {
    await resolveTestCode('''
void f() => [() => 0, () => 1];
''');
    expect(
        findNode.functionExpression('() => 0').declaredElement!.location,
        isNot(
            findNode.functionExpression('() => 1').declaredElement!.location));
  }

  test_ambiguous_closure_in_local_variable() async {
    await resolveTestCode('''
void f() {
  var x = [() => 0, () => 1];
}
''');
    expect(
        findNode.functionExpression('() => 0').declaredElement!.location,
        isNot(
            findNode.functionExpression('() => 1').declaredElement!.location));
  }

  test_ambiguous_closure_in_top_level_variable() async {
    await resolveTestCode('''
var x = [() => 0, () => 1];
''');
    expect(
        findNode.functionExpression('() => 0').declaredElement!.location,
        isNot(
            findNode.functionExpression('() => 1').declaredElement!.location));
  }

  test_ambiguous_local_variable_in_executable() async {
    await resolveTestCode('''
f() {
  {
    int x = 0;
  }
  {
    int x = 1;
  }
}
''');
    expect(findNode.variableDeclaration('x = 0').declaredElement!.location,
        isNot(findNode.variableDeclaration('x = 1').declaredElement!.location));
  }
}

@reflectiveTest
class VoidTypeImplTest extends AbstractTypeSystemTest {
  /// Reference {code VoidTypeImpl.getInstance()}.
  final DartType _voidType = VoidTypeImpl.instance;

  void test_isVoid() {
    expect(_voidType.isVoid, isTrue);
  }

  @deprecated
  void test_resolveToBound() {
    // Returns this.
    expect(_voidType.resolveToBound(objectNone), same(_voidType));
  }
}
