// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import '../base/file_system.dart';
import '../base/utils.dart';
import '../convert.dart';

/// A pseudo-filesystem stored in memory.
///
/// To support output to arbitrary multi-root file schemes, the frontend server
/// will output web sources, sourcemaps, and metadata to concatenated single files
/// with an additional manifest file containing the correct offsets.
class WebMemoryFS {
  final metadataFiles = <String, Uint8List>{};
  final files = <String, Uint8List>{};
  final sourcemaps = <String, Uint8List>{};

  String? get mergedMetadata => _mergedMetadata;
  String? _mergedMetadata;

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
    for (final MapEntry(key: filePath, value: offsets) in manifest.entries) {
      if (offsets case {
        'code': [final int codeStart, final int codeEnd],
        'sourcemap': [final int sourcemapStart, final int sourcemapEnd],
        'metadata': [final int metadataStart, final int metadataEnd],
      }) {
        if (codeStart < 0 || codeEnd > codeBytes.lengthInBytes) {
          continue;
        }
        final byteView = Uint8List.view(codeBytes.buffer, codeStart, codeEnd - codeStart);
        final String fileName = filePath.startsWith('/') ? filePath.substring(1) : filePath;
        files[fileName] = byteView;

        if (sourcemapStart < 0 || sourcemapEnd > sourcemapBytes.lengthInBytes) {
          continue;
        }
        final sourcemapView = Uint8List.view(
          sourcemapBytes.buffer,
          sourcemapStart,
          sourcemapEnd - sourcemapStart,
        );
        final sourcemapName = '$fileName.map';
        sourcemaps[sourcemapName] = sourcemapView;

        if (metadataStart < 0 || metadataEnd > metadataBytes.lengthInBytes) {
          continue;
        }
        final metadataView = Uint8List.view(
          metadataBytes.buffer,
          metadataStart,
          metadataEnd - metadataStart,
        );
        final metadataName = '$fileName.metadata';
        metadataFiles[metadataName] = metadataView;

        modules.add(fileName);
      }
    }

    _mergedMetadata = metadataFiles.values
        .map((Uint8List encoded) => utf8.decode(encoded))
        .join('\n');

    return modules;
  }
}
