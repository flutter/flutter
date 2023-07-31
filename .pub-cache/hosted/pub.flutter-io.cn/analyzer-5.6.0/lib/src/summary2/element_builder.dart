// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/invokes_super_self.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/util/comment.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:collection/collection.dart';

class ElementBuilder extends ThrowingAstVisitor<void> {
  final LibraryBuilder _libraryBuilder;
  final LibraryOrAugmentationElementImpl _container;
  final CompilationUnitElementImpl _unitElement;

  var _isFirstLibraryDirective = true;
  var _augmentationDirectiveIndex = 0;
  var _exportDirectiveIndex = 0;
  var _importDirectiveIndex = 0;
  var _partDirectiveIndex = 0;

  _EnclosingContext _enclosingContext;
  var _nextUnnamedExtensionId = 0;

  ElementBuilder({
    required LibraryBuilder libraryBuilder,
    required LibraryOrAugmentationElementImpl container,
    required Reference unitReference,
    required CompilationUnitElementImpl unitElement,
  })  : _libraryBuilder = libraryBuilder,
        _container = container,
        _unitElement = unitElement,
        _enclosingContext = _EnclosingContext(unitReference, unitElement);

  Linker get _linker => _libraryBuilder.linker;

  void buildDeclarationElements(CompilationUnit unit) {
    _visitPropertyFirst<TopLevelVariableDeclaration>(unit.declarations);
    _unitElement.accessors = _enclosingContext.propertyAccessors;
    _unitElement.classes = _enclosingContext.classes;
    _unitElement.enums = _enclosingContext.enums;
    _unitElement.extensions = _enclosingContext.extensions;
    _unitElement.functions = _enclosingContext.functions;
    _unitElement.mixins = _enclosingContext.mixins;
    _unitElement.topLevelVariables = _enclosingContext.topLevelVariables;
    _unitElement.typeAliases = _enclosingContext.typeAliases;
  }

  /// Build exports and imports, metadata into [_container].
  void buildLibraryElementChildren(CompilationUnit unit) {
    unit.directives.accept(this);

    if (_isFirstLibraryDirective) {
      _isFirstLibraryDirective = false;
      var firstDirective = unit.directives.firstOrNull;
      if (firstDirective != null) {
        _container.documentationComment = getCommentNodeRawText(
          firstDirective.documentationComment,
        );
        var firstDirectiveMetadata = firstDirective.element?.metadata;
        if (firstDirectiveMetadata != null) {
          _container.metadata = firstDirectiveMetadata;
        }
      }
    }
  }

  @override
  void visitAugmentationImportDirective(AugmentationImportDirective node) {
    final index = _augmentationDirectiveIndex++;
    final element = _container.augmentationImports[index];
    element.metadata = _buildAnnotations(node.metadata);
  }

  @override
  void visitClassDeclaration(covariant ClassDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = ClassElementImpl(name, nameToken.offset);
    element.isAbstract = node.abstractKeyword != null;
    element.isMacro = node.macroKeyword != null;
    if (node.sealedKeyword != null) {
      element.isSealed = true;
      element.isAbstract = true;
    }
    element.isBase = node.baseKeyword != null;
    element.isInterface = node.interfaceKeyword != null;
    element.isFinal = node.finalKeyword != null;
    element.isMixinClass = node.mixinKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addClass(name, element);
    _libraryBuilder.declare(name, reference);

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
    _buildClass(node);
  }

  @override
  void visitClassTypeAlias(covariant ClassTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = ClassElementImpl(name, nameToken.offset);
    element.isAbstract = node.abstractKeyword != null;
    element.isMacro = node.macroKeyword != null;
    if (node.sealedKeyword != null) {
      element.isSealed = true;
      element.isAbstract = true;
    }
    element.isBase = node.baseKeyword != null;
    element.isInterface = node.interfaceKeyword != null;
    element.isFinal = node.finalKeyword != null;
    element.isMixinApplication = true;
    element.isMixinClass = node.mixinKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addClass(name, element);
    _libraryBuilder.declare(name, reference);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    node.superclass.accept(this);
    node.withClause.accept(this);
    node.implementsClause?.accept(this);
  }

