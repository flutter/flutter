// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import 'utils.dart';

/// Loads manifest data from `manifest.yaml` file or from [yaml], if present.
Manifest loadTaskManifest([ String yaml ]) {
  final dynamic manifestYaml = yaml == null
    ? loadYaml(file('manifest.yaml').readAsStringSync())
    : loadYamlNode(yaml);

  _checkType(manifestYaml is Map, manifestYaml, 'Manifest', 'dictionary');
  return _validateAndParseManifest(manifestYaml);
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
    @required this.name,
    @required this.description,
    @required this.stage,
    @required this.requiredAgentCapabilities,
    @required this.isFlaky,
    @required this.timeoutInMinutes,
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
  final List<dynamic> requiredAgentCapabilities;

  /// Whether this test is flaky.
  ///
  /// Flaky tests are not considered when deciding if the build is broken.
  final bool isFlaky;

  /// An optional custom timeout specified in minutes.
  final int timeoutInMinutes;
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
Manifest _validateAndParseManifest(Map<dynamic, dynamic> manifestYaml) {
  _checkKeys(manifestYaml, 'manifest', const <String>['tasks']);
  return new Manifest._(_validateAndParseTasks(manifestYaml['tasks']));
}

List<ManifestTask> _validateAndParseTasks(dynamic tasksYaml) {
  _checkType(tasksYaml is Map, tasksYaml, 'Value of "tasks"', 'dictionary');
  final List<dynamic> sortedKeys = tasksYaml.keys.toList()..sort();
  return sortedKeys.map((dynamic taskName) => _validateAndParseTask(taskName, tasksYaml[taskName])).toList();
}

ManifestTask _validateAndParseTask(dynamic taskName, dynamic taskYaml) {
  _checkType(taskName is String, taskName, 'Task name', 'string');
  _checkType(taskYaml is Map, taskYaml, 'Value of task "$taskName"', 'dictionary');
  _checkKeys(taskYaml, 'Value of task "$taskName"', const <String>[
    'description',
    'stage',
    'required_agent_capabilities',
    'flaky',
    'timeout_in_minutes',
  ]);

  final dynamic isFlaky = taskYaml['flaky'];
  if (isFlaky != null) {
    _checkType(isFlaky is bool, isFlaky, 'flaky', 'boolean');
  }

  final dynamic timeoutInMinutes = taskYaml['timeout_in_minutes'];
  if (timeoutInMinutes != null) {
    _checkType(timeoutInMinutes is int, timeoutInMinutes, 'timeout_in_minutes', 'integer');
  }

  final List<dynamic> capabilities = _validateAndParseCapabilities(taskName, taskYaml['required_agent_capabilities']);
  return new ManifestTask._(
    name: taskName,
    description: taskYaml['description'],
    stage: taskYaml['stage'],
    requiredAgentCapabilities: capabilities,
    isFlaky: isFlaky ?? false,
    timeoutInMinutes: timeoutInMinutes,
  );
}

List<String> _validateAndParseCapabilities(String taskName, dynamic capabilitiesYaml) {
  _checkType(capabilitiesYaml is List, capabilitiesYaml, 'required_agent_capabilities', 'list');
  for (int i = 0; i < capabilitiesYaml.length; i++) {
    final dynamic capability = capabilitiesYaml[i];
    _checkType(capability is String, capability, 'required_agent_capabilities[$i]', 'string');
  }
  return capabilitiesYaml.cast<String>();
}

void _checkType(bool isValid, dynamic value, String variableName, String typeName) {
  if (!isValid) {
    throw new ManifestError(
      '$variableName must be a $typeName but was ${value.runtimeType}: $value',
    );
  }
}

void _checkIsNotBlank(dynamic value, String variableName, String ownerName) {
  if (value == null || value.isEmpty) {
    throw new ManifestError('$variableName must not be empty in $ownerName.');
  }
}

void _checkKeys(Map<dynamic, dynamic> map, String variableName, List<String> allowedKeys) {
  for (String key in map.keys) {
    if (!allowedKeys.contains(key)) {
      throw new ManifestError(
        'Unrecognized property "$key" in $variableName. '
        'Allowed properties: ${allowedKeys.join(', ')}');
    }
  }
}
