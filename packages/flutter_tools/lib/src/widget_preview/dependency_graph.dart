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
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';

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
typedef PreviewDependencyGraph = Map<PreviewPath, PreviewDependencyNode>;

/// Visitor which detects previews and extracts [PreviewDetails] for later code
/// generation.
class _PreviewVisitor extends RecursiveAstVisitor<void> {
  final List<PreviewDetails> previewEntries = <PreviewDetails>[];

  FunctionDeclaration? _currentFunction;
  ConstructorDeclaration? _currentConstructor;
  MethodDeclaration? _currentMethod;
  PreviewDetails? _currentPreview;

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

  @override
  void visitAnnotation(Annotation node) {
    if (!node.isPreview) {
      return;
    }
    assert(_currentFunction != null || _currentConstructor != null || _currentMethod != null);
    if (_currentFunction != null) {
      final NamedType returnType = _currentFunction!.returnType! as NamedType;
      _currentPreview = PreviewDetails(
        functionName: _currentFunction!.name.toString(),
        isBuilder: returnType.name2.isWidgetBuilder,
      );
    } else if (_currentConstructor != null) {
      final SimpleIdentifier returnType = _currentConstructor!.returnType as SimpleIdentifier;
      final Token? name = _currentConstructor!.name;
      _currentPreview = PreviewDetails(
        functionName: '$returnType${name == null ? '' : '.$name'}',
        isBuilder: false,
      );
    } else if (_currentMethod != null) {
      final NamedType returnType = _currentMethod!.returnType! as NamedType;
      final ClassDeclaration parentClass = _currentMethod!.parent! as ClassDeclaration;
      _currentPreview = PreviewDetails(
        functionName: '${parentClass.name}.${_currentMethod!.name}',
        isBuilder: returnType.name2.isWidgetBuilder,
      );
    }
    node.visitChildren(this);
    previewEntries.add(_currentPreview!);
    _currentPreview = null;
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    // Extracts named properties from the @Preview annotation.
    _currentPreview?.setField(node: node);
  }

  void _scopedVisitChildren<T extends AstNode>(T node, void Function(T?) setter) {
    setter(node);
    node.visitChildren(this);
    setter(null);
  }
}

/// Contains all the information related to a file being watched by [PreviewDetector].
final class PreviewDependencyNode {
  PreviewDependencyNode({required this.previewPath, required this.logger});

  final Logger logger;

  /// The path and URI pointing to the file.
  final PreviewPath previewPath;

  /// The list of previews contained within the file.
  final List<PreviewDetails> filePreviews = <PreviewDetails>[];

  /// Files that import this file.
  final Set<PreviewDependencyNode> dependedOnBy = <PreviewDependencyNode>{};

  /// Files this file imports.
  final Set<PreviewDependencyNode> dependsOn = <PreviewDependencyNode>{};

  /// `true` if a transitive dependency has compile time errors.
  ///
  /// IMPORTANT NOTE: this flag will not be set if there is a compile time error found in a
  /// transitive dependency outside the previewed project (e.g., in a path or Git dependency, or
  /// a modified package).
  // TODO(bkonyi): determine how to best handle compile time errors in non-analyzed dependencies.
  bool dependencyHasErrors = false;

  /// `true` if this file contains compile time errors.
  bool get hasErrors => errors.isNotEmpty;

  /// The set of errors found in this file.
  final List<AnalysisError> errors = <AnalysisError>[];

  /// Determines the set of errors found in this file.
  ///
  /// Results in [errors] being populated with the latest set of errors for the file.
  Future<void> populateErrors({required AnalysisContext context}) async {
    errors
      ..clear()
      ..addAll(
        ((await context.currentSession.getErrors(previewPath.path)) as ErrorsResult).errors
            .where((AnalysisError error) => error.severity == Severity.error)
            .toList(),
      );
  }

  /// Finds all previews defined in [compilationUnit] and adds them to [filePreviews].
  void findPreviews({required CompilationUnit compilationUnit}) {
    // Iterate over the compilation unit's AST to find previews.
    final _PreviewVisitor visitor = _PreviewVisitor();
    compilationUnit.visitChildren(visitor);
    filePreviews
      ..clear()
      ..addAll(visitor.previewEntries);
  }

  /// Updates the dependency [graph] based on changes to a compilation [unit].
  ///
  /// This method is responsible for:
  ///   - Inserting new nodes into the graph when new dependencies are introduced
  ///   - Computing the set of upstream and downstream dependencies of [unit]
  void updateDependencyGraph({
    required PreviewDependencyGraph graph,
    required ResolvedUnitResult unit,
  }) {
    final Set<PreviewDependencyNode> updatedDependencies = <PreviewDependencyNode>{};
    final LibraryFragment fragment = unit.libraryFragment;
    for (final LibraryImport importedLib in fragment.libraryImports2) {
      for (final LibraryFragment importedFragment in importedLib.importedLibrary2!.fragments) {
        if (importedFragment == fragment) {
          // Don't include the current file as its own dependency.
          continue;
        }
        final PreviewDependencyNode result = graph.putIfAbsent(
          importedFragment.source.toPreviewPath(),
          () => PreviewDependencyNode(
            previewPath: importedFragment.source.toPreviewPath(),
            logger: logger,
          ),
        );
        updatedDependencies.add(result);
      }
    }

    final Set<PreviewDependencyNode> removedDependencies = dependsOn.difference(
      updatedDependencies,
    );
    for (final PreviewDependencyNode removedDependency in removedDependencies) {
      removedDependency.dependedOnBy.remove(this);
    }

    dependsOn
      ..clear()
      ..addAll(updatedDependencies);

    dependencyHasErrors = false;
    for (final PreviewDependencyNode dependency in updatedDependencies) {
      dependency.dependedOnBy.add(this);
      if (dependency.dependencyHasErrors || dependency.errors.isNotEmpty) {
        logger.printWarning('Dependency ${dependency.previewPath.uri} has errors');
        dependencyHasErrors = true;
      }
    }
  }

  @override
  String toString() {
    return '(errorCount: ${errors.length} dependencyHasErrors: $dependencyHasErrors '
        'previews: $filePreviews '
        'dependedOnBy: ${dependedOnBy.length})';
  }
}
