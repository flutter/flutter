// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/constant/value.dart';
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
import '../../summary/resolved_ast_printer.dart';
import 'dart_object_printer.dart';
import 'node_text_expectations.dart';

final isDynamicType = TypeMatcher<DynamicTypeImpl>();

final isNeverType = TypeMatcher<NeverTypeImpl>();

final isVoidType = TypeMatcher<VoidTypeImpl>();

/// Base for resolution tests.
mixin ResolutionTest implements ResourceProviderMixin {
  late ResolvedUnitResult result;
  late FindNode findNode;
  late FindElement findElement;

  ClassElement get boolElement => typeProvider.boolElement;

  ClassElement get doubleElement => typeProvider.doubleElement;

  InterfaceType get doubleType => typeProvider.doubleType;

  Element get dynamicElement =>
      (typeProvider.dynamicType as DynamicTypeImpl).element;

  FeatureSet get featureSet => result.libraryElement.featureSet;

  ClassElement get futureElement => typeProvider.futureElement;

  ClassElement get intElement => typeProvider.intElement;

  InterfaceType get intType => typeProvider.intType;

  bool get isLegacyLibrary {
    return !result.libraryElement.isNonNullableByDefault;
  }

  bool get isNullSafetyEnabled => false;

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  NeverElementImpl get neverElement => NeverElementImpl.instance;

  ClassElement get numElement => typeProvider.numElement;

  ClassElement get objectElement =>
      typeProvider.objectType.element as ClassElement;

  InterfaceType get objectType => typeProvider.objectType;

  ClassElement get stringElement => typeProvider.stringElement;

  InterfaceType get stringType => typeProvider.stringType;

  File get testFile;

  TypeProvider get typeProvider => result.typeProvider;

  TypeSystemImpl get typeSystem => result.typeSystem as TypeSystemImpl;

  VoidType get voidType => VoidTypeImpl.instance;

  void addTestFile(String content) {
    newFile(testFile.path, content);
  }

  /// Assert that the given [identifier] is a reference to a class, in the
  /// form that is not a separate expression, e.g. in a static method
  /// invocation like `C.staticMethod()`, or a type annotation `C c = null`.
  void assertClassRef(Expression? identifier, ClassElement expectedElement) {
    identifier as SimpleIdentifier;
    assertElement(identifier, expectedElement);
    assertTypeNull(identifier);
  }

  void assertConstructorElement(ConstructorElement? actual, Object? expected) {
    if (actual is ConstructorMember && expected is ConstructorMember) {
      expect(actual.declaration, same(expected.declaration));
      // TODO(brianwilkerson) Compare the type arguments of the two members.
    } else {
      assertElement(actual, expected);
    }
  }

  void assertConstructors(ClassElement class_, List<String> expected) {
    expect(
      class_.constructors.map((c) {
        return c.getDisplayString(withNullability: false);
      }).toList(),
      unorderedEquals(expected),
    );
  }

  void assertDartObjectText(
    DartObject? object,
    String expected, {
    LibraryElement? libraryElement,
  }) {
    libraryElement ??= result.libraryElement;

    var buffer = StringBuffer();
    DartObjectPrinter(
      sink: buffer,
      selfUriStr: '${libraryElement.source.uri}',
    ).write(object as DartObjectImpl?);
    var actual = buffer.toString();
    if (actual != expected) {
      print(buffer);
    }
    expect(actual, expected);
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
      withNullability: isNullSafetyEnabled,
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
    newFile(path, content);

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

  Future<void> assertNoErrorsInCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    assertErrorsInResolvedUnit(result, const []);
  }

  void assertNoErrorsInResult() {
    assertErrorsInResult(const []);
  }

  void assertParameterElementType(FormalParameter node, String expected) {
    var parameterElement = node.declaredElement!;
    assertType(parameterElement.type, expected);
  }

  void assertParsedNodeText(
    AstNode node,
    String expected, {
    bool skipArgumentList = false,
  }) {
    var actual = _parsedNodeText(
      node,
      skipArgumentList: skipArgumentList,
    );
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void assertPrefixedIdentifier(
    PrefixedIdentifier node, {
    required Object? element,
    required String type,
  }) {
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

  void assertResolvedNodeText(
    AstNode node,
    String expected, {
    bool skipArgumentList = false,
  }) {
    var actual = _resolvedNodeText(
      node,
      skipArgumentList: skipArgumentList,
    );
    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void assertSimpleFormalParameter(
    SimpleFormalParameter node, {
    required ParameterElement element,
  }) {
    assertElement(node.declaredElement, element);
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

  void assertUnresolvedIndexExpression(IndexExpression node) {
    assertElementNull(node);
    assertTypeNull(node);
  }

  void assertUnresolvedPrefixedIdentifier(PrefixedIdentifier node) {
    assertElementNull(node);
    assertTypeNull(node);
    assertUnresolvedSimpleIdentifier(node.identifier);
  }

  /// TODO(scheglov) Remove [disableElementCheck]
  void assertUnresolvedPropertyAccess(
    PropertyAccess node, {
    bool disableElementCheck = false,
  }) {
    if (!disableElementCheck) {
      assertElementNull(node);
    }
    assertTypeNull(node);
    assertUnresolvedSimpleIdentifier(node.propertyName);
  }

  /// TODO(scheglov) Remove [disableElementCheck]
  void assertUnresolvedSimpleIdentifier(
    SimpleIdentifier node, {
    bool disableElementCheck = false,
  }) {
    if (!disableElementCheck) {
      assertElementNull(node);
    }
    assertTypeNull(node);
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
    if (isNullSafetyEnabled) {
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
    newFile(path, content);
    return resolveFile2(path);
  }

  /// Put the [code] into the test file, and resolve it.
  Future<void> resolveTestCode(String code) {
    addTestFile(code);
    return resolveTestFile();
  }

  Future<void> resolveTestFile() {
    return resolveFile2(testFile.path);
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
      type.getDisplayString(withNullability: isNullSafetyEnabled);

  String typeStringByNullability({
    required String nullable,
    required String legacy,
  }) {
    if (isNullSafetyEnabled) {
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

  String _parsedNodeText(
    AstNode node, {
    bool skipArgumentList = false,
  }) {
    var buffer = StringBuffer();
    node.accept(
      ResolvedAstPrinter(
        selfUriStr: '${result.libraryElement.source.uri}',
        sink: buffer,
        indent: '',
        skipArgumentList: skipArgumentList,
        withResolution: false,
      ),
    );
    return buffer.toString();
  }

  String _resolvedNodeText(
    AstNode node, {
    bool skipArgumentList = false,
  }) {
    var buffer = StringBuffer();
    node.accept(
      ResolvedAstPrinter(
        selfUriStr: '${result.libraryElement.source.uri}',
        sink: buffer,
        indent: '',
        skipArgumentList: skipArgumentList,
      ),
    );
    return buffer.toString();
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
