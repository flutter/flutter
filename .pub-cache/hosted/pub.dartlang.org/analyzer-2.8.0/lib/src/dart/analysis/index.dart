// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

Element? declaredParameterElement(
  SimpleIdentifier node,
  Element? element,
) {
  if (element == null || element.enclosingElement != null) {
    return element;
  }

  /// When we instantiate the [FunctionType] of an executable, we use
  /// synthetic [ParameterElement]s, disconnected from the rest of the
  /// element model. But we want to index these parameter references
  /// as references to declared parameters.
  ParameterElement? namedParameterElement(ExecutableElement? executable) {
    if (executable == null) {
      return null;
    }

    var parameterName = node.name;
    return executable.declaration.parameters.where((parameter) {
      return parameter.isNamed && parameter.name == parameterName;
    }).first;
  }

  var parent = node.parent;
  if (parent is Label && parent.label == node) {
    var namedExpression = parent.parent;
    if (namedExpression is NamedExpression && namedExpression.name == parent) {
      var argumentList = namedExpression.parent;
      if (argumentList is ArgumentList) {
        var invocation = argumentList.parent;
        if (invocation is InstanceCreationExpression) {
          var executable = invocation.constructorName.staticElement;
          return namedParameterElement(executable);
        } else if (invocation is MethodInvocation) {
          var executable = invocation.methodName.staticElement;
          if (executable is ExecutableElement) {
            return namedParameterElement(executable);
          }
        }
      }
    }
  }

  return element;
}

/// Return the [CompilationUnitElement] that should be used for [element].
/// Throw [StateError] if the [element] is not linked into a unit.
CompilationUnitElement getUnitElement(Element element) {
  for (Element? e = element; e != null; e = e.enclosingElement) {
    if (e is CompilationUnitElement) {
      return e;
    }
    if (e is LibraryElement) {
      return e.definingCompilationUnit;
    }
  }
  throw StateError('Element not contained in compilation unit: $element');
}

/// Index the [unit] into a new [AnalysisDriverUnitIndexBuilder].
AnalysisDriverUnitIndexBuilder indexUnit(CompilationUnit unit) {
  return _IndexAssembler().assemble(unit);
}

class ElementNameComponents {
  final String? parameterName;
  final String? classMemberName;
  final String? unitMemberName;

  factory ElementNameComponents(Element element) {
    String? parameterName;
    if (element is ParameterElement) {
      parameterName = element.name;
      element = element.enclosingElement!;
    }

    String? classMemberName;
    if (element.enclosingElement is ClassElement ||
        element.enclosingElement is ExtensionElement) {
      classMemberName = element.name;
      element = element.enclosingElement!;
    }

    String? unitMemberName;
    if (element.enclosingElement is CompilationUnitElement) {
      unitMemberName = element.name;
      if (element is ExtensionElement && unitMemberName == null) {
        var enclosingUnit = element.enclosingElement;
        var indexOf = enclosingUnit.extensions.indexOf(element);
        unitMemberName = 'extension-$indexOf';
      }
    }

    return ElementNameComponents._(
      parameterName: parameterName,
      classMemberName: classMemberName,
      unitMemberName: unitMemberName,
    );
  }

  ElementNameComponents._({
    @required this.parameterName,
    @required this.classMemberName,
    @required this.unitMemberName,
  });
}

/// Information about an element that is actually put into index for some other
/// related element. For example for a synthetic getter this is the
/// corresponding non-synthetic field and [IndexSyntheticElementKind.getter] as
/// the [kind].
class IndexElementInfo {
  final Element element;
  final IndexSyntheticElementKind kind;

