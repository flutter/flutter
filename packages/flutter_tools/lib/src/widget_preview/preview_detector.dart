// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/source.dart';
import 'package:watcher/watcher.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/utils.dart';

/// A path / URI pair used to map previews to a file.
///
/// We don't just use a path or a URI as the file watcher doesn't report URIs
/// (e.g., package:*) but the analyzer APIs do, and the code generator emits
/// package URIs for preview imports.
typedef PreviewPath = ({String path, Uri uri});

/// A mapping of file / library paths to dependency graph nodes containing details related to
/// previews defined within the file / library.
typedef PreviewDependencyGraph = Map<PreviewPath, PreviewDependencyNode>;

extension on Token {
  /// Convenience getter to identify tokens for private fields and functions.
  bool get isPrivate => toString().startsWith('_');

  /// Convenience getter to identify WidgetBuilder types.
  bool get isWidgetBuilder => toString() == 'WidgetBuilder';
}

extension on Annotation {
  /// Convenience getter to identify `@Preview` annotations
  bool get isPreview => name.name == 'Preview';
}

/// Convenience getters for examining [String] paths.
extension on String {
  bool get isDartFile => endsWith('.dart');
  bool get isPubspec => endsWith('pubspec.yaml');
  bool get doesContainDartTool => contains('.dart_tool');
}

extension on ParsedUnitResult {
  /// Convenience method to package [path] and [uri] into a [PreviewPath]
  PreviewPath toPreviewPath() => (path: path, uri: uri);
}

extension on Source {
  /// Convenience method to package [fullName] and [uri] into a [PreviewPath]
  PreviewPath toPreviewPath() => (path: fullName, uri: uri);
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
    final PreviewVisitor visitor = PreviewVisitor();
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

/// Contains details related to a single preview instance.
final class PreviewDetails {
  PreviewDetails({required this.functionName, required this.isBuilder});

  static const String kName = 'name';
  static const String kSize = 'size';
  static const String kTextScaleFactor = 'textScaleFactor';
  static const String kWrapper = 'wrapper';
  static const String kTheme = 'theme';
  static const String kBrightness = 'brightness';
  static const String kLocalizations = 'localizations';

  /// The name of the function returning the preview.
  final String functionName;

  /// Set to `true` if the preview function is returning a `WidgetBuilder`
  /// instead of a `Widget`.
  final bool isBuilder;

  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  Expression? get name => _name;
  Expression? _name;

  /// Artificial constraints to be applied to the `child`.
  ///
  /// If not provided, the previewed widget will attempt to set its own
  /// constraints and may result in an unbounded constraint error.
  Expression? get size => _size;
  Expression? _size;

  /// Applies font scaling to text within the `child`.
  ///
  /// If not provided, the default text scaling factor provided by `MediaQuery`
  /// will be used.
  Expression? get textScaleFactor => _textScaleFactor;
  Expression? _textScaleFactor;

  /// The name of a tear-off used to wrap the `Widget` returned by the preview
  /// function defined by [functionName].
  ///
  /// If not provided, the `Widget` returned by [functionName] will be used by
  /// the previewer directly.
  Identifier? get wrapper => _wrapper;
  Identifier? _wrapper;

  /// Set to `true` if `wrapper` is set.
  bool get hasWrapper => _wrapper != null;

  /// A callback to return Material and Cupertino theming data to be applied
  /// to the previewed `Widget`.
  Identifier? get theme => _theme;
  Identifier? _theme;

  /// Sets the initial theme brightness.
  ///
  /// If not provided, the current system default brightness will be used.
  Expression? get brightness => _brightness;
  Expression? _brightness;

  Expression? get localizations => _localizations;
  Expression? _localizations;

