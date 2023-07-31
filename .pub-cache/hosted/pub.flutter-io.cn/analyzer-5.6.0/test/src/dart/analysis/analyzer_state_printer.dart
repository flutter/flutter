// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_context.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

class AnalyzerStatePrinter {
  final MemoryByteStore byteStore;
  final IdProvider idProvider;
  final LibraryContext libraryContext;
  final bool omitSdkFiles;
  final ResourceProvider resourceProvider;
  final StringSink sink;
  final bool withKeysGetPut;

  String _indent = '';
  final Set<LibraryCycle> _libraryCyclesWithWrittenDetails = Set.identity();

  AnalyzerStatePrinter({
    required this.byteStore,
    required this.idProvider,
    required this.libraryContext,
    required this.omitSdkFiles,
    required this.resourceProvider,
    required this.sink,
    required this.withKeysGetPut,
  });

  FileSystemState get fileSystemState => libraryContext.fileSystemState;

  void writeAnalysisDriver(AnalysisDriverTestView testData) {
    _writeFiles(testData.fileSystem);
    _writeLibraryContext(testData.libraryContext);
    _writeElementFactory();
  }

  void writeFileResolver(FileResolverTestData testData) {
    _writeFiles(testData.fileSystem);
    _writeLibraryContext(testData.libraryContext);
    _writeElementFactory();
    _writeByteStore();
  }

  /// If the path style is `Windows`, returns the corresponding Posix path.
  /// Otherwise the path is already a Posix path, and it is returned as is.
  String _posixPath(File file) {
    final pathContext = resourceProvider.pathContext;
    if (pathContext.style == Style.windows) {
      final components = pathContext.split(file.path);
      return '/${components.skip(1).join('/')}';
    } else {
      return file.path;
    }
  }

  String _stringOfLibraryCycle(LibraryCycle cycle) {
    if (omitSdkFiles) {
      final isSdkLibrary = cycle.libraries.any((library) {
        return library.file.uri.isScheme('dart');
      });
      if (isSdkLibrary) {
        if (cycle.libraries.any((e) => e.file.uriStr == 'dart:core')) {
          return 'dart:core';
        } else {
          throw UnimplementedError('$cycle');
        }
      }
    }
    return idProvider.libraryCycle(cycle);
  }

  String _stringOfUriStr(String uriStr) {
    if (uriStr.trim().isEmpty) {
      return "'$uriStr'";
    } else {
      return uriStr;
    }
  }

  void _withIndent(void Function() f) {
    var indent = _indent;
    _indent = '$_indent  ';
    f();
    _indent = indent;
  }

  void _writeAugmentationImports(LibraryOrAugmentationFileKind container) {
    _writeElements<AugmentationImportState>(
      'augmentationImports',
      container.augmentationImports,
      (import) {
        if (import is AugmentationImportWithFile) {
          expect(import.container, same(container));
          final file = import.importedFile;
          sink.write(_indent);

          final importedAugmentation = import.importedAugmentation;
          if (importedAugmentation != null) {
            expect(importedAugmentation.file, file);
            sink.write(idProvider.fileKind(importedAugmentation));
          } else {
            sink.write('notAugmentation ${idProvider.fileState(file)}');
          }
          sink.writeln();
        } else if (import is AugmentationImportWithUri) {
          _writelnWithIndent('uri: ${import.uri.relativeUri}');
        } else if (import is AugmentationImportWithUriStr) {
          final uriStr = _stringOfUriStr(import.uri.relativeUriStr);
          _writelnWithIndent('uriStr: $uriStr');
        } else {
          _writelnWithIndent('noUriStr');
        }
      },
    );
  }

  void _writeByteStore() {
    _writelnWithIndent('byteStore');
    _withIndent(() {
      final groups = byteStore.map.entries.groupListsBy((element) {
        return element.value.refCount;
      });

      for (final groupEntry in groups.entries) {
        final keys = groupEntry.value.map((e) => e.key).toList();
        final shortKeys = idProvider.shortKeys(keys)..sort();
        _writelnWithIndent('${groupEntry.key}: $shortKeys');
      }
    });
  }

  void _writeElementFactory() {
    _writelnWithIndent('elementFactory');
    _withIndent(() {
      final elementFactory = libraryContext.elementFactory;
      _writeUriList(
        'hasElement',
        elementFactory.uriListWithLibraryElements,
      );
      _writeUriList(
        'hasReader',
        elementFactory.uriListWithLibraryReaders,
      );
    });
  }

