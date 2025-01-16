// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

// ignore: implementation_imports
import 'package:_fe_analyzer_shared/src/base/syntactic_entity.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:watcher/watcher.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../globals.dart' as globals;
import 'preview_code_generator.dart';

typedef PreviewMapping = Map<String, List<String>>;

class PreviewDetector {
  PreviewDetector({required this.logger, required this.onChangeDetected});

  final Logger logger;
  final void Function(PreviewMapping) onChangeDetected;
  StreamSubscription<WatchEvent>? _fileWatcher;
  final PreviewMapping _pathToPreviews = PreviewMapping();

  Future<void> initialize(Directory projectRoot) async {
    final Watcher watcher = Watcher(projectRoot.path);
    _fileWatcher = watcher.events.listen((WatchEvent event) async {
      // Only trigger a reload when changes to Dart sources are detected. We
      // ignore the generated preview file to avoid getting stuck in a loop.
      if (!event.path.endsWith('.dart') ||
          event.path.endsWith(PreviewCodeGenerator.generatedPreviewFilePath)) {
        return;
      }
      final String eventPath = Uri.file(event.path).toString();
      logger.printStatus('Detected change in $eventPath. Performing reload...');

      final PreviewMapping filePreviewsMapping = findPreviewFunctions(globals.fs.file(event.path));
      if (filePreviewsMapping.isEmpty) {
        // No previews found, nothing to do.
        return;
      }
      if (filePreviewsMapping.length > 1) {
        logger.printWarning('Previews from more than one file were detected!');
        logger.printWarning('Previews: $filePreviewsMapping');
      }
      final MapEntry<String, List<String>>(key: String uri, value: List<String> filePreviews) =
          filePreviewsMapping.entries.first;
      logger.printStatus('Updated previews for $uri: $filePreviews');
      if (filePreviews.isNotEmpty) {
        final List<String>? currentPreviewsForFile = _pathToPreviews[uri];
        if (filePreviews != currentPreviewsForFile) {
          _pathToPreviews[uri] = filePreviews;
        }
      } else {
        _pathToPreviews.remove(uri);
      }
      onChangeDetected(_pathToPreviews);
    });
    // Wait for file watcher to finish initializing, otherwise we might miss changes and cause
    // tests to flake.
    await watcher.ready;
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
        if (!filePath.endsWith('.dart')) {
          continue;
        }

        final SomeParsedLibraryResult lib = context.currentSession.getParsedLibrary(filePath);
        if (lib is ParsedLibraryResult) {
          for (final ParsedUnitResult unit in lib.units) {
            final List<String> previewEntries = previews[unit.uri.toString()] ?? <String>[];
            for (final SyntacticEntity entity in unit.unit.childEntities) {
              if (entity is FunctionDeclaration && !entity.name.toString().startsWith('_')) {
                bool foundPreview = false;
                for (final Annotation annotation in entity.metadata) {
                  if (annotation.name.name == 'Preview') {
                    // What happens if the annotation is applied multiple times?
                    foundPreview = true;
                    break;
                  }
                }
                if (foundPreview) {
                  logger.printStatus('Found preview at:');
                  logger.printStatus('File path: ${unit.uri}');
                  logger.printStatus('Preview function: ${entity.name}');
                  logger.printStatus('');
                  previewEntries.add(entity.name.toString());
                }
              }
            }
            if (previewEntries.isNotEmpty) {
              previews[unit.uri.toString()] = previewEntries;
            }
          }
        } else {
          logger.printWarning('Unknown library type at $filePath: $lib');
        }
      }
    }
    return previews;
  }
}
