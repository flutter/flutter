// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/multi_executor.dart'
    as macro;
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/element/element.dart'
    show CompilationUnitElement, LibraryElement;
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/exception/exception.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/bundle_reader.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';

/// Context information necessary to analyze one or more libraries within an
/// [AnalysisDriver].
///
/// Currently this is implemented as a wrapper around [AnalysisContext].
class LibraryContext {
  final LibraryContextTestData? testData;
  final PerformanceLog logger;
  final ByteStore byteStore;
  final FileSystemState fileSystemState;
  final MacroKernelBuilder? macroKernelBuilder;
  final macro.MultiMacroExecutor? macroExecutor;
  final SummaryDataStore store = SummaryDataStore();

  late final AnalysisContextImpl analysisContext;
  late final LinkedElementFactory elementFactory;

  Set<LibraryCycle> loadedBundles = Set.identity();

  LibraryContext({
    required this.testData,
    required AnalysisSessionImpl analysisSession,
    required this.logger,
    required this.byteStore,
    required this.fileSystemState,
    required AnalysisOptionsImpl analysisOptions,
    required DeclaredVariables declaredVariables,
    required SourceFactory sourceFactory,
    required this.macroKernelBuilder,
    required this.macroExecutor,
    required SummaryDataStore? externalSummaries,
  }) {
    analysisContext = AnalysisContextImpl(
      analysisOptions: analysisOptions,
      declaredVariables: declaredVariables,
      sourceFactory: sourceFactory,
    );

    elementFactory = LinkedElementFactory(
      analysisContext,
      analysisSession,
      Reference.root(),
    );
    if (externalSummaries != null) {
      for (var bundle in externalSummaries.bundles) {
        elementFactory.addBundle(
          BundleReader(
            elementFactory: elementFactory,
            resolutionBytes: bundle.resolutionBytes,
            unitsInformativeBytes: {},
          ),
        );
      }
    }
  }

  /// Computes a [CompilationUnitElement] for the given library/unit pair.
  CompilationUnitElementImpl computeUnitElement(
    LibraryFileKind library,
    FileState unit,
  ) {
    var reference = elementFactory.rootReference
        .getChild(library.file.uriStr)
        .getChild('@unit')
        .getChild(unit.uriStr);
    var element = elementFactory.elementOfReference(reference);
    return element as CompilationUnitElementImpl;
  }