  factory IndexElementInfo(Element element) {
    IndexSyntheticElementKind kind = IndexSyntheticElementKind.notSynthetic;
    ElementKind elementKind = element.kind;
    if (elementKind == ElementKind.LIBRARY ||
        elementKind == ElementKind.COMPILATION_UNIT) {
      kind = IndexSyntheticElementKind.unit;
    } else if (element.isSynthetic) {
      if (elementKind == ElementKind.CONSTRUCTOR) {
        kind = IndexSyntheticElementKind.constructor;
        element = element.enclosingElement!;
      } else if (element is FunctionElement &&
          element.name == FunctionElement.LOAD_LIBRARY_NAME) {
        kind = IndexSyntheticElementKind.loadLibrary;
        element = element.library;
      } else if (elementKind == ElementKind.FIELD) {
        var field = element as FieldElement;
        kind = IndexSyntheticElementKind.field;
        element = (field.getter ?? field.setter)!;
      } else if (elementKind == ElementKind.GETTER ||
          elementKind == ElementKind.SETTER) {
        var accessor = element as PropertyAccessorElement;
        Element enclosing = element.enclosingElement;
        bool isEnumGetter = enclosing is ClassElement && enclosing.isEnum;
        if (isEnumGetter && accessor.name == 'index') {
          kind = IndexSyntheticElementKind.enumIndex;
          element = enclosing;
        } else if (isEnumGetter && accessor.name == 'values') {
          kind = IndexSyntheticElementKind.enumValues;
          element = enclosing;
        } else {
          kind = accessor.isGetter
              ? IndexSyntheticElementKind.getter
              : IndexSyntheticElementKind.setter;
          element = accessor.variable;
        }
      } else if (element is MethodElement) {
        Element enclosing = element.enclosingElement;
        bool isEnumMethod = enclosing is ClassElement && enclosing.isEnum;
        if (isEnumMethod && element.name == 'toString') {
          kind = IndexSyntheticElementKind.enumToString;
          element = enclosing;
        }
      } else if (element is TopLevelVariableElement) {
        kind = IndexSyntheticElementKind.topLevelVariable;
        element = (element.getter ?? element.setter)!;
      } else {
        throw ArgumentError(
            'Unsupported synthetic element ${element.runtimeType}');
      }
    }
    return IndexElementInfo._(element, kind);
  }

  IndexElementInfo._(this.element, this.kind);
}

/// Information about an element referenced in index.
class _ElementInfo {
  /// The identifier of the [CompilationUnitElement] containing this element.
  final int unitId;

  /// The identifier of the top-level name, or `null` if the element is a
  /// reference to the unit.
  final _StringInfo nameIdUnitMember;

  /// The identifier of the class member name, or `null` if the element is not a
  /// class member or a named parameter of a class member.
  final _StringInfo nameIdClassMember;

  /// The identifier of the named parameter name, or `null` if the element is
  /// not a named parameter.
  final _StringInfo nameIdParameter;

  /// The kind of the element.
  final IndexSyntheticElementKind kind;

  /// The unique id of the element.  It is set after indexing of the whole
  /// package is done and we are assembling the full package index.
  late int id;

  _ElementInfo(this.unitId, this.nameIdUnitMember, this.nameIdClassMember,
      this.nameIdParameter, this.kind);
}

/// Information about a single relation in a single compilation unit.
class _ElementRelationInfo {
  final _ElementInfo elementInfo;
  final IndexRelationKind kind;
  final int offset;
  final int length;
  final bool isQualified;

  _ElementRelationInfo(
      this.elementInfo, this.kind, this.offset, this.length, this.isQualified);
}

/// Assembler of a single [CompilationUnit] index.
///
/// The intended usage sequence:
///
///  - Call [addElementRelation] for each element relation found in the unit.
///  - Call [addNameRelation] for each name relation found in the unit.
///  - Assign ids to all the [_ElementInfo] in [elementRelations].
///  - Call [assemble] to produce the final unit index.
class _IndexAssembler {
  /// The string to use in place of the `null` string.
  static const NULL_STRING = '--nullString--';

  /// Map associating referenced elements with their [_ElementInfo]s.
  final Map<Element, _ElementInfo> elementMap = {};

  /// Map associating [CompilationUnitElement]s with their identifiers, which
  /// are indices into [unitLibraryUris] and [unitUnitUris].
  final Map<CompilationUnitElement, int> unitMap = {};

  /// The fields [unitLibraryUris] and [unitUnitUris] are used together to
  /// describe each unique [CompilationUnitElement].
  ///
  /// This field contains the library URI of a unit.
  final List<_StringInfo> unitLibraryUris = [];