  @override
  void visitConstructorDeclaration(
    covariant ConstructorDeclarationImpl node,
  ) {
    var nameNode = node.name ?? node.returnType;
    var name = node.name?.lexeme ?? '';
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

    var reference = _enclosingContext.addConstructor(element);
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
    var name = nameNode.lexeme;
    var nameOffset = nameNode.offset;

    var element = EnumElementImpl(name, nameOffset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addEnum(name, element);
    _libraryBuilder.declare(name, reference);

    var holder = _EnclosingContext(
      reference,
      element,
      hasConstConstructor: true,
    );

    // Build fields for all enum constants.
    var constants = node.constants;
    var valuesElements = <ExpressionImpl>[];
    for (var i = 0; i < constants.length; ++i) {
      var constant = constants[i];
      var name = constant.name.lexeme;
      var field = ConstFieldElementImpl(name, constant.name.offset)
        ..hasImplicitType = true
        ..hasInitializer = true
        ..isConst = true
        ..isEnumConstant = true
        ..isStatic = true;
      _setCodeRange(field, constant);
      _setDocumentation(field, constant);
      field.metadata = _buildAnnotationsWithUnit(
        _unitElement,
        constant.metadata,
      );

      var constructorSelector = constant.arguments?.constructorSelector;
      var constructorName = constructorSelector?.name.name;

      var initializer = InstanceCreationExpressionImpl(
        keyword: null,
        constructorName: ConstructorNameImpl(
          type: NamedTypeImpl(
            name: astFactory.simpleIdentifier(
              StringToken(TokenType.STRING, element.name, -1),
            ),
            typeArguments: constant.arguments?.typeArguments,
            question: null,
          ),
          period: constructorName != null ? Tokens.period() : null,
          name: constructorName != null
              ? astFactory.simpleIdentifier(
                  StringToken(TokenType.STRING, constructorName, -1),
                )
              : null,
        ),
        argumentList: ArgumentListImpl(
          leftParenthesis: Tokens.openParenthesis(),
          arguments: [
            ...?constant.arguments?.argumentList.arguments,
          ],
          rightParenthesis: Tokens.closeParenthesis(),
        ),
        typeArguments: null,
      );

      var variableDeclaration = VariableDeclarationImpl(
        name: StringToken(TokenType.STRING, name, -1),
        equals: Tokens.eq(),
        initializer: initializer,
      );
      VariableDeclarationListImpl(
        comment: null,
        metadata: null,
        lateKeyword: null,
        keyword: null,
        type: null,
        variables: [variableDeclaration],
      );
      _linker.elementNodes[field] = variableDeclaration;

      field.constantInitializer = initializer;
      holder.addNonSyntheticField(field);
      valuesElements.add(
        astFactory.simpleIdentifier(
          StringToken(TokenType.STRING, name, -1),
        ),
      );
    }

    // Build the 'values' field.
    ConstFieldElementImpl valuesField;
    NamedTypeImpl valuesTypeNode;
    {
      valuesField = ConstFieldElementImpl('values', -1)
        ..isConst = true
        ..isStatic = true
        ..isSynthetic = true;
      var initializer = ListLiteralImpl(
        constKeyword: null,
        typeArguments: null,
        leftBracket: Tokens.openSquareBracket(),
        elements: valuesElements,
        rightBracket: Tokens.closeSquareBracket(),
      );
      valuesField.constantInitializer = initializer;

      var variableDeclaration = VariableDeclarationImpl(
        name: StringToken(TokenType.STRING, 'values', -1),
        equals: Tokens.eq(),
        initializer: initializer,
      );
      valuesTypeNode = NamedTypeImpl(
        name: astFactory.simpleIdentifier(
          StringToken(TokenType.STRING, 'List', -1),
        ),
        typeArguments: TypeArgumentListImpl(
          leftBracket: Tokens.lt(),
          arguments: [
            NamedTypeImpl(
              name: astFactory.simpleIdentifier(
                StringToken(TokenType.STRING, element.name, -1),
              )..staticElement = element,
              typeArguments: null,
              question: null,
            )
          ],
          rightBracket: Tokens.gt(),
        ),
        question: null,
      );
      VariableDeclarationListImpl(
        comment: null,
        metadata: null,
        lateKeyword: null,
        keyword: Tokens.const_(),
        variables: [variableDeclaration],
        type: valuesTypeNode,
      );
      _linker.elementNodes[valuesField] = variableDeclaration;

      holder.addNonSyntheticField(valuesField);
    }

    node.withClause?.accept(this);
    node.implementsClause?.accept(this);

    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    var needsImplicitConstructor = !holder.constructors.any(
      (e) => e.name.isEmpty || e.isGenerative,
    );

    if (needsImplicitConstructor) {
      holder.addConstructor(
        ConstructorElementImpl('', -1)
          ..isConst = true
          ..isSynthetic = true,
      );
    }

    _libraryBuilder.implicitEnumNodes.add(
      ImplicitEnumNodes(
        element: element,
        valuesTypeNode: valuesTypeNode,
        valuesField: valuesField,
      ),
    );

    element.accessors = holder.propertyAccessors;
    element.constructors = holder.constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;
    element.typeParameters = holder.typeParameters;

    _resolveConstructorFieldFormals(element);
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    final index = _exportDirectiveIndex++;
    final exportElement = _container.libraryExports[index];
    exportElement.metadata = _buildAnnotations(node.metadata);
    node.element = exportElement;
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    node.superclass.accept(this);
  }

  @override
  void visitExtensionDeclaration(covariant ExtensionDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken?.lexeme;
    var nameOffset = nameToken?.offset ?? -1;

    var element = ExtensionElementImpl(name, nameOffset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var refName = name ?? '${_nextUnnamedExtensionId++}';
    var reference = _enclosingContext.addExtension(refName, element);

    if (name != null) {
      _libraryBuilder.declare(name, reference);
    }

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });

    // TODO(scheglov) don't create a duplicate
    {
      var holder = _EnclosingContext(reference, element);
      _withEnclosing(holder, () {
        _visitPropertyFirst<FieldDeclaration>(node.members);
      });
      element.accessors = holder.propertyAccessors;
      element.fields = holder.fields;
      element.methods = holder.methods;
    }

    node.extendedType.accept(this);
  }

