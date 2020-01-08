// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart' as io;
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import 'sdk.dart';

/// The [Pub] instance.
Pub get pub => context.get<Pub>();

/// Represents Flutter-specific data that is added to the `PUB_ENVIRONMENT`
/// environment variable and allows understanding the type of requests made to
/// the package site on Flutter's behalf.
// DO NOT update without contacting kevmoo.
// We have server-side tooling that assumes the values are consistent.
class PubContext {
  PubContext._(this._values) {
    for (final String item in _values) {
      if (!_validContext.hasMatch(item)) {
        throw ArgumentError.value(
            _values, 'value', 'Must match RegExp ${_validContext.pattern}');
      }
    }
  }

  static PubContext getVerifyContext(String commandName) =>
      PubContext._(<String>['verify', commandName.replaceAll('-', '_')]);

  static final PubContext create = PubContext._(<String>['create']);
  static final PubContext createPackage = PubContext._(<String>['create_pkg']);
  static final PubContext createPlugin = PubContext._(<String>['create_plugin']);
  static final PubContext interactive = PubContext._(<String>['interactive']);
  static final PubContext pubGet = PubContext._(<String>['get']);
  static final PubContext pubUpgrade = PubContext._(<String>['upgrade']);
  static final PubContext pubForward = PubContext._(<String>['forward']);
  static final PubContext runTest = PubContext._(<String>['run_test']);

  static final PubContext flutterTests = PubContext._(<String>['flutter_tests']);
  static final PubContext updatePackages = PubContext._(<String>['update_packages']);

  final List<String> _values;

  static final RegExp _validContext = RegExp('[a-z][a-z_]*[a-z]');

  @override
  String toString() => 'PubContext: ${_values.join(':')}';

  String toAnalyticsString()  {
    return _values.map((String s) => s.replaceAll('_', '-')).toList().join('-');
  }
}

bool _shouldRunPubGet({ File pubSpecYaml, File dotPackages }) {
  if (!dotPackages.existsSync()) {
    return true;
  }
  final DateTime dotPackagesLastModified = dotPackages.lastModifiedSync();
  if (pubSpecYaml.lastModifiedSync().isAfter(dotPackagesLastModified)) {
    return true;
  }
  final File flutterToolsStamp = globals.cache.getStampFileFor('flutter_tools');
  if (flutterToolsStamp.existsSync() &&
      flutterToolsStamp.lastModifiedSync().isAfter(dotPackagesLastModified)) {
    return true;
  }
  return false;
}

/// A handle for interacting with the pub tool.
abstract class Pub {
  /// Create a default [Pub] instance.
  const factory Pub() = _DefaultPub;

  /// Runs `pub get`.
  ///
  /// [context] provides extra information to package server requests to
  /// understand usage.
  Future<void> get({
    @required PubContext context,
    String directory,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool checkLastModified = true,
    bool skipPubspecYamlCheck = false,
  });

  /// Runs pub in 'batch' mode.
  ///
  /// forwarding complete lines written by pub to its stdout/stderr streams to
  /// the corresponding stream of this process, optionally applying filtering.
  /// The pub process will not receive anything on its stdin stream.
  ///
  /// The `--trace` argument is passed to `pub` (by mutating the provided
  /// `arguments` list) when `showTraceForErrors` is true, and when `showTraceForErrors`
  /// is null/unset, and `isRunningOnBot` is true.
  ///
  /// [context] provides extra information to package server requests to
  /// understand usage.
  Future<void> batch(
    List<String> arguments, {
    @required PubContext context,
    String directory,
    MessageFilter filter,
    String failureMessage = 'pub failed',
    @required bool retry,
    bool showTraceForErrors,
  });


  /// Runs pub in 'interactive' mode.
  ///
  /// directly piping the stdin stream of this process to that of pub, and the
  /// stdout/stderr stream of pub to the corresponding streams of this process.
  Future<void> interactively(
    List<String> arguments, {
    String directory,
  });
}

class _DefaultPub implements Pub {
  const _DefaultPub();

  @override
  Future<void> get({
    @required PubContext context,
    String directory,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool checkLastModified = true,
    bool skipPubspecYamlCheck = false,
  }) async {
    directory ??= globals.fs.currentDirectory.path;

    final File pubSpecYaml = globals.fs.file(globals.fs.path.join(directory, 'pubspec.yaml'));
    final File dotPackages = globals.fs.file(globals.fs.path.join(directory, '.packages'));

    if (!skipPubspecYamlCheck && !pubSpecYaml.existsSync()) {
      if (!skipIfAbsent) {
        throwToolExit('$directory: no pubspec.yaml found');
      }
      return;
    }

    final DateTime originalPubspecYamlModificationTime = pubSpecYaml.lastModifiedSync();

    if (!checkLastModified || _shouldRunPubGet(pubSpecYaml: pubSpecYaml, dotPackages: dotPackages)) {
      final String command = upgrade ? 'upgrade' : 'get';
      final Status status = globals.logger.startProgress(
        'Running "flutter pub $command" in ${globals.fs.path.basename(directory)}...',
        timeout: timeoutConfiguration.slowOperation,
      );
      final bool verbose = FlutterCommand.current != null && FlutterCommand.current.globalResults['verbose'] as bool;
      final List<String> args = <String>[
        if (verbose) '--verbose' else '--verbosity=warning',
        ...<String>[command, '--no-precompile'],
        if (offline) '--offline',
      ];
      try {
        await batch(
          args,
          context: context,
          directory: directory,
          filter: _filterOverrideWarnings,
          failureMessage: 'pub $command failed',
          retry: true,
        );
        status.stop();
      } catch (exception) {
        status.cancel();
        rethrow;
      }
    }

    if (!dotPackages.existsSync()) {
      throwToolExit('$directory: pub did not create .packages file.');
    }
    if (pubSpecYaml.lastModifiedSync() != originalPubspecYamlModificationTime) {
      throwToolExit('$directory: unexpected concurrent modification of pubspec.yaml while running pub.');
    }
    // We don't check if dotPackages was actually modified, because as far as we can tell sometimes
    // pub will decide it does not need to actually modify it.
    // Since we rely on the file having a more recent timestamp, though, we do manually force the
    // file to be more recently modified.
    final DateTime now = DateTime.now();
    if (now.isBefore(originalPubspecYamlModificationTime)) {
      globals.printError(
        'Warning: File "${globals.fs.path.absolute(pubSpecYaml.path)}" was created in the future. '
        'Optimizations that rely on comparing time stamps will be unreliable. Check your '
        'system clock for accuracy.\n'
        'The timestamp was: $originalPubspecYamlModificationTime\n'
        'The time now is: $now'
      );
    } else {
      dotPackages.setLastModifiedSync(now);
      final DateTime newDotPackagesTimestamp = dotPackages.lastModifiedSync();
      if (newDotPackagesTimestamp.isBefore(originalPubspecYamlModificationTime)) {
        globals.printError(
          'Warning: Failed to set timestamp of "${globals.fs.path.absolute(dotPackages.path)}". '
          'Tried to set timestamp to $now, but new timestamp is $newDotPackagesTimestamp.'
        );
        if (newDotPackagesTimestamp.isAfter(now)) {
          globals.printError('Maybe the file was concurrently modified?');
        }
      }
    }
  }


