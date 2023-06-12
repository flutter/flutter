// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/context_collection_resolution.dart';
import '../util/element_type_matchers.dart';
import 'elements_types_mixin.dart';
import 'test_analysis_context.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationElementResolverTest);
    defineReflectiveTests(ElementResolverTest);
  });
}

/// Wrapper around the test package's `fail` function.
///
/// Unlike the test package's `fail` function, this function is not annotated
/// with @alwaysThrows, so we can call it at the top of a test method without
/// causing the rest of the method to be flagged as dead code.
void _fail(String message) {
  fail(message);
}

@reflectiveTest
class AnnotationElementResolverTest extends PubPackageResolutionTest {
  test_class_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A.named();
}
''');
    await _validateAnnotation('', '@A.named()',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isClassElement);
      expect(name1.staticElement!.displayName, 'A');
      expect(name2!.staticElement, isConstructorElement);
      expect(name2.staticElement!.displayName, 'A.named');
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, 'A.named');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_prefixed_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A.named();
}
''');
    await _validateAnnotation('as p', '@p.A.named()',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPrefixElement);
      expect(name1.staticElement!.displayName, 'p');
      expect(name2!.staticElement, isClassElement);
      expect(name2.staticElement!.displayName, 'A');
      expect(name3!.staticElement, isConstructorElement);
      expect(name3.staticElement!.displayName, 'A.named');
      if (annotationElement is ConstructorElement) {
        expect(annotationElement, same(name3.staticElement));
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, 'A.named');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_prefixed_staticConstField() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static const V = 0;
}
''');
    await _validateAnnotation('as p', '@p.A.V',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPrefixElement);
      expect(name1.staticElement!.displayName, 'p');
      expect(name2!.staticElement, isClassElement);
      expect(name2.staticElement!.displayName, 'A');
      expect(name3!.staticElement, isPropertyAccessorElement);
      expect(name3.staticElement!.displayName, 'V');
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name3.staticElement));
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_prefixed_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A();
}
''');
    await _validateAnnotation('as p', '@p.A',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPrefixElement);
      expect(name1.staticElement!.displayName, 'p');
      expect(name2!.staticElement, isClassElement);
      expect(name2.staticElement!.displayName, 'A');
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement.enclosingElement, name2.staticElement);
        expect(annotationElement.displayName, 'A');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_staticConstField() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static const V = 0;
}
''');
    await _validateAnnotation('', '@A.V',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isClassElement);
      expect(name1.staticElement!.displayName, 'A');
      expect(name2!.staticElement, isPropertyAccessorElement);
      expect(name2.staticElement!.displayName, 'V');
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_class_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A();
}
''');
    await _validateAnnotation('', '@A',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isClassElement);
      expect(name1.staticElement!.displayName, 'A');
      expect(name2, isNull);
      expect(name3, isNull);
      if (annotationElement is ConstructorElement) {
        expect(annotationElement.enclosingElement, name1.staticElement);
        expect(annotationElement.displayName, 'A');
        expect(annotationElement.parameters, isEmpty);
      } else {
        fail('Expected "annotationElement" is ConstructorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const V = 0;
''');
    await _validateAnnotation('', '@V',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPropertyAccessorElement);
      expect(name1.staticElement!.displayName, 'V');
      expect(name2, isNull);
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name1.staticElement));
        expect(annotationElement.enclosingElement, isCompilationUnitElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  test_topLevelVariable_prefixed() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const V = 0;
''');
    await _validateAnnotation('as p', '@p.V',
        (name1, name2, name3, annotationElement) {
      expect(name1!.staticElement, isPrefixElement);
      expect(name1.staticElement!.displayName, 'p');
      expect(name2!.staticElement, isPropertyAccessorElement);
      expect(name2.staticElement!.displayName, 'V');
      expect(name3, isNull);
      if (annotationElement is PropertyAccessorElement) {
        expect(annotationElement, same(name2.staticElement));
        expect(annotationElement.enclosingElement, isCompilationUnitElement);
        expect(annotationElement.displayName, 'V');
      } else {
        fail('Expected "annotationElement" is PropertyAccessorElement, '
            'but (${annotationElement.runtimeType}) $annotationElement found.');
      }
    });
  }

  Future<void> _validateAnnotation(
      String annotationPrefix,
      String annotationText,
      Function(SimpleIdentifier? name, SimpleIdentifier? name2,
              SimpleIdentifier? name3, Element annotationElement)
          validator) async {
    await resolveTestCode('''
import 'a.dart' $annotationPrefix;
$annotationText
class C {}
''');
    var clazz = findNode.classDeclaration('C');
    Annotation annotation = clazz.metadata.single;
    Identifier name = annotation.name;
    Element annotationElement = annotation.element!;
    if (name is SimpleIdentifier) {
      validator(name, null, annotation.constructorName, annotationElement);
    } else if (name is PrefixedIdentifier) {
      validator(name.prefix, name.identifier, annotation.constructorName,
          annotationElement);
    } else {
      fail('Unknown "name": ${name.runtimeType} $name');
    }
  }
}

