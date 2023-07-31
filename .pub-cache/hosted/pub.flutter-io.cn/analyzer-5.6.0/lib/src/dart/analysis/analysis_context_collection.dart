// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as macro;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_locator.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/context_builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/summary2/kernel_compilation_service.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/util/sdk.dart';

/// An implementation of [AnalysisContextCollection].
class AnalysisContextCollectionImpl implements AnalysisContextCollection {
  /// The resource provider used to access the file system.
  final ResourceProvider resourceProvider;

  /// The instance of macro executor that is used for all macros.
  final macro.MultiMacroExecutor macroExecutor = macro.MultiMacroExecutor();

  /// The instance of the macro kernel builder.
  final MacroKernelBuilder macroKernelBuilder = MacroKernelBuilder();

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
    List<String>? librarySummaryPaths,
    String? optionsFile,
    String? packagesFile,
    PerformanceLog? performanceLog,
    ResourceProvider? resourceProvider,
    bool retainDataForTesting = false,
    String? sdkPath,
    String? sdkSummaryPath,
    AnalysisDriverScheduler? scheduler,
    FileContentCache? fileContentCache,
    UnlinkedUnitStore? unlinkedUnitStore,
    @Deprecated('Use updateAnalysisOptions2, which must be a function that '
        'accepts a second parameter')
        void Function(AnalysisOptionsImpl)? updateAnalysisOptions,
    void Function({
      required AnalysisOptionsImpl analysisOptions,
      required ContextRoot contextRoot,
      required DartSdk sdk,
    })?
        updateAnalysisOptions2,
  }) : resourceProvider =
            resourceProvider ?? PhysicalResourceProvider.INSTANCE {
    sdkPath ??= getSdkPath();

    _throwIfAnyNotAbsoluteNormalizedPath(includedPaths);
    _throwIfNotAbsoluteNormalizedPath(sdkPath);

    if (updateAnalysisOptions != null && updateAnalysisOptions2 != null) {
      throw ArgumentError(
          'Either updateAnalysisOptions or updateAnalysisOptions2 must be '
          'given, but not both.');
    }

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
        librarySummaryPaths: librarySummaryPaths,
        performanceLog: performanceLog,
        retainDataForTesting: retainDataForTesting,
        sdkPath: sdkPath,
        sdkSummaryPath: sdkSummaryPath,
        scheduler: scheduler,
        // ignore: deprecated_member_use_from_same_package
        updateAnalysisOptions: updateAnalysisOptions,
        updateAnalysisOptions2: updateAnalysisOptions2,
        fileContentCache: fileContentCache,
        unlinkedUnitStore: unlinkedUnitStore ?? UnlinkedUnitStoreImpl(),
        macroKernelBuilder: macroKernelBuilder,
        macroExecutor: macroExecutor,
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

  Future<void> dispose({
    bool forTesting = false,
  }) async {
    for (final analysisContext in contexts) {
      await analysisContext.driver.dispose2();
    }
    await macroExecutor.close();
    // If there are other collections, they will have to start it again.
    if (!forTesting) {
      await KernelCompilationService.dispose();
    }
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
