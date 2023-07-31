// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/analysis_options/analysis_options_provider.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/cache.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show ErrorEncoding;
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_analyzer.dart';
import 'package:analyzer/src/dart/analysis/library_context.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/micro/analysis_context.dart';
import 'package:analyzer/src/dart/micro/utils.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/task/options.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/file_system.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

class CiderFileContent implements FileContent {
  final CiderFileContentStrategy strategy;
  final String path;
  final String digestStr;

  CiderFileContent({
    required this.strategy,
    required this.path,
    required this.digestStr,
  });

  @override
  String get content {
    final contentWithDigest = _getContent();

    if (contentWithDigest.digestStr != digestStr) {
      throw StateError('File was changed, but not invalidated: $path');
    }

    return contentWithDigest.content;
  }

  @override
  String get contentHash => digestStr;

  @override
  bool get exists => digestStr.isNotEmpty;

  _ContentWithDigest _getContent() {
    String content;
    try {
      final file = strategy.resourceProvider.getFile(path);
      content = file.readAsStringSync();
    } catch (_) {
      content = '';
    }

    final digestStr = strategy.getFileDigest(path);
    return _ContentWithDigest(
      content: content,
      digestStr: digestStr,
    );
  }
}

class CiderFileContentStrategy implements FileContentStrategy {
  final ResourceProvider resourceProvider;

  /// A function that returns the digest for a file as a String. The function
  /// returns a non null value, returns an empty string if file does
  /// not exist/has no contents.
  final String Function(String path) getFileDigest;

  CiderFileContentStrategy({
    required this.resourceProvider,
    required this.getFileDigest,
  });

  @override
  CiderFileContent get(String path) {
    final digestStr = getFileDigest(path);
    return CiderFileContent(
      strategy: this,
      path: path,
      digestStr: digestStr,
    );
  }
}

class CiderSearchInfo {
  final CharacterLocation startPosition;
  final int length;
  final MatchKind kind;

  CiderSearchInfo(this.startPosition, this.length, this.kind);

  @override
  bool operator ==(Object other) =>
      other is CiderSearchInfo &&
      startPosition == other.startPosition &&
      length == other.length &&
      kind == other.kind;
}

class CiderSearchMatch {
  final String path;
  final List<CiderSearchInfo> references;

  CiderSearchMatch(this.path, this.references);

  @override
  bool operator ==(Object other) =>
      other is CiderSearchMatch &&
      path == other.path &&
      const ListEquality<CiderSearchInfo>()
          .equals(references, other.references);

  @override
  String toString() {
    return '($path, $references)';
  }
}

class FileContext {
  final AnalysisOptionsImpl analysisOptions;
  final FileState file;

  FileContext(this.analysisOptions, this.file);
}

class FileResolver {
  final PerformanceLog logger;
  final ResourceProvider resourceProvider;
  ByteStore byteStore;
  final SourceFactory sourceFactory;

  /// A function that returns the digest for a file as a String. The function
  /// returns a non null value, can return an empty string if file does
  /// not exist/has no contents.
  final String Function(String path) getFileDigest;

  /// A function that returns true if the given file path is likely to be that
  /// of a file that is generated.
  final bool Function(String path) isGenerated;

  /// A function that fetches the given list of files. This function can be used
  /// to batch file reads in systems where file fetches are expensive.
  final void Function(List<String> paths)? prefetchFiles;

  final Workspace workspace;

  /// This field gets value only during testing.
  final FileResolverTestData? testData;

  FileSystemState? fsState;

  MicroContextObjects? contextObjects;

  LibraryContext? libraryContext;

  /// List of keys for cache elements that are invalidated. Track elements that
  /// are invalidated during [changeFiles]. Used in [releaseAndClearRemovedIds]
  /// to release the cache items and is then cleared.
  final Set<String> removedCacheKeys = {};

  /// The cache of file results, cleared on [changeFiles].
  ///
  /// It is used to allow assists and fixes without resolving the same file
  /// multiple times, as we compute more than one assist, or fixes when there
  /// are more than one error on a line.
  @visibleForTesting
  final Map<String, ResolvedLibraryResult> cachedResults = {};

  /// The cache of error results.
  final Cache<String, Uint8List> _errorResultsCache =
      Cache(128 * 1024, (bytes) => bytes.length);

