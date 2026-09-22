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

const Set<String> _kUnhashedAssetRelativePaths = <String>{
  'AssetManifest.json',
  'AssetManifest.bin',
  'AssetManifest.bin.json',
  'FontManifest.json',
  'NOTICES',
  'NOTICES.Z',
};

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

Map<String, File> hashWebAssets(Directory assetsDir) {
  final renamedFileMap = <String, File>{};
  if (!assetsDir.existsSync()) {
    return renamedFileMap;
  }

  final FileSystem fileSystem = assetsDir.fileSystem;
  final List<File> files = assetsDir.listSync(recursive: true).whereType<File>().toList();
  final renamedAssets = <String, String>{};

  for (final file in files) {
    final String relativePath = fileSystem.path.relative(file.path, from: assetsDir.path);
    final List<String> segments = fileSystem.path.split(relativePath);
    final String posixRelativePath = p.posix.joinAll(segments);

    if (_kUnhashedAssetRelativePaths.contains(posixRelativePath) ||
        fileSystem.path.extension(file.path).toLowerCase() == '.frag' ||
        segments.firstOrNull == 'shaders') {
      continue;
    }

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
    renamedAssets[posixRelativePath] = posixNewPath;
    try {
      final String decoded = Uri.decodeFull(posixRelativePath);
      renamedAssets[decoded] = posixNewPath;
    } on FormatException {
      // Retain raw path if malformed percent escape sequence.
    }
    final String encoded = Uri.encodeFull(posixRelativePath);
    renamedAssets[encoded] = posixNewPath;
  }

  // Now update the manifests if they exist.
  final File assetManifestBin = assetsDir.childFile('AssetManifest.bin');
  if (assetManifestBin.existsSync()) {
    final Uint8List rawBytes = assetManifestBin.readAsBytesSync();
    final message = ByteData.sublistView(rawBytes);
    final Object? decoded = const StandardMessageCodec().decodeMessage(message);
    if (decoded is Map<Object?, Object?>) {
      final newManifest = <String, dynamic>{};
      for (final MapEntry<Object?, Object?> entry in decoded.entries) {
        final key = entry.key.toString();
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
              newVariantMap[vKey] = renamedAssets[vValue] ?? vValue;
            } else {
              newVariantMap[vKey] = vEntry.value;
            }
          }
          newVariants.add(newVariantMap);
        }
        newManifest[key] = newVariants;
      }
      final ByteData encoded = const StandardMessageCodec().encodeMessage(newManifest)!;
      final encodedBytes = Uint8List.sublistView(encoded);
      assetManifestBin.writeAsBytesSync(encodedBytes);

      // Update AssetManifest.bin.json
      final File assetManifestBinJson = assetsDir.childFile('AssetManifest.bin.json');
      if (assetManifestBinJson.existsSync()) {
        assetManifestBinJson.writeAsStringSync(json.encode(base64.encode(encodedBytes)));
      }
    }
  }

  // Update legacy AssetManifest.json if present.
  final File assetManifestJson = assetsDir.childFile('AssetManifest.json');
  if (assetManifestJson.existsSync()) {
    final Object? decodedJson = json.decode(assetManifestJson.readAsStringSync());
    if (decodedJson is Map<String, dynamic>) {
      final newManifest = <String, dynamic>{};
      for (final MapEntry<String, dynamic> entry in decodedJson.entries) {
        final Object? variants = entry.value;
        if (variants is! List<dynamic>) {
          newManifest[entry.key] = variants;
          continue;
        }
        final newVariants = <String>[];
        for (final Object? variant in variants) {
          if (variant is String) {
            newVariants.add(renamedAssets[variant] ?? variant);
          } else if (variant != null) {
            newVariants.add(variant.toString());
          }
        }
        newManifest[entry.key] = newVariants;
      }
      assetManifestJson.writeAsStringSync(json.encode(newManifest));
    }
  }

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
  }

  return renamedFileMap;
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
