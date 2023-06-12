// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/analysis/dependency/node.dart';
import 'package:analyzer/src/dart/analysis/dependency/reference_collector.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/summary/api_signature.dart';

/// Build [Library] that describes nodes and dependencies of the library
/// with the given [uri] and [units].
///
/// If the [units] are just parsed, then only token signatures and referenced
/// names of nodes can be computed. If the [units] are fully resolved, then
/// also class member references can be recorded.
Library buildLibrary(Uri uri, List<CompilationUnit> units) {
  return _LibraryBuilder(uri, units).build();
}

/// The `show` or `hide` namespace combinator.
class Combinator {
  final bool isShow;
  final List<String> names;

  Combinator(this.isShow, this.names);

  @override
  String toString() {
    if (isShow) {
      return 'show ' + names.join(', ');
    } else {
      return 'hide ' + names.join(', ');
    }
  }
}

/// The `export` directive.
class Export {
  /// The absolute URI of the exported library.
  final Uri uri;

  /// The list of namespace combinators to apply, not `null`.
  final List<Combinator> combinators;

  Export(this.uri, this.combinators);

  @override
  String toString() {
    return 'Export(uri: $uri, combinators: $combinators)';
  }
}

/// The `import` directive.
class Import {
  /// The absolute URI of the imported library.
  final Uri uri;

  /// The import prefix, or `null` if not specified.
  final String? prefix;

  /// The list of namespace combinators to apply, not `null`.
  final List<Combinator> combinators;

  Import(this.uri, this.prefix, this.combinators);

  @override
  String toString() {
    return 'Import(uri: $uri, prefix: $prefix, combinators: $combinators)';
  }
}

/// The collection of imports, exports, and top-level nodes.
class Library {
  /// The absolute URI of the library.
  final Uri uri;

  /// The list of imports in this library.
  final List<Import> imports;

  /// The list of exports in this library.
  final List<Export> exports;

  /// The list of libraries that correspond to the [imports].
  List<Library>? importedLibraries;

  /// The list of top-level nodes defined in the library.
  ///
  /// This list is sorted.
  final List<Node> declaredNodes;

  /// The map of [declaredNodes], used for fast search.
  /// TODO(scheglov) consider using binary search instead.
  final Map<LibraryQualifiedName, Node> declaredNodeMap = {};

  /// The list of nodes exported from this library, either using `export`
  /// directives, or declared in this library.
  ///
  /// This list is sorted.
  List<Node>? exportedNodes;

  /// The map of nodes that are visible in the library, either imported,
  /// or declared in this library.
  ///
  /// TODO(scheglov) support for imports with prefixes
  Map<String, Node>? libraryScope;

  Library(this.uri, this.imports, this.exports, this.declaredNodes) {
    for (var node in declaredNodes) {
      declaredNodeMap[node.name] = node;
    }
  }

  @override
  String toString() => '$uri';
}

class _LibraryBuilder {
  /// The URI of the library.
  final Uri uri;

  /// The units of the library, parsed or fully resolved.
  final List<CompilationUnit> units;

  /// The instance of the referenced names, class members collector.
  final ReferenceCollector referenceCollector = ReferenceCollector();

  /// The list of imports in the library.
  final List<Import> imports = [];

  /// The list of exports in the library.
  final List<Export> exports = [];

  /// The top-level nodes declared in the library.
  final List<Node> declaredNodes = [];

  /// The precomputed signature of the [uri].
  ///
  /// It is mixed into every API token signature, because for example even
  /// though types of two functions might be the same, their locations
  /// are different.
  late Uint8List uriSignature;

  /// The precomputed signature of the enclosing class name, or `null` if
  /// outside a class.
  ///
  /// It is mixed into every API token signature of every class member, because
  /// for example even though types of two methods might be the same, their
  /// locations are different.
  Uint8List? enclosingClassNameSignature;

  _LibraryBuilder(this.uri, this.units);

  Library build() {
    uriSignature = (ApiSignature()..addString(uri.toString())).toByteList();

    _addImports();
    _addExports();

    for (var unit in units) {
      _addUnit(unit);
    }
    declaredNodes.sort(Node.compare);

    return Library(uri, imports, exports, declaredNodes);
  }

