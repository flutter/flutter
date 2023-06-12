// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer/src/util/uri.dart';
import 'package:collection/collection.dart';

class ElementBuilder extends ThrowingAstVisitor<void> {
  final LibraryBuilder _libraryBuilder;
  final CompilationUnitElementImpl _unitElement;

  final _exports = <ExportElement>[];
  final _imports = <ImportElement>[];
  var _isFirstLibraryDirective = true;
  var _hasCoreImport = false;
  var _partDirectiveIndex = 0;

  _EnclosingContext _enclosingContext;
  var _nextUnnamedExtensionId = 0;

  ElementBuilder({
    required LibraryBuilder libraryBuilder,
    required Reference unitReference,
    required CompilationUnitElementImpl unitElement,
  })  : _libraryBuilder = libraryBuilder,
        _unitElement = unitElement,
        _enclosingContext = _EnclosingContext(unitReference, unitElement);

  LibraryElementImpl get _libraryElement => _libraryBuilder.element;

  Linker get _linker => _libraryBuilder.linker;

  void buildDeclarationElements(CompilationUnit unit) {
    _visitPropertyFirst<TopLevelVariableDeclaration>(unit.declarations);
    _unitElement.accessors = _enclosingContext.propertyAccessors;
    _unitElement.classes = _enclosingContext.classes;
    _unitElement.enums = _enclosingContext.enums;
    _unitElement.extensions = _enclosingContext.extensions;
    _unitElement.functions = _enclosingContext.functions;
    _unitElement.mixins = _enclosingContext.mixins;
    _unitElement.topLevelVariables = _enclosingContext.properties
        .whereType<TopLevelVariableElementImpl>()
        .toList();
    _unitElement.typeAliases = _enclosingContext.typeAliases;
  }

  /// Build exports and imports, metadata into [_libraryElement].
  void buildLibraryElementChildren(CompilationUnit unit) {
    unit.directives.accept(this);

    _libraryElement.exports = _exports;

    if (!_hasCoreImport) {
      var dartCore = _linker.elementFactory.libraryOfUri2('dart:core');
      _imports.add(
        ImportElementImpl(-1)
          ..importedLibrary = dartCore
          ..isSynthetic = true
          ..uri = 'dart:core',
      );
    }
    _libraryElement.imports = _imports;

    if (_isFirstLibraryDirective) {
      _isFirstLibraryDirective = false;
      var firstDirective = unit.directives.firstOrNull;
      if (firstDirective != null) {
        _libraryElement.documentationComment = getCommentNodeRawText(
          firstDirective.documentationComment,
        );
        var firstDirectiveMetadata = firstDirective.element?.metadata;
        if (firstDirectiveMetadata != null) {
          _libraryElement.metadata = firstDirectiveMetadata;
        }
      }
    }
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;

    var element = ClassElementImpl(name, nameNode.offset);
    element.isAbstract = node.isAbstract;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addClass(name, element);
    _libraryBuilder.localScope.declare(name, reference);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    node.extendsClause?.accept(this);
    node.withClause?.accept(this);
    node.implementsClause?.accept(this);
    _buildClassOrMixin(node);
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;

    var element = ClassElementImpl(name, nameNode.offset);
    element.isAbstract = node.isAbstract;
    element.isMixinApplication = true;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addClass(name, element);
    _libraryBuilder.localScope.declare(name, reference);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    node.superclass2.accept(this);
    node.withClause.accept(this);
    node.implementsClause?.accept(this);
  }

