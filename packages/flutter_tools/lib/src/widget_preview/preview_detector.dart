// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:meta/meta.dart';
import 'package:watcher/watcher.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import 'analytics.dart';
import 'dependency_graph.dart';
import 'utils.dart';

class PreviewDetector {
  PreviewDetector({
    required this.previewAnalytics,
    required this.projectRoot,
    required this.fs,
    required this.logger,
    required this.onChangeDetected,
    required this.onPubspecChangeDetected,
  });

  final WidgetPreviewAnalytics previewAnalytics;
  final Directory projectRoot;
  final FileSystem fs;
  final Logger logger;
  final void Function(PreviewDependencyGraph) onChangeDetected;
  final void Function(String path) onPubspecChangeDetected;

  StreamSubscription<WatchEvent>? _fileWatcher;
  final _mutex = PreviewDetectorMutex();

  @visibleForTesting
  PreviewDependencyGraph get dependencyGraph => _dependencyGraph;
  final PreviewDependencyGraph _dependencyGraph = PreviewDependencyGraph();

  late final collection = AnalysisContextCollection(
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

    final watcher = Watcher(projectRoot.path);
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
        onPubspecChangeDetected(eventPath);
        return;
      }
      // Only trigger a reload when changes to Dart sources are detected. We
      // ignore the generated preview file to avoid getting stuck in a loop.
      if (!eventPath.isDartFile || eventPath.doesContainDartTool) {
        return;
      }

      // Start tracking how long it takes to reload a preview after the file change is detected.
      previewAnalytics.startPreviewReloadStopwatch();

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
      final AnalysisContext context = collection.contextFor(eventPath);
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

