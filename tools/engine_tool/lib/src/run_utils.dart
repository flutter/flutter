// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:process_runner/process_runner.dart';

import 'environment.dart';
import 'json_utils.dart';

const String _targetPlatformKey = 'targetPlatform';
const String _nameKey = 'name';
const String _idKey = 'id';

/// Target to run a flutter application on.
class RunTarget {
  /// Construct a RunTarget from a JSON map.
  factory RunTarget.fromJson(Map<String, Object> map) {
    final List<String> errors = <String>[];
    final String name = stringOfJson(map, _nameKey, errors)!;
    final String id = stringOfJson(map, _idKey, errors)!;
    final String targetPlatform =
        stringOfJson(map, _targetPlatformKey, errors)!;

    if (errors.isNotEmpty) {
      throw FormatException('Failed to parse RunTarget: ${errors.join('\n')}');
    }
    return RunTarget._(name, id, targetPlatform);
  }

  RunTarget._(this.name, this.id, this.targetPlatform);

  /// Name of target device.
  final String name;

  /// Id of target device.
  final String id;

  /// Target platform of device.
  final String targetPlatform;

  /// BuildConfig name for compilation mode.
  String buildConfigFor(String mode) {
    switch (targetPlatform) {
      case 'android-arm64':
        return 'android_${mode}_arm64';
      case 'darwin':
        return 'host_$mode';
      case 'web-javascript':
        return 'chrome_$mode';
      default:
        throw UnimplementedError('No mapping for $targetPlatform');
    }
  }
}

/// Parse the raw output of `flutter devices --machine`.
List<RunTarget> parseDevices(Environment env, String flutterDevicesMachine) {
  late final List<dynamic> decoded;
  try {
    decoded = jsonDecode(flutterDevicesMachine) as List<dynamic>;
  } on FormatException catch (e) {
    env.logger.error(
        'Failed to parse flutter devices output: $e\n\n$flutterDevicesMachine\n\n');
    return <RunTarget>[];
  }

  final List<RunTarget> r = <RunTarget>[];
  for (final dynamic device in decoded) {
    if (device is! Map<String, Object?>) {
      return <RunTarget>[];
    }
    if (!device.containsKey(_nameKey) || !device.containsKey(_idKey)) {
      env.logger.error('device is missing required fields:\n$device\n');
      return <RunTarget>[];
    }
    if (!device.containsKey(_targetPlatformKey)) {
      env.logger.warning('Skipping ${device[_nameKey]}: '
          'Could not find $_targetPlatformKey in device description.');
      continue;
    }
    late final RunTarget target;
    try {
      target = RunTarget.fromJson(device.cast<String, Object>());
    } on FormatException catch (e) {
      env.logger.error(e);
      return <RunTarget>[];
    }
    r.add(target);
  }

  return r;
}

/// Return the default device to be used.
RunTarget? defaultDevice(Environment env, List<RunTarget> targets) {
  if (targets.isEmpty) {
    return null;
  }
  return targets.first;
}

/// Select a run target.
RunTarget? selectRunTarget(Environment env, String flutterDevicesMachine,
    [String? idPrefix]) {
  final List<RunTarget> targets = parseDevices(env, flutterDevicesMachine);
  if (idPrefix != null && idPrefix.isNotEmpty) {
    for (final RunTarget target in targets) {
      if (target.id.startsWith(idPrefix)) {
        return target;
      }
    }
  }
  return defaultDevice(env, targets);
}

/// Detects available targets and then selects one.
Future<RunTarget?> detectAndSelectRunTarget(Environment env,
    [String? idPrefix]) async {
  final ProcessRunnerResult result = await env.processRunner
      .runProcess(<String>['flutter', 'devices', '--machine']);
  if (result.exitCode != 0) {
    env.logger.error('flutter devices --machine failed:\n'
        'EXIT_CODE:${result.exitCode}\n'
        'STDOUT:\n${result.stdout}'
        'STDERR:\n${result.stderr}');
    return null;
  }
  return selectRunTarget(env, result.stdout, idPrefix);
}