  void _setField({required NamedExpression node}) {
    final String key = node.name.label.name;
    final Expression expression = node.expression;
    switch (key) {
      case kName:
        _name = expression;
      case kSize:
        _size = expression;
      case kTextScaleFactor:
        _textScaleFactor = expression;
      case kWrapper:
        _wrapper = expression as Identifier;
      case kTheme:
        _theme = expression as Identifier;
      case kBrightness:
        _brightness = expression;
      case kLocalizations:
        _localizations = expression;
      default:
        throw StateError('Unknown Preview field "$name": ${expression.toSource()}');
    }
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is PreviewDetails &&
        other.functionName == functionName &&
        other.isBuilder == isBuilder &&
        other.size == size &&
        other.textScaleFactor == textScaleFactor &&
        other.wrapper == wrapper &&
        other.theme == theme &&
        other.brightness == brightness &&
        other.localizations == localizations;
  }

  @override
  String toString() =>
      'PreviewDetails(function: $functionName isBuilder: $isBuilder $kName: $name '
      '$kSize: $size $kTextScaleFactor: $textScaleFactor $kWrapper: $wrapper '
      '$kTheme: $theme $kBrightness: $_brightness $kLocalizations: $_localizations)';

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(<Object?>[
    functionName,
    isBuilder,
    size,
    textScaleFactor,
    wrapper,
    theme,
    brightness,
    localizations,
  ]);
}

class PreviewDetector {
  PreviewDetector({
    required this.projectRoot,
    required this.fs,
    required this.logger,
    required this.onChangeDetected,
    required this.onPubspecChangeDetected,
  });

  final Directory projectRoot;
  final FileSystem fs;
  final Logger logger;
  final void Function(PreviewDependencyGraph) onChangeDetected;
  final void Function() onPubspecChangeDetected;

  StreamSubscription<WatchEvent>? _fileWatcher;
  final PreviewDetectorMutex _mutex = PreviewDetectorMutex();
  final PreviewDependencyGraph _dependencyGraph = PreviewDependencyGraph();

  late final AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[projectRoot.absolute.path],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  /// Starts listening for changes to Dart sources under [projectRoot] and returns
  /// the initial [PreviewDependencyGraph] for the project.
  Future<PreviewDependencyGraph> initialize() async {
    // Find the initial set of previews.
    await _findPreviewFunctions(projectRoot);

    // Determine which files have transitive dependencies with compile time errors.
    _propagateErrors();

    final Watcher watcher = Watcher(projectRoot.path);
    _fileWatcher = watcher.events.listen(_onFileSystemEvent);

    // Wait for file watcher to finish initializing, otherwise we might miss changes and cause
    // tests to flake.
    await watcher.ready;
    return _dependencyGraph;
  }

  Future<void> dispose() async {
    // Guard disposal behind a mutex to make sure the analyzer has finished
    // processing the latest file updates to avoid throwing an exception.
    await _mutex.runGuarded(() async {
      await _fileWatcher?.cancel();
      await collection.dispose();
    });
  }

  Future<void> _onFileSystemEvent(WatchEvent event) async {
    // Only process one FileSystemEntity at a time so we don't invalidate an AnalysisSession that's
    // in use when we call context.changeFile(...).
    await _mutex.runGuarded(() async {
      final String eventPath = event.path;
      // If the pubspec has changed, new dependencies or assets could have been added, requiring
      // the preview scaffold's pubspec to be updated.
      if (eventPath.isPubspec && !eventPath.doesContainDartTool) {
        onPubspecChangeDetected();
        return;
      }
      // Only trigger a reload when changes to Dart sources are detected. We
      // ignore the generated preview file to avoid getting stuck in a loop.
      if (!eventPath.isDartFile || eventPath.doesContainDartTool) {
        return;
      }

      // TODO(bkonyi): investigate batching change detection to handle cases where directories are
      // deleted or moved. Currently, analysis, preview detection, and error propagation will be
      // performed for each file contained in a modified directory (i.e., moved or deleted). This
      // will likely cause performance issues when performing large directory operations,
      // particularly for large projects.
      //
      // Unfortunately, package:watcher doesn't report changes to directories, only individual
      // files. However, it does have a batching mechanism under the hood in the BatchEvents
      // extension which may be worth using here.

      // We need to notify the analyzer that this file has changed so it can reanalyze the file.
      final AnalysisContext context = collection.contexts.single;
      final File file = fs.file(eventPath);
      context.changeFile(file.path);
      await context.applyPendingFileChanges();

      logger.printStatus('Detected change in $eventPath.');
      if (event.type == ChangeType.REMOVE) {
        await _fileRemoved(context: context, eventPath: eventPath);
      } else {
        await _fileAddedOrUpdated(context: context, eventPath: eventPath);
      }
      // Determine which files have transitive dependencies with compile time errors.
      _propagateErrors();
      onChangeDetected(_dependencyGraph);
    });
  }