  @override
  void visitFieldDeclaration(
    covariant FieldDeclarationImpl node,
  ) {
    var metadata = _buildAnnotations(node.metadata);
    for (var variable in node.fields.variables) {
      var nameToken = variable.name;
      var name = nameToken.lexeme;
      var nameOffset = nameToken.offset;

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
      }

      _enclosingContext.addNonSyntheticField(element);

      _linker.elementNodes[element] = variable;
      variable.declaredElement = element;
    }
    _buildType(node.fields.type);
  }

  @override
  void visitFieldFormalParameter(
    covariant FieldFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

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
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;

    // TODO(scheglov) check that we don't set reference for parameters
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
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    var functionExpression = node.functionExpression;
    var body = functionExpression.body;

    Reference reference;
    ExecutableElementImpl executableElement;
    if (node.isGetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isGetter = true;
      element.isStatic = true;

      reference = _enclosingContext.addGetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else if (node.isSetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isSetter = true;
      element.isStatic = true;

      reference = _enclosingContext.addSetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else {
      var element = FunctionElementImpl(name, nameOffset);
      element.isStatic = true;
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

    node.declaredElement = executableElement;
    _linker.elementNodes[executableElement] = node;

    _buildExecutableElementChildren(
      reference: reference,
      element: executableElement,
      formalParameters: functionExpression.parameters,
      typeParameters: functionExpression.typeParameters,
    );

    if (node.isSetter) {
      _libraryBuilder.declare('$name=', reference);
    } else {
      _libraryBuilder.declare(name, reference);
    }

    _buildType(node.returnType);
  }

  @override
  void visitFunctionTypeAlias(covariant FunctionTypeAliasImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = TypeAliasElementImpl(name, nameToken.offset);
    element.isFunctionTypeAliasBased = true;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addTypeAlias(name, element);
    _libraryBuilder.declare(name, reference);

    var holder = _EnclosingContext(reference, element);
    _withEnclosing(holder, () {
      node.typeParameters?.accept(this);
      node.returnType?.accept(this);
      node.parameters.accept(this);
    });

    var aliasedElement = GenericFunctionTypeElementImpl.forOffset(
      nameToken.offset,
    );
    aliasedElement.parameters = holder.parameters;

    element.typeParameters = holder.typeParameters;
    element.aliasedElement = aliasedElement;
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

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

    node.declaredElement = element;
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
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = TypeAliasElementImpl(name, nameToken.offset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addTypeAlias(name, element);
    _libraryBuilder.declare(name, reference);

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
    node.interfaces.accept(this);
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    final index = _importDirectiveIndex++;
    final importElement = _container.libraryImports[index];
    importElement.metadata = _buildAnnotations(node.metadata);
    node.element = importElement;
  }

  @override
  void visitLibraryAugmentationDirective(LibraryAugmentationDirective node) {
    _container.metadata = _buildAnnotations(node.metadata);
  }

  @override
  void visitLibraryDirective(covariant LibraryDirectiveImpl node) {
    if (_isFirstLibraryDirective) {
      _isFirstLibraryDirective = false;
      node.element = _container;
      _container.documentationComment = getCommentNodeRawText(
        node.documentationComment,
      );
      _container.metadata = _buildAnnotations(node.metadata);
    }
  }

  @override
  void visitMethodDeclaration(covariant MethodDeclarationImpl node) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    Reference reference;
    ExecutableElementImpl executableElement;
    if (node.isGetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isAbstract = node.isAbstract;
      element.isGetter = true;
      element.isStatic = node.isStatic;

      // `class Enum {}` in `dart:core` declares `int get index` as abstract.
      // But the specification says that practically a different class
      // implementing `Enum` is used as a superclass, so `index` should be
      // considered to have non-abstract implementation.
      if (_enclosingContext.isDartCoreEnum && name == 'index') {
        element.isAbstract = false;
      }

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
    executableElement.invokesSuperSelf = node.invokesSuperSelf;
    executableElement.isAsynchronous = node.body.isAsynchronous;
    executableElement.isExternal =
        node.externalKeyword != null || node.body is NativeFunctionBody;
    executableElement.isGenerator = node.body.isGenerator;
    executableElement.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(executableElement, node);
    _setDocumentation(executableElement, node);

    node.declaredElement = executableElement;
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
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = MixinElementImpl(name, nameToken.offset);
    element.isSealed = node.sealedKeyword != null;
    element.isBase = node.baseKeyword != null;
    element.isInterface = node.interfaceKeyword != null;
    element.isFinal = node.finalKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);
    _setDocumentation(element, node);

    node.declaredElement = element;
    _linker.elementNodes[element] = node;

    var reference = _enclosingContext.addMixin(name, element);
    _libraryBuilder.declare(name, reference);

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
    _buildMixin(node);
  }

  @override
  void visitNamedType(NamedType node) {
    node.typeArguments?.accept(this);
  }

  @override
  void visitOnClause(OnClause node) {
    node.superclassConstraints.accept(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    final libraryElement = _container;
    if (libraryElement is LibraryElementImpl) {
      final index = _partDirectiveIndex++;
      final partElement = libraryElement.parts[index];
      partElement.metadata = _buildAnnotations(node.metadata);
    }
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    final libraryElement = _container;
    if (libraryElement is LibraryElementImpl) {
      libraryElement.hasPartOfDirective = true;
    }
  }

  @override
  void visitRecordTypeAnnotation(RecordTypeAnnotation node) {
    node.positionalFields.accept(this);
    node.namedFields?.accept(this);
  }

  @override
  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitRecordTypeAnnotationNamedFields(
    RecordTypeAnnotationNamedFields node,
  ) {
    node.fields.accept(this);
  }

  @override
  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    node.type.accept(this);
  }

  @override
  void visitSimpleFormalParameter(
    covariant SimpleFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken?.lexeme ?? '';
    var nameOffset = nameToken?.offset ?? -1;

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

    _buildType(node.type);
  }

  @override
  void visitSuperFormalParameter(
    covariant SuperFormalParameterImpl node,
  ) {
    var nameToken = node.name;
    var name = nameToken.lexeme;
    var nameOffset = nameToken.offset;

    SuperFormalParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameter) {
      element = DefaultSuperFormalParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      )..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
      _enclosingContext.addParameter(name, element);
    } else {
      element = SuperFormalParameterElementImpl(
        name: name,
        nameOffset: nameOffset,
        parameterKind: node.kind,
      );
      _linker.elementNodes[element] = node;
      _enclosingContext.addParameter(null, element);
    }
    element.hasImplicitType = node.type == null && node.parameters == null;
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;

    // TODO(scheglov) check that we don't set reference for parameters
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
  void visitTopLevelVariableDeclaration(
    covariant TopLevelVariableDeclarationImpl node,
  ) {
    var enclosingRef = _enclosingContext.reference;

    var metadata = _buildAnnotations(node.metadata);
    for (var variable in node.variables.variables) {
      var nameToken = variable.name;
      var name = nameToken.lexeme;
      var nameOffset = nameToken.offset;

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
      }

      element.createImplicitAccessors(enclosingRef, name);

      _linker.elementNodes[element] = variable;
      _enclosingContext.addTopLevelVariable(name, element);
      variable.declaredElement = element;

      var getter = element.getter;
      if (getter is PropertyAccessorElementImpl) {
        _enclosingContext.addGetter(name, getter);
        _libraryBuilder.declare(name, getter.reference!);
      }

      var setter = element.setter;
      if (setter is PropertyAccessorElementImpl) {
        _enclosingContext.addSetter(name, setter);
        _libraryBuilder.declare('$name=', setter.reference!);
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
    var nameToken = node.name;
    var name = nameToken.lexeme;

    var element = TypeParameterElementImpl(name, nameToken.offset);
    element.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(element, node);

    node.declaredElement = element;
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
    node.mixinTypes.accept(this);
  }

  List<ElementAnnotation> _buildAnnotations(List<Annotation> nodeList) {
    return _buildAnnotationsWithUnit(_unitElement, nodeList);
  }

  void _buildClass(ClassDeclaration node) {
    var element = node.declaredElement as ClassElementImpl;
    var hasConstConstructor = node.members.any((e) {
      return e is ConstructorDeclaration && e.constKeyword != null;
    });
    // TODO(scheglov) don't create a duplicate
    var holder = _EnclosingContext(element.reference!, element,
        hasConstConstructor: hasConstConstructor);
    _withEnclosing(holder, () {
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    if (!holder.hasConstructors) {
      holder.addConstructor(
        ConstructorElementImpl('', -1)..isSynthetic = true,
      );
    }

    element.accessors = holder.propertyAccessors;
    element.constructors = holder.constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;

    _resolveConstructorFieldFormals(element);
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

  void _buildMixin(MixinDeclaration node) {
    var element = node.declaredElement as MixinElementImpl;
    var hasConstConstructor = node.members.any((e) {
      return e is ConstructorDeclaration && e.constKeyword != null;
    });
    // TODO(scheglov) don't create a duplicate
    var holder = _EnclosingContext(element.reference!, element,
        hasConstConstructor: hasConstConstructor);
    _withEnclosing(holder, () {
      _visitPropertyFirst<FieldDeclaration>(node.members);
    });

    element.accessors = holder.propertyAccessors;
    element.constructors = holder.constructors;
    element.fields = holder.fields;
    element.methods = holder.methods;

    _resolveConstructorFieldFormals(element);
  }

  void _buildSyntheticVariable({
    required String name,
    required PropertyAccessorElementImpl accessorElement,
  }) {
    var enclosingRef = _enclosingContext.reference;
    var enclosingElement = _enclosingContext.element;

    bool canUseExisting(PropertyInducingElement property) {
      return property.isSynthetic ||
          accessorElement.isSetter && property.setter == null;
    }

    final PropertyInducingElementImpl property;
    if (enclosingElement is CompilationUnitElement) {
      final reference = enclosingRef.getChild('@variable').getChild(name);
      final existing = reference.element;
      if (existing is TopLevelVariableElementImpl && canUseExisting(existing)) {
        property = existing;
      } else {
        final variable = property = TopLevelVariableElementImpl(name, -1)
          ..isSynthetic = true;
        _enclosingContext.addTopLevelVariable(name, variable);
      }
    } else {
      final reference = enclosingRef.getChild('@field').getChild(name);
      final existing = reference.element;
      if (existing is FieldElementImpl && canUseExisting(existing)) {
        property = existing;
      } else {
        final field = property = FieldElementImpl(name, -1)
          ..isStatic = accessorElement.isStatic
          ..isSynthetic = true;
        _enclosingContext.addField(name, field);
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

  void _resolveConstructorFieldFormals(AbstractClassElementImpl element) {
    for (var constructor in element.constructors) {
      for (var parameter in constructor.parameters) {
        if (parameter is FieldFormalParameterElementImpl) {
          parameter.field = element.getField(parameter.name);
        }
      }
    }
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

  static List<ElementAnnotation> _buildAnnotationsWithUnit(
    CompilationUnitElementImpl unitElement,
    List<Annotation> nodeList,
  ) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotation>[];
    }

    return List<ElementAnnotation>.generate(length, (index) {
      var ast = nodeList[index] as AnnotationImpl;
      var element = ElementAnnotationImpl(unitElement);
      element.annotationAst = ast;
      ast.elementAnnotation = element;
      return element;
    }, growable: false);
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
  final List<ClassElementImpl> _classes = [];
  final List<ConstructorElementImpl> _constructors = [];
  final List<EnumElementImpl> _enums = [];
  final List<ExtensionElementImpl> _extensions = [];
  final List<FieldElementImpl> _fields = [];
  final List<FunctionElementImpl> _functions = [];
  final List<MethodElementImpl> _methods = [];
  final List<MixinElementImpl> _mixins = [];
  final List<ParameterElementImpl> _parameters = [];
  final List<PropertyAccessorElementImpl> _propertyAccessors = [];
  final List<TopLevelVariableElementImpl> _topLevelVariables = [];
  final List<TypeAliasElementImpl> _typeAliases = [];
  final List<TypeParameterElementImpl> _typeParameters = [];
  final bool hasConstConstructor;

  _EnclosingContext(
    this.reference,
    this.element, {
    this.hasConstConstructor = false,
  });

  List<ClassElementImpl> get classes {
    return _classes.toFixedList();
  }

  List<ConstructorElementImpl> get constructors {
    return _constructors.toFixedList();
  }

  List<EnumElementImpl> get enums {
    return _enums.toFixedList();
  }

  List<ExtensionElementImpl> get extensions {
    return _extensions.toFixedList();
  }

  List<FieldElementImpl> get fields {
    return _fields.toFixedList();
  }

  List<FunctionElementImpl> get functions {
    return _functions.toFixedList();
  }

  bool get hasConstructors => _constructors.isNotEmpty;

  bool get isDartCoreEnum {
    final element = this.element;
    return element is ClassElementImpl && element.isDartCoreEnum;
  }

  List<MethodElementImpl> get methods {
    return _methods.toFixedList();
  }

  List<MixinElementImpl> get mixins {
    return _mixins.toFixedList();
  }

  List<ParameterElementImpl> get parameters {
    return _parameters.toFixedList();
  }

  List<PropertyAccessorElementImpl> get propertyAccessors {
    return _propertyAccessors.toFixedList();
  }

  List<TopLevelVariableElementImpl> get topLevelVariables {
    return _topLevelVariables.toFixedList();
  }

  List<TypeAliasElementImpl> get typeAliases {
    return _typeAliases.toFixedList();
  }

  List<TypeParameterElementImpl> get typeParameters {
    return _typeParameters.toFixedList();
  }

  Reference addClass(String name, ClassElementImpl element) {
    _classes.add(element);
    return _bindReference('@class', name, element);
  }

  Reference addConstructor(ConstructorElementImpl element) {
    _constructors.add(element);

    final referenceName = element.name.ifNotEmptyOrElse('new');
    return _bindReference('@constructor', referenceName, element);
  }

  Reference addEnum(String name, EnumElementImpl element) {
    _enums.add(element);
    return _bindReference('@enum', name, element);
  }

  Reference addExtension(String name, ExtensionElementImpl element) {
    _extensions.add(element);
    return _bindReference('@extension', name, element);
  }

  Reference addField(String name, FieldElementImpl element) {
    _fields.add(element);
    return _bindReference('@field', name, element);
  }

  Reference addFunction(String name, FunctionElementImpl element) {
    _functions.add(element);
    return _bindReference('@function', name, element);
  }

  Reference addGetter(String name, PropertyAccessorElementImpl element) {
    _propertyAccessors.add(element);
    return _bindReference('@getter', name, element);
  }

  Reference addMethod(String name, MethodElementImpl element) {
    _methods.add(element);
    return _bindReference('@method', name, element);
  }

  Reference addMixin(String name, MixinElementImpl element) {
    _mixins.add(element);
    return _bindReference('@mixin', name, element);
  }

  void addNonSyntheticField(FieldElementImpl element) {
    var name = element.name;
    element.createImplicitAccessors(reference, name);

    addField(name, element);

    var getter = element.getter;
    if (getter is PropertyAccessorElementImpl) {
      addGetter(name, getter);
    }

    var setter = element.setter;
    if (setter is PropertyAccessorElementImpl) {
      addSetter(name, setter);
    }
  }

  Reference? addParameter(String? name, ParameterElementImpl element) {
    _parameters.add(element);
    if (name == null) {
      return null;
    } else {
      return _bindReference('@parameter', name, element);
    }
  }

  Reference addSetter(String name, PropertyAccessorElementImpl element) {
    _propertyAccessors.add(element);
    return _bindReference('@setter', name, element);
  }

  Reference addTopLevelVariable(
      String name, TopLevelVariableElementImpl element) {
    _topLevelVariables.add(element);
    return _bindReference('@variable', name, element);
  }

  Reference addTypeAlias(String name, TypeAliasElementImpl element) {
    _typeAliases.add(element);
    return _bindReference('@typeAlias', name, element);
  }

  void addTypeParameter(String name, TypeParameterElementImpl element) {
    _typeParameters.add(element);
    this.element.encloseElement(element);
  }

  Reference getMethod(String name) {
    return reference.getChild('@method').getChild(name);
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
