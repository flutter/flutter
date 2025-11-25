// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'preview_detector.dart';
library;

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';

import '../base/logger.dart';
import 'preview_details.dart';
import 'utils.dart';

/// A path / URI pair used to map previews to a file.
///
/// We don't just use a path or a URI as the file watcher doesn't report URIs
/// (e.g., package:*) but the analyzer APIs do, and the code generator emits
/// package URIs for preview imports.
typedef PreviewPath = ({String path, Uri uri});

/// A mapping of file / library paths to dependency graph nodes containing details related to
/// previews defined within the file / library.
typedef PreviewDependencyGraph = Map<PreviewPath, LibraryPreviewNode>;

/// Visitor which detects previews and extracts [PreviewDetails] for later code
/// generation.
class _PreviewVisitor extends RecursiveAstVisitor<void> {
  _PreviewVisitor({required LibraryElement lib})
    : packageName = lib.uri.scheme == 'package' ? lib.uri.pathSegments.first : null;

  late final String? packageName;

  final previewEntries = <PreviewDetails>[];

  FunctionDeclaration? _currentFunction;
  ConstructorDeclaration? _currentConstructor;
  MethodDeclaration? _currentMethod;

  late Uri _currentScriptUri;
  late CompilationUnit _currentUnit;

  void findPreviewsInResolvedUnitResult(ResolvedUnitResult unit) {
    _currentScriptUri = unit.file.toUri();
    _currentUnit = unit.unit;
    _currentUnit.visitChildren(this);
  }

  /// Handles previews defined on top-level functions.
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    assert(_currentFunction == null);
    if (node.name.isPrivate) {
      return;
    }

    final TypeAnnotation? returnType = node.returnType;
    if (returnType == null || returnType.question != null) {
      return;
    }
    _scopedVisitChildren(node, (FunctionDeclaration? node) => _currentFunction = node);
  }

  /// Handles previews defined on constructors.
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _scopedVisitChildren(node, (ConstructorDeclaration? node) => _currentConstructor = node);
  }

  /// Handles previews defined on static methods within classes.
  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isStatic) {
      return;
    }
    _scopedVisitChildren(node, (MethodDeclaration? node) => _currentMethod = node);
  }

  bool hasRequiredParams(FormalParameterList? params) {
    return params?.parameters.any((p) => p.isRequired) ?? false;
  }

  @override
  void visitAnnotation(Annotation node) {
    final bool isMultiPreview = node.isMultiPreview;
    // Skip non-preview annotations.
    if (!node.isPreview && !isMultiPreview) {
      return;
    }
    // The preview annotations must only have constant arguments.
    final DartObject? preview = node.elementAnnotation!.computeConstantValue();
    if (preview == null) {
      return;
    }
    final LineInfo lineInfo = _currentUnit.lineInfo;
    final CharacterLocation location = lineInfo.getLocation(node.offset);
    final int line = location.lineNumber;
    final int column = location.columnNumber;
    if (_currentFunction != null &&
        !hasRequiredParams(_currentFunction!.functionExpression.parameters)) {
      final TypeAnnotation? returnTypeAnnotation = _currentFunction!.returnType;
      if (returnTypeAnnotation is NamedType) {
        final Token returnType = returnTypeAnnotation.name;
        if (returnType.isWidget || returnType.isWidgetBuilder) {
          previewEntries.add(
            PreviewDetails(
              scriptUri: _currentScriptUri,
              line: line,
              column: column,
              packageName: packageName,
              functionName: _currentFunction!.name.toString(),
              isBuilder: returnType.isWidgetBuilder,
              previewAnnotation: preview,
              isMultiPreview: isMultiPreview,
            ),
          );
        }
      }
    } else if (_currentConstructor != null && !hasRequiredParams(_currentConstructor!.parameters)) {
      final returnType = _currentConstructor!.returnType as SimpleIdentifier;
      final Token? name = _currentConstructor!.name;
      previewEntries.add(
        PreviewDetails(
          scriptUri: _currentScriptUri,
          line: line,
          column: column,
          packageName: packageName,
          functionName: '$returnType${name == null ? '' : '.$name'}',
          isBuilder: false,
          previewAnnotation: preview,
          isMultiPreview: isMultiPreview,
        ),
      );
    } else if (_currentMethod != null && !hasRequiredParams(_currentMethod!.parameters)) {
      final TypeAnnotation? returnTypeAnnotation = _currentMethod!.returnType;
      if (returnTypeAnnotation is NamedType) {
        final Token returnType = returnTypeAnnotation.name;
        if (returnType.isWidget || returnType.isWidgetBuilder) {
          final parentClass = _currentMethod!.parent! as ClassDeclaration;
          previewEntries.add(
            PreviewDetails(
              scriptUri: _currentScriptUri,
              line: line,
              column: column,
              packageName: packageName,
              functionName: '${parentClass.name}.${_currentMethod!.name}',
              isBuilder: returnType.isWidgetBuilder,
              previewAnnotation: preview,
              isMultiPreview: isMultiPreview,
            ),
          );
        }
      }
    }
  }

  void _scopedVisitChildren<T extends AstNode>(T node, void Function(T?) setter) {
    setter(node);
    node.visitChildren(this);
    setter(null);
  }
}

