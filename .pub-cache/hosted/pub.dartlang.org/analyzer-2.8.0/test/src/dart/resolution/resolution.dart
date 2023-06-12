// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';

import '../../../generated/test_support.dart';

final isDynamicType = TypeMatcher<DynamicTypeImpl>();

final isNeverType = TypeMatcher<NeverTypeImpl>();

final isVoidType = TypeMatcher<VoidTypeImpl>();

/// Base for resolution tests.
mixin ResolutionTest implements ResourceProviderMixin {
  late ResolvedUnitResult result;
  late FindNode findNode;
  late FindElement findElement;

  ClassElement get boolElement => typeProvider.boolElement;

  ClassElement get doubleElement => typeProvider.doubleType.element;

  InterfaceType get doubleType => typeProvider.doubleType;

  Element get dynamicElement => typeProvider.dynamicType.element!;

  FeatureSet get featureSet => result.libraryElement.featureSet;

  ClassElement get futureElement => typeProvider.futureElement;

  /// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
  bool get hasAssignmentLeftResolution => false;

  ClassElement get intElement => typeProvider.intType.element;

  InterfaceType get intType => typeProvider.intType;

  bool get isLegacyLibrary {
    return !result.libraryElement.isNonNullableByDefault;
  }

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  NeverElementImpl get neverElement => NeverElementImpl.instance;

  ClassElement get numElement => typeProvider.numType.element;

  ClassElement get objectElement => typeProvider.objectType.element;

  InterfaceType get objectType => typeProvider.objectType;

  ClassElement get stringElement => typeProvider.stringType.element;

  InterfaceType get stringType => typeProvider.stringType;

  String get testFilePath => '/test/lib/test.dart';

  TypeProvider get typeProvider => result.typeProvider;

  TypeSystemImpl get typeSystem => result.typeSystem as TypeSystemImpl;

  /// Whether `DartType.toString()` with nullability should be asked.
  bool get typeToStringWithNullability => false;

  VoidType get voidType => VoidTypeImpl.instance;

  void addTestFile(String content) {
    newFile(testFilePath, content: content);
  }

  void assertAssignment(
    AssignmentExpression node, {
    required Object? readElement,
    required String? readType,
    required Object? writeElement,
    required String writeType,
    required Object? operatorElement,
    required String type,
  }) {
    assertCompoundAssignment(
      node,
      readElement: readElement,
      readType: readType,
      writeElement: writeElement,
      writeType: writeType,
    );
    assertElement(node.staticElement, operatorElement);
    assertType(node, type);
  }

  void assertBinaryExpression(
    BinaryExpression node, {
    required Object? element,
    required String type,
  }) {
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  /// Assert that the given [identifier] is a reference to a class, in the
  /// form that is not a separate expression, e.g. in a static method
  /// invocation like `C.staticMethod()`, or a type annotation `C c = null`.
  void assertClassRef(Expression? identifier, ClassElement expectedElement) {
    identifier as SimpleIdentifier;
    assertElement(identifier, expectedElement);
    assertTypeNull(identifier);
  }

  void assertCompoundAssignment(
    CompoundAssignmentExpression node, {
    required Object? readElement,
    required String? readType,
    required Object? writeElement,
    required String? writeType,
  }) {
    assertElement(node.readElement, readElement);
    if (readType == null) {
      expect(node.readType, isNull);
    } else {
      assertType(node.readType, readType);
    }

    assertElement(node.writeElement, writeElement);
    if (writeType == null) {
      expect(node.writeType, isNull);
    } else {
      assertType(node.writeType, writeType);
    }
  }

  void assertConstructorElement(ConstructorElement? actual, Object? expected) {
    if (actual is ConstructorMember && expected is ConstructorMember) {
      expect(actual.declaration, same(expected.declaration));
      // TODO(brianwilkerson) Compare the type arguments of the two members.
    } else {
      assertElement(actual, expected);
    }
  }

  void assertConstructorReference(
    ConstructorReference node,
    Object? expectedConstructorElement,
    ClassElement expectedClassElement,
    String expectedType, {
    PrefixElement? expectedPrefix,
    Element? expectedTypeNameElement,
  }) {
    var actualConstructorName = node.constructorName.name;
    if (actualConstructorName != null) {
      assertConstructorElement(
        actualConstructorName.staticElement as ConstructorElement?,
        expectedConstructorElement,
      );
    }

    assertElement(node, expectedConstructorElement);
    assertType(node, expectedType);

    var namedType = node.constructorName.type2;
    expectedTypeNameElement ??= expectedClassElement;
    assertNamedType(
      namedType, expectedTypeNameElement,
      // The [NamedType] child node of the [ConstructorName] should not have a
      // static type.
      null,
      expectedPrefix: expectedPrefix,
    );
  }

  void assertConstructors(ClassElement class_, List<String> expected) {
    expect(
      class_.constructors.map((c) {
        return c.getDisplayString(withNullability: false);
      }).toList(),
      unorderedEquals(expected),
    );
  }

  void assertElement(Object? nodeOrElement, Object? elementOrMatcher) {
    Element? element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element?;
    }

    expect(element, _elementMatcher(elementOrMatcher));
  }

  void assertElement2(
    Object? nodeOrElement, {
    required Element declaration,
    bool isLegacy = false,
    Map<String, String> substitution = const {},
  }) {
    Element? element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element?;
    }

    var actualDeclaration = element?.declaration;
    expect(actualDeclaration, same(declaration));

    if (element is Member) {
      expect(element.isLegacy, isLegacy);
      assertSubstitution(element.substitution, substitution);
    } else {
      if (isLegacy || substitution.isNotEmpty) {
        fail('Expected to be a Member: (${element.runtimeType}) $element');
      }
    }
  }

  void assertElementLibraryUri(Element? element, String expected) {
    var uri = element!.library!.source.uri;
    expect('$uri', expected);
  }

  void assertElementName(Element element, String name,
      {bool isSynthetic = false, int? offset}) {
    expect(element.name, name);
    expect(element.isSynthetic, isSynthetic);
    if (offset != null) {
      expect(element.nameOffset, offset);
    }
  }

  void assertElementNull(Object? nodeOrElement) {
    Element? element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element?;
    }

    expect(element, isNull);
  }

  void assertElementString(Element element, String expected) {
    var str = element.getDisplayString(
      withNullability: typeToStringWithNullability,
    );
    expect(str, expected);
  }

  void assertElementTypes(List<DartType>? types, List<String> expected,
      {bool ordered = false}) {
    if (types == null) {
      fail('Expected types, actually null.');
    }

    var typeStrList = types.map(typeString).toList();
    if (ordered) {
      expect(typeStrList, expected);
    } else {
      expect(typeStrList, unorderedEquals(expected));
    }
  }

  void assertEnclosingElement(Element element, Element expectedEnclosing) {
    expect(element.enclosingElement, expectedEnclosing);
  }

  Future<void> assertErrorsInCode(
      String code, List<ExpectedError> expectedErrors) async {
    addTestFile(code);
    await resolveTestFile();

    assertErrorsInResolvedUnit(result, expectedErrors);
  }

  Future<ResolvedUnitResult> assertErrorsInFile(
    String path,
    String content,
    List<ExpectedError> expectedErrors,
  ) async {
    path = convertPath(path);
    newFile(path, content: content);

    var result = await resolveFile(path);
    assertErrorsInResolvedUnit(result, expectedErrors);

    return result;
  }

  Future<void> assertErrorsInFile2(
    String path,
    List<ExpectedError> expectedErrors,
  ) async {
    path = convertPath(path);

    var result = await resolveFile(path);
    assertErrorsInResolvedUnit(result, expectedErrors);
  }

  void assertErrorsInList(
    List<AnalysisError> errors,
    List<ExpectedError> expectedErrors,
  ) {
    GatheringErrorListener errorListener = GatheringErrorListener();
    errorListener.addAll(errors);
    errorListener.assertErrors(expectedErrors);
  }

  void assertErrorsInResolvedUnit(
    ResolvedUnitResult result,
    List<ExpectedError> expectedErrors,
  ) {
    assertErrorsInList(result.errors, expectedErrors);
  }

  void assertErrorsInResult(List<ExpectedError> expectedErrors) {
    assertErrorsInResolvedUnit(result, expectedErrors);
  }

  void assertExtensionOverride(
    ExtensionOverride node, {
    required Object element,
    required String extendedType,
    required List<String> typeArgumentTypes,
  }) {
    assertElement(node, element);
    assertType(node.extendedType, extendedType);
    assertElementTypes(node.typeArgumentTypes, typeArgumentTypes);
  }

  void assertFunctionExpressionInvocation(
    FunctionExpressionInvocation node, {
    required ExecutableElement? element,
    required List<String> typeArgumentTypes,
    required String invokeType,
    required String type,
  }) {
    assertElement(node, element);
    assertTypeArgumentTypes(node, typeArgumentTypes);
    assertInvokeType(node, invokeType);
    assertType(node, type);
  }

  void assertFunctionReference(
      FunctionReference node, Element? expectedElement, String expectedType) {
    if (expectedElement != null) {
      assertElement(node, expectedElement);
    }
    assertType(node, expectedType);
  }

  void assertHasTestErrors() {
    expect(result.errors, isNotEmpty);
  }

  void assertIdentifierTopGetRef(SimpleIdentifier ref, String name) {
    var getter = findElement.topGet(name);
    assertElement(ref, getter);

    var type = typeString(getter.returnType);
    assertType(ref, type);
  }

  void assertIdentifierTopSetRef(SimpleIdentifier ref, String name) {
    var setter = findElement.topSet(name);
    assertElement(ref, setter);

    var type = typeString(setter.parameters[0].type);
    assertType(ref, type);
  }

  void assertImplicitCallReference(ImplicitCallReference node,
      Element? expectedElement, String expectedType) {
    assertElement(node, expectedElement);
    assertType(node, expectedType);
  }

  /// In valid code [element] must be a [PrefixElement], but for invalid code
  /// like `int.double v;` we want to resolve `int` somehow. Still not type.
  void assertImportPrefix(Expression? identifier, Element? element) {
    identifier as SimpleIdentifier;
    assertElement(identifier, element);
    assertTypeNull(identifier);
  }

  void assertIndexExpression(
    IndexExpression node, {
    required Object? readElement,
    required Object? writeElement,
    required String? type,
  }) {
    var isRead = node.inGetterContext();
    var isWrite = node.inSetterContext();
    if (isRead && isWrite) {
      assertElement(node.staticElement, writeElement);
    } else if (isRead) {
      assertElement(node.staticElement, readElement);
    } else {
      expect(isWrite, isTrue);
      assertElement(node.staticElement, writeElement);
    }

    if (isRead) {
      assertType(node, type);
    } else {
      // TODO(scheglov) enforce this
//      expect(type, isNull);
//      assertTypeNull(node);
    }
  }

  /// TODO(srawlins): Refactor to accept an `Object? expectedConstructor` which
  /// can accept `elementMatcher` for generics, and simplify, similar to
  /// [assertConstructorReference].
  void assertInstanceCreation(
    InstanceCreationExpression creation,
    ClassElement expectedClassElement,
    String expectedType, {
    String? constructorName,
    bool expectedConstructorMember = false,
    Map<String, String>? expectedSubstitution,
    PrefixElement? expectedPrefix,
    Element? expectedTypeNameElement,
  }) {
    var expectedConstructorElement =
        _getConstructorElement(expectedClassElement, constructorName);

    var actualConstructorElement =
        getNodeElement(creation) as ConstructorElement?;
    var constructorName2 = creation.constructorName.name;
    if (constructorName2 != null) {
      // TODO(brianwilkerson) This used to enforce that the two elements were
      // the same object, but the changes to the AstRewriteVisitor broke that.
      // We should explore re-establishing this restriction for performance.
      assertConstructorElement(
        constructorName2.staticElement as ConstructorElement?,
        actualConstructorElement,
      );
    }

    if (expectedConstructorMember) {
      expect(actualConstructorElement, const TypeMatcher<Member>());
      assertMember(
        creation,
        expectedConstructorElement,
        expectedSubstitution!,
      );
    } else {
      assertElement(creation, expectedConstructorElement);
    }

    assertType(creation, expectedType);

    var namedType = creation.constructorName.type2;
    expectedTypeNameElement ??= expectedClassElement;
    assertNamedType(namedType, expectedTypeNameElement, expectedType,
        expectedPrefix: expectedPrefix);
  }

  /// Resolve the [code], and ensure that it can be resolved without a crash,
  /// and is invalid, i.e. produces a diagnostic.
  Future<void> assertInvalidTestCode(String code) async {
    await resolveTestCode(code);
    assertHasTestErrors();
  }

  void assertInvokeType(Expression node, String expected) {
    DartType? actual;
    if (node is BinaryExpression) {
      actual = node.staticInvokeType;
    } else if (node is InvocationExpression) {
      actual = node.staticInvokeType;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
    expect(typeString(actual!), expected);
  }

  void assertInvokeTypeDynamic(InvocationExpression node) {
    var actual = node.staticInvokeType;
    expect(actual, isDynamicType);
  }

  void assertInvokeTypeNull(BinaryExpression node) {
    var actual = node.staticInvokeType;
    expect(actual, isNull);
  }

  void assertMember(
    Object? elementOrNode,
    Element expectedBase,
    Map<String, String> expectedSubstitution,
  ) {
    Member? actual;
    if (elementOrNode is Member) {
      actual = elementOrNode;
    } else {
      actual = getNodeElement(elementOrNode as AstNode) as Member;
    }

    expect(actual.declaration, same(expectedBase));

    assertSubstitution(actual.substitution, expectedSubstitution);
  }

  void assertMethodInvocation(
    MethodInvocation invocation,
    Object? expectedElement,
    String expectedInvokeType, {
    String? expectedMethodNameType,
    String? expectedNameType,
    String? expectedType,
    List<String> expectedTypeArguments = const <String>[],
  }) {
    var invocationImpl = invocation as MethodInvocationImpl;

    // TODO(scheglov) Check for Member.
    var element = invocation.methodName.staticElement;
    if (expectedElement is Element) {
      expect(element?.declaration, same(expectedElement));
    } else {
      expect(element, expectedElement);
    }

    // TODO(scheglov) Should we enforce this?
//    if (expectedNameType == null) {
//      if (expectedElement is ExecutableElement) {
//        expectedNameType = expectedElement.type.displayName;
//      } else if (expectedElement is VariableElement) {
//        expectedNameType = expectedElement.type.displayName;
//      }
//    }
//    assertType(invocation.methodName, expectedNameType);

    assertTypeArgumentTypes(invocation, expectedTypeArguments);

    assertInvokeType(invocation, expectedInvokeType);

    expectedType ??= _extractReturnType(expectedInvokeType);
    assertType(invocation, expectedType);

    expectedMethodNameType ??= expectedInvokeType;
    assertType(invocationImpl.methodNameType, expectedMethodNameType);
  }

  void assertMethodInvocation2(
    MethodInvocation node, {
    required Object? element,
    required List<String> typeArgumentTypes,
    required String invokeType,
    required String type,
  }) {
    assertElement(node.methodName, element);
    assertTypeArgumentTypes(node, typeArgumentTypes);
    assertType(node.staticInvokeType, invokeType);
    assertType(node.staticType, type);
  }

  void assertNamedParameterRef(String search, String name) {
    var ref = findNode.simple(search);
    assertElement(ref, findElement.parameter(name));
    assertTypeNull(ref);
  }

  void assertNamedType(
      NamedType node, Element? expectedElement, String? expectedType,
      {Element? expectedPrefix}) {
    assertType(node, expectedType);

    if (expectedPrefix == null) {
      var name = node.name as SimpleIdentifier;
      assertElement(name, expectedElement);
      // TODO(scheglov) Should this be null?
//      assertType(name, expectedType);
    } else {
      var name = node.name as PrefixedIdentifier;
      assertImportPrefix(name.prefix, expectedPrefix);
      assertElement(name.identifier, expectedElement);

      // TODO(scheglov) This should be null, but it is not.
      // ResolverVisitor sets the tpe for `Bar` in `new foo.Bar()`. This is
      // probably wrong. It is fine for the TypeName `foo.Bar` to have a type,
      // and for `foo.Bar()` to have a type. But not a name of a type? No.
//      expect(name.identifier.staticType, isNull);
    }
  }

  void assertNamespaceDirectiveSelected(
    NamespaceDirective directive, {
    required String expectedRelativeUri,
    required String expectedUri,
  }) {
    expect(directive.selectedUriContent, expectedRelativeUri);
    expect('${directive.selectedSource!.uri}', expectedUri);
  }

  Future<void> assertNoErrorsInCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    assertErrorsInResolvedUnit(result, const []);
  }

  void assertNoErrorsInResult() {
    assertErrorsInResult(const []);
  }

  void assertParameterElement(
    Expression expression,
    ParameterElement expected,
  ) {
    expect(expression.staticParameterElement, expected);
  }

  void assertParameterElementType(FormalParameter node, String expected) {
    var parameterElement = node.declaredElement!;
    assertType(parameterElement.type, expected);
  }

  void assertPostfixExpression(
    PostfixExpression node, {
    required Object? readElement,
    required String? readType,
    required Object? writeElement,
    required String? writeType,
    required Object? element,
    required String type,
  }) {
    assertCompoundAssignment(
      node,
      readElement: readElement,
      readType: readType,
      writeElement: writeElement,
      writeType: writeType,
    );
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  void assertPrefixedIdentifier(
    PrefixedIdentifier node, {
    required Object? element,
    required String type,
  }) {
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  void assertPrefixExpression(
    PrefixExpression node, {
    required Object? readElement,
    required String? readType,
    required Object? writeElement,
    required String? writeType,
    required Object? element,
    required String type,
  }) {
    assertCompoundAssignment(
      node,
      readElement: readElement,
      readType: readType,
      writeElement: writeElement,
      writeType: writeType,
    );
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  void assertPropertyAccess(
    PropertyAccess access,
    Element expectedElement,
    String expectedType,
  ) {
    assertElement(access.propertyName, expectedElement);
    assertType(access, expectedType);
  }

  void assertPropertyAccess2(
    PropertyAccess node, {
    required Object? element,
    required String type,
  }) {
    assertElement(node.propertyName.staticElement, element);
    assertType(node.staticType, type);
  }

  void assertSimpleIdentifier(
    Expression node, {
    required Object? element,
    required String? type,
  }) {
    if (node is! SimpleIdentifier) {
      _failNotSimpleIdentifier(node);
    }

    var isRead = node.inGetterContext();
    expect(isRead, isTrue);

    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  /// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
  void assertSimpleIdentifierAssignmentTarget(Expression node) {
    if (node is! SimpleIdentifier) {
      _failNotSimpleIdentifier(node);
    }

    // TODO(scheglov) Enforce maybe?
    // Currently VariableResolverVisitor sets it.
    // expect(node.staticElement, isNull);
    expect(node.staticType, isNull);
  }

  void assertSubstitution(
    MapSubstitution substitution,
    Map<String, String> expected,
  ) {
    var actualMapString = Map.fromEntries(
      substitution.map.entries.where((entry) {
        return entry.key.enclosingElement is! ExecutableElement;
      }).map((entry) {
        return MapEntry(
          entry.key.name,
          typeString(entry.value),
        );
      }),
    );
    expect(actualMapString, expected);
  }

  void assertSuperExpression(Expression? node) {
    if (node is! SuperExpression) {
      fail('Expected SuperExpression: (${node.runtimeType}) $node');
    }

    // TODO(scheglov) I think `super` does not have type itself.
    // It is just a signal to look for implemented method in the supertype.
    // With mixins there isn't a type anyway.
//    assertTypeNull(superExpression);
  }

  void assertTopGetRef(String search, String name) {
    var ref = findNode.simple(search);
    assertIdentifierTopGetRef(ref, name);
  }

  void assertType(Object? typeOrNode, String? expected) {
    DartType? actual;
    if (typeOrNode is DartType) {
      actual = typeOrNode;
    } else if (typeOrNode is Expression) {
      actual = typeOrNode.staticType;
    } else if (typeOrNode is GenericFunctionType) {
      actual = typeOrNode.type;
    } else if (typeOrNode is NamedType) {
      actual = typeOrNode.type;
    } else {
      fail('Unsupported node: (${typeOrNode.runtimeType}) $typeOrNode');
    }

    if (expected == null) {
      expect(actual, isNull);
    } else if (actual == null) {
      fail('Null, expected: $expected');
    } else {
      expect(typeString(actual), expected);
    }
  }

  /// We have a contract with the Angular team that FunctionType(s) from
  /// typedefs carry the element of the typedef, and the type arguments.
  void assertTypeAlias(
    DartType type, {
    required TypeAliasElement element,
    required List<String> typeArguments,
  }) {
    assertElement2(type.alias?.element, declaration: element);
    assertElementTypes(type.alias?.typeArguments, typeArguments);
  }

  /// Assert that the given [identifier] is a reference to a type alias, in the
  /// form that is not a separate expression, e.g. in a static method
  /// invocation like `C.staticMethod()`, or a type annotation `C c = null`.
  void assertTypeAliasRef(
      SimpleIdentifier identifier, TypeAliasElement expected) {
    assertElement(identifier, expected);
    assertTypeNull(identifier);
  }

  void assertTypeArgumentTypes(
    InvocationExpression node,
    List<String> expected,
  ) {
    var actual = node.typeArgumentTypes!.map((t) => typeString(t)).toList();
    expect(actual, expected);
  }

  void assertTypeDynamic(Object? typeOrExpression) {
    DartType? actual;
    if (typeOrExpression is DartType?) {
      actual = typeOrExpression;
      var type = typeOrExpression;
      expect(type, isDynamicType);
    } else {
      actual = (typeOrExpression as Expression).staticType;
    }
    expect(actual, isDynamicType);
  }

  void assertTypeLegacy(Expression? expression) {
    expression!;
    NullabilitySuffix actual = expression.typeOrThrow.nullabilitySuffix;
    expect(actual, NullabilitySuffix.star);
  }

  void assertTypeLiteral(
      TypeLiteral node, Element? expectedElement, String expectedType,
      {Element? expectedPrefix}) {
    assertType(node, 'Type');
    assertNamedType(node.type, expectedElement, expectedType,
        expectedPrefix: expectedPrefix);
  }

  void assertTypeNull(Expression node) {
    expect(node.staticType, isNull);
  }

  /// TODO(scheglov) Remove `?` from [declaration].
  Matcher elementMatcher(
    Element? declaration, {
    bool isLegacy = false,
    Map<String, String> substitution = const {},
  }) {
    return _ElementMatcher(
      this,
      declaration: declaration!,
      isLegacy: isLegacy,
      substitution: substitution,
    );
  }

  ExpectedError error(ErrorCode code, int offset, int length,
          {Pattern? correctionContains,
          String? text,
          List<Pattern> messageContains = const [],
          List<ExpectedContextMessage> contextMessages =
              const <ExpectedContextMessage>[]}) =>
      ExpectedError(code, offset, length,
          correctionContains: correctionContains,
          message: text,
          messageContains: messageContains,
          expectedContextMessages: contextMessages);

  List<ExpectedError> expectedErrorsByNullability({
    required List<ExpectedError> nullable,
    required List<ExpectedError> legacy,
  }) {
    if (typeToStringWithNullability) {
      return nullable;
    } else {
      return legacy;
    }
  }

  Element? getNodeElement(AstNode node) {
    if (node is Annotation) {
      return node.element;
    } else if (node is AssignmentExpression) {
      return node.staticElement;
    } else if (node is BinaryExpression) {
      return node.staticElement;
    } else if (node is ConstructorReference) {
      return node.constructorName.staticElement;
    } else if (node is Declaration) {
      return node.declaredElement;
    } else if (node is ExtensionOverride) {
      return node.staticElement;
    } else if (node is FormalParameter) {
      return node.declaredElement;
    } else if (node is FunctionExpressionInvocation) {
      return node.staticElement;
    } else if (node is FunctionReference) {
      var function = node.function.unParenthesized;
      if (function is Identifier) {
        return function.staticElement;
      } else if (function is PropertyAccess) {
        return function.propertyName.staticElement;
      } else if (function is ConstructorReference) {
        return function.constructorName.staticElement;
      } else {
        fail('Unsupported node: (${function.runtimeType}) $function');
      }
    } else if (node is Identifier) {
      return node.staticElement;
    } else if (node is ImplicitCallReference) {
      return node.staticElement;
    } else if (node is IndexExpression) {
      return node.staticElement;
    } else if (node is InstanceCreationExpression) {
      return node.constructorName.staticElement;
    } else if (node is MethodInvocation) {
      return node.methodName.staticElement;
    } else if (node is PostfixExpression) {
      return node.staticElement;
    } else if (node is PrefixExpression) {
      return node.staticElement;
    } else if (node is PropertyAccess) {
      return node.propertyName.staticElement;
    } else if (node is NamedType) {
      return node.name.staticElement;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
  }

  ExpectedContextMessage message(String filePath, int offset, int length) =>
      ExpectedContextMessage(convertPath(filePath), offset, length);

  Matcher multiplyDefinedElementMatcher(List<Element> elements) {
    return _MultiplyDefinedElementMatcher(elements);
  }

  Future<ResolvedUnitResult> resolveFile(String path);

  /// Resolve the file with the [path] into [result].
  Future<void> resolveFile2(String path) async {
    path = convertPath(path);

    result = await resolveFile(path);

    findNode = FindNode(result.content, result.unit);
    findElement = FindElement(result.unit);
  }

  /// Create a new file with the [path] and [content], resolve it into [result].
  Future<void> resolveFileCode(String path, String content) {
    newFile(path, content: content);
    return resolveFile2(path);
  }

  /// Put the [code] into the test file, and resolve it.
  Future<void> resolveTestCode(String code) {
    addTestFile(code);
    return resolveTestFile();
  }

  Future<void> resolveTestFile() {
    return resolveFile2(testFilePath);
  }

  /// Choose the type display string, depending on whether the [result] is
  /// non-nullable or legacy.
  String typeStr(String nonNullable, String legacy) {
    if (result.libraryElement.isNonNullableByDefault) {
      return nonNullable;
    } else {
      return legacy;
    }
  }

  /// Return a textual representation of the [type] that is appropriate for
  /// tests.
  String typeString(DartType type) =>
      type.getDisplayString(withNullability: typeToStringWithNullability);

  String typeStringByNullability({
    required String nullable,
    required String legacy,
  }) {
    if (typeToStringWithNullability) {
      return nullable;
    } else {
      return legacy;
    }
  }

  Matcher _elementMatcher(Object? elementOrMatcher) {
    if (elementOrMatcher is Element) {
      return _ElementMatcher(this, declaration: elementOrMatcher);
    } else {
      return wrapMatcher(elementOrMatcher);
    }
  }

  Never _failNotSimpleIdentifier(AstNode node) {
    fail('Expected SimpleIdentifier: (${node.runtimeType}) $node');
  }

  ConstructorElement _getConstructorElement(
      ClassElement classElement, String? constructorName) {
    var constructorElement = constructorName == null
        ? classElement.unnamedConstructor
        : classElement.getNamedConstructor(constructorName);
    return constructorElement ??
        fail("No constructor '${constructorName ?? '<unnamed>'}' in class "
            "'${classElement.name}'.");
  }

  static String _extractReturnType(String invokeType) {
    int functionIndex = invokeType.indexOf(' Function');
    expect(functionIndex, isNonNegative);
    return invokeType.substring(0, functionIndex);
  }
}

class _ElementMatcher extends Matcher {
  final ResolutionTest test;
  final Element declaration;
  final bool isLegacy;
  final Map<String, String> substitution;

  _ElementMatcher(
    this.test, {
    required this.declaration,
    this.isLegacy = false,
    this.substitution = const {},
  });

  @override
  Description describe(Description description) {
    return description
        .add('declaration: $declaration\n')
        .add('isLegacy: $isLegacy\n')
        .add('substitution: $substitution\n');
  }

  @override
  bool matches(element, Map matchState) {
    if (element is Element) {
      if (!identical(element.declaration, declaration)) {
        return false;
      }

      if (element is Member) {
        if (element.isLegacy != isLegacy) {
          return false;
        }

        test.assertSubstitution(element.substitution, substitution);
        return true;
      } else {
        return !isLegacy && substitution.isEmpty;
      }
    }
    return false;
  }
}

class _MultiplyDefinedElementMatcher extends Matcher {
  final Iterable<Element> elements;

  _MultiplyDefinedElementMatcher(this.elements);

  @override
  Description describe(Description description) {
    return description.add('elements: $elements\n');
  }

  @override
  bool matches(element, Map matchState) {
    if (element is MultiplyDefinedElementImpl) {
      var actualSet = element.conflictingElements.toSet();
      actualSet.removeAll(elements);
      return actualSet.isEmpty;
    }
    return false;
  }
}