  void _writeElements<T>(String name, List<T> elements, void Function(T) f) {
    if (elements.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var element in elements) {
          f(element);
        }
      });
    }
  }

  void _writeFile(FileState file) {
    _withIndent(() {
      _writelnWithIndent('id: ${idProvider.fileState(file)}');
      _writeFileKind(file);
      _writeReferencingFiles(file);
      _writeFileUnlinkedKey(file);
    });
  }

  void _writeFileKind(FileState file) {
    final kind = file.kind;
    expect(kind.file, same(file));

    _writelnWithIndent('kind: ${idProvider.fileKind(kind)}');
    if (kind is AugmentationKnownFileKind) {
      _withIndent(() {
        final augmented = kind.augmented;
        if (augmented != null) {
          final id = idProvider.fileKind(augmented);
          _writelnWithIndent('augmented: $id');
        } else {
          final id = idProvider.fileState(kind.uriFile);
          _writelnWithIndent('uriFile: $id');
        }

        final library = kind.library;
        if (library != null) {
          final id = idProvider.fileKind(library);
          _writelnWithIndent('library: $id');
        }

        _writeLibraryImports(kind);
        _writeLibraryExports(kind);
        _writeAugmentationImports(kind);
      });
    } else if (kind is AugmentationUnknownFileKind) {
      _withIndent(() {
        _writelnWithIndent('uri: ${kind.unlinked.uri}');
      });
    } else if (kind is LibraryFileKind) {
      expect(kind.library, same(kind));

      _withIndent(() {
        final name = kind.name;
        if (name != null) {
          _writelnWithIndent('name: $name');
        }

        _writeLibraryImports(kind);
        _writeLibraryExports(kind);
        _writeAugmentationImports(kind);
        _writeLibraryParts(kind);
        _writeLibraryCycle(kind);
      });
    } else if (kind is PartOfNameFileKind) {
      _withIndent(() {
        final libraries = kind.libraries;
        if (libraries.isNotEmpty) {
          final keys = libraries
              .map(idProvider.fileKind)
              .sorted(compareNatural)
              .join(' ');
          _writelnWithIndent('libraries: $keys');
        }

        final library = kind.library;
        if (library != null) {
          final id = idProvider.fileKind(library);
          _writelnWithIndent('library: $id');
        } else {
          _writelnWithIndent('name: ${kind.unlinked.name}');
        }
      });
    } else if (kind is PartOfUriKnownFileKind) {
      _withIndent(() {
        final library = kind.library;
        if (library != null) {
          final id = idProvider.fileKind(library);
          _writelnWithIndent('library: $id');
        } else {
          final id = idProvider.fileState(kind.uriFile);
          _writelnWithIndent('uriFile: $id');
        }
      });
    } else if (kind is PartOfUriUnknownFileKind) {
      _withIndent(() {
        _writelnWithIndent('uri: ${kind.unlinked.uri}');
        expect(kind.library, isNull);
      });
    } else {
      throw UnimplementedError('${kind.runtimeType}');
    }
  }

  void _writeFiles(FileSystemTestData testData) {
    fileSystemState.pullReferencedFiles();

    // Discover libraries for parts.
    // This is required for consistency checking.
    for (final fileData in testData.files.values.toList()) {
      final current = fileSystemState.getExisting(fileData.file);
      if (current != null) {
        final kind = current.kind;
        if (kind is PartOfNameFileKind) {
          kind.discoverLibraries();
        }
      }
    }

    // Discover referenced files.
    // This is required for consistency checking.
    for (final fileData in testData.files.values.toList()) {
      final current = fileSystemState.getExisting(fileData.file);
      if (current != null) {
        final kind = current.kind;
        if (kind is LibraryOrAugmentationFileKind) {
          kind.discoverReferencedFiles();
        }
      }
    }

    // Sort, mostly by path.
    // But sort SDK libraries to the end, with `dart:core` first.
    final fileDataList = testData.files.values.toList();
    fileDataList.sort((first, second) {
      final firstPath = first.file.path;
      final secondPath = second.file.path;
      if (omitSdkFiles) {
        final firstUri = first.uri;
        final secondUri = second.uri;
        final firstIsSdk = firstUri.isScheme('dart');
        final secondIsSdk = secondUri.isScheme('dart');
        if (firstIsSdk && !secondIsSdk) {
          return 1;
        } else if (!firstIsSdk && secondIsSdk) {
          return -1;
        } else if (firstIsSdk && secondIsSdk) {
          if ('$firstUri' == 'dart:core') {
            return -1;
          } else if ('$secondUri' == 'dart:core') {
            return 1;
          }
        }
      }
      return firstPath.compareTo(secondPath);
    });

    // Ask ID for every file in the sorted order, so that IDs are nice.
    // Register objects that can be referenced.
    idProvider.resetRegisteredObject();
    for (final fileData in fileDataList) {
      final current = fileSystemState.getExisting(fileData.file);
      if (current != null) {
        idProvider.registerFileState(current);
        final kind = current.kind;
        idProvider.registerFileKind(kind);
        if (kind is LibraryFileKind) {
          idProvider.registerLibraryCycle(kind.libraryCycle);
        }
      }
    }

    _writelnWithIndent('files');
    _withIndent(() {
      for (final fileData in fileDataList) {
        if (omitSdkFiles && fileData.uri.isScheme('dart')) {
          continue;
        }
        final file = fileData.file;
        _writelnWithIndent(_posixPath(file));
        _withIndent(() {
          _writelnWithIndent('uri: ${fileData.uri}');

          final current = fileSystemState.getExisting(file);
          if (current != null) {
            _writelnWithIndent('current');
            _writeFile(current);
          }

          if (withKeysGetPut) {
            final shortGets = idProvider.shortKeys(fileData.unlinkedKeyGet);
            final shortPuts = idProvider.shortKeys(fileData.unlinkedKeyPut);
            _writelnWithIndent('unlinkedGet: $shortGets');
            _writelnWithIndent('unlinkedPut: $shortPuts');
          }
        });
      }
    });
  }

  void _writeFileUnlinkedKey(FileState file) {
    final unlinkedShort = idProvider.shortKey(file.unlinkedKey);
    _writelnWithIndent('unlinkedKey: $unlinkedShort');
  }

  void _writeLibraryContext(LibraryContextTestData testData) {
    _writelnWithIndent('libraryCycles');
    _withIndent(() {
      final cyclesToPrint = <_LibraryCycleToPrint>[];
      for (final entry in testData.libraryCycles.entries) {
        if (omitSdkFiles && entry.key.any((e) => e.uri.isScheme('dart'))) {
          continue;
        }
        cyclesToPrint.add(
          _LibraryCycleToPrint(
            entry.key.map((e) => _posixPath(e.file)).join(' '),
            entry.value,
          ),
        );
      }
      cyclesToPrint.sortBy((e) => e.pathListStr);

      final loadedBundlesMap = Map.fromEntries(
        libraryContext.loadedBundles.map((cycle) {
          final pathListStr = cycle.libraries
              .map((library) => _posixPath(library.file.resource))
              .sorted()
              .join(' ');
          return MapEntry(pathListStr, cycle);
        }),
      );

      for (final cycleToPrint in cyclesToPrint) {
        _writelnWithIndent(cycleToPrint.pathListStr);
        _withIndent(() {
          final current = loadedBundlesMap[cycleToPrint.pathListStr];
          if (current != null) {
            final id = idProvider.libraryCycle(current);
            _writelnWithIndent('current: $id');
            _withIndent(() {
              // TODO(scheglov) Print it with the cycle instead?
              final short = idProvider.shortKey(current.linkedKey);
              _writelnWithIndent('key: $short');
            });
          }

          final cycleData = cycleToPrint.data;
          final shortGets = idProvider.shortKeys(cycleData.getKeys);
          final shortPuts = idProvider.shortKeys(cycleData.putKeys);
          _writelnWithIndent('get: $shortGets');
          _writelnWithIndent('put: $shortPuts');
        });
      }
    });
  }

  void _writeLibraryCycle(LibraryFileKind library) {
    final cycle = library.libraryCycle;
    _writelnWithIndent(idProvider.libraryCycle(cycle));

    if (!_libraryCyclesWithWrittenDetails.add(cycle)) {
      return;
    }

    _withIndent(() {
      final dependencyIds = cycle.directDependencies
          .map(_stringOfLibraryCycle)
          .sorted(compareNatural)
          .join(' ');
      if (dependencyIds.isNotEmpty) {
        _writelnWithIndent('dependencies: $dependencyIds');
      } else {
        _writelnWithIndent('dependencies: none');
      }

      final libraryIds = cycle.libraries
          .map(idProvider.fileKind)
          .sorted(compareNatural)
          .join(' ');
      _writelnWithIndent('libraries: $libraryIds');

      _writelnWithIndent(idProvider.apiSignature(cycle.apiSignature));

      final userIds = cycle.directUsers
          .map(_stringOfLibraryCycle)
          .sorted(compareNatural)
          .join(' ');
      if (userIds.isNotEmpty) {
        _writelnWithIndent('users: $userIds');
      }
    });
  }

  void _writeLibraryExports(LibraryOrAugmentationFileKind container) {
    _writeElements<LibraryExportState>(
      'libraryExports',
      container.libraryExports,
      (export) {
        if (export is LibraryExportWithFile) {
          expect(export.container, same(container));
          final file = export.exportedFile;
          sink.write(_indent);

          final exportedLibrary = export.exportedLibrary;
          if (exportedLibrary != null) {
            expect(exportedLibrary.file, file);
            sink.write(idProvider.fileKind(exportedLibrary));
          } else {
            sink.write('notLibrary ${idProvider.fileState(file)}');
          }

          if (omitSdkFiles && file.uri.isScheme('dart')) {
            sink.write(' ${file.uri}');
          }
          sink.writeln();
        } else if (export is LibraryExportWithInSummarySource) {
          sink.write(_indent);
          sink.write('inSummary ${export.exportedSource.uri}');

          final librarySource = export.exportedLibrarySource;
          if (librarySource != null) {
            expect(librarySource, same(export.exportedSource));
          } else {
            sink.write(' notLibrary');
          }
          sink.writeln();
        } else if (export is LibraryExportWithUri) {
          _writelnWithIndent('uri: ${export.selectedUri.relativeUri}');
        } else if (export is LibraryExportWithUriStr) {
          final uriStr = _stringOfUriStr(export.selectedUri.relativeUriStr);
          _writelnWithIndent('uriStr: $uriStr');
        } else {
          _writelnWithIndent('noUriStr');
        }
      },
    );
  }

  void _writeLibraryImports(LibraryOrAugmentationFileKind container) {
    _writeElements<LibraryImportState>(
      'libraryImports',
      container.libraryImports,
      (import) {
        if (import is LibraryImportWithFile) {
          expect(import.container, same(container));
          final file = import.importedFile;
          sink.write(_indent);

          final importedLibrary = import.importedLibrary;
          if (importedLibrary != null) {
            expect(importedLibrary.file, file);
            sink.write(idProvider.fileKind(importedLibrary));
          } else {
            sink.write('notLibrary ${idProvider.fileState(file)}');
          }

          if (omitSdkFiles && file.uri.isScheme('dart')) {
            sink.write(' ${file.uri}');
          }

          if (import.isSyntheticDartCore) {
            sink.write(' synthetic');
          }
          sink.writeln();
        } else if (import is LibraryImportWithInSummarySource) {
          sink.write(_indent);
          sink.write('inSummary ${import.importedSource.uri}');

          final librarySource = import.importedLibrarySource;
          if (librarySource != null) {
            expect(librarySource, same(import.importedSource));
          } else {
            sink.write(' notLibrary');
          }

          if (import.isSyntheticDartCore) {
            sink.write(' synthetic');
          }
          sink.writeln();
        } else if (import is LibraryImportWithUri) {
          sink.write(_indent);
          sink.write('uri: ${import.selectedUri.relativeUri}');
          if (import.isSyntheticDartCore) {
            sink.write(' synthetic');
          }
          sink.writeln();
        } else if (import is LibraryImportWithUriStr) {
          final uriStr = _stringOfUriStr(import.selectedUri.relativeUriStr);
          sink.write(_indent);
          sink.write('uriStr: $uriStr');
          if (import.isSyntheticDartCore) {
            sink.write(' synthetic');
          }
          sink.writeln();
        } else {
          _writelnWithIndent('noUriStr');
        }
      },
    );
  }

  void _writeLibraryParts(LibraryFileKind library) {
    _writeElements<PartState>('parts', library.parts, (part) {
      expect(part.library, same(library));
      if (part is PartWithFile) {
        final file = part.includedFile;
        sink.write(_indent);

        final includedPart = part.includedPart;
        if (includedPart != null) {
          expect(includedPart.file, file);
          sink.write(idProvider.fileKind(includedPart));
        } else {
          sink.write('notPart ${idProvider.fileState(file)}');
        }
        sink.writeln();
      } else if (part is PartWithUri) {
        final uriStr = _stringOfUriStr(part.uri.relativeUriStr);
        _writelnWithIndent('uri: $uriStr');
      } else {
        _writelnWithIndent('noUri');
      }
    });
  }

  void _writelnWithIndent(String line) {
    sink.write(_indent);
    sink.writeln(line);
  }

  void _writeReferencingFiles(FileState file) {
    final referencingFiles = file.referencingFiles;
    if (referencingFiles.isNotEmpty) {
      final fileIds = referencingFiles
          .map(idProvider.fileState)
          .sorted(compareNatural)
          .join(' ');
      _writelnWithIndent('referencingFiles: $fileIds');
    }
  }

  void _writeUriList(String name, Iterable<Uri> uriIterable) {
    final uriStrList = <String>[];
    for (final uri in uriIterable) {
      if (omitSdkFiles && uri.isScheme('dart')) {
        continue;
      }
      uriStrList.add('$uri');
    }

    if (uriStrList.isNotEmpty) {
      uriStrList.sort();
      _writelnWithIndent(name);
      _withIndent(() {
        for (final uriStr in uriStrList) {
          _writelnWithIndent(uriStr);
        }
      });
    }
  }
}

