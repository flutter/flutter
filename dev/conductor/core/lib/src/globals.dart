// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import 'repository.dart';

const String gsutilBinary = 'gsutil.py';

const String kFrameworkDefaultBranch = 'master';
const String kForceFlag = 'force';

const List<String> kBaseReleaseChannels = <String>['stable', 'beta'];

const List<String> kReleaseChannels = <String>[
  ...kBaseReleaseChannels,
  FrameworkRepository.defaultBranch,
];

const String kReleaseDocumentationUrl =
    'https://github.com/flutter/flutter/blob/main/docs/releases/Flutter-Cherrypick-Process.md';

const String kLuciPackagingConsoleLink =
    'https://ci.chromium.org/p/dart-internal/g/flutter_packaging/console';

const String kWebsiteReleasesUrl = 'https://docs.flutter.dev/development/tools/sdk/releases';

const String discordReleaseChannel =
    'https://discord.com/channels/608014603317936148/783492179922124850';

const String flutterReleaseHotline = 'https://mail.google.com/chat/u/0/#chat/space/AAAA6RKcK2k';

const String hotfixToStableWiki = 'https://github.com/flutter/flutter/blob/main/CHANGELOG.md';

const String flutterAnnounceGroup = 'https://groups.google.com/g/flutter-announce';

const String hotfixDocumentationBestPractices =
    'https://github.com/flutter/flutter/blob/main/docs/releases/Hotfix-Documentation-Best-Practices.md';

final RegExp releaseCandidateBranchRegex = RegExp(r'flutter-(\d+)\.(\d+)-candidate\.(\d+)');

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
}) {
  final String envName = fromArgToEnvName(name);
  if (env[envName] != null) {
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
    'to be provided!',
  );
}

bool getBoolFromEnvOrArgs(String name, ArgResults argResults, Map<String, String> env) {
  final String envName = fromArgToEnvName(name);
  if (env[envName] != null) {
    return env[envName]?.toUpperCase() == 'TRUE';
  }
  return argResults[name] as bool;
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
List<String> getValuesFromEnvOrArgs(String name, ArgResults argResults, Map<String, String> env) {
  final String envName = fromArgToEnvName(name);
  if (env[envName] != null && env[envName] != '') {
    return env[envName]!.split(',');
  }
  final List<String>? argValues = argResults[name] as List<String>?;
  if (argValues != null) {
    return argValues;
  }

  throw ConductorException(
    'Expected either the CLI arg --$name or the environment variable $envName '
    'to be provided!',
  );
}

/// Translate CLI arg names to env variable names.
///
/// For example, 'state-file' -> 'STATE_FILE'.
String fromArgToEnvName(String argName) {
  return argName.toUpperCase().replaceAll(r'-', r'_');
}
