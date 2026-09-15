// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:meta/meta.dart';

import '../../convert.dart';
import 'native_assets.dart';

/// A path representation for a native code asset in `NativeAssetsManifest.json`.
///
/// See `engine/src/flutter/assets/native_assets.cc` and
/// `engine/src/flutter/runtime/dart_isolate.cc` for the expected engine format.
@immutable
sealed class NativeAssetPath {
  const NativeAssetPath();

  factory NativeAssetPath.fromJson(List<Object?> json) {
    return switch (json) {
      ['absolute', final String path] => NativeAssetAbsolutePath(Uri.file(path)),
      ['system', final String path] => NativeAssetSystemPath(Uri.file(path)),
      ['process'] => const NativeAssetInProcess(),
      ['executable'] => const NativeAssetInExecutable(),
      _ => throw FormatException('Invalid native asset path JSON: $json'),
    };
  }

  List<String> toJson();
}

/// Asset at an absolute or bundle-relative path [uri] on the target device.
final class NativeAssetAbsolutePath extends NativeAssetPath {
  const NativeAssetAbsolutePath(this.uri);

  final Uri uri;

  static const _pathTypeValue = 'absolute';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NativeAssetAbsolutePath && other.uri == uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'NativeAssetAbsolutePath($uri)';

  @override
  List<String> toJson() => <String>[_pathTypeValue, uri.toFilePath()];
}

/// Asset available on the target system's dynamic library search path (`PATH` / `LD_LIBRARY_PATH`).
final class NativeAssetSystemPath extends NativeAssetPath {
  const NativeAssetSystemPath(this.uri);

  final Uri uri;

  static const _pathTypeValue = 'system';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NativeAssetSystemPath && other.uri == uri);

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'NativeAssetSystemPath($uri)';

  @override
  List<String> toJson() => <String>[_pathTypeValue, uri.toFilePath()];
}

/// Asset loaded in the process and available through `DynamicLibrary.process()`.
final class NativeAssetInProcess extends NativeAssetPath {
  const NativeAssetInProcess();

  static const _pathTypeValue = 'process';

  @override
  List<String> toJson() => const <String>[_pathTypeValue];
}

/// Asset embedded in the executable and available through `DynamicLibrary.executable()`.
final class NativeAssetInExecutable extends NativeAssetPath {
  const NativeAssetInExecutable();

  static const _pathTypeValue = 'executable';

  @override
  List<String> toJson() => const <String>[_pathTypeValue];
}

/// The target location of a [FlutterCodeAsset] in a Flutter build.
final class FlutterCodeAssetTargetLocation {
  const FlutterCodeAssetTargetLocation({required this.runtimePath, this.bundlePath});

  /// The path recorded in `NativeAssetsManifest.json` for runtime lookup.
  final NativeAssetPath runtimePath;

  /// The path relative to the native assets build output directory where the
  /// bundled binary/framework should be copied (null if not bundled).
  final Uri? bundlePath;
}

/// Computes the [FlutterCodeAssetTargetLocation] for a [FlutterCodeAsset].
///
/// For [DynamicLoadingBundled] assets, calls [bundledLocationCallback] to
/// determine the OS-specific bundle and runtime paths.
FlutterCodeAssetTargetLocation targetLocationForCodeAsset(
  FlutterCodeAsset asset,
  FlutterCodeAssetTargetLocation Function(FlutterCodeAsset asset) bundledLocationCallback,
) {
  final LinkMode linkMode = asset.codeAsset.linkMode;
  return switch (linkMode) {
    DynamicLoadingSystem(:final uri) => FlutterCodeAssetTargetLocation(
      runtimePath: NativeAssetSystemPath(uri),
    ),
    LookupInExecutable() => const FlutterCodeAssetTargetLocation(
      runtimePath: NativeAssetInExecutable(),
    ),
    LookupInProcess() => const FlutterCodeAssetTargetLocation(runtimePath: NativeAssetInProcess()),
    DynamicLoadingBundled() => bundledLocationCallback(asset),
    _ => throw Exception('Unsupported asset link mode ${linkMode.runtimeType} in asset $asset'),
  };
}

/// Model for `NativeAssetsManifest.json` bundled inside `flutter_assets/`.
final class NativeAssetsManifest {
  const NativeAssetsManifest({required this.assets});

  factory NativeAssetsManifest.fromTargetLocations(
    Map<FlutterCodeAsset, FlutterCodeAssetTargetLocation> targetLocations,
  ) {
    final assetsPerTarget = <String, Map<String, NativeAssetPath>>{};
    for (final MapEntry<FlutterCodeAsset, FlutterCodeAssetTargetLocation>(
          key: asset,
          value: location,
        )
        in targetLocations.entries) {
      final Map<String, NativeAssetPath> targetMap = assetsPerTarget.putIfAbsent(
        asset.targetString,
        () => <String, NativeAssetPath>{},
      );
      targetMap[asset.codeAsset.id] = location.runtimePath;
    }
    return NativeAssetsManifest(assets: assetsPerTarget);
  }

  factory NativeAssetsManifest.fromJson(Map<String, Object?> json) {
    final Object? nativeAssetsJson = json[_nativeAssetsKey];
    if (nativeAssetsJson is! Map<String, Object?>) {
      return const NativeAssetsManifest(assets: <String, Map<String, NativeAssetPath>>{});
    }
    final assets = <String, Map<String, NativeAssetPath>>{};
    for (final MapEntry<String, Object?>(key: targetString, value: targetAssets)
        in nativeAssetsJson.entries) {
      if (targetAssets is! Map<String, Object?>) {
        continue;
      }
      final targetMap = <String, NativeAssetPath>{};
      for (final MapEntry<String, Object?>(key: assetId, value: pathInfo) in targetAssets.entries) {
        if (pathInfo is List<Object?>) {
          targetMap[assetId] = NativeAssetPath.fromJson(pathInfo);
        }
      }
      assets[targetString] = targetMap;
    }
    return NativeAssetsManifest(assets: assets);
  }

  static const _formatVersionKey = 'format-version';
  static const _nativeAssetsKey = 'native-assets';

  /// Mapping from target string (e.g. `macos_arm64`) to a map from asset ID
  /// to its runtime [NativeAssetPath].
  final Map<String, Map<String, NativeAssetPath>> assets;

  Map<String, Object> toJson() => <String, Object>{
    _formatVersionKey: const <int>[1, 0, 0],
    _nativeAssetsKey: <String, Map<String, List<String>>>{
      for (final MapEntry<String, Map<String, NativeAssetPath>>(
            key: targetString,
            value: targetAssets,
          )
          in assets.entries)
        targetString: <String, List<String>>{
          for (final MapEntry<String, NativeAssetPath>(key: assetId, value: path)
              in targetAssets.entries)
            assetId: path.toJson(),
        },
    },
  };

  String toJsonString() => jsonEncode(toJson());
}