  /// The fields [unitLibraryUris] and [unitUnitUris] are used together to
  /// describe each unique [CompilationUnitElement].
  ///
  /// This field contains the unit URI of a unit, which might be the same as
  /// the library URI for the defining unit, or a different one for a part.
  final List<_StringInfo> unitUnitUris = [];

  /// Map associating strings with their [_StringInfo]s.
  final Map<String, _StringInfo> stringMap = {};

  /// All element relations.
  final List<_ElementRelationInfo> elementRelations = [];

  /// All unresolved name relations.
  final List<_NameRelationInfo> nameRelations = [];

  /// All subtypes declared in the unit.
  final List<_SubtypeInfo> subtypes = [];

  /// The [_StringInfo] to use for `null` strings.
  late final _StringInfo nullString;

  _IndexAssembler() {
    nullString = _getStringInfo(NULL_STRING);
  }

  void addElementRelation(Element element, IndexRelationKind kind, int offset,
      int length, bool isQualified) {
    _ElementInfo elementInfo = _getElementInfo(element);
    elementRelations.add(
        _ElementRelationInfo(elementInfo, kind, offset, length, isQualified));
  }

  void addNameRelation(
      String name, IndexRelationKind kind, int offset, bool isQualified) {
    _StringInfo nameId = _getStringInfo(name);
    nameRelations.add(_NameRelationInfo(nameId, kind, offset, isQualified));
  }

  void addSubtype(String name, List<String> members, List<String> supertypes) {
    for (var supertype in supertypes) {
      subtypes.add(
        _SubtypeInfo(
          _getStringInfo(supertype),
          _getStringInfo(name),
          members.map(_getStringInfo).toList(),
        ),
      );
    }
  }

  /// Index the [unit] and assemble a new [AnalysisDriverUnitIndexBuilder].
  AnalysisDriverUnitIndexBuilder assemble(CompilationUnit unit) {
    unit.accept(_IndexContributor(this));

    // Sort strings and set IDs.
    List<_StringInfo> stringInfoList = stringMap.values.toList();
    stringInfoList.sort((a, b) {
      return a.value.compareTo(b.value);
    });
    for (int i = 0; i < stringInfoList.length; i++) {
      stringInfoList[i].id = i;
    }

    // Sort elements and set IDs.
    List<_ElementInfo> elementInfoList = elementMap.values.toList();
    elementInfoList.sort((a, b) {
      int delta;
      delta = a.nameIdUnitMember.id - b.nameIdUnitMember.id;
      if (delta != 0) {
        return delta;
      }
      delta = a.nameIdClassMember.id - b.nameIdClassMember.id;
      if (delta != 0) {
        return delta;
      }
      return a.nameIdParameter.id - b.nameIdParameter.id;
    });
    for (int i = 0; i < elementInfoList.length; i++) {
      elementInfoList[i].id = i;
    }

    // Sort element and name relations.
    elementRelations.sort((a, b) {
      return a.elementInfo.id - b.elementInfo.id;
    });
    nameRelations.sort((a, b) {
      return a.nameInfo.id - b.nameInfo.id;
    });

    // Sort subtypes by supertypes.
    subtypes.sort((a, b) {
      return a.supertype.id - b.supertype.id;
    });

    return AnalysisDriverUnitIndexBuilder(
        strings: stringInfoList.map((s) => s.value).toList(),
        nullStringId: nullString.id,
        unitLibraryUris: unitLibraryUris.map((s) => s.id).toList(),
        unitUnitUris: unitUnitUris.map((s) => s.id).toList(),
        elementKinds: elementInfoList.map((e) => e.kind).toList(),
        elementUnits: elementInfoList.map((e) => e.unitId).toList(),
        elementNameUnitMemberIds:
            elementInfoList.map((e) => e.nameIdUnitMember.id).toList(),
        elementNameClassMemberIds:
            elementInfoList.map((e) => e.nameIdClassMember.id).toList(),
        elementNameParameterIds:
            elementInfoList.map((e) => e.nameIdParameter.id).toList(),
        usedElements: elementRelations.map((r) => r.elementInfo.id).toList(),
        usedElementKinds: elementRelations.map((r) => r.kind).toList(),
        usedElementOffsets: elementRelations.map((r) => r.offset).toList(),
        usedElementLengths: elementRelations.map((r) => r.length).toList(),
        usedElementIsQualifiedFlags:
            elementRelations.map((r) => r.isQualified).toList(),
        usedNames: nameRelations.map((r) => r.nameInfo.id).toList(),
        usedNameKinds: nameRelations.map((r) => r.kind).toList(),
        usedNameOffsets: nameRelations.map((r) => r.offset).toList(),
        usedNameIsQualifiedFlags:
            nameRelations.map((r) => r.isQualified).toList(),
        supertypes: subtypes.map((subtype) => subtype.supertype.id).toList(),
        subtypes: subtypes.map((subtype) {
          return AnalysisDriverSubtypeBuilder(
            name: subtype.name.id,
            members: subtype.members.map((member) => member.id).toList(),
          );
        }).toList());
  }