  Future<void> _fileAddedOrUpdated({
    required AnalysisContext context,
    required String eventPath,
  }) async {
    final PreviewDependencyGraph filePreviewsMapping = await _findPreviewFunctions(
      fs.file(eventPath),
    );
    if (filePreviewsMapping.length > 1) {
      logger.printWarning('Previews from more than one file were detected!');
      logger.printWarning('Previews: $filePreviewsMapping');
    }

    if (filePreviewsMapping.isNotEmpty) {
      // The set of previews has changed, but there are still previews in the file.
      final MapEntry<PreviewPath, PreviewDependencyNode>(
        key: PreviewPath location,
        value: PreviewDependencyNode fileDetails,
      ) = filePreviewsMapping.entries.single;
      logger.printStatus('Updated previews for ${location.uri}: ${fileDetails.filePreviews}');
      _dependencyGraph[location] = fileDetails;
    } else {
      // Why is this working with an empty file system on Linux?
      final PreviewPath removedPath = _dependencyGraph.keys.firstWhere(
        (PreviewPath element) => element.path == eventPath,
      );
      // The file previously had previews that were removed.
      logger.printStatus('Previews removed from $eventPath');
      _dependencyGraph.remove(removedPath);
    }
  }

  /// Search for functions annotated with `@Preview` in the current project.
  Future<PreviewDependencyGraph> _findPreviewFunctions(FileSystemEntity entity) async {
    final PreviewDependencyGraph updatedPreviews = PreviewDependencyGraph();

    final AnalysisContext context = collection.contexts.single;
    logger.printStatus('Finding previews in ${entity.path}...');
    for (final String filePath in context.contextRoot.analyzedFiles()) {
      logger.printTrace('Checking file: $filePath');
      if (!filePath.isDartFile || !filePath.startsWith(entity.path)) {
        logger.printTrace('Skipping $filePath');
        continue;
      }
      final SomeResolvedLibraryResult lib = await context.currentSession.getResolvedLibrary(
        filePath,
      );
      // TODO(bkonyi): ensure this can handle part files.
      if (lib is ResolvedLibraryResult) {
        for (final ResolvedUnitResult libUnit in lib.units) {
          final PreviewPath previewPath = libUnit.toPreviewPath();
          final PreviewDependencyNode previewForFile = _dependencyGraph.putIfAbsent(
            previewPath,
            () => PreviewDependencyNode(previewPath: previewPath, logger: logger),
          );
          previewForFile.updateDependencyGraph(graph: _dependencyGraph, unit: libUnit);
          updatedPreviews[previewPath] = previewForFile;

          // Check for errors in the compilation unit.
          await previewForFile.populateErrors(context: context);

          // Iterate over the compilation unit's AST to find previews.
          previewForFile.findPreviews(compilationUnit: libUnit.unit);
        }
      } else {
        logger.printWarning('Unknown library type at $filePath: $lib');
      }
    }
    final int previewCount = updatedPreviews.values.fold<int>(
      0,
      (int count, PreviewDependencyNode value) => count + value.filePreviews.length,
    );
    logger.printStatus('Found $previewCount ${pluralize('preview', previewCount)}.');
    return updatedPreviews;
  }

