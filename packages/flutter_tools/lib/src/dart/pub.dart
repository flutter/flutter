// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../globals.dart';
import 'sdk.dart';

bool _shouldRunPubGet({ File pubSpecYaml, File dotPackages }) {
  if (!dotPackages.existsSync())
    return true;
  final DateTime dotPackagesLastModified = dotPackages.lastModifiedSync();
  if (pubSpecYaml.lastModifiedSync().isAfter(dotPackagesLastModified))
    return true;
  final File flutterToolsStamp = Cache.instance.getStampFileFor('flutter_tools');
  if (flutterToolsStamp.existsSync() &&
      flutterToolsStamp.lastModifiedSync().isAfter(dotPackagesLastModified))
    return true;
  return false;
}

Future<Null> pubGet({
  String directory,
  bool skipIfAbsent: false,
  bool upgrade: false,
  bool offline: false,
  bool checkLastModified: true
}) async {
  directory ??= fs.currentDirectory.path;

  final File pubSpecYaml = fs.file(fs.path.join(directory, 'pubspec.yaml'));
  final File dotPackages = fs.file(fs.path.join(directory, '.packages'));

  if (!pubSpecYaml.existsSync()) {
    if (!skipIfAbsent)
      throwToolExit('$directory: no pubspec.yaml found');
    return;
  }

  if (!checkLastModified || _shouldRunPubGet(pubSpecYaml: pubSpecYaml, dotPackages: dotPackages)) {
    final String command = upgrade ? 'upgrade' : 'get';
    final Status status = logger.startProgress(
      'Running "flutter packages $command" in ${fs.path.basename(directory)}...',
      expectSlowOperation: true,
    );
    final List<String> args = <String>['--verbosity=warning', command, '--no-precompile'];
    if (offline)
      args.add('--offline');
    try {
      await pub(args, directory: directory, filter: _filterOverrideWarnings, failureMessage: 'pub $command failed');
    } finally {
      status.stop();
    }
  }

  if (!dotPackages.existsSync())
    throwToolExit('$directory: pub did not create .packages file');

  if (dotPackages.lastModifiedSync().isBefore(pubSpecYaml.lastModifiedSync()))
    throwToolExit('$directory: pub did not update .packages file (pubspec.yaml file has a newer timestamp)');
}

typedef String MessageFilter(String message);

Future<Null> pub(List<String> arguments, {
  String directory,
  MessageFilter filter,
  String failureMessage: 'pub failed'
}) async {
  final List<String> command = <String>[ sdkBinaryName('pub') ]..addAll(arguments);
  final int code = await runCommandAndStreamOutput(
    command,
    workingDirectory: directory,
    mapFunction: filter,
    environment: <String, String>{ 'FLUTTER_ROOT': Cache.flutterRoot, _pubEnvironmentKey: _getPubEnvironmentValue() }
  );
  if (code != 0)
    throwToolExit('$failureMessage ($code)', exitCode: code);
}

final RegExp _analyzerWarning = new RegExp(r'^! \w+ [^ ]+ from path \.\./\.\./bin/cache/dart-sdk/lib/\w+$');

/// The console environment key used by the pub tool.
const String _pubEnvironmentKey = 'PUB_ENVIRONMENT';

/// Returns the environment value that should be used when running pub.
///
/// Includes any existing environment variable, if one exists.
String _getPubEnvironmentValue() {
  final List<String> values = <String>[];

  final String existing = platform.environment[_pubEnvironmentKey];

  if ((existing != null) && existing.isNotEmpty) {
    values.add(existing);
  }

  if (isRunningOnBot) {
    values.add('flutter_bot');
  }

  values.add('flutter_cli');

  return values.join(':');
}

String _filterOverrideWarnings(String message) {
  // This function filters out these three messages:
  //   Warning: You are using these overridden dependencies:
  //   ! analyzer 0.29.0-alpha.0 from path ../../bin/cache/dart-sdk/lib/analyzer
  //   ! front_end 0.1.0-alpha.0 from path ../../bin/cache/dart-sdk/lib/front_end
  if (message == 'Warning: You are using these overridden dependencies:')
    return null;
  if (message.contains(_analyzerWarning))
    return null;
  return message;
}
