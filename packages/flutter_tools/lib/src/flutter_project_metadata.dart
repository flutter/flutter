// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/utils.dart';

enum FlutterProjectType {
  /// This is the default project with the user-managed host code.
  /// It is different than the "module" template in that it exposes and doesn't
  /// manage the platform code.
  app,
  /// The is a project that has managed platform host code. It is an application with
  /// ephemeral .ios and .android directories that can be updated automatically.
  module,
  /// This is a Flutter Dart package project. It doesn't have any native
  /// components, only Dart.
  package,
  /// This is a native plugin project.
  plugin,
}

String flutterProjectTypeToString(FlutterProjectType type) {
  return getEnumName(type);
}

FlutterProjectType? stringToProjectType(String value) {
  FlutterProjectType? result;
  for (final FlutterProjectType type in FlutterProjectType.values) {
    if (value == flutterProjectTypeToString(type)) {
      result = type;
      break;
    }
  }
  return result;
}

/// A wrapper around the `.metadata` file.
class FlutterProjectMetadata {
  FlutterProjectMetadata(
    File metadataFile,
    Logger logger,
    )  : _metadataFile = metadataFile,
      _logger = logger;

  final File _metadataFile;
  final Logger _logger;

  String? get versionChannel => _versionValue('channel');
  String? get versionRevision => _versionValue('revision');

  FlutterProjectType? get projectType {
    final dynamic projectTypeYaml = _metadataValue('project_type');
    if (projectTypeYaml is String) {
      return stringToProjectType(projectTypeYaml);
    } else {
      _logger.printTrace('.metadata project_type version is malformed.');
      return null;
    }
  }

  YamlMap? _versionYaml;
  String? _versionValue(String key) {
    if (_versionYaml == null) {
      final dynamic versionYaml = _metadataValue('version');
      if (versionYaml is YamlMap) {
        _versionYaml = versionYaml;
      } else {
        _logger.printTrace('.metadata version is malformed.');
        return null;
      }
    }
    if (_versionYaml != null && _versionYaml!.containsKey(key) && _versionYaml![key] is String) {
      return _versionYaml![key] as String;
    }
    return null;
  }

  YamlMap? _metadataYaml;
  dynamic _metadataValue(String key) {
    if (_metadataYaml == null) {
      if (!_metadataFile.existsSync()) {
        return null;
      }
      dynamic metadataYaml;
      try {
        metadataYaml = loadYaml(_metadataFile.readAsStringSync());
      } on YamlException {
        // Handled in return below.
      }
      if (metadataYaml is YamlMap) {
        _metadataYaml = metadataYaml;
      } else {
        _logger.printTrace('.metadata is malformed.');
        return null;
      }
    }

    return _metadataYaml![key];
  }
}
