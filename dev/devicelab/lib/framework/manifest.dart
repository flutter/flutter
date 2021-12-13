// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'utils.dart';

/// Loads manifest data from `manifest.yaml` file or from [yaml], if present.
Manifest loadTaskManifest([ String? yaml ]) {
  final dynamic manifestYaml = yaml == null
    ? loadYaml(file('manifest.yaml').readAsStringSync())
    : loadYamlNode(yaml);

  _checkType(manifestYaml is YamlMap, manifestYaml, 'Manifest', 'dictionary');
  return _validateAndParseManifest(manifestYaml as YamlMap);
}

/// Contains CI task information.
class Manifest {
  Manifest._(this.tasks);

  /// CI tasks.
  final List<ManifestTask> tasks;
}

/// A CI task.
class ManifestTask {
  ManifestTask._({
    required this.name,
    required this.description,
    required this.stage,
    required this.requiredAgentCapabilities,
    required this.isFlaky,
    required this.timeoutInMinutes,
    required this.onLuci,
  }) {
    final String taskName = 'task "$name"';
    _checkIsNotBlank(name, 'Task name', taskName);
    _checkIsNotBlank(description, 'Task description', taskName);
    _checkIsNotBlank(stage, 'Task stage', taskName);
    _checkIsNotBlank(requiredAgentCapabilities, 'requiredAgentCapabilities', taskName);
  }

  /// Task name as it appears on the dashboard.
  final String name;

  /// A human-readable description of the task.
  final String description;

  /// The stage this task should run in.
  final String stage;

  /// Capabilities required of the build agent to be able to perform this task.
  final List<String> requiredAgentCapabilities;

  /// Whether this test is flaky.
  ///
  /// Flaky tests are not considered when deciding if the build is broken.
  final bool isFlaky;

  /// An optional custom timeout specified in minutes.
  final int timeoutInMinutes;

  /// (Optional) Whether this test runs on LUCI.
  final bool onLuci;

  /// Whether the task is supported by the current host platform
  bool isSupportedByHost() {
    final Set<String> supportedHosts = Set<String>.from(
      requiredAgentCapabilities.map<String>(
        (String str) => str.split('/')[0]
      )
    );
    String hostPlatform = Platform.operatingSystem;
    if (hostPlatform == 'macos') {
      hostPlatform = 'mac'; // package:platform uses 'macos' while manifest.yaml uses 'mac'
    }
    return supportedHosts.contains(hostPlatform);
  }
}

/// Thrown when the manifest YAML is not valid.
class ManifestError extends Error {
  ManifestError(this.message);

  final String message;

  @override
  String toString() => '$ManifestError: $message';
}

// There's no good YAML validator, at least not for Dart, so we validate
// manually. It's not too much code and produces good error messages.
Manifest _validateAndParseManifest(YamlMap manifestYaml) {
  _checkKeys(manifestYaml, 'manifest', const <String>['tasks']);
  return Manifest._(_validateAndParseTasks(manifestYaml['tasks']));
}

List<ManifestTask> _validateAndParseTasks(dynamic tasksYaml) {
  _checkType(tasksYaml is YamlMap, tasksYaml, 'Value of "tasks"', 'dictionary');
  final List<String> sortedKeys = (tasksYaml as YamlMap).keys.toList().cast<String>()..sort();
  // ignore: avoid_dynamic_calls
  return sortedKeys.map<ManifestTask>((String taskName) => _validateAndParseTask(taskName, tasksYaml[taskName])).toList();
}

ManifestTask _validateAndParseTask(String taskName, dynamic taskYaml) {
  _checkType(taskYaml is YamlMap, taskYaml, 'Value of task "$taskName"', 'dictionary');
  _checkKeys(taskYaml as YamlMap, 'Value of task "$taskName"', const <String>[
    'description',
    'stage',
    'required_agent_capabilities',
    'flaky',
    'timeout_in_minutes',
    'on_luci',
  ]);
  // ignore: avoid_dynamic_calls
  final dynamic isFlaky = taskYaml['flaky'];
  if (isFlaky != null) {
    _checkType(isFlaky is bool, isFlaky, 'flaky', 'boolean');
  }

  // ignore: avoid_dynamic_calls
  final dynamic timeoutInMinutes = taskYaml['timeout_in_minutes'];
  if (timeoutInMinutes != null) {
    _checkType(timeoutInMinutes is int, timeoutInMinutes, 'timeout_in_minutes', 'integer');
  }

  // ignore: avoid_dynamic_calls
  final List<dynamic> capabilities = _validateAndParseCapabilities(taskName, taskYaml['required_agent_capabilities']);

  // ignore: avoid_dynamic_calls
  final dynamic onLuci = taskYaml['on_luci'];
  if (onLuci != null) {
    _checkType(onLuci is bool, onLuci, 'on_luci', 'boolean');
  }

  return ManifestTask._(
    name: taskName,
    // ignore: avoid_dynamic_calls
    description: taskYaml['description'] as String,
    // ignore: avoid_dynamic_calls
    stage: taskYaml['stage'] as String,
    requiredAgentCapabilities: capabilities as List<String>,
    isFlaky: isFlaky as bool,
    timeoutInMinutes: timeoutInMinutes as int,
    onLuci: onLuci as bool,
  );
}

List<String> _validateAndParseCapabilities(String taskName, dynamic capabilitiesYaml) {
  _checkType(capabilitiesYaml is List, capabilitiesYaml, 'required_agent_capabilities', 'list');
  final List<dynamic> capabilities = capabilitiesYaml as List<dynamic>;
  for (int i = 0; i < capabilities.length; i++) {
    final dynamic capability = capabilities[i];
    _checkType(capability is String, capability, 'required_agent_capabilities[$i]', 'string');
  }
  return capabilitiesYaml.cast<String>();
}

void _checkType(bool isValid, dynamic value, String variableName, String typeName) {
  if (!isValid) {
    throw ManifestError(
      '$variableName must be a $typeName but was ${value.runtimeType}: $value',
    );
  }
}

void _checkIsNotBlank(dynamic value, String variableName, String ownerName) {
  if (value == null || value is String && value.isEmpty || value is List<dynamic> && value.isEmpty) {
    throw ManifestError('$variableName must not be empty in $ownerName.');
  }
}

void _checkKeys(Map<dynamic, dynamic> map, String variableName, List<String> allowedKeys) {
  for (final String key in map.keys.cast<String>()) {
    if (!allowedKeys.contains(key)) {
      throw ManifestError(
        'Unrecognized property "$key" in $variableName. '
        'Allowed properties: ${allowedKeys.join(', ')}');
    }
  }
}