  /// Handles the deletion of a file from the target project.
  ///
  /// This involves removing the relevant [PreviewDependencyNode] from the dependency graph as well
  /// as checking for newly introduced errors in files which had a transitive dependency on the
  /// removed file.
  Future<void> _fileRemoved({required AnalysisContext context, required String eventPath}) async {
    final File file = fs.file(eventPath);
    final PreviewPath previewPath = _dependencyGraph.keys.firstWhere(
      (PreviewPath e) => e.path == file.path,
    );

    final Set<PreviewDependencyNode> visitedNodes = <PreviewDependencyNode>{};
    Future<void> populateErrorsDownstream({required PreviewDependencyNode node}) async {
      visitedNodes.add(node);
      await node.populateErrors(context: context);
      for (final PreviewDependencyNode downstream in node.dependedOnBy) {
        if (!visitedNodes.contains(downstream)) {
          await populateErrorsDownstream(node: downstream);
        }
      }
    }

    final PreviewDependencyNode node = _dependencyGraph.remove(previewPath)!;

    // Removing a file can cause errors to be introduced down the dependency chain, so all
    // downstream dependencies need to be checked for errors.
    for (final PreviewDependencyNode downstream in node.dependedOnBy) {
      downstream.dependsOn.remove(node);
      await populateErrorsDownstream(node: node);
    }
    for (final PreviewDependencyNode upstream in node.dependsOn) {
      upstream.dependedOnBy.remove(node);
    }
  }

  /// Determines which files in the project have transitive dependencies containing compile time
  /// errors, setting [PreviewDependencyNode.dependencyHasErrors] to true for files which
  /// would cause errors if imported into the previewer.
  // TODO(bkonyi): allow for processing a subset of files.
  void _propagateErrors() {
    final PreviewDependencyGraph previews = _dependencyGraph;

    // Reset the error state for all dependencies.
    for (final PreviewDependencyNode fileDetails in previews.values) {
      if (fileDetails.errors.isEmpty) {
        fileDetails.dependencyHasErrors = false;
      }
    }

    void propagateErrorsHelper(PreviewDependencyNode errorContainingNode) {
      for (final PreviewDependencyNode importer in errorContainingNode.dependedOnBy) {
        if (importer.dependencyHasErrors) {
          // This dependency path has already been processed.
          continue;
        }
        logger.printWarning('Propagating errors to: ${importer.previewPath.path}');
        importer.dependencyHasErrors = true;
        propagateErrorsHelper(importer);
      }
    }

    // Find the files that have errors and mark each of their downstream dependencies as having
    // a dependency containing errors.
    for (final PreviewDependencyNode nodeDetails in previews.values) {
      if (nodeDetails.errors.isNotEmpty) {
        logger.printWarning('${nodeDetails.previewPath.path} has errors.');
        propagateErrorsHelper(nodeDetails);
      }
    }
  }
}

/// Visitor which detects previews and extracts [PreviewDetails] for later code
/// generation.
class PreviewVisitor extends RecursiveAstVisitor<void> {
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
    _currentPreview?._setField(node: node);
  }

  void _scopedVisitChildren<T extends AstNode>(T node, void Function(T?) setter) {
    setter(node);
    node.visitChildren(this);
    setter(null);
  }
}

/// Used to protect global state accessed in blocks containing calls to
/// asynchronous methods.
///
/// Originally from DDS:
/// https://github.com/dart-lang/sdk/blob/3fe58da3cfe2c03fb9ee691a7a4709082fad3e73/pkg/dds/lib/src/utils/mutex.dart
class PreviewDetectorMutex {
  /// Executes a block of code containing asynchronous calls atomically.
  ///
  /// If no other asynchronous context is currently executing within
  /// [criticalSection], it will immediately be called. Otherwise, the
  /// caller will be suspended and entered into a queue to be resumed once the
  /// lock is released.
  Future<T> runGuarded<T>(FutureOr<T> Function() criticalSection) async {
    try {
      await _acquireLock();
      return await criticalSection();
    } finally {
      _releaseLock();
    }
  }

  Future<void> _acquireLock() async {
    if (!_locked) {
      _locked = true;
      return;
    }

    final Completer<void> request = Completer<void>();
    _outstandingRequests.add(request);
    await request.future;
  }

  void _releaseLock() {
    if (_outstandingRequests.isNotEmpty) {
      final Completer<void> request = _outstandingRequests.removeFirst();
      request.complete();
      return;
    }
    // Only release the lock if no other requests are pending to prevent races
    // between the next request from the queue to be handled and incoming
    // requests.
    _locked = false;
  }

  bool _locked = false;
  final Queue<Completer<void>> _outstandingRequests = Queue<Completer<void>>();
}