  void _addClassOrMixin(ClassOrMixinDeclaration node) {
    var enclosingClassName = node.name.name;

    NamedType? enclosingSuperClass;
    if (node is ClassDeclaration) {
      enclosingSuperClass = node.extendsClause?.superclass2;
    }

    enclosingClassNameSignature =
        (ApiSignature()..addString(enclosingClassName)).toByteList();

    var apiTokenSignature = _computeTokenSignature(
      node.beginToken,
      node.leftBracket,
    );

    var typeParameters = node.typeParameters;

    Dependencies api;
    if (node is ClassDeclaration) {
      api = referenceCollector.collect(
        apiTokenSignature,
        thisNodeName: enclosingClassName,
        typeParameters: typeParameters,
        extendsClause: node.extendsClause,
        withClause: node.withClause,
        implementsClause: node.implementsClause,
      );
    } else if (node is MixinDeclaration) {
      api = referenceCollector.collect(
        apiTokenSignature,
        thisNodeName: enclosingClassName,
        typeParameters: typeParameters,
        onClause: node.onClause,
        implementsClause: node.implementsClause,
      );
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    var enclosingClass = Node(
      LibraryQualifiedName(uri, enclosingClassName),
      node is MixinDeclaration ? NodeKind.MIXIN : NodeKind.CLASS,
      api,
      Dependencies.none,
    );

    var hasConstConstructor = node.members.any(
      (m) => m is ConstructorDeclaration && m.constKeyword != null,
    );

    // TODO(scheglov) do we need type parameters at all?
    List<Node> classTypeParameters;
    if (typeParameters != null) {
      classTypeParameters = <Node>[];
      for (var typeParameter in typeParameters.typeParameters) {
        var api = referenceCollector.collect(
          _computeNodeTokenSignature(typeParameter),
          enclosingClassName: enclosingClassName,
          thisNodeName: typeParameter.name.name,
          type: typeParameter.bound,
        );
        classTypeParameters.add(Node(
          LibraryQualifiedName(uri, typeParameter.name.name),
          NodeKind.TYPE_PARAMETER,
          api,
          Dependencies.none,
          enclosingClass: enclosingClass,
        ));
      }
      classTypeParameters.sort(Node.compare);
      enclosingClass.setTypeParameters(classTypeParameters);
    }

    var classMembers = <Node>[];
    var hasConstructor = false;
    for (var member in node.members) {
      if (member is ConstructorDeclaration) {
        hasConstructor = true;
        _addConstructor(
          enclosingClass,
          enclosingSuperClass,
          classMembers,
          member,
        );
      } else if (member is FieldDeclaration) {
        _addVariables(
          enclosingClass,
          classMembers,
          member.metadata,
          member.fields,
          hasConstConstructor,
        );
      } else if (member is MethodDeclaration) {
        _addMethod(enclosingClass, classMembers, member);
      } else {
        throw UnimplementedError('(${member.runtimeType}) $member');
      }
    }

    if (node is ClassDeclaration && !hasConstructor) {
      classMembers.add(Node(
        LibraryQualifiedName(uri, ''),
        NodeKind.CONSTRUCTOR,
        Dependencies.none,
        Dependencies.none,
        enclosingClass: enclosingClass,
      ));
    }

    classMembers.sort(Node.compare);
    enclosingClass.setClassMembers(classMembers);

    declaredNodes.add(enclosingClass);
    enclosingClassNameSignature = null;
  }

  void _addClassTypeAlias(ClassTypeAlias node) {
    var apiTokenSignature = _computeNodeTokenSignature(node);
    var api = referenceCollector.collect(
      apiTokenSignature,
      typeParameters: node.typeParameters,
      superClass: node.superclass2,
      withClause: node.withClause,
      implementsClause: node.implementsClause,
    );

    declaredNodes.add(Node(
      LibraryQualifiedName(uri, node.name.name),
      NodeKind.CLASS_TYPE_ALIAS,
      api,
      Dependencies.none,
    ));
  }

  void _addConstructor(
    Node enclosingClass,
    NamedType? enclosingSuperClass,
    List<Node> classMembers,
    ConstructorDeclaration node,
  ) {
    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendFormalParametersTokens(builder, node.parameters);
    var apiTokenSignature = builder.toByteList();

    var api = referenceCollector.collect(
      apiTokenSignature,
      enclosingClassName: enclosingClass.name.name,
      formalParameters: node.parameters,
    );

    var implTokenSignature = _computeNodeTokenSignature(node.body);
    var impl = referenceCollector.collect(
      implTokenSignature,
      enclosingClassName: enclosingClass.name.name,
      enclosingSuperClass: enclosingSuperClass,
      formalParametersForImpl: node.parameters,
      constructorInitializers: node.initializers,
      redirectedConstructor: node.redirectedConstructor,
      functionBody: node.body,
    );

    classMembers.add(Node(
      LibraryQualifiedName(uri, node.name?.name ?? ''),
      NodeKind.CONSTRUCTOR,
      api,
      impl,
      enclosingClass: enclosingClass,
    ));
  }

  void _addEnum(EnumDeclaration node) {
    var enumTokenSignature = _newApiSignatureBuilder().toByteList();

    var enumNode = Node(
      LibraryQualifiedName(uri, node.name.name),
      NodeKind.ENUM,
      Dependencies(enumTokenSignature, [], [], [], [], []),
      Dependencies.none,
    );

    Dependencies fieldDependencies;
    {
      var builder = _newApiSignatureBuilder();
      builder.addString(node.name.name);
      _appendTokens(builder, node.leftBracket, node.rightBracket);
      var tokenSignature = builder.toByteList();
      fieldDependencies = Dependencies(tokenSignature, [], [], [], [], []);
    }

    var members = <Node>[];
    for (var constant in node.constants) {
      members.add(Node(
        LibraryQualifiedName(uri, constant.name.name),
        NodeKind.GETTER,
        fieldDependencies,
        Dependencies.none,
        enclosingClass: enumNode,
      ));
    }

    members.add(Node(
      LibraryQualifiedName(uri, 'index'),
      NodeKind.GETTER,
      fieldDependencies,
      Dependencies.none,
      enclosingClass: enumNode,
    ));

    members.add(Node(
      LibraryQualifiedName(uri, 'values'),
      NodeKind.GETTER,
      fieldDependencies,
      Dependencies.none,
      enclosingClass: enumNode,
    ));

    members.sort(Node.compare);
    enumNode.setClassMembers(members);

    declaredNodes.add(enumNode);
  }

  /// Fill [exports] with information about exports.
  void _addExports() {
    for (var directive in units.first.directives) {
      if (directive is ExportDirective) {
        var refUri = directive.uri.stringValue;
        if (refUri != null) {
          var importUri = uri.resolve(refUri);
          var combinators = _getCombinators(directive);
          exports.add(Export(importUri, combinators));
        }
      }
    }
  }

  void _addFunction(FunctionDeclaration node) {
    var functionExpression = node.functionExpression;

    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendNodeTokens(builder, node.returnType);
    _appendNodeTokens(builder, functionExpression.typeParameters);
    _appendFormalParametersTokens(builder, functionExpression.parameters);
    var apiTokenSignature = builder.toByteList();

    var rawName = node.name.name;
    var name = LibraryQualifiedName(uri, node.isSetter ? '$rawName=' : rawName);

    NodeKind kind;
    if (node.isGetter) {
      kind = NodeKind.GETTER;
    } else if (node.isSetter) {
      kind = NodeKind.SETTER;
    } else {
      kind = NodeKind.FUNCTION;
    }

    var api = referenceCollector.collect(
      apiTokenSignature,
      thisNodeName: node.name.name,
      typeParameters: functionExpression.typeParameters,
      formalParameters: functionExpression.parameters,
      returnType: node.returnType,
    );

    var body = functionExpression.body;
    var implTokenSignature = _computeNodeTokenSignature(body);
    var impl = referenceCollector.collect(
      implTokenSignature,
      thisNodeName: node.name.name,
      formalParametersForImpl: functionExpression.parameters,
      functionBody: body,
    );

    declaredNodes.add(Node(name, kind, api, impl));
  }

  void _addFunctionTypeAlias(FunctionTypeAlias node) {
    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendNodeTokens(builder, node.typeParameters);
    _appendNodeTokens(builder, node.returnType);
    _appendFormalParametersTokens(builder, node.parameters);
    var apiTokenSignature = builder.toByteList();

    var api = referenceCollector.collect(
      apiTokenSignature,
      thisNodeName: node.name.name,
      typeParameters: node.typeParameters,
      formalParameters: node.parameters,
      returnType: node.returnType,
    );

    declaredNodes.add(Node(
      LibraryQualifiedName(uri, node.name.name),
      NodeKind.FUNCTION_TYPE_ALIAS,
      api,
      Dependencies.none,
    ));
  }

  void _addGenericTypeAlias(GenericTypeAlias node) {
    // TODO(scheglov) Support all types.
    var functionType = node.functionType;

    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendNodeTokens(builder, node.typeParameters);
    _appendNodeTokens(builder, functionType?.returnType);
    _appendNodeTokens(builder, functionType?.typeParameters);
    _appendFormalParametersTokens(builder, functionType?.parameters);
    var apiTokenSignature = builder.toByteList();

    var api = referenceCollector.collect(
      apiTokenSignature,
      typeParameters: node.typeParameters,
      typeParameters2: functionType?.typeParameters,
      formalParameters: functionType?.parameters,
      returnType: functionType?.returnType,
    );

    declaredNodes.add(Node(
      LibraryQualifiedName(uri, node.name.name),
      NodeKind.GENERIC_TYPE_ALIAS,
      api,
      Dependencies.none,
    ));
  }

  /// Fill [imports] with information about imports.
  void _addImports() {
    var hasDartCoreImport = false;
    for (var directive in units.first.directives) {
      if (directive is ImportDirective) {
        var refUri = directive.uri.stringValue;
        if (refUri == null) {
          continue;
        }

        var importUri = uri.resolve(refUri);

        if (importUri.toString() == 'dart:core') {
          hasDartCoreImport = true;
        }

        var combinators = _getCombinators(directive);

        var prefix = directive.prefix;
        imports.add(Import(importUri, prefix?.name, combinators));

        if (prefix != null) {
          referenceCollector.addImportPrefix(prefix.name);
        }
      }
    }

    if (!hasDartCoreImport) {
      imports.add(Import(Uri.parse('dart:core'), null, []));
    }
  }

  void _addMethod(
    Node enclosingClass,
    List<Node> classMembers,
    MethodDeclaration node,
  ) {
    var builder = _newApiSignatureBuilder();
    _appendMetadataTokens(builder, node.metadata);
    _appendNodeTokens(builder, node.returnType);
    _appendNodeTokens(builder, node.typeParameters);
    _appendFormalParametersTokens(builder, node.parameters);
    var apiTokenSignature = builder.toByteList();

    NodeKind kind;
    if (node.isGetter) {
      kind = NodeKind.GETTER;
    } else if (node.isSetter) {
      kind = NodeKind.SETTER;
    } else {
      kind = NodeKind.METHOD;
    }

    // TODO(scheglov) metadata, here and everywhere
    var api = referenceCollector.collect(
      apiTokenSignature,
      enclosingClassName: enclosingClass.name.name,
      thisNodeName: node.name.name,
      typeParameters: node.typeParameters,
      formalParameters: node.parameters,
      returnType: node.returnType,
    );

    var implTokenSignature = _computeNodeTokenSignature(node.body);
    var impl = referenceCollector.collect(
      implTokenSignature,
      enclosingClassName: enclosingClass.name.name,
      thisNodeName: node.name.name,
      formalParametersForImpl: node.parameters,
      functionBody: node.body,
    );

    var name = LibraryQualifiedName(uri, node.name.name);
    classMembers.add(
      Node(name, kind, api, impl, enclosingClass: enclosingClass),
    );
  }

  void _addUnit(CompilationUnit unit) {
    for (var declaration in unit.declarations) {
      if (declaration is ClassOrMixinDeclaration) {
        _addClassOrMixin(declaration);
      } else if (declaration is ClassTypeAlias) {
        _addClassTypeAlias(declaration);
      } else if (declaration is EnumDeclaration) {
        _addEnum(declaration);
      } else if (declaration is FunctionDeclaration) {
        _addFunction(declaration);
      } else if (declaration is FunctionTypeAlias) {
        _addFunctionTypeAlias(declaration);
      } else if (declaration is GenericTypeAlias) {
        _addGenericTypeAlias(declaration);
      } else if (declaration is TopLevelVariableDeclaration) {
        _addVariables(
          null,
          declaredNodes,
          declaration.metadata,
          declaration.variables,
          false,
        );
      } else {
        throw UnimplementedError('(${declaration.runtimeType}) $declaration');
      }
    }
  }

  void _addVariables(
    Node? enclosingClass,
    List<Node> variableNodes,
    List<Annotation> metadata,
    VariableDeclarationList variables,
    bool appendInitializerToApi,
  ) {
    if (variables.isConst || variables.type == null) {
      appendInitializerToApi = true;
    }

    for (var variable in variables.variables) {
      var initializer = variable.initializer;

      var builder = _newApiSignatureBuilder();
      builder.addInt(variables.isConst ? 1 : 0); // const flag
      _appendMetadataTokens(builder, metadata);
      _appendNodeTokens(builder, variables.type);
      if (appendInitializerToApi) {
        _appendNodeTokens(builder, initializer);
      }

      var apiTokenSignature = builder.toByteList();
      var api = referenceCollector.collect(
        apiTokenSignature,
        enclosingClassName: enclosingClass?.name.name,
        thisNodeName: variable.name.name,
        type: variables.type,
        expression: appendInitializerToApi ? initializer : null,
      );

      var implTokenSignature = _computeNodeTokenSignature(initializer);
      var impl = referenceCollector.collect(
        implTokenSignature,
        enclosingClassName: enclosingClass?.name.name,
        thisNodeName: variable.name.name,
        expression: initializer,
      );

      var rawName = variable.name.name;
      variableNodes.add(Node(
        LibraryQualifiedName(uri, rawName),
        NodeKind.GETTER,
        api,
        impl,
        enclosingClass: enclosingClass,
      ));

      if (!variables.isConst && !variables.isFinal) {
        // Note that one set of dependencies is enough for body.
        // So, the setter has empty "impl" dependencies.
        variableNodes.add(
          Node(
            LibraryQualifiedName(uri, '$rawName='),
            NodeKind.SETTER,
            api,
            Dependencies.none,
            enclosingClass: enclosingClass,
          ),
        );
      }
    }
  }

  /// Return the signature for all tokens of the [node].
  Uint8List _computeNodeTokenSignature(AstNode? node) {
    if (node == null) {
      return Uint8List(0);
    }
    return _computeTokenSignature(node.beginToken, node.endToken);
  }

  /// Return the signature for tokens from [begin] to [end] (both including).
  Uint8List _computeTokenSignature(Token begin, Token end) {
    var signature = _newApiSignatureBuilder();
    _appendTokens(signature, begin, end);
    return signature.toByteList();
  }

  /// Return a new signature builder, primed with the current context salts.
  ApiSignature _newApiSignatureBuilder() {
    var builder = ApiSignature();
    builder.addBytes(uriSignature);

    final enclosingClassNameSignature = this.enclosingClassNameSignature;
    if (enclosingClassNameSignature != null) {
      builder.addBytes(enclosingClassNameSignature);
    }

    return builder;
  }

  /// Append tokens of the given [parameters] to the [signature].
  static void _appendFormalParametersTokens(
      ApiSignature signature, FormalParameterList? parameters) {
    if (parameters == null) return;

    for (var parameter in parameters.parameters) {
      if (parameter.isRequiredPositional) {
        signature.addInt(1);
      } else if (parameter.isRequiredNamed) {
        signature.addInt(4);
      } else if (parameter.isOptionalPositional) {
        signature.addInt(2);
      } else if (parameter.isOptionalNamed) {
        signature.addInt(3);
      }

      // If a simple not named parameter, we don't need its name.
      // We should be careful to include also annotations.
      if (parameter is SimpleFormalParameter) {
        var type = parameter.type;
        if (type != null) {
          _appendTokens(signature, parameter.beginToken, type.endToken);
          continue;
        }
      }

      // We don't know anything better than adding the whole parameter.
      _appendNodeTokens(signature, parameter);
    }
  }

  static void _appendMetadataTokens(
      ApiSignature signature, List<Annotation> metadata) {
    for (var annotation in metadata) {
      _appendNodeTokens(signature, annotation);
    }
  }

  /// Append tokens of the given [node] to the [signature].
  static void _appendNodeTokens(ApiSignature signature, AstNode? node) {
    if (node != null) {
      _appendTokens(signature, node.beginToken, node.endToken);
    }
  }

  /// Append tokens from [begin] to [end] (both including) to the [signature].
  static void _appendTokens(ApiSignature signature, Token begin, Token end) {
    if (begin is CommentToken) {
      begin = begin.parent!;
    }

    Token? token = begin;
    while (token != null) {
      signature.addString(token.lexeme);

      if (token == end) {
        break;
      }

      var nextToken = token.next;
      if (nextToken == token) {
        break;
      }

      token = nextToken;
    }
  }

  /// Return [Combinator]s for the given import or export [directive].
  static List<Combinator> _getCombinators(NamespaceDirective directive) {
    var combinators = <Combinator>[];
    for (var combinator in directive.combinators) {
      if (combinator is ShowCombinator) {
        combinators.add(
          Combinator(
            true,
            combinator.shownNames.map((id) => id.name).toList(),
          ),
        );
      }
      if (combinator is HideCombinator) {
        combinators.add(
          Combinator(
            false,
            combinator.hiddenNames.map((id) => id.name).toList(),
          ),
        );
      }
    }
    return combinators;
  }
}