  @override
  Future<void> batch(
    List<String> arguments, {
    @required PubContext context,
    String directory,
    MessageFilter filter,
    String failureMessage = 'pub failed',
    @required bool retry,
    bool showTraceForErrors,
  }) async {
    showTraceForErrors ??= isRunningOnBot;

    String lastPubMessage = 'no message';
    bool versionSolvingFailed = false;
    String filterWrapper(String line) {
      lastPubMessage = line;
      if (line.contains('version solving failed')) {
        versionSolvingFailed = true;
      }
      if (filter == null) {
        return line;
      }
      return filter(line);
    }

    if (showTraceForErrors) {
      arguments.insert(0, '--trace');
    }
    int attempts = 0;
    int duration = 1;
    int code;
    loop: while (true) {
      attempts += 1;
      code = await processUtils.stream(
        _pubCommand(arguments),
        workingDirectory: directory,
        mapFunction: filterWrapper, // may set versionSolvingFailed, lastPubMessage
        environment: _createPubEnvironment(context),
      );
      String message;
      switch (code) {
        case 69: // UNAVAILABLE in https://github.com/dart-lang/pub/blob/master/lib/src/exit_codes.dart
          message = 'server unavailable';
          break;
        default:
          break loop;
      }
      assert(message != null);
      versionSolvingFailed = false;
      globals.printStatus('$failureMessage ($message) -- attempting retry $attempts in $duration second${ duration == 1 ? "" : "s"}...');
      await Future<void>.delayed(Duration(seconds: duration));
      if (duration < 64) {
        duration *= 2;
      }
    }
    assert(code != null);

    String result = 'success';
    if (versionSolvingFailed) {
      result = 'version-solving-failed';
    } else if (code != 0) {
      result = 'failure';
    }
    PubResultEvent(
      context: context.toAnalyticsString(),
      result: result,
    ).send();

    if (code != 0) {
      throwToolExit('$failureMessage ($code; $lastPubMessage)', exitCode: code);
    }
  }

  @override
  Future<void> interactively(
    List<String> arguments, {
    String directory,
  }) async {
    Cache.releaseLockEarly();
    final io.Process process = await processUtils.start(
      _pubCommand(arguments),
      workingDirectory: directory,
      environment: _createPubEnvironment(PubContext.interactive),
    );

    // Pipe the Flutter tool stdin to the pub stdin.
    unawaited(process.stdin.addStream(io.stdin));

    // Pipe the put stdout and stderr to the tool stdout and stderr.
    await Future.wait<dynamic>(<Future<dynamic>>[
      io.stdout.addStream(process.stdout),
      io.stderr.addStream(process.stderr),
    ]);

    // Wait for pub to exit.
    final int code = await process.exitCode;
    if (code != 0) {
      throwToolExit('pub finished with exit code $code', exitCode: code);
    }
  }

  /// The command used for running pub.
  List<String> _pubCommand(List<String> arguments) {
    return <String>[sdkBinaryName('pub'), ...arguments];
  }

}

typedef MessageFilter = String Function(String message);

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

final RegExp _analyzerWarning = RegExp(r'^! \w+ [^ ]+ from path \.\./\.\./bin/cache/dart-sdk/lib/\w+$');

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
  final String existing = globals.platform.environment[_pubEnvironmentKey];
  final List<String> values = <String>[
    if (existing != null && existing.isNotEmpty) existing,
    if (isRunningOnBot) 'flutter_bot',
    'flutter_cli',
    ...pubContext._values,
  ];
  return values.join(':');
}

String _getRootPubCacheIfAvailable() {
  if (globals.platform.environment.containsKey(_pubCacheEnvironmentKey)) {
    return globals.platform.environment[_pubCacheEnvironmentKey];
  }

  final String cachePath = globals.fs.path.join(Cache.flutterRoot, '.pub-cache');
  if (globals.fs.directory(cachePath).existsSync()) {
    globals.printTrace('Using $cachePath for the pub cache.');
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
  if (message == 'Warning: You are using these overridden dependencies:') {
    return null;
  }
  if (message.contains(_analyzerWarning)) {
    return null;
  }
  return message;
}