/// Contains all the information related to a library being watched by [PreviewDetector].
final class LibraryPreviewNode {
  LibraryPreviewNode({required LibraryElement library, required this.logger})
    : path = library.toPreviewPath() {
    final libraryFilePaths = <String>[
      for (final LibraryFragment fragment in library.fragments) fragment.source.fullName,
    ];
    files.addAll(libraryFilePaths);
  }

  final Logger logger;

  /// The path and URI pointing to the library.
  final PreviewPath path;

  /// The set of files contained in the library.
  final files = <String>[];

  /// The list of previews contained within the file.
  final previews = <PreviewDetails>[];

  /// Files that import this file.
  final dependedOnBy = <LibraryPreviewNode>{};

  /// Files this file imports.
  final dependsOn = <LibraryPreviewNode>{};

  /// `true` if a transitive dependency has compile time errors.
  ///
  /// IMPORTANT NOTE: this flag will not be set if there is a compile time error found in a
  /// transitive dependency outside the previewed project (e.g., in a path or Git dependency, or
  /// a modified package).
  // TODO(bkonyi): determine how to best handle compile time errors in non-analyzed dependencies.
  var dependencyHasErrors = false;

  /// `true` if this library contains compile time errors.
  bool get hasErrors => errors.isNotEmpty;

  /// The set of errors found in this library.
  final errors = <Diagnostic>[];

  /// Determines the set of errors found in this library.
  ///
  /// Results in [errors] being populated with the latest set of errors for the library.
  Future<void> populateErrors({required AnalysisContext context}) async {
    errors.clear();
    for (final String file in files) {
      final SomeErrorsResult errorsResult = await context.currentSession.getErrors(file);
      // If errorsResult isn't an ErrorsResult, the analysis context has likely been disposed and
      // we're in the process of shutting down. Ignore those results.
      if (errorsResult is ErrorsResult) {
        errors.addAll(
          errorsResult.diagnostics.where((error) => error.severity == Severity.error).toList(),
        );
      }
    }
  }

  /// Finds all previews defined in the [lib] and adds them to [previews].
  void findPreviews({required ResolvedLibraryResult lib}) {
    // Iterate over the compilation unit's AST to find previews.
    final visitor = _PreviewVisitor(lib: lib.element);
    lib.units.forEach(visitor.findPreviewsInResolvedUnitResult);
    previews
      ..clear()
      ..addAll(visitor.previewEntries);
  }

  /// Updates the dependency [graph] based on changes to a set of compilation [units].
  ///
  /// This method is responsible for:
  ///   - Inserting new nodes into the graph when new dependencies are introduced
  ///   - Computing the set of upstream and downstream dependencies of [units]
  void updateDependencyGraph({
    required PreviewDependencyGraph graph,
    required List<ResolvedUnitResult> units,
  }) {
    final updatedDependencies = <LibraryPreviewNode>{};

    for (final unit in units) {
      final LibraryFragment fragment = unit.libraryFragment;
      for (final LibraryImport importedLib in fragment.libraryImports) {
        if (importedLib.importedLibrary == null) {
          // This is an import for a file that's not analyzed (likely an import of a package from
          // the pub-cache) and isn't necessary to track as part of the dependency graph.
          continue;
        }
        final LibraryElement importedLibrary = importedLib.importedLibrary!;
        final LibraryPreviewNode result = graph.putIfAbsent(
          importedLibrary.toPreviewPath(),
          () => LibraryPreviewNode(library: importedLibrary, logger: logger),
        );
        updatedDependencies.add(result);
      }
    }

    final Set<LibraryPreviewNode> removedDependencies = dependsOn.difference(updatedDependencies);
    for (final removedDependency in removedDependencies) {
      removedDependency.dependedOnBy.remove(this);
    }

    dependsOn
      ..clear()
      ..addAll(updatedDependencies);

    dependencyHasErrors = false;
    for (final dependency in updatedDependencies) {
      dependency.dependedOnBy.add(this);
      if (dependency.dependencyHasErrors || dependency.errors.isNotEmpty) {
        logger.printWarning('Dependency ${dependency.path.uri} has errors');
        dependencyHasErrors = true;
      }
    }
  }

  @override
  String toString() {
    return '(errorCount: ${errors.length} dependencyHasErrors: $dependencyHasErrors '
        'previews: $previews dependedOnBy: ${dependedOnBy.length})';
  }
}