  /// Return the unique [_ElementInfo] corresponding the [element].  The field
  /// [_ElementInfo.id] is filled by [assemble] during final sorting.
  _ElementInfo _getElementInfo(Element element) {
    element = element.declaration!;
    return elementMap.putIfAbsent(element, () {
      CompilationUnitElement unitElement = getUnitElement(element);
      int unitId = _getUnitId(unitElement);
      return _newElementInfo(unitId, element);
    });
  }

  /// Return the unique [_StringInfo] corresponding the given [string].  The
  /// field [_StringInfo.id] is filled by [assemble] during final sorting.
  _StringInfo _getStringInfo(String? string) {
    if (string == null) {
      return nullString;
    }

    return stringMap.putIfAbsent(string, () {
      return _StringInfo(string);
    });
  }

  /// Add information about [unitElement] to [unitUnitUris] and
  /// [unitLibraryUris] if necessary, and return the location in those
  /// arrays representing [unitElement].
  int _getUnitId(CompilationUnitElement unitElement) {
    return unitMap.putIfAbsent(unitElement, () {
      assert(unitLibraryUris.length == unitUnitUris.length);
      int id = unitUnitUris.length;
      unitLibraryUris.add(_getUriInfo(unitElement.library.source.uri));
      unitUnitUris.add(_getUriInfo(unitElement.source.uri));
      return id;
    });
  }

  /// Return the unique [_StringInfo] corresponding [uri].  The field
  /// [_StringInfo.id] is filled by [assemble] during final sorting.
  _StringInfo _getUriInfo(Uri uri) {
    String str = uri.toString();
    return _getStringInfo(str);
  }

  /// Return a new [_ElementInfo] for the given [element] in the given [unitId].
  /// This method is static, so it cannot add any information to the index.
  _ElementInfo _newElementInfo(int unitId, Element element) {
    IndexElementInfo info = IndexElementInfo(element);
    element = info.element;

    var components = ElementNameComponents(element);
    return _ElementInfo(
      unitId,
      _getStringInfo(components.unitMemberName),
      _getStringInfo(components.classMemberName),
      _getStringInfo(components.parameterName),
      info.kind,
    );
  }
}

/// Visits a resolved AST and adds relationships into the [assembler].
class _IndexContributor extends GeneralizingAstVisitor {
  final _IndexAssembler assembler;

  _IndexContributor(this.assembler);

  void recordIsAncestorOf(ClassElement descendant) {
    _recordIsAncestorOf(descendant, descendant, false, <ClassElement>[]);
  }

  /// Record that the name [node] has a relation of the given [kind].
  void recordNameRelation(
      SimpleIdentifier node, IndexRelationKind kind, bool isQualified) {
    assembler.addNameRelation(node.name, kind, node.offset, isQualified);
  }

  /// Record reference to the given operator [Element].
  void recordOperatorReference(Token operator, Element? element) {
    recordRelationToken(element, IndexRelationKind.IS_INVOKED_BY, operator);
  }

