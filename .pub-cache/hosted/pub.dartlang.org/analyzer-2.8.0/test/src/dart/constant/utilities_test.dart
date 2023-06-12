// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstantFinderTest);
    defineReflectiveTests(ReferenceFinderTest);
  });
}

@reflectiveTest
class ConstantFinderTest {
  late final AstNode _node;
  late final TypeProvider _typeProvider;
  late final Source _source;

  void setUp() {
    _typeProvider = TestTypeProvider();
    _source = TestSource();
  }

  /// Test an annotation that consists solely of an identifier (and hence
  /// represents a reference to a compile-time constant variable).
  void test_visitAnnotation_constantVariable() {
    var compilationUnitElement =
        ElementFactory.compilationUnit('/test.dart', _source)..source = _source;
    ElementFactory.library(_AnalysisContextMock(), 'L')
        .definingCompilationUnit = compilationUnitElement;
    ElementAnnotationImpl elementAnnotation =
        ElementAnnotationImpl(compilationUnitElement);
    var annotation = AstTestFactory.annotation(AstTestFactory.identifier3('x'));
    _node = elementAnnotation.annotationAst = annotation
      ..elementAnnotation = elementAnnotation;
    expect(_findAnnotations(), contains(_node));
  }

  void test_visitAnnotation_enumConstant() {
    // Analyzer ignores annotations on enum constant declarations.
    Annotation annotation = AstTestFactory.annotation2(
        AstTestFactory.identifier3('A'), null, AstTestFactory.argumentList());
    _node = astFactory.enumConstantDeclaration(
        null, <Annotation>[annotation], AstTestFactory.identifier3('C'));
    expect(_findConstants(), isEmpty);
  }

  /// Test an annotation that represents the invocation of a constant
  /// constructor.
  void test_visitAnnotation_invocation() {
    var compilationUnitElement =
        ElementFactory.compilationUnit('/test.dart', _source)..source = _source;
    ElementFactory.library(_AnalysisContextMock(), 'L')
        .definingCompilationUnit = compilationUnitElement;
    ElementAnnotationImpl elementAnnotation =
        ElementAnnotationImpl(compilationUnitElement);
    var annotation = AstTestFactory.annotation2(
        AstTestFactory.identifier3('A'), null, AstTestFactory.argumentList());
    _node = elementAnnotation.annotationAst = annotation
      ..elementAnnotation = elementAnnotation;
    expect(_findAnnotations(), contains(_node));
  }

  void test_visitAnnotation_partOf() {
    // Analyzer ignores annotations on "part of" directives.
    Annotation annotation = AstTestFactory.annotation2(
        AstTestFactory.identifier3('A'), null, AstTestFactory.argumentList());
    _node = AstTestFactory.partOfDirective2(<Annotation>[annotation],
        AstTestFactory.libraryIdentifier2(<String>['L']));
    expect(_findConstants(), isEmpty);
  }

  void test_visitConstructorDeclaration_const() {
    ConstructorElement element = _setupConstructorDeclaration("A", true);
    expect(_findConstants(), contains(element));
  }

  void test_visitConstructorDeclaration_nonConst() {
    _setupConstructorDeclaration("A", false);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_const() {
    VariableElement element = _setupVariableDeclaration("v", true, true);
    expect(_findConstants(), contains(element));
  }

  void test_visitVariableDeclaration_final_inClass() {
    _setupFieldDeclaration('C', 'f', Keyword.FINAL);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        hasConstConstructor: true);
    expect(_findConstants(), contains(field.declaredElement));
  }

