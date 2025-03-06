// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:watcher/watcher.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/utils.dart';
import 'preview_code_generator.dart';

/// A path / URI pair used to map previews to a file.
///
/// We don't just use a path or a URI as the file watcher doesn't report URIs
/// (e.g., package:*) but the analyzer APIs do, and the code generator emits
/// package URIs for preview imports.
typedef PreviewPath = ({String path, Uri uri});

/// Represents a set of previews for a given file.
typedef PreviewMapping = Map<PreviewPath, List<String>>;

extension on Token {
  /// Convenience getter to identify tokens for private fields and functions.
  bool get isPrivate => toString().startsWith('_');
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
  bool get isGeneratedPreviewFile => endsWith(PreviewCodeGenerator.generatedPreviewFilePath);
}

extension on ParsedUnitResult {
  /// Convenience method to package [path] and [uri] into a [PreviewPath]
  PreviewPath toPreviewPath() => (path: path, uri: uri);
}

class PreviewDetector {
  PreviewDetector({
    required this.fs,
    required this.logger,
    required this.onChangeDetected,
    required this.onPubspecChangeDetected,
  });

  final FileSystem fs;
  final Logger logger;
  final void Function(PreviewMapping) onChangeDetected;
  final void Function() onPubspecChangeDetected;

  StreamSubscription<WatchEvent>? _fileWatcher;
  late final PreviewMapping _pathToPreviews;

  /// Starts listening for changes to Dart sources under [projectRoot] and returns
  /// the initial [PreviewMapping] for the project.
  Future<PreviewMapping> initialize(Directory projectRoot) async {
    // Find the initial set of previews.
    _pathToPreviews = findPreviewFunctions(projectRoot);

    final Watcher watcher = Watcher(projectRoot.path);
    _fileWatcher = watcher.events.listen((WatchEvent event) async {
      final String eventPath = event.path;
      // If the pubspec has changed, new dependencies or assets could have been added, requiring
      // the preview scaffold's pubspec to be updated.
      if (eventPath.isPubspec && !eventPath.doesContainDartTool) {
        onPubspecChangeDetected();
        return;
      }
      // Only trigger a reload when changes to Dart sources are detected. We
      // ignore the generated preview file to avoid getting stuck in a loop.
      if (!eventPath.isDartFile || eventPath.isGeneratedPreviewFile) {
        return;
      }
      logger.printStatus('Detected change in $eventPath.');
      final PreviewMapping filePreviewsMapping = findPreviewFunctions(
        fs.file(Uri.file(event.path)),
      );
      final bool hasExistingPreviews =
          _pathToPreviews.keys.where((PreviewPath e) => e.path == event.path).isNotEmpty;
      if (filePreviewsMapping.isEmpty && !hasExistingPreviews) {
        // No previews found or removed, nothing to do.
        return;
      }
      if (filePreviewsMapping.length > 1) {
        logger.printWarning('Previews from more than one file were detected!');
        logger.printWarning('Previews: $filePreviewsMapping');
      }
      if (filePreviewsMapping.isNotEmpty) {
        // The set of previews has changed, but there are still previews in the file.
        final MapEntry<PreviewPath, List<String>>(
          key: PreviewPath location,
          value: List<String> filePreviews,
        ) = filePreviewsMapping.entries.first;
        logger.printStatus('Updated previews for ${location.uri}: $filePreviews');
        if (filePreviews.isNotEmpty) {
          final List<String>? currentPreviewsForFile = _pathToPreviews[location];
          if (filePreviews != currentPreviewsForFile) {
            _pathToPreviews[location] = filePreviews;
          }
        }
      } else {
        // The file previously had previews that were removed.
        logger.printStatus('Previews removed from $eventPath');
        _pathToPreviews.removeWhere((PreviewPath e, _) => e.path == eventPath);
      }
      onChangeDetected(_pathToPreviews);
    });
    // Wait for file watcher to finish initializing, otherwise we might miss changes and cause
    // tests to flake.
    await watcher.ready;
    return _pathToPreviews;
  }

  Future<void> dispose() async {
    await _fileWatcher?.cancel();
  }

  /// Search for functions annotated with `@Preview` in the current project.
  PreviewMapping findPreviewFunctions(FileSystemEntity entity) {
    final AnalysisContextCollection collection = AnalysisContextCollection(
      includedPaths: <String>[entity.absolute.path],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    final PreviewMapping previews = PreviewMapping();
    for (final AnalysisContext context in collection.contexts) {
      logger.printStatus('Finding previews in ${context.contextRoot.root.path}...');

      for (final String filePath in context.contextRoot.analyzedFiles()) {
        logger.printTrace('Checking file: $filePath');
        if (!filePath.isDartFile) {
          continue;
        }

        final SomeParsedLibraryResult lib = context.currentSession.getParsedLibrary(filePath);
        if (lib is ParsedLibraryResult) {
          for (final ParsedUnitResult libUnit in lib.units) {
            final List<String> previewEntries = previews[libUnit.toPreviewPath()] ?? <String>[];
            for (final CompilationUnitMember entity in libUnit.unit.declarations) {
              if (entity is FunctionDeclaration && !entity.name.isPrivate) {
                bool foundPreview = false;
                for (final Annotation annotation in entity.metadata) {
                  if (annotation.isPreview) {
                    // What happens if the annotation is applied multiple times?
                    foundPreview = true;
                    break;
                  }
                }
                if (foundPreview) {
                  logger.printStatus('Found preview at:');
                  logger.printStatus('File path: ${libUnit.uri}');
                  logger.printStatus('Preview function: ${entity.name}');
                  logger.printStatus('');
                  previewEntries.add(entity.name.toString());
                }
              }
            }
            if (previewEntries.isNotEmpty) {
              previews[libUnit.toPreviewPath()] = previewEntries;
            }
          }
        } else {
          logger.printWarning('Unknown library type at $filePath: $lib');
        }
      }
    }
    final int previewCount = previews.values.fold<int>(
      0,
      (int count, List<String> value) => count + value.length,
    );
    logger.printStatus('Found $previewCount ${pluralize('preview', previewCount)}.');
    return previews;
  }
}
