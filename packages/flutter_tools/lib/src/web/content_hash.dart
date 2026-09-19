// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p; // flutter_ignore: package_path_import
import 'package:standard_message_codec/standard_message_codec.dart';

import '../base/file_system.dart';
import '../convert.dart';

const List<String> _kKnownHashedExtensions = <String>[
  '.js.map',
  '.wasm.map',
  '.mjs.map',
  '.js',
  '.wasm',
  '.mjs',
];

const Set<String> _kManifestAssetRelativePaths = <String>{
  'AssetManifest.json',
  'AssetManifest.bin',
  'AssetManifest.bin.json',
  'FontManifest.json',
};

/// Result of content-hashing the files and manifests in `build/web/assets/`.
class WebAssetHashResult {
  const WebAssetHashResult({
    required this.renamedFiles,
    this.assetManifestBinJson,
    this.fontManifestJson,
  });

  /// Mapping from original file paths (and normalized paths) to their renamed
  /// content-hashed [File] handles on disk.
  final Map<String, File> renamedFiles;

  /// The content-hashed filename of `AssetManifest.bin.json` (for example,
  /// `AssetManifest.bin.a1b2c3d4.json`), if present.
  final String? assetManifestBinJson;

  /// The content-hashed filename of `FontManifest.json` (for example,
  /// `FontManifest.e5f60718.json`), if present.
  final String? fontManifestJson;
}

String computeHashedBasename(String oldBasename, String contentHash, FileSystem fileSystem) {
  final String doubleExt = fileSystem.path.extension(oldBasename, 2);
  final String ext = _kKnownHashedExtensions.contains(doubleExt)
      ? doubleExt
      : fileSystem.path.extension(oldBasename);
  if (ext.isNotEmpty) {
    final String stem = oldBasename.substring(0, oldBasename.length - ext.length);
    return '$stem.$contentHash$ext';
  }
  return '$oldBasename.$contentHash';
}

