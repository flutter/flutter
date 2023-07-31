// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

abstract class AnalysisResultImpl implements AnalysisResult {
  @override
  final AnalysisSession session;

  AnalysisResultImpl(this.session);
}

class ElementDeclarationResultImpl implements ElementDeclarationResult {
  @override
  final Element element;

  @override
  final AstNode node;

  @override
  final ParsedUnitResult? parsedUnit;

  @override
  final ResolvedUnitResult? resolvedUnit;

  ElementDeclarationResultImpl(
      this.element, this.node, this.parsedUnit, this.resolvedUnit);
}

class ErrorsResultImpl extends FileResultImpl implements ErrorsResult {
  @override
  final List<AnalysisError> errors;

  ErrorsResultImpl(super.session, super.path, super.uri, super.lineInfo,
      super.isPart, this.errors);
}

class FileResultImpl extends AnalysisResultImpl implements FileResult {
  @override
  final String path;

  @override
  final Uri uri;

  @override
  final LineInfo lineInfo;

  @override
  final bool isPart;

  FileResultImpl(
      super.session, this.path, this.uri, this.lineInfo, this.isPart);
}

class LibraryElementResultImpl implements LibraryElementResult {
  @override
  final LibraryElement element;

  LibraryElementResultImpl(this.element);
}

class ParsedLibraryResultImpl extends AnalysisResultImpl
    implements ParsedLibraryResult {
  @override
  final List<ParsedUnitResult> units;

  ParsedLibraryResultImpl(super.session, this.units);

  @override
  ElementDeclarationResult? getElementDeclaration(Element element) {
    if (element is CompilationUnitElement ||
        element is LibraryElement ||
        element.isSynthetic ||
        element.nameOffset == -1) {
      return null;
    }

    var elementPath = element.source!.fullName;
    var unitResult = units.firstWhere(
      (r) => r.path == elementPath,
      orElse: () {
        var elementStr = element.getDisplayString(withNullability: true);
        throw ArgumentError('Element (${element.runtimeType}) $elementStr is '
            'not defined in this library.');
      },
    );

    var locator = _DeclarationByElementLocator(element);
    unitResult.unit.accept(locator);
    var declaration = locator.result;

    if (declaration == null) {
      return null;
    }

    return ElementDeclarationResultImpl(element, declaration, unitResult, null);
  }
}

class ParsedUnitResultImpl extends FileResultImpl implements ParsedUnitResult {
  @override
  final String content;

  @override
  final CompilationUnit unit;

  @override
  final List<AnalysisError> errors;

  ParsedUnitResultImpl(AnalysisSession session, String path, Uri uri,
      this.content, LineInfo lineInfo, bool isPart, this.unit, this.errors)
      : super(session, path, uri, lineInfo, isPart);
}

class ParseStringResultImpl implements ParseStringResult {
  @override
  final String content;

  @override
  final List<AnalysisError> errors;

  @override
  final CompilationUnit unit;

  ParseStringResultImpl(this.content, this.unit, this.errors);

  @override
  LineInfo get lineInfo => unit.lineInfo;
}

class ResolvedForCompletionResultImpl {
  final AnalysisSession analysisSession;
  final String path;
  final Uri uri;
  final bool exists;
  final String content;
  final LineInfo lineInfo;

  /// The full parsed unit.
  final CompilationUnit parsedUnit;

  /// The full element for the unit.
  final CompilationUnitElement unitElement;

  /// Nodes from [parsedUnit] that were resolved to provide enough context
  /// to perform completion. How much is enough depends on the location
  /// where resolution for completion was requested, and our knowledge
  /// how completion contributors work and what information they expect.
  ///
  /// This is usually a small subset of the whole unit - a method, a field.
  /// It could be even empty if the location does not provide any context
  /// information for any completion contributor, e.g. a type annotation.
  /// But it could be the whole unit as well, if the location is not something
  /// we have an optimization for.
  ///
  /// If this list is not empty, then the last node contains the requested
  /// offset. Other nodes are provided mostly FYI.
  final List<AstNode> resolvedNodes;

  ResolvedForCompletionResultImpl({
    required this.analysisSession,
    required this.path,
    required this.uri,
    required this.exists,
    required this.content,
    required this.lineInfo,
    required this.parsedUnit,
    required this.unitElement,
    required this.resolvedNodes,
  });

  LibraryElement get libraryElement => unitElement.enclosingElement;
}

