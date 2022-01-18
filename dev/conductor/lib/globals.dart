// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';

const String kUpstreamRemote = 'https://github.com/flutter/flutter.git';

const String gsutilBinary = 'gsutil.py';

const List<String> kReleaseChannels = <String>[
  'stable',
  'beta',
  'dev',
  'master',
];

const String kReleaseDocumentationUrl = 'https://github.com/flutter/flutter/wiki/Flutter-Cherrypick-Process';

final RegExp releaseCandidateBranchRegex = RegExp(
  r'flutter-(\d+)\.(\d+)-candidate\.(\d+)',
);

/// Cast a dynamic to String and trim.
String stdoutToString(dynamic input) {
  final String str = input as String;
  return str.trim();
}

class ConductorException implements Exception {
  ConductorException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

Directory? _flutterRoot;
Directory get localFlutterRoot {
  if (_flutterRoot != null) {
    return _flutterRoot!;
  }
  String filePath;
  const FileSystem fileSystem = LocalFileSystem();
  const Platform platform = LocalPlatform();

  // If a test
  if (platform.script.scheme == 'data') {
    final RegExp pattern = RegExp(
      r'(file:\/\/[^"]*[/\\]dev\/conductor[/\\][^"]+\.dart)',
      multiLine: true,
    );
    final Match? match =
        pattern.firstMatch(Uri.decodeFull(platform.script.path));
    if (match == null) {
      throw Exception(
        'Cannot determine path of script!\n${platform.script.path}',
      );
    }
    filePath = Uri.parse(match.group(1)!).path.replaceAll(r'%20', ' ');
  } else {
    filePath = platform.script.toFilePath();
  }
  final String checkoutsDirname = fileSystem.path.normalize(
    fileSystem.path.join(
      fileSystem.path.dirname(filePath),
      '..', // flutter/dev/tools
      '..', // flutter/dev
      '..', // flutter
    ),
  );
  _flutterRoot = fileSystem.directory(checkoutsDirname);
  return _flutterRoot!;
}

bool assertsEnabled() {
  // Verify asserts enabled
  bool assertsEnabled = false;

  assert(() {
    assertsEnabled = true;
    return true;
  }());
  return assertsEnabled;
}

/// Either return the value from [env] or fall back to [argResults].
///
/// If the key does not exist in either the environment or CLI args, throws a
/// [ConductorException].
///
/// The environment is favored over CLI args since the latter can have a default
/// value, which the environment should be able to override.
String? getValueFromEnvOrArgs(
  String name,
  ArgResults argResults,
  Map<String, String> env, {
    bool allowNull = false,
  }
) {
  final String envName = fromArgToEnvName(name);
  if (env[envName] != null ) {
    return env[envName];
  }
  final String? argValue = argResults[name] as String?;
  if (argValue != null) {
    return argValue;
  }

  if (allowNull) {
    return null;
  }
  throw ConductorException(
    'Expected either the CLI arg --$name or the environment variable $envName '
    'to be provided!');
}

/// Return multiple values from the environment or fall back to [argResults].
///
/// Values read from an environment variable are assumed to be comma-delimited.
///
/// If the key does not exist in either the CLI args or environment, throws a
/// [ConductorException].
///
/// The environment is favored over CLI args since the latter can have a default
/// value, which the environment should be able to override.
List<String> getValuesFromEnvOrArgs(
  String name,
  ArgResults argResults,
  Map<String, String> env,
) {
  final String envName = fromArgToEnvName(name);
  if (env[envName] != null && env[envName] != '') {
    return env[envName]!.split(',');
  }
  final List<String> argValues = argResults[name] as List<String>;
  if (argValues != null) {
    return argValues;
  }

  throw ConductorException(
    'Expected either the CLI arg --$name or the environment variable $envName '
    'to be provided!');
}

/// Translate CLI arg names to env variable names.
///
/// For example, 'state-file' -> 'STATE_FILE'.
String fromArgToEnvName(String argName) {
  return argName.toUpperCase().replaceAll(r'-', r'_');
}