  @override
  void visitConstructorDeclaration(
    covariant ConstructorDeclarationImpl node,
  ) {
    var nameNode = node.name ?? node.returnType;
    var name = node.name?.name ?? '';
    if (name == 'new') {
      // A constructor declared as `C.new` is unnamed, and is modeled as such.
      name = '';
    }
    var nameOffset = nameNode.offset;

    var element = ConstructorElementImpl(name, nameOffset);
    element.isConst = node.constKeyword != null;
    element.isExternal = node.externalKeyword != null;
    element.isFactory = node.factoryKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    element.nameEnd = nameNode.end;
    element.periodOffset = node.period?.offset;
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    if (element.isConst || element.isFactory) {
      element.constantInitializers = node.initializers;
    }

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addConstructor(name, element);
    _buildExecutableElementChildren(
      reference: reference,
      element: element,
      formalParameters: node.parameters,
    );
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitEnumDeclaration(covariant EnumDeclarationImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;
    var nameOffset = nameNode.offset;

    var element = EnumElementImpl(name, nameOffset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addEnum(name, element);
    _libraryBuilder.localScope.declare(name, reference);
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var element = ExportElementImpl(node.keyword.offset);
    element.combinators = _buildCombinators(node.combinators);
    element.exportedLibrary = _selectLibrary(node);
    element.metadata = _buildAnnotations(node.metadata);
    element.uri = node.uri.stringValue;

    node.element = element;
    _exports.add(element);
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    node.superclass2.accept(this);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var nodeName = node.name;
    var name = nodeName?.name;
    var nameOffset = nodeName?.offset ?? -1;

    var element = ExtensionElementImpl(name, nameOffset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var refName = name ?? 'extension-${_nextUnnamedExtensionId++}';
    var reference = _enclosingContext.addExtension(refName, element);

    if (name != null) {
      _libraryBuilder.localScope.declare(name, reference);
    }

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    {
      var holder = _buildClassMembers(element, node.members);
      element.accessors = holder.propertyAccessors;
      element.fields = holder.properties.whereType<FieldElement>().toList();
      element.methods = holder.methods;
    }

    node.extendedType.accept(this);
  }

  @override
  void visitFieldDeclaration(
    covariant FieldDeclarationImpl node,
  ) {
    var enclosingRef = _enclosingContext.reference;

    var metadata = _buildAnnotations(node.metadata);
    for (var variable in node.fields.variables) {
      var nameNode = variable.name as SimpleIdentifierImpl;
      var name = nameNode.name;
      var nameOffset = nameNode.offset;

      FieldElementImpl element;
      if (_shouldBeConstField(node)) {
        element = ConstFieldElementImpl(name, nameOffset)
          ..constantInitializer = variable.initializer;
      } else {
        element = FieldElementImpl(name, nameOffset);
      }

      element.hasInitializer = variable.initializer != null;
      element.isAbstract = node.abstractKeyword != null;
      element.isConst = node.fields.isConst;
      element.isCovariant = node.covariantKeyword != null;
      element.isExternal = node.externalKeyword != null;
      element.isFinal = node.fields.isFinal;
      element.isLate = node.fields.isLate;
      element.isStatic = node.isStatic;
      element.metadata = metadata;
      _setCodeRange(element, variable);
      _setDocumentation(element, node);

      if (node.fields.type == null) {
        element.hasImplicitType = true;
        element.type = DynamicTypeImpl.instance;
      }

      element.createImplicitAccessors(enclosingRef, name);

      _linker.elementNodes[element] = variable;
      _enclosingContext.addField(name, element);
      nameNode.staticElement = element;

      var getter = element.getter;
      if (getter is PropertyAccessorElementImpl) {
        _enclosingContext.addGetter(name, getter);
      }

      var setter = element.setter;
      if (setter is PropertyAccessorElementImpl) {
        _enclosingContext.addSetter(name, setter);
      }
    }
    _buildType(node.fields.type);
  }

  @override
  void visitFieldFormalParameter(
    covariant FieldFormalParameterImpl node,
  ) {
    var nameNode = node.identifier;
    var name = nameNode.name;
    var nameOffset = nameNode.offset;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameter) {
      element = DefaultFieldFormalParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
      _enclosingContext.addParameter(name, element);
    } else {
      element = FieldFormalParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      );
      _linker.elementNodes[element] = node;
      _enclosingContext.addParameter(null, element);
    }
    element.hasImplicitType = node.type == null && node.parameters == null;
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    nameNode.staticElement = element;

    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        element.parameters = holder.parameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.type);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;
    var nameOffset = nameNode.offset;

    var functionExpression = node.functionExpression;
    var body = functionExpression.body;

    Reference reference;
    ExecutableElementImpl executableElement;
    if (node.isGetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isGetter = true;

      reference = _enclosingContext.addGetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else if (node.isSetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isSetter = true;

      reference = _enclosingContext.addSetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else {
      var element = FunctionElementImpl(name, nameOffset);
      reference = _enclosingContext.addFunction(name, element);
      executableElement = element;
    }

    executableElement.hasImplicitReturnType = node.returnType == null;
    executableElement.isAsynchronous = body.isAsynchronous;
    executableElement.isExternal = node.externalKeyword != null;
    executableElement.isGenerator = body.isGenerator;
    executableElement.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(executableElement, node);
    _setDocumentation(executableElement, node);

    nameNode.staticElement = executableElement;
    _linker.elementNodes[executableElement] = node;

    _buildExecutableElementChildren(
      reference: reference,
      element: executableElement,
      formalParameters: functionExpression.parameters,
      typeParameters: functionExpression.typeParameters,
    );

    var localScope = _libraryBuilder.localScope;
    if (node.isSetter) {
      localScope.declare('$name=', reference);
    } else {
      localScope.declare(name, reference);
    }

    _buildType(node.returnType);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;

    var element = TypeAliasElementImpl(name, nameNode.offset);
    element.isFunctionTypeAliasBased = true;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addTypeAlias(name, element);
    _libraryBuilder.localScope.declare(name, reference);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.returnType?.accept(this);
      node.parameters.accept(this);
    });

    var aliasedElement = GenericFunctionTypeElementImpl.forOffset(
      node.name.offset,
    );
    aliasedElement.parameters = holder.parameters;

    element.typeParameters = holder.typeParameters;
    element.aliasedElement = aliasedElement;
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var nameNode = node.identifier;
    var name = nameNode.name;
    var nameOffset = nameNode.offset;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameter) {
      element = DefaultParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
    } else {
      element = ParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      );
      _linker.elementNodes[element] = node;
    }
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;
    _enclosingContext.addParameter(name, element);

    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      element.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.returnType);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var element = GenericFunctionTypeElementImpl.forOffset(node.offset);
    _unitElement.encloseElement(element);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      element.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    _buildType(node.returnType);
  }

  @override
  void visitGenericTypeAlias(covariant GenericTypeAliasImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;

    var element = TypeAliasElementImpl(name, nameNode.offset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addTypeAlias(name, element);
    _libraryBuilder.localScope.declare(name, reference);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
    });
    element.typeParameters = holder.typeParameters;

    var typeNode = node.type;
    typeNode.accept(this);

    if (typeNode is GenericFunctionTypeImpl) {
      element.aliasedElement =
          typeNode.declaredElement as GenericFunctionTypeElementImpl;
    }
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    node.interfaces2.accept(this);
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var uriStr = node.uri.stringValue;

    var element = ImportElementImpl(node.keyword.offset);
    element.combinators = _buildCombinators(node.combinators);
    element.importedLibrary = _selectLibrary(node);
    element.isDeferred = node.deferredKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    element.uri = uriStr;

    var prefixNode = node.prefix;
    if (prefixNode != null) {
      element.prefix = PrefixElementImpl(
        prefixNode.name,
        prefixNode.offset,
        reference: _libraryBuilder.reference
            .getChild('@prefix')
            .getChild(prefixNode.name),
      );
    }

    node.element = element;

    _imports.add(element);

    if (uriStr == 'dart:core') {
      _hasCoreImport = true;
    }
  }

  @override
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {
    if (_isFirstLibraryDirective) {
      _isFirstLibraryDirective = false;
      node.element = _libraryElement;
      _libraryElement.documentationComment = getCommentNodeRawText(
        node.documentationComment,
      );
      _libraryElement.metadata = _buildAnnotations(node.metadata);
    }
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;
    var nameOffset = nameNode.offset;

    Reference reference;
    ExecutableElementImpl executableElement;
    if (node.isGetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isAbstract = node.isAbstract;
      element.isGetter = true;
      element.isStatic = node.isStatic;

      reference = _enclosingContext.addGetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else if (node.isSetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isAbstract = node.isAbstract;
      element.isSetter = true;
      element.isStatic = node.isStatic;

      reference = _enclosingContext.addSetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else {
      if (name == '-') {
        var parameters = node.parameters;
        if (parameters != null && parameters.parameters.isEmpty) {
          name = 'unary-';
        }
      }

      var element = MethodElementImpl(name, nameOffset);
      element.isAbstract = node.isAbstract;
      element.isStatic = node.isStatic;

      reference = _enclosingContext.addMethod(name, element);
      executableElement = element;
    }
    executableElement.hasImplicitReturnType = node.returnType == null;
    executableElement.isAsynchronous = node.body.isAsynchronous;
    executableElement.isExternal =
        node.externalKeyword != null || node.body is NativeFunctionBody;
    executableElement.isGenerator = node.body.isGenerator;
    executableElement.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(executableElement, node);
    _setDocumentation(executableElement, node);

    nameNode.staticElement = executableElement;
    _linker.elementNodes[executableElement] = node;

    _buildExecutableElementChildren(
      reference: reference,
      element: executableElement,
      formalParameters: node.parameters,
      typeParameters: node.typeParameters,
    );

    _buildType(node.returnType);
  }

  @override
  void visitMixinDeclaration(covariant MixinDeclarationImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;

    var element = MixinElementImpl(name, nameNode.offset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addMixin(name, element);
    _libraryBuilder.localScope.declare(name, reference);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    node.onClause?.accept(this);
    node.implementsClause?.accept(this);
    _buildClassOrMixin(node);
  }

  @override
  void visitNamedType(NamedType node) {
    node.typeArguments?.accept(this);
  }

  @override
  void visitOnClause(OnClause node) {
    node.superclassConstraints2.accept(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    var index = _partDirectiveIndex++;
    // TODO(scheglov) With invalid URIs we will associate metadata incorrectly
    if (index < _libraryElement.parts.length) {
      var partElement = _libraryElement.parts[index];
      partElement as CompilationUnitElementImpl;
      partElement.metadata = _buildAnnotations(node.metadata);
    }
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _libraryElement.hasPartOfDirective = true;
  }

  @override
  void visitSimpleFormalParameter(
    covariant SimpleFormalParameterImpl node,
  ) {
    var nameNode = node.identifier;
    var name = nameNode?.name ?? '';
    var nameOffset = nameNode?.offset ?? -1;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameter) {
      element = DefaultParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
      _enclosingContext.addParameter(name, element);
    } else {
      element = ParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      );
      _linker.elementNodes[element] = node;
      _enclosingContext.addParameter(null, element);
    }

    element.hasImplicitType = node.type == null;
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;
    nameNode?.staticElement = element;

    _buildType(node.type);
  }

  @override
  void visitTopLevelVariableDeclaration(
    covariant TopLevelVariableDeclarationImpl node,
  ) {
    var enclosingRef = _enclosingContext.reference;

    var metadata = _buildAnnotations(node.metadata);
    for (var variable in node.variables.variables) {
      var nameNode = variable.name as SimpleIdentifierImpl;
      var name = nameNode.name;
      var nameOffset = nameNode.offset;

      TopLevelVariableElementImpl element;
      if (node.variables.isConst) {
        element = ConstTopLevelVariableElementImpl(name, nameOffset);
      } else {
        element = TopLevelVariableElementImpl(name, nameOffset);
      }

      element.hasInitializer = variable.initializer != null;
      element.isConst = node.variables.isConst;
      element.isExternal = node.externalKeyword != null;
      element.isFinal = node.variables.isFinal;
      element.isLate = node.variables.isLate;
      element.metadata = metadata;
      _setCodeRange(element, variable);
      _setDocumentation(element, node);

      if (node.variables.type == null) {
        element.hasImplicitType = true;
        element.type = DynamicTypeImpl.instance;
      }

      element.createImplicitAccessors(enclosingRef, name);

      _linker.elementNodes[element] = variable;
      _enclosingContext.addTopLevelVariable(name, element);
      nameNode.staticElement = element;

      var getter = element.getter;
      if (getter is PropertyAccessorElementImpl) {
        _enclosingContext.addGetter(name, getter);
        var localScope = _libraryBuilder.localScope;
        localScope.declare(name, getter.reference!);
      }

      var setter = element.setter;
      if (setter is PropertyAccessorElementImpl) {
        _enclosingContext.addSetter(name, setter);
        var localScope = _libraryBuilder.localScope;
        localScope.declare('$name=', setter.reference!);
      }
    }

    _buildType(node.variables.type);
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    node.arguments.accept(this);
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;

    var element = TypeParameterElementImpl(name, nameNode.offset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;
    _enclosingContext.addTypeParameter(name, element);

    _buildType(node.bound);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  @override
  void visitWithClause(WithClause node) {
    node.mixinTypes2.accept(this);
  }

  List<ElementAnnotation> _buildAnnotations(List<Annotation> nodeList) {
    return _buildAnnotationsWithUnit(_unitElement, nodeList);
  }

  _EnclosingContext _buildClassMembers(
      ElementImpl element, NodeList<ClassMember> members) {
    var hasConstConstructor = members.any((e) {
      return e is ConstructorDeclaration && e.constKeyword != null;
    });
    var holder = _EnclosingContext(element.reference!, element,
        hasConstConstructor: hasConstConstructor);
    _withEnclosing(holder, () {
      _visitPropertyFirst<FieldDeclaration>(members);
    });
    return holder;
  }

  void _buildClassOrMixin(ClassOrMixinDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;
    var holder = _buildClassMembers(element, node.members);
    element.accessors = holder.propertyAccessors;
    element.fields = holder.properties.whereType<FieldElement>().toList();
    element.methods = holder.methods;

    var constructors = holder.constructors;
    if (constructors.isEmpty) {
      var containerRef = element.reference!.getChild('@constructor');
      constructors = [
        ConstructorElementImpl('', -1)
          ..isSynthetic = true
          ..reference = containerRef.getChild(''),
      ];
    }
    element.constructors = constructors;

    // We have all fields and constructors.
    // Now we can resolve field formal parameters.
    for (var constructor in constructors) {
      for (var parameter in constructor.parameters) {
        if (parameter is FieldFormalParameterElementImpl) {
          parameter.field = element.getField(parameter.name);
        }
      }
    }
  }

  void _buildExecutableElementChildren({
    required Reference reference,
    required ExecutableElementImpl element,
    FormalParameterList? formalParameters,
    TypeParameterList? typeParameters,
  }) {
    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      if (formalParameters != null) {
        formalParameters.accept(this);
        element.parameters = holder.parameters;
      }
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });
  }

  void _buildSyntheticVariable({
    required String name,
    required PropertyAccessorElementImpl accessorElement,
  }) {
    var enclosingRef = _enclosingContext.reference;
    var enclosingElement = _enclosingContext.element;

    PropertyInducingElementImpl? property;
    if (enclosingElement is CompilationUnitElement) {
      var containerRef = enclosingRef.getChild('@variable');
      var propertyRef = containerRef.getChild(name);
      property = propertyRef.element as PropertyInducingElementImpl?;
      if (property == null) {
        var variable = TopLevelVariableElementImpl(name, -1);
        variable.isSynthetic = true;
        _enclosingContext.addTopLevelVariable(name, variable);
        property = variable;
      }
    } else {
      var containerRef = enclosingRef.getChild('@field');
      var propertyRef = containerRef.getChild(name);
      property = propertyRef.element as PropertyInducingElementImpl?;
      if (property == null) {
        var field = FieldElementImpl(name, -1);
        field.isSynthetic = true;
        field.isStatic = accessorElement.isStatic;
        _enclosingContext.addField(name, field);
        property = field;
      }
    }

    accessorElement.variable = property;
    if (accessorElement.isGetter) {
      property.getter = accessorElement;
    } else {
      property.setter = accessorElement;
    }
  }

  /// TODO(scheglov) Maybe inline?
  void _buildType(TypeAnnotation? node) {
    node?.accept(this);
  }

  Uri? _selectAbsoluteUri(NamespaceDirective directive) {
    var relativeUriStr = _selectRelativeUri(
      directive.configurations,
      directive.uri.stringValue,
    );
    if (relativeUriStr == null) {
      return null;
    }

    Uri relativeUri;
    try {
      relativeUri = Uri.parse(relativeUriStr);
    } on FormatException {
      return null;
    }

    var absoluteUri = resolveRelativeUri(_libraryBuilder.uri, relativeUri);

    var sourceFactory = _linker.analysisContext.sourceFactory;
    return rewriteFileToPackageUri(sourceFactory, absoluteUri);
  }

  LibraryElement? _selectLibrary(NamespaceDirective node) {
    var uri = _selectAbsoluteUri(node);
    if (uri != null) {
      return _linker.elementFactory.libraryOfUri('$uri');
    }
  }

  String? _selectRelativeUri(
    List<Configuration> configurations,
    String? defaultUri,
  ) {
    for (var configuration in configurations) {
      var name = configuration.name.components.join('.');
      var value = configuration.value?.stringValue ?? 'true';
      if (_linker.declaredVariables.get(name) == value) {
        return configuration.uri.stringValue;
      }
    }
    return defaultUri;
  }

  bool _shouldBeConstField(FieldDeclaration node) {
    var fields = node.fields;
    return fields.isConst ||
        !node.isStatic &&
            fields.isFinal &&
            _enclosingContext.hasConstConstructor;
  }

  void _visitPropertyFirst<T extends AstNode>(List<AstNode> nodes) {
    // When loading from bytes, we read fields first.
    // There is no particular reason for this - we just have to store
    // either non-synthetic fields first, or non-synthetic property
    // accessors first. And we arbitrary decided to store fields first.
    for (var node in nodes) {
      if (node is T) {
        node.accept(this);
      }
    }

    // ...then we load non-synthetic accessors.
    for (var node in nodes) {
      if (node is! T) {
        node.accept(this);
      }
    }
  }

  /// Make the given [context] be the current one while running [f].
  void _withEnclosing(_EnclosingContext context, void Function() f) {
    var previousContext = _enclosingContext;
    _enclosingContext = context;
    try {
      f();
    } finally {
      _enclosingContext = previousContext;
    }
  }

  static void buildEnumChildren(
    Linker linker,
    LibraryElementImpl libraryElement,
  ) {
    for (var unitElement in libraryElement.units) {
      for (var element in unitElement.enums) {
        var node = linker.elementNodes[element] as EnumDeclaration;
        element as EnumElementImpl;
        var reference = element.reference!;

        var fields = <FieldElementImpl>[];
        var getters = <PropertyAccessorElementImpl>[];

        // Build the 'index' field.
        {
          var field = FieldElementImpl('index', -1)
            ..enclosingElement = element
            ..isSynthetic = true
            ..isFinal = true
            ..type = libraryElement.typeProvider.intType;
          fields.add(field);
          getters.add(PropertyAccessorElementImpl_ImplicitGetter(field,
              reference: reference.getChild('@getter').getChild('index'))
            ..enclosingElement = element);
        }

        // Build the 'values' field.
        {
          var field = ConstFieldElementImpl_EnumValues(element);
          fields.add(field);
          getters.add(PropertyAccessorElementImpl_ImplicitGetter(field,
              reference: reference.getChild('@getter').getChild('values'))
            ..enclosingElement = element);
        }

        // Build fields for all enum constants.
        var containerRef = reference.getChild('@constant');
        var constants = node.constants;
        for (var i = 0; i < constants.length; ++i) {
          var constant = constants[i];
          var name = constant.name.name;
          var reference = containerRef.getChild(name);
          var field = ConstFieldElementImpl_EnumValue(element, name, i);
          // TODO(scheglov) test it
          field.nameOffset = constant.name.offset;
          _setCodeRange(field, constant);
          _setDocumentation(field, constant);
          field.reference = reference;
          field.metadata = _buildAnnotationsWithUnit(
            unitElement as CompilationUnitElementImpl,
            constant.metadata,
          );
          field.createImplicitAccessors(containerRef.parent!, name);
          fields.add(field);
          getters.add(field.getter as PropertyAccessorElementImpl);
        }

        element.fields = fields;
        element.accessors = getters;

        element.createToStringMethodElement();
        (element.getMethod('toString') as MethodElementImpl).returnType =
            libraryElement.typeProvider.stringType;
      }
    }
  }

  static List<ElementAnnotation> _buildAnnotationsWithUnit(
    CompilationUnitElementImpl unitElement,
    List<Annotation> nodeList,
  ) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotation>[];
    }

    var annotations = <ElementAnnotation>[];
    for (int i = 0; i < length; i++) {
      var ast = nodeList[i] as AnnotationImpl;
      var element = ElementAnnotationImpl(unitElement);
      element.annotationAst = ast;
      ast.elementAnnotation = element;
      annotations.add(element);
    }
    return annotations;
  }

  static List<NamespaceCombinator> _buildCombinators(
    List<Combinator> combinators,
  ) {
    return combinators.map((node) {
      if (node is HideCombinator) {
        return HideElementCombinatorImpl()
          ..hiddenNames = node.hiddenNames.nameList;
      }
      if (node is ShowCombinator) {
        return ShowElementCombinatorImpl()
          ..offset = node.keyword.offset
          ..end = node.end
          ..shownNames = node.shownNames.nameList;
      }
      throw UnimplementedError('${node.runtimeType}');
    }).toList();
  }

  static void _setCodeRange(ElementImpl element, AstNode node) {
    var parent = node.parent;
    if (node is FormalParameter && parent is DefaultFormalParameter) {
      node = parent;
    }

    if (node is VariableDeclaration && parent is VariableDeclarationList) {
      var fieldDeclaration = parent.parent;
      if (fieldDeclaration != null && parent.variables.first == node) {
        var offset = fieldDeclaration.offset;
        element.setCodeRange(offset, node.end - offset);
        return;
      }
    }

    element.setCodeRange(node.offset, node.length);
  }

  static void _setDocumentation(ElementImpl element, AnnotatedNode node) {
    element.documentationComment =
        getCommentNodeRawText(node.documentationComment);
  }
}