/// Encoder of object identifies into short identifiers.
class IdProvider {
  final Map<FileState, String> _fileState = Map.identity();
  final Map<LibraryCycle, String> _libraryCycle = Map.identity();
  final Map<FileKind, String> _fileKind = Map.identity();
  final Map<String, String> _keyToShort = {};
  final Map<String, String> _shortToKey = {};
  final Map<String, String> _apiSignature = {};

  Set<FileState> _currentFiles = {};
  Set<FileKind> _currentFileKinds = {};
  Set<LibraryCycle> _currentCycles = {};

  String apiSignature(String signature) {
    final length = _apiSignature.length;
    return _apiSignature[signature] ??= 'apiSignature_$length';
  }

  String fileKind(FileKind kind) {
    if (!_currentFileKinds.contains(kind)) {
      throw StateError('$kind');
    }
    return _fileKind[kind] ??= () {
      if (kind is AugmentationKnownFileKind) {
        return 'augmentation_${_fileKind.length}';
      } else if (kind is AugmentationUnknownFileKind) {
        return 'augmentationUnknown_${_fileKind.length}';
      } else if (kind is LibraryFileKind) {
        return 'library_${_fileKind.length}';
      } else if (kind is PartOfNameFileKind) {
        return 'partOfName_${_fileKind.length}';
      } else if (kind is PartOfUriKnownFileKind) {
        return 'partOfUriKnown_${_fileKind.length}';
      } else if (kind is PartFileKind) {
        return 'partOfUriUnknown_${_fileKind.length}';
      } else {
        throw UnimplementedError('${kind.runtimeType}');
      }
    }();
  }

