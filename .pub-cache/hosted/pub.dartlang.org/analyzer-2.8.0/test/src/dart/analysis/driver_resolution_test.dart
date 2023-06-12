// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/elements_types_mixin.dart';
import '../../../utils.dart';
import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverResolutionTest);
  });
}

final isDynamicType = TypeMatcher<DynamicTypeImpl>();

final isNeverType = TypeMatcher<NeverTypeImpl>();

final isVoidType = TypeMatcher<VoidTypeImpl>();

/// Integration tests for resolution.
@reflectiveTest
class AnalysisDriverResolutionTest extends PubPackageResolutionTest
    with ElementsTypesMixin {
  void assertDeclaredVariableType(SimpleIdentifier node, String expected) {
    var element = node.staticElement as VariableElement;
    assertType(element.type, expected);
  }

  void assertDeclaredVariableTypeObject(SimpleIdentifier node) {
    var element = node.staticElement as VariableElement;
    expect(element.type, typeProvider.objectType);
  }

  /// Test that [argumentList] has exactly two type items `int` and `double`.
  void assertTypeArguments(
      TypeArgumentList argumentList, List<DartType> expectedTypes) {
    expect(argumentList.arguments, hasLength(expectedTypes.length));
    for (int i = 0; i < expectedTypes.length; i++) {
      _assertNamedTypeSimple(argumentList.arguments[i], expectedTypes[i]);
    }
  }

  void assertUnresolvedInvokeType(DartType invokeType) {
    expect(invokeType, isDynamicType);
  }

  /// Creates a function that checks that an expression is a reference to a top
  /// level variable with the given [name].
  void Function(Expression) checkTopVarRef(String name) {
    return (Expression e) {
      TopLevelVariableElement variable = _getTopLevelVariable(result, name);
      SimpleIdentifier node = e as SimpleIdentifier;
      expect(node.staticElement, same(variable.getter));
      expect(node.staticType, variable.type);
    };
  }

  /// Creates a function that checks that an expression is a named argument
  /// that references a top level variable with the given [name], where the
  /// name of the named argument is undefined.
  void Function(Expression) checkTopVarUndefinedNamedRef(String name) {
    return (Expression e) {
      TopLevelVariableElement variable = _getTopLevelVariable(result, name);
      NamedExpression named = e as NamedExpression;
      expect(named.staticType, variable.type);

      SimpleIdentifier nameIdentifier = named.name.label;
      expect(nameIdentifier.staticElement, isNull);
      expect(nameIdentifier.staticType, isNull);

      var expression = named.expression as SimpleIdentifier;
      expect(expression.staticElement, same(variable.getter));
      expect(expression.staticType, variable.type);
    };
  }

  test_adjacentStrings() async {
    String content = r'''
void main() {
  'aaa' 'bbb' 'ccc';
}
''';
    addTestFile(content);
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var statement = statements[0] as ExpressionStatement;
    var expression = statement.expression as AdjacentStrings;
    expect(expression.staticType, typeProvider.stringType);
    expect(expression.strings, hasLength(3));

    StringLiteral literal_1 = expression.strings[0];
    expect(literal_1.staticType, typeProvider.stringType);

    StringLiteral literal_2 = expression.strings[1];
    expect(literal_2.staticType, typeProvider.stringType);

    StringLiteral literal_3 = expression.strings[2];
    expect(literal_3.staticType, typeProvider.stringType);
  }

  test_annotation() async {
    String content = r'''
const myAnnotation = 1;

@myAnnotation
class C {
  @myAnnotation
  int field1 = 2, field2 = 3;

  @myAnnotation
  C() {}

  @myAnnotation
  void method() {}
}

@myAnnotation
int topLevelVariable1 = 4, topLevelVariable2 = 5;

@myAnnotation
void topLevelFunction() {}
''';
    addTestFile(content);

    await resolveTestFile();

    var myDeclaration =
        result.unit.declarations[0] as TopLevelVariableDeclaration;
    var myVariable = myDeclaration.variables.variables[0];
    var myElement = myVariable.declaredElement as TopLevelVariableElement;

    void assertMyAnnotation(AnnotatedNode node) {
      Annotation annotation = node.metadata[0];
      expect(annotation.element, same(myElement.getter));

      var identifier_1 = annotation.name as SimpleIdentifier;
      expect(identifier_1.staticElement, same(myElement.getter));
      expect(identifier_1.staticType, isNull);
    }

    {
      var classNode = result.unit.declarations[1] as ClassDeclaration;
      assertMyAnnotation(classNode);

      {
        var node = classNode.members[0] as FieldDeclaration;
        assertMyAnnotation(node);
      }

      {
        var node = classNode.members[1] as ConstructorDeclaration;
        assertMyAnnotation(node);
      }

      {
        var node = classNode.members[2] as MethodDeclaration;
        assertMyAnnotation(node);
      }
    }

    {
      var node = result.unit.declarations[2] as TopLevelVariableDeclaration;
      assertMyAnnotation(node);
    }

    {
      var node = result.unit.declarations[3] as FunctionDeclaration;
      assertMyAnnotation(node);
    }
  }

  test_annotation_onDirective_export() async {
    addTestFile(r'''
@a
export 'dart:math';

const a = 1;
''');
    await resolveTestFile();

    var directive = findNode.export('dart:math');

    expect(directive.metadata, hasLength(1));
    Annotation annotation = directive.metadata[0];
    expect(annotation.element, findElement.topGet('a'));

    var aRef = annotation.name as SimpleIdentifier;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_annotation_onDirective_import() async {
    addTestFile(r'''
@a
import 'dart:math';

const a = 1;
''');
    await resolveTestFile();

    var directive = findNode.import('dart:math');

    expect(directive.metadata, hasLength(1));
    Annotation annotation = directive.metadata[0];
    expect(annotation.element, findElement.topGet('a'));

    var aRef = annotation.name as SimpleIdentifier;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_annotation_onDirective_library() async {
    addTestFile(r'''
@a
library test;

const a = 1;
''');
    await resolveTestFile();

    var directive = findNode.libraryDirective;

    expect(directive.metadata, hasLength(1));
    Annotation annotation = directive.metadata[0];
    expect(annotation.element, findElement.topGet('a'));

    var aRef = annotation.name as SimpleIdentifier;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_annotation_onDirective_part() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
part of 'test.dart';
''');
    addTestFile(r'''
@a
part 'a.dart';

const a = 1;
''');
    await resolveTestFile();

    var directive = findNode.part('a.dart');

    expect(directive.metadata, hasLength(1));
    Annotation annotation = directive.metadata[0];
    expect(annotation.element, findElement.topGet('a'));

    var aRef = annotation.name as SimpleIdentifier;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_annotation_onDirective_partOf() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
part 'test.dart';
''');
    addTestFile(r'''
@a
part of 'a.dart';

const a = 1;
''');
    await resolveTestFile();

    var directive = findNode.partOf('a.dart');

    expect(directive.metadata, hasLength(1));
    Annotation annotation = directive.metadata[0];
    expect(annotation.element, findElement.topGet('a'));

    var aRef = annotation.name as SimpleIdentifier;
    assertElement(aRef, findElement.topGet('a'));
    assertTypeNull(aRef);
  }

  test_annotation_onFormalParameter_redirectingFactory() async {
    addTestFile(r'''
class C {
  factory C(@a @b x, y, {@c z}) = C.named;
  C.named(int p);
}

const a = 1;
const b = 2;
const c = 2;
''');
    await resolveTestFile();

    void assertTopGetAnnotation(Annotation annotation, String name) {
      var getter = findElement.topGet(name);
      expect(annotation.element, getter);

      var ref = annotation.name as SimpleIdentifier;
      assertElement(ref, getter);
      assertTypeNull(ref);
    }

    {
      var parameter = findNode.simpleParameter('x, ');

      expect(parameter.metadata, hasLength(2));
      assertTopGetAnnotation(parameter.metadata[0], 'a');
      assertTopGetAnnotation(parameter.metadata[1], 'b');
    }

    {
      var parameter = findNode.simpleParameter('z}');

      expect(parameter.metadata, hasLength(1));
      assertTopGetAnnotation(parameter.metadata[0], 'c');
    }
  }

  test_annotation_onVariableList_constructor() async {
    String content = r'''
class C {
  final Object x;
  const C(this.x);
}
main() {
  @C(C(42))
  var foo = null;
}
''';
    addTestFile(content);

    await resolveTestFile();

    var c = result.unit.declarations[0] as ClassDeclaration;
    var constructor = c.members[1] as ConstructorDeclaration;
    ConstructorElement element = constructor.declaredElement!;

    var main = result.unit.declarations[1] as FunctionDeclaration;
    var statement = (main.functionExpression.body as BlockFunctionBody)
        .block
        .statements[0] as VariableDeclarationStatement;
    Annotation annotation = statement.variables.metadata[0];
    expect(annotation.element, same(element));

    var identifier_1 = annotation.name as SimpleIdentifier;
    expect(identifier_1.staticElement, same(c.declaredElement));
  }

  test_annotation_onVariableList_topLevelVariable() async {
    String content = r'''
const myAnnotation = 1;

class C {
  void method() {
    @myAnnotation
    int var1 = 4, var2 = 5;
  }
}
''';
    addTestFile(content);

    await resolveTestFile();

    var myDeclaration =
        result.unit.declarations[0] as TopLevelVariableDeclaration;
    VariableDeclaration myVariable = myDeclaration.variables.variables[0];
    var myElement = myVariable.declaredElement as TopLevelVariableElement;

    var classNode = result.unit.declarations[1] as ClassDeclaration;
    var node = classNode.members[0] as MethodDeclaration;
    var statement = (node.body as BlockFunctionBody).block.statements[0]
        as VariableDeclarationStatement;
    Annotation annotation = statement.variables.metadata[0];
    expect(annotation.element, same(myElement.getter));

    var identifier_1 = annotation.name as SimpleIdentifier;
    expect(identifier_1.staticElement, same(myElement.getter));
    assertTypeNull(identifier_1);
  }

  test_annotation_prefixed_classField() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  static const a = 1;
}
''');
    addTestFile(r'''
import 'a.dart' as p;

@p.A.a
main() {}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    ImportElement aImport = unit.declaredElement!.library.imports[0];
    PrefixElement aPrefix = aImport.prefix!;
    LibraryElement aLibrary = aImport.importedLibrary!;

    CompilationUnitElement aUnitElement = aLibrary.definingCompilationUnit;
    ClassElement aClass = aUnitElement.getType('A')!;
    var aGetter = aClass.getField('a')!.getter;

    Annotation annotation = unit.declarations[0].metadata.single;
    expect(annotation.element, same(aGetter));
    var prefixed = annotation.name as PrefixedIdentifier;

    expect(prefixed.prefix.staticElement, same(aPrefix));
    expect(prefixed.prefix.staticType, isNull);

    expect(prefixed.identifier.staticElement, same(aClass));
    expect(prefixed.prefix.staticType, isNull);

    expect(annotation.constructorName!.staticElement, aGetter);
    assertTypeNull(annotation.constructorName!);

    expect(annotation.arguments, isNull);
  }

  test_annotation_prefixed_constructor() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A(int a, {int b});
}
''');
    addTestFile(r'''
import 'a.dart' as p;

@p.A(1, b: 2)
main() {}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    ImportElement aImport = unit.declaredElement!.library.imports[0];
    PrefixElement aPrefix = aImport.prefix!;
    LibraryElement aLibrary = aImport.importedLibrary!;

    CompilationUnitElement aUnitElement = aLibrary.definingCompilationUnit;
    ClassElement aClass = aUnitElement.getType('A')!;
    ConstructorElement constructor = aClass.unnamedConstructor!;

    Annotation annotation = unit.declarations[0].metadata.single;
    expect(annotation.element, same(constructor));
    var prefixed = annotation.name as PrefixedIdentifier;

    expect(prefixed.prefix.staticElement, same(aPrefix));
    expect(prefixed.prefix.staticType, isNull);

    expect(prefixed.identifier.staticElement, same(aClass));
    expect(prefixed.prefix.staticType, isNull);

    expect(annotation.constructorName, isNull);

    var arguments = annotation.arguments!.arguments;
    var parameters = constructor.parameters;
    _assertArgumentToParameter(arguments[0], parameters[0]);
    _assertArgumentToParameter(arguments[1], parameters[1]);
  }

  test_annotation_prefixed_constructor_named() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class A {
  const A.named(int a, {int b});
}
''');
    addTestFile(r'''
import 'a.dart' as p;

@p.A.named(1, b: 2)
main() {}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    ImportElement aImport = unit.declaredElement!.library.imports[0];
    PrefixElement aPrefix = aImport.prefix!;
    LibraryElement aLibrary = aImport.importedLibrary!;

    CompilationUnitElement aUnitElement = aLibrary.definingCompilationUnit;
    ClassElement aClass = aUnitElement.getType('A')!;
    ConstructorElement constructor = aClass.getNamedConstructor('named')!;

    Annotation annotation = unit.declarations[0].metadata.single;
    expect(annotation.element, same(constructor));
    var prefixed = annotation.name as PrefixedIdentifier;

    expect(prefixed.prefix.staticElement, same(aPrefix));
    expect(prefixed.prefix.staticType, isNull);

    expect(prefixed.identifier.staticElement, same(aClass));
    expect(prefixed.prefix.staticType, isNull);

    var constructorName = annotation.constructorName as SimpleIdentifier;
    expect(constructorName.staticElement, same(constructor));
    assertTypeNull(constructorName);

    var arguments = annotation.arguments!.arguments;
    var parameters = constructor.parameters;
    _assertArgumentToParameter(arguments[0], parameters[0]);
    _assertArgumentToParameter(arguments[1], parameters[1]);
  }

  test_annotation_prefixed_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
const topAnnotation = 1;
''');
    addTestFile(r'''
import 'a.dart' as p;