  /// Notifies this object that it is about to be discarded.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> dispose() {
    final keys = unloadAll();
    elementFactory.dispose();
    return keys;
  }

  /// Get the [LibraryElement] for the given library.
  LibraryElement getLibraryElement(Uri uri) {
    _createElementFactoryTypeProvider();
    return elementFactory.libraryOfUri2(uri);
  }

  /// Load data required to access elements of the given [targetLibrary].
  Future<void> load({
    required LibraryFileKind targetLibrary,
    required OperationPerformanceImpl performance,
  }) async {
    addToLogRing('[load][targetLibrary: ${targetLibrary.file}]');
    var librariesTotal = 0;
    var librariesLoaded = 0;
    var librariesLinked = 0;
    var librariesLinkedTimer = Stopwatch();
    var bytesGet = 0;
    var bytesPut = 0;

    Future<void> loadBundle(LibraryCycle cycle) async {
      if (!loadedBundles.add(cycle)) return;

      performance.getDataInt('cycleCount').increment();
      performance.getDataInt('libraryCount').add(cycle.libraries.length);

      librariesTotal += cycle.libraries.length;

      for (var directDependency in cycle.directDependencies) {
        await loadBundle(directDependency);
      }

      var unitsInformativeBytes = <Uri, Uint8List>{};
      var macroLibraries = <MacroLibrary>[];
      for (var library in cycle.libraries) {
        var macroClasses = <MacroClass>[];
        for (var file in library.files) {
          unitsInformativeBytes[file.uri] = file.unlinked2.informativeBytes;
          for (var macroClass in file.unlinked2.macroClasses) {
            macroClasses.add(
              MacroClass(
                name: macroClass.name,
                constructors: macroClass.constructors,
              ),
            );
          }
        }
        if (macroClasses.isNotEmpty) {
          macroLibraries.add(
            MacroLibrary(
              uri: library.file.uri,
              path: library.file.path,
              classes: macroClasses,
            ),
          );
        }
      }

      var linkedBytes = byteStore.get(cycle.linkedKey);

      if (linkedBytes == null) {
        librariesLinkedTimer.start();

        testData?.linkedCycles.add(
          cycle.libraries.map((e) => e.file.path).toSet(),
        );

        LinkResult linkResult;
        try {
          linkResult = await link(
            elementFactory: elementFactory,
            performance: OperationPerformanceImpl('link'),
            inputLibraries: cycle.libraries,
            macroExecutor: macroExecutor,
          );
          librariesLinked += cycle.libraries.length;
        } catch (exception, stackTrace) {
          _throwLibraryCycleLinkException(cycle, exception, stackTrace);
        }

        linkedBytes = linkResult.resolutionBytes;
        byteStore.putGet(cycle.linkedKey, linkedBytes);
        performance.getDataInt('bytesPut').add(linkedBytes.length);
        testData?.forCycle(cycle).putKeys.add(cycle.linkedKey);
        bytesPut += linkedBytes.length;

        librariesLinkedTimer.stop();
      } else {
        testData?.forCycle(cycle).getKeys.add(cycle.linkedKey);
        performance.getDataInt('bytesGet').add(linkedBytes.length);
        performance.getDataInt('libraryLoadCount').add(cycle.libraries.length);
        // TODO(scheglov) Take / clear parsed units in files.
        bytesGet += linkedBytes.length;
        librariesLoaded += cycle.libraries.length;
        elementFactory.addBundle(
          BundleReader(
            elementFactory: elementFactory,
            unitsInformativeBytes: unitsInformativeBytes,
            resolutionBytes: linkedBytes,
          ),
        );
      }

      final macroKernelBuilder = this.macroKernelBuilder;
      if (macroKernelBuilder != null && macroLibraries.isNotEmpty) {
        var macroKernelBytes = byteStore.get(cycle.macroKey);
        if (macroKernelBytes == null) {
          macroKernelBytes = await macroKernelBuilder.build(
            fileSystem: _MacroFileSystem(fileSystemState),
            libraries: macroLibraries,
          );
          byteStore.putGet(cycle.macroKey, macroKernelBytes);
          bytesPut += macroKernelBytes.length;
        } else {
          bytesGet += macroKernelBytes.length;
        }

        final macroExecutor = this.macroExecutor;
        if (macroExecutor != null) {
          var bundleMacroExecutor = BundleMacroExecutor(
            macroExecutor: macroExecutor,
            kernelBytes: macroKernelBytes,
            libraries: cycle.libraries.map((e) => e.file.uri).toSet(),
          );
          for (var library in cycle.libraries) {
            var libraryUri = library.file.uri;
            var libraryElement = elementFactory.libraryOfUri2(libraryUri);
            libraryElement.bundleMacroExecutor = bundleMacroExecutor;
          }
        }
      }
    }

    await logger.runAsync('Prepare linked bundles', () async {
      var libraryCycle = targetLibrary.libraryCycle;
      await loadBundle(libraryCycle);
      logger.writeln(
        '[librariesTotal: $librariesTotal]'
        '[librariesLoaded: $librariesLoaded]'
        '[librariesLinked: $librariesLinked]'
        '[librariesLinkedTimer: ${librariesLinkedTimer.elapsedMilliseconds} ms]'
        '[bytesGet: $bytesGet][bytesPut: $bytesPut]',
      );
    });

    // There might be a rare (and wrong) situation, when the external summaries
    // already include the [targetLibrary]. When this happens, [loadBundle]
    // exists without doing any work. But the type provider must be created.
    _createElementFactoryTypeProvider();
  }

  /// Remove libraries represented by the [removed] files.
  /// If we need these libraries later, we will relink and reattach them.
  void remove(Set<FileState> removed, Set<String> removedKeys) {
    elementFactory.removeLibraries(
      removed.map((e) => e.uri).toSet(),
    );

    loadedBundles.removeWhere((cycle) {
      final cycleFiles = cycle.libraries.map((e) => e.file);
      if (cycleFiles.any(removed.contains)) {
        removedKeys.add(cycle.linkedKey);
        return true;
      }
      return false;
    });
  }

  /// Unloads all loaded bundles.
  ///
  /// Returns the keys of the artifacts that are no longer used.
  Set<String> unloadAll() {
    final keySet = <String>{};
    final uriSet = <Uri>{};

    for (final cycle in loadedBundles) {
      keySet.add(cycle.linkedKey);
      uriSet.addAll(cycle.libraries.map((e) => e.file.uri));
    }

    elementFactory.removeLibraries(uriSet);
    loadedBundles.clear();

    return keySet;
  }

  /// Ensure that type provider is created.
  void _createElementFactoryTypeProvider() {
    if (!analysisContext.hasTypeProvider) {
      elementFactory.createTypeProviders(
        elementFactory.dartCoreElement,
        elementFactory.dartAsyncElement,
      );
    }
  }

  /// The [exception] was caught during the [cycle] linking.
  ///
  /// Throw another exception that wraps the given one, with more information.
  Never _throwLibraryCycleLinkException(
    LibraryCycle cycle,
    Object exception,
    StackTrace stackTrace,
  ) {
    var fileContentMap = <String, String>{};
    for (var library in cycle.libraries) {
      for (var file in library.files) {
        fileContentMap[file.path] = file.content;
      }
    }
    throw CaughtExceptionWithFiles(exception, stackTrace, fileContentMap);
  }
}

class LibraryContextTestData {
  final FileSystemTestData fileSystemTestData;

  /// TODO(scheglov) Use [libraryCycles] and textual dumps for the driver too.
  final List<Set<String>> linkedCycles = [];

  /// Keys: the sorted list of library files.
  final Map<List<FileTestData>, LibraryCycleTestData> libraryCycles =
      LinkedHashMap(
    hashCode: Object.hashAll,
    equals: const ListEquality<FileTestData>().equals,
  );

  LibraryContextTestData({
    required this.fileSystemTestData,
  });

  LibraryCycleTestData forCycle(LibraryCycle cycle) {
    final files = cycle.libraries.map((library) {
      final file = library.file;
      return fileSystemTestData.forFile(file.resource, file.uri);
    }).toList();
    files.sortBy((fileData) => fileData.file.path);

    return libraryCycles[files] ??= LibraryCycleTestData();
  }
}

class LibraryCycleTestData {
  final List<String> getKeys = [];
  final List<String> putKeys = [];
}

class _MacroFileEntry implements MacroFileEntry {
  final FileState fileState;

  _MacroFileEntry(this.fileState);

  @override
  String get content => fileState.content;

  @override
  bool get exists => fileState.exists;
}

class _MacroFileSystem implements MacroFileSystem {
  final FileSystemState fileSystemState;

  _MacroFileSystem(this.fileSystemState);

  @override
  Context get pathContext => fileSystemState.pathContext;

  @override
  MacroFileEntry getFile(String path) {
    var fileState = fileSystemState.getFileForPath(path);
    return _MacroFileEntry(fileState);
  }
}
