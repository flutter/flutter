// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:watcher/watcher.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import 'dependency_graph.dart';
import 'utils.dart';

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
