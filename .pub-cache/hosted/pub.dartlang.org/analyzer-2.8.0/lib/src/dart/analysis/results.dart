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

  @Deprecated('Use FileResult.path instead')
  @override
  final String path;

  @Deprecated('Use FileResult.uri instead')
  @override
  final Uri uri;

  AnalysisResultImpl(this.session, this.path, this.uri);
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

  ErrorsResultImpl(AnalysisSession session, String path, Uri uri,
      LineInfo lineInfo, bool isPart, this.errors)
      : super(session, path, uri, lineInfo, isPart);
}

class FileResultImpl extends AnalysisResultImpl implements FileResult {
  @override
  final LineInfo lineInfo;

  @override
  final bool isPart;

  FileResultImpl(
      AnalysisSession session, String path, Uri uri, this.lineInfo, this.isPart)
      : super(session, path, uri);

  @override
  // TODO(scheglov) Convert into a field.
  // ignore: deprecated_member_use_from_same_package, unnecessary_overrides
  String get path => super.path;

  @Deprecated('Check for specific Result subtypes instead')
  @override
  ResultState get state => ResultState.VALID;

  @override
  // TODO(scheglov) Convert into a field.
  // ignore: deprecated_member_use_from_same_package, unnecessary_overrides
  Uri get uri => super.uri;
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

  ParsedLibraryResultImpl(
      AnalysisSession session, String path, Uri uri, this.units)
      : super(session, path, uri);

  @Deprecated('Check for specific Result subtypes instead')
  @override
  ResultState get state {
    return ResultState.VALID;
  }

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

  @Deprecated('Check for specific Result subtypes instead')
  @override
  ResultState get state => ResultState.VALID;
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
  LineInfo get lineInfo => unit.lineInfo!;
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
}

class ResolvedLibraryResultImpl extends AnalysisResultImpl
    implements ResolvedLibraryResult {
  @override
  final LibraryElement element;

  @override
  final List<ResolvedUnitResult> units;

  ResolvedLibraryResultImpl(
      AnalysisSession session, String path, Uri uri, this.element, this.units)
      : super(session, path, uri);

  @Deprecated('Check for specific Result subtypes instead')
  @override
  ResultState get state {
    return ResultState.VALID;
  }

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

  @Deprecated('Check for specific Result subtypes instead')
  @override
  ResultState get state => ResultState.VALID;

  @override
  TypeProvider get typeProvider => libraryElement.typeProvider;

  @override
  TypeSystemImpl get typeSystem => libraryElement.typeSystem as TypeSystemImpl;
}

class UnitElementResultImpl extends FileResultImpl
    implements UnitElementResult {
  @override
  final String signature;

  @override
  final CompilationUnitElement element;

  UnitElementResultImpl(AnalysisSession session, String path, Uri uri,
      LineInfo lineInfo, bool isPart, this.signature, this.element)
      : super(session, path, uri, lineInfo, isPart);

  @Deprecated('Check for specific Result subtypes instead')
  @override
  ResultState get state => ResultState.VALID;
}

class _DeclarationByElementLocator extends GeneralizingAstVisitor<void> {
  final Element element;
  AstNode? result;

  _DeclarationByElementLocator(this.element);

  @override
  void visitNode(AstNode node) {
    if (result != null) return;

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

    super.visitNode(node);
  }

  bool _hasOffset(AstNode? node) {
    return node?.offset == element.nameOffset;
  }
}