@p.topAnnotation
main() {}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    ImportElement aImport = unit.declaredElement!.library.imports[0];
    PrefixElement aPrefix = aImport.prefix!;
    LibraryElement aLibrary = aImport.importedLibrary!;

    CompilationUnitElement aUnitElement = aLibrary.definingCompilationUnit;
    var topAnnotation = aUnitElement.topLevelVariables[0].getter;

    Annotation annotation = unit.declarations[0].metadata.single;
    expect(annotation.element, same(topAnnotation));
    var prefixed = annotation.name as PrefixedIdentifier;

    expect(prefixed.prefix.staticElement, same(aPrefix));
    expect(prefixed.prefix.staticType, isNull);

    expect(prefixed.identifier.staticElement, same(topAnnotation));
    expect(prefixed.prefix.staticType, isNull);

    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNull);
  }

  test_annotation_unprefixed_classField() async {
    addTestFile(r'''
@A.a
main() {}

class A {
  static const a = 1;
}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    ClassElement aClass = unitElement.getType('A')!;
    var aGetter = aClass.getField('a')!.getter;

    Annotation annotation = unit.declarations[0].metadata.single;
    expect(annotation.element, same(aGetter));
    var prefixed = annotation.name as PrefixedIdentifier;

    expect(prefixed.prefix.staticElement, same(aClass));
    assertTypeNull(prefixed.prefix);

    expect(prefixed.identifier.staticElement, same(aGetter));
    assertTypeNull(prefixed.identifier);

    expect(annotation.constructorName, isNull);
    expect(annotation.arguments, isNull);
  }

  test_annotation_unprefixed_constructor() async {
    addTestFile(r'''
@A(1, b: 2)
main() {}

class A {
  const A(int a, {int b});
}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    ClassElement aClass = unitElement.getType('A')!;
    ConstructorElement constructor = aClass.unnamedConstructor!;

    Annotation annotation = unit.declarations[0].metadata.single;
    expect(annotation.element, same(constructor));

    var name = annotation.name as SimpleIdentifier;
    expect(name.staticElement, same(aClass));

    expect(annotation.constructorName, isNull);

    var arguments = annotation.arguments!.arguments;
    var parameters = constructor.parameters;
    _assertArgumentToParameter(arguments[0], parameters[0]);
    _assertArgumentToParameter(arguments[1], parameters[1]);
  }

  test_annotation_unprefixed_constructor_named() async {
    addTestFile(r'''
@A.named(1, b: 2)
main() {}

class A {
  const A.named(int a, {int b});
}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    ClassElement aClass = unitElement.getType('A')!;
    ConstructorElement constructor = aClass.constructors.single;

    Annotation annotation = unit.declarations[0].metadata.single;
    expect(annotation.element, same(constructor));
    var prefixed = annotation.name as PrefixedIdentifier;

    expect(prefixed.prefix.staticElement, same(aClass));
    assertTypeNull(prefixed.prefix);

    expect(prefixed.identifier.staticElement, same(constructor));
    assertTypeNull(prefixed.identifier);

    expect(annotation.constructorName, isNull);

    var arguments = annotation.arguments!.arguments;
    var parameters = constructor.parameters;
    _assertArgumentToParameter(arguments[0], parameters[0]);
    _assertArgumentToParameter(arguments[1], parameters[1]);
  }

  test_annotation_unprefixed_constructor_withNestedConstructorInvocation() async {
    addTestFile('''
class C {
  const C();
}
class D {
  final C c;
  const D(this.c);
}
@D(const C())
f() {}
''');
    await resolveTestFile();
    var elementC = AstFinder.getClass(result.unit, 'C').declaredElement!;
    var constructorC = elementC.constructors[0];
    var elementD = AstFinder.getClass(result.unit, 'D').declaredElement!;
    var constructorD = elementD.constructors[0];
    var atD = AstFinder.getTopLevelFunction(result.unit, 'f').metadata[0];
    var constC = atD.arguments!.arguments[0] as InstanceCreationExpression;

    expect(atD.name.staticElement, elementD);
    expect(atD.element, constructorD);

    expect(constC.staticType, interfaceTypeNone(elementC));

    var constructorName = constC.constructorName;
    expect(constructorName.staticElement, constructorC);
    expect(constructorName.type2.type, interfaceTypeNone(elementC));
  }

  test_annotation_unprefixed_topLevelVariable() async {
    String content = r'''
const annotation_1 = 1;
const annotation_2 = 1;
@annotation_1
@annotation_2
void main() {
  print(42);
}
''';
    addTestFile(content);

    await resolveTestFile();

    var declaration_1 =
        result.unit.declarations[0] as TopLevelVariableDeclaration;
    VariableDeclaration variable_1 = declaration_1.variables.variables[0];
    var element_1 = variable_1.declaredElement as TopLevelVariableElement;

    var declaration_2 =
        result.unit.declarations[1] as TopLevelVariableDeclaration;
    VariableDeclaration variable_2 = declaration_2.variables.variables[0];
    var element_2 = variable_2.declaredElement as TopLevelVariableElement;

    var main = result.unit.declarations[2] as FunctionDeclaration;

    Annotation annotation_1 = main.metadata[0];
    expect(annotation_1.element, same(element_1.getter));

    var identifier_1 = annotation_1.name as SimpleIdentifier;
    expect(identifier_1.staticElement, same(element_1.getter));
    assertTypeNull(identifier_1);

    Annotation annotation_2 = main.metadata[1];
    expect(annotation_2.element, same(element_2.getter));

    var identifier_2 = annotation_2.name as SimpleIdentifier;
    expect(identifier_2.staticElement, same(element_2.getter));
    assertTypeNull(identifier_2);
  }

  test_asExpression() async {
    await assertNoErrorsInCode(r'''
void main() {
  num v = 42;
  v as int;
}
''');

    List<Statement> statements = _getMainStatements(result);

    // num v = 42;
    VariableElement vElement;
    {
      var statement = statements[0] as VariableDeclarationStatement;
      vElement = statement.variables.variables[0].name.staticElement
          as VariableElement;
      expect(vElement.type, typeProvider.numType);
    }

    // v as int;
    {
      var statement = statements[1] as ExpressionStatement;
      var asExpression = statement.expression as AsExpression;
      expect(asExpression.staticType, typeProvider.intType);

      var target = asExpression.expression as SimpleIdentifier;
      expect(target.staticElement, vElement);
      expect(target.staticType, typeProvider.numType);

      var intName = asExpression.type as NamedType;
      expect(intName.name.staticElement, typeProvider.intType.element);
      expect(intName.name.staticType, isNull);
    }
  }

  test_binary_operator_with_synthetic_operands() async {
    addTestFile('''
void main() {
  var list = *;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    // Note: no further expectations.  We don't care how the error is recovered
    // from, provided it is recovered from in a way that doesn't crash the
    // analyzer/FE integration.
  }

  test_binaryExpression() async {
    String content = r'''
main() {
  var v = 1 + 2;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    var statement = mainStatements[0] as VariableDeclarationStatement;
    VariableDeclaration vNode = statement.variables.variables[0];
    VariableElement vElement = vNode.declaredElement!;
    expect(vElement.type, typeProvider.intType);

    var value = vNode.initializer as BinaryExpression;
    expect(value.leftOperand.staticType, typeProvider.intType);
    expect(value.rightOperand.staticType, typeProvider.intType);
    expect(value.staticElement!.name, '+');
    expect(value.staticType, typeProvider.intType);
  }

  test_binaryExpression_gtGtGt() async {
    await resolveTestCode('''
class A {
  A operator >>>(int amount) => this;
}
f(A a) {
  a >>> 3;
}
''');

    assertBinaryExpression(
      findNode.binary('>>> 3'),
      element: findElement.method('>>>'),
      type: 'A',
    );
  }

  test_binaryExpression_ifNull() async {
    String content = r'''
int x = 3;
main() {
  1.2 ?? x;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    var statement = mainStatements[0] as ExpressionStatement;
    var binary = statement.expression as BinaryExpression;
    expect(binary.operator.type, TokenType.QUESTION_QUESTION);
    expect(binary.staticElement, isNull);
    expect(binary.staticType, typeProvider.numType);

    expect(binary.leftOperand.staticType, typeProvider.doubleType);
    expect(binary.rightOperand.staticType, typeProvider.intType);
  }

  test_binaryExpression_logical() async {
    addTestFile(r'''
main() {
  true && true;
  true || true;
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    {
      var statement = statements[0] as ExpressionStatement;
      var binaryExpression = statement.expression as BinaryExpression;
      expect(binaryExpression.staticElement, isNull);
      expect(binaryExpression.staticType, typeProvider.boolType);
    }

    {
      var statement = statements[1] as ExpressionStatement;
      var binaryExpression = statement.expression as BinaryExpression;
      expect(binaryExpression.staticElement, isNull);
      expect(binaryExpression.staticType, typeProvider.boolType);
    }
  }

  test_binaryExpression_notEqual() async {
    String content = r'''
main() {
  1 != 2;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;
    var expression = statement.expression as BinaryExpression;
    expect(expression.operator.type, TokenType.BANG_EQ);
    expect(expression.leftOperand.staticType, typeProvider.intType);
    expect(expression.rightOperand.staticType, typeProvider.intType);
    expect(expression.staticElement!.name, '==');
    expect(expression.staticType, typeProvider.boolType);
  }

  test_cascade_get_with_numeric_getter_name() async {
    addTestFile('''
void f(x) {
  x..42;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    // Note: no further expectations.  We don't care how the error is recovered
    // from, provided it is recovered from in a way that doesn't crash the
    // analyzer/FE integration.
  }

  test_cascade_method_call_with_synthetic_method_name() async {
    addTestFile('''
void f(x) {
  x..(42);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    // Note: no further expectations.  We don't care how the error is recovered
    // from, provided it is recovered from in a way that doesn't crash the
    // analyzer/FE integration.
  }

  test_cascadeExpression() async {
    String content = r'''
void main() {
  new A()..a()..b();
}
class A {
  void a() {}
  void b() {}
}
''';
    addTestFile(content);
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var statement = statements[0] as ExpressionStatement;
    var expression = statement.expression as CascadeExpression;
    expect(expression.target.staticType, isNotNull);
    NodeList<Expression> sections = expression.cascadeSections;

    var a = sections[0] as MethodInvocation;
    expect(a.methodName.staticElement, isNotNull);
    expect(a.staticType, isNotNull);

    var b = sections[1] as MethodInvocation;
    expect(b.methodName.staticElement, isNotNull);
    expect(b.staticType, isNotNull);
  }

  test_closure() async {
    addTestFile(r'''
main() {
  var items = <int>[1, 2, 3];
  items.forEach((item) {
    item;
  });
  items.forEach((item) {
    item;
  });
}
''');
    await resolveTestFile();

    var mainDeclaration = result.unit.declarations[0] as FunctionDeclaration;
    var mainElement = mainDeclaration.declaredElement as FunctionElement;
    var mainBody = mainDeclaration.functionExpression.body as BlockFunctionBody;
    List<Statement> mainStatements = mainBody.block.statements;

    var itemsStatement = mainStatements[0] as VariableDeclarationStatement;
    var itemsElement = itemsStatement.variables.variables[0].declaredElement!;

    // First closure.
    ParameterElement itemElement1;
    {
      var forStatement = mainStatements[1] as ExpressionStatement;
      var forInvocation = forStatement.expression as MethodInvocation;

      var forTarget = forInvocation.target as SimpleIdentifier;
      expect(forTarget.staticElement, itemsElement);

      var closureTypeStr = 'void Function(int)';
      var closure =
          forInvocation.argumentList.arguments[0] as FunctionExpression;

      var closureElement = closure.declaredElement as FunctionElementImpl;
      expect(closureElement.enclosingElement, same(mainElement));

      ParameterElement itemElement = closureElement.parameters[0];
      itemElement1 = itemElement;

      expect(closureElement.returnType, typeProvider.voidType);
      assertType(closureElement.type, closureTypeStr);
      expect(closure.staticType, same(closureElement.type));

      List<FormalParameter> closureParameters = closure.parameters!.parameters;
      expect(closureParameters, hasLength(1));

      var itemNode = closureParameters[0] as SimpleFormalParameter;
      _assertSimpleParameter(itemNode, itemElement,
          name: 'item',
          offset: 56,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      var closureBody = closure.body as BlockFunctionBody;
      List<Statement> closureStatements = closureBody.block.statements;

      var itemStatement = closureStatements[0] as ExpressionStatement;
      var itemIdentifier = itemStatement.expression as SimpleIdentifier;
      expect(itemIdentifier.staticElement, itemElement);
      expect(itemIdentifier.staticType, typeProvider.intType);
    }

    // Second closure, same names, different elements.
    {
      var forStatement = mainStatements[2] as ExpressionStatement;
      var forInvocation = forStatement.expression as MethodInvocation;

      var forTarget = forInvocation.target as SimpleIdentifier;
      expect(forTarget.staticElement, itemsElement);

      var closureTypeStr = 'void Function(int)';
      var closure =
          forInvocation.argumentList.arguments[0] as FunctionExpression;

      var closureElement = closure.declaredElement as FunctionElementImpl;
      expect(closureElement.enclosingElement, same(mainElement));

      ParameterElement itemElement = closureElement.parameters[0];
      expect(itemElement, isNot(same(itemElement1)));

      expect(closureElement.returnType, typeProvider.voidType);
      assertType(closureElement.type, closureTypeStr);
      expect(closure.staticType, same(closureElement.type));

      List<FormalParameter> closureParameters = closure.parameters!.parameters;
      expect(closureParameters, hasLength(1));

      var itemNode = closureParameters[0] as SimpleFormalParameter;
      _assertSimpleParameter(itemNode, itemElement,
          name: 'item',
          offset: 97,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      var closureBody = closure.body as BlockFunctionBody;
      List<Statement> closureStatements = closureBody.block.statements;

      var itemStatement = closureStatements[0] as ExpressionStatement;
      var itemIdentifier = itemStatement.expression as SimpleIdentifier;
      expect(itemIdentifier.staticElement, itemElement);
      expect(itemIdentifier.staticType, typeProvider.intType);
    }
  }

  test_closure_generic() async {
    addTestFile(r'''
main() {
  foo(<T>() => new List<T>(4));
}

void foo(List<T> Function<T>() createList) {}
''');
    await resolveTestFile();

    var closure = findNode.functionExpression('<T>() =>');
    assertType(closure, 'List<T> Function<T>()');

    var closureElement = closure.declaredElement as FunctionElementImpl;
    expect(closureElement.enclosingElement, findElement.function('main'));
    assertType(closureElement.returnType, 'List<T>');
    expect(closureElement.parameters, isEmpty);

    var typeParameters = closureElement.typeParameters;
    expect(typeParameters, hasLength(1));

    TypeParameterElement tElement = typeParameters[0];
    expect(tElement.name, 'T');
    expect(tElement.nameOffset, 16);

    var creation = findNode.instanceCreation('new List');
    assertType(creation, 'List<T>');

    var tRef = findNode.simple('T>(4)');
    assertElement(tRef, tElement);
  }

  test_closure_inField() async {
    addTestFile(r'''
class C {
  var v = (() => 42)();
}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var c = unit.declarations[0] as ClassDeclaration;
    var declaration = c.members[0] as FieldDeclaration;
    VariableDeclaration field = declaration.fields.variables[0];

    var invocation = field.initializer as FunctionExpressionInvocation;
    var closure = invocation.function.unParenthesized as FunctionExpression;
    var closureElement = closure.declaredElement as FunctionElementImpl;
    expect(closureElement, isNotNull);
  }

  test_closure_inTopLevelVariable() async {
    addTestFile(r'''
var v = (() => 42)();
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
    VariableDeclaration variable = declaration.variables.variables[0];

    var invocation = variable.initializer as FunctionExpressionInvocation;
    var closure = invocation.function.unParenthesized as FunctionExpression;
    var closureElement = closure.declaredElement as FunctionElementImpl;
    expect(closureElement, isNotNull);
  }

  test_conditionalExpression() async {
    String content = r'''
void main() {
  true ? 1 : 2.3;
}
''';
    addTestFile(content);
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var statement = statements[0] as ExpressionStatement;
    var expression = statement.expression as ConditionalExpression;
    expect(expression.staticType, typeProvider.numType);
    expect(expression.condition.staticType, typeProvider.boolType);
    expect(expression.thenExpression.staticType, typeProvider.intType);
    expect(expression.elseExpression.staticType, typeProvider.doubleType);
  }

  test_const_constructor_calls_non_const_super() async {
    addTestFile('''
class A {
  final a;
  A(this.a);
}
class B extends A {
  const B() : super(5);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    // Note: no further expectations.  We don't care how the error is recovered
    // from, provided it is recovered from in a way that doesn't crash the
    // analyzer/FE integration.
  }

  test_constructor_context() async {
    addTestFile(r'''
class C {
  C(int p) {
    p;
  }
}
''');
    await resolveTestFile();

    var cNode = result.unit.declarations[0] as ClassDeclaration;

    var constructorNode = cNode.members[0] as ConstructorDeclaration;
    ParameterElement pElement = constructorNode.declaredElement!.parameters[0];

    var constructorBody = constructorNode.body as BlockFunctionBody;
    var pStatement = constructorBody.block.statements[0] as ExpressionStatement;

    var pIdentifier = pStatement.expression as SimpleIdentifier;
    expect(pIdentifier.staticElement, same(pElement));
    expect(pIdentifier.staticType, typeProvider.intType);
  }

  test_constructor_initializer_field() async {
    addTestFile(r'''
class C {
  int f;
  C(int p) : f = p {
    f;
  }
}
''');
    await resolveTestFile();

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    FieldElement fElement = cElement.getField('f')!;

    var constructorNode = cNode.members[1] as ConstructorDeclaration;
    ParameterElement pParameterElement =
        constructorNode.declaredElement!.parameters[0];

    {
      var initializer =
          constructorNode.initializers[0] as ConstructorFieldInitializer;
      expect(initializer.fieldName.staticElement, same(fElement));

      var expression = initializer.expression as SimpleIdentifier;
      expect(expression.staticElement, same(pParameterElement));
    }
  }

  test_constructor_initializer_super() async {
    addTestFile(r'''
class A {
  A(int a);
  A.named(int a, {int b});
}
class B extends A {
  B.one(int p) : super(p + 1);
  B.two(int p) : super.named(p + 1, b: p + 2);
}
''');
    await resolveTestFile();

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;

    var bNode = result.unit.declarations[1] as ClassDeclaration;

    {
      var constructor = bNode.members[0] as ConstructorDeclaration;
      var initializer =
          constructor.initializers[0] as SuperConstructorInvocation;
      expect(initializer.staticElement, same(aElement.unnamedConstructor));
      expect(initializer.constructorName, isNull);
    }

    {
      var namedConstructor = aElement.getNamedConstructor('named')!;

      var constructor = bNode.members[1] as ConstructorDeclaration;
      var initializer =
          constructor.initializers[0] as SuperConstructorInvocation;
      expect(initializer.staticElement, same(namedConstructor));

      var constructorName = initializer.constructorName!;
      expect(constructorName.staticElement, same(namedConstructor));
      expect(constructorName.staticType, isNull);

      List<Expression> arguments = initializer.argumentList.arguments;
      _assertArgumentToParameter(arguments[0], namedConstructor.parameters[0]);
      _assertArgumentToParameter(arguments[1], namedConstructor.parameters[1]);
    }
  }

  test_constructor_initializer_this() async {
    addTestFile(r'''
class C {
  C(int a, [int b]);
  C.named(int a, {int b});
  C.one(int p) : this(1, 2);
  C.two(int p) : this.named(3, b: 4);
}
''');
    await resolveTestFile();

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    {
      var unnamedConstructor = cElement.constructors[0];

      var constructor = cNode.members[2] as ConstructorDeclaration;
      var initializer =
          constructor.initializers[0] as RedirectingConstructorInvocation;
      expect(initializer.staticElement, same(unnamedConstructor));
      expect(initializer.constructorName, isNull);

      List<Expression> arguments = initializer.argumentList.arguments;
      _assertArgumentToParameter(
          arguments[0], unnamedConstructor.parameters[0]);
      _assertArgumentToParameter(
          arguments[1], unnamedConstructor.parameters[1]);
    }

    {
      var namedConstructor = cElement.constructors[1];

      var constructor = cNode.members[3] as ConstructorDeclaration;
      var initializer =
          constructor.initializers[0] as RedirectingConstructorInvocation;
      expect(initializer.staticElement, same(namedConstructor));

      var constructorName = initializer.constructorName!;
      expect(constructorName.staticElement, same(namedConstructor));
      expect(constructorName.staticType, isNull);

      List<Expression> arguments = initializer.argumentList.arguments;
      _assertArgumentToParameter(arguments[0], namedConstructor.parameters[0]);
      _assertArgumentToParameter(arguments[1], namedConstructor.parameters[1]);
    }
  }

  test_constructor_redirected() async {
    addTestFile(r'''
class A implements B {
  A(int a);
  A.named(double a);
}
class B {
  factory B.one(int b) = A;
  factory B.two(double b) = A.named;
}
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;

    var bNode = result.unit.declarations[1] as ClassDeclaration;

    {
      ConstructorElement aUnnamed = aElement.constructors[0];

      var constructor = bNode.members[0] as ConstructorDeclaration;
      ConstructorElement element = constructor.declaredElement!;
      expect(element.redirectedConstructor, same(aUnnamed));

      var constructorName = constructor.redirectedConstructor!;
      expect(constructorName.staticElement, same(aUnnamed));

      NamedType namedType = constructorName.type2;
      expect(namedType.type, interfaceTypeNone(aElement));

      var identifier = namedType.name as SimpleIdentifier;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, isNull);

      expect(constructorName.name, isNull);
    }

    {
      ConstructorElement aNamed = aElement.constructors[1];

      var constructor = bNode.members[1] as ConstructorDeclaration;
      ConstructorElement element = constructor.declaredElement!;
      expect(element.redirectedConstructor, same(aNamed));

      var constructorName = constructor.redirectedConstructor!;
      expect(constructorName.staticElement, same(aNamed));

      var namedType = constructorName.type2;
      expect(namedType.type, interfaceTypeNone(aElement));

      var identifier = namedType.name as SimpleIdentifier;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, isNull);

      expect(constructorName.name!.staticElement, aNamed);
      expect(constructorName.name!.staticType, isNull);
    }
  }

  test_constructor_redirected_generic() async {
    addTestFile(r'''
class A<T> implements B<T> {
  A(int a);
  A.named(double a);
}
class B<U> {
  factory B.one(int b) = A<U>;
  factory B.two(double b) = A<U>.named;
}
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;

    var bNode = result.unit.declarations[1] as ClassDeclaration;
    TypeParameterType uType =
        typeParameterTypeNone(bNode.declaredElement!.typeParameters[0]);
    InterfaceType auType = aElement.instantiate(
      typeArguments: [uType],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    {
      ConstructorElement expectedElement = aElement.constructors[0];

      var constructor = bNode.members[0] as ConstructorDeclaration;
      ConstructorElement element = constructor.declaredElement!;

      var actualMember = element.redirectedConstructor!;
      assertMember(actualMember, expectedElement, {'T': 'U'});

      var constructorName = constructor.redirectedConstructor!;
      expect(constructorName.staticElement, same(actualMember));

      NamedType namedType = constructorName.type2;
      expect(namedType.type, auType);

      var identifier = namedType.name as SimpleIdentifier;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, isNull);

      expect(constructorName.name, isNull);
    }

    {
      ConstructorElement expectedElement = aElement.constructors[1];

      var constructor = bNode.members[1] as ConstructorDeclaration;
      ConstructorElement element = constructor.declaredElement!;

      var actualMember = element.redirectedConstructor!;
      assertMember(actualMember, expectedElement, {'T': 'U'});

      var constructorName = constructor.redirectedConstructor!;
      expect(constructorName.staticElement, same(actualMember));

      NamedType namedType = constructorName.type2;
      expect(namedType.type, auType);

      var identifier = namedType.name as SimpleIdentifier;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, isNull);

      expect(constructorName.name!.staticElement, same(actualMember));
      expect(constructorName.name!.staticType, isNull);
    }
  }

  test_deferredImport_loadLibrary_invocation() async {
    newFile('$testPackageLibPath/a.dart');
    addTestFile(r'''
import 'a.dart' deferred as a;
main() {
  a.loadLibrary();
}
''');
    await resolveTestFile();
    var import = findElement.import('package:test/a.dart');

    var invocation = findNode.methodInvocation('loadLibrary');
    assertType(invocation, 'Future<dynamic>');
    assertInvokeType(invocation, 'Future<dynamic> Function()');

    var target = invocation.target as SimpleIdentifier;
    assertElement(target, import.prefix);
    assertType(target, null);

    var name = invocation.methodName;
    assertElement(name, import.importedLibrary!.loadLibraryFunction);
    assertType(name, 'Future<dynamic> Function()');
  }

  test_deferredImport_loadLibrary_invocation_argument() async {
    newFile('$testPackageLibPath/a.dart');
    addTestFile(r'''
import 'a.dart' deferred as a;
var b = 1;
var c = 2;
main() {
  a.loadLibrary(b, c);
}
''');
    await resolveTestFile();
    var import = findElement.import('package:test/a.dart');

    var invocation = findNode.methodInvocation('loadLibrary');
    assertType(invocation, 'Future<dynamic>');
    assertInvokeType(invocation, 'Future<dynamic> Function()');

    var target = invocation.target as SimpleIdentifier;
    assertElement(target, import.prefix);
    assertType(target, null);

    var name = invocation.methodName;
    assertElement(name, import.importedLibrary!.loadLibraryFunction);
    assertType(name, 'Future<dynamic> Function()');

    var bRef = invocation.argumentList.arguments[0];
    assertElement(bRef, findElement.topGet('b'));
    assertType(bRef, 'int');

    var cRef = invocation.argumentList.arguments[1];
    assertElement(cRef, findElement.topGet('c'));
    assertType(cRef, 'int');
  }

  test_deferredImport_loadLibrary_tearOff() async {
    newFile('$testPackageLibPath/a.dart');
    addTestFile(r'''
import 'a.dart' deferred as a;
main() {
  a.loadLibrary;
}
''');
    await resolveTestFile();
    var import = findElement.import('package:test/a.dart');

    var prefixed = findNode.prefixed('a.loadLibrary');
    assertType(prefixed, 'Future<dynamic> Function()');

    var prefix = prefixed.prefix;
    assertElement(prefix, import.prefix);
    assertType(prefix, null);

    var identifier = prefixed.identifier;
    assertElement(identifier, import.importedLibrary!.loadLibraryFunction);
    assertType(identifier, 'Future<dynamic> Function()');
  }

  test_deferredImport_variable() async {
    newFile('$testPackageLibPath/a.dart', content: 'var v = 0;');
    addTestFile(r'''
import 'a.dart' deferred as a;
main() async {
  a.v;
  a.v = 1;
}
''');
    await resolveTestFile();
    var import = findElement.import('package:test/a.dart');
    var v = (import.importedLibrary!.publicNamespace.get('v')
            as PropertyAccessorElement)
        .variable as TopLevelVariableElement;

    {
      var prefixed = findNode.prefixed('a.v;');
      assertElement(prefixed, v.getter);
      assertType(prefixed, 'int');

      assertElement(prefixed.prefix, import.prefix);
      assertType(prefixed.prefix, null);

      assertElement(prefixed.identifier, v.getter);
      assertType(prefixed.identifier, 'int');
    }

    {
      var prefixed = findNode.prefixed('a.v = 1;');
      if (hasAssignmentLeftResolution) {
        assertElement(prefixed, v.setter);
        assertType(prefixed, 'int');
      } else {
        assertElementNull(prefixed);
        assertTypeNull(prefixed);
      }

      assertElement(prefixed.prefix, import.prefix);
      assertType(prefixed.prefix, null);

      if (hasAssignmentLeftResolution) {
        assertElement(prefixed.identifier, v.setter);
        assertType(prefixed.identifier, 'int');
      } else {
        assertElementNull(prefixed.identifier);
        assertTypeNull(prefixed.identifier);
      }
    }
  }

  test_directive_export() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class MyClass {}
int myVar;
int get myGetter => 0;
int set mySetter(_) {}
''');
    addTestFile(r'''
export 'a.dart' show MyClass, myVar, myGetter, mySetter, Unresolved;
''');
    await resolveTestFile();
    var export = findElement.export('package:test/a.dart');
    var namespace = export.exportedLibrary!.exportNamespace;

    {
      var ref = findNode.simple('MyClass');
      assertElement(ref, namespace.get('MyClass'));
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('myVar');
      var getter = namespace.get('myVar') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('myGetter');
      var getter = namespace.get('myGetter') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('mySetter');
      var getter = namespace.get('mySetter=') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('Unresolved');
      assertElementNull(ref);
      assertType(ref, null);
    }
  }

  test_directive_import_hide() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class MyClass {}
int myVar;
int get myGetter => 0;
int set mySetter(_) {}
''');
    addTestFile(r'''
import 'a.dart' hide MyClass, myVar, myGetter, mySetter, Unresolved;
''');
    await resolveTestFile();
    var import = findElement.import('package:test/a.dart');
    var namespace = import.importedLibrary!.exportNamespace;

    {
      var ref = findNode.simple('MyClass');
      assertElement(ref, namespace.get('MyClass'));
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('myVar');
      var getter = namespace.get('myVar') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('myGetter');
      var getter = namespace.get('myGetter') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('mySetter');
      var getter = namespace.get('mySetter=') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('Unresolved');
      assertElementNull(ref);
      assertType(ref, null);
    }
  }

  test_directive_import_show() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class MyClass {}
int myVar;
int get myGetter => 0;
int set mySetter(_) {}
''');
    addTestFile(r'''
import 'a.dart' show MyClass, myVar, myGetter, mySetter, Unresolved;
''');
    await resolveTestFile();
    var import = findElement.import('package:test/a.dart');
    var namespace = import.importedLibrary!.exportNamespace;

    {
      var ref = findNode.simple('MyClass');
      assertElement(ref, namespace.get('MyClass'));
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('myVar');
      var getter = namespace.get('myVar') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('myGetter');
      var getter = namespace.get('myGetter') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('mySetter');
      var getter = namespace.get('mySetter=') as PropertyAccessorElement;
      assertElement(ref, getter.variable);
      assertType(ref, null);
    }

    {
      var ref = findNode.simple('Unresolved');
      assertElementNull(ref);
      assertType(ref, null);
    }
  }

  test_enum_toString() async {
    addTestFile(r'''
enum MyEnum { A, B, C }
main(MyEnum e) {
  e.toString();
}
''');
    await resolveTestFile();

    var enumNode = result.unit.declarations[0] as EnumDeclaration;
    ClassElement enumElement = enumNode.declaredElement!;

    List<Statement> mainStatements = _getMainStatements(result);

    var statement = mainStatements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    assertInvokeType(invocation, 'String Function()');

    var methodElement = invocation.methodName.staticElement as MethodElement;
    expect(methodElement.name, 'toString');
    expect(methodElement.enclosingElement, same(enumElement));
  }

  test_error_unresolvedTypeAnnotation() async {
    String content = r'''
main() {
  Foo<int> v = null;
}
''';
    addTestFile(content);
    await resolveTestFile();

    var statements = _getMainStatements(result);

    var statement = statements[0] as VariableDeclarationStatement;

    var namedType = statement.variables.type as NamedType;
    expect(namedType.type, isDynamicType);
    expect(namedType.typeArguments!.arguments[0].type, typeProvider.intType);

    VariableDeclaration vNode = statement.variables.variables[0];
    expect(vNode.name.staticType, isNull);
    expect(vNode.declaredElement!.type, isDynamicType);
  }

  test_field_context() async {
    addTestFile(r'''
class C<T> {
  var f = <T>[];
}
''');
    await resolveTestFile();

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    var tElement = cNode.declaredElement!.typeParameters[0];

    var fDeclaration = cNode.members[0] as FieldDeclaration;
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    var fElement = fNode.declaredElement as FieldElement;
    expect(
        fElement.type, typeProvider.listType(typeParameterTypeNone(tElement)));
  }

  test_field_generic() async {
    addTestFile(r'''
class C<T> {
  T f;
}
main(C<int> c) {
  c.f; // ref
  c.f = 1;
}
''');
    await resolveTestFile();

    {
      var fRef = findNode.simple('f; // ref');
      assertMember(fRef, findElement.getter('f'), {'T': 'int'});
      assertType(fRef, 'int');
    }

    {
      var fRef = findNode.simple('f = 1;');
      if (hasAssignmentLeftResolution) {
        assertMember(fRef, findElement.setter('f'), {'T': 'int'});
        assertType(fRef, 'int');
      } else {
        assertElementNull(fRef);
        assertTypeNull(fRef);
      }
    }
  }

  test_formalParameter_functionTyped() async {
    addTestFile(r'''
class A {
  A(String p(int a));
}
''');
    await resolveTestFile();

    var clazz = result.unit.declarations[0] as ClassDeclaration;
    var constructor = clazz.members[0] as ConstructorDeclaration;
    List<FormalParameter> parameters = constructor.parameters.parameters;

    var p = parameters[0] as FunctionTypedFormalParameter;
    expect(p.declaredElement, same(constructor.declaredElement!.parameters[0]));

    {
      var type =
          (p.identifier.staticElement as ParameterElement).type as FunctionType;
      expect(type.returnType, typeProvider.stringType);

      expect(type.parameters, hasLength(1));
      expect(type.parameters[0].type, typeProvider.intType);
    }

    _assertNamedTypeSimple(p.returnType!, typeProvider.stringType);

    {
      var a = p.parameters.parameters[0] as SimpleFormalParameter;
      _assertNamedTypeSimple(a.type!, typeProvider.intType);
      expect(a.identifier!.staticType, isNull);
    }
  }

  test_formalParameter_functionTyped_fieldFormal_typed() async {
    // TODO(scheglov) Add "untyped" version with precise type in field.
    addTestFile(r'''
class A {
  Function f;
  A(String this.f(int a));
}
''');
    await resolveTestFile();

    var clazz = result.unit.declarations[0] as ClassDeclaration;

    var fDeclaration = clazz.members[0] as FieldDeclaration;
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    var fElement = fNode.declaredElement as FieldElement;

    var constructor = clazz.members[1] as ConstructorDeclaration;

    var pElement = constructor.declaredElement!.parameters[0]
        as FieldFormalParameterElement;
    expect(pElement.field, same(fElement));

    List<FormalParameter> parameters = constructor.parameters.parameters;
    var p = parameters[0] as FieldFormalParameter;
    expect(p.declaredElement, same(pElement));

    expect(p.identifier.staticElement, same(pElement));
    assertType(p.identifier.staticType, 'String Function(int)');

    {
      var type = p.identifier.staticType as FunctionType;
      expect(type.returnType, typeProvider.stringType);

      expect(type.parameters, hasLength(1));
      expect(type.parameters[0].type, typeProvider.intType);
    }

    _assertNamedTypeSimple(p.type!, typeProvider.stringType);

    {
      var a = p.parameters!.parameters[0] as SimpleFormalParameter;
      _assertNamedTypeSimple(a.type!, typeProvider.intType);
      expect(a.identifier!.staticType, isNull);
    }
  }

  test_formalParameter_simple_fieldFormal() async {
    addTestFile(r'''
class A {
  int f;
  A(this.f);
}
''');
    await resolveTestFile();

    var clazz = result.unit.declarations[0] as ClassDeclaration;

    var fDeclaration = clazz.members[0] as FieldDeclaration;
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    var fElement = fNode.declaredElement as FieldElement;

    var constructor = clazz.members[1] as ConstructorDeclaration;
    List<FormalParameter> parameters = constructor.parameters.parameters;

    var parameterElement = constructor.declaredElement!.parameters[0]
        as FieldFormalParameterElement;
    expect(parameterElement.field, same(fElement));

    var parameterNode = parameters[0] as FieldFormalParameter;
    expect(parameterNode.type, isNull);
    expect(parameterNode.declaredElement, same(parameterElement));

    expect(parameterNode.identifier.staticElement, same(parameterElement));
    expect(parameterNode.identifier.staticType, typeProvider.intType);
  }

  test_formalParameter_simple_fieldFormal_typed() async {
    addTestFile(r'''
class A {
  int f;
  A(int this.f);
}
''');
    await resolveTestFile();

    var clazz = result.unit.declarations[0] as ClassDeclaration;

    var fDeclaration = clazz.members[0] as FieldDeclaration;
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    var fElement = fNode.declaredElement as FieldElement;

    var constructor = clazz.members[1] as ConstructorDeclaration;
    List<FormalParameter> parameters = constructor.parameters.parameters;

    var parameterElement = constructor.declaredElement!.parameters[0]
        as FieldFormalParameterElement;
    expect(parameterElement.field, same(fElement));

    var parameterNode = parameters[0] as FieldFormalParameter;
    _assertNamedTypeSimple(parameterNode.type!, typeProvider.intType);
    expect(parameterNode.declaredElement, same(parameterElement));

    expect(parameterNode.identifier.staticElement, same(parameterElement));
    expect(parameterNode.identifier.staticType, typeProvider.intType);
  }

  test_forwardingStub_class() async {
    addTestFile(r'''
class A<T> {
  void m(T t) {}
}
class B extends A<int> {}
main(B b) {
  b.m(1);
}
''');
    await resolveTestFile();

//    var aNode = result.unit!.declarations[0] as ClassDeclaration;
//    ClassElement eElement = aNode.declaredElement!;
//    MethodElement mElement = eElement.getMethod('m');

    List<Statement> mainStatements = _getMainStatements(result);

    var statement = mainStatements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    assertInvokeType(invocation, 'void Function(int)');
    // TODO(scheglov) Check for MethodElement
//    expect(invocation.methodName.staticElement, same(mElement));
  }

  test_function_call_with_synthetic_arguments() async {
    addTestFile('''
void f(x) {}
class C {
  m() {
    f(,);
  }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    // Note: no further expectations.  We don't care how the error is recovered
    // from, provided it is recovered from in a way that doesn't crash the
    // analyzer/FE integration.
  }

  test_functionExpressionInvocation() async {
    addTestFile(r'''
typedef Foo<S> = S Function<T>(T x);
void main(f) {
  (f as Foo<int>)<String>('hello');
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var statement = statements[0] as ExpressionStatement;
    var invocation = statement.expression as FunctionExpressionInvocation;

    expect(invocation.staticElement, isNull);
    assertInvokeType(invocation, 'int Function(String)');
    expect(invocation.staticType, typeProvider.intType);

    List<TypeAnnotation> typeArguments = invocation.typeArguments!.arguments;
    expect(typeArguments, hasLength(1));
    _assertNamedTypeSimple(typeArguments[0], typeProvider.stringType);
  }

  test_functionExpressionInvocation_namedArgument() async {
    addTestFile(r'''
int a;
main(f) {
  (f)(p: a);
}
''');
    await resolveTestFile();
    assertTopGetRef('a);', 'a');
  }

  test_generic_function_type() async {
    addTestFile('''
main() {
  void Function<T>(T) f;
}
''');
    await resolveTestFile();
    assertTypeNull(findNode.simple('f;'));
    var fType = findElement.localVar('f').type as FunctionType;
    var fTypeTypeParameter = fType.typeFormals[0];
    var fTypeParameter = fType.normalParameterTypes[0] as TypeParameterType;
    expect(fTypeParameter.element, same(fTypeTypeParameter));
    var tRef = findNode.simple('T>');
    var functionTypeNode = tRef.parent!.parent!.parent as GenericFunctionType;
    var functionType = functionTypeNode.type as FunctionType;
    assertElement(tRef, functionType.typeFormals[0]);
  }

  test_indexExpression() async {
    String content = r'''
main() {
  var items = <int>[1, 2, 3];
  items[0];
}
''';
    addTestFile(content);

    await resolveTestFile();

    InterfaceType intType = typeProvider.intType;
    InterfaceType listIntType = typeProvider.listType(intType);

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement itemsElement;
    {
      var statement = mainStatements[0] as VariableDeclarationStatement;
      VariableDeclaration itemsNode = statement.variables.variables[0];
      itemsElement = itemsNode.declaredElement!;
      expect(itemsElement.type, listIntType);
    }

    var statement = mainStatements[1] as ExpressionStatement;
    var indexExpression = statement.expression as IndexExpression;
    expect(indexExpression.staticType, intType);

    var actualElement = indexExpression.staticElement as MethodMember;
    var expectedElement = listIntType.getMethod('[]') as MethodMember;
    expect(actualElement.name, '[]');
    expect(actualElement.declaration, same(expectedElement.declaration));
    expect(actualElement.returnType, intType);
    expect(actualElement.parameters[0].type, intType);
  }

  test_instanceCreation_factory() async {
    String content = r'''
class C {
  factory C() => throw 0;
  factory C.named() => throw 0;
}
var a = new C();
var b = new C.named();
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cNode = unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    ConstructorElement defaultConstructor = cElement.constructors[0];
    ConstructorElement namedConstructor = cElement.constructors[1];

    {
      var aDeclaration = unit.declarations[1] as TopLevelVariableDeclaration;
      VariableDeclaration aNode = aDeclaration.variables.variables[0];
      var value = aNode.initializer as InstanceCreationExpression;
      expect(value.staticType, interfaceTypeNone(cElement));

      var constructorName = value.constructorName;
      expect(constructorName.name, isNull);
      expect(constructorName.staticElement, defaultConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments, isNull);

      Identifier typeIdentifier = namedType.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, isNull);
    }

    {
      var bDeclaration = unit.declarations[2] as TopLevelVariableDeclaration;
      VariableDeclaration bNode = bDeclaration.variables.variables[0];
      var value = bNode.initializer as InstanceCreationExpression;
      expect(value.staticType, interfaceTypeNone(cElement));

      var constructorName = value.constructorName;
      expect(constructorName.staticElement, namedConstructor);
      expect(constructorName.name!.staticType, isNull);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments, isNull);

      var typeIdentifier = namedType.name as SimpleIdentifier;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, isNull);
    }
  }

  test_instanceCreation_namedArgument() async {
    addTestFile(r'''
class X {
  X(int a, {bool b, double c});
}
var v = new X(1, b: true, c: 3.0);
''');

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var xNode = unit.declarations[0] as ClassDeclaration;
    ClassElement xElement = xNode.declaredElement!;
    ConstructorElement constructorElement = xElement.constructors[0];

    var vDeclaration = unit.declarations[1] as TopLevelVariableDeclaration;
    VariableDeclaration vNode = vDeclaration.variables.variables[0];

    var creation = vNode.initializer as InstanceCreationExpression;
    List<Expression> arguments = creation.argumentList.arguments;
    expect(creation.staticType, interfaceTypeNone(xElement));

    var constructorName = creation.constructorName;
    expect(constructorName.name, isNull);
    expect(constructorName.staticElement, constructorElement);

    NamedType namedType = constructorName.type2;
    expect(namedType.typeArguments, isNull);

    Identifier typeIdentifier = namedType.name;
    expect(typeIdentifier.staticElement, xElement);
    expect(typeIdentifier.staticType, isNull);

    _assertArgumentToParameter(arguments[0], constructorElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], constructorElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], constructorElement.parameters[2]);
  }

  test_instanceCreation_noTypeArguments() async {
    String content = r'''
class C {
  C(int p);
  C.named(int p);
}
var a = new C(1);
var b = new C.named(2);
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cNode = unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    ConstructorElement defaultConstructor = cElement.constructors[0];
    ConstructorElement namedConstructor = cElement.constructors[1];

    {
      var aDeclaration = unit.declarations[1] as TopLevelVariableDeclaration;
      VariableDeclaration aNode = aDeclaration.variables.variables[0];
      var value = aNode.initializer as InstanceCreationExpression;
      expect(value.staticType, interfaceTypeNone(cElement));

      var constructorName = value.constructorName;
      expect(constructorName.name, isNull);
      expect(constructorName.staticElement, defaultConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments, isNull);

      Identifier typeIdentifier = namedType.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, isNull);

      Expression argument = value.argumentList.arguments[0];
      _assertArgumentToParameter(argument, defaultConstructor.parameters[0]);
    }

    {
      var bDeclaration = unit.declarations[2] as TopLevelVariableDeclaration;
      VariableDeclaration bNode = bDeclaration.variables.variables[0];
      var value = bNode.initializer as InstanceCreationExpression;
      expect(value.staticType, interfaceTypeNone(cElement));

      var constructorName = value.constructorName;
      expect(constructorName.staticElement, namedConstructor);
      expect(constructorName.name!.staticElement, namedConstructor);
      expect(constructorName.name!.staticType, isNull);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments, isNull);

      var typeIdentifier = namedType.name as SimpleIdentifier;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, isNull);

      Expression argument = value.argumentList.arguments[0];
      _assertArgumentToParameter(argument, namedConstructor.parameters[0]);
    }
  }

  test_instanceCreation_prefixed() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class C<T> {
  C(T p);
  C.named(T p);
}
''');
    addTestFile(r'''
import 'a.dart' as p;
main() {
  new p.C(0);
  new p.C.named(1.2);
  new p.C<bool>.named(false);
}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    ImportElement aImport = unit.declaredElement!.library.imports[0];
    LibraryElement aLibrary = aImport.importedLibrary!;

    ClassElement cElement = aLibrary.getType('C')!;
    ConstructorElement defaultConstructor = cElement.constructors[0];
    ConstructorElement namedConstructor = cElement.constructors[1];

    var statements = _getMainStatements(result);
    {
      var cTypeInt = cElement.instantiate(
        typeArguments: [typeProvider.intType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      var statement = statements[0] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      expect(creation.staticType, cTypeInt);

      var constructorName = creation.constructorName;
      expect(constructorName.name, isNull);
      expect(constructorName.staticElement, defaultConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments, isNull);

      var typeIdentifier = namedType.name as PrefixedIdentifier;
      expect(typeIdentifier.staticElement, same(cElement));
      expect(typeIdentifier.staticType, isNull);

      SimpleIdentifier typePrefix = typeIdentifier.prefix;
      expect(typePrefix.name, 'p');
      expect(typePrefix.staticElement, same(aImport.prefix));
      expect(typePrefix.staticType, isNull);

      expect(typeIdentifier.identifier.staticElement, same(cElement));
    }

    {
      var cTypeDouble = cElement.instantiate(
        typeArguments: [typeProvider.doubleType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      var statement = statements[1] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      expect(creation.staticType, cTypeDouble);

      var constructorName = creation.constructorName;
      expect(constructorName.name!.staticElement, namedConstructor);
      expect(constructorName.name!.staticType, isNull);
      expect(constructorName.staticElement, namedConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments, isNull);

      var typeIdentifier = namedType.name as PrefixedIdentifier;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, isNull);

      SimpleIdentifier typePrefix = typeIdentifier.prefix;
      expect(typePrefix.name, 'p');
      expect(typePrefix.staticElement, same(aImport.prefix));
      expect(typePrefix.staticType, isNull);

      expect(typeIdentifier.identifier.staticElement, same(cElement));
    }

    {
      var cTypeBool = cElement.instantiate(
        typeArguments: [typeProvider.boolType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      var statement = statements[2] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      expect(creation.staticType, cTypeBool);

      var constructorName = creation.constructorName;
      expect(constructorName.name!.staticElement, namedConstructor);
      expect(constructorName.name!.staticType, isNull);
      expect(constructorName.staticElement, namedConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments!.arguments, hasLength(1));
      _assertNamedTypeSimple(
          namedType.typeArguments!.arguments[0], typeProvider.boolType);

      var typeIdentifier = namedType.name as PrefixedIdentifier;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, isNull);

      SimpleIdentifier typePrefix = typeIdentifier.prefix;
      expect(typePrefix.name, 'p');
      expect(typePrefix.staticElement, same(aImport.prefix));
      expect(typePrefix.staticType, isNull);

      expect(typeIdentifier.identifier.staticElement, same(cElement));
    }
  }

  test_instanceCreation_unprefixed() async {
    addTestFile(r'''
main() {
  new C(0);
  new C<bool>(false);
  new C.named(1.2);
  new C<bool>.named(false);
}

class C<T> {
  C(T p);
  C.named(T p);
}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    ClassElement cElement = unitElement.getType('C')!;
    ConstructorElement defaultConstructor = cElement.constructors[0];
    ConstructorElement namedConstructor = cElement.constructors[1];

    var statements = _getMainStatements(result);
    {
      var cTypeInt = cElement.instantiate(
        typeArguments: [typeProvider.intType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      var statement = statements[0] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      expect(creation.staticType, cTypeInt);

      var constructorName = creation.constructorName;
      expect(constructorName.name, isNull);
      expect(constructorName.staticElement, defaultConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments, isNull);

      var typeIdentifier = namedType.name as SimpleIdentifier;
      expect(typeIdentifier.staticElement, same(cElement));
      expect(typeIdentifier.staticType, isNull);
    }

    {
      var cTypeBool = cElement.instantiate(
        typeArguments: [typeProvider.boolType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      var statement = statements[1] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      expect(creation.staticType, cTypeBool);

      var constructorName = creation.constructorName;
      expect(constructorName.name, isNull);
      expect(constructorName.staticElement, defaultConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments!.arguments, hasLength(1));
      _assertNamedTypeSimple(
          namedType.typeArguments!.arguments[0], typeProvider.boolType);

      var typeIdentifier = namedType.name as SimpleIdentifier;
      expect(typeIdentifier.staticElement, same(cElement));
      expect(typeIdentifier.staticType, isNull);
    }

    {
      var cTypeDouble = cElement.instantiate(
        typeArguments: [typeProvider.doubleType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      var statement = statements[2] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      expect(creation.staticType, cTypeDouble);

      var constructorName = creation.constructorName;
      expect(constructorName.name!.staticElement, namedConstructor);
      expect(constructorName.name!.staticType, isNull);
      expect(constructorName.staticElement, namedConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments, isNull);

      var typeIdentifier = namedType.name as SimpleIdentifier;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, isNull);
    }

    {
      var cTypeBool = cElement.instantiate(
        typeArguments: [typeProvider.boolType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      var statement = statements[3] as ExpressionStatement;
      var creation = statement.expression as InstanceCreationExpression;
      expect(creation.staticType, cTypeBool);

      var constructorName = creation.constructorName;
      expect(constructorName.name!.staticElement, namedConstructor);
      expect(constructorName.name!.staticType, isNull);
      expect(constructorName.staticElement, namedConstructor);

      NamedType namedType = constructorName.type2;
      expect(namedType.typeArguments!.arguments, hasLength(1));
      _assertNamedTypeSimple(
          namedType.typeArguments!.arguments[0], typeProvider.boolType);

      var typeIdentifier = namedType.name as SimpleIdentifier;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, isNull);
    }
  }

  test_instanceCreation_withTypeArguments() async {
    addTestFile(r'''
class C<K, V> {
  C(K k, V v);
  C.named(K k, V v);
}
var a = new C<int, double>(1, 2.3);
var b = new C<num, String>.named(4, 'five');
''');
    await resolveTestFile();

    var cElement = findElement.class_('C');
    var defaultConstructor = cElement.unnamedConstructor!;
    var namedConstructor = cElement.getNamedConstructor('named')!;

    {
      var creation = findNode.instanceCreation('new C<int, double>(1, 2.3);');

      assertMember(creation, defaultConstructor, {'K': 'int', 'V': 'double'});
      assertType(creation, 'C<int, double>');

      var namedType = creation.constructorName.type2;
      assertNamedType(namedType, cElement, 'C<int, double>');

      var typeArguments = namedType.typeArguments!.arguments;
      assertNamedType(typeArguments[0] as NamedType, intElement, 'int');
      assertNamedType(typeArguments[1] as NamedType, doubleElement, 'double');

      expect(creation.constructorName.name, isNull);

      Expression argument = creation.argumentList.arguments[0];
      _assertArgumentToParameter2(argument, 'int');
    }

    {
      var creation = findNode.instanceCreation('new C<num, String>.named');

      assertMember(creation, namedConstructor, {'K': 'num', 'V': 'String'});
      assertType(creation, 'C<num, String>');

      var namedType = creation.constructorName.type2;
      assertNamedType(namedType, cElement, 'C<num, String>');

      var typeArguments = namedType.typeArguments!.arguments;
      assertNamedType(typeArguments[0] as NamedType, numElement, 'num');
      assertNamedType(typeArguments[1] as NamedType, stringElement, 'String');

      var constructorName = creation.constructorName.name;
      assertMember(
          constructorName, namedConstructor, {'K': 'num', 'V': 'String'});
      assertType(constructorName, null);

      var argument = creation.argumentList.arguments[0];
      _assertArgumentToParameter2(argument, 'num');
    }
  }

  test_invalid_annotation_on_variable_declaration() async {
    addTestFile(r'''
const a = null;
main() {
  int x, @a y;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    // Note: no further expectations.  We don't care how the error is recovered
    // from, provided it is recovered from in a way that doesn't crash the
    // analyzer/FE integration.
  }

  test_invalid_annotation_on_variable_declaration_for() async {
    addTestFile(r'''
const a = null;
main() {
  for (var @a x = 0;;) {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    // Note: no further expectations.  We don't care how the error is recovered
    // from, provided it is recovered from in a way that doesn't crash the
    // analyzer/FE integration.
  }

  test_invalid_catch_parameters_3() async {
    addTestFile(r'''
main() {
  try { } catch (x, y, z) { }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    assertDeclaredVariableTypeObject(findNode.simple('x,'));
    assertDeclaredVariableType(findNode.simple('y,'), 'StackTrace');
  }

  test_invalid_catch_parameters_empty() async {
    addTestFile(r'''
main() {
  try { } catch () { }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
  }

  test_invalid_catch_parameters_named_stack() async {
    addTestFile(r'''
main() {
  try { } catch (e, {s}) { }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    assertDeclaredVariableTypeObject(findNode.simple('e,'));
    assertDeclaredVariableType(findNode.simple('s})'), 'StackTrace');
  }

  test_invalid_catch_parameters_optional_stack() async {
    addTestFile(r'''
main() {
  try { } catch (e, [s]) { }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    assertDeclaredVariableTypeObject(findNode.simple('e,'));
    assertDeclaredVariableType(findNode.simple('s])'), 'StackTrace');
  }

  test_invalid_const_as() async {
    addTestFile(r'''
const num a = 1.2;
const int b = a as int;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a as int');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'num');

    assertNamedType(findNode.namedType('int;'), intElement, 'int');
  }

  test_invalid_const_constructor_initializer_field_multiple() async {
    addTestFile(r'''
var a = 0;
class A {
  final x = 0;
  const A() : x = a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = a');
    assertElement(xRef, findElement.field('x'));

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_const_methodInvocation() async {
    addTestFile(r'''
const a = 'foo';
const b = 0;
const c = a.codeUnitAt(b);
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var invocation = findNode.methodInvocation('codeUnitAt');
    assertType(invocation, 'int');
    assertInvokeType(invocation, 'int Function(int)');
    assertElement(
      invocation.methodName,
      elementMatcher(
        stringElement.getMethod('codeUnitAt'),
        isLegacy: isLegacyLibrary,
      ),
    );

    var aRef = invocation.target;
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'String');

    var bRef = invocation.argumentList.arguments[0];
    assertElement(bRef, findElement.topGet('b'));
    assertType(bRef, 'int');
  }

  test_invalid_const_methodInvocation_static() async {
    addTestFile(r'''
const c = A.m();
class A {
  static int m() => 0;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var invocation = findNode.methodInvocation('m();');
    assertType(invocation, 'int');
    assertInvokeType(invocation, 'int Function()');
    assertElement(invocation.methodName, findElement.method('m'));
  }

  test_invalid_const_methodInvocation_topLevelFunction() async {
    addTestFile(r'''
const id = identical;
const a = 0;
const b = 0;
const c = id(a, b);
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var invocation = findNode.functionExpressionInvocation('id(');
    assertElement(invocation.function, findElement.topGet('id'));
    assertInvokeType(invocation, 'bool Function(Object?, Object?)');
    assertType(invocation, 'bool');

    var aRef = invocation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');

    var bRef = invocation.argumentList.arguments[1];
    assertElement(bRef, findElement.topGet('b'));
    assertType(bRef, 'int');
  }

  test_invalid_const_throw_local() async {
    addTestFile(r'''
main() {
  const c = throw 42;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var throwExpression = findNode.throw_('throw 42;');
    expect(throwExpression.staticType, isNeverType);
    assertType(throwExpression.expression, 'int');
  }

  test_invalid_const_throw_topLevel() async {
    addTestFile(r'''
const c = throw 42;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var throwExpression = findNode.throw_('throw 42;');
    expect(throwExpression.staticType, isNeverType);
    assertType(throwExpression.expression, 'int');
  }

  test_invalid_constructor_initializer_field_class() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : X = a;
}
class X {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('X = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_getter() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
  int get x => 0;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElement(xRef, findElement.field('x'));

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_importPrefix() async {
    addTestFile(r'''
import 'dart:async' as x;
var a = 0;
class A {
  A() : x = a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_method() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
  void x() {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_setter() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
  set x(_) {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElement(xRef, findElement.field('x'));

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_topLevelFunction() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
}
void x() {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_topLevelVar() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
}
int x;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.simple('x = ');
    assertElementNull(xRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_typeParameter() async {
    addTestFile(r'''
var a = 0;
class A<T> {
  A() : T = a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T = ');
    assertElementNull(tRef);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_initializer_field_unresolved() async {
    addTestFile(r'''
var a = 0;
class A {
  A() : x = a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_constructor_return_blockBody() async {
    addTestFile(r'''
int a = 0;
class C {
  C() {
    return a;
  }
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    assertTopGetRef('a;', 'a');
  }

  test_invalid_constructor_return_expressionBody() async {
    addTestFile(r'''
int a = 0;
class C {
  C() => a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    assertTopGetRef('a;', 'a');
  }

  test_invalid_deferred_type_localVariable() async {
    addTestFile(r'''
import 'dart:async' deferred as a;

main() {
  a.Future<int> v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    assertNamedType(
      findNode.namedType('a.Future'),
      futureElement,
      'Future<int>',
      expectedPrefix: findElement.import('dart:async').prefix,
    );
    assertNamedType(findNode.namedType('int>'), intElement, 'int');
  }

  test_invalid_fieldInitializer_field() async {
    addTestFile(r'''
class C {
  final int a = 0;
  final int b = a + 1;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a + 1');
    assertElement(aRef, findElement.getter('a'));
    assertType(aRef, 'int');
  }

  test_invalid_fieldInitializer_getter() async {
    addTestFile(r'''
class C {
  int get a => 0;
  final int b = a + 1;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a + 1');
    assertElement(aRef, findElement.getter('a'));
    assertType(aRef, 'int');
  }

  test_invalid_fieldInitializer_method() async {
    addTestFile(r'''
class C {
  int a() => 0;
  final int b = a + 1;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a + 1');
    assertElement(aRef, findElement.method('a'));
    assertType(aRef, 'int Function()');
  }

  test_invalid_fieldInitializer_this() async {
    addTestFile(r'''
class C {
  final b = this;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var thisRef = findNode.this_('this');
    assertType(thisRef, 'C');
  }

  test_invalid_generator_async_return_blockBody() async {
    addTestFile(r'''
int a = 0;
f() async* {
  return a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_generator_async_return_expressionBody() async {
    addTestFile(r'''
int a = 0;
f() async* => a;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_generator_sync_return_blockBody() async {
    addTestFile(r'''
int a = 0;
f() sync* {
  return a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_generator_sync_return_expressionBody() async {
    addTestFile(r'''
int a = 0;
f() sync* => a;
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_getter_parameters() async {
    addTestFile(r'''
get m(int a, double b) {
  a;
  b;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('a;');
    assertElement(aRef, findElement.parameter('a'));
    assertType(aRef, 'int');

    var bRef = findNode.simple('b;');
    assertElement(bRef, findElement.parameter('b'));
    assertType(bRef, 'double');
  }

  @failingTest
  test_invalid_instanceCreation_abstract() async {
    addTestFile(r'''
abstract class C<T> {
  C(T a);
  C.named(T a);
  C.named2();
}
var a = 0;
var b = true;
main() {
  new C(a);
  new C.named(b);
  new C<double>.named2();
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var c = findElement.class_('C');

    {
      var creation = findNode.instanceCreation('new C(a)');
      assertType(creation, 'C<int>');

      ConstructorName constructorName = creation.constructorName;
      expect(constructorName.name, isNull);

      NamedType type = constructorName.type2;
      expect(type.typeArguments, isNull);
      assertElement(type.name, c);
      assertTypeNull(type.name);

      var aRef = creation.argumentList.arguments[0] as SimpleIdentifier;
      assertElement(aRef, findElement.topGet('a'));
      assertType(aRef, 'int');
    }

    {
      var creation = findNode.instanceCreation('new C.named(b)');
      assertType(creation, 'C<bool>');

      ConstructorName constructorName = creation.constructorName;
      expect(constructorName.name!.name, 'named');

      NamedType type = constructorName.type2;
      expect(type.typeArguments, isNull);
      assertElement(type.name, c);
      assertType(type.name, 'C<bool>');

      var bRef = creation.argumentList.arguments[0] as SimpleIdentifier;
      assertElement(bRef, findElement.topGet('b'));
      assertType(bRef, 'bool');
    }

    {
      var creation = findNode.instanceCreation('new C<double>.named2()');
      assertType(creation, 'C<double>');

      ConstructorName constructorName = creation.constructorName;
      expect(constructorName.name!.name, 'named2');

      NamedType type = constructorName.type2;
      assertTypeArguments(type.typeArguments!, [doubleType]);
      assertElement(type.name, c);
      assertType(type.name, 'C<double>');
    }
  }

  test_invalid_instanceCreation_arguments_named() async {
    addTestFile(r'''
class C {
  C();
}
var a = 0;
main() {
  new C(x: a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('new C(x: a)');
    _assertConstructorInvocation(creation, classElement);

    var argument = creation.argumentList.arguments[0] as NamedExpression;
    assertElementNull(argument.name.label);
    var aRef = argument.expression;
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_instanceCreation_arguments_required_01() async {
    addTestFile(r'''
class C {
  C();
}
var a = 0;
main() {
  new C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('new C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_instanceCreation_arguments_required_21() async {
    addTestFile(r'''
class C {
  C(a, b);
}
var a = 0;
main() {
  new C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('new C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_instanceCreation_constOfNotConst_factory() async {
    addTestFile(r'''
class C {
  factory C(x) => throw 0;
}

var a = 0;
main() {
  const C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('const C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_instanceCreation_constOfNotConst_generative() async {
    addTestFile(r'''
class C {
  C(x);
}

var a = 0;
main() {
  const C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('const C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  @failingTest
  test_invalid_instanceCreation_prefixAsType() async {
    addTestFile(r'''
import 'dart:math' as p;
int a;
main() {
  new p(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    ImportElement import = findNode.import('dart:math').element!;

    var pRef = findNode.simple('p(a)');
    assertElement(pRef, import.prefix);
    assertTypeDynamic(pRef);

    var aRef = findNode.simple('a);');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_instance_method() async {
    addTestFile(r'''
class C {
  void m() {}
}
var a = 0;
main(C c) {
  c.m(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var m = findElement.method('m');

    var invocation = findNode.methodInvocation('m(a)');
    assertElement(invocation.methodName, m);
    assertType(invocation.methodName, 'void Function()');
    assertType(invocation, 'void');

    var aRef = invocation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_named_duplicate2() async {
    addTestFile(r'''
void f({p}) {}
int a, b;
main() {
  f(p: a, p: b);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var f = findElement.function('f');

    var invocation = findNode.methodInvocation('f(p: a');
    assertElement(invocation.methodName, f);
    assertType(invocation.methodName, 'void Function({dynamic p})');
    assertType(invocation, 'void');

    var arg0 = invocation.argumentList.arguments[0] as NamedExpression;
    assertElement(arg0.name.label, f.parameters[0]);
    assertIdentifierTopGetRef(arg0.expression as SimpleIdentifier, 'a');

    var arg1 = invocation.argumentList.arguments[1] as NamedExpression;
    assertElement(arg1.name.label, f.parameters[0]);
    assertIdentifierTopGetRef(arg1.expression as SimpleIdentifier, 'b');
  }

  test_invalid_invocation_arguments_named_duplicate3() async {
    addTestFile(r'''
void f({p}) {}
int a, b, c;
main() {
  f(p: a, p: b, p: c);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var f = findElement.function('f');

    var invocation = findNode.methodInvocation('f(p: a');
    assertElement(invocation.methodName, f);
    assertType(invocation.methodName, 'void Function({dynamic p})');
    assertType(invocation, 'void');

    var arg0 = invocation.argumentList.arguments[0] as NamedExpression;
    assertElement(arg0.name.label, f.parameters[0]);
    assertIdentifierTopGetRef(arg0.expression as SimpleIdentifier, 'a');

    var arg1 = invocation.argumentList.arguments[1] as NamedExpression;
    assertElement(arg1.name.label, f.parameters[0]);
    assertIdentifierTopGetRef(arg1.expression as SimpleIdentifier, 'b');

    var arg2 = invocation.argumentList.arguments[2] as NamedExpression;
    assertElement(arg2.name.label, f.parameters[0]);
    assertIdentifierTopGetRef(arg2.expression as SimpleIdentifier, 'c');
  }

  test_invalid_invocation_arguments_requiredAfterNamed() async {
    addTestFile(r'''
var a = 0;
var b = 0;
main() {
  f(p: a, b);
}
void f({p}) {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    assertTopGetRef('a, ', 'a');
    assertTopGetRef('b);', 'b');
  }

  test_invalid_invocation_arguments_static_method() async {
    addTestFile(r'''
class C {
  static void m() {}
}
var a = 0;
main() {
  C.m(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var m = findElement.method('m');

    var invocation = findNode.methodInvocation('m(a)');
    assertElement(invocation.methodName, m);
    assertType(invocation.methodName, 'void Function()');
    assertType(invocation, 'void');

    var aRef = invocation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_static_redirectingConstructor() async {
    addTestFile(r'''
class C {
  factory C() = C.named;
  C.named();
}

int a;
main() {
  new C(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var classElement = findElement.class_('C');

    var creation = findNode.instanceCreation('new C(a)');
    _assertConstructorInvocation(creation, classElement);

    var aRef = creation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_static_topLevelFunction() async {
    addTestFile(r'''
void f() {}
var a = 0;
main() {
  f(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var f = findElement.function('f');

    var invocation = findNode.methodInvocation('f(a)');
    assertElement(invocation.methodName, f);
    assertType(invocation.methodName, 'void Function()');
    assertType(invocation, 'void');

    var aRef = invocation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_arguments_static_topLevelVariable() async {
    addTestFile(r'''
void Function() f;
var a = 0;
main() {
  f(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    var f = findElement.topGet('f');

    var invocation = findNode.functionExpressionInvocation('f(a)');
    assertElement(invocation.function, f);
    assertInvokeType(invocation, 'void Function()');
    assertType(invocation, 'void');

    var aRef = invocation.argumentList.arguments[0];
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_invocation_prefixAsMethodName() async {
    addTestFile(r'''
import 'dart:math' as p;
int a;
main() {
  p(a);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    ImportElement import = findNode.import('dart:math').element!;

    var invocation = findNode.methodInvocation('p(a)');
    expect(invocation.staticType, isDynamicType);
    assertUnresolvedInvokeType(invocation.staticInvokeType!);

    var pRef = invocation.methodName;
    assertElement(pRef, import.prefix);
    assertTypeDynamic(pRef);

    var aRef = findNode.simple('a);');
    assertElement(aRef, findElement.topGet('a'));
    assertType(aRef, 'int');
  }

  test_invalid_methodInvocation_simpleIdentifier() async {
    addTestFile(r'''
int foo = 0;
main() {
  foo(1);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var invocation = findNode.functionExpressionInvocation('foo(1)');
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    assertElement(invocation.function, findElement.topGet('foo'));
    assertType(invocation.function, 'int');
  }

  @failingTest
  test_invalid_nonTypeAsType_class_constructor() async {
    addTestFile(r'''
class A {
  A.T();
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_class_instanceField() async {
    addTestFile(r'''
class A {
  int T;
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_class_instanceMethod() async {
    addTestFile(r'''
class A {
  int T() => 0;
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_class_staticField() async {
    addTestFile(r'''
class A {
  static int T;
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_class_staticMethod() async {
    addTestFile(r'''
class A {
  static int T() => 0;
}
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.class_('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelFunction() async {
    addTestFile(r'''
int T() => 0;
main() {
  T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, findElement.topFunction('T'));
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelFunction_prefixed() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
int T() => 0;
''');
    addTestFile(r'''
import 'a.dart' as p;
main() {
  p.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    ImportElement import = findNode.import('a.dart').element!;
    var tElement = import.importedLibrary!.publicNamespace.get('T');

    var prefixedName = findNode.prefixed('p.T');
    assertTypeDynamic(prefixedName);

    var pRef = prefixedName.prefix;
    assertElement(pRef, import.prefix);
    expect(pRef.staticType, null);

    var tRef = prefixedName.identifier;
    assertElement(tRef, tElement);
    assertTypeDynamic(tRef);

    var namedType = prefixedName.parent as NamedType;
    expect(namedType.type, isDynamicType);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelVariable() async {
    addTestFile(r'''
int T;
main() {
  T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, findElement.topGet('T'));
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelVariable_name() async {
    addTestFile(r'''
int A;
main() {
  A.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var aRef = findNode.simple('A.T v;');
    assertElement(aRef, findElement.topGet('A'));
    assertTypeDynamic(aRef);

    var tRef = findNode.simple('T v;');
    assertElement(tRef, null);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_topLevelVariable_prefixed() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
int T;
''');
    addTestFile(r'''
import 'a.dart' as p;
main() {
  p.T v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    ImportElement import = findNode.import('a.dart').element!;
    var tElement = import.importedLibrary!.publicNamespace.get('T');

    var prefixedName = findNode.prefixed('p.T');
    assertTypeDynamic(prefixedName);

    var pRef = prefixedName.prefix;
    assertElement(pRef, import.prefix);
    expect(pRef.staticType, null);

    var tRef = prefixedName.identifier;
    assertElement(tRef, tElement);
    assertTypeDynamic(tRef);

    var namedType = prefixedName.parent as NamedType;
    expect(namedType.type, isDynamicType);
  }

  @failingTest
  test_invalid_nonTypeAsType_typeParameter_name() async {
    addTestFile(r'''
main<T>() {
  T.U v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T.U v;');
    var tElement = findNode.typeParameter('T>()').declaredElement!;
    assertElement(tRef, tElement);
    assertTypeDynamic(tRef);
  }

  @failingTest
  test_invalid_nonTypeAsType_unresolved_name() async {
    addTestFile(r'''
main() {
  T.U v;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.simple('T.U v;');
    assertElementNull(tRef);
    assertTypeDynamic(tRef);
  }

  test_invalid_rethrow() async {
    addTestFile('''
main() {
  rethrow;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var rethrowExpression = findNode.rethrow_('rethrow;');
    expect(rethrowExpression.staticType, isNeverType);
  }

  test_invalid_tryCatch_1() async {
    addTestFile(r'''
main() {
  try {}
  catch String catch (e) {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
  }

  test_invalid_tryCatch_2() async {
    addTestFile(r'''
main() {
  try {}
  catch catch (e) {}
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
  }

  test_isExpression() async {
    await assertNoErrorsInCode(r'''
void f(var a) {
  a is num;
}
''');

    var isExpression = findNode.isExpression('a is num');
    expect(isExpression.notOperator, isNull);
    expect(isExpression.staticType, typeProvider.boolType);

    var target = isExpression.expression as SimpleIdentifier;
    expect(target.staticElement, findElement.parameter('a'));
    expect(target.staticType, dynamicType);

    var numName = isExpression.type as NamedType;
    expect(numName.name.staticElement, typeProvider.numType.element);
    expect(numName.name.staticType, isNull);
  }

  test_isExpression_not() async {
    await assertNoErrorsInCode(r'''
void f(var a) {
  a is! num;
}
''');

    var isExpression = findNode.isExpression('a is! num');
    expect(isExpression.notOperator, isNotNull);
    expect(isExpression.staticType, typeProvider.boolType);

    var target = isExpression.expression as SimpleIdentifier;
    expect(target.staticElement, findElement.parameter('a'));
    expect(target.staticType, dynamicType);

    var numName = isExpression.type as NamedType;
    expect(numName.name.staticElement, typeProvider.numType.element);
    expect(numName.name.staticType, isNull);
  }

  test_label_while() async {
    addTestFile(r'''
main() {
  myLabel:
  while (true) {
    continue myLabel;
    break myLabel;
  }
}
''');
    await resolveTestFile();
    List<Statement> statements = _getMainStatements(result);

    var statement = statements[0] as LabeledStatement;

    Label label = statement.labels.single;
    var labelElement = label.label.staticElement as LabelElement;

    var whileStatement = statement.statement as WhileStatement;
    var whileBlock = whileStatement.body as Block;

    var continueStatement = whileBlock.statements[0] as ContinueStatement;
    expect(continueStatement.label!.staticElement, same(labelElement));
    expect(continueStatement.label!.staticType, isNull);

    var breakStatement = whileBlock.statements[1] as BreakStatement;
    expect(breakStatement.label!.staticElement, same(labelElement));
    expect(breakStatement.label!.staticType, isNull);
  }

  test_listLiteral_01() async {
    addTestFile(r'''
main() {
  var v = [];
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var literal = findNode.listLiteral('[];');
    expect(literal.typeArguments, isNull);
    assertType(literal, 'List<dynamic>');
  }

  test_listLiteral_02() async {
    addTestFile(r'''
main() {
  var v = <>[];
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var literal = findNode.listLiteral('[];');
    expect(literal.typeArguments, isNotNull);
    assertType(literal, 'List<dynamic>');
  }

  test_listLiteral_2() async {
    addTestFile(r'''
main() {
  var v = <int, double>[];
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var literal = findNode.listLiteral('<int, double>[]');
    assertType(literal, 'List<dynamic>');

    var intRef = findNode.simple('int, double');
    assertElement(intRef, intElement);
    assertTypeNull(intRef);

    var doubleRef = findNode.simple('double>[]');
    assertElement(doubleRef, doubleElement);
    assertTypeNull(doubleRef);
  }

  test_local_function() async {
    addTestFile(r'''
void main() {
  double f(int a, String b) {}
  var v = f(1, '2');
}
''');
    String fTypeString = 'double Function(int, String)';

    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    InterfaceType doubleType = typeProvider.doubleType;

    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    var fElement = fNode.declaredElement as FunctionElement;
    expect(fElement, isNotNull);
    assertType(fElement.type, fTypeString);

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, isNull);

    var fReturnTypeNode = fNode.returnType as NamedType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);

    expect(fExpression.declaredElement, same(fElement));

    {
      List<ParameterElement> elements = fElement.parameters;
      expect(elements, hasLength(2));

      List<FormalParameter> nodes = fExpression.parameters!.parameters;
      expect(nodes, hasLength(2));

      _assertSimpleParameter(nodes[0] as SimpleFormalParameter, elements[0],
          name: 'a',
          offset: 29,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      _assertSimpleParameter(nodes[1] as SimpleFormalParameter, elements[1],
          name: 'b',
          offset: 39,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.stringType);
    }

    var vStatement = mainStatements[1] as VariableDeclarationStatement;
    VariableDeclaration vDeclaration = vStatement.variables.variables[0];
    expect(vDeclaration.declaredElement!.type, doubleType);

    var fInvocation = vDeclaration.initializer as MethodInvocation;
    expect(fInvocation.methodName.staticElement, same(fElement));
    assertType(fInvocation.methodName, fTypeString);
    expect(fInvocation.staticType, doubleType);
    assertInvokeType(fInvocation, fTypeString);
  }

  test_local_function_call_with_incomplete_closure_argument() async {
    addTestFile('''
void main() {
  f(x) => null;
  f(=> 42);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
    // Note: no further expectations.  We don't care how the error is recovered
    // from, provided it is recovered from in a way that doesn't crash the
    // analyzer/FE integration.
  }

  @failingTest
  test_local_function_generic() async {
    addTestFile(r'''
void main() {
  T f<T, U>(T a, U b) {
    a;
    b;
  }
  var v = f(1, '2');
}
''');
    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    var fElement = fNode.declaredElement as FunctionElement;

    TypeParameterElement tElement = fElement.typeParameters[0];
    TypeParameterElement uElement = fElement.typeParameters[1];

    {
      var fTypeParameters = fExpression.typeParameters!.typeParameters;
      expect(fTypeParameters, hasLength(2));

      TypeParameter tNode = fTypeParameters[0];
      expect(tNode.declaredElement, same(tElement));
      expect(tNode.name.staticElement, same(tElement));
      expect(tNode.name.staticType, typeProvider.typeType);

      TypeParameter uNode = fTypeParameters[1];
      expect(uNode.declaredElement, same(uElement));
      expect(uNode.name.staticElement, same(uElement));
      expect(uNode.name.staticType, typeProvider.typeType);
    }

    expect(fElement, isNotNull);
    assertType(fElement.type, 'T Function<T,U>(T, U)');

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, fElement.type);

    var fReturnTypeNode = fNode.returnType as NamedType;
    expect(fReturnTypeNode.name.staticElement, same(tElement));
    expect(fReturnTypeNode.type, typeParameterTypeStar(tElement));

    expect(fExpression.declaredElement, same(fElement));

    {
      List<ParameterElement> parameters = fElement.parameters;
      expect(parameters, hasLength(2));

      List<FormalParameter> nodes = fExpression.parameters!.parameters;
      expect(nodes, hasLength(2));

      _assertSimpleParameter(nodes[0] as SimpleFormalParameter, parameters[0],
          name: 'a',
          offset: 28,
          kind: ParameterKind.REQUIRED,
          type: typeParameterTypeStar(tElement));

      _assertSimpleParameter(nodes[1] as SimpleFormalParameter, parameters[1],
          name: 'b',
          offset: 33,
          kind: ParameterKind.REQUIRED,
          type: typeParameterTypeStar(uElement));

      var aRef = findNode.simple('a;');
      assertElement(aRef, parameters[0]);
      assertType(aRef, 'T');

      var bRef = findNode.simple('b;');
      assertElement(bRef, parameters[1]);
      assertType(bRef, 'U');
    }

    var vStatement = mainStatements[1] as VariableDeclarationStatement;
    VariableDeclaration vDeclaration = vStatement.variables.variables[0];
    expect(vDeclaration.declaredElement!.type, typeProvider.intType);

    var fInvocation = vDeclaration.initializer as MethodInvocation;
    expect(fInvocation.methodName.staticElement, same(fElement));
    expect(fInvocation.staticType, typeProvider.intType);

    assertTypeNull(fInvocation.methodName);
    assertInvokeType(fInvocation, 'int Function(int, String)');
  }

  test_local_function_generic_f_bounded() async {
    addTestFile('''
void main() {
  void F<T extends U, U, V extends U>(T x, U y, V z) {}
}
''');
    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    var fElement = fNode.declaredElement as FunctionElement;

    assertType(
        fElement.type, 'void Function<T extends U, U, V extends U>(T, U, V)');
    var tElement = fElement.typeParameters[0];
    var uElement = fElement.typeParameters[1];
    var vElement = fElement.typeParameters[2];
    expect((tElement.bound as TypeParameterType).element, same(uElement));
    expect((vElement.bound as TypeParameterType).element, same(uElement));
  }

  test_local_function_generic_with_named_parameter() async {
    addTestFile('''
void main() {
  void F<T>({T x}) {}
}
''');
    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    var fElement = fNode.declaredElement as FunctionElement;

    assertType(fElement.type, 'void Function<T>({T x})');
    var tElement = fElement.typeParameters[0];
    expect(fElement.type.typeFormals[0], same(tElement));
    expect((fElement.type.parameters[0].type as TypeParameterType).element,
        same(tElement));
  }

  test_local_function_generic_with_optional_parameter() async {
    addTestFile('''
void main() {
  void F<T>([T x]) {}
}
''');
    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    var fElement = fNode.declaredElement as FunctionElement;

    assertType(fElement.type, 'void Function<T>([T])');
    var tElement = fElement.typeParameters[0];
    expect(fElement.type.typeFormals[0], same(tElement));
    expect((fElement.type.parameters[0].type as TypeParameterType).element,
        same(tElement));
  }

  test_local_function_namedParameters() async {
    addTestFile(r'''
void main() {
  double f(int a, {String b, bool c: false}) {}
  f(1, b: '2', c: true);
}
''');
    String fTypeString = 'double Function(int, {String b, bool c})';

    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    InterfaceType doubleType = typeProvider.doubleType;

    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    var fElement = fNode.declaredElement as FunctionElement;
    expect(fElement, isNotNull);
    assertType(fElement.type, fTypeString);

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, isNull);

    var fReturnTypeNode = fNode.returnType as NamedType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);

    expect(fExpression.declaredElement, same(fElement));

    {
      List<ParameterElement> elements = fElement.parameters;
      expect(elements, hasLength(3));

      List<FormalParameter> nodes = fExpression.parameters!.parameters;
      expect(nodes, hasLength(3));

      _assertSimpleParameter(nodes[0] as SimpleFormalParameter, elements[0],
          name: 'a',
          offset: 29,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      _assertDefaultParameter(nodes[1] as DefaultFormalParameter, elements[1],
          name: 'b',
          offset: 40,
          kind: ParameterKind.NAMED,
          type: typeProvider.stringType);

      _assertDefaultParameter(nodes[2] as DefaultFormalParameter, elements[2],
          name: 'c',
          offset: 48,
          kind: ParameterKind.NAMED,
          type: typeProvider.boolType);
    }

    {
      var statement = mainStatements[1] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;
      List<Expression> arguments = invocation.argumentList.arguments;

      _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
      _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
      _assertArgumentToParameter(arguments[2], fElement.parameters[2]);
    }
  }

  test_local_function_noReturnType() async {
    addTestFile(r'''
void main() {
  f() {}
}
''');

    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    var fElement = fNode.declaredElement as FunctionElement;

    expect(fNode.returnType, isNull);
    expect(fElement, isNotNull);
    assertType(fElement.type, 'Null Function()');

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, isNull);

    expect(fExpression.declaredElement, same(fElement));
  }

  test_local_function_optionalParameters() async {
    addTestFile(r'''
void main() {
  double f(int a, [String b, bool c]) {}
  var v = f(1, '2', true);
}
''');
    String fTypeString = 'double Function(int, [String, bool])';

    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    InterfaceType doubleType = typeProvider.doubleType;

    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    var fElement = fNode.declaredElement as FunctionElement;
    expect(fElement, isNotNull);
    assertType(fElement.type, fTypeString);

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, isNull);

    var fReturnTypeNode = fNode.returnType as NamedType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);

    expect(fExpression.declaredElement, same(fElement));

    {
      List<ParameterElement> elements = fElement.parameters;
      expect(elements, hasLength(3));

      List<FormalParameter> nodes = fExpression.parameters!.parameters;
      expect(nodes, hasLength(3));

      _assertSimpleParameter(nodes[0] as SimpleFormalParameter, elements[0],
          name: 'a',
          offset: 29,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      _assertDefaultParameter(nodes[1] as DefaultFormalParameter, elements[1],
          name: 'b',
          offset: 40,
          kind: ParameterKind.POSITIONAL,
          type: typeProvider.stringType);

      _assertDefaultParameter(nodes[2] as DefaultFormalParameter, elements[2],
          name: 'c',
          offset: 48,
          kind: ParameterKind.POSITIONAL,
          type: typeProvider.boolType);
    }

    {
      var statement = mainStatements[1] as VariableDeclarationStatement;
      VariableDeclaration declaration = statement.variables.variables[0];
      expect(declaration.declaredElement!.type, doubleType);

      var invocation = declaration.initializer as MethodInvocation;
      expect(invocation.methodName.staticElement, same(fElement));
      assertType(invocation.methodName, fTypeString);
      expect(invocation.staticType, doubleType);
      assertInvokeType(invocation, fTypeString);

      List<Expression> arguments = invocation.argumentList.arguments;
      _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
      _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
      _assertArgumentToParameter(arguments[2], fElement.parameters[2]);
    }
  }

  test_local_function_with_function_typed_parameter() async {
    addTestFile('''
class C {}
class D {}
class E {}
void f() {
  void g(C callback<T extends E>(D d)) {}
}
''');
    await resolveTestFile();
    var callbackIdentifier = findNode.simple('callback<');
    var callbackElement = callbackIdentifier.staticElement as ParameterElement;
    assertType(callbackElement.type, 'C Function<T extends E>(D)');
    var cReference = findNode.simple('C callback');
    var cElement = findElement.class_('C');
    assertTypeNull(cReference);
    assertElement(cReference, cElement);
    var dReference = findNode.simple('D d');
    var dElement = findElement.class_('D');
    assertTypeNull(dReference);
    assertElement(dReference, dElement);
    var eReference = findNode.simple('E>');
    var eElement = findElement.class_('E');
    assertTypeNull(eReference);
    assertElement(eReference, eElement);
  }

  test_local_parameter() async {
    await assertNoErrorsInCode(r'''
void main(List<String> p) {
  p;
}
''');

    var main = result.unit.declarations[0] as FunctionDeclaration;
    List<Statement> statements = _getMainStatements(result);

    // (int p)
    VariableElement pElement = main.declaredElement!.parameters[0];
    expect(pElement.type, listNone(typeProvider.stringType));

    // p;
    {
      var statement = statements[0] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;
      expect(identifier.staticElement, pElement);
      expect(identifier.staticType, listNone(typeProvider.stringType));
    }
  }

  test_local_parameter_ofLocalFunction() async {
    addTestFile(r'''
void main() {
  void f(int a) {
    a;
    void g(double b) {
      b;
    }
  }
}
''');
    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    // f(int a) {}
    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    var fElement = fNode.declaredElement as FunctionElement;
    ParameterElement aElement = fElement.parameters[0];
    _assertSimpleParameter(
        fExpression.parameters!.parameters[0] as SimpleFormalParameter,
        aElement,
        name: 'a',
        offset: 27,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    var fBody = fExpression.body as BlockFunctionBody;
    List<Statement> fStatements = fBody.block.statements;

    // a;
    var aStatement = fStatements[0] as ExpressionStatement;
    var aNode = aStatement.expression as SimpleIdentifier;
    expect(aNode.staticElement, same(aElement));
    expect(aNode.staticType, typeProvider.intType);

    // g(double b) {}
    var gStatement = fStatements[1] as FunctionDeclarationStatement;
    FunctionDeclaration gNode = gStatement.functionDeclaration;
    FunctionExpression gExpression = gNode.functionExpression;
    var gElement = gNode.declaredElement as FunctionElement;
    ParameterElement bElement = gElement.parameters[0];
    _assertSimpleParameter(
        gExpression.parameters!.parameters[0] as SimpleFormalParameter,
        bElement,
        name: 'b',
        offset: 57,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.doubleType);

    var gBody = gExpression.body as BlockFunctionBody;
    List<Statement> gStatements = gBody.block.statements;

    // b;
    var bStatement = gStatements[0] as ExpressionStatement;
    var bNode = bStatement.expression as SimpleIdentifier;
    expect(bNode.staticElement, same(bElement));
    expect(bNode.staticType, typeProvider.doubleType);
  }

  test_local_type_parameter_reference_as_expression() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    T;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var bodyStatement = body.block.statements[0] as ExpressionStatement;
    var tReference = bodyStatement.expression as SimpleIdentifier;
    assertElement(tReference, tElement);
    assertType(tReference, 'Type');
  }

  test_local_type_parameter_reference_function_named_parameter_type() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    void Function({T t}) g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var gDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var gType = gDeclaration.variables.type as GenericFunctionType;
    var gTypeType = gType.type as FunctionType;
    var gTypeParameterType =
        gTypeType.namedParameterTypes['t'] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));
    var gParameterType =
        ((gType.parameters.parameters[0] as DefaultFormalParameter).parameter
                as SimpleFormalParameter)
            .type as NamedType;
    var tReference = gParameterType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_function_normal_parameter_type() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    void Function(T) g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var gDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var gType = gDeclaration.variables.type as GenericFunctionType;
    var gTypeType = gType.type as FunctionType;
    var gTypeParameterType =
        gTypeType.normalParameterTypes[0] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));
    var gParameterType =
        (gType.parameters.parameters[0] as SimpleFormalParameter).type
            as NamedType;
    var tReference = gParameterType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_function_optional_parameter_type() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    void Function([T]) g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var gDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var gType = gDeclaration.variables.type as GenericFunctionType;
    var gTypeType = gType.type as FunctionType;
    var gTypeParameterType =
        gTypeType.optionalParameterTypes[0] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));
    var gParameterType =
        ((gType.parameters.parameters[0] as DefaultFormalParameter).parameter
                as SimpleFormalParameter)
            .type as NamedType;
    var tReference = gParameterType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_function_return_type() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    T Function() g = () => x;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var gDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var gType = gDeclaration.variables.type as GenericFunctionType;
    var gTypeType = gType.type as FunctionType;
    var gTypeReturnType = gTypeType.returnType as TypeParameterType;
    expect(gTypeReturnType.element, same(tElement));
    var gReturnType = gType.returnType as NamedType;
    var tReference = gReturnType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_interface_type_parameter() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    List<T> y = [x];
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var yDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var yType = yDeclaration.variables.type as NamedType;
    var yTypeType = yType.type as InterfaceType;
    var yTypeTypeArgument = yTypeType.typeArguments[0] as TypeParameterType;
    expect(yTypeTypeArgument.element, same(tElement));
    var yElementType = yType.typeArguments!.arguments[0] as NamedType;
    var tReference = yElementType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_simple() async {
    addTestFile('''
void main() {
  void f<T>(T x) {
    T y = x;
  }
  f(1);
}
''');
    await resolveTestFile();

    var mainStatements = _getMainStatements(result);
    var fDeclaration = mainStatements[0] as FunctionDeclarationStatement;
    var fElement = fDeclaration.functionDeclaration.declaredElement!;
    var tElement = fElement.typeParameters[0];
    var body = fDeclaration.functionDeclaration.functionExpression.body
        as BlockFunctionBody;
    var yDeclaration = body.block.statements[0] as VariableDeclarationStatement;
    var yType = yDeclaration.variables.type as NamedType;
    var tReference = yType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_typedef_named_parameter_type() async {
    addTestFile('''
typedef void Consumer<U>({U u});
void main() {
  void f<T>(T x) {
    Consumer<T> g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var tElement = findNode.typeParameter('T>(T x)').declaredElement!;

    var gType = findNode.namedType('Consumer<T>');
    var gTypeType = gType.type as FunctionType;

    var gTypeParameterType =
        gTypeType.namedParameterTypes['u'] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));

    var gArgumentType = gType.typeArguments!.arguments[0] as NamedType;
    var tReference = gArgumentType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_typedef_normal_parameter_type() async {
    addTestFile('''
typedef void Consumer<U>(U u);
void main() {
  void f<T>(T x) {
    Consumer<T> g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var tElement = findNode.typeParameter('T>(T x)').declaredElement!;

    var gType = findNode.namedType('Consumer<T>');
    var gTypeType = gType.type as FunctionType;

    var gTypeParameterType =
        gTypeType.normalParameterTypes[0] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));

    var gArgumentType = gType.typeArguments!.arguments[0] as NamedType;
    var tReference = gArgumentType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_typedef_optional_parameter_type() async {
    addTestFile('''
typedef void Consumer<U>([U u]);
void main() {
  void f<T>(T x) {
    Consumer<T> g = null;
  }
  f(1);
}
''');
    await resolveTestFile();

    var tElement = findNode.typeParameter('T>(T x)').declaredElement!;

    var gType = findNode.namedType('Consumer<T>');
    var gTypeType = gType.type as FunctionType;

    var gTypeParameterType =
        gTypeType.optionalParameterTypes[0] as TypeParameterType;
    expect(gTypeParameterType.element, same(tElement));

    var gArgumentType = gType.typeArguments!.arguments[0] as NamedType;
    var tReference = gArgumentType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_type_parameter_reference_typedef_return_type() async {
    addTestFile('''
typedef U Producer<U>();
void main() {
  void f<T>(T x) {
    Producer<T> g = () => x;
  }
  f(1);
}
''');
    await resolveTestFile();

    var tElement = findNode.typeParameter('T>(T x)').declaredElement!;

    var gType = findNode.namedType('Producer<T>');
    var gTypeType = gType.type as FunctionType;

    var gTypeReturnType = gTypeType.returnType as TypeParameterType;
    expect(gTypeReturnType.element, same(tElement));

    var gArgumentType = gType.typeArguments!.arguments[0] as NamedType;
    var tReference = gArgumentType.name;
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_local_variable() async {
    await assertNoErrorsInCode(r'''
void main() {
  var v = 42;
  v;
}
''');

    InterfaceType intType = typeProvider.intType;

    var main = result.unit.declarations[0] as FunctionDeclaration;
    expect(main.declaredElement, isNotNull);
    expect(main.name.staticElement, isNotNull);
    expect(main.name.staticType, isNull);

    var body = main.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;

    // var v = 42;
    VariableElement vElement;
    {
      var statement = statements[0] as VariableDeclarationStatement;
      VariableDeclaration vNode = statement.variables.variables[0];
      expect(vNode.name.staticType, isNull);
      expect(vNode.initializer!.staticType, intType);

      vElement = vNode.name.staticElement as VariableElement;
      expect(vElement, isNotNull);
      expect(vElement.type, isNotNull);
      expect(vElement.type, intType);
    }

    // v;
    {
      var statement = statements[1] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;
      expect(identifier.staticElement, same(vElement));
      expect(identifier.staticType, intType);
    }
  }

  test_local_variable_forIn_identifier_field() async {
    addTestFile(r'''
class C {
  num v;
  void foo() {
    for (v in <int>[]) {
      v;
    }
  }
}
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cDeclaration = unit.declarations[0] as ClassDeclaration;

    var vDeclaration = cDeclaration.members[0] as FieldDeclaration;
    VariableDeclaration vNode = vDeclaration.fields.variables[0];
    var vElement = vNode.declaredElement as FieldElement;
    expect(vElement.type, typeProvider.numType);

    var fooDeclaration = cDeclaration.members[1] as MethodDeclaration;
    var fooBody = fooDeclaration.body as BlockFunctionBody;
    List<Statement> statements = fooBody.block.statements;

    var forEachStatement = statements[0] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithIdentifier;

    SimpleIdentifier vInFor = forEachParts.identifier;
    expect(vInFor.staticElement, same(vElement.setter));
    expect(vInFor.staticType, typeProvider.numType);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, same(vElement.getter));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_identifier_localVariable() async {
    addTestFile(r'''
void main() {
  num v;
  for (v in <int>[]) {
    v;
  }
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var vStatement = statements[0] as VariableDeclarationStatement;
    VariableDeclaration vNode = vStatement.variables.variables[0];
    var vElement = vNode.declaredElement as LocalVariableElement;
    expect(vElement.type, typeProvider.numType);

    var forEachStatement = statements[1] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithIdentifier;

    SimpleIdentifier vInFor = forEachParts.identifier;
    expect(vInFor.staticElement, vElement);
    expect(vInFor.staticType, typeProvider.numType);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, same(vElement));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_identifier_topLevelVariable() async {
    addTestFile(r'''
void main() {
  for (v in <int>[]) {
    v;
  }
}
num v;
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    List<Statement> statements = _getMainStatements(result);

    var vDeclaration = unit.declarations[1] as TopLevelVariableDeclaration;
    VariableDeclaration vNode = vDeclaration.variables.variables[0];
    var vElement = vNode.declaredElement as TopLevelVariableElement;
    expect(vElement.type, typeProvider.numType);

    var forEachStatement = statements[0] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithIdentifier;

    SimpleIdentifier vInFor = forEachParts.identifier;
    expect(vInFor.staticElement, same(vElement.setter));
    expect(vInFor.staticType, typeProvider.numType);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, same(vElement.getter));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_loopVariable() async {
    addTestFile(r'''
void main() {
  for (var v in <int>[]) {
    v;
  }
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var forEachStatement = statements[0] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithDeclaration;

    DeclaredIdentifier vNode = forEachParts.loopVariable;
    LocalVariableElement vElement = vNode.declaredElement!;
    expect(vElement.type, typeProvider.intType);

    expect(vNode.identifier.staticElement, vElement);
    expect(vNode.identifier.staticType, isNull);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, vElement);
    expect(identifier.staticType, typeProvider.intType);
  }

  test_local_variable_forIn_loopVariable_explicitType() async {
    addTestFile(r'''
void main() {
  for (num v in <int>[]) {
    v;
  }
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var forEachStatement = statements[0] as ForStatement;
    var forBlock = forEachStatement.body as Block;
    var forEachParts =
        forEachStatement.forLoopParts as ForEachPartsWithDeclaration;

    DeclaredIdentifier vNode = forEachParts.loopVariable;
    LocalVariableElement vElement = vNode.declaredElement!;
    expect(vElement.type, typeProvider.numType);

    var vNamedType = vNode.type as NamedType;
    expect(vNamedType.type, typeProvider.numType);

    var vTypeIdentifier = vNamedType.name as SimpleIdentifier;
    expect(vTypeIdentifier.staticElement, typeProvider.numType.element);
    expect(vTypeIdentifier.staticType, isNull);

    expect(vNode.identifier.staticElement, vElement);
    expect(vNode.identifier.staticType, isNull);

    var statement = forBlock.statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, vElement);
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_multiple() async {
    addTestFile(r'''
void main() {
  var a = 1, b = 2.3;
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var declarationStatement = statements[0] as VariableDeclarationStatement;

    VariableDeclaration aNode = declarationStatement.variables.variables[0];
    var aElement = aNode.declaredElement as LocalVariableElement;
    expect(aElement.type, typeProvider.intType);

    VariableDeclaration bNode = declarationStatement.variables.variables[1];
    var bElement = bNode.declaredElement as LocalVariableElement;
    expect(bElement.type, typeProvider.doubleType);
  }

  test_local_variable_ofLocalFunction() async {
    addTestFile(r'''
void main() {
  void f() {
    int a;
    a;
    void g() {
      double b;
      a;
      b;
    }
  }
}
''');
    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    // f() {}
    var fStatement = mainStatements[0] as FunctionDeclarationStatement;
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    var fBody = fNode.functionExpression.body as BlockFunctionBody;
    List<Statement> fStatements = fBody.block.statements;

    // int a;
    var aDeclaration = fStatements[0] as VariableDeclarationStatement;
    VariableElement aElement =
        aDeclaration.variables.variables[0].declaredElement!;

    // a;
    {
      var aStatement = fStatements[1] as ExpressionStatement;
      var aNode = aStatement.expression as SimpleIdentifier;
      expect(aNode.staticElement, same(aElement));
      expect(aNode.staticType, typeProvider.intType);
    }

    // g(double b) {}
    var gStatement = fStatements[2] as FunctionDeclarationStatement;
    FunctionDeclaration gNode = gStatement.functionDeclaration;
    var gBody = gNode.functionExpression.body as BlockFunctionBody;
    List<Statement> gStatements = gBody.block.statements;

    // double b;
    var bDeclaration = gStatements[0] as VariableDeclarationStatement;
    VariableElement bElement =
        bDeclaration.variables.variables[0].declaredElement!;

    // a;
    {
      var aStatement = gStatements[1] as ExpressionStatement;
      var aNode = aStatement.expression as SimpleIdentifier;
      expect(aNode.staticElement, same(aElement));
      expect(aNode.staticType, typeProvider.intType);
    }

    // b;
    {
      var bStatement = gStatements[2] as ExpressionStatement;
      var bNode = bStatement.expression as SimpleIdentifier;
      expect(bNode.staticElement, same(bElement));
      expect(bNode.staticType, typeProvider.doubleType);
    }
  }

  test_mapLiteral() async {
    addTestFile(r'''
void main() {
  <int, double>{};
  const <bool, String>{};
}
''');
    await resolveTestFile();

    var statements = _getMainStatements(result);

    {
      var statement = statements[0] as ExpressionStatement;
      var mapLiteral = statement.expression as SetOrMapLiteral;
      expect(mapLiteral.staticType,
          typeProvider.mapType(typeProvider.intType, typeProvider.doubleType));
    }

    {
      var statement = statements[1] as ExpressionStatement;
      var mapLiteral = statement.expression as SetOrMapLiteral;
      expect(mapLiteral.staticType,
          typeProvider.mapType(typeProvider.boolType, typeProvider.stringType));
    }
  }

  test_mapLiteral_3() async {
    addTestFile(r'''
main() {
  var v = <bool, int, double>{};
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var literal = findNode.setOrMapLiteral('<bool, int, double>{}');
    assertType(literal, 'Map<dynamic, dynamic>');

    var boolRef = findNode.simple('bool, ');
    assertElement(boolRef, boolElement);
    assertTypeNull(boolRef);

    var intRef = findNode.simple('int, ');
    assertElement(intRef, intElement);
    assertTypeNull(intRef);

    var doubleRef = findNode.simple('double>');
    assertElement(doubleRef, doubleElement);
    assertTypeNull(doubleRef);
  }

  test_method_namedParameters() async {
    addTestFile(r'''
class C {
  double f(int a, {String b, bool c: false}) {}
}
void g(C c) {
  c.f(1, b: '2', c: true);
}
''');
    String fTypeString = 'double Function(int, {String b, bool c})';

    await resolveTestFile();
    var classDeclaration = result.unit.declarations[0] as ClassDeclaration;
    var methodDeclaration = classDeclaration.members[0] as MethodDeclaration;
    var methodElement = methodDeclaration.declaredElement as MethodElement;

    InterfaceType doubleType = typeProvider.doubleType;

    expect(methodElement, isNotNull);
    assertType(methodElement.type, fTypeString);

    expect(methodDeclaration.name.staticElement, same(methodElement));
    expect(methodDeclaration.name.staticType, isNull);

    var fReturnTypeNode = methodDeclaration.returnType as NamedType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);
    //
    // Validate the parameters at the declaration site.
    //
    List<ParameterElement> elements = methodElement.parameters;
    expect(elements, hasLength(3));

    List<FormalParameter> nodes = methodDeclaration.parameters!.parameters;
    expect(nodes, hasLength(3));

    _assertSimpleParameter(nodes[0] as SimpleFormalParameter, elements[0],
        name: 'a',
        offset: 25,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    _assertDefaultParameter(nodes[1] as DefaultFormalParameter, elements[1],
        name: 'b',
        offset: 36,
        kind: ParameterKind.NAMED,
        type: typeProvider.stringType);

    _assertDefaultParameter(nodes[2] as DefaultFormalParameter, elements[2],
        name: 'c',
        offset: 44,
        kind: ParameterKind.NAMED,
        type: typeProvider.boolType);
    //
    // Validate the arguments at the call site.
    //
    var functionDeclaration =
        result.unit.declarations[1] as FunctionDeclaration;
    var body = functionDeclaration.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;

    List<Expression> arguments = invocation.argumentList.arguments;
    _assertArgumentToParameter(arguments[0], methodElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], methodElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], methodElement.parameters[2]);
  }

  test_methodInvocation_explicitCall_classTarget() async {
    addTestFile(r'''
class C {
  double call(int p) => 0.0;
}
main() {
  new C().call(0);
}
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    MethodElement callElement = cElement.methods[0];

    List<Statement> statements = _getMainStatements(result);

    var statement = statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;

    expect(invocation.staticType, typeProvider.doubleType);
    assertInvokeType(invocation, 'double Function(int)');

    SimpleIdentifier methodName = invocation.methodName;
    expect(methodName.staticElement, same(callElement));
    assertType(methodName.staticType, 'double Function(int)');
  }

  test_methodInvocation_explicitCall_functionTarget() async {
    addTestFile(r'''
f(double computation(int p)) {
  computation.call(1);
}
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var main = result.unit.declarations[0] as FunctionDeclaration;
    var mainElement = main.declaredElement as FunctionElement;
    ParameterElement parameter = mainElement.parameters[0];

    var mainBody = main.functionExpression.body as BlockFunctionBody;
    List<Statement> statements = mainBody.block.statements;

    var statement = statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;

    expect(invocation.staticType, typeProvider.doubleType);
    assertInvokeType(invocation, 'double Function(int)');

    var target = invocation.target as SimpleIdentifier;
    expect(target.staticElement, same(parameter));
    assertType(target.staticType, 'double Function(int)');

    SimpleIdentifier methodName = invocation.methodName;
    expect(methodName.staticElement, isNull);
    expect(methodName.staticType, dynamicType);
  }

  test_methodInvocation_instanceMethod_forwardingStub() async {
    addTestFile(r'''
class A {
  void foo(int x) {}
}
abstract class I<T> {
  void foo(T x);
}
class B extends A implements I<int> {}
main(B b) {
  b.foo(1);
}
''');
    await resolveTestFile();

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    var fooNode = aNode.members[0] as MethodDeclaration;
    var fooElement = fooNode.declaredElement as MethodElement;

    List<Statement> mainStatements = _getMainStatements(result);
    var statement = mainStatements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    expect(invocation.methodName.staticElement, same(fooElement));

    var invokeTypeStr = 'void Function(int)';
    assertType(invocation.staticType, 'void');
    assertInvokeType(invocation, invokeTypeStr);
  }

  @FailingTest(
      reason: 'This test started failing, because we probably assign '
          'corresponding parameter elements from FunctionType, which became '
          'pure in this CL. We should clean this up by using MethodMember '
          'parameters instead.')
  test_methodInvocation_instanceMethod_genericClass() async {
    addTestFile(r'''
main() {
  new C<int, double>().m(1);
}
class C<T, U> {
  void m(T p) {}
}
''');
    await resolveTestFile();
    MethodElement mElement = findElement.method('m');

    {
      var invocation = findNode.methodInvocation('m(1)');
      List<Expression> arguments = invocation.argumentList.arguments;

      var invokeTypeStr = 'void Function(int)';
      assertType(invocation, 'void');
      assertInvokeType(invocation, invokeTypeStr);

      assertMember(
          invocation.methodName, mElement, {'T': 'int', 'U': 'double'});
      assertType(invocation.methodName, invokeTypeStr);

      _assertArgumentToParameter(arguments[0], mElement.parameters[0]);
    }
  }

  test_methodInvocation_instanceMethod_genericClass_genericMethod() async {
    addTestFile(r'''
main() {
  new C<int>().m(1, 2.3);
}
class C<T> {
  Map<T, U> m<U>(T a, U b) => null;
}
''');
    await resolveTestFile();
    MethodElement mElement = findElement.method('m');

    {
      var invocation = findNode.methodInvocation('m(1, 2.3)');
      List<Expression> arguments = invocation.argumentList.arguments;

      var invokeTypeStr = 'Map<int, double> Function(int, double)';
      assertType(invocation, 'Map<int, double>');
      assertInvokeType(invocation, invokeTypeStr);

      assertMember(invocation.methodName, mElement, {'T': 'int'});
      assertType(invocation.methodName, 'Map<int, U> Function<U>(int, U)');

      _assertArgumentToParameter2(arguments[0], 'int');
      _assertArgumentToParameter2(arguments[1], 'double');
    }
  }

  test_methodInvocation_namedArgument() async {
    addTestFile(r'''
void main() {
  foo(1, b: true, c: 3.0);
}
void foo(int a, {bool b, double c}) {}
''');
    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    var foo = result.unit.declarations[1] as FunctionDeclaration;
    ExecutableElement fooElement = foo.declaredElement!;

    var statement = mainStatements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    List<Expression> arguments = invocation.argumentList.arguments;

    _assertArgumentToParameter(arguments[0], fooElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], fooElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], fooElement.parameters[2]);
  }

  test_methodInvocation_notFunction_field_dynamic() async {
    addTestFile(r'''
class C {
  dynamic f;
  foo() {
    f(1);
  }
}
''');
    await resolveTestFile();

    var invocation = findNode.functionExpressionInvocation('f(1)');
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);
    assertElement(invocation.function, findElement.getter('f'));

    List<Expression> arguments = invocation.argumentList.arguments;
    expect(arguments[0].staticParameterElement, isNull);
  }

  test_methodInvocation_notFunction_getter_dynamic() async {
    addTestFile(r'''
class C {
  get f => null;
  foo() {
    f(1);
  }
}
''');
    await resolveTestFile();

    var invocation = findNode.functionExpressionInvocation('f(1)');
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);
    assertElement(invocation.function, findElement.getter('f'));

    List<Expression> arguments = invocation.argumentList.arguments;
    expect(arguments[0].staticParameterElement, isNull);
  }

  test_methodInvocation_notFunction_getter_typedef() async {
    addTestFile(r'''
typedef String Fun(int a, {int b});
class C {
  Fun get f => null;
  foo() {
    f(1, b: 2);
  }
}
''');
    await resolveTestFile();

    var invocation = findNode.functionExpressionInvocation('f(1');
    assertElement(invocation.function, findElement.getter('f'));
    assertInvokeType(invocation, 'String Function(int, {int b})');
    assertType(invocation, 'String');

    List<Expression> arguments = invocation.argumentList.arguments;
    _assertArgumentToParameter2(arguments[0], 'int');
    _assertArgumentToParameter2(arguments[1], 'int');
  }

  test_methodInvocation_notFunction_local_dynamic() async {
    addTestFile(r'''
main(f) {
  f(1);
}
''');
    await resolveTestFile();

    var invocation = findNode.functionExpressionInvocation('f(1)');
    assertElement(invocation.function, findElement.parameter('f'));
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    List<Expression> arguments = invocation.argumentList.arguments;

    Expression argument = arguments[0];
    expect(argument.staticParameterElement, isNull);
  }

  test_methodInvocation_notFunction_local_functionTyped() async {
    addTestFile(r'''
main(String f(int a)) {
  f(1);
}
''');
    await resolveTestFile();

    var fElement = findElement.parameter('f');
    var invocation = findNode.functionExpressionInvocation('f(1)');
    assertElement(invocation.function, fElement);
    assertInvokeType(invocation, 'String Function(int)');
    assertType(invocation, 'String');

    List<Expression> arguments = invocation.argumentList.arguments;
    _assertArgumentToParameter(
        arguments[0], (fElement.type as FunctionType).parameters[0]);
  }

  test_methodInvocation_notFunction_topLevelVariable_dynamic() async {
    addTestFile(r'''
dynamic f;
main() {
  f(1);
}
''');
    await resolveTestFile();

    var invocation = findNode.functionExpressionInvocation('f(1)');
    assertElement(invocation.function, findElement.topGet('f'));
    assertInvokeTypeDynamic(invocation);
    assertTypeDynamic(invocation);

    List<Expression> arguments = invocation.argumentList.arguments;

    Expression argument = arguments[0];
    expect(argument.staticParameterElement, isNull);
  }

  test_methodInvocation_staticMethod() async {
    addTestFile(r'''
main() {
  C.m(1);
}
class C {
  static void m(int p) {}
  void foo() {
    m(2);
  }
}
''');
    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    var cNode = result.unit.declarations[1] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    var mNode = cNode.members[0] as MethodDeclaration;
    var mElement = mNode.declaredElement as MethodElement;

    {
      var statement = mainStatements[0] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;
      List<Expression> arguments = invocation.argumentList.arguments;

      var target = invocation.target as SimpleIdentifier;
      expect(target.staticElement, same(cElement));
      assertTypeNull(target);

      var invokeTypeStr = 'void Function(int)';
      assertType(invocation.staticType, 'void');
      assertInvokeType(invocation, invokeTypeStr);
      expect(invocation.methodName.staticElement, same(mElement));
      assertType(invocation.methodName, invokeTypeStr);

      Expression argument = arguments[0];
      _assertArgumentToParameter(argument, mElement.parameters[0]);
    }

    {
      var fooNode = cNode.members[1] as MethodDeclaration;
      var fooBody = fooNode.body as BlockFunctionBody;
      List<Statement> statements = fooBody.block.statements;

      var statement = statements[0] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;
      List<Expression> arguments = invocation.argumentList.arguments;

      expect(invocation.target, isNull);

      var invokeTypeStr = 'void Function(int)';
      assertType(invocation.staticType, 'void');
      assertInvokeType(invocation, invokeTypeStr);
      expect(invocation.methodName.staticElement, same(mElement));
      assertType(invocation.methodName, invokeTypeStr);

      Expression argument = arguments[0];
      _assertArgumentToParameter(argument, mElement.parameters[0]);
    }
  }

  test_methodInvocation_staticMethod_contextTypeParameter() async {
    addTestFile(r'''
class C<T> {
  static E foo<E>(C<E> c) => null;
  void bar() {
    foo(this);
  }
}
''');
    await resolveTestFile();

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    TypeParameterElement tElement = cNode.declaredElement!.typeParameters[0];

    var barNode = cNode.members[1] as MethodDeclaration;
    var barBody = barNode.body as BlockFunctionBody;
    var fooStatement = barBody.block.statements[0] as ExpressionStatement;
    var fooInvocation = fooStatement.expression as MethodInvocation;
    assertInvokeType(fooInvocation, 'T Function(C<T>)');
    assertType(fooInvocation.staticType, 'T');
    expect(fooInvocation.typeOrThrow.element, same(tElement));
  }

  test_methodInvocation_topLevelFunction() async {
    addTestFile(r'''
void main() {
  f(1, '2');
}
double f(int a, String b) {}
''');
    String fTypeString = 'double Function(int, String)';

    await resolveTestFile();
    List<Statement> mainStatements = _getMainStatements(result);

    InterfaceType doubleType = typeProvider.doubleType;

    var fNode = result.unit.declarations[1] as FunctionDeclaration;
    var fElement = fNode.declaredElement as FunctionElement;

    var statement = mainStatements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    List<Expression> arguments = invocation.argumentList.arguments;

    expect(invocation.methodName.staticElement, same(fElement));
    assertType(invocation.methodName, fTypeString);
    expect(invocation.staticType, doubleType);
    assertInvokeType(invocation, fTypeString);

    _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
  }

  @failingTest
  test_methodInvocation_topLevelFunction_generic() async {
    addTestFile(r'''
void main() {
  f<bool, String>(true, 'str');
  f(1, 2.3);
}
void f<T, U>(T a, U b) {}
''');
    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    var fNode = result.unit.declarations[1] as FunctionDeclaration;
    var fElement = fNode.declaredElement as FunctionElement;

    // f<bool, String>(true, 'str');
    {
      String fTypeString = 'void Function(bool, String)';
      var statement = mainStatements[0] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;

      List<TypeAnnotation> typeArguments = invocation.typeArguments!.arguments;
      expect(typeArguments, hasLength(2));
      {
        var typeArgument = typeArguments[0] as NamedType;
        InterfaceType boolType = typeProvider.boolType;
        expect(typeArgument.type, boolType);
        expect(typeArgument.name.staticElement, boolType.element);
        expect(typeArgument.name.staticType, boolType);
      }
      {
        var typeArgument = typeArguments[1] as NamedType;
        InterfaceType stringType = typeProvider.stringType;
        expect(typeArgument.type, stringType);
        expect(typeArgument.name.staticElement, stringType.element);
        expect(typeArgument.name.staticType, stringType);
      }

      List<Expression> arguments = invocation.argumentList.arguments;

      expect(invocation.methodName.staticElement, same(fElement));
      expect(invocation.methodName.staticType.toString(), fTypeString);
      expect(invocation.staticType, VoidTypeImpl.instance);
      assertInvokeType(invocation, fTypeString);

      _assertArgumentToParameter(arguments[0], fElement.parameters[0],
          memberType: typeProvider.boolType);
      _assertArgumentToParameter(arguments[1], fElement.parameters[1],
          memberType: typeProvider.stringType);
    }

    // f(1, 2.3);
    {
      String fTypeString = 'void Function(int, double)';
      var statement = mainStatements[1] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;
      List<Expression> arguments = invocation.argumentList.arguments;

      expect(invocation.methodName.staticElement, same(fElement));
      expect(invocation.methodName.staticType.toString(), fTypeString);
      expect(invocation.staticType, VoidTypeImpl.instance);
      assertInvokeType(invocation, fTypeString);

      _assertArgumentToParameter(arguments[0], fElement.parameters[0],
          memberType: typeProvider.intType);
      _assertArgumentToParameter(arguments[1], fElement.parameters[1],
          memberType: typeProvider.doubleType);
    }
  }

  test_optionalConst() async {
    addTestFile(r'''
class C {
  const C();
  const C.named();
}
const a = C(); // ref
const b = C.named(); // ref
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);
    var c = findElement.class_('C');

    {
      var creation = findNode.instanceCreation('C(); // ref');
      assertElement(creation, c.unnamedConstructor);
      assertType(creation, 'C');

      assertNamedType(creation.constructorName.type2, c, 'C');
    }

    {
      var creation = findNode.instanceCreation('C.named(); // ref');
      var namedConstructor = c.getNamedConstructor('named')!;
      assertElement(creation, namedConstructor);
      assertType(creation, 'C');

      assertNamedType(creation.constructorName.type2, c, 'C');
      assertElement(creation.constructorName.name, namedConstructor);
    }
  }

  test_optionalConst_prefixed() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
class C {
  const C();
  const C.named();
}
''');
    addTestFile(r'''
import 'a.dart' as p;
const a = p.C(); // ref
const b = p.C.named(); // ref
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);
    var import = findElement.import('package:test/a.dart');
    var c = import.importedLibrary!.getType('C')!;

    {
      var creation = findNode.instanceCreation('C(); // ref');
      assertElement(creation, c.unnamedConstructor);
      assertType(creation, 'C');

      assertNamedType(creation.constructorName.type2, c, 'C',
          expectedPrefix: import.prefix);
    }

    {
      var creation = findNode.instanceCreation('C.named(); // ref');
      var namedConstructor = c.getNamedConstructor('named')!;
      assertElement(creation, namedConstructor);
      assertType(creation, 'C');

      assertNamedType(creation.constructorName.type2, c, 'C',
          expectedPrefix: import.prefix);
      assertElement(creation.constructorName.name, namedConstructor);
    }
  }

  test_optionalConst_typeArguments() async {
    addTestFile(r'''
class C<T> {
  const C();
  const C.named();
}
const a = C<int>(); // ref
const b = C<String>.named(); // ref
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);
    var c = findElement.class_('C');

    {
      var creation = findNode.instanceCreation('C<int>(); // ref');
      assertMember(creation, c.unnamedConstructor!, {'T': 'int'});
      assertType(creation, 'C<int>');

      assertNamedType(creation.constructorName.type2, c, 'C<int>');
      assertNamedType(findNode.namedType('int>'), intElement, 'int');
    }

    {
      var creation = findNode.instanceCreation('C<String>.named(); // ref');
      var namedConstructor = c.getNamedConstructor('named')!;
      assertMember(creation, namedConstructor, {'T': 'String'});
      assertType(creation, 'C<String>');

      assertNamedType(creation.constructorName.type2, c, 'C<String>');
      assertNamedType(findNode.namedType('String>'), stringElement, 'String');

      assertMember(
          creation.constructorName.name, namedConstructor, {'T': 'String'});
    }
  }

  test_outline_invalid_mixin_arguments_tooFew() async {
    addTestFile(r'''
class A extends Object with Map<int> {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var mapRef = findNode.namedType('Map<');
    assertNamedType(mapRef, mapElement, 'Map<dynamic, dynamic>');

    var intRef = findNode.namedType('int>');
    assertNamedType(intRef, intElement, 'int');
  }

  test_outline_invalid_mixin_arguments_tooMany() async {
    addTestFile(r'''
class A extends Object with List<int, double> {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var listRef = findNode.namedType('List<');
    assertNamedType(listRef, listElement, 'List<dynamic>');

    var intRef = findNode.namedType('int,');
    assertNamedType(intRef, intElement, 'int');

    var doubleRef = findNode.namedType('double>');
    assertNamedType(doubleRef, doubleElement, 'double');
  }

  test_outline_invalid_mixin_typeParameter() async {
    addTestFile(r'''
class A<T> extends Object with T<int, double> {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.namedType('T<');
    assertNamedType(tRef, findElement.typeParameter('T'), 'T');

    var intRef = findNode.namedType('int,');
    assertNamedType(intRef, intElement, 'int');

    var doubleRef = findNode.namedType('double>');
    assertNamedType(doubleRef, doubleElement, 'double');
  }

  test_outline_invalid_supertype_arguments_tooFew() async {
    addTestFile(r'''
class A extends Map<int> {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var mapRef = findNode.namedType('Map<');
    assertNamedType(mapRef, mapElement, 'Map<dynamic, dynamic>');

    var intRef = findNode.namedType('int>');
    assertNamedType(intRef, intElement, 'int');
  }

  test_outline_invalid_supertype_arguments_tooMany() async {
    addTestFile(r'''
class A extends List<int, double> {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var listRef = findNode.namedType('List<');
    assertNamedType(listRef, listElement, 'List<dynamic>');

    var intRef = findNode.namedType('int,');
    assertNamedType(intRef, intElement, 'int');

    var doubleRef = findNode.namedType('double>');
    assertNamedType(doubleRef, doubleElement, 'double');
  }

  test_outline_invalid_supertype_hasArguments() async {
    addTestFile(r'''
class A extends X<int, double> {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.namedType('X<');
    assertNamedType(xRef, null, 'dynamic');

    var intRef = findNode.namedType('int,');
    assertNamedType(intRef, intElement, 'int');

    var doubleRef = findNode.namedType('double>');
    assertNamedType(doubleRef, doubleElement, 'double');
  }

  test_outline_invalid_supertype_noArguments() async {
    addTestFile(r'''
class A extends X {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var xRef = findNode.namedType('X {}');
    assertNamedType(xRef, null, 'dynamic');
  }

  test_outline_invalid_supertype_typeParameter() async {
    addTestFile(r'''
class A<T> extends T<int, double> {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.namedType('T<');
    assertNamedType(tRef, findElement.typeParameter('T'), 'T');

    var intRef = findNode.namedType('int,');
    assertNamedType(intRef, intElement, 'int');

    var doubleRef = findNode.namedType('double>');
    assertNamedType(doubleRef, doubleElement, 'double');
  }

  test_outline_invalid_type_arguments_tooFew() async {
    addTestFile(r'''
typedef Map<int> F();
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var mapRef = findNode.namedType('Map<');
    assertNamedType(mapRef, mapElement, 'Map<dynamic, dynamic>');

    var intRef = findNode.namedType('int>');
    assertNamedType(intRef, intElement, 'int');
  }

  test_outline_invalid_type_arguments_tooMany() async {
    addTestFile(r'''
typedef List<int, double> F();
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var listRef = findNode.namedType('List<');
    assertNamedType(listRef, listElement, 'List<dynamic>');

    var intRef = findNode.namedType('int,');
    assertNamedType(intRef, intElement, 'int');

    var doubleRef = findNode.namedType('double>');
    assertNamedType(doubleRef, doubleElement, 'double');
  }

  test_outline_invalid_type_typeParameter() async {
    addTestFile(r'''
typedef T<int> F<T>();
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var tRef = findNode.namedType('T<');
    assertNamedType(tRef, findElement.typeParameter('T'), 'T');

    var intRef = findNode.namedType('int>');
    assertNamedType(intRef, intElement, 'int');
  }

  test_outline_type_genericFunction() async {
    addTestFile(r'''
int Function(double) g() => (double g) => 0;
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var intRef = findNode.namedType('int Function');
    assertNamedType(intRef, intElement, 'int');

    var functionRef = findNode.genericFunctionType('Function(double)');
    assertType(functionRef, 'int Function(double)');

    var doubleRef = findNode.namedType('double) g');
    assertNamedType(doubleRef, doubleElement, 'double');
  }

  test_outline_type_topLevelVar_named() async {
    addTestFile(r'''
int a = 0;
List<double> b = [];
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var intRef = findNode.namedType('int a');
    assertNamedType(intRef, intElement, 'int');

    var listRef = findNode.namedType('List<double> b');
    assertNamedType(listRef, listElement, 'List<double>');

    var doubleRef = findNode.namedType('double> b');
    assertNamedType(doubleRef, doubleElement, 'double');
  }

  test_outline_type_topLevelVar_named_prefixed() async {
    addTestFile(r'''
import 'dart:async' as my;
my.Future<int> a;
''');
    await resolveTestFile();
    ImportElement myImport = result.libraryElement.imports[0];

    var intRef = findNode.namedType('int> a');
    assertNamedType(intRef, intElement, 'int');

    var futureRef = findNode.namedType('my.Future<int> a');
    assertNamedType(futureRef, futureElement, 'Future<int>',
        expectedPrefix: myImport.prefix);
  }

  test_postfix_increment_of_non_generator() async {
    addTestFile('''
void f(int g()) {
  g()++;
}
''');
    await resolveTestFile();

    var gRef = findNode.simple('g()++');
    assertType(gRef, 'int Function()');
    assertElement(gRef, findElement.parameter('g'));
  }

  test_postfix_increment_of_postfix_increment() async {
    addTestFile('''
void f(int x) {
  x ++ ++;
}
''');
    await resolveTestFile();

    var xRef = findNode.simple('x ++');
    if (hasAssignmentLeftResolution) {
      assertElement(xRef, findElement.parameter('x'));
      assertType(xRef, 'int');
    } else {
      // assertElementNull(xRef);
      assertTypeNull(xRef);
    }
  }

  test_postfixExpression_local() async {
    String content = r'''
main() {
  int v = 0;
  v++;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      var statement = mainStatements[0] as VariableDeclarationStatement;
      v = statement.variables.variables[0].declaredElement!;
      expect(v.type, typeProvider.intType);
    }

    {
      var statement = mainStatements[1] as ExpressionStatement;

      var postfix = statement.expression as PostfixExpression;
      expect(postfix.operator.type, TokenType.PLUS_PLUS);
      expect(postfix.staticElement!.name, '+');
      expect(postfix.staticType, typeProvider.intType);

      var operand = postfix.operand as SimpleIdentifier;
      if (hasAssignmentLeftResolution) {
        expect(operand.staticElement, same(v));
        expect(operand.staticType, typeProvider.intType);
      } else {
        // expect(operand.staticElement, same(v));
        expect(operand.staticType, isNull);
      }
    }
  }

  test_postfixExpression_propertyAccess() async {
    String content = r'''
main() {
  new C().f++;
}
class C {
  int f;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cClassDeclaration = unit.declarations[1] as ClassDeclaration;
    ClassElement cClassElement = cClassDeclaration.declaredElement!;
    FieldElement fElement = cClassElement.getField('f')!;

    List<Statement> mainStatements = _getMainStatements(result);

    {
      var statement = mainStatements[0] as ExpressionStatement;

      var postfix = statement.expression as PostfixExpression;
      expect(postfix.operator.type, TokenType.PLUS_PLUS);
      expect(postfix.staticElement!.name, '+');
      expect(postfix.staticType, typeProvider.intType);

      var propertyAccess = postfix.operand as PropertyAccess;
      if (hasAssignmentLeftResolution) {
        expect(propertyAccess.staticType, typeProvider.intType);
      } else {
        assertTypeNull(propertyAccess);
      }

      SimpleIdentifier propertyName = propertyAccess.propertyName;
      if (hasAssignmentLeftResolution) {
        expect(propertyName.staticElement, same(fElement.setter));
        expect(propertyName.staticType, typeProvider.intType);
      } else {
        assertElementNull(propertyName);
        assertTypeNull(propertyName);
      }
    }
  }

  test_prefix_increment_of_non_generator() async {
    addTestFile('''
void f(bool x) {
  ++!x;
}
''');
    await resolveTestFile();

    var xRef = findNode.simple('x;');
    assertType(xRef, 'bool');
    assertElement(xRef, findElement.parameter('x'));
  }

  test_prefix_increment_of_postfix_increment() async {
    addTestFile('''
void f(int x) {
  ++x++;
}
''');
    await resolveTestFile();

    var xRef = findNode.simple('x++');
    if (hasAssignmentLeftResolution) {
      assertElement(xRef, findElement.parameter('x'));
      assertType(xRef, 'int');
    } else {
      // assertElementNull(xRef);
      assertTypeNull(xRef);
    }
  }

  test_prefix_increment_of_prefix_increment() async {
    addTestFile('''
void f(int x) {
  ++ ++ x;
}
''');
    await resolveTestFile();

    var xRef = findNode.simple('x;');
    if (hasAssignmentLeftResolution) {
      assertElement(xRef, findElement.parameter('x'));
      assertType(xRef, 'int');
    } else {
      // assertElementNull(xRef);
      assertTypeNull(xRef);
    }
  }

  test_prefixedIdentifier_classInstance_instanceField() async {
    String content = r'''
main() {
  var c = new C();
  c.f;
}
class C {
  int f;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var cDeclaration = result.unit.declarations[1] as ClassDeclaration;
    ClassElement cElement = cDeclaration.declaredElement!;
    FieldElement fElement = cElement.fields[0];

    var cStatement = statements[0] as VariableDeclarationStatement;
    VariableElement vElement =
        cStatement.variables.variables[0].declaredElement!;

    var statement = statements[1] as ExpressionStatement;
    var prefixed = statement.expression as PrefixedIdentifier;

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, same(vElement));
    expect(prefix.staticType, interfaceTypeNone(cElement));

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, same(fElement.getter));
    expect(identifier.staticType, typeProvider.intType);
  }

  test_prefixedIdentifier_className_staticField() async {
    String content = r'''
main() {
  C.f;
}
class C {
  static f = 0;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    var cDeclaration = result.unit.declarations[1] as ClassDeclaration;
    ClassElement cElement = cDeclaration.declaredElement!;
    FieldElement fElement = cElement.fields[0];

    var statement = statements[0] as ExpressionStatement;
    var prefixed = statement.expression as PrefixedIdentifier;

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, same(cElement));
    assertTypeNull(prefix);

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, same(fElement.getter));
    expect(identifier.staticType, typeProvider.intType);
  }

  test_prefixedIdentifier_explicitCall() async {
    addTestFile(r'''
f(double computation(int p)) {
  computation.call;
}
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var main = result.unit.declarations[0] as FunctionDeclaration;
    var mainElement = main.declaredElement as FunctionElement;
    ParameterElement parameter = mainElement.parameters[0];

    var mainBody = main.functionExpression.body as BlockFunctionBody;
    List<Statement> statements = mainBody.block.statements;

    var statement = statements[0] as ExpressionStatement;
    var prefixed = statement.expression as PrefixedIdentifier;

    expect(prefixed.prefix.staticElement, same(parameter));
    assertType(prefixed.prefix.staticType, 'double Function(int)');

    SimpleIdentifier methodName = prefixed.identifier;
    expect(methodName.staticElement, isNull);
    assertType(methodName.staticType, 'double Function(int)');
  }

  test_prefixedIdentifier_importPrefix_className() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
class MyClass {}
typedef void MyFunctionTypeAlias();
int myTopVariable;
int myTopFunction() => 0;
int get myGetter => 0;
void set mySetter(int _) {}
''');
    addTestFile(r'''
import 'lib.dart' as my;
main() {
  my.MyClass;
  my.MyFunctionTypeAlias;
  my.myTopVariable;
  my.myTopFunction;
  my.myTopFunction();
  my.myGetter;
  my.mySetter = 0;
}
''');
    await resolveTestFile();
    // TODO(scheglov) Uncomment and fix "unused imports" hint.
//    expect(result.errors, isEmpty);

    var unitElement = result.unit.declaredElement!;
    ImportElement myImport = unitElement.library.imports[0];
    PrefixElement myPrefix = myImport.prefix!;

    var myLibrary = myImport.importedLibrary!;
    var myUnit = myLibrary.definingCompilationUnit;
    var myClass = myUnit.classes.single;
    var myTypeAlias = myUnit.typeAliases.single;
    var myTopVariable = myUnit.topLevelVariables[0];
    var myTopFunction = myUnit.functions.single;
    var myGetter = myUnit.topLevelVariables[1].getter!;
    var mySetter = myUnit.topLevelVariables[2].setter!;
    expect(myTopVariable.name, 'myTopVariable');
    expect(myGetter.displayName, 'myGetter');
    expect(mySetter.displayName, 'mySetter');

    List<Statement> statements = _getMainStatements(result);

    void assertPrefix(SimpleIdentifier identifier) {
      expect(identifier.staticElement, same(myPrefix));
      expect(identifier.staticType, isNull);
    }

    void assertPrefixedIdentifier(
        int statementIndex, Element expectedElement, DartType expectedType) {
      var statement = statements[statementIndex] as ExpressionStatement;
      var prefixed = statement.expression as PrefixedIdentifier;
      assertPrefix(prefixed.prefix);

      expect(prefixed.identifier.staticElement, same(expectedElement));
      expect(prefixed.identifier.staticType, expectedType);
    }

    assertPrefixedIdentifier(0, myClass, typeProvider.typeType);
    assertPrefixedIdentifier(1, myTypeAlias, typeProvider.typeType);
    assertPrefixedIdentifier(2, myTopVariable.getter!, typeProvider.intType);

    {
      var statement = statements[3] as ExpressionStatement;
      var prefixed = statement.expression as PrefixedIdentifier;
      assertPrefix(prefixed.prefix);

      expect(prefixed.identifier.staticElement, same(myTopFunction));
      expect(prefixed.identifier.staticType, isNotNull);
    }

    {
      var statement = statements[4] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;
      assertPrefix(invocation.target as SimpleIdentifier);

      expect(invocation.methodName.staticElement, same(myTopFunction));
      expect(invocation.methodName.staticType, isNotNull);
    }

    assertPrefixedIdentifier(5, myGetter, typeProvider.intType);

    {
      var statement = statements[6] as ExpressionStatement;
      var assignment = statement.expression as AssignmentExpression;
      var left = assignment.leftHandSide as PrefixedIdentifier;
      assertPrefix(left.prefix);

      if (hasAssignmentLeftResolution) {
        expect(left.identifier.staticElement, same(mySetter));
        expect(left.identifier.staticType, typeProvider.intType);
      } else {
        assertElementNull(left.identifier);
        assertTypeNull(left.identifier);
      }
    }
  }

  test_prefixExpression_local() async {
    String content = r'''
main() {
  int v = 0;
  ++v;
  ~v;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      var statement = mainStatements[0] as VariableDeclarationStatement;
      v = statement.variables.variables[0].declaredElement!;
      expect(v.type, typeProvider.intType);
    }

    {
      var statement = mainStatements[1] as ExpressionStatement;

      var prefix = statement.expression as PrefixExpression;
      expect(prefix.operator.type, TokenType.PLUS_PLUS);
      expect(prefix.staticElement!.name, '+');
      expect(prefix.staticType, typeProvider.intType);

      var operand = prefix.operand as SimpleIdentifier;
      if (hasAssignmentLeftResolution) {
        expect(operand.staticElement, same(v));
        expect(operand.staticType, typeProvider.intType);
      } else {
        // assertElementNull(operand);
        assertTypeNull(operand);
      }
    }

    {
      var statement = mainStatements[2] as ExpressionStatement;

      var prefix = statement.expression as PrefixExpression;
      expect(prefix.operator.type, TokenType.TILDE);
      expect(prefix.staticElement!.name, '~');
      expect(prefix.staticType, typeProvider.intType);

      var operand = prefix.operand as SimpleIdentifier;
      expect(operand.staticElement, same(v));
      expect(operand.staticType, typeProvider.intType);
    }
  }

  test_prefixExpression_local_not() async {
    String content = r'''
main() {
  bool v = true;
  !v;
}
''';
    addTestFile(content);

    await resolveTestFile();

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      var statement = mainStatements[0] as VariableDeclarationStatement;
      v = statement.variables.variables[0].declaredElement!;
      expect(v.type, typeProvider.boolType);
    }

    {
      var statement = mainStatements[1] as ExpressionStatement;

      var prefix = statement.expression as PrefixExpression;
      expect(prefix.operator.type, TokenType.BANG);
      expect(prefix.staticElement, isNull);
      expect(prefix.staticType, typeProvider.boolType);

      var operand = prefix.operand as SimpleIdentifier;
      expect(operand.staticElement, same(v));
      expect(operand.staticType, typeProvider.boolType);
    }
  }

  test_prefixExpression_propertyAccess() async {
    String content = r'''
main() {
  ++new C().f;
  ~new C().f;
}
class C {
  int f;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cClassDeclaration = unit.declarations[1] as ClassDeclaration;
    ClassElement cClassElement = cClassDeclaration.declaredElement!;
    FieldElement fElement = cClassElement.getField('f')!;

    List<Statement> mainStatements = _getMainStatements(result);

    {
      var statement = mainStatements[0] as ExpressionStatement;

      var prefix = statement.expression as PrefixExpression;
      expect(prefix.operator.type, TokenType.PLUS_PLUS);
      expect(prefix.staticElement!.name, '+');
      expect(prefix.staticType, typeProvider.intType);

      var propertyAccess = prefix.operand as PropertyAccess;
      if (hasAssignmentLeftResolution) {
        expect(propertyAccess.staticType, typeProvider.intType);
      } else {
        assertTypeNull(propertyAccess);
      }

      SimpleIdentifier propertyName = propertyAccess.propertyName;
      if (hasAssignmentLeftResolution) {
        expect(propertyName.staticElement, same(fElement.setter));
        expect(propertyName.staticType, typeProvider.intType);
      } else {
        assertElementNull(propertyName.staticElement);
        assertTypeNull(propertyName);
      }
    }

    {
      var statement = mainStatements[1] as ExpressionStatement;

      var prefix = statement.expression as PrefixExpression;
      expect(prefix.operator.type, TokenType.TILDE);
      expect(prefix.staticElement!.name, '~');
      expect(prefix.staticType, typeProvider.intType);

      var propertyAccess = prefix.operand as PropertyAccess;
      expect(propertyAccess.staticType, typeProvider.intType);

      SimpleIdentifier propertyName = propertyAccess.propertyName;
      expect(propertyName.staticElement, same(fElement.getter));
      expect(propertyName.staticType, typeProvider.intType);
    }
  }

  test_propertyAccess_field() async {
    String content = r'''
main() {
  new C().f;
}
class C {
  int f;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cClassDeclaration = unit.declarations[1] as ClassDeclaration;
    ClassElement cClassElement = cClassDeclaration.declaredElement!;
    FieldElement fElement = cClassElement.getField('f')!;

    List<Statement> mainStatements = _getMainStatements(result);

    {
      var statement = mainStatements[0] as ExpressionStatement;
      var access = statement.expression as PropertyAccess;
      expect(access.staticType, typeProvider.intType);

      var newC = access.target as InstanceCreationExpression;
      expect(
        newC.constructorName.staticElement,
        cClassElement.unnamedConstructor,
      );
      expect(newC.staticType, interfaceTypeNone(cClassElement));

      expect(access.propertyName.staticElement, same(fElement.getter));
      expect(access.propertyName.staticType, typeProvider.intType);
    }
  }

  test_propertyAccess_getter() async {
    String content = r'''
main() {
  new C().f;
}
class C {
  int get f => 0;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cClassDeclaration = unit.declarations[1] as ClassDeclaration;
    ClassElement cClassElement = cClassDeclaration.declaredElement!;
    FieldElement fElement = cClassElement.getField('f')!;

    List<Statement> mainStatements = _getMainStatements(result);

    {
      var statement = mainStatements[0] as ExpressionStatement;
      var access = statement.expression as PropertyAccess;
      expect(access.staticType, typeProvider.intType);

      var newC = access.target as InstanceCreationExpression;
      expect(
        newC.constructorName.staticElement,
        cClassElement.unnamedConstructor,
      );
      expect(newC.staticType, interfaceTypeNone(cClassElement));

      expect(access.propertyName.staticElement, same(fElement.getter));
      expect(access.propertyName.staticType, typeProvider.intType);
    }
  }

  test_reference_to_class_type_parameter() async {
    addTestFile('''
class C<T> {
  void f() {
    T x;
  }
}
''');
    await resolveTestFile();
    var tElement = findElement.class_('C').typeParameters[0];
    var tReference = findNode.simple('T x');
    assertElement(tReference, tElement);
    assertTypeNull(tReference);
  }

  test_setLiteral() async {
    addTestFile(r'''
main() {
  var v = <int>{};
  print(v);
}
''');
    await resolveTestFile();
    expect(result.errors, isEmpty);

    var literal = findNode.setOrMapLiteral('<int>{}');
    assertType(literal, 'Set<int>');

    var intRef = findNode.simple('int>{}');
    assertElement(intRef, intElement);
    assertTypeNull(intRef);
  }

  test_stringInterpolation() async {
    await assertNoErrorsInCode(r'''
void main() {
  var v = 42;
  '$v$v $v';
  ' ${v + 1} ';
}
''');

    var main = result.unit.declarations[0] as FunctionDeclaration;
    expect(main.declaredElement, isNotNull);
    expect(main.name.staticElement, isNotNull);
    expect(main.name.staticType, isNull);

    var body = main.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;

    // var v = 42;
    VariableElement vElement;
    {
      var statement = statements[0] as VariableDeclarationStatement;
      vElement = statement.variables.variables[0].name.staticElement
          as VariableElement;
    }

    {
      var statement = statements[1] as ExpressionStatement;
      var interpolation = statement.expression as StringInterpolation;

      var element_1 = interpolation.elements[1] as InterpolationExpression;
      var expression_1 = element_1.expression as SimpleIdentifier;
      expect(expression_1.staticElement, same(vElement));
      expect(expression_1.staticType, typeProvider.intType);

      var element_3 = interpolation.elements[3] as InterpolationExpression;
      var expression_3 = element_3.expression as SimpleIdentifier;
      expect(expression_3.staticElement, same(vElement));
      expect(expression_3.staticType, typeProvider.intType);

      var element_5 = interpolation.elements[5] as InterpolationExpression;
      var expression_5 = element_5.expression as SimpleIdentifier;
      expect(expression_5.staticElement, same(vElement));
      expect(expression_5.staticType, typeProvider.intType);
    }

    {
      var statement = statements[2] as ExpressionStatement;
      var interpolation = statement.expression as StringInterpolation;

      var element_1 = interpolation.elements[1] as InterpolationExpression;
      var expression = element_1.expression as BinaryExpression;
      expect(expression.staticType, typeProvider.intType);

      var left = expression.leftOperand as SimpleIdentifier;
      expect(left.staticElement, same(vElement));
      expect(left.staticType, typeProvider.intType);
    }
  }

  test_stringInterpolation_multiLine_emptyBeforeAfter() async {
    addTestFile(r"""
void main() {
  var v = 42;
  '''$v''';
}
""");
    await resolveTestFile();
    expect(result.errors, isEmpty);
  }

  test_super() async {
    String content = r'''
class A {
  void method(int p) {}
  int get getter => 0;
  void set setter(int p) {}
  int operator+(int p) => 0;
}
class B extends A {
  void test() {
    method(1);
    super.method(2);
    getter;
    super.getter;
    setter = 3;
    super.setter = 4;
    this + 5;
  }
}
''';
    addTestFile(content);
    await resolveTestFile();

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    var bNode = result.unit.declarations[1] as ClassDeclaration;

    var methodElement = aNode.members[0].declaredElement as MethodElement;
    var getterElement =
        aNode.members[1].declaredElement as PropertyAccessorElement;
    var setterElement =
        aNode.members[2].declaredElement as PropertyAccessorElement;
    var operatorElement = aNode.members[3].declaredElement as MethodElement;

    var testNode = bNode.members[0] as MethodDeclaration;
    var testBody = testNode.body as BlockFunctionBody;
    List<Statement> testStatements = testBody.block.statements;

    // method(1);
    {
      var statement = testStatements[0] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;

      expect(invocation.target, isNull);

      expect(invocation.methodName.staticElement, same(methodElement));
    }

    // super.method(2);
    {
      var statement = testStatements[1] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;

      var target = invocation.target as SuperExpression;
      expect(
          target.staticType, interfaceTypeNone(bNode.declaredElement!)); // raw

      expect(invocation.methodName.staticElement, same(methodElement));
    }

    // getter;
    {
      var statement = testStatements[2] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;

      expect(identifier.staticElement, same(getterElement));
      expect(identifier.staticType, typeProvider.intType);
    }

    // super.getter;
    {
      var statement = testStatements[3] as ExpressionStatement;
      var propertyAccess = statement.expression as PropertyAccess;
      expect(propertyAccess.staticType, typeProvider.intType);

      var target = propertyAccess.target as SuperExpression;
      expect(
          target.staticType, interfaceTypeNone(bNode.declaredElement!)); // raw

      expect(propertyAccess.propertyName.staticElement, same(getterElement));
      expect(propertyAccess.propertyName.staticType, typeProvider.intType);
    }

    // setter = 3;
    {
      var statement = testStatements[4] as ExpressionStatement;
      var assignment = statement.expression as AssignmentExpression;

      var identifier = assignment.leftHandSide as SimpleIdentifier;
      if (hasAssignmentLeftResolution) {
        expect(identifier.staticElement, same(setterElement));
        expect(identifier.staticType, typeProvider.intType);
      } else {
        assertElementNull(identifier);
        assertTypeNull(identifier);
      }
    }

    // this.setter = 4;
    {
      var statement = testStatements[5] as ExpressionStatement;
      var assignment = statement.expression as AssignmentExpression;

      var propertyAccess = assignment.leftHandSide as PropertyAccess;

      var target = propertyAccess.target as SuperExpression;
      expect(
          target.staticType, interfaceTypeNone(bNode.declaredElement!)); // raw

      if (hasAssignmentLeftResolution) {
        expect(propertyAccess.propertyName.staticElement, same(setterElement));
        expect(propertyAccess.propertyName.staticType, typeProvider.intType);
      } else {
        assertElementNull(propertyAccess.propertyName);
        assertTypeNull(propertyAccess.propertyName);
      }
    }

    // super + 5;
    {
      var statement = testStatements[6] as ExpressionStatement;
      var binary = statement.expression as BinaryExpression;

      var target = binary.leftOperand as ThisExpression;
      expect(
          target.staticType, interfaceTypeNone(bNode.declaredElement!)); // raw

      expect(binary.staticElement, same(operatorElement));
      expect(binary.staticType, typeProvider.intType);
    }
  }

  test_this() async {
    String content = r'''
class A {
  void method(int p) {}
  int get getter => 0;
  void set setter(int p) {}
  int operator+(int p) => 0;
  void test() {
    method(1);
    this.method(2);
    getter;
    this.getter;
    setter = 3;
    this.setter = 4;
    this + 5;
  }
}
''';
    addTestFile(content);
    await resolveTestFile();

    var aNode = result.unit.declarations[0] as ClassDeclaration;

    var methodElement = aNode.members[0].declaredElement as MethodElement;
    var getterElement =
        aNode.members[1].declaredElement as PropertyAccessorElement;
    var setterElement =
        aNode.members[2].declaredElement as PropertyAccessorElement;
    var operatorElement = aNode.members[3].declaredElement as MethodElement;

    var testNode = aNode.members[4] as MethodDeclaration;
    var testBody = testNode.body as BlockFunctionBody;
    List<Statement> testStatements = testBody.block.statements;

    var elementA = findElement.class_('A');
    var thisTypeA = interfaceTypeNone(elementA);

    // method(1);
    {
      var statement = testStatements[0] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;

      expect(invocation.target, isNull);

      expect(invocation.methodName.staticElement, same(methodElement));
    }

    // this.method(2);
    {
      var statement = testStatements[1] as ExpressionStatement;
      var invocation = statement.expression as MethodInvocation;

      var target = invocation.target as ThisExpression;
      expect(target.staticType, thisTypeA); // raw

      expect(invocation.methodName.staticElement, same(methodElement));
    }

    // getter;
    {
      var statement = testStatements[2] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;

      expect(identifier.staticElement, same(getterElement));
      expect(identifier.staticType, typeProvider.intType);
    }

    // this.getter;
    {
      var statement = testStatements[3] as ExpressionStatement;
      var propertyAccess = statement.expression as PropertyAccess;
      expect(propertyAccess.staticType, typeProvider.intType);

      var target = propertyAccess.target as ThisExpression;
      expect(target.staticType, thisTypeA); // raw

      expect(propertyAccess.propertyName.staticElement, same(getterElement));
      expect(propertyAccess.propertyName.staticType, typeProvider.intType);
    }

    // setter = 3;
    {
      var statement = testStatements[4] as ExpressionStatement;
      var assignment = statement.expression as AssignmentExpression;

      var identifier = assignment.leftHandSide as SimpleIdentifier;
      if (hasAssignmentLeftResolution) {
        expect(identifier.staticElement, same(setterElement));
        expect(identifier.staticType, typeProvider.intType);
      } else {
        assertElementNull(identifier);
        assertTypeNull(identifier);
      }
    }

    // this.setter = 4;
    {
      var statement = testStatements[5] as ExpressionStatement;
      var assignment = statement.expression as AssignmentExpression;

      var propertyAccess = assignment.leftHandSide as PropertyAccess;

      var target = propertyAccess.target as ThisExpression;
      expect(target.staticType, thisTypeA); // raw

      if (hasAssignmentLeftResolution) {
        expect(propertyAccess.propertyName.staticElement, same(setterElement));
        expect(propertyAccess.propertyName.staticType, typeProvider.intType);
      } else {
        assertElementNull(propertyAccess.propertyName);
        assertTypeNull(propertyAccess.propertyName);
      }
    }

    // this + 5;
    {
      var statement = testStatements[6] as ExpressionStatement;
      var binary = statement.expression as BinaryExpression;

      var target = binary.leftOperand as ThisExpression;
      expect(target.staticType, thisTypeA); // raw

      expect(binary.staticElement, same(operatorElement));
      expect(binary.staticType, typeProvider.intType);
    }
  }

  test_top_class_constructor_parameter_defaultValue() async {
    String content = r'''
class C {
  double f;
  C([int a: 1 + 2]) : f = 3.4;
}
''';
    addTestFile(content);
    await resolveTestFile();

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    var constructorNode = cNode.members[1] as ConstructorDeclaration;

    var aNode =
        constructorNode.parameters.parameters[0] as DefaultFormalParameter;
    _assertDefaultParameter(aNode, cElement.unnamedConstructor!.parameters[0],
        name: 'a',
        offset: 31,
        kind: ParameterKind.POSITIONAL,
        type: typeProvider.intType);

    var binary = aNode.defaultValue as BinaryExpression;
    expect(binary.staticElement, isNotNull);
    expect(binary.staticType, typeProvider.intType);
    expect(binary.leftOperand.staticType, typeProvider.intType);
    expect(binary.rightOperand.staticType, typeProvider.intType);
  }

  test_top_class_extends() async {
    String content = r'''
class A<T> {}
class B extends A<int> {}
''';
    addTestFile(content);
    await resolveTestFile();

    var aRef = findNode.namedType('A<int>');
    assertNamedType(aRef, findElement.class_('A'), 'A<int>');

    var intRef = findNode.namedType('int>');
    assertNamedType(intRef, intElement, 'int');
  }

  test_top_class_full() async {
    String content = r'''
class A<T> {}
class B<T> {}
class C<T> {}
class D extends A<bool> with B<int> implements C<double> {}
''';
    addTestFile(content);
    await resolveTestFile();

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;

    var bNode = result.unit.declarations[1] as ClassDeclaration;
    ClassElement bElement = bNode.declaredElement!;

    var cNode = result.unit.declarations[2] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    var dNode = result.unit.declarations[3] as ClassDeclaration;
    Element dElement = dNode.declaredElement!;

    SimpleIdentifier dName = dNode.name;
    expect(dName.staticElement, same(dElement));
    expect(dName.staticType, isNull);

    {
      var expectedType = aElement.instantiate(
        typeArguments: [typeProvider.boolType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType superClass = dNode.extendsClause!.superclass2;
      expect(superClass.type, expectedType);

      var identifier = superClass.name as SimpleIdentifier;
      expect(identifier.staticElement, aElement);
      expect(identifier.staticType, isNull);
    }

    {
      var expectedType = bElement.instantiate(
        typeArguments: [typeProvider.intType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType mixinType = dNode.withClause!.mixinTypes2[0];
      expect(mixinType.type, expectedType);

      var identifier = mixinType.name as SimpleIdentifier;
      expect(identifier.staticElement, bElement);
      expect(identifier.staticType, isNull);
    }

    {
      var expectedType = cElement.instantiate(
        typeArguments: [typeProvider.doubleType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType implementedType = dNode.implementsClause!.interfaces2[0];
      expect(implementedType.type, expectedType);

      var identifier = implementedType.name as SimpleIdentifier;
      expect(identifier.staticElement, cElement);
      expect(identifier.staticType, isNull);
    }
  }

  test_top_classTypeAlias() async {
    String content = r'''
class A<T> {}
class B<T> {}
class C<T> {}
class D = A<bool> with B<int> implements C<double>;
''';
    addTestFile(content);
    await resolveTestFile();

    var aNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;

    var bNode = result.unit.declarations[1] as ClassDeclaration;
    ClassElement bElement = bNode.declaredElement!;

    var cNode = result.unit.declarations[2] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    var dNode = result.unit.declarations[3] as ClassTypeAlias;
    Element dElement = dNode.declaredElement!;

    SimpleIdentifier dName = dNode.name;
    expect(dName.staticElement, same(dElement));
    expect(dName.staticType, isNull);

    {
      var expectedType = aElement.instantiate(
        typeArguments: [typeProvider.boolType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType superClass = dNode.superclass2;
      expect(superClass.type, expectedType);

      var identifier = superClass.name as SimpleIdentifier;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, isNull);
    }

    {
      var expectedType = bElement.instantiate(
        typeArguments: [typeProvider.intType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType mixinType = dNode.withClause.mixinTypes2[0];
      expect(mixinType.type, expectedType);

      var identifier = mixinType.name as SimpleIdentifier;
      expect(identifier.staticElement, same(bElement));
      expect(identifier.staticType, isNull);
    }

    {
      var expectedType = cElement.instantiate(
        typeArguments: [typeProvider.doubleType],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      NamedType interfaceType = dNode.implementsClause!.interfaces2[0];
      expect(interfaceType.type, expectedType);

      var identifier = interfaceType.name as SimpleIdentifier;
      expect(identifier.staticElement, same(cElement));
      expect(identifier.staticType, isNull);
    }
  }

  test_top_enum() async {
    String content = r'''
enum MyEnum {
  A, B
}
''';
    addTestFile(content);
    await resolveTestFile();

    var enumNode = result.unit.declarations[0] as EnumDeclaration;
    ClassElement enumElement = enumNode.declaredElement!;

    SimpleIdentifier dName = enumNode.name;
    expect(dName.staticElement, same(enumElement));
    expect(dName.staticType, isNull);

    {
      var aElement = enumElement.getField('A');
      var aNode = enumNode.constants[0];
      expect(aNode.declaredElement, same(aElement));
      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, isNull);
    }

    {
      var bElement = enumElement.getField('B');
      var bNode = enumNode.constants[1];
      expect(bNode.declaredElement, same(bElement));
      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, isNull);
    }
  }

  test_top_executables_class() async {
    await assertNoErrorsInCode(r'''
class C {
  C(int p);
  C.named(int p);

  int publicMethod(double p) => 0;
  int get publicGetter => 0;
  void set publicSetter(double p) {}
}
''');

    InterfaceType doubleType = typeProvider.doubleType;
    InterfaceType intType = typeProvider.intType;
    ClassElement doubleElement = doubleType.element;
    ClassElement intElement = intType.element;

    var cNode = result.unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    // The class name identifier.
    expect(cNode.name.staticElement, same(cElement));
    expect(cNode.name.staticType, isNull);

    // unnamed constructor
    {
      var node = cNode.members[0] as ConstructorDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'C Function(int)');
      expect(node.returnType.staticElement, same(cElement));
      expect(node.returnType.staticType, isNull);
      expect(node.name, isNull);
    }

    // named constructor
    {
      var node = cNode.members[1] as ConstructorDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'C Function(int)');
      expect(node.returnType.staticElement, same(cElement));
      expect(node.returnType.staticType, isNull);
      expect(node.name!.staticElement, same(node.declaredElement));
      expect(node.name!.staticType, isNull);
    }

    // publicMethod()
    {
      var node = cNode.members[2] as MethodDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'int Function(double)');

      // method return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, isNull);

      // method name
      expect(node.name.staticElement, same(node.declaredElement));
      expect(node.name.staticType, isNull);

      // method parameter
      {
        var pNode = node.parameters!.parameters[0] as SimpleFormalParameter;
        expect(pNode.declaredElement, isNotNull);
        expect(pNode.declaredElement!.type, doubleType);

        var pType = pNode.type as NamedType;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, isNull);

        expect(pNode.identifier!.staticElement, pNode.declaredElement);
        expect(pNode.identifier!.staticType, isNull);
      }
    }

    // publicGetter()
    {
      var node = cNode.members[3] as MethodDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'int Function()');

      // getter return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, isNull);

      // getter name
      expect(node.name.staticElement, same(node.declaredElement));
      expect(node.name.staticType, isNull);
    }

    // publicSetter()
    {
      var node = cNode.members[4] as MethodDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'void Function(double)');

      // setter return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, VoidTypeImpl.instance);
      expect(returnTypeName.staticElement, isNull);
      expect(returnTypeName.staticType, isNull);

      // setter name
      expect(node.name.staticElement, same(node.declaredElement));
      expect(node.name.staticType, isNull);

      // setter parameter
      {
        var pNode = node.parameters!.parameters[0] as SimpleFormalParameter;
        expect(pNode.declaredElement, isNotNull);
        expect(pNode.declaredElement!.type, doubleType);

        var pType = pNode.type as NamedType;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, isNull);

        expect(pNode.identifier!.staticElement, pNode.declaredElement);
        expect(pNode.identifier!.staticType, isNull);
      }
    }
  }

  test_top_executables_top() async {
    await assertNoErrorsInCode(r'''
int topFunction(double p) => 0;
int get topGetter => 0;
void set topSetter(double p) {}
''');

    InterfaceType doubleType = typeProvider.doubleType;
    InterfaceType intType = typeProvider.intType;
    ClassElement doubleElement = doubleType.element;
    ClassElement intElement = intType.element;

    // topFunction()
    {
      var node = result.unit.declarations[0] as FunctionDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'int Function(double)');

      // function return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, isNull);

      // function name
      expect(node.name.staticElement, same(node.declaredElement));
      expect(node.name.staticType, isNull);

      // function parameter
      {
        var pNode = node.functionExpression.parameters!.parameters[0]
            as SimpleFormalParameter;
        expect(pNode.declaredElement, isNotNull);
        expect(pNode.declaredElement!.type, doubleType);

        var pType = pNode.type as NamedType;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, isNull);

        expect(pNode.identifier!.staticElement, pNode.declaredElement);
        expect(pNode.identifier!.staticType, isNull);
      }
    }

    // topGetter()
    {
      var node = result.unit.declarations[1] as FunctionDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'int Function()');

      // getter return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, isNull);

      // getter name
      expect(node.name.staticElement, same(node.declaredElement));
      expect(node.name.staticType, isNull);
    }

    // topSetter()
    {
      var node = result.unit.declarations[2] as FunctionDeclaration;
      expect(node.declaredElement, isNotNull);
      assertType(node.declaredElement!.type, 'void Function(double)');

      // setter return type
      var returnType = node.returnType as NamedType;
      var returnTypeName = returnType.name as SimpleIdentifier;
      expect(returnType.type, VoidTypeImpl.instance);
      expect(returnTypeName.staticElement, isNull);
      expect(returnTypeName.staticType, isNull);

      // setter name
      expect(node.name.staticElement, same(node.declaredElement));
      expect(node.name.staticType, isNull);

      // setter parameter
      {
        var pNode = node.functionExpression.parameters!.parameters[0]
            as SimpleFormalParameter;
        expect(pNode.declaredElement, isNotNull);
        expect(pNode.declaredElement!.type, doubleType);

        var pType = pNode.type as NamedType;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, isNull);

        expect(pNode.identifier!.staticElement, pNode.declaredElement);
        expect(pNode.identifier!.staticType, isNull);
      }
    }
  }

  test_top_field_class() async {
    String content = r'''
class C<T> {
  var a = 1;
  T b;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    var cNode = unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    TypeParameterElement tElement = cElement.typeParameters[0];
    expect(cElement, same(unitElement.classes[0]));

    {
      FieldElement aElement = cElement.getField('a')!;
      var aDeclaration = cNode.members[0] as FieldDeclaration;
      VariableDeclaration aNode = aDeclaration.fields.variables[0];
      expect(aNode.declaredElement, same(aElement));
      expect(aElement.type, typeProvider.intType);
      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, isNull);

      var aValue = aNode.initializer as Expression;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      FieldElement bElement = cElement.getField('b')!;
      var bDeclaration = cNode.members[1] as FieldDeclaration;

      var namedType = bDeclaration.fields.type as NamedType;
      var typeIdentifier = namedType.name as SimpleIdentifier;
      expect(typeIdentifier.staticElement, same(tElement));
      expect(typeIdentifier.staticType, isNull);

      VariableDeclaration bNode = bDeclaration.fields.variables[0];
      expect(bNode.declaredElement, same(bElement));
      expect(bElement.type, typeParameterTypeNone(tElement));
      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, isNull);
    }
  }

  test_top_field_class_multiple() async {
    String content = r'''
class C {
  var a = 1, b = 2.3;
}
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var cNode = unit.declarations[0] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;

    var fieldDeclaration = cNode.members[0] as FieldDeclaration;

    {
      FieldElement aElement = cElement.getField('a')!;

      VariableDeclaration aNode = fieldDeclaration.fields.variables[0];
      expect(aNode.declaredElement, same(aElement));
      expect(aElement.type, typeProvider.intType);

      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, isNull);

      Expression aValue = aNode.initializer!;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      FieldElement bElement = cElement.getField('b')!;

      VariableDeclaration bNode = fieldDeclaration.fields.variables[1];
      expect(bNode.declaredElement, same(bElement));
      expect(bElement.type, typeProvider.doubleType);

      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, isNull);

      Expression aValue = bNode.initializer!;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_field_top() async {
    String content = r'''
var a = 1;
double b = 2.3;
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    {
      var aDeclaration = unit.declarations[0] as TopLevelVariableDeclaration;
      VariableDeclaration aNode = aDeclaration.variables.variables[0];
      var aElement = aNode.declaredElement as TopLevelVariableElement;
      expect(aElement, same(unitElement.topLevelVariables[0]));
      expect(aElement.type, typeProvider.intType);
      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, isNull);

      Expression aValue = aNode.initializer!;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      var bDeclaration = unit.declarations[1] as TopLevelVariableDeclaration;

      VariableDeclaration bNode = bDeclaration.variables.variables[0];
      var bElement = bNode.declaredElement as TopLevelVariableElement;
      expect(bElement, same(unitElement.topLevelVariables[1]));
      expect(bElement.type, typeProvider.doubleType);

      var namedType = bDeclaration.variables.type as NamedType;
      _assertNamedTypeSimple(namedType, typeProvider.doubleType);

      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, isNull);

      Expression aValue = bNode.initializer!;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_field_top_multiple() async {
    String content = r'''
var a = 1, b = 2.3;
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    var variableDeclaration =
        unit.declarations[0] as TopLevelVariableDeclaration;
    expect(variableDeclaration.variables.type, isNull);

    {
      VariableDeclaration aNode = variableDeclaration.variables.variables[0];
      var aElement = aNode.declaredElement as TopLevelVariableElement;
      expect(aElement, same(unitElement.topLevelVariables[0]));
      expect(aElement.type, typeProvider.intType);

      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, isNull);

      Expression aValue = aNode.initializer!;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      VariableDeclaration bNode = variableDeclaration.variables.variables[1];
      var bElement = bNode.declaredElement as TopLevelVariableElement;
      expect(bElement, same(unitElement.topLevelVariables[1]));
      expect(bElement.type, typeProvider.doubleType);

      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, isNull);

      Expression aValue = bNode.initializer!;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_function_namedParameters() async {
    addTestFile(r'''
double f(int a, {String b, bool c: 1 == 2}) {}
void main() {
  f(1, b: '2', c: true);
}
''');
    String fTypeString = 'double Function(int, {String b, bool c})';

    await resolveTestFile();
    var fDeclaration = result.unit.declarations[0] as FunctionDeclaration;
    var fElement = fDeclaration.declaredElement as FunctionElement;

    InterfaceType doubleType = typeProvider.doubleType;

    expect(fElement, isNotNull);
    assertType(fElement.type, fTypeString);

    expect(fDeclaration.name.staticElement, same(fElement));
    expect(fDeclaration.name.staticType, isNull);

    var fReturnTypeNode = fDeclaration.returnType as NamedType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);
    //
    // Validate the parameters at the declaration site.
    //
    List<ParameterElement> elements = fElement.parameters;
    expect(elements, hasLength(3));

    List<FormalParameter> nodes =
        fDeclaration.functionExpression.parameters!.parameters;
    expect(nodes, hasLength(3));

    _assertSimpleParameter(nodes[0] as SimpleFormalParameter, elements[0],
        name: 'a',
        offset: 13,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    var bNode = nodes[1] as DefaultFormalParameter;
    _assertDefaultParameter(bNode, elements[1],
        name: 'b',
        offset: 24,
        kind: ParameterKind.NAMED,
        type: typeProvider.stringType);
    expect(bNode.defaultValue, isNull);

    var cNode = nodes[2] as DefaultFormalParameter;
    _assertDefaultParameter(cNode, elements[2],
        name: 'c',
        offset: 32,
        kind: ParameterKind.NAMED,
        type: typeProvider.boolType);
    {
      var defaultValue = cNode.defaultValue as BinaryExpression;
      expect(defaultValue.staticElement, isNotNull);
      expect(defaultValue.staticType, typeProvider.boolType);
    }

    //
    // Validate the arguments at the call site.
    //
    var mainDeclaration = result.unit.declarations[1] as FunctionDeclaration;
    var body = mainDeclaration.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    List<Expression> arguments = invocation.argumentList.arguments;

    _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], fElement.parameters[2]);
  }

  test_top_functionTypeAlias() async {
    String content = r'''
typedef int F<T>(bool a, T b);
''';
    addTestFile(content);

    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var alias = unit.declarations[0] as FunctionTypeAlias;
    TypeAliasElement aliasElement = alias.declaredElement!;
    var function = aliasElement.aliasedElement as GenericFunctionTypeElement;
    expect(aliasElement, same(findElement.typeAlias('F')));
    expect(function.returnType, typeProvider.intType);

    _assertNamedTypeSimple(alias.returnType as NamedType, typeProvider.intType);

    _assertSimpleParameter(
        alias.parameters.parameters[0] as SimpleFormalParameter,
        function.parameters[0],
        name: 'a',
        offset: 22,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.boolType);

    _assertSimpleParameter(
        alias.parameters.parameters[1] as SimpleFormalParameter,
        function.parameters[1],
        name: 'b',
        offset: 27,
        kind: ParameterKind.REQUIRED,
        type: typeParameterTypeNone(aliasElement.typeParameters[0]));
  }

  test_top_typeParameter() async {
    String content = r'''
class A {}
class C<T extends A, U extends List<A>, V> {}
''';
    addTestFile(content);
    await resolveTestFile();
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.declaredElement!;

    var aNode = unit.declarations[0] as ClassDeclaration;
    ClassElement aElement = aNode.declaredElement!;
    expect(aElement, same(unitElement.classes[0]));

    var cNode = unit.declarations[1] as ClassDeclaration;
    ClassElement cElement = cNode.declaredElement!;
    expect(cElement, same(unitElement.classes[1]));

    {
      TypeParameter tNode = cNode.typeParameters!.typeParameters[0];
      expect(tNode.declaredElement, same(cElement.typeParameters[0]));

      var bound = tNode.bound as NamedType;
      expect(bound.type, interfaceTypeNone(aElement));

      var boundIdentifier = bound.name as SimpleIdentifier;
      expect(boundIdentifier.staticElement, same(aElement));
      expect(boundIdentifier.staticType, isNull);
    }

    {
      var listElement = typeProvider.listElement;
      var listOfA = listElement.instantiate(
        typeArguments: [interfaceTypeNone(aElement)],
        nullabilitySuffix: NullabilitySuffix.none,
      );

      TypeParameter uNode = cNode.typeParameters!.typeParameters[1];
      expect(uNode.declaredElement, same(cElement.typeParameters[1]));

      var bound = uNode.bound as NamedType;
      expect(bound.type, listOfA);

      var listIdentifier = bound.name as SimpleIdentifier;
      expect(listIdentifier.staticElement, same(listElement));
      expect(listIdentifier.staticType, isNull);

      var aNamedType = bound.typeArguments!.arguments[0] as NamedType;
      expect(aNamedType.type, interfaceTypeNone(aElement));

      var aIdentifier = aNamedType.name as SimpleIdentifier;
      expect(aIdentifier.staticElement, same(aElement));
      expect(aIdentifier.staticType, isNull);
    }

    {
      TypeParameter vNode = cNode.typeParameters!.typeParameters[2];
      expect(vNode.declaredElement, same(cElement.typeParameters[2]));
      expect(vNode.bound, isNull);
    }
  }

  test_tryCatch() async {
    addTestFile(r'''
void main() {
  try {} catch (e, st) {
    e;
    st;
  }
  try {} on int catch (e, st) {
    e;
    st;
  }
  try {} catch (e) {
    e;
  }
  try {} on int catch (e) {
    e;
  }
  try {} on int {}
}
''');
    await resolveTestFile();

    List<Statement> statements = _getMainStatements(result);

    // catch (e, st)
    {
      var statement = statements[0] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      expect(catchClause.exceptionType, isNull);

      var exceptionNode = catchClause.exceptionParameter as SimpleIdentifier;
      var exceptionElement =
          exceptionNode.staticElement as LocalVariableElement;
      expect(exceptionElement.type, typeProvider.objectType);

      var stackNode = catchClause.stackTraceParameter as SimpleIdentifier;
      var stackElement = stackNode.staticElement as LocalVariableElement;
      expect(stackElement.type, typeProvider.stackTraceType);

      List<Statement> catchStatements = catchClause.body.statements;

      var exceptionStatement = catchStatements[0] as ExpressionStatement;
      var exceptionIdentifier =
          exceptionStatement.expression as SimpleIdentifier;
      expect(exceptionIdentifier.staticElement, same(exceptionElement));
      expect(exceptionIdentifier.staticType, typeProvider.objectType);

      var stackStatement = catchStatements[1] as ExpressionStatement;
      var stackIdentifier = stackStatement.expression as SimpleIdentifier;
      expect(stackIdentifier.staticElement, same(stackElement));
      expect(stackIdentifier.staticType, typeProvider.stackTraceType);
    }

    // on int catch (e, st)
    {
      var statement = statements[1] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      _assertNamedTypeSimple(
          catchClause.exceptionType as NamedType, typeProvider.intType);

      var exceptionNode = catchClause.exceptionParameter as SimpleIdentifier;
      var exceptionElement =
          exceptionNode.staticElement as LocalVariableElement;
      expect(exceptionElement.type, typeProvider.intType);

      var stackNode = catchClause.stackTraceParameter as SimpleIdentifier;
      var stackElement = stackNode.staticElement as LocalVariableElement;
      expect(stackElement.type, typeProvider.stackTraceType);

      List<Statement> catchStatements = catchClause.body.statements;

      var exceptionStatement = catchStatements[0] as ExpressionStatement;
      var exceptionIdentifier =
          exceptionStatement.expression as SimpleIdentifier;
      expect(exceptionIdentifier.staticElement, same(exceptionElement));
      expect(exceptionIdentifier.staticType, typeProvider.intType);

      var stackStatement = catchStatements[1] as ExpressionStatement;
      var stackIdentifier = stackStatement.expression as SimpleIdentifier;
      expect(stackIdentifier.staticElement, same(stackElement));
      expect(stackIdentifier.staticType, typeProvider.stackTraceType);
    }

    // catch (e)
    {
      var statement = statements[2] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      expect(catchClause.exceptionType, isNull);
      expect(catchClause.stackTraceParameter, isNull);

      var exceptionNode = catchClause.exceptionParameter as SimpleIdentifier;
      var exceptionElement =
          exceptionNode.staticElement as LocalVariableElement;
      expect(exceptionElement.type, typeProvider.objectType);
    }

    // on int catch (e)
    {
      var statement = statements[3] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      _assertNamedTypeSimple(catchClause.exceptionType!, typeProvider.intType);
      expect(catchClause.stackTraceParameter, isNull);

      var exceptionNode = catchClause.exceptionParameter as SimpleIdentifier;
      var exceptionElement =
          exceptionNode.staticElement as LocalVariableElement;
      expect(exceptionElement.type, typeProvider.intType);
    }

    // on int catch (e)
    {
      var statement = statements[4] as TryStatement;
      CatchClause catchClause = statement.catchClauses[0];
      _assertNamedTypeSimple(
          catchClause.exceptionType as NamedType, typeProvider.intType);
      expect(catchClause.exceptionParameter, isNull);
      expect(catchClause.stackTraceParameter, isNull);
    }
  }

  test_type_dynamic() async {
    addTestFile('''
main() {
  dynamic d;
}
''');
    await resolveTestFile();
    var statements = _getMainStatements(result);
    var variableDeclarationStatement =
        statements[0] as VariableDeclarationStatement;
    var type = variableDeclarationStatement.variables.type as NamedType;
    expect(type.type, isDynamicType);
    var namedType = type.name;
    assertTypeNull(namedType);
    expect(namedType.staticElement, same(typeProvider.dynamicType.element));
  }

  test_type_functionTypeAlias() async {
    addTestFile(r'''
typedef T F<T>(bool a);
class C {
  F<int> f;
}
''');

    await resolveTestFile();

    FunctionTypeAlias alias = findNode.functionTypeAlias('F<T>');
    TypeAliasElement aliasElement = alias.declaredElement!;

    FieldDeclaration fDeclaration = findNode.fieldDeclaration('F<int> f');

    var namedType = fDeclaration.fields.type as NamedType;
    assertType(namedType, 'int Function(bool)');

    var typeIdentifier = namedType.name as SimpleIdentifier;
    expect(typeIdentifier.staticElement, same(aliasElement));
    expect(typeIdentifier.staticType, isNull);

    List<TypeAnnotation> typeArguments = namedType.typeArguments!.arguments;
    expect(typeArguments, hasLength(1));
    _assertNamedTypeSimple(typeArguments[0], typeProvider.intType);
  }

  test_type_void() async {
    addTestFile('''
main() {
  void v;
}
''');
    await resolveTestFile();
    var statements = _getMainStatements(result);
    var variableDeclarationStatement =
        statements[0] as VariableDeclarationStatement;
    var type = variableDeclarationStatement.variables.type as NamedType;
    expect(type.type, isVoidType);
    var namedType = type.name;
    expect(namedType.staticType, isNull);
    expect(namedType.staticElement, isNull);
  }

  test_typeAnnotation_prefixed() async {
    newFile('$testPackageLibPath/a.dart', content: 'class A {}');
    newFile('$testPackageLibPath/b.dart', content: "export 'a.dart';");
    newFile('$testPackageLibPath/c.dart', content: "export 'a.dart';");
    addTestFile(r'''
import 'b.dart' as b;
import 'c.dart' as c;
b.A a1;
c.A a2;
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    ImportElement bImport = unit.declaredElement!.library.imports[0];
    ImportElement cImport = unit.declaredElement!.library.imports[1];

    LibraryElement bLibrary = bImport.importedLibrary!;
    LibraryElement aLibrary = bLibrary.exports[0].exportedLibrary!;
    ClassElement aClass = aLibrary.getType('A')!;

    {
      var declaration = unit.declarations[0] as TopLevelVariableDeclaration;
      var namedType = declaration.variables.type as NamedType;

      var typeIdentifier = namedType.name as PrefixedIdentifier;
      expect(typeIdentifier.staticElement, aClass);

      expect(typeIdentifier.prefix.name, 'b');
      expect(typeIdentifier.prefix.staticElement, same(bImport.prefix));

      expect(typeIdentifier.identifier.staticElement, aClass);
    }

    {
      var declaration = unit.declarations[1] as TopLevelVariableDeclaration;
      var namedType = declaration.variables.type as NamedType;

      var typeIdentifier = namedType.name as PrefixedIdentifier;
      expect(typeIdentifier.staticElement, aClass);

      expect(typeIdentifier.prefix.name, 'c');
      expect(typeIdentifier.prefix.staticElement, same(cImport.prefix));

      expect(typeIdentifier.identifier.staticElement, aClass);
    }
  }

  test_typeLiteral() async {
    addTestFile(r'''
void main() {
  int;
  F;
}
typedef void F(int p);
''');
    await resolveTestFile();
    CompilationUnit unit = result.unit;

    var fNode = unit.declarations[1] as FunctionTypeAlias;
    TypeAliasElement fElement = fNode.declaredElement!;

    var statements = _getMainStatements(result);

    {
      var statement = statements[0] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;
      expect(identifier.staticElement, same(typeProvider.intType.element));
      expect(identifier.staticType, typeProvider.typeType);
    }

    {
      var statement = statements[1] as ExpressionStatement;
      var identifier = statement.expression as SimpleIdentifier;
      expect(identifier.staticElement, same(fElement));
      expect(identifier.staticType, typeProvider.typeType);
    }
  }

  test_typeParameter() async {
    addTestFile(r'''
class C<T> {
  get t => T;
}
''');
    await resolveTestFile();

    var identifier = findNode.simple('T;');
    assertElement(identifier, findElement.typeParameter('T'));
    assertType(identifier, 'Type');
  }

  test_unresolved_instanceCreation_name_11() async {
    addTestFile(r'''
int arg1, arg2;
main() {
  new Foo<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var creation = statement.expression as InstanceCreationExpression;
    expect(creation.staticType, isDynamicType);

    ConstructorName constructorName = creation.constructorName;
    expect(constructorName.name, isNull);

    NamedType namedType = constructorName.type2;
    expect(namedType.type, isDynamicType);

    var typeIdentifier = namedType.name as SimpleIdentifier;
    expect(typeIdentifier.staticElement, isNull);
    expect(typeIdentifier.staticType, isNull);

    assertTypeArguments(namedType.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(creation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  @failingTest
  test_unresolved_instanceCreation_name_21() async {
    addTestFile(r'''
int arg1, arg2;
main() {
  new foo.Bar<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var creation = statement.expression as InstanceCreationExpression;
    expect(creation.staticType, isDynamicType);

    ConstructorName constructorName = creation.constructorName;
    expect(constructorName.name, isNull);

    NamedType namedType = constructorName.type2;
    expect(namedType.type, isDynamicType);

    var typePrefixed = namedType.name as PrefixedIdentifier;
    expect(typePrefixed.staticElement, isNull);
    expect(typePrefixed.staticType, isDynamicType);

    SimpleIdentifier typePrefix = typePrefixed.prefix;
    expect(typePrefix.staticElement, isNull);
    expect(typePrefix.staticType, isNull);

    SimpleIdentifier typeIdentifier = typePrefixed.identifier;
    expect(typeIdentifier.staticElement, isNull);
    expect(typeIdentifier.staticType, isDynamicType);

    assertTypeArguments(namedType.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(creation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  @failingTest
  test_unresolved_instanceCreation_name_22() async {
    addTestFile(r'''
import 'dart:math' as foo;
int arg1, arg2;
main() {
  new foo.Bar<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var unitElement = result.unit.declaredElement!;
    var foo = unitElement.library.imports[0].prefix;

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var creation = statement.expression as InstanceCreationExpression;
    expect(creation.staticType, isDynamicType);

    ConstructorName constructorName = creation.constructorName;
    expect(constructorName.name, isNull);

    NamedType namedType = constructorName.type2;
    expect(namedType.type, isDynamicType);

    var typePrefixed = namedType.name as PrefixedIdentifier;
    expect(typePrefixed.staticElement, isNull);
    expect(typePrefixed.staticType, isDynamicType);

    SimpleIdentifier typePrefix = typePrefixed.prefix;
    expect(typePrefix.staticElement, same(foo));
    expect(typePrefix.staticType, isNull);

    SimpleIdentifier typeIdentifier = typePrefixed.identifier;
    expect(typeIdentifier.staticElement, isNull);
    expect(typeIdentifier.staticType, isDynamicType);

    assertTypeArguments(namedType.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(creation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_instanceCreation_name_31() async {
    addTestFile(r'''
int arg1, arg2;
main() {
  new foo.Bar<int, double>.baz(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var creation = statement.expression as InstanceCreationExpression;
    expect(creation.staticType, isDynamicType);

    ConstructorName constructorName = creation.constructorName;

    NamedType namedType = constructorName.type2;
    expect(namedType.type, isDynamicType);

    var typePrefixed = namedType.name as PrefixedIdentifier;
    assertElementNull(typePrefixed);
    assertTypeNull(typePrefixed);

    SimpleIdentifier typePrefix = typePrefixed.prefix;
    assertElementNull(typePrefix);
    assertTypeNull(typePrefix);

    SimpleIdentifier typeIdentifier = typePrefixed.identifier;
    assertElementNull(typeIdentifier);
    assertTypeNull(typeIdentifier);

    assertElementNull(constructorName.name);
    assertTypeNull(constructorName.name!);

    assertTypeArguments(namedType.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(creation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_instanceCreation_name_32() async {
    addTestFile(r'''
import 'dart:math' as foo;
int arg1, arg2;
main() {
  new foo.Bar<int, double>.baz(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var unitElement = result.unit.declaredElement!;
    var mathImport = unitElement.library.imports[0];
    var foo = mathImport.prefix;

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var creation = statement.expression as InstanceCreationExpression;
    expect(creation.staticType, isDynamicType);

    ConstructorName constructorName = creation.constructorName;

    NamedType namedType = constructorName.type2;
    expect(namedType.type, isDynamicType);

    var typePrefixed = namedType.name as PrefixedIdentifier;
    assertElementNull(typePrefixed);
    assertTypeNull(typePrefixed);

    SimpleIdentifier typePrefix = typePrefixed.prefix;
    assertElement(typePrefix, foo);
    assertTypeNull(typePrefix);

    SimpleIdentifier typeIdentifier = typePrefixed.identifier;
    assertElementNull(typeIdentifier);
    assertTypeNull(typeIdentifier);

    assertElementNull(constructorName.name);
    assertTypeNull(constructorName.name!);

    assertTypeArguments(namedType.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(creation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_instanceCreation_name_33() async {
    addTestFile(r'''
import 'dart:math' as foo;
int arg1, arg2;
main() {
  new foo.Random<int, double>.baz(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var unitElement = result.unit.declaredElement!;
    var mathImport = unitElement.library.imports[0];
    var foo = mathImport.prefix;
    var randomElement = mathImport.importedLibrary!.getType('Random')!;

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var creation = statement.expression as InstanceCreationExpression;
    expect(creation.staticType, interfaceTypeNone(randomElement));

    ConstructorName constructorName = creation.constructorName;

    NamedType namedType = constructorName.type2;
    assertType(namedType, 'Random');

    var typePrefixed = namedType.name as PrefixedIdentifier;
    assertElement(typePrefixed, randomElement);
    assertTypeNull(typePrefixed);

    SimpleIdentifier typePrefix = typePrefixed.prefix;
    assertElement(typePrefix, foo);
    assertTypeNull(typePrefix);

    SimpleIdentifier typeIdentifier = typePrefixed.identifier;
    assertElement(typeIdentifier, randomElement);
    assertTypeNull(typeIdentifier);

    assertElementNull(constructorName.name);
    assertTypeNull(constructorName.name!);

    assertTypeArguments(namedType.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(creation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_methodInvocation_noTarget() async {
    addTestFile(r'''
int arg1, arg2;
main() {
  bar<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var invocation = statement.expression as MethodInvocation;
    expect(invocation.target, isNull);
    expect(invocation.staticType, isDynamicType);
    assertUnresolvedInvokeType(invocation.staticInvokeType!);

    SimpleIdentifier name = invocation.methodName;
    expect(name.staticElement, isNull);
    expect(name.staticType, isDynamicType);

    assertTypeArguments(invocation.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(invocation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_methodInvocation_target_resolved() async {
    addTestFile(r'''
Object foo;
int arg1, arg2;
main() {
  foo.bar<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    TopLevelVariableElement foo = _getTopLevelVariable(result, 'foo');

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var invocation = statement.expression as MethodInvocation;
    expect(invocation.staticType, isDynamicType);
    assertUnresolvedInvokeType(invocation.staticInvokeType!);

    var target = invocation.target as SimpleIdentifier;
    expect(target.staticElement, same(foo.getter));
    expect(target.staticType, typeProvider.objectType);

    SimpleIdentifier name = invocation.methodName;
    expect(name.staticElement, isNull);
    assertUnresolvedInvokeType(name.typeOrThrow);

    assertTypeArguments(invocation.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(invocation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_methodInvocation_target_unresolved() async {
    addTestFile(r'''
int arg1, arg2;
main() {
  foo.bar<int, double>(arg1, p2: arg2);
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var invocation = findNode.methodInvocation('foo.bar');
    assertTypeDynamic(invocation);
    assertUnresolvedInvokeType(invocation.staticInvokeType!);

    var target = invocation.target as SimpleIdentifier;
    assertElementNull(target);
    assertTypeDynamic(target);

    SimpleIdentifier name = invocation.methodName;
    assertElementNull(name);
    assertUnresolvedInvokeType(name.typeOrThrow);

    assertTypeArguments(invocation.typeArguments!, [intType, doubleType]);
    _assertInvocationArguments(invocation.argumentList,
        [checkTopVarRef('arg1'), checkTopVarUndefinedNamedRef('arg2')]);
  }

  test_unresolved_postfix_operand() async {
    addTestFile(r'''
main() {
  a++;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var postfix = findNode.postfix('a++');
    assertElementNull(postfix);
    assertTypeDynamic(postfix);

    var aRef = postfix.operand as SimpleIdentifier;
    if (hasAssignmentLeftResolution) {
      assertElementNull(aRef);
      assertTypeDynamic(aRef);
    } else {
      assertElementNull(aRef);
      assertTypeNull(aRef);
    }
  }

  test_unresolved_postfix_operator() async {
    addTestFile(r'''
A a;
main() {
  a++;
}
class A {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var postfix = findNode.postfix('a++');
    assertElementNull(postfix);
    assertType(postfix, 'A');

    var aRef = postfix.operand as SimpleIdentifier;
    if (hasAssignmentLeftResolution) {
      assertElement(aRef, findElement.topSet('a'));
      assertType(aRef, 'A');
    } else {
      assertElementNull(aRef);
      assertTypeNull(aRef);
    }
  }

  test_unresolved_prefix_operand() async {
    addTestFile(r'''
main() {
  ++a;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var prefix = findNode.prefix('++a');
    assertElementNull(prefix);
    assertTypeDynamic(prefix);

    var aRef = prefix.operand as SimpleIdentifier;
    if (hasAssignmentLeftResolution) {
      assertElementNull(aRef);
      assertTypeDynamic(aRef);
    } else {
      assertElementNull(aRef);
      assertTypeNull(aRef);
    }
  }

  test_unresolved_prefix_operator() async {
    addTestFile(r'''
A a;
main() {
  ++a;
}
class A {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var prefix = findNode.prefix('++a');
    assertElementNull(prefix);
    assertTypeDynamic(prefix);

    var aRef = prefix.operand as SimpleIdentifier;
    if (hasAssignmentLeftResolution) {
      assertElement(aRef, findElement.topSet('a'));
      assertType(aRef, 'A');
    } else {
      assertElementNull(aRef);
      assertTypeNull(aRef);
    }
  }

  test_unresolved_prefixedIdentifier_identifier() async {
    addTestFile(r'''
Object foo;
main() {
  foo.bar;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    TopLevelVariableElement foo = _getTopLevelVariable(result, 'foo');

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var prefixed = statement.expression as PrefixedIdentifier;
    expect(prefixed.staticElement, isNull);
    expect(prefixed.staticType, isDynamicType);

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, same(foo.getter));
    expect(prefix.staticType, typeProvider.objectType);

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, isNull);
    expect(identifier.staticType, isDynamicType);
  }

  test_unresolved_prefixedIdentifier_prefix() async {
    addTestFile(r'''
main() {
  foo.bar;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var prefixed = statement.expression as PrefixedIdentifier;
    expect(prefixed.staticElement, isNull);
    expect(prefixed.staticType, isDynamicType);

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, isNull);
    expect(prefix.staticType, isDynamicType);

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, isNull);
    expect(identifier.staticType, isDynamicType);
  }

  test_unresolved_propertyAccess_1() async {
    addTestFile(r'''
main() {
  foo.bar.baz;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var propertyAccess = statement.expression as PropertyAccess;
    expect(propertyAccess.staticType, isDynamicType);

    {
      var prefixed = propertyAccess.target as PrefixedIdentifier;
      expect(prefixed.staticElement, isNull);
      expect(prefixed.staticType, isDynamicType);

      SimpleIdentifier prefix = prefixed.prefix;
      expect(prefix.staticElement, isNull);
      expect(prefix.staticType, isDynamicType);

      SimpleIdentifier identifier = prefixed.identifier;
      expect(identifier.staticElement, isNull);
      expect(identifier.staticType, isDynamicType);
    }

    SimpleIdentifier property = propertyAccess.propertyName;
    expect(property.staticElement, isNull);
    expect(property.staticType, isDynamicType);
  }

  test_unresolved_propertyAccess_2() async {
    addTestFile(r'''
Object foo;
main() {
  foo.bar.baz;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    TopLevelVariableElement foo = _getTopLevelVariable(result, 'foo');

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var propertyAccess = statement.expression as PropertyAccess;
    expect(propertyAccess.staticType, isDynamicType);

    {
      var prefixed = propertyAccess.target as PrefixedIdentifier;
      expect(prefixed.staticElement, isNull);
      expect(prefixed.staticType, isDynamicType);

      SimpleIdentifier prefix = prefixed.prefix;
      expect(prefix.staticElement, same(foo.getter));
      expect(prefix.staticType, typeProvider.objectType);

      SimpleIdentifier identifier = prefixed.identifier;
      expect(identifier.staticElement, isNull);
      expect(identifier.staticType, isDynamicType);
    }

    SimpleIdentifier property = propertyAccess.propertyName;
    expect(property.staticElement, isNull);
    expect(property.staticType, isDynamicType);
  }

  test_unresolved_propertyAccess_3() async {
    addTestFile(r'''
Object foo;
main() {
  foo.hashCode.baz;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    PropertyAccessorElement objectHashCode =
        objectElement.getGetter('hashCode')!;
    TopLevelVariableElement foo = _getTopLevelVariable(result, 'foo');

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;

    var propertyAccess = statement.expression as PropertyAccess;
    expect(propertyAccess.staticType, isDynamicType);

    {
      var prefixed = propertyAccess.target as PrefixedIdentifier;
      assertPrefixedIdentifier(
        prefixed,
        element: elementMatcher(
          objectHashCode,
          isLegacy: isLegacyLibrary,
        ),
        type: 'int',
      );

      SimpleIdentifier prefix = prefixed.prefix;
      expect(prefix.staticElement, same(foo.getter));
      expect(prefix.staticType, typeProvider.objectType);

      SimpleIdentifier identifier = prefixed.identifier;
      assertSimpleIdentifier(
        identifier,
        element: elementMatcher(
          objectHashCode,
          isLegacy: isLegacyLibrary,
        ),
        type: 'int',
      );
    }

    SimpleIdentifier property = propertyAccess.propertyName;
    expect(property.staticElement, isNull);
    expect(property.staticType, isDynamicType);
  }

  test_unresolved_redirectingFactory_1() async {
    addTestFile(r'''
class A {
  factory A() = B;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);
  }

  test_unresolved_redirectingFactory_22() async {
    addTestFile(r'''
class A {
  factory A() = B.named;
}
class B {}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    var bRef = findNode.simple('B.');
    assertElement(bRef, findElement.class_('B'));
    assertTypeNull(bRef);

    var namedRef = findNode.simple('named;');
    assertElementNull(namedRef);
    assertTypeNull(namedRef);
  }

  test_unresolved_simpleIdentifier() async {
    addTestFile(r'''
main() {
  foo;
}
''');
    await resolveTestFile();
    expect(result.errors, isNotEmpty);

    List<Statement> statements = _getMainStatements(result);
    var statement = statements[0] as ExpressionStatement;
    var identifier = statement.expression as SimpleIdentifier;
    expect(identifier.staticElement, isNull);
    expect(identifier.staticType, isDynamicType);
  }

  /// Assert that the [argument] is associated with the [expected]. If the
  /// [argument] is a [NamedExpression], the name must be resolved to the
  /// parameter.
  void _assertArgumentToParameter(
      Expression argument, ParameterElement expected,
      {DartType? memberType}) {
    ParameterElement actual = argument.staticParameterElement!;
    if (memberType != null) {
      expect(actual.type, memberType);
    }

    expect(actual.declaration, same(expected));

    if (argument is NamedExpression) {
      SimpleIdentifier name = argument.name.label;
      expect(name.staticElement, same(actual));
      expect(name.staticType, isNull);
    }
  }

  /// Assert that the [argument] has the [expectedType]. If the [argument] is
  /// a [NamedExpression], the name must be resolved to the same parameter.
  void _assertArgumentToParameter2(Expression argument, String expectedType) {
    ParameterElement actual = argument.staticParameterElement!;
    assertType(actual.type, expectedType);

    if (argument is NamedExpression) {
      SimpleIdentifier name = argument.name.label;
      expect(name.staticElement, same(actual));
      expect(name.staticType, isNull);
    }
  }

  /// Assert that the given [creation] creates instance of the [classElement].
  /// Limitations: no import prefix, no type arguments, unnamed constructor.
  void _assertConstructorInvocation(
      InstanceCreationExpression creation, ClassElement classElement) {
    assertType(creation, classElement.name);

    var constructorName = creation.constructorName;
    var constructorElement = classElement.unnamedConstructor;
    expect(constructorName.staticElement, constructorElement);

    var namedType = constructorName.type2;
    expect(namedType.typeArguments, isNull);

    var typeIdentifier = namedType.name as SimpleIdentifier;
    assertElement(typeIdentifier, classElement);
    assertTypeNull(typeIdentifier);

    // Only unnamed constructors are supported now.
    expect(constructorName.name, isNull);
  }

  void _assertDefaultParameter(
      DefaultFormalParameter node, ParameterElement element,
      {String? name, int? offset, ParameterKind? kind, DartType? type}) {
    expect(node, isNotNull);
    var normalNode = node.parameter as SimpleFormalParameter;
    _assertSimpleParameter(normalNode, element,
        name: name, offset: offset, kind: kind, type: type);
  }

  /// Test that [argumentList] has exactly two arguments - required `arg1`, and
  /// unresolved named `arg2`, both are the reference to top-level variables.
  void _assertInvocationArguments(ArgumentList argumentList,
      List<void Function(Expression)> argumentCheckers) {
    expect(argumentList.arguments, hasLength(argumentCheckers.length));
    for (int i = 0; i < argumentCheckers.length; i++) {
      argumentCheckers[i](argumentList.arguments[i]);
    }
  }

  void _assertNamedTypeSimple(TypeAnnotation namedType, DartType type) {
    namedType as NamedType;
    expect(namedType.type, type);

    var identifier = namedType.name as SimpleIdentifier;
    expect(identifier.staticElement, same(type.element));
    expect(identifier.staticType, isNull);
  }

  void _assertParameterElement(ParameterElement element,
      {String? name, int? offset, ParameterKind? kind, DartType? type}) {
    expect(element, isNotNull);
    expect(name, isNotNull);
    expect(offset, isNotNull);
    expect(kind, isNotNull);
    expect(type, isNotNull);
    expect(element.name, name);
    expect(element.nameOffset, offset);
    // ignore: deprecated_member_use_from_same_package
    expect(element.parameterKind, kind);
    expect(element.type, type);
  }

  void _assertSimpleParameter(
      SimpleFormalParameter node, ParameterElement element,
      {String? name, int? offset, ParameterKind? kind, DartType? type}) {
    _assertParameterElement(element,
        name: name, offset: offset, kind: kind, type: type);

    expect(node, isNotNull);
    expect(node.declaredElement, same(element));
    expect(node.identifier!.staticElement, same(element));

    var namedType = node.type as NamedType?;
    if (namedType != null) {
      expect(namedType.type, type);
      expect(namedType.name.staticElement, same(type!.element));
    }
  }

  List<Statement> _getMainStatements(ResolvedUnitResult result) {
    for (var declaration in result.unit.declarations) {
      if (declaration is FunctionDeclaration &&
          declaration.name.name == 'main') {
        var body = declaration.functionExpression.body as BlockFunctionBody;
        return body.block.statements;
      }
    }
    fail('Not found main() in ${result.unit}');
  }

  TopLevelVariableElement _getTopLevelVariable(
      ResolvedUnitResult result, String name) {
    for (var variable in result.unit.declaredElement!.topLevelVariables) {
      if (variable.name == name) {
        return variable;
      }
    }
    fail('Not found $name');
  }
}
