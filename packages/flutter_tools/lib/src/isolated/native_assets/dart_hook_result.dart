// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:hooks_runner/hooks_runner.dart';
import '../../asset.dart' show FlutterHookResult, HookAsset;
import 'native_assets.dart' show FlutterCodeAsset;

/// The assets produced by a Dart hook run and the dependencies of those assets.
///
/// If any of the dependencies change, then the Dart build should be performed
/// again.
final class DartHooksResult {
  const DartHooksResult({
    required this.buildStart,
    required this.buildEnd,
    required this.codeAssets,
    required this.dataAssets,
    required this.dependencies,
  });

  DartHooksResult.empty()
    : buildStart = DateTime.now(),
      buildEnd = DateTime.now(),
      codeAssets = const <FlutterCodeAsset>[],
      dataAssets = const <DataAsset>[],
      dependencies = const <Uri>[];

  factory DartHooksResult.fromJson(Map<String, Object?> json) {
    if (json case {
      _buildStartKey: final String buildStartString,
      _buildEndKey: final String buildEndString,
      _dependenciesKey: final List<Object?>? dependenciesList,
      _codeAssetsKey: final List<Object?> codeAssetsList,
      _dataAssetsKey: final List<Object?>? dataAssetsList,
    }) {
      final DateTime buildStart = DateTime.parse(buildStartString);
      final DateTime buildEnd = DateTime.parse(buildEndString);
      final dependencies = <Uri>[
        for (final Object? encodedUri in dependenciesList ?? <Object?>[])
          Uri.parse(encodedUri! as String),
      ];
      final codeAssets = <FlutterCodeAsset>[
        for (final (Map<String, Object?> codeAsset, String target) in codeAssetsList.map(
          (Object? codeJson) => switch (codeJson) {
            {_assetKey: final Map<String, Object?> codeAsset, _targetKey: final String target} => (
              codeAsset,
              target,
            ),
            _ => throw UnimplementedError(),
          },
        ))
          FlutterCodeAsset(
            codeAsset: CodeAsset.fromEncoded(EncodedAsset.fromJson(codeAsset)),
            target: Target.fromString(target),
          ),
      ];
      final dataAssets = <DataAsset>[
        for (final Object? dataAssetJson in dataAssetsList ?? const <Object?>[])
          DataAsset.fromEncoded(EncodedAsset.fromJson(dataAssetJson! as Map<String, Object?>)),
      ];
      return DartHooksResult(
        buildStart: buildStart,
        buildEnd: buildEnd,
        codeAssets: codeAssets,
        dataAssets: dataAssets,
        dependencies: dependencies,
      );
    } else {
      throw ArgumentError('Invalid json $json');
    }
  }

  /// The timestamp at which we start a build - so the timestamp of the inputs.
  final DateTime buildStart;

  /// The timestamp at which we finish a build - so the timestamp of the
  /// outputs.
  final DateTime buildEnd;
  final List<FlutterCodeAsset> codeAssets;
  final List<DataAsset> dataAssets;
  final List<Uri> dependencies;

  Map<String, Object?> toJson() => <String, Object?>{
    _buildStartKey: buildStart.toIso8601String(),
    _buildEndKey: buildEnd.toIso8601String(),
    _dependenciesKey: <Object?>[for (final Uri dep in dependencies) dep.toString()],
    _codeAssetsKey: <Object?>[
      for (final FlutterCodeAsset code in codeAssets)
        <String, Object>{
          _assetKey: code.codeAsset.encode().toJson(),
          _targetKey: code.target.toString(),
        },
    ],
    _dataAssetsKey: <Object?>[for (final DataAsset asset in dataAssets) asset.encode().toJson()],
  };

  static const _buildStartKey = 'build_start';
  static const _buildEndKey = 'build_end';
  static const _dependenciesKey = 'dependencies';
  static const _codeAssetsKey = 'code_assets';
  static const _dataAssetsKey = 'data_assets';
  static const _assetKey = 'asset';
  static const _targetKey = 'target';

  /// The files that eventually should be bundled with the app.
  List<Uri> get filesToBeBundled => <Uri>[
    for (final FlutterCodeAsset code in codeAssets)
      if (code.codeAsset.linkMode is DynamicLoadingBundled) code.codeAsset.file!,
  ];

  FlutterHookResult get asFlutterResult {
    final List<HookAsset> hookAssets = dataAssets
        .map(
          (DataAsset asset) =>
              HookAsset(file: asset.file, name: asset.name, package: asset.package),
        )
        .toList();
    return FlutterHookResult(
      buildStart: buildStart,
      buildEnd: buildEnd,
      dataAssets: hookAssets,
      dependencies: dependencies,
    );
  }
}