WebAssetHashResult hashWebAssets(Directory assetsDir) {
  final renamedFileMap = <String, File>{};
  if (!assetsDir.existsSync()) {
    return WebAssetHashResult(renamedFiles: renamedFileMap);
  }

  final FileSystem fileSystem = assetsDir.fileSystem;
  final List<File> files = assetsDir.listSync(recursive: true).whereType<File>().toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));
  final rawRenamedAssets = <String, String>{};
  final renamedAssets = <String, String>{};

  String hashAndRenameFile(File file, String posixRelativePath) {
    final String relativePath = fileSystem.path.relative(file.path, from: assetsDir.path);
    final List<String> segments = fileSystem.path.split(relativePath);
    final String basename = fileSystem.path.basename(file.path);
    final String contentHash = crypto.sha256
        .convert(file.readAsBytesSync())
        .toString()
        .substring(0, 8);
    final String newBasename = computeHashedBasename(basename, contentHash, fileSystem);

    final newSegments = <String>[...segments.sublist(0, segments.length - 1), newBasename];
    final String newRelativePath = fileSystem.path.joinAll(newSegments);
    final String posixNewPath = p.posix.joinAll(newSegments);

    // Rename the physical file on disk.
    final String newPath = fileSystem.path.join(assetsDir.path, newRelativePath);
    final String oldPath = file.path;
    final String normalizedOldPath = fileSystem.path.normalize(oldPath);
    file.renameSync(newPath);
    final File newFile = fileSystem.file(newPath);
    renamedFileMap[oldPath] = newFile;
    renamedFileMap[normalizedOldPath] = newFile;

    // Map POSIX paths (for manifests). Handle raw, decoded, and encoded paths.
    rawRenamedAssets[posixRelativePath] = posixNewPath;
    renamedAssets[posixRelativePath] = posixNewPath;
    try {
      final String decoded = Uri.decodeFull(posixRelativePath);
      renamedAssets[decoded] = posixNewPath;
    } on FormatException {
      // Retain raw path if malformed percent escape sequence.
    }
    final String encoded = Uri.encodeFull(posixRelativePath);
    renamedAssets[encoded] = posixNewPath;
    return posixNewPath;
  }

  // Pass 1: Hash all physical asset files (including shaders and NOTICES)
  // except the manifest files themselves, whose contents depend on Pass 1 hashes.
  for (final file in files) {
    final String relativePath = fileSystem.path.relative(file.path, from: assetsDir.path);
    final List<String> segments = fileSystem.path.split(relativePath);
    final String posixRelativePath = p.posix.joinAll(segments);

    if (_kManifestAssetRelativePaths.contains(posixRelativePath)) {
      continue;
    }

    hashAndRenameFile(file, posixRelativePath);
  }

  // Pass 2a: Rewrite FontManifest.json and hash it on disk.
  String? hashedFontManifestJson;
  final File fontManifest = assetsDir.childFile('FontManifest.json');
  if (fontManifest.existsSync()) {
    final Object? decodedJson = json.decode(fontManifest.readAsStringSync());
    if (decodedJson is List<dynamic>) {
      for (final Object? font in decodedJson) {
        if (font is Map<String, dynamic>) {
          final Object? fonts = font['fonts'];
          if (fonts is List<dynamic>) {
            for (final Object? fontAsset in fonts) {
              if (fontAsset is Map<String, dynamic>) {
                final Object? asset = fontAsset['asset'];
                if (asset is String && renamedAssets.containsKey(asset)) {
                  fontAsset['asset'] = renamedAssets[asset];
                }
              }
            }
          }
        }
      }
      fontManifest.writeAsStringSync(json.encode(decodedJson));
    }
    hashedFontManifestJson = hashAndRenameFile(fontManifest, 'FontManifest.json');
  }

  // Pass 2b: Rewrite legacy AssetManifest.json if present and hash it on disk.
  final File assetManifestJson = assetsDir.childFile('AssetManifest.json');
  if (assetManifestJson.existsSync()) {
    final Object? decodedJson = json.decode(assetManifestJson.readAsStringSync());
    if (decodedJson is Map<String, dynamic>) {
      final newManifest = <String, dynamic>{};
      final existingTargets = <String>{};
      for (final MapEntry<String, dynamic> entry in decodedJson.entries) {
        existingTargets.add(entry.key);
        existingTargets.add(Uri.encodeFull(entry.key));
        final Object? variants = entry.value;
        if (variants is! List<dynamic>) {
          newManifest[entry.key] = variants;
          continue;
        }
        final newVariants = <String>[];
        for (final Object? variant in variants) {
          if (variant is String) {
            existingTargets.add(variant);
            existingTargets.add(Uri.encodeFull(variant));
            newVariants.add(renamedAssets[variant] ?? variant);
          } else if (variant != null) {
            newVariants.add(variant.toString());
          }
        }
        newManifest[entry.key] = newVariants;
      }
      for (final MapEntry<String, String> entry in rawRenamedAssets.entries) {
        if (!newManifest.containsKey(entry.key) && !existingTargets.contains(entry.key)) {
          newManifest[entry.key] = <String>[entry.value];
        }
      }
      assetManifestJson.writeAsStringSync(json.encode(newManifest));
    }
    hashAndRenameFile(assetManifestJson, 'AssetManifest.json');
  }

  // Pass 2c: Rewrite AssetManifest.bin and AssetManifest.bin.json and hash both on disk.
  String? hashedAssetManifestBinJson;
  final File assetManifestBin = assetsDir.childFile('AssetManifest.bin');
  final File assetManifestBinJson = assetsDir.childFile('AssetManifest.bin.json');
  if (assetManifestBin.existsSync()) {
    final Uint8List rawBytes = assetManifestBin.readAsBytesSync();
    final message = ByteData.sublistView(rawBytes);
    final Object? decoded = const StandardMessageCodec().decodeMessage(message);
    if (decoded is Map<Object?, Object?>) {
      final newManifest = <String, dynamic>{};
      final existingTargets = <String>{};
      for (final MapEntry<Object?, Object?> entry in decoded.entries) {
        final key = entry.key.toString();
        existingTargets.add(key);
        existingTargets.add(Uri.encodeFull(key));
        final Object? variantsVal = entry.value;
        if (variantsVal is! List<Object?>) {
          newManifest[key] = variantsVal;
          continue;
        }
        final newVariants = <dynamic>[];
        for (final Object? variantObj in variantsVal) {
          if (variantObj is! Map<Object?, Object?>) {
            newVariants.add(variantObj);
            continue;
          }
          final newVariantMap = <String, dynamic>{};
          for (final MapEntry<Object?, Object?> vEntry in variantObj.entries) {
            final vKey = vEntry.key.toString();
            if (vKey == 'asset') {
              final vValue = vEntry.value.toString();
              existingTargets.add(vValue);
              existingTargets.add(Uri.encodeFull(vValue));
              newVariantMap[vKey] = renamedAssets[vValue] ?? vValue;
            } else {
              newVariantMap[vKey] = vEntry.value;
            }
          }
          newVariants.add(newVariantMap);
        }
        newManifest[key] = newVariants;
      }
      // Include any hashed files in build/web/assets/ not already covered by
      // manifest entries (such as framework shaders, NOTICES, NOTICES.Z,
      // FontManifest.json, and AssetManifest.json) so that runtime asset lookup
      // can resolve every file in build/web/assets/.
      for (final MapEntry<String, String> entry in rawRenamedAssets.entries) {
        if (!newManifest.containsKey(entry.key) && !existingTargets.contains(entry.key)) {
          newManifest[entry.key] = <Map<String, Object?>>[
            <String, Object?>{'asset': entry.value},
          ];
        }
      }
      final ByteData encoded = const StandardMessageCodec().encodeMessage(newManifest)!;
      final encodedBytes = Uint8List.sublistView(encoded);
      assetManifestBin.writeAsBytesSync(encodedBytes);
      final String hashedAssetManifestBin = hashAndRenameFile(
        assetManifestBin,
        'AssetManifest.bin',
      );

      // Update AssetManifest.bin.json (including the hashed AssetManifest.bin entry)
      // and hash it on disk.
      if (assetManifestBinJson.existsSync()) {
        newManifest['AssetManifest.bin'] = <Map<String, Object?>>[
          <String, Object?>{'asset': hashedAssetManifestBin},
        ];
        final ByteData binJsonEncoded = const StandardMessageCodec().encodeMessage(newManifest)!;
        final binJsonBytes = Uint8List.sublistView(binJsonEncoded);
        assetManifestBinJson.writeAsStringSync(json.encode(base64.encode(binJsonBytes)));
        hashedAssetManifestBinJson = hashAndRenameFile(
          assetManifestBinJson,
          'AssetManifest.bin.json',
        );
      }
    }
  }

  return WebAssetHashResult(
    renamedFiles: renamedFileMap,
    assetManifestBinJson: hashedAssetManifestBinJson,
    fontManifestJson: hashedFontManifestJson,
  );
}

