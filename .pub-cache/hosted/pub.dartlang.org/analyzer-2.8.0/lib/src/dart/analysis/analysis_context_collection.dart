// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:cli_util/cli_util.dart';

/// An implementation of [AnalysisContextCollection].
class AnalysisContextCollectionImpl implements AnalysisContextCollection {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The list of analysis contexts.
  @override
  final List<DriverBasedAnalysisContext> contexts = [];

  /// Initialize a newly created analysis context manager.
  AnalysisContextCollectionImpl({
    ByteStore? byteStore,
    Map<String, String>? declaredVariables,
    bool drainStreams = true,
    bool enableIndex = false,
    required List<String> includedPaths,
    List<String>? excludedPaths,
    String? optionsFile,
    String? packagesFile,
    PerformanceLog? performanceLog,
    ResourceProvider? resourceProvider,
    bool retainDataForTesting = false,
    String? sdkPath,
    AnalysisDriverScheduler? scheduler,
    FileContentCache? fileContentCache,
    void Function(AnalysisOptionsImpl)? updateAnalysisOptions,
  }) : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE {
    sdkPath ??= getSdkPath();

    _throwIfAnyNotAbsoluteNormalizedPath(includedPaths);
    _throwIfNotAbsoluteNormalizedPath(sdkPath);

    var contextLocator = ContextLocator(
      resourceProvider: this.resourceProvider,
    );
    var roots = contextLocator.locateRoots(
      includedPaths: includedPaths,
      excludedPaths: excludedPaths,
      optionsFile: optionsFile,
      packagesFile: packagesFile,
    );
    for (var root in roots) {
      var contextBuilder = ContextBuilderImpl(
        resourceProvider: this.resourceProvider,
      );
      var context = contextBuilder.createContext(
        byteStore: byteStore,
        contextRoot: root,
        declaredVariables: DeclaredVariables.fromMap(declaredVariables ?? {}),
        drainStreams: drainStreams,
        enableIndex: enableIndex,
        performanceLog: performanceLog,
        retainDataForTesting: retainDataForTesting,
        sdkPath: sdkPath,
        scheduler: scheduler,
        updateAnalysisOptions: updateAnalysisOptions,
        fileContentCache: fileContentCache,
      );
      contexts.add(context);
    }
  }

  /// Return `true` if the read state of configuration files is consistent
  /// with their current state on the file system. We use this as a work
  /// around an issue with watching for file system changes.
  bool get areWorkspacesConsistent {
    for (var analysisContext in contexts) {
      var contextRoot = analysisContext.contextRoot;
      var workspace = contextRoot.workspace;
      if (!workspace.isConsistentWithFileSystem) {
        return false;
      }
    }
    return true;
  }

  @override
  DriverBasedAnalysisContext contextFor(String path) {
    _throwIfNotAbsoluteNormalizedPath(path);

    for (var context in contexts) {
      if (context.contextRoot.isAnalyzed(path)) {
        return context;
      }
    }

    throw StateError('Unable to find the context to $path');
  }

  /// Check every element with [_throwIfNotAbsoluteNormalizedPath].
  void _throwIfAnyNotAbsoluteNormalizedPath(List<String> paths) {
    for (var path in paths) {
      _throwIfNotAbsoluteNormalizedPath(path);
    }
  }

  /// The driver supports only absolute normalized paths, this method is used
  /// to validate any input paths to prevent errors later.
  void _throwIfNotAbsoluteNormalizedPath(String path) {
    var pathContext = resourceProvider.pathContext;
    if (!pathContext.isAbsolute(path) || pathContext.normalize(path) != path) {
      throw ArgumentError(
          'Only absolute normalized paths are supported: $path');
    }
  }
}