  String fileState(FileState file) {
    if (!_currentFiles.contains(file)) {
      throw StateError('$file');
    }
    return _fileState[file] ??= 'file_${_fileState.length}';
  }

  String libraryCycle(LibraryCycle cycle) {
    if (!_currentCycles.contains(cycle)) {
      throw StateError('$cycle');
    }
    return _libraryCycle[cycle] ??= 'cycle_${_libraryCycle.length}';
  }

  /// Register that [kind] is an object that can be referenced.
  void registerFileKind(FileKind kind) {
    if (_currentFileKinds.contains(kind)) {
      throw StateError('Duplicate: $kind');
    }
    _currentFileKinds.add(kind);
    fileKind(kind);
  }

  /// Register that [file] is an object that can be referenced.
  void registerFileState(FileState file) {
    if (_currentFiles.contains(file)) {
      throw StateError('Duplicate: $file');
    }
    _currentFiles.add(file);
    fileState(file);
  }

  /// Register that [cycle] is an object that can be referenced.
  void registerLibraryCycle(LibraryCycle cycle) {
    _currentCycles.add(cycle);
    libraryCycle(cycle);
  }

  void resetRegisteredObject() {
    _currentFiles = {};
    _currentFileKinds = {};
    _currentCycles = {};
  }

  String shortKey(String key) {
    var short = _keyToShort[key];
    if (short == null) {
      short = 'k${_keyToShort.length.toString().padLeft(2, '0')}';
      _keyToShort[key] = short;
      _shortToKey[short] = key;
    }
    return short;
  }

  List<String> shortKeys(List<String> keys) {
    return keys.map(shortKey).toList();
  }
}

class _LibraryCycleToPrint {
  final String pathListStr;
  final LibraryCycleTestData data;

  _LibraryCycleToPrint(this.pathListStr, this.data);
}