  FileResolver({
    required this.logger,
    required this.resourceProvider,
    required this.sourceFactory,
    required this.getFileDigest,
    required this.prefetchFiles,
    required this.workspace,
    required this.isGenerated,
    required this.byteStore,
    this.testData,
  });

  /// Update the resolver to reflect the fact that the files with the given
  /// [paths] were changed. For each specified file we need to make sure that
  /// when the file, of any file that directly or indirectly referenced it,
  /// is resolved, we use the new state of the file.
  void changeFiles(List<String> paths) {
    if (fsState == null) {
      return;
    }

    // Forget all results, anything is potentially affected.
    cachedResults.clear();

    // Remove the specified files and files that transitively depend on it.
    final removedFiles = <FileState>{};
    for (final path in paths) {
      fsState!.changeFile(path, removedFiles);
    }

    // Schedule disposing references to cached unlinked data.
    for (final removedFile in removedFiles) {
      removedCacheKeys.add(removedFile.unlinkedKey);
    }

    // Remove libraries represented by removed files.
    // If we need these libraries later, we will relink and reattach them.
    libraryContext?.remove(removedFiles, removedCacheKeys);

    releaseAndClearRemovedIds();
  }

  /// Collects all the cached artifacts and add all the cache id's for the
  /// removed artifacts to [removedCacheKeys].
  @Deprecated('Use dispose() instead')
  void collectSharedDataIdentifiers() {
    removedCacheKeys.addAll(fsState!.dispose());
    removedCacheKeys.addAll(libraryContext!.dispose());
  }

  /// Notifies this object that it is about to be discarded, so it should
  /// release any shared data.
  void dispose() {
    removedCacheKeys.addAll(fsState!.dispose());
    removedCacheKeys.addAll(libraryContext!.dispose());
    releaseAndClearRemovedIds();
  }

  /// Looks for references to the given Element. All the files currently
  ///  cached by the resolver are searched, generated files are ignored.
  Future<List<CiderSearchMatch>> findReferences2(Element element,
      {OperationPerformanceImpl? performance}) async {
    return logger.runAsync('findReferences for ${element.name}', () async {
      var references = <CiderSearchMatch>[];

      Future<void> collectReferences2(
          String path, OperationPerformanceImpl performance) async {
        await performance.runAsync('collectReferences', (_) async {
          var resolved = await resolve2(path: path);
          var collector = ReferencesCollector(element);
          resolved.unit.accept(collector);
          var matches = collector.references;
          if (matches.isNotEmpty) {
            var lineInfo = resolved.unit.lineInfo;
            references.add(CiderSearchMatch(
                path,
                matches
                    .map((match) => CiderSearchInfo(
                        lineInfo.getLocation(match.offset),
                        match.length,
                        match.matchKind))
                    .toList()));
          }
        });
      }

      performance ??= OperationPerformanceImpl('<default>');
      // TODO(keertip): check if element is named constructor.
      if (element is LocalVariableElement ||
          (element is ParameterElement && !element.isNamed)) {
        await collectReferences2(element.source!.fullName, performance!);
      } else if (element is LibraryImportElement) {
        return await _searchReferences_Import(element);
      } else {
        var result = performance!.run('getFilesContaining', (performance) {
          return fsState!.getFilesContaining(element.displayName);
        });
        for (var filePath in result) {
          await collectReferences2(filePath, performance!);
        }
      }
      return references;
    });
  }

