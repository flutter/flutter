// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../base/file_system.dart';
import '../base/utils.dart';
import '../convert.dart';

const String _kCode = 'code';
const String _kImportUri = 'importUri';
const String _kLibraries = 'libraries';
const String _kMetadata = 'metadata';
const String _kMetadataExtension = '.metadata';
const String _kSourceMapExtension = '.map';
const String _kSourcemap = 'sourcemap';

/// A pseudo-filesystem stored in memory.
///
/// To support output to arbitrary multi-root file schemes, the frontend server
/// will output web sources, sourcemaps, and metadata to concatenated single files
/// with an additional manifest file containing the correct offsets.
class WebMemoryFS {
  final metadataFiles = <String, Uint8List>{};
  final files = <String, Uint8List>{};
  final sourcemaps = <String, Uint8List>{};

  // Maps each module file name (e.g. 'packages/app/main.dart.lib.js') to the
  // set of Dart library import URIs (e.g. 'package:app/main.dart') compiled
  // into that module. Used to track library ownership across compilations.
  final _moduleToLibraries = <String, Set<String>>{};

  String? get mergedMetadata => _mergedMetadata;
  String? _mergedMetadata;

  /// Parses the set of Dart library import URIs from a module's `.metadata`
  /// JSON payload.
  Set<String> _parseLibraries(Uint8List metadataBytes) {
    try {
      final Map<String, Object?>? metadataJson = castStringKeyedMap(
        json.decode(utf8.decode(metadataBytes)),
      );
      if (metadataJson?[_kLibraries] case final List<Object?> libraries) {
        final result = <String>{};
        for (final lib in libraries) {
          if (lib case {_kImportUri: final String importUri}) {
            result.add(importUri);
          }
        }
        return result;
      }
    } on Exception {
      // Ignore if metadata is not valid JSON or does not contain libraries.
    }
    return const <String>{};
  }

  /// Update the filesystem with the provided source and manifest files.
  ///
  /// Returns the list of updated files.
  List<String> write(File codeFile, File manifestFile, File sourcemapFile, File metadataFile) {
    final modules = <String>[];
    final Uint8List codeBytes = codeFile.readAsBytesSync();
    final Uint8List sourcemapBytes = sourcemapFile.readAsBytesSync();
    final Uint8List metadataBytes = metadataFile.readAsBytesSync();
    final Map<String, Object?> manifest = castStringKeyedMap(
      json.decode(manifestFile.readAsStringSync()),
    )!;

    // Collect all newly compiled modules and parse their metadata to identify
    // which Dart libraries they contain.
    final newModules = <String, _CompiledModule>{};

    for (final String filePath in manifest.keys) {
      final Map<String, Object?> offsets = castStringKeyedMap(manifest[filePath])!;
      if (offsets case {
        _kCode: [final int codeStart, final int codeEnd],
        _kSourcemap: [final int sourcemapStart, final int sourcemapEnd],
        _kMetadata: [final int metadataStart, final int metadataEnd],
      }) {
        if (codeStart < 0 || codeEnd > codeBytes.lengthInBytes) {
          continue;
        }
        if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
          continue;
        }
        if (metadataStart < 0 || metadataEnd > metadataBytes.lengthInBytes) {
          continue;
        }

        final byteView = Uint8List.view(codeBytes.buffer, codeStart, codeEnd - codeStart);
        final sourcemapView = Uint8List.view(
          sourcemapBytes.buffer,
          sourcemapStart,
          sourcemapEnd - sourcemapStart,
        );
        final metadataView = Uint8List.view(
          metadataBytes.buffer,
          metadataStart,
          metadataEnd - metadataStart,
        );
        final String fileName = filePath.startsWith('/') ? filePath.substring(1) : filePath;

        newModules[fileName] = (
          code: byteView,
          sourcemap: sourcemapView,
          metadata: metadataView,
          libraries: _parseLibraries(metadataView),
        );
      }
    }

    final allNewLibraries = <String>{for (final module in newModules.values) ...module.libraries};

    // Check if any previously compiled modules contain libraries that have now
    // been compiled into one of the new modules (e.g. when breaking an import
    // cycle causes libraries previously bundled together into a single module
    // to be compiled into separate modules).
    //
    // The incremental compiler only emits changed modules in its manifest and
    // will not report the old bundled module as deleted. If the stale module is
    // not evicted, DWDS will attempt to load both the stale and updated modules
    // in main_module.bootstrap.js, causing the stale module to load first and
    // shadow the updated application when reloading the browser tab.
    if (allNewLibraries.isNotEmpty) {
      final modulesToRemove = <String>{};
      for (final String metadataName in metadataFiles.keys) {
        if (!metadataName.endsWith(_kMetadataExtension)) {
          continue;
        }
        final String moduleFileName = metadataName.substring(
          0,
          metadataName.length - _kMetadataExtension.length,
        );
        if (newModules.containsKey(moduleFileName)) {
          continue;
        }
        final Set<String> existingLibraries = _moduleToLibraries[moduleFileName] ??=
            _parseLibraries(metadataFiles[metadataName]!);
        if (existingLibraries.any(allNewLibraries.contains)) {
          modulesToRemove.add(moduleFileName);
        }
      }

      // Evict any stale modules from memory and internal caches.
      for (final module in modulesToRemove) {
        _moduleToLibraries.remove(module);
        files.remove(module);
        sourcemaps.remove('$module$_kSourceMapExtension');
        metadataFiles.remove('$module$_kMetadataExtension');
      }
    }

    // Store the updated module files, sourcemaps, and metadata.
    for (final MapEntry(key: String fileName, value: _CompiledModule module)
        in newModules.entries) {
      files[fileName] = module.code;
      sourcemaps['$fileName$_kSourceMapExtension'] = module.sourcemap;
      metadataFiles['$fileName$_kMetadataExtension'] = module.metadata;
      _moduleToLibraries[fileName] = module.libraries;
      modules.add(fileName);
    }

    _mergedMetadata = metadataFiles.values
        .map((Uint8List encoded) => utf8.decode(encoded))
        .join('\n');

    return modules;
  }
}

typedef _CompiledModule = ({
  Uint8List code,
  Set<String> libraries,
  Uint8List metadata,
  Uint8List sourcemap,
});