@reflectiveTest
class ElementResolverTest with ResourceProviderMixin, ElementsTypesMixin {
  /// The error listener to which errors will be reported.
  late GatheringErrorListener _listener;

  /// The type provider used to access the types.
  late TypeProvider _typeProvider;

  /// The library containing the code being resolved.
  late LibraryElementImpl _definingLibrary;

  /// The resolver visitor that maintains the state for the resolver.
  late ResolverVisitor _visitor;

  /// The resolver being used to resolve the test cases.
  late ElementResolver _resolver;

  @override
  TypeProvider get typeProvider => _typeProvider;

  void fail_visitExportDirective_combinators() {
    _fail("Not yet tested");
    // Need to set up the exported library so that the identifier can be
    // resolved.
    ExportDirective directive = AstTestFactory.exportDirective2('dart:math', [
      AstTestFactory.hideCombinator2(["A"])
    ]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitFunctionExpressionInvocation() {
    _fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitImportDirective_combinators_noPrefix() {
    _fail("Not yet tested");
    // Need to set up the imported library so that the identifier can be
    // resolved.
    ImportDirective directive =
        AstTestFactory.importDirective3('dart:math', null, [
      AstTestFactory.showCombinator2(["A"])
    ]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitImportDirective_combinators_prefix() {
    _fail("Not yet tested");
    // Need to set up the imported library so that the identifiers can be
    // resolved.
    String prefixName = "p";
    _definingLibrary.imports = <ImportElement>[
      ElementFactory.importFor(
          _LibraryElementMock(), ElementFactory.prefix(prefixName))
    ];
    ImportDirective directive =
        AstTestFactory.importDirective3('dart:math', prefixName, [
      AstTestFactory.showCombinator2(["A"]),
      AstTestFactory.hideCombinator2(["B"])
    ]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitRedirectingConstructorInvocation() {
    _fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void setUp() {
    _listener = GatheringErrorListener();
    _createResolver();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_visitBreakStatement_withLabel() async {
    // loop: while (true) {
    //   break loop;
    // }
    String label = "loop";
    LabelElementImpl labelElement = LabelElementImpl(label, -1, false, false);
    BreakStatement breakStatement = AstTestFactory.breakStatement2(label);
    Expression condition = AstTestFactory.booleanLiteral(true);
    WhileStatement whileStatement =
        AstTestFactory.whileStatement(condition, breakStatement);
    expect(_resolveBreak(breakStatement, labelElement, whileStatement),
        same(labelElement));
    expect(breakStatement.target, same(whileStatement));
    _listener.assertNoErrors();
  }

  test_visitBreakStatement_withoutLabel() async {
    BreakStatement statement = AstTestFactory.breakStatement();
    _resolveStatement(statement, null, null);
    _listener.assertNoErrors();
  }

  test_visitCommentReference_prefixedIdentifier_class_getter() async {
    LibraryElementImpl library =
        ElementFactory.library(_definingLibrary.context, "lib");
    CompilationUnitElementImpl unit =
        library.definingCompilationUnit as CompilationUnitElementImpl;
    ClassElementImpl classA = ElementFactory.classElement2("A");
    unit.classes = [classA];

    // set accessors
    String propName = "p";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(propName, false, _typeProvider.intType);
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter, setter];
    // prepare "A.p"
    PrefixedIdentifierImpl prefixed = AstTestFactory.identifier5('A', 'p');
    prefixed.prefix.scopeLookupResult = ScopeLookupResult(classA, null);
    CommentReference commentReference =
        astFactory.commentReference(null, prefixed);
    // resolve
    _resolveNode(commentReference);
    expect(prefixed.prefix.staticElement, classA);
    expect(prefixed.identifier.staticElement, getter);
    _listener.assertNoErrors();
  }

  test_visitCommentReference_prefixedIdentifier_class_method() async {
    LibraryElementImpl library =
        ElementFactory.library(_definingLibrary.context, "lib");
    CompilationUnitElementImpl unit =
        library.definingCompilationUnit as CompilationUnitElementImpl;
    ClassElementImpl classA = ElementFactory.classElement2("A");
    unit.classes = [classA];
    // set method
    MethodElement method =
        ElementFactory.methodElement("m", _typeProvider.intType);
    classA.methods = <MethodElement>[method];
    // prepare "A.m"
    PrefixedIdentifierImpl prefixed = AstTestFactory.identifier5('A', 'm');
    prefixed.prefix.scopeLookupResult = ScopeLookupResult(classA, null);
    CommentReference commentReference =
        astFactory.commentReference(null, prefixed);
    // resolve
    _resolveNode(commentReference);
    expect(prefixed.prefix.staticElement, classA);
    expect(prefixed.identifier.staticElement, method);
    _listener.assertNoErrors();
  }

  test_visitCommentReference_prefixedIdentifier_class_operator() async {
    LibraryElementImpl library =
        ElementFactory.library(_definingLibrary.context, "lib");
    CompilationUnitElementImpl unit =
        library.definingCompilationUnit as CompilationUnitElementImpl;
    ClassElementImpl classA = ElementFactory.classElement2("A");
    unit.classes = [classA];
    // set method
    MethodElement method =
        ElementFactory.methodElement("==", _typeProvider.boolType);
    classA.methods = <MethodElement>[method];
    // prepare "A.=="
    PrefixedIdentifierImpl prefixed = AstTestFactory.identifier5('A', '==');
    prefixed.prefix.scopeLookupResult = ScopeLookupResult(classA, null);
    CommentReference commentReference =
        astFactory.commentReference(null, prefixed);
    // resolve
    _resolveNode(commentReference);
    expect(prefixed.prefix.staticElement, classA);
    expect(prefixed.identifier.staticElement, method);
    _listener.assertNoErrors();
  }

  test_visitConstructorName_named() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    _encloseElement(classA);
    String constructorName = "a";
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstTestFactory.constructorName(
        AstTestFactory.namedType(classA), constructorName);
    _resolveNode(name);
    expect(name.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  test_visitConstructorName_unnamed() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    _encloseElement(classA);
    String constructorName = 'named';
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name = AstTestFactory.constructorName(
        AstTestFactory.namedType(classA), constructorName);
    _resolveNode(name);
    expect(name.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_visitContinueStatement_withLabel() async {
    // loop: while (true) {
    //   continue loop;
    // }
    String label = "loop";
    LabelElementImpl labelElement = LabelElementImpl(label, -1, false, false);
    ContinueStatement continueStatement =
        AstTestFactory.continueStatement(label);
    Expression condition = AstTestFactory.booleanLiteral(true);
    WhileStatement whileStatement =
        AstTestFactory.whileStatement(condition, continueStatement);
    expect(_resolveContinue(continueStatement, labelElement, whileStatement),
        same(labelElement));
    expect(continueStatement.target, same(whileStatement));
    _listener.assertNoErrors();
  }

  test_visitContinueStatement_withoutLabel() async {
    ContinueStatement statement = AstTestFactory.continueStatement();
    _resolveStatement(statement, null, null);
    _listener.assertNoErrors();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_visitExportDirective_noCombinators() async {
    var directive = AstTestFactory.exportDirective2('dart:math');
    directive.element = ElementFactory.exportFor(
        ElementFactory.library(_definingLibrary.context, "lib"));
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  test_visitFieldFormalParameter() async {
    String fieldName = "f";
    InterfaceType intType = _typeProvider.intType;
    FieldElementImpl fieldElement =
        ElementFactory.fieldElement(fieldName, false, false, false, intType);
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.fields = <FieldElement>[fieldElement];
    var parameter = AstTestFactory.fieldFormalParameter2(fieldName);
    FieldFormalParameterElementImpl parameterElement =
        ElementFactory.fieldFormalParameter(parameter.identifier);
    parameterElement.field = fieldElement;
    parameterElement.type = intType;
    parameter.identifier.staticElement = parameterElement;
    _resolveInClass(parameter, classA);
    expect(parameter.declaredElement!.type, same(intType));
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_visitImportDirective_noCombinators_noPrefix() async {
    var directive = AstTestFactory.importDirective3('dart:math', null);
    directive.element = ElementFactory.importFor(
        ElementFactory.library(_definingLibrary.context, "lib"), null);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_visitImportDirective_noCombinators_prefix() async {
    String prefixName = "p";
    ImportElement importElement = ElementFactory.importFor(
        ElementFactory.library(_definingLibrary.context, "lib"),
        ElementFactory.prefix(prefixName));
    _definingLibrary.imports = <ImportElement>[importElement];
    var directive = AstTestFactory.importDirective3('dart:math', prefixName);
    directive.element = importElement;
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/44522')
  test_visitImportDirective_withCombinators() async {
    ShowCombinator combinator = AstTestFactory.showCombinator2(["A", "B", "C"]);
    var directive =
        AstTestFactory.importDirective3('dart:math', null, [combinator]);
    LibraryElementImpl library =
        ElementFactory.library(_definingLibrary.context, "lib");
    TopLevelVariableElementImpl varA =
        ElementFactory.topLevelVariableElement2("A");
    TopLevelVariableElementImpl varB =
        ElementFactory.topLevelVariableElement2("B");
    TopLevelVariableElementImpl varC =
        ElementFactory.topLevelVariableElement2("C");
    CompilationUnitElementImpl unit =
        library.definingCompilationUnit as CompilationUnitElementImpl;
    unit.accessors = <PropertyAccessorElement>[
      varA.getter!,
      varA.setter!,
      varB.getter!,
      varC.setter!
    ];
    unit.topLevelVariables = <TopLevelVariableElement>[varA, varB, varC];
    directive.element = ElementFactory.importFor(library, null);
    _resolveNode(directive);
    expect(combinator.shownNames[0].staticElement, same(varA));
    expect(combinator.shownNames[1].staticElement, same(varB));
    expect(combinator.shownNames[2].staticElement, same(varC));
    _listener.assertNoErrors();
  }

  test_visitInstanceCreationExpression_named() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = "a";
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    var name = AstTestFactory.constructorName(
        AstTestFactory.namedType(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstTestFactory.instanceCreationExpression(Keyword.NEW, name);
    _resolveNode(creation);
    _listener.assertNoErrors();
  }

  test_visitInstanceCreationExpression_unnamed() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = 'named';
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    var name = AstTestFactory.constructorName(
        AstTestFactory.namedType(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstTestFactory.instanceCreationExpression(Keyword.NEW, name);
    _resolveNode(creation);
    _listener.assertNoErrors();
  }

  test_visitInstanceCreationExpression_unnamed_namedParameter() async {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = 'named';
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    String parameterName = "a";
    ParameterElement parameter =
        ElementFactory.namedParameter2(parameterName, _typeProvider.intType);
    constructor.parameters = <ParameterElement>[parameter];
    classA.constructors = <ConstructorElement>[constructor];
    var name = AstTestFactory.constructorName(
        AstTestFactory.namedType(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstTestFactory.instanceCreationExpression(Keyword.NEW, name, [
      AstTestFactory.namedExpression2(parameterName, AstTestFactory.integer(0))
    ]);
    _resolveNode(creation);
    expect(
        (creation.argumentList.arguments[0] as NamedExpression)
            .name
            .label
            .staticElement,
        same(parameter));
    _listener.assertNoErrors();
  }

  test_visitMethodInvocation() async {
    InterfaceType numType = _typeProvider.numType;
    var left = AstTestFactory.identifier3("i");
    left.staticType = numType;
    String methodName = "abs";
    MethodInvocation invocation =
        AstTestFactory.methodInvocation(left, methodName);
    _resolveNode(invocation);
    expect(invocation.methodName.staticElement!.declaration,
        same(numType.getMethod(methodName)));
    _listener.assertNoErrors();
  }

  test_visitPrefixedIdentifier_dynamic() async {
    DartType dynamicType = _typeProvider.dynamicType;
    var target = AstTestFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = dynamicType;
    target.staticElement = variable;
    target.staticType = dynamicType;
    PrefixedIdentifier identifier =
        AstTestFactory.identifier(target, AstTestFactory.identifier3("b"));
    _resolveNode(identifier);
    expect(identifier.staticElement, isNull);
    expect(identifier.identifier.staticElement, isNull);
    _listener.assertNoErrors();
  }

  test_visitSuperConstructorInvocation() async {
    ClassElementImpl superclass = ElementFactory.classElement2("A");
    _encloseElement(superclass);
    ConstructorElementImpl superConstructor =
        ElementFactory.constructorElement2(superclass, null);
    superclass.constructors = <ConstructorElement>[superConstructor];
    ClassElementImpl subclass =
        ElementFactory.classElement("B", interfaceTypeStar(superclass));
    _encloseElement(subclass);
    ConstructorElementImpl subConstructor =
        ElementFactory.constructorElement2(subclass, null);
    subclass.constructors = <ConstructorElement>[subConstructor];
    SuperConstructorInvocation invocation =
        AstTestFactory.superConstructorInvocation();
    AstTestFactory.classDeclaration(null, 'C', null, null, null, null, [
      AstTestFactory.constructorDeclaration(AstTestFactory.identifier3('C'),
          null, AstTestFactory.formalParameterList(), [invocation])
    ]);
    _resolveInClass(invocation, subclass);
    expect(invocation.staticElement, superConstructor);
    _listener.assertNoErrors();
  }

  test_visitSuperConstructorInvocation_namedParameter() async {
    ClassElementImpl superclass = ElementFactory.classElement2("A");
    _encloseElement(superclass);
    ConstructorElementImpl superConstructor =
        ElementFactory.constructorElement2(superclass, null);
    String parameterName = "p";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    superConstructor.parameters = <ParameterElement>[parameter];
    superclass.constructors = <ConstructorElement>[superConstructor];
    ClassElementImpl subclass =
        ElementFactory.classElement("B", interfaceTypeStar(superclass));
    _encloseElement(subclass);
    ConstructorElementImpl subConstructor =
        ElementFactory.constructorElement2(subclass, null);
    subclass.constructors = <ConstructorElement>[subConstructor];
    SuperConstructorInvocation invocation =
        AstTestFactory.superConstructorInvocation([
      AstTestFactory.namedExpression2(parameterName, AstTestFactory.integer(0))
    ]);
    AstTestFactory.classDeclaration(null, 'C', null, null, null, null, [
      AstTestFactory.constructorDeclaration(AstTestFactory.identifier3('C'),
          null, AstTestFactory.formalParameterList(), [invocation])
    ]);
    _resolveInClass(invocation, subclass);
    expect(invocation.staticElement, superConstructor);
    expect(
        (invocation.argumentList.arguments[0] as NamedExpression)
            .name
            .label
            .staticElement,
        same(parameter));
    _listener.assertNoErrors();
  }

  /// Create and return the resolver used by the tests.
  void _createResolver() {
    var context = TestAnalysisContext();
    _typeProvider = context.typeProviderLegacy;

    Source source = FileSource(getFile("/test.dart"));
    CompilationUnitElementImpl unit = CompilationUnitElementImpl();
    unit.librarySource = unit.source = source;
    _definingLibrary = ElementFactory.library(context, "test");
    _definingLibrary.definingCompilationUnit = unit;

    _definingLibrary.typeProvider = context.typeProviderLegacy;
    _definingLibrary.typeSystem = context.typeSystemLegacy;
    var inheritance = InheritanceManager3();

    var featureSet = FeatureSet.latestLanguageVersion();
    _visitor = ResolverVisitor(
        inheritance, _definingLibrary, source, _typeProvider, _listener,
        featureSet: featureSet,
        flowAnalysisHelper:
            FlowAnalysisHelper(context.typeSystemLegacy, false, featureSet));
    _resolver = _visitor.elementResolver;
  }

  void _encloseElement(ElementImpl element) {
    if (element is ClassElement) {
      element.enclosingElement = _definingLibrary;
    }
  }

  /// Return the element associated with the label of [statement] after the
  /// resolver has resolved it.  [labelElement] is the label element to be
  /// defined in the statement's label scope, and [labelTarget] is the statement
  /// the label resolves to.
  Element? _resolveBreak(BreakStatement statement,
      LabelElementImpl labelElement, Statement labelTarget) {
    _resolveStatement(statement, labelElement, labelTarget);
    return statement.label!.staticElement;
  }

  /// Return the element associated with the label [statement] after the
  /// resolver has resolved it.  [labelElement] is the label element to be
  /// defined in the statement's label scope, and [labelTarget] is the AST node
  /// the label resolves to.
  ///
  /// @param statement the statement to be resolved
  /// @param labelElement the label element to be defined in the statement's
  ///          label scope
  /// @return the element to which the statement's label was resolved
  Element? _resolveContinue(ContinueStatement statement,
      LabelElementImpl labelElement, AstNode labelTarget) {
    _resolveStatement(statement, labelElement, labelTarget);
    return statement.label!.staticElement;
  }

  /// Return the element associated with the given identifier after the resolver
  /// has resolved the identifier.
  ///
  /// @param node the expression to be resolved
  /// @param enclosingClass the element representing the class enclosing the
  ///          identifier
  /// @return the element to which the expression was resolved
  void _resolveInClass(AstNode node, ClassElement enclosingClass) {
    try {
      _visitor.enclosingClass = enclosingClass;
      node.accept(_resolver);
    } finally {
      _visitor.enclosingClass = null;
    }
  }

  /// Return the element associated with the given identifier after the resolver
  /// has resolved the identifier.
  ///
  /// @param node the expression to be resolved
  /// @param definedElements the elements that are to be defined in the scope in
  ///          which the element is being resolved
  /// @return the element to which the expression was resolved
  void _resolveNode(AstNode node) {
    node.accept(_resolver);
  }

  /// Return the element associated with the label of the given statement after
  /// the resolver has resolved the statement.
  ///
  /// @param statement the statement to be resolved
  /// @param labelElement the label element to be defined in the statement's
  ///          label scope
  /// @return the element to which the statement's label was resolved
  void _resolveStatement(Statement statement, LabelElementImpl? labelElement,
      AstNode? labelTarget) {
    statement.accept(_resolver);
  }
}

class _LibraryElementMock implements LibraryElement {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
