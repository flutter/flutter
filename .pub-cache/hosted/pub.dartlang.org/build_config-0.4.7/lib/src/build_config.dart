// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';

import 'build_target.dart';
import 'builder_definition.dart';
import 'common.dart';
import 'expandos.dart';
import 'input_set.dart';
import 'key_normalization.dart';

part 'build_config.g.dart';

/// The parsed values from a `build.yaml` file.
@JsonSerializable(createToJson: false, disallowUnrecognizedKeys: true)
class BuildConfig {
  /// Returns a parsed [BuildConfig] file in [path], if one exist, otherwise a
  /// default config.
  ///
  /// [path] must be a directory which contains a `pubspec.yaml` file and
  /// optionally a `build.yaml`.
  static Future<BuildConfig> fromPackageDir(String path) async {
    final pubspec = await _fromPackageDir(path);
    return fromBuildConfigDir(pubspec.name, pubspec.dependencies.keys, path);
  }

  /// Returns a parsed [BuildConfig] file in [path], if one exists, otherwise a
  /// default config.
  ///
  /// [path] should the path to a directory which may contain a `build.yaml`.
  static Future<BuildConfig> fromBuildConfigDir(
      String packageName, Iterable<String> dependencies, String path) async {
    final configPath = p.join(path, 'build.yaml');
    final file = File(configPath);
    if (await file.exists()) {
      return BuildConfig.parse(
        packageName,
        dependencies,
        await file.readAsString(),
        configYamlPath: file.path,
      );
    } else {
      return BuildConfig.useDefault(packageName, dependencies);
    }
  }

  @JsonKey(ignore: true)
  final String packageName;

  /// All the `builders` defined in a `build.yaml` file.
  @JsonKey(name: 'builders')
  final Map<String, BuilderDefinition> builderDefinitions;

  /// All the `post_process_builders` defined in a `build.yaml` file.
  @JsonKey(name: 'post_process_builders')
  final Map<String, PostProcessBuilderDefinition> postProcessBuilderDefinitions;

  /// All the `targets` defined in a `build.yaml` file.
  @JsonKey(name: 'targets', fromJson: _buildTargetsFromJson)
  final Map<String, BuildTarget> buildTargets;

  @JsonKey(name: 'global_options')
  final Map<String, GlobalBuilderConfig> globalOptions;

  @JsonKey(name: 'additional_public_assets')
  final List<String> additionalPublicAssets;

  /// The default config if you have no `build.yaml` file.
  factory BuildConfig.useDefault(
      String packageName, Iterable<String> dependencies) {
    return runInBuildConfigZone(() {
      final key = '$packageName:$packageName';
      final target = BuildTarget(
        dependencies: dependencies
            .map((dep) => normalizeTargetKeyUsage(dep, packageName))
            .toList(),
        sources: InputSet.anything,
      );
      return BuildConfig(
        packageName: packageName,
        buildTargets: {key: target},
        globalOptions: {},
      );
    }, packageName, dependencies.toList());
  }

  /// Create a [BuildConfig] by parsing [configYaml].
  ///
  /// If [configYamlPath] is passed, it's used as the URL from which
  /// [configYaml] for error reporting.
  factory BuildConfig.parse(
    String packageName,
    Iterable<String> dependencies,
    String configYaml, {
    String configYamlPath,
  }) {
    try {
      return checkedYamlDecode(
        configYaml,
        (map) =>
            BuildConfig.fromMap(packageName, dependencies, map ?? const {}),
        allowNull: true,
        sourceUrl: configYamlPath == null ? null : Uri.file(configYamlPath),
      );
    } on ParsedYamlException catch (e) {
      throw ArgumentError(e.formattedMessage);
    }
  }

  /// Create a [BuildConfig] read a map which was already parsed.
  factory BuildConfig.fromMap(
      String packageName, Iterable<String> dependencies, Map config) {
    return runInBuildConfigZone(() => BuildConfig._fromJson(config),
        packageName, dependencies.toList());
  }

  BuildConfig({
    String packageName,
    @required Map<String, BuildTarget> buildTargets,
    Map<String, GlobalBuilderConfig> globalOptions,
    Map<String, BuilderDefinition> builderDefinitions,
    Map<String, PostProcessBuilderDefinition> postProcessBuilderDefinitions =
        const {},
    this.additionalPublicAssets = const [],
  })  : buildTargets = buildTargets ??
            {
              _defaultTarget(packageName ?? currentPackage): BuildTarget(
                dependencies: currentPackageDefaultDependencies,
              )
            },
        globalOptions = (globalOptions ?? const {}).map((key, config) =>
            MapEntry(normalizeBuilderKeyUsage(key, currentPackage), config)),
        builderDefinitions = _normalizeBuilderDefinitions(
            builderDefinitions ?? const {}, packageName ?? currentPackage),
        postProcessBuilderDefinitions = _normalizeBuilderDefinitions(
            postProcessBuilderDefinitions ?? const {},
            packageName ?? currentPackage),
        packageName = packageName ?? currentPackage {
    // Set up the expandos for all our build targets and definitions so they
    // can know which package and builder key they refer to.
    this.buildTargets.forEach((key, target) {
      packageExpando[target] = this.packageName;
      builderKeyExpando[target] = key;
    });
    this.builderDefinitions.forEach((key, definition) {
      packageExpando[definition] = this.packageName;
      builderKeyExpando[definition] = key;
    });
    this.postProcessBuilderDefinitions.forEach((key, definition) {
      packageExpando[definition] = this.packageName;
      builderKeyExpando[definition] = key;
    });
  }

  factory BuildConfig._fromJson(Map json) => _$BuildConfigFromJson(json);
}

String _defaultTarget(String package) => '$package:$package';

Map<String, T> _normalizeBuilderDefinitions<T>(
        Map<String, T> builderDefinitions, String packageName) =>
    builderDefinitions.map((key, definition) =>
        MapEntry(normalizeBuilderKeyDefinition(key, packageName), definition));

Map<String, BuildTarget> _buildTargetsFromJson(Map json) {
  if (json == null) {
    return null;
  }
  var targets = json.map((key, target) => MapEntry(
      normalizeTargetKeyDefinition(key as String, currentPackage),
      BuildTarget.fromJson(target as Map)));

  if (!targets.containsKey(_defaultTarget(currentPackage))) {
    throw ArgumentError('Must specify a target with the name '
        '`$currentPackage` or `\$default`.');
  }

  return targets;
}

Future<Pubspec> _fromPackageDir(String path) async {
  final pubspec = p.join(path, 'pubspec.yaml');
  final file = File(pubspec);
  if (await file.exists()) {
    return Pubspec.parse(await file.readAsString());
  }
  throw FileSystemException('No file found', p.absolute(pubspec));
}