  void test_visitVariableDeclaration_final_outsideClass() {
    _setupVariableDeclaration('v', false, true, isFinal: true);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_noInitializer() {
    _setupVariableDeclaration("v", true, false);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_nonConst() {
    _setupVariableDeclaration("v", false, true);
    expect(_findConstants(), isEmpty);
  }

  void test_visitVariableDeclaration_static_const_inClass() {
    VariableDeclaration field =
        _setupFieldDeclaration('C', 'f', Keyword.CONST, isStatic: true);
    expect(_findConstants(), contains(field.declaredElement));
  }

  void
      test_visitVariableDeclaration_static_const_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.CONST,
        isStatic: true, hasConstConstructor: true);
    expect(_findConstants(), contains(field.declaredElement));
  }

  void
      test_visitVariableDeclaration_static_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        isStatic: true, hasConstConstructor: true);
    expect(_findConstants(), isNot(contains(field.declaredElement)));
  }

  void
      test_visitVariableDeclaration_uninitialized_final_inClassWithConstConstructor() {
    VariableDeclaration field = _setupFieldDeclaration('C', 'f', Keyword.FINAL,
        isInitialized: false, hasConstConstructor: true);
    expect(_findConstants(), isNot(contains(field.declaredElement)));
  }

  void test_visitVariableDeclaration_uninitialized_static_const_inClass() {
    _setupFieldDeclaration('C', 'f', Keyword.CONST,
        isStatic: true, isInitialized: false);
    expect(_findConstants(), isEmpty);
  }

  List<Annotation> _findAnnotations() {
    Set<Annotation> annotations = <Annotation>{};
    for (ConstantEvaluationTarget target in _findConstants()) {
      if (target is ElementAnnotationImpl) {
        expect(target.source, same(_source));
        annotations.add(target.annotationAst);
      }
    }
    return List<Annotation>.from(annotations);
  }

  List<ConstantEvaluationTarget> _findConstants() {
    ConstantFinder finder = ConstantFinder();
    _node.accept(finder);
    List<ConstantEvaluationTarget> constants = finder.constantsToCompute;
    expect(constants, isNotNull);
    return constants;
  }

  ConstructorElement _setupConstructorDeclaration(String name, bool isConst) {
    var constKeyword = isConst ? Keyword.CONST : null;
    var constructorDeclaration = AstTestFactory.constructorDeclaration2(
        constKeyword,
        null,
        AstTestFactory.identifier3(name),
        null,
        AstTestFactory.formalParameterList(),
        [],
        AstTestFactory.blockFunctionBody2());
    ClassElement classElement = ElementFactory.classElement2(name);
    ConstructorElement element =
        ElementFactory.constructorElement(classElement, name, isConst);
    constructorDeclaration.declaredElement = element;
    _node = constructorDeclaration;
    return element;
  }

  VariableDeclaration _setupFieldDeclaration(
      String className, String fieldName, Keyword keyword,
      {bool isInitialized = true,
      bool isStatic = false,
      bool hasConstConstructor = false}) {
    var variableDeclaration = isInitialized
        ? AstTestFactory.variableDeclaration2(
            fieldName, AstTestFactory.integer(0))
        : AstTestFactory.variableDeclaration(fieldName);
    var fieldElement = ElementFactory.fieldElement(
        fieldName,
        isStatic,
        keyword == Keyword.FINAL,
        keyword == Keyword.CONST,
        _typeProvider.intType);
    variableDeclaration.name.staticElement = fieldElement;
    FieldDeclaration fieldDeclaration = AstTestFactory.fieldDeclaration2(
        isStatic, keyword, <VariableDeclaration>[variableDeclaration]);
    var classDeclaration = AstTestFactory.classDeclaration(
        null, className, null, null, null, null);
    classDeclaration.members.add(fieldDeclaration);
    _node = classDeclaration;
    ClassElementImpl classElement = ElementFactory.classElement2(className);
    classElement.fields = <FieldElement>[fieldElement];
    classDeclaration.name.staticElement = classElement;
    if (hasConstConstructor) {
      var constructorDeclaration = AstTestFactory.constructorDeclaration2(
          Keyword.CONST,
          null,
          AstTestFactory.identifier3(className),
          null,
          AstTestFactory.formalParameterList(),
          [],
          AstTestFactory.blockFunctionBody2());
      classDeclaration.members.add(constructorDeclaration);
      ConstructorElement constructorElement =
          ElementFactory.constructorElement(classElement, '', true);
      constructorDeclaration.declaredElement = constructorElement;
      classElement.constructors = <ConstructorElement>[constructorElement];
    } else {
      classElement.constructors = const <ConstructorElement>[];
    }
    return variableDeclaration;
  }

  VariableElement _setupVariableDeclaration(
      String name, bool isConst, bool isInitialized,
      {isFinal = false}) {
    var variableDeclaration = isInitialized
        ? AstTestFactory.variableDeclaration2(name, AstTestFactory.integer(0))
        : AstTestFactory.variableDeclaration(name);
    var identifier = variableDeclaration.name;
    VariableElement element = ElementFactory.localVariableElement(identifier);
    identifier.staticElement = element;
    var keyword = isConst
        ? Keyword.CONST
        : isFinal
            ? Keyword.FINAL
            : null;
    AstTestFactory.variableDeclarationList2(keyword, [variableDeclaration]);
    _node = variableDeclaration;
    return element;
  }
}

