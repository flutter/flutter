// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:native_assets_cli/code_assets_builder.dart';
import 'package:native_assets_cli/data_assets_builder.dart';
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
    final DateTime buildStart = DateTime.parse((json[_buildStartKey] as String?)!);
    final DateTime buildEnd = DateTime.parse((json[_buildEndKey] as String?)!);
    final List<Uri> dependencies = <Uri>[
      for (final Object? encodedUri in json[_dependenciesKey] as List<Object?>? ?? <Object?>[])
        Uri.parse(encodedUri! as String),
    ];
    final List<FlutterCodeAsset> codeAssets = <FlutterCodeAsset>[
      for (final Object? json in json[_codeAssetsKey]! as List<Object?>)
        FlutterCodeAsset(
          codeAsset: CodeAsset.fromEncoded(
            EncodedAsset.fromJson(
              (json! as Map<String, Object?>)[_assetKey]! as Map<String, Object?>,
            ),
          ),
          target: Target.fromString((json as Map<String, Object?>)[_targetKey]! as String),
        ),
    ];
    final List<DataAsset> dataAssets = <DataAsset>[
      for (final Object? json in json[_dataAssetsKey] as List<Object?>? ?? const <Object?>[])
        DataAsset.fromEncoded(EncodedAsset.fromJson(json! as Map<String, Object?>)),
    ];
    return DartHooksResult(
      buildStart: buildStart,
      buildEnd: buildEnd,
      codeAssets: codeAssets,
      dataAssets: dataAssets,
      dependencies: dependencies,
    );
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

  static const String _buildStartKey = 'build_start';
  static const String _buildEndKey = 'build_end';
  static const String _dependenciesKey = 'dependencies';
  static const String _codeAssetsKey = 'code_assets';
  static const String _dataAssetsKey = 'data_assets';
  static const String _assetKey = 'asset';
  static const String _targetKey = 'target';

  /// The files that eventually should be bundled with the app.
  List<Uri> get filesToBeBundled => <Uri>[
    for (final FlutterCodeAsset code in codeAssets)
      if (code.codeAsset.linkMode is DynamicLoadingBundled) code.codeAsset.file!,
  ];

  FlutterHookResult get asFlutterResult {
    final List<HookAsset> hookAssets =
        dataAssets
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