final RegExp _buildConfigPrefixPattern = RegExp(r'_flutter\.buildConfig\s*=\s*\{');

int? _findMatchingClosingBrace(String text, int openBraceIndex) {
  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = openBraceIndex; i < text.length; i++) {
    final int ch = text.codeUnitAt(i);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch == 0x5C /* \ */ ) {
        escaped = true;
      } else if (ch == 0x22 /* " */ ) {
        inString = false;
      }
      continue;
    }
    if (ch == 0x22 /* " */ ) {
      inString = true;
    } else if (ch == 0x7B /* { */ ) {
      depth++;
    } else if (ch == 0x7D /* } */ ) {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return null;
}

String _updateBuildConfigInContent(String content, WebAssetHashResult hashResult) {
  final buffer = StringBuffer();
  var cursor = 0;
  for (final Match match in _buildConfigPrefixPattern.allMatches(content)) {
    if (match.start < cursor) {
      continue;
    }
    final int openBraceIndex = match.end - 1;
    final int? closeBraceIndex = _findMatchingClosingBrace(content, openBraceIndex);
    if (closeBraceIndex == null) {
      continue;
    }
    int endIndex = closeBraceIndex + 1;
    if (endIndex < content.length && content.codeUnitAt(endIndex) == 0x3B /* ; */ ) {
      endIndex++;
    }
    final String jsonPart = content.substring(openBraceIndex, closeBraceIndex + 1);
    try {
      final Object? decoded = json.decode(jsonPart);
      if (decoded is Map<String, Object?>) {
        final updatedMap = <String, Object?>{
          ...decoded,
          if (hashResult.assetManifestBinJson != null)
            'assetManifest': hashResult.assetManifestBinJson,
          if (hashResult.fontManifestJson != null) 'fontManifest': hashResult.fontManifestJson,
        };
        buffer.write(content.substring(cursor, match.start));
        buffer.write('_flutter.buildConfig = ${json.encode(updatedMap)};');
        cursor = endIndex;
      }
    } on FormatException {
      // Leave unchanged if buildConfig is not valid JSON.
    }
  }
  if (cursor == 0) {
    return content;
  }
  buffer.write(content.substring(cursor));
  return buffer.toString();
}