@reflectiveTest
class ReferenceFinderTest {
  late final Element _tail;
  final List<ConstantEvaluationTarget> _dependencies = [];

  void test_visitSimpleIdentifier_const() {
    _visitNode(_makeTailVariable("v2", true));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_const() {
    _visitNode(_makeTailSuperConstructorInvocation("A", true));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_nonConst() {
    _visitNode(_makeTailSuperConstructorInvocation("A", false));
    _assertOneArc(_tail);
  }

  void test_visitSuperConstructorInvocation_unresolved() {
    SuperConstructorInvocation superConstructorInvocation =
        AstTestFactory.superConstructorInvocation();
    _visitNode(superConstructorInvocation);
    _assertNoArcs();
  }

  void _assertNoArcs() {
    expect(_dependencies, isEmpty);
  }

  void _assertOneArc(Element tail) {
    expect(_dependencies, hasLength(1));
    expect(_dependencies[0], same(tail));
  }

  SuperConstructorInvocation _makeTailSuperConstructorInvocation(
      String name, bool isConst) {
    List<ConstructorInitializer> initializers = <ConstructorInitializer>[];
    var constructorDeclaration = AstTestFactory.constructorDeclaration(
        AstTestFactory.identifier3(name),
        null,
        AstTestFactory.formalParameterList(),
        initializers);
    if (isConst) {
      constructorDeclaration.constKeyword = KeywordToken(Keyword.CONST, 0);
    }
    ClassElementImpl classElement = ElementFactory.classElement2(name);
    var superConstructorInvocation =
        AstTestFactory.superConstructorInvocation();
    ConstructorElementImpl constructorElement =
        ElementFactory.constructorElement(classElement, name, isConst);
    _tail = constructorElement;
    superConstructorInvocation.staticElement = constructorElement;
    return superConstructorInvocation;
  }

  SimpleIdentifier _makeTailVariable(String name, bool isConst) {
    VariableDeclaration variableDeclaration =
        AstTestFactory.variableDeclaration(name);
    ConstLocalVariableElementImpl variableElement =
        ElementFactory.constLocalVariableElement(name);
    _tail = variableElement;
    variableElement.isConst = isConst;
    AstTestFactory.variableDeclarationList2(
        isConst ? Keyword.CONST : Keyword.VAR, [variableDeclaration]);
    var identifier = AstTestFactory.identifier3(name);
    identifier.staticElement = variableElement;
    return identifier;
  }

  void _visitNode(AstNode node) {
    var referenceFinder = ReferenceFinder((dependency) {
      _dependencies.add(dependency);
    });
    node.accept(referenceFinder);
  }
}

class _AnalysisContextMock implements AnalysisContext {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
