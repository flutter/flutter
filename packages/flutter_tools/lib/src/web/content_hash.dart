// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p; // flutter_ignore: package_path_import
import 'package:standard_message_codec/standard_message_codec.dart';

import '../base/common.dart';
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
    this.extraAssets = const <String, String>{},
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

  /// Non-manifest files in `build/web/assets/` (such as `NOTICES`, framework
  /// shaders not listed in `AssetManifest.bin`, `AssetManifest.bin`, and
  /// `AssetManifest.json`) mapped from their unhashed relative path to their
  /// content-hashed relative path.
  final Map<String, String> extraAssets;
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
  final decodedRenamedAssets = <String, String>{};

  String decodeSafe(String value) {
    try {
      return Uri.decodeFull(value);
    } on ArgumentError {
      return value;
    }
  }

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
    final String decodedNewPath = decodeSafe(posixNewPath);

    // Rename the physical file on disk.
    final String newPath = fileSystem.path.join(assetsDir.path, newRelativePath);
    final String oldPath = file.path;
    final String normalizedOldPath = fileSystem.path.normalize(oldPath);
    file.renameSync(newPath);
    final File newFile = fileSystem.file(newPath);
    renamedFileMap[oldPath] = newFile;
    renamedFileMap[normalizedOldPath] = newFile;

    // Map POSIX paths:
    // - `renamedAssets` maps to the on-disk `%20`-encoded path (used by FontManifest.json).
    // - `decodedRenamedAssets` maps to the `Uri.decodeFull` path (used by AssetManifest.bin /
    //   AssetManifest.json, matching `_createAssetManifest` in `asset.dart`).
    rawRenamedAssets[posixRelativePath] = posixNewPath;
    renamedAssets[posixRelativePath] = posixNewPath;
    decodedRenamedAssets[posixRelativePath] = decodedNewPath;

    final String decodedOld = decodeSafe(posixRelativePath);
    renamedAssets[decodedOld] = posixNewPath;
    decodedRenamedAssets[decodedOld] = decodedNewPath;

    final String encodedOld = Uri.encodeFull(posixRelativePath);
    renamedAssets[encodedOld] = posixNewPath;
    decodedRenamedAssets[encodedOld] = decodedNewPath;

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

  final manifestCoveredTargets = <String>{};
  void recordManifestTarget(String target) {
    manifestCoveredTargets.add(target);
    manifestCoveredTargets.add(Uri.encodeFull(target));
    manifestCoveredTargets.add(Uri(path: Uri.encodeFull(target)).path);
    final String decoded = decodeSafe(target);
    manifestCoveredTargets.add(decoded);
    manifestCoveredTargets.add(Uri.encodeFull(decoded));
    manifestCoveredTargets.add(Uri(path: Uri.encodeFull(decoded)).path);
  }

  // Pass 2a: Rewrite FontManifest.json and hash it on disk.
  // FontManifest.json keeps the `%20`-encoded `posixNewPath` because `loadAssetFonts`
  // in `web_ui` calls `assetManager.loadAsset` directly without `PlatformAssetBundle`.
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
      for (final MapEntry<String, dynamic> entry in decodedJson.entries) {
        recordManifestTarget(entry.key);
        final Object? variants = entry.value;
        if (variants is! List<dynamic>) {
          newManifest[entry.key] = variants;
          continue;
        }
        final newVariants = <String>[];
        for (final Object? variant in variants) {
          if (variant is String) {
            recordManifestTarget(variant);
            newVariants.add(decodedRenamedAssets[variant] ?? variant);
          } else if (variant != null) {
            newVariants.add(variant.toString());
          }
        }
        newManifest[entry.key] = newVariants;
      }
      assetManifestJson.writeAsStringSync(json.encode(newManifest));
    }
    hashAndRenameFile(assetManifestJson, 'AssetManifest.json');
  }

  // Pass 2c: Rewrite AssetManifest.bin and AssetManifest.bin.json and hash both on disk.
  // Do NOT insert non-manifest SDK files (`NOTICES`, framework shaders, `FontManifest.json`,
  // `AssetManifest.bin`, etc.) into `AssetManifest.bin` or `AssetManifest.bin.json` so that
  // `AssetManifest.loadFromAssetBundle(rootBundle).listAssets()` returns the exact same keys
  // as a build without `--web-content-hash`.
  String? hashedAssetManifestBinJson;
  final File assetManifestBin = assetsDir.childFile('AssetManifest.bin');
  final File assetManifestBinJson = assetsDir.childFile('AssetManifest.bin.json');
  if (assetManifestBin.existsSync()) {
    final Uint8List rawBytes = assetManifestBin.readAsBytesSync();
    final message = ByteData.sublistView(rawBytes);
    final Object? decoded = const StandardMessageCodec().decodeMessage(message);
    if (decoded is Map<Object?, Object?>) {
      final newManifest = <String, dynamic>{};
      for (final MapEntry<Object?, Object?> entry in decoded.entries) {
        final key = entry.key.toString();
        recordManifestTarget(key);
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
              recordManifestTarget(vValue);
              newVariantMap[vKey] = decodedRenamedAssets[vValue] ?? vValue;
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
      hashAndRenameFile(assetManifestBin, 'AssetManifest.bin');

      // Update AssetManifest.bin.json with the same manifest entries and hash it on disk.
      if (assetManifestBinJson.existsSync()) {
        assetManifestBinJson.writeAsStringSync(json.encode(base64.encode(encodedBytes)));
        hashedAssetManifestBinJson = hashAndRenameFile(
          assetManifestBinJson,
          'AssetManifest.bin.json',
        );
      }
    }
  }

  // Collect non-manifest files in `build/web/assets/` (such as `NOTICES`,
  // framework shaders not listed in `pubspec.yaml`, `FontManifest.json`,
  // `AssetManifest.bin`, and `AssetManifest.json`) into `extraAssets` for
  // `_flutter.buildConfig`.
  final extraAssets = <String, String>{};
  for (final MapEntry<String, String> entry in rawRenamedAssets.entries) {
    if (entry.key == 'AssetManifest.bin.json') {
      continue;
    }
    if (!manifestCoveredTargets.contains(entry.key) &&
        !manifestCoveredTargets.contains(decodeSafe(entry.key))) {
      extraAssets[decodeSafe(entry.key)] = entry.value;
    }
  }

  return WebAssetHashResult(
    renamedFiles: renamedFileMap,
    assetManifestBinJson: hashedAssetManifestBinJson,
    fontManifestJson: hashedFontManifestJson,
    extraAssets: extraAssets,
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

String _updateBuildConfigInContent(
  String content,
  WebAssetHashResult hashResult, {
  required String filePath,
}) {
  final Iterable<Match> matches = _buildConfigPrefixPattern.allMatches(content);
  if (matches.isEmpty) {
    throwToolExit(
      'Failed to inject content-hashed asset manifest into $filePath: '
      '"_flutter.buildConfig" is not a JSON object assignment. '
      'Ensure "{{flutter_build_config}}" is used.',
    );
  }
  final buffer = StringBuffer();
  var cursor = 0;
  for (final Match match in matches) {
    if (match.start < cursor) {
      continue;
    }
    final int openBraceIndex = match.end - 1;
    final int? closeBraceIndex = _findMatchingClosingBrace(content, openBraceIndex);
    if (closeBraceIndex == null) {
      throwToolExit(
        'Failed to inject content-hashed asset manifest into $filePath: '
        'unterminated "_flutter.buildConfig" object.',
      );
    }
    int endIndex = closeBraceIndex + 1;
    if (endIndex < content.length && content.codeUnitAt(endIndex) == 0x3B /* ; */ ) {
      endIndex++;
    }
    final String jsonPart = content.substring(openBraceIndex, closeBraceIndex + 1);
    try {
      final Object? decoded = json.decode(jsonPart);
      if (decoded is! Map<String, Object?>) {
        throwToolExit(
          'Failed to inject content-hashed asset manifest into $filePath: '
          '"_flutter.buildConfig" is not a JSON object.',
        );
      }
      final updatedMap = <String, Object?>{
        ...decoded,
        if (hashResult.assetManifestBinJson != null)
          'assetManifest': hashResult.assetManifestBinJson,
        if (hashResult.fontManifestJson != null) 'fontManifest': hashResult.fontManifestJson,
        if (hashResult.extraAssets.isNotEmpty) 'extraAssets': hashResult.extraAssets,
      };
      buffer.write(content.substring(cursor, match.start));
      buffer.write('_flutter.buildConfig = ${json.encode(updatedMap)};');
      cursor = endIndex;
    } on FormatException catch (e) {
      throwToolExit(
        'Failed to inject content-hashed asset manifest into $filePath: '
        '"_flutter.buildConfig" is not valid JSON ($e). '
        'Ensure "{{flutter_build_config}}" is used.',
      );
    }
  }
  if (cursor == 0) {
    return content;
  }
  buffer.write(content.substring(cursor));
  return buffer.toString();
}

/// Injects `"assetManifest"`, `"fontManifest"`, and `"extraAssets"` into
/// `_flutter.buildConfig` inside `flutter_bootstrap.js` and `index.html` in
/// [outputDir].
void injectManifestBuildConfig(Directory outputDir, WebAssetHashResult hashResult) {
  if (!outputDir.existsSync()) {
    return;
  }
  if (hashResult.assetManifestBinJson == null &&
      hashResult.fontManifestJson == null &&
      hashResult.extraAssets.isEmpty) {
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
    final String updated = _updateBuildConfigInContent(content, hashResult, filePath: file.path);
    if (updated != content) {
      file.writeAsStringSync(updated);
    }
  }
  if (hashResult.assetManifestBinJson != null) {
    final File bootstrapFile = outputDir.childFile('flutter_bootstrap.js');
    if (!bootstrapFile.existsSync() ||
        !bootstrapFile.readAsStringSync().contains('"assetManifest"')) {
      throwToolExit(
        'Failed to inject content-hashed "assetManifest" into ${bootstrapFile.path}. '
        'Ensure web/flutter_bootstrap.js contains the "{{flutter_build_config}}" placeholder.',
      );
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