/// Injects `"assetManifest"` and `"fontManifest"` into `_flutter.buildConfig`
/// inside `flutter_bootstrap.js` and `index.html` in [outputDir].
void injectManifestBuildConfig(Directory outputDir, WebAssetHashResult hashResult) {
  if (!outputDir.existsSync()) {
    return;
  }
  if (hashResult.assetManifestBinJson == null && hashResult.fontManifestJson == null) {
    return;
  }
  for (final File file in outputDir.listSync(recursive: true).whereType<File>()) {
    final String basename = file.fileSystem.path.basename(file.path);
    if (basename != 'flutter_bootstrap.js' && basename != 'index.html') {
      continue;
    }
    final String content = file.readAsStringSync();
    if (!content.contains('_flutter.buildConfig')) {
      continue;
    }
    final String updated = _updateBuildConfigInContent(content, hashResult);
    if (updated != content) {
      file.writeAsStringSync(updated);
    }
  }
}

/// The filename of the precache manifest generated for web content hashing.
const String kPrecacheManifestFile = 'precache_manifest.json';

bool _shouldExcludeFromPrecacheManifest({
  required String posixUrl,
  required String basename,
  required List<String> segments,
  required bool useLocalCanvasKit,
}) {
  if (basename.startsWith('.') ||
      posixUrl == kPrecacheManifestFile ||
      posixUrl == 'flutter_service_worker.js') {
    return true;
  }
  if (basename.endsWith('.map') ||
      basename.endsWith('.symbols') ||
      basename.endsWith('.info.json')) {
    return true;
  }
  if (!useLocalCanvasKit && segments.firstOrNull == 'canvaskit') {
    return true;
  }
  return false;
}

/// Writes `precache_manifest.json` in [outputDir] when [enabled] is true, or
/// removes any stale manifest file when [enabled] is false.
File? updatePrecacheManifest(
  Directory outputDir, {
  required bool enabled,
  required bool useLocalCanvasKit,
}) {
  final File manifestFile = outputDir.childFile(kPrecacheManifestFile);
  if (!enabled) {
    if (manifestFile.existsSync()) {
      manifestFile.deleteSync();
    }
    return null;
  }

  if (!outputDir.existsSync()) {
    return null;
  }

  final FileSystem fileSystem = outputDir.fileSystem;
  final List<File> files = outputDir.listSync(recursive: true).whereType<File>().toList();

  final entries = <Map<String, Object>>[];
  for (final file in files) {
    final String relativePath = fileSystem.path.relative(file.path, from: outputDir.path);
    final List<String> segments = fileSystem.path.split(relativePath);
    final String posixUrl = p.posix.joinAll(segments);
    final String basename = segments.last;

    if (_shouldExcludeFromPrecacheManifest(
      posixUrl: posixUrl,
      basename: basename,
      segments: segments,
      useLocalCanvasKit: useLocalCanvasKit,
    )) {
      continue;
    }

    final Uint8List bytes = file.readAsBytesSync();
    final String shortHash = crypto.sha256.convert(bytes).toString().substring(0, 8);
    final bool urlHashed = basename.contains('.$shortHash.') || basename.endsWith('.$shortHash');

    entries.add(<String, Object>{
      'url': posixUrl,
      'hash': shortHash,
      'size': bytes.length,
      'urlHashed': urlHashed,
    });
  }

  entries.sort(
    (Map<String, Object> a, Map<String, Object> b) =>
        (a['url']! as String).compareTo(b['url']! as String),
  );

  manifestFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, Object>{'version': 1, 'entries': entries}),
  );
  return manifestFile;
}