  Future<ErrorsResult> getErrors2({
    required String path,
    OperationPerformanceImpl? performance,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return logger.runAsync('Get errors for $path', () async {
      var fileContext = getFileContext(
        path: path,
        performance: performance!,
      );
      var file = fileContext.file;
      final kind = file.kind.library ?? file.kind.asLibrary;

      final errorsSignatureBuilder = ApiSignature();
      errorsSignatureBuilder.addString(kind.libraryCycle.apiSignature);
      errorsSignatureBuilder.addString(file.contentHash);
      final errorsKey = '${errorsSignatureBuilder.toHex()}.errors';

      final List<AnalysisError> errors;
      final bytes = _errorResultsCache.get(errorsKey);
      if (bytes != null) {
        var data = CiderUnitErrors.fromBuffer(bytes);
        errors = data.errors.map((error) {
          return ErrorEncoding.decode(file.source, error)!;
        }).toList();
      } else {
        var unitResult = await resolve2(
          path: path,
          performance: performance,
        );
        errors = unitResult.errors;

        _errorResultsCache.put(
          errorsKey,
          CiderUnitErrorsBuilder(
            errors: errors.map(ErrorEncoding.encode).toList(),
          ).toBuffer(),
        );
      }

      return ErrorsResultImpl(
        session: contextObjects!.analysisSession,
        path: path,
        uri: file.uri,
        lineInfo: file.lineInfo,
        isAugmentation: file.kind is AugmentationFileKind,
        isLibrary: file.kind is LibraryFileKind,
        isPart: file.kind is PartFileKind,
        errors: errors,
      );
    });
  }

  FileContext getFileContext({
    required String path,
    required OperationPerformanceImpl performance,
  }) {
    return performance.run('fileContext', (performance) {
      var analysisOptions = performance.run('analysisOptions', (performance) {
        return _getAnalysisOptions(
          path: path,
          performance: performance,
        );
      });

      performance.run('createContext', (_) {
        _createContext(path, analysisOptions);
      });

      var file = performance.run('fileForPath', (performance) {
        return fsState!.getFileForPath2(
          path: path,
          performance: performance,
        );
      });

      return FileContext(analysisOptions, file);
    });
  }

  /// Return files that have a top-level declaration with the [name].
  List<FileState> getFilesWithTopLevelDeclarations(String name) {
    final fsState = this.fsState;
    if (fsState == null) {
      return const [];
    }
    return fsState.getFilesWithTopLevelDeclarations(name);
  }

  Future<LibraryElement> getLibraryByUri2({
    required String uriStr,
    OperationPerformanceImpl? performance,
  }) async {
    performance ??= OperationPerformanceImpl('<default>');

    var uri = uriCache.parse(uriStr);
    var path = sourceFactory.forUri2(uri)?.fullName;

    if (path == null) {
      throw ArgumentError('$uri cannot be resolved to a file.');
    }

    var fileContext = getFileContext(
      path: path,
      performance: performance,
    );
    var file = fileContext.file;

    final kind = file.kind;
    if (kind is! LibraryFileKind) {
      throw ArgumentError('$uri is not a library.');
    }

    await performance.runAsync('libraryContext', (performance) async {
      await libraryContext!.load(
        targetLibrary: kind,
        performance: performance,
      );
    });

    return libraryContext!.elementFactory.libraryOfUri2(uri);
  }

  String getLibraryLinkedSignature({
    required String path,
    required OperationPerformanceImpl performance,
  }) {
    _throwIfNotAbsoluteNormalizedPath(path);

    var file = fsState!.getFileForPath2(
      path: path,
      performance: performance,
    );

    // TODO(scheglov) Casts are unsafe.
    final kind = file.kind as LibraryFileKind;
    return kind.libraryCycle.apiSignature;
  }

  /// Ensure that libraries necessary for resolving [path] are linked.
  ///
  /// Libraries are linked in library cycles, from the bottom to top, so that
  /// when we link a cycle, everything it transitively depends is ready. We
  /// load newly linked libraries from bytes, and when we link a new library
  /// cycle we partially resynthesize AST and elements from previously
  /// loaded libraries.
  ///
  /// But when we are done linking libraries, and want to resolve just the
  /// very top library that transitively depends on the whole dependency
  /// tree, this library will not reference as many elements in the
  /// dependencies as we needed for linking. Most probably it references
  /// elements from directly imported libraries, and a couple of layers below.
  /// So, keeping all previously resynthesized data is usually a waste.
  ///
  /// This method ensures that we discard the libraries context, with all its
  /// partially resynthesized data, and so prepare for loading linked summaries
  /// from bytes, which will be done by [getErrors2]. It is OK for it to
  /// spend some more time on this.
  Future<void> linkLibraries2({
    required String path,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    var performance = OperationPerformanceImpl('<unused>');

    var fileContext = getFileContext(
      path: path,
      performance: performance,
    );
    var file = fileContext.file;
    final libraryKind = file.kind.library ?? file.kind.asLibrary;

    // Load the library, link if necessary.
    await libraryContext!.load(
      targetLibrary: libraryKind,
      performance: performance,
    );

    // Unload libraries, but don't release the linked data.
    // If we are the only consumer of it, we will lose it.
    final linkedKeysToRelease = libraryContext!.unloadAll();

    // Load the library again, the reference count is `>= 2`.
    await libraryContext!.load(
      targetLibrary: libraryKind,
      performance: performance,
    );

    // Release the linked data, the reference count is `>= 1`.
    if (linkedKeysToRelease.isNotEmpty) {
      byteStore.release(linkedKeysToRelease);
    }
  }

  /// Releases from the cache and clear [removedCacheKeys].
  void releaseAndClearRemovedIds() {
    if (removedCacheKeys.isNotEmpty) {
      byteStore.release(removedCacheKeys);
      removedCacheKeys.clear();
    }
  }

  /// Remove cached [FileState]'s that were not used in the current analysis
  /// session. The list of files analyzed is used to compute the set of unused
  /// [FileState]'s. Adds the cache id's for the removed [FileState]'s to
  /// [removedCacheKeys].
  void removeFilesNotNecessaryForAnalysisOf(List<String> files) {
    var removedFiles = fsState!.removeUnusedFiles(files);
    for (var removedFile in removedFiles) {
      removedCacheKeys.add(removedFile.unlinkedKey);
    }
    libraryContext?.remove(removedFiles, removedCacheKeys);
    releaseAndClearRemovedIds();
  }

  Future<ResolvedUnitResult> resolve2({
    required String path,
    OperationPerformanceImpl? performance,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return logger.runAsync('Resolve $path', () async {
      var fileContext = getFileContext(
        path: path,
        performance: performance!,
      );
      var file = fileContext.file;

      final libraryKind = file.kind.library ?? file.kind.asLibrary;
      final libraryFile = libraryKind.file;

      var libraryResult = await resolveLibrary2(
        path: libraryFile.path,
        performance: performance,
      );
      return libraryResult.units.firstWhere(
        (unitResult) => unitResult.path == path,
      );
    });
  }

  /// The [completionLine] and [completionColumn] are zero based.
  Future<ResolvedForCompletionResultImpl> resolveForCompletion({
    required int completionLine,
    required int completionColumn,
    required String path,
    OperationPerformanceImpl? performance,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    return logger.runAsync('Resolve $path', () async {
      final fileContext = getFileContext(
        path: path,
        performance: performance!,
      );
      final file = fileContext.file;
      final libraryKind = file.kind.library ?? file.kind.asLibrary;

      final lineOffset = file.lineInfo.getOffsetOfLine(completionLine);
      final completionOffset = lineOffset + completionColumn;

      await performance.runAsync('libraryContext', (performance) async {
        await libraryContext!.load(
          targetLibrary: libraryKind,
          performance: performance,
        );
      });

      final unitElement = libraryContext!.computeUnitElement(libraryKind, file);

      return logger.run('Compute analysis results', () {
        final elementFactory = libraryContext!.elementFactory;
        final analysisSession = elementFactory.analysisSession;

        var libraryAnalyzer = LibraryAnalyzer(
          fileContext.analysisOptions,
          contextObjects!.declaredVariables,
          elementFactory.libraryOfUri2(libraryKind.file.uri),
          analysisSession.inheritanceManager,
          libraryKind,
        );

        final analysisResult = performance!.run('analyze', (performance) {
          return libraryAnalyzer.analyzeForCompletion(
            file: file,
            offset: completionOffset,
            unitElement: unitElement,
            performance: performance,
          );
        });

        return ResolvedForCompletionResultImpl(
          analysisSession: analysisSession,
          path: path,
          uri: file.uri,
          exists: file.exists,
          content: file.content,
          lineInfo: file.lineInfo,
          parsedUnit: analysisResult.parsedUnit,
          unitElement: unitElement,
          resolvedNodes: analysisResult.resolvedNodes,
        );
      });
    });
  }

  Future<ResolvedLibraryResult> resolveLibrary2({
    required String path,
    OperationPerformanceImpl? performance,
  }) async {
    _throwIfNotAbsoluteNormalizedPath(path);

    performance ??= OperationPerformanceImpl('<default>');

    var cachedResult = cachedResults[path];
    if (cachedResult != null) {
      return cachedResult;
    }

    return logger.runAsync('Resolve $path', () async {
      var fileContext = getFileContext(
        path: path,
        performance: performance!,
      );
      var file = fileContext.file;
      final libraryKind = file.kind.library ?? file.kind.asLibrary;

      await performance.runAsync('libraryContext', (performance) async {
        await libraryContext!.load(
          targetLibrary: libraryKind,
          performance: performance,
        );
      });

      testData?.addResolvedLibrary(path);

      late List<UnitAnalysisResult> results;

      logger.run('Compute analysis results', () {
        var libraryAnalyzer = LibraryAnalyzer(
          fileContext.analysisOptions,
          contextObjects!.declaredVariables,
          libraryContext!.elementFactory.libraryOfUri2(libraryKind.file.uri),
          libraryContext!.elementFactory.analysisSession.inheritanceManager,
          libraryKind,
        );

        results = performance!.run('analyze', (performance) {
          return libraryAnalyzer.analyze();
        });
      });

      var resolvedUnits = results.map((fileResult) {
        var file = fileResult.file;
        return ResolvedUnitResultImpl(
          session: contextObjects!.analysisSession,
          path: file.path,
          uri: file.uri,
          exists: file.exists,
          content: file.content,
          lineInfo: file.lineInfo,
          isAugmentation: file.kind is AugmentationFileKind,
          isLibrary: file.kind is LibraryFileKind,
          isPart: file.kind is PartFileKind,
          unit: fileResult.unit,
          errors: fileResult.errors,
        );
      }).toList();

      var libraryUnit = resolvedUnits.first;
      var result = ResolvedLibraryResultImpl(
        session: contextObjects!.analysisSession,
        element: libraryUnit.libraryElement,
        units: resolvedUnits,
      );

      cachedResults[path] = result;

      return result;
    });
  }

  /// Make sure that [fsState], [contextObjects], and [libraryContext] are
  /// created and configured with the given [fileAnalysisOptions].
  ///
  /// The [fsState] is not affected by [fileAnalysisOptions].
  ///
  /// The [fileAnalysisOptions] only affect reported diagnostics, but not
  /// elements and types. So, we really need to reconfigure only when we are
  /// going to resolve some files using these new options.
  ///
  /// Specifically, "implicit casts" and "strict inference" affect the type
  /// system. And there are lints that are enabled for one package, but not
  /// for another.
  void _createContext(String path, AnalysisOptionsImpl fileAnalysisOptions) {
    if (contextObjects != null) {
      libraryContext!.analysisContext.analysisOptions = fileAnalysisOptions;
      return;
    }

    var analysisOptions = AnalysisOptionsImpl()
      ..implicitCasts = fileAnalysisOptions.implicitCasts
      ..strictInference = fileAnalysisOptions.strictInference;

    if (fsState == null) {
      var featureSetProvider = FeatureSetProvider.build(
        sourceFactory: sourceFactory,
        resourceProvider: resourceProvider,
        packages: Packages.empty,
        packageDefaultFeatureSet: analysisOptions.contextFeatures,
        nonPackageDefaultLanguageVersion: ExperimentStatus.currentVersion,
        nonPackageDefaultFeatureSet: analysisOptions.nonPackageFeatureSet,
      );

      fsState = FileSystemState(
        logger,
        byteStore,
        resourceProvider,
        'contextName',
        sourceFactory,
        workspace,
        DeclaredVariables.fromMap({}),
        Uint32List(0), // _saltForUnlinked
        Uint32List(0), // _saltForElements
        featureSetProvider,
        fileContentStrategy: CiderFileContentStrategy(
          resourceProvider: resourceProvider,
          getFileDigest: getFileDigest,
        ),
        prefetchFiles: prefetchFiles,
        isGenerated: isGenerated,
        testData: testData?.fileSystem,
        unlinkedUnitStore: UnlinkedUnitStoreImpl(),
      );
    }

    if (contextObjects == null) {
      var rootFolder = resourceProvider.getFolder(workspace.root);
      var root = ContextRootImpl(resourceProvider, rootFolder, workspace);
      root.included.add(rootFolder);

      contextObjects = createMicroContextObjects(
        fileResolver: this,
        analysisOptions: analysisOptions,
        sourceFactory: sourceFactory,
        root: root,
        resourceProvider: resourceProvider,
      );

      libraryContext = LibraryContext(
        declaredVariables: contextObjects!.declaredVariables,
        byteStore: byteStore,
        analysisOptions: contextObjects!.analysisOptions,
        analysisSession: contextObjects!.analysisSession,
        logger: logger,
        fileSystemState: fsState!,
        sourceFactory: sourceFactory,
        externalSummaries: SummaryDataStore(),
        macroExecutor: null,
        macroKernelBuilder: null,
        testData: testData?.libraryContext,
      );

      contextObjects!.analysisSession.elementFactory =
          libraryContext!.elementFactory;
    }
  }

  /// Return the analysis options.
  ///
  /// If the [path] is not `null`, read it.
  ///
  /// If the [workspace] is a [WorkspaceWithDefaultAnalysisOptions], get the
  /// default options, if the file exists.
  ///
  /// Otherwise, return the default options.
  AnalysisOptionsImpl _getAnalysisOptions({
    required String path,
    required OperationPerformanceImpl performance,
  }) {
    YamlMap? optionMap;

    var separator = resourceProvider.pathContext.separator;
    var isThirdParty = path
            .contains('${separator}third_party${separator}dart$separator') ||
        path.contains('${separator}third_party${separator}dart_lang$separator');

    File? optionsFile;
    if (!isThirdParty) {
      optionsFile = performance.run('findAnalysisOptionsYamlFile', (_) {
        var folder = resourceProvider.getFile(path).parent;
        return folder.findAnalysisOptionsYamlFile();
      });
    }

    if (optionsFile != null) {
      performance.run('getOptionsFromFile', (_) {
        try {
          var optionsProvider = AnalysisOptionsProvider(sourceFactory);
          optionMap = optionsProvider.getOptionsFromFile(optionsFile!);
        } catch (_) {}
      });
    } else {
      var source = performance.run('defaultOptions', (_) {
        if (workspace is WorkspaceWithDefaultAnalysisOptions) {
          if (isThirdParty) {
            return sourceFactory.forUri(
              WorkspaceWithDefaultAnalysisOptions.thirdPartyUri,
            );
          } else {
            return sourceFactory.forUri(
              WorkspaceWithDefaultAnalysisOptions.uri,
            );
          }
        }
        return null;
      });

      if (source != null && source.exists()) {
        performance.run('getOptionsFromFile', (_) {
          try {
            var optionsProvider = AnalysisOptionsProvider(sourceFactory);
            optionMap = optionsProvider.getOptionsFromSource(source);
          } catch (_) {}
        });
      }
    }

    var options = AnalysisOptionsImpl();

    if (optionMap != null) {
      performance.run('applyToAnalysisOptions', (_) {
        applyToAnalysisOptions(options, optionMap!);
      });
    }

    if (isThirdParty) {
      options.hint = false;
    }

    return options;
  }

  Future<List<CiderSearchMatch>> _searchReferences_Import(
      LibraryImportElement element) async {
    var results = <CiderSearchMatch>[];
    LibraryElement libraryElement = element.library;
    for (CompilationUnitElement unitElement in libraryElement.units) {
      String unitPath = unitElement.source.fullName;
      var unitResult = await resolve2(path: unitPath);
      var visitor = ImportElementReferencesVisitor(element, unitElement);
      unitResult.unit.accept(visitor);
      var lineInfo = unitResult.lineInfo;
      var infos = visitor.results
          .map((searchResult) => CiderSearchInfo(
              lineInfo.getLocation(searchResult.offset),
              searchResult.length,
              MatchKind.REFERENCE))
          .toList();
      results.add(CiderSearchMatch(unitPath, infos));
    }
    return results;
  }

  void _throwIfNotAbsoluteNormalizedPath(String path) {
    var pathContext = resourceProvider.pathContext;
    if (pathContext.normalize(path) != path) {
      throw ArgumentError(
        'Only normalized paths are supported: $path',
      );
    }
  }
}

class FileResolverTestData {
  final fileSystem = FileSystemTestData();

  late final libraryContext = LibraryContextTestData(
    fileSystemTestData: fileSystem,
  );

  /// The paths of libraries which were resolved.
  ///
  /// The library path is added every time when it is resolved.
  final List<String> resolvedLibraries = [];

  void addResolvedLibrary(String path) {
    resolvedLibraries.add(path);
  }
}

class _ContentWithDigest {
  final String content;
  final String digestStr;

  _ContentWithDigest({
    required this.content,
    required this.digestStr,
  });
}