  /// Record that [element] has a relation of the given [kind] at the location
  /// of the given [node].  The flag [isQualified] is `true` if [node] has an
  /// explicit or implicit qualifier, so cannot be shadowed by a local
  /// declaration.
  void recordRelation(Element? element, IndexRelationKind kind, AstNode node,
      bool isQualified) {
    if (element != null) {
      recordRelationOffset(
          element, kind, node.offset, node.length, isQualified);
    }
  }

  /// Record that [element] has a relation of the given [kind] at the given
  /// [offset] and [length].  The flag [isQualified] is `true` if the relation
  /// has an explicit or implicit qualifier, so [element] cannot be shadowed by
  /// a local declaration.
  void recordRelationOffset(Element? element, IndexRelationKind kind,
      int offset, int length, bool isQualified) {
    if (element == null) return;

    // Ignore elements that can't be referenced outside of the unit.
    ElementKind elementKind = element.kind;
    if (elementKind == ElementKind.DYNAMIC ||
        elementKind == ElementKind.ERROR ||
        elementKind == ElementKind.LABEL ||
        elementKind == ElementKind.LOCAL_VARIABLE ||
        elementKind == ElementKind.NEVER ||
        elementKind == ElementKind.PREFIX ||
        elementKind == ElementKind.TYPE_PARAMETER ||
        elementKind == ElementKind.FUNCTION &&
            element is FunctionElement &&
            element.enclosingElement is ExecutableElement ||
        false) {
      return;
    }
    // Ignore named parameters of synthetic functions, e.g. created for LUB.
    // These functions are not bound to a source, we cannot index them.
    if (elementKind == ElementKind.PARAMETER && element is ParameterElement) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement == null || enclosingElement.isSynthetic) {
        return;
      }
    }
    // Elements for generic function types are enclosed by the compilation
    // units, but don't have names. So, we cannot index references to their
    // named parameters. Ignore them.
    if (elementKind == ElementKind.PARAMETER &&
        element is ParameterElement &&
        element.enclosingElement is GenericFunctionTypeElement) {
      return;
    }
    // Add the relation.
    assembler.addElementRelation(element, kind, offset, length, isQualified);
  }

  /// Record that [element] has a relation of the given [kind] at the location
  /// of the given [token].
  void recordRelationToken(
      Element? element, IndexRelationKind kind, Token token) {
    recordRelationOffset(element, kind, token.offset, token.length, true);
  }

  /// Record a relation between a super [namedType] and its [Element].
  void recordSuperType(NamedType namedType, IndexRelationKind kind) {
    Identifier name = namedType.name;
    Element? element = name.staticElement;
    bool isQualified;
    SimpleIdentifier relNode;
    if (name is PrefixedIdentifier) {
      isQualified = true;
      relNode = name.identifier;
    } else {
      isQualified = false;
      relNode = name as SimpleIdentifier;
    }
    recordRelation(element, kind, relNode, isQualified);
    recordRelation(
        element, IndexRelationKind.IS_REFERENCED_BY, relNode, isQualified);
    namedType.typeArguments?.accept(this);
  }

  void recordUriReference(Element? element, StringLiteral uri) {
    recordRelation(element, IndexRelationKind.IS_REFERENCED_BY, uri, true);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    recordOperatorReference(node.operator, node.staticElement);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    recordOperatorReference(node.operator, node.staticElement);
    super.visitBinaryExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _addSubtypeForClassDeclaration(node);
    var declaredElement = node.declaredElement!;
    if (node.extendsClause == null) {
      ClassElement? objectElement = declaredElement.supertype?.element;
      recordRelationOffset(objectElement, IndexRelationKind.IS_EXTENDED_BY,
          node.name.offset, 0, true);
    }
    recordIsAncestorOf(declaredElement);
    super.visitClassDeclaration(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _addSubtypeForClassTypeAlis(node);
    recordIsAncestorOf(node.declaredElement!);
    super.visitClassTypeAlias(node);
  }

  @override
  visitCommentReference(CommentReference node) {
    var expression = node.expression;
    if (expression is Identifier) {
      var element = expression.staticElement;
      if (element is ConstructorElement) {
        if (expression is PrefixedIdentifier) {
          var offset = expression.prefix.end;
          var length = expression.end - offset;
          recordRelationOffset(element, IndexRelationKind.IS_REFERENCED_BY,
              offset, length, true);
          return;
        } else {
          var offset = expression.end;
          recordRelationOffset(
              element, IndexRelationKind.IS_REFERENCED_BY, offset, 0, true);
          return;
        }
      }
    } else {
      throw UnimplementedError('Unhandled CommentReference expression type: '
          '${expression.runtimeType}');
    }

    return super.visitCommentReference(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var fieldName = node.fieldName;
    var element = fieldName.staticElement;
    recordRelation(element, IndexRelationKind.IS_WRITTEN_BY, fieldName, true);
    node.expression.accept(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    var element = node.staticElement?.declaration;
    element = _getActualConstructorElement(element);

    IndexRelationKind kind;
    if (node.parent is ConstructorReference) {
      kind = IndexRelationKind.IS_REFERENCED_BY_CONSTRUCTOR_TEAR_OFF;
    } else if (node.parent is InstanceCreationExpression) {
      kind = IndexRelationKind.IS_INVOKED_BY;
    } else {
      kind = IndexRelationKind.IS_REFERENCED_BY;
    }

    int offset;
    int length;
    if (node.name != null) {
      offset = node.period!.offset;
      length = node.name!.end - offset;
    } else {
      offset = node.type2.end;
      length = 0;
    }

    recordRelationOffset(element, kind, offset, length, true);

    node.type2.accept(this);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    ExportElement? element = node.element;
    recordUriReference(element?.exportedLibrary, node.uri);
    super.visitExportDirective(node);
  }

  @override
  void visitExpression(Expression node) {
    ParameterElement? parameterElement = node.staticParameterElement;
    if (parameterElement != null && parameterElement.isOptionalPositional) {
      recordRelationOffset(parameterElement, IndexRelationKind.IS_REFERENCED_BY,
          node.offset, 0, true);
    }
    super.visitExpression(node);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    recordSuperType(node.superclass2, IndexRelationKind.IS_EXTENDED_BY);
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    for (NamedType namedType in node.interfaces2) {
      recordSuperType(namedType, IndexRelationKind.IS_IMPLEMENTED_BY);
    }
  }

  @override
  void visitImportDirective(ImportDirective node) {
    ImportElement? element = node.element;
    recordUriReference(element?.importedLibrary, node.uri);
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    Element? element = node.writeOrReadElement;
    if (element is MethodElement) {
      Token operator = node.leftBracket;
      recordRelationToken(element, IndexRelationKind.IS_INVOKED_BY, operator);
    }
    super.visitIndexExpression(node);
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {}

  @override
  void visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier name = node.methodName;
    Element? element = name.staticElement;
    // unresolved name invocation
    bool isQualified = node.realTarget != null;
    if (element == null) {
      recordNameRelation(name, IndexRelationKind.IS_INVOKED_BY, isQualified);
    }
    // element invocation
    IndexRelationKind kind = element is ClassElement
        ? IndexRelationKind.IS_REFERENCED_BY
        : IndexRelationKind.IS_INVOKED_BY;
    recordRelation(element, kind, name, isQualified);
    node.target?.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _addSubtypeForMixinDeclaration(node);
    recordIsAncestorOf(node.declaredElement!);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    AstNode parent = node.parent!;
    if (parent is ClassTypeAlias && parent.superclass2 == node) {
      recordSuperType(node, IndexRelationKind.IS_EXTENDED_BY);
    } else {
      super.visitNamedType(node);
    }
  }

  @override
  void visitOnClause(OnClause node) {
    for (NamedType namedType in node.superclassConstraints2) {
      recordSuperType(namedType, IndexRelationKind.IS_IMPLEMENTED_BY);
    }
  }

  @override
  void visitPartDirective(PartDirective node) {
    var element = node.element as CompilationUnitElement?;
    if (element?.source != null) {
      recordUriReference(element, node.uri);
    }
    super.visitPartDirective(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    recordOperatorReference(node.operator, node.staticElement);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    recordOperatorReference(node.operator, node.staticElement);
    super.visitPrefixExpression(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var element = node.staticElement;
    if (node.constructorName != null) {
      int offset = node.period!.offset;
      int length = node.constructorName!.end - offset;
      recordRelationOffset(
          element, IndexRelationKind.IS_INVOKED_BY, offset, length, true);
    } else {
      int offset = node.thisKeyword.end;
      recordRelationOffset(
          element, IndexRelationKind.IS_INVOKED_BY, offset, 0, true);
    }
    node.argumentList.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // name in declaration
    if (node.inDeclarationContext()) {
      return;
    }

    Element? element = node.writeOrReadElement;
    if (element is ParameterElement) {
      element = declaredParameterElement(node, element);
    }

    // record unresolved name reference
    bool isQualified = _isQualified(node);
    if (element == null) {
      bool inGetterContext = node.inGetterContext();
      bool inSetterContext = node.inSetterContext();
      IndexRelationKind kind;
      if (inGetterContext && inSetterContext) {
        kind = IndexRelationKind.IS_READ_WRITTEN_BY;
      } else if (inGetterContext) {
        kind = IndexRelationKind.IS_READ_BY;
      } else {
        kind = IndexRelationKind.IS_WRITTEN_BY;
      }
      recordNameRelation(node, kind, isQualified);
    }
    // this.field parameter
    if (element is FieldFormalParameterElement) {
      AstNode parent = node.parent!;
      IndexRelationKind kind =
          parent is FieldFormalParameter && parent.identifier == node
              ? IndexRelationKind.IS_WRITTEN_BY
              : IndexRelationKind.IS_REFERENCED_BY;
      recordRelation(element.field, kind, node, true);
      return;
    }
    // ignore a local reference to a parameter
    if (element is ParameterElement && node.parent is! Label) {
      return;
    }
    // record specific relations
    recordRelation(
        element, IndexRelationKind.IS_REFERENCED_BY, node, isQualified);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var element = node.staticElement;
    if (node.constructorName != null) {
      int offset = node.period!.offset;
      int length = node.constructorName!.end - offset;
      recordRelationOffset(
          element, IndexRelationKind.IS_INVOKED_BY, offset, length, true);
    } else {
      int offset = node.superKeyword.end;
      recordRelationOffset(
          element, IndexRelationKind.IS_INVOKED_BY, offset, 0, true);
    }
    node.argumentList.accept(this);
  }

  @override
  void visitWithClause(WithClause node) {
    for (NamedType namedType in node.mixinTypes2) {
      recordSuperType(namedType, IndexRelationKind.IS_MIXED_IN_BY);
    }
  }

  /// Record the given class as a subclass of its direct superclasses.
  void _addSubtype(String name,
      {NamedType? superclass,
      WithClause? withClause,
      OnClause? onClause,
      ImplementsClause? implementsClause,
      required List<ClassMember> memberNodes}) {
    List<String> supertypes = [];
    List<String> members = [];

    String getClassElementId(ClassElement element) {
      return element.library.source.uri.toString() +
          ';' +
          element.source.uri.toString() +
          ';' +
          element.name;
    }

    void addSupertype(NamedType? type) {
      var element = type?.name.staticElement;
      if (element is ClassElement) {
        String id = getClassElementId(element);
        supertypes.add(id);
      }
    }

    addSupertype(superclass);
    withClause?.mixinTypes2.forEach(addSupertype);
    onClause?.superclassConstraints2.forEach(addSupertype);
    implementsClause?.interfaces2.forEach(addSupertype);

    void addMemberName(SimpleIdentifier identifier) {
      String name = identifier.name;
      if (name.isNotEmpty) {
        members.add(name);
      }
    }

    for (ClassMember member in memberNodes) {
      if (member is MethodDeclaration && !member.isStatic) {
        addMemberName(member.name);
      } else if (member is FieldDeclaration && !member.isStatic) {
        for (var field in member.fields.variables) {
          addMemberName(field.name);
        }
      }
    }

    supertypes.sort();
    members.sort();

    assembler.addSubtype(name, members, supertypes);
  }

  /// Record the given class as a subclass of its direct superclasses.
  void _addSubtypeForClassDeclaration(ClassDeclaration node) {
    _addSubtype(node.name.name,
        superclass: node.extendsClause?.superclass2,
        withClause: node.withClause,
        implementsClause: node.implementsClause,
        memberNodes: node.members);
  }

  /// Record the given class as a subclass of its direct superclasses.
  void _addSubtypeForClassTypeAlis(ClassTypeAlias node) {
    _addSubtype(node.name.name,
        superclass: node.superclass2,
        withClause: node.withClause,
        implementsClause: node.implementsClause,
        memberNodes: const []);
  }

  /// Record the given mixin as a subclass of its direct superclasses.
  void _addSubtypeForMixinDeclaration(MixinDeclaration node) {
    _addSubtype(node.name.name,
        onClause: node.onClause,
        implementsClause: node.implementsClause,
        memberNodes: node.members);
  }

  /// If the given [constructor] is a synthetic constructor created for a
  /// [ClassTypeAlias], return the actual constructor of a [ClassDeclaration]
  /// which is invoked.  Return `null` if a redirection cycle is detected.
  ConstructorElement? _getActualConstructorElement(
      ConstructorElement? constructor) {
    var seenConstructors = <ConstructorElement?>{};
    while (constructor is ConstructorElementImpl && constructor.isSynthetic) {
      var enclosing = constructor.enclosingElement;
      if (enclosing.isMixinApplication) {
        var superInvocation = constructor.constantInitializers
            .whereType<SuperConstructorInvocation>()
            .singleOrNull;
        if (superInvocation != null) {
          constructor = superInvocation.staticElement;
        }
      } else {
        break;
      }
      // fail if a cycle is detected
      if (!seenConstructors.add(constructor)) {
        return null;
      }
    }
    return constructor;
  }

  /// Return `true` if [node] has an explicit or implicit qualifier, so that it
  /// cannot be shadowed by a local declaration.
  bool _isQualified(SimpleIdentifier node) {
    if (node.isQualified) {
      return true;
    }
    AstNode parent = node.parent!;
    return parent is Combinator || parent is Label;
  }

  void _recordIsAncestorOf(Element descendant, ClassElement ancestor,
      bool includeThis, List<ClassElement> visitedElements) {
    if (visitedElements.contains(ancestor)) {
      return;
    }
    visitedElements.add(ancestor);
    if (includeThis) {
      int offset = descendant.nameOffset;
      int length = descendant.nameLength;
      assembler.addElementRelation(
          ancestor, IndexRelationKind.IS_ANCESTOR_OF, offset, length, false);
    }
    {
      var superType = ancestor.supertype;
      if (superType != null) {
        _recordIsAncestorOf(
            descendant, superType.element, true, visitedElements);
      }
    }
    for (InterfaceType mixinType in ancestor.mixins) {
      _recordIsAncestorOf(descendant, mixinType.element, true, visitedElements);
    }
    for (InterfaceType type in ancestor.superclassConstraints) {
      _recordIsAncestorOf(descendant, type.element, true, visitedElements);
    }
    for (InterfaceType implementedType in ancestor.interfaces) {
      _recordIsAncestorOf(
          descendant, implementedType.element, true, visitedElements);
    }
  }
}

/// Information about a single name relation in single compilation unit.
class _NameRelationInfo {
  final _StringInfo nameInfo;
  final IndexRelationKind kind;
  final int offset;
  final bool isQualified;

  _NameRelationInfo(this.nameInfo, this.kind, this.offset, this.isQualified);
}

/// Information about a string referenced in the index.
class _StringInfo {
  /// The value of the string.
  final String value;

  /// The unique id of the string.  It is set after indexing of the whole
  /// package is done and we are assembling the full package index.
  late int id;

  _StringInfo(this.value);
}

/// Information about a subtype in the index.
class _SubtypeInfo {
  /// The identifier of a direct supertype.
  final _StringInfo supertype;

  /// The name of the class.
  final _StringInfo name;

  /// The names of defined instance members.
  final List<_StringInfo> members;

  _SubtypeInfo(this.supertype, this.name, this.members);
}