class _EnclosingContext {
  final Reference reference;
  final ElementImpl element;
  final List<ClassElementImpl> classes = [];
  final List<ConstructorElementImpl> constructors = [];
  final List<EnumElementImpl> enums = [];
  final List<ExtensionElementImpl> extensions = [];
  final List<FunctionElementImpl> functions = [];
  final List<MethodElementImpl> methods = [];
  final List<MixinElementImpl> mixins = [];
  final List<ParameterElementImpl> parameters = [];
  final List<PropertyInducingElementImpl> properties = [];
  final List<PropertyAccessorElementImpl> propertyAccessors = [];
  final List<TypeAliasElementImpl> typeAliases = [];
  final List<TypeParameterElementImpl> typeParameters = [];
  final bool hasConstConstructor;

  _EnclosingContext(
    this.reference,
    this.element, {
    this.hasConstConstructor = false,
  });

  Reference addClass(String name, ClassElementImpl element) {
    classes.add(element);
    return _bindReference('@class', name, element);
  }

  Reference addConstructor(String name, ConstructorElementImpl element) {
    constructors.add(element);
    return _bindReference('@constructor', name, element);
  }

  Reference addEnum(String name, EnumElementImpl element) {
    enums.add(element);
    return _bindReference('@enum', name, element);
  }

