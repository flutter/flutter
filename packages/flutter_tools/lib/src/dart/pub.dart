// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

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
      await pub(
        args,
        directory: directory,
        filter: _filterOverrideWarnings,
        failureMessage: 'pub $command failed',
        retry: true,
      );
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

/// Runs pub in 'batch' mode, forwarding complete lines written by pub to its
/// stdout/stderr streams to the corresponding stream of this process, optionally
/// applying filtering. The pub process will not receive anything on its stdin stream.
Future<Null> pub(List<String> arguments, {
  String directory,
  MessageFilter filter,
  String failureMessage: 'pub failed',
  @required bool retry,
}) async {
  int attempts = 0;
  int duration = 1;
  int code;
  while (true) {
    attempts += 1;
    code = await runCommandAndStreamOutput(
      _pubCommand(arguments),
      workingDirectory: directory,
      mapFunction: filter,
      environment: _pubEnvironment,
    );
    if (code != 69) // UNAVAILABLE in https://github.com/dart-lang/pub/blob/master/lib/src/exit_codes.dart
      break;
    printStatus('$failureMessage ($code) -- attempting retry $attempts in $duration second${ duration == 1 ? "" : "s"}...');
    await new Future<Null>.delayed(new Duration(seconds: duration));
    if (duration < 64)
      duration *= 2;
  }
  assert(code != null);
  if (code != 0)
    throwToolExit('$failureMessage ($code)', exitCode: code);
}

/// Runs pub in 'interactive' mode, directly piping the stdin stream of this
/// process to that of pub, and the stdout/stderr stream of pub to the corresponding
/// streams of this process.
Future<Null> pubInteractively(List<String> arguments, {
  String directory,
}) async {
  final int code = await runInteractively(
    _pubCommand(arguments),
    workingDirectory: directory,
    environment: _pubEnvironment,
  );
  if (code != 0)
    throwToolExit('pub finished with exit code $code', exitCode: code);
}

/// The command used for running pub.
List<String> _pubCommand(List<String> arguments) {
  return <String>[ sdkBinaryName('pub') ]..addAll(arguments);
}

/// The full environment used when running pub.
Map<String, String> get _pubEnvironment => <String, String>{
  'FLUTTER_ROOT': Cache.flutterRoot,
  _pubEnvironmentKey: _getPubEnvironmentValue(),
};

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
