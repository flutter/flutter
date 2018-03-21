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
import '../runner/flutter_command.dart';
import 'sdk.dart';

/// Represents Flutter-specific data that is added to the `PUB_ENVIRONMENT`
/// environment variable and allows understanding the type of requests made to
/// the package site on Flutter's behalf.
// DO NOT update without contacting kevmoo.
// We have server-side tooling that assumes the values are consistent.
class PubContext {
  static final RegExp _validContext = new RegExp('[a-z][a-z_]*[a-z]');

  static final PubContext create = new PubContext._(<String>['create']);
  static final PubContext createPackage = new PubContext._(<String>['create_pkg']);
  static final PubContext createPlugin = new PubContext._(<String>['create_plugin']);
  static final PubContext interactive = new PubContext._(<String>['interactive']);
  static final PubContext pubGet = new PubContext._(<String>['get']);
  static final PubContext pubUpgrade = new PubContext._(<String>['upgrade']);
  static final PubContext runTest = new PubContext._(<String>['run_test']);

  static final PubContext flutterTests = new PubContext._(<String>['flutter_tests']);
  static final PubContext updatePackages = new PubContext._(<String>['update_packages']);

  final List<String> _values;

  PubContext._(this._values) {
    for (String item in _values) {
      if (!_validContext.hasMatch(item)) {
        throw new ArgumentError.value(
            _values, 'value', 'Must match RegExp ${_validContext.pattern}');
      }
    }
  }

  static PubContext getVerifyContext(String commandName) =>
      new PubContext._(<String>['verify', commandName.replaceAll('-', '_')]);

  @override
  String toString() => 'PubContext: ${_values.join(':')}';
}

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

/// [context] provides extra information to package server requests to
/// understand usage.
Future<Null> pubGet({
  @required PubContext context,
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
    final List<String> args = <String>['--verbosity=warning'];
    if (FlutterCommand.current != null && FlutterCommand.current.globalResults['verbose'])
      args.add('--verbose');
    args.addAll(<String>[command, '--no-precompile']);
    if (offline)
      args.add('--offline');
    try {
      await pub(
        args,
        context: context,
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
///
/// The `--trace` argument is passed to `pub` (by mutating the provided
/// `arguments` list) when `showTraceForErrors` is true, and when `showTraceForErrors`
/// is null/unset, and `isRunningOnBot` is true.
///
/// [context] provides extra information to package server requests to
/// understand usage.
Future<Null> pub(List<String> arguments, {
  @required PubContext context,
  String directory,
  MessageFilter filter,
  String failureMessage: 'pub failed',
  @required bool retry,
  bool showTraceForErrors,
}) async {
  showTraceForErrors ??= isRunningOnBot;

  if (showTraceForErrors)
    arguments.insert(0, '--trace');
  int attempts = 0;
  int duration = 1;
  int code;
  while (true) {
    attempts += 1;
    code = await runCommandAndStreamOutput(
      _pubCommand(arguments),
      workingDirectory: directory,
      mapFunction: filter,
      environment: _createPubEnvironment(context),
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
    environment: _createPubEnvironment(PubContext.interactive),
  );
  if (code != 0)
    throwToolExit('pub finished with exit code $code', exitCode: code);
}

/// The command used for running pub.
List<String> _pubCommand(List<String> arguments) {
  return <String>[ sdkBinaryName('pub') ]..addAll(arguments);
}

/// The full environment used when running pub.
///
/// [context] provides extra information to package server requests to
/// understand usage.
Map<String, String> _createPubEnvironment(PubContext context) {
  final Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': Cache.flutterRoot,
    _pubEnvironmentKey: _getPubEnvironmentValue(context),
  };
  final String pubCache = _getRootPubCacheIfAvailable();
  if (pubCache != null) {
    environment[_pubCacheEnvironmentKey] = pubCache;
  }
  return environment;
}

final RegExp _analyzerWarning = new RegExp(r'^! \w+ [^ ]+ from path \.\./\.\./bin/cache/dart-sdk/lib/\w+$');

/// The console environment key used by the pub tool.
const String _pubEnvironmentKey = 'PUB_ENVIRONMENT';

/// The console environment key used by the pub tool to find the cache directory.
const String _pubCacheEnvironmentKey = 'PUB_CACHE';

/// Returns the environment value that should be used when running pub.
///
/// Includes any existing environment variable, if one exists.
///
/// [context] provides extra information to package server requests to
/// understand usage.
String _getPubEnvironmentValue(PubContext pubContext) {
  // DO NOT update this function without contacting kevmoo.
  // We have server-side tooling that assumes the values are consistent.
  final List<String> values = <String>[];

  final String existing = platform.environment[_pubEnvironmentKey];

  if ((existing != null) && existing.isNotEmpty) {
    values.add(existing);
  }

  if (isRunningOnBot) {
    values.add('flutter_bot');
  }

  values.add('flutter_cli');
  values.addAll(pubContext._values);

  return values.join(':');
}

String _getRootPubCacheIfAvailable() {
  if (platform.environment.containsKey(_pubCacheEnvironmentKey)) {
    return platform.environment[_pubCacheEnvironmentKey];
  }

  final String cachePath = fs.path.join(Cache.flutterRoot, '.pub-cache');
  if (fs.directory(cachePath).existsSync()) {
    printTrace('Using $cachePath for the pub cache.');
    return cachePath;
  }

  // Use pub's default location by returning null.
  return null;
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
