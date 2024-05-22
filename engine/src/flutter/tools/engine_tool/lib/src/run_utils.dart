// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:process_runner/process_runner.dart';

import 'environment.dart';
import 'label.dart';
import 'typed_json.dart';

const String _targetPlatformKey = 'targetPlatform';
const String _nameKey = 'name';
const String _idKey = 'id';

/// Target to run a flutter application on.
class RunTarget {
  /// Construct a RunTarget from a JSON map.
  factory RunTarget.fromJson(Map<String, Object> map) {
    return JsonObject(map).map(
        (JsonObject json) => RunTarget._(
              json.string(_nameKey),
              json.string(_idKey),
              json.string(_targetPlatformKey),
            ), onError: (JsonObject source, JsonMapException e) {
      throw FormatException(
          'Failed to parse RunTarget: $e', source.toPrettyString());
    });
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

  /// Returns the minimum set of build targets needed to build the shell for
  /// this target platform.
  List<Label> buildTargetsForShell() {
    final List<Label> labels = <Label>[];
    switch (targetPlatform) {
      case 'android-arm64':
      case 'android-arm32':
        {
          labels.add(
              Label.parseGn('//flutter/shell/platform/android:android_jar'));
          break;
        }
      // TODO(cbracken): iOS and MacOS share the same target platform but
      // have different build targets. For now hard code iOS.
      case 'darwin':
        {
          labels.add(Label.parseGn(
              '//flutter/shell/platform/darwin/ios:flutter_framework'));
          break;
        }
      default:
        throw UnimplementedError('No mapping for $targetPlatform');
      // For the future:
      // //flutter/shell/platform/darwin/macos:flutter_framework
      // //flutter/shell/platform/linux:flutter_linux_gtk
      // //flutter/shell/platform/windows
      // //flutter/web_sdk:flutter_web_sdk_archive
    }
    return labels;
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