  Reference addExtension(String name, ExtensionElementImpl element) {
    extensions.add(element);
    return _bindReference('@extension', name, element);
  }

  Reference addField(String name, FieldElementImpl element) {
    properties.add(element);
    return _bindReference('@field', name, element);
  }

  Reference addFunction(String name, FunctionElementImpl element) {
    functions.add(element);
    return _bindReference('@function', name, element);
  }

  Reference addGetter(String name, PropertyAccessorElementImpl element) {
    propertyAccessors.add(element);
    return _bindReference('@getter', name, element);
  }

  Reference addMethod(String name, MethodElementImpl element) {
    methods.add(element);
    return _bindReference('@method', name, element);
  }

  Reference addMixin(String name, MixinElementImpl element) {
    mixins.add(element);
    return _bindReference('@mixin', name, element);
  }

  Reference? addParameter(String? name, ParameterElementImpl element) {
    parameters.add(element);
    if (name != null) {
      return _bindReference('@parameter', name, element);
    }
  }

  Reference addSetter(String name, PropertyAccessorElementImpl element) {
    propertyAccessors.add(element);
    return _bindReference('@setter', name, element);
  }

  Reference addTopLevelVariable(
      String name, TopLevelVariableElementImpl element) {
    properties.add(element);
    return _bindReference('@variable', name, element);
  }

  Reference addTypeAlias(String name, TypeAliasElementImpl element) {
    typeAliases.add(element);
    return _bindReference('@typeAlias', name, element);
  }

  void addTypeParameter(String name, TypeParameterElementImpl element) {
    typeParameters.add(element);
    this.element.encloseElement(element);
  }

  Reference _bindReference(
    String containerName,
    String name,
    ElementImpl element,
  ) {
    var containerRef = this.reference.getChild(containerName);
    var reference = containerRef.getChild(name);
    reference.element = element;
    element.reference = reference;
    this.element.encloseElement(element);
    return reference;
  }
}

extension on Iterable<SimpleIdentifier> {
  List<String> get nameList {
    return map((e) => e.name).toList();
  }
}