class ResolvedLibraryResultImpl extends AnalysisResultImpl
    implements ResolvedLibraryResult {
  @override
  final LibraryElement element;

  @override
  final List<ResolvedUnitResult> units;

  ResolvedLibraryResultImpl(super.session, this.element, this.units);

  @override
  TypeProvider get typeProvider => element.typeProvider;

  @override
  ElementDeclarationResult? getElementDeclaration(Element element) {
    if (element is CompilationUnitElement ||
        element is LibraryElement ||
        element.isSynthetic ||
        element.nameOffset == -1) {
      return null;
    }

    var elementPath = element.source!.fullName;
    var unitResult = units.firstWhere(
      (r) => r.path == elementPath,
      orElse: () {
        var elementStr = element.getDisplayString(withNullability: true);
        throw ArgumentError('Element (${element.runtimeType}) $elementStr is '
            'not defined in this library.');
      },
    );

    var locator = _DeclarationByElementLocator(element);
    unitResult.unit.accept(locator);
    var declaration = locator.result;

    if (declaration == null) {
      return null;
    }

    return ElementDeclarationResultImpl(element, declaration, null, unitResult);
  }
}

class ResolvedUnitResultImpl extends FileResultImpl
    implements ResolvedUnitResult {
  @override
  final bool exists;

  @override
  final String content;

  @override
  final CompilationUnit unit;

  @override
  final List<AnalysisError> errors;

  ResolvedUnitResultImpl(
      AnalysisSession session,
      String path,
      Uri uri,
      this.exists,
      this.content,
      LineInfo lineInfo,
      bool isPart,
      this.unit,
      this.errors)
      : super(session, path, uri, lineInfo, isPart);

  @override
  LibraryElement get libraryElement {
    return unit.declaredElement!.library;
  }

  @override
  TypeProvider get typeProvider => libraryElement.typeProvider;

  @override
  TypeSystemImpl get typeSystem => libraryElement.typeSystem as TypeSystemImpl;
}

class UnitElementResultImpl extends FileResultImpl
    implements UnitElementResult {
  @override
  final CompilationUnitElement element;

  UnitElementResultImpl(super.session, super.path, super.uri, super.lineInfo,
      super.isPart, this.element);
}

/// A visitor which locates the [AstNode] which declares [element].
class _DeclarationByElementLocator extends UnifyingAstVisitor<void> {
  // TODO: This visitor could be further optimized by special casing each static
  // type of [element]. For example, for library-level elements (classes etc),
  // we can iterate over the compilation unit's declarations.

  final Element element;
  final int _nameOffset;
  AstNode? result;

  _DeclarationByElementLocator(this.element) : _nameOffset = element.nameOffset;

  @override
  void visitNode(AstNode node) {
    if (result != null) return;

    if (node.endToken.end < _nameOffset || node.offset > _nameOffset) {
      return;
    }

    if (element is ClassElement) {
      if (node is ClassOrMixinDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      } else if (node is ClassTypeAlias) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      } else if (node is EnumDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      }
    } else if (element is ConstructorElement) {
      if (node is ConstructorDeclaration) {
        if (node.name != null) {
          if (_hasOffset(node.name)) {
            result = node;
          }
        } else {
          if (_hasOffset(node.returnType)) {
            result = node;
          }
        }
      }
    } else if (element is ExtensionElement) {
      if (node is ExtensionDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      }
    } else if (element is FieldElement) {
      if (node is EnumConstantDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      } else if (node is VariableDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      }
    } else if (element is FunctionElement) {
      if (node is FunctionDeclaration && _hasOffset(node.name)) {
        result = node;
      }
    } else if (element is LocalVariableElement) {
      if (node is VariableDeclaration && _hasOffset(node.name)) {
        result = node;
      }
    } else if (element is MethodElement) {
      if (node is MethodDeclaration && _hasOffset(node.name)) {
        result = node;
      }
    } else if (element is ParameterElement) {
      if (node is FormalParameter && _hasOffset(node.identifier)) {
        result = node;
      }
    } else if (element is PropertyAccessorElement) {
      if (node is FunctionDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      } else if (node is MethodDeclaration) {
        if (_hasOffset(node.name)) {
          result = node;
        }
      }
    } else if (element is TopLevelVariableElement) {
      if (node is VariableDeclaration && _hasOffset(node.name)) {
        result = node;
      }
    }

    if (result == null) {
      node.visitChildren(this);
    }
  }

  bool _hasOffset(AstNode? node) {
    return node?.offset == _nameOffset;
  }
}
