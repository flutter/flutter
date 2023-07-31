// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/comment_reference_resolver.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/super_context.dart';

/// An object used by instances of [ResolverVisitor] to resolve references
/// within the AST structure to the elements being referenced. The requirements
/// for the element resolver are:
///
/// 1. Every [SimpleIdentifier] should be resolved to the element to which it
///    refers. Specifically:
///    * An identifier within the declaration of that name should resolve to the
///      element being declared.
///    * An identifier denoting a prefix should resolve to the element
///      representing the import that defines the prefix (an [LibraryImportElement]).
///    * An identifier denoting a variable should resolve to the element
///      representing the variable (a [VariableElement]).
///    * An identifier denoting a parameter should resolve to the element
///      representing the parameter (a [ParameterElement]).
///    * An identifier denoting a field should resolve to the element
///      representing the getter or setter being invoked (a
///      [PropertyAccessorElement]).
///    * An identifier denoting the name of a method or function being invoked
///      should resolve to the element representing the method or function (an
///      [ExecutableElement]).
///    * An identifier denoting a label should resolve to the element
///      representing the label (a [LabelElement]).
///    The identifiers within directives are exceptions to this rule and are
///    covered below.
/// 2. Every node containing a token representing an operator that can be
///    overridden ( [BinaryExpression], [PrefixExpression], [PostfixExpression])
///    should resolve to the element representing the method invoked by that
///    operator (a [MethodElement]).
/// 3. Every [FunctionExpressionInvocation] should resolve to the element
///    representing the function being invoked (a [FunctionElement]). This will
///    be the same element as that to which the name is resolved if the function
///    has a name, but is provided for those cases where an unnamed function is
///    being invoked.
/// 4. Every [LibraryDirective] and [PartOfDirective] should resolve to the
///    element representing the library being specified by the directive (a
///    [LibraryElement]) unless, in the case of a part-of directive, the
///    specified library does not exist.
/// 5. Every [ImportDirective] and [ExportDirective] should resolve to the
///    element representing the library being specified by the directive unless
///    the specified library does not exist (an [LibraryImportElement] or
///    [LibraryExportElement]).
/// 6. The identifier representing the prefix in an [ImportDirective] should
///    resolve to the element representing the prefix (a [PrefixElement]).
/// 7. The identifiers in the hide and show combinators in [ImportDirective]s
///    and [ExportDirective]s should resolve to the elements that are being
///    hidden or shown, respectively, unless those names are not defined in the
///    specified library (or the specified library does not exist).
/// 8. Every [PartDirective] should resolve to the element representing the
///    compilation unit being specified by the string unless the specified
///    compilation unit does not exist (a [CompilationUnitElement]).
///
/// Note that AST nodes that would represent elements that are not defined are
/// not resolved to anything. This includes such things as references to
/// undeclared variables (which is an error) and names in hide and show
/// combinators that are not defined in the imported library (which is not an
/// error).
class ElementResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElement _definingLibrary;

  final MethodInvocationResolver _methodInvocationResolver;

  late final _commentReferenceResolver =
      CommentReferenceResolver(_typeProvider, _resolver);

  /// Initialize a newly created visitor to work for the given [_resolver] to
  /// resolve the nodes in a compilation unit.
  ElementResolver(this._resolver,
      {MigratableAstInfoProvider migratableAstInfoProvider =
          const MigratableAstInfoProvider()})
      : _definingLibrary = _resolver.definingLibrary,
        _methodInvocationResolver = MethodInvocationResolver(
          _resolver,
          migratableAstInfoProvider,
          inferenceHelper: _resolver.inferenceHelper,
        );

  /// Return `true` iff the current enclosing function is a constant constructor
  /// declaration.
  bool get isInConstConstructor {
    var function = _resolver.enclosingFunction;
    if (function is ConstructorElement) {
      return function.isConst;
    }
    return false;
  }

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  void visitAugmentationImportDirective(AugmentationImportDirectiveImpl node) {
    _resolveAnnotations(node.metadata);
  }

  void visitClassDeclaration(ClassDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitClassTypeAlias(ClassTypeAlias node) {
    _resolveAnnotations(node.metadata);
  }

  void visitCommentReference(CommentReference node) {
    _commentReferenceResolver.resolve(node);
  }

  void visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorElement element = node.declaredElement!;
    if (element is ConstructorElementImpl) {
      var redirectedNode = node.redirectedConstructor;
      if (redirectedNode != null) {
        // set redirected factory constructor
        var redirectedElement = redirectedNode.staticElement;
        element.redirectedConstructor = redirectedElement;
      } else {
        // set redirected generative constructor
        for (ConstructorInitializer initializer in node.initializers) {
          if (initializer is RedirectingConstructorInvocation) {
            var redirectedElement = initializer.staticElement;
            element.redirectedConstructor = redirectedElement;
          }
        }
      }
      _resolveAnnotations(node.metadata);
    }
  }

  void visitConstructorFieldInitializer(
      covariant ConstructorFieldInitializerImpl node) {
    var fieldName = node.fieldName;
    final enclosingClass = _resolver.enclosingClass!;
    var fieldElement = enclosingClass.getField(fieldName.name);
    fieldName.staticElement = fieldElement;
  }

  void visitConstructorName(covariant ConstructorNameImpl node) {
    var type = node.type.type;
    if (type == null) {
      return;
    }
    if (type.isDynamic) {
      // Nothing to do.
    } else if (type is InterfaceType) {
      // look up ConstructorElement
      ConstructorElement? constructor;
      var name = node.name;
      if (name == null) {
        constructor = type.lookUpConstructor(null, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
      } else {
        constructor = type.lookUpConstructor(name.name, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
        name.staticElement = constructor;
      }
      node.staticElement = constructor;
    }
  }

  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    _resolveAnnotations(node.metadata);
  }

  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitEnumDeclaration(EnumDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitExportDirective(ExportDirective node) {
    var exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid
      // TODO(brianwilkerson) Figure out whether the element can ever be
      // something other than an ExportElement
      _resolveCombinators(exportElement.exportedLibrary, node.combinators);
      _resolveAnnotations(node.metadata);
    }
  }

  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitFieldDeclaration(FieldDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitFieldFormalParameter(FieldFormalParameter node) {
    _resolveMetadataForParameter(node);
  }

  void visitFunctionDeclaration(FunctionDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _resolveAnnotations(node.metadata);
  }

  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _resolveMetadataForParameter(node);
  }

  void visitGenericTypeAlias(GenericTypeAlias node) {
    _resolveAnnotations(node.metadata);
  }

  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var prefixNode = node.prefix;
    if (prefixNode != null) {
      String prefixName = prefixNode.name;
      List<PrefixElement> prefixes = _definingLibrary.prefixes;
      int count = prefixes.length;
      for (int i = 0; i < count; i++) {
        PrefixElement prefixElement = prefixes[i];
        if (prefixElement.displayName == prefixName) {
          prefixNode.staticElement = prefixElement;
          break;
        }
      }
    }
    var importElement = node.element;
    if (importElement != null) {
      // The element is null when the URI is invalid
      var library = importElement.importedLibrary;
      if (library != null) {
        _resolveCombinators(library, node.combinators);
      }
      _resolveAnnotations(node.metadata);
    }
  }

  void visitInstanceCreationExpression(
      covariant InstanceCreationExpressionImpl node) {
    var invokedConstructor = node.constructorName.staticElement;
    var argumentList = node.argumentList;
    var parameters =
        _resolveArgumentsToFunction(argumentList, invokedConstructor);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  void visitLibraryAugmentationDirective(LibraryAugmentationDirective node) {
    _resolveAnnotations(node.metadata);
  }

  void visitLibraryDirective(LibraryDirective node) {
    _resolveAnnotations(node.metadata);
  }

  void visitMethodDeclaration(MethodDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitMethodInvocation(MethodInvocation node,
      {List<WhyNotPromotedGetter>? whyNotPromotedList,
      required DartType? contextType}) {
    whyNotPromotedList ??= [];
    _methodInvocationResolver.resolve(
        node as MethodInvocationImpl, whyNotPromotedList,
        contextType: contextType);
  }

  void visitMixinDeclaration(MixinDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitPartDirective(PartDirective node) {
    _resolveAnnotations(node.metadata);
  }

  void visitPartOfDirective(PartOfDirective node) {
    _resolveAnnotations(node.metadata);
  }

  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {
    _resolveAnnotations(node.metadata);
  }

  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {
    _resolveAnnotations(node.metadata);
  }

  void visitRedirectingConstructorInvocation(
      covariant RedirectingConstructorInvocationImpl node) {
    var enclosingClass = _resolver.enclosingClass;
    if (enclosingClass is! InterfaceElement) {
      // TODO(brianwilkerson) Report this error.
      return;
    }
    ConstructorElement? element;
    var name = node.constructorName;
    if (name == null) {
      element = enclosingClass.unnamedConstructor;
    } else {
      element = enclosingClass.getNamedConstructor(name.name);
    }
    if (element == null) {
      // TODO(brianwilkerson) Report this error and decide what element to
      // associate with the node.
      return;
    }
    if (name != null) {
      name.staticElement = element;
    }
    node.staticElement = element;
    var argumentList = node.argumentList;
    var parameters = _resolveArgumentsToFunction(argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _resolveMetadataForParameter(node);
  }

  void visitSuperConstructorInvocation(
      covariant SuperConstructorInvocationImpl node) {
    var enclosingClass = _resolver.enclosingClass;
    if (enclosingClass is! InterfaceElement) {
      // TODO(brianwilkerson) Report this error.
      return;
    }
    var superType = enclosingClass.supertype;
    if (superType == null) {
      // TODO(brianwilkerson) Report this error.
      return;
    }
    var name = node.constructorName;
    var superName = name?.name;
    var element = superType.lookUpConstructor(superName, _definingLibrary);
    element = _resolver.toLegacyElement(element);
    if (element == null || !element.isAccessibleIn(_definingLibrary)) {
      if (name != null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER,
            node,
            [superType, name.name]);
      } else {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
            node,
            [superType]);
      }
      return;
    } else {
      if (element.isFactory &&
          // Check if we've reported [NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS].
          !element.enclosingElement.constructors
              .every((constructor) => constructor.isFactory)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node, [element]);
      }
    }
    if (name != null) {
      name.staticElement = element;
    }
    node.staticElement = element;
    // TODO(brianwilkerson) Defer this check until we know there's an error (by
    // in-lining _resolveArgumentsToFunction below).
    var declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    var superclassName = declaration?.extendsClause?.superclass.name;
    if (superclassName != null &&
        _resolver.definingLibrary
            .shouldIgnoreUndefinedIdentifier(superclassName)) {
      return;
    }
    var argumentList = node.argumentList;
    var parameters = _resolveArgumentsToFunction(
      argumentList,
      element,
      enclosingConstructor: node.thisOrAncestorOfType<ConstructorDeclaration>(),
    );
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  void visitSuperExpression(SuperExpression node) {
    var context = SuperContext.of(node);
    if (context == SuperContext.annotation || context == SuperContext.static) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, node);
    } else if (context == SuperContext.extension) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_EXTENSION, node);
    }
  }

  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  void visitTypeParameter(TypeParameter node) {
    _resolveAnnotations(node.metadata);
  }

  void visitVariableDeclarationList(VariableDeclarationList node) {
    _resolveAnnotations(node.metadata);
  }

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to
  /// the list of arguments. An error will be reported if any of the arguments
  /// cannot be matched to a parameter. Return the parameters that correspond to
  /// the arguments, or `null` if no correspondence could be computed.
  List<ParameterElement?>? _resolveArgumentsToFunction(
    ArgumentList argumentList,
    ExecutableElement? executableElement, {
    ConstructorDeclaration? enclosingConstructor,
  }) {
    if (executableElement == null) {
      return null;
    }
    return ResolverVisitor.resolveArgumentsToParameters(
      argumentList: argumentList,
      parameters: executableElement.parameters,
      errorReporter: _errorReporter,
      enclosingConstructor: enclosingConstructor,
    );
  }

  /// Resolve the names in the given [combinators] in the scope of the given
  /// [library].
  void _resolveCombinators(
      LibraryElement? library, NodeList<Combinator> combinators) {
    if (library == null) {
      //
      // The library will be null if the directive containing the combinators
      // has a URI that is not valid.
      //
      return;
    }
    Namespace namespace =
        NamespaceBuilder().createExportNamespaceForLibrary(library);
    for (Combinator combinator in combinators) {
      NodeList<SimpleIdentifier> names;
      if (combinator is HideCombinator) {
        names = combinator.hiddenNames;
      } else {
        names = (combinator as ShowCombinator).shownNames;
      }
      for (var name in names) {
        name as SimpleIdentifierImpl;
        String nameStr = name.name;
        var element = namespace.get(nameStr) ?? namespace.get("$nameStr=");
        if (element != null) {
          // Ensure that the name always resolves to a top-level variable
          // rather than a getter or setter
          if (element is PropertyAccessorElement) {
            name.staticElement = element.variable;
          } else {
            name.staticElement = element;
          }
        }
      }
    }
  }

  /// Given a [node] that can have annotations associated with it, resolve the
  /// annotations in the element model representing annotations to the node.
  void _resolveMetadataForParameter(NormalFormalParameter node) {
    _resolveAnnotations(node.metadata);
  }

  /// Checks whether the given [expression] is a reference to a class. If it is
  /// then the element representing the class is returned, otherwise `null` is
  /// returned.
  static InterfaceElement? getTypeReference(Expression expression) {
    if (expression is Identifier) {
      var element = expression.staticElement;
      if (element is InterfaceElement) {
        return element;
      } else if (element is TypeAliasElement) {
        var aliasedType = element.aliasedType;
        if (aliasedType is InterfaceType) {
          return aliasedType.element;
        }
      }
    }
    return null;
  }

  /// Resolve each of the annotations in the given list of [annotations].
  static void _resolveAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      var elementAnnotation =
          annotation.elementAnnotation as ElementAnnotationImpl?;
      if (elementAnnotation != null) {
        elementAnnotation.element = annotation.element;
      }
    }
  }
}

/// An identifier that can be used to look up names in the lexical scope when
/// there is no identifier in the AST structure. There is no identifier in the
/// AST when the parser could not distinguish between a method invocation and an
/// invocation of a top-level function imported with a prefix.
class SyntheticIdentifier implements SimpleIdentifier {
  @override
  final String name;

  SyntheticIdentifier(this.name);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