      // Report how long it took to analyze the changed file, find preview instances, update the
      // dependency graph, generate code, and reload the widget preview scaffold with the changes.
      previewAnalytics.reportPreviewReloadTiming();
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
      // The set of previews has changed, but there are still previews in the library.
      final MapEntry<PreviewPath, LibraryPreviewNode>(
        key: PreviewPath location,
        value: LibraryPreviewNode libraryDetails,
      ) = filePreviewsMapping.entries.single;
      logger.printStatus('Updated previews for ${location.uri}: ${libraryDetails.previews}');
      _dependencyGraph[location] = libraryDetails;
    } else {
      // Why is this working with an empty file system on Linux?
      final PreviewPath removedLibraryPath = _dependencyGraph.values
          .firstWhere((LibraryPreviewNode element) => element.files.contains(eventPath))
          .path;
      // The library previously had previews that were removed.
      logger.printStatus('Previews removed from $eventPath');
      _dependencyGraph.remove(removedLibraryPath);
    }
  }

  /// Search for functions annotated with `@Preview` in the current project.
  Future<PreviewDependencyGraph> _findPreviewFunctions(FileSystemEntity entity) async {
    final PreviewDependencyGraph updatedPreviews = PreviewDependencyGraph();

    logger.printStatus('Finding previews in ${entity.path}...');
    for (final AnalysisContext context in collection.contexts) {
      for (final String filePath in context.contextRoot.analyzedFiles()) {
        logger.printTrace('Checking file: $filePath');
        if (!filePath.isDartFile || !filePath.startsWith(entity.path)) {
          logger.printTrace('Skipping $filePath');
          continue;
        }
        SomeResolvedLibraryResult lib = await context.currentSession.getResolvedLibrary(filePath);
        // If filePath points to a file that's part of a library, retrieve its compilation unit first
        // in order to get the actual path to the library.
        if (lib is NotLibraryButPartResult) {
          final unit =
              (await context.currentSession.getResolvedUnit(filePath)) as ResolvedUnitResult;
          lib = await context.currentSession.getResolvedLibrary(
            unit.libraryElement2.firstFragment.source.fullName,
          );
        }
        if (lib is ResolvedLibraryResult) {
          final ResolvedLibraryResult resolvedLib = lib;
          final PreviewPath previewPath = lib.element2.toPreviewPath();
          // This library has already been processed.
          if (updatedPreviews.containsKey(previewPath)) {
            continue;
          }

          final LibraryPreviewNode previewsForLibrary = _dependencyGraph.putIfAbsent(
            previewPath,
            () => LibraryPreviewNode(library: resolvedLib.element2, logger: logger),
          );

          previewsForLibrary.updateDependencyGraph(graph: _dependencyGraph, units: lib.units);
          updatedPreviews[previewPath] = previewsForLibrary;

          // Check for errors in the library.
          await previewsForLibrary.populateErrors(context: context);

          // Iterate over each library's AST to find previews.
          previewsForLibrary.findPreviews(lib: lib);
        }
      }
    }
    final int previewCount = updatedPreviews.values.fold<int>(
      0,
      (int count, LibraryPreviewNode value) => count + value.previews.length,
    );
    logger.printStatus('Found $previewCount ${pluralize('preview', previewCount)}.');
    return updatedPreviews;
  }

  /// Handles the deletion of a file from the target project.
  ///
  /// This involves removing the relevant [LibraryPreviewNode] from the dependency graph as well
  /// as checking for newly introduced errors in files which had a transitive dependency on the
  /// removed file.
  Future<void> _fileRemoved({required AnalysisContext context, required String eventPath}) async {
    final File file = fs.file(eventPath);
    final LibraryPreviewNode node = _dependencyGraph.values.firstWhere(
      (LibraryPreviewNode e) => e.files.contains(file.path),
    );

    final visitedNodes = <LibraryPreviewNode>{};
    Future<void> populateErrorsDownstream({required LibraryPreviewNode node}) async {
      visitedNodes.add(node);
      await node.populateErrors(context: context);
      for (final LibraryPreviewNode downstream in node.dependedOnBy) {
        if (!visitedNodes.contains(downstream)) {
          await populateErrorsDownstream(node: downstream);
        }
      }
    }

    node.files.remove(eventPath);

    // If the library node contains no files, the library has been completely deleted.
    if (node.files.isEmpty) {
      _dependencyGraph.remove(node.path)!;

      // Removing a library can cause errors to be introduced down the dependency chain, so all
      // downstream dependencies need to be checked for errors.
      for (final LibraryPreviewNode downstream in node.dependedOnBy) {
        downstream.dependsOn.remove(node);
        await populateErrorsDownstream(node: node);
      }
      for (final LibraryPreviewNode upstream in node.dependsOn) {
        upstream.dependedOnBy.remove(node);
      }
    }
  }

  /// Determines which libraries in the project have transitive dependencies containing compile
  /// time errors, setting [LibraryPreviewNode.dependencyHasErrors] to true for libraries which
  /// would cause errors if imported into the previewer.
  // TODO(bkonyi): allow for processing a subset of files.
  void _propagateErrors() {
    final PreviewDependencyGraph previews = _dependencyGraph;

    // Reset the error state for all dependencies.
    for (final LibraryPreviewNode libraryDetails in previews.values) {
      if (libraryDetails.errors.isEmpty) {
        libraryDetails.dependencyHasErrors = false;
      }
    }

    void propagateErrorsHelper(LibraryPreviewNode errorContainingNode) {
      for (final LibraryPreviewNode importer in errorContainingNode.dependedOnBy) {
        if (importer.dependencyHasErrors) {
          // This dependency path has already been processed.
          continue;
        }
        logger.printWarning('Propagating errors to: ${importer.path.path}');
        importer.dependencyHasErrors = true;
        propagateErrorsHelper(importer);
      }
    }

    // Find the libraries that have errors and mark each of their downstream dependencies as having
    // a dependency containing errors.
    for (final LibraryPreviewNode nodeDetails in previews.values) {
      if (nodeDetails.errors.isNotEmpty) {
        logger.printWarning('${nodeDetails.path.path} has errors.');
        propagateErrorsHelper(nodeDetails);
      }
    }
  }
}
