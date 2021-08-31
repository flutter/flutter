// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import '../base/bot_detector.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart' as io;
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../reporting/reporting.dart';

/// The [Pub] instance.
Pub get pub => context.get<Pub>()!;

/// The console environment key used by the pub tool.
const String _kPubEnvironmentKey = 'PUB_ENVIRONMENT';

/// The console environment key used by the pub tool to find the cache directory.
const String _kPubCacheEnvironmentKey = 'PUB_CACHE';

typedef MessageFilter = String Function(String message);

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

/// A handle for interacting with the pub tool.
abstract class Pub {
  /// Create a default [Pub] instance.
  factory Pub({
    required FileSystem fileSystem,
    required Logger logger,
    required ProcessManager processManager,
    required Platform platform,
    required BotDetector botDetector,
    required Usage usage,
  }) = _DefaultPub;

  /// Runs `pub get`.
  ///
  /// [context] provides extra information to package server requests to
  /// understand usage.
  ///
  /// If [shouldSkipThirdPartyGenerator] is true, the overall pub get will be
  /// skipped if the package config file has a "generator" other than "pub".
  /// Defaults to true.
  Future<void> get({
    required PubContext context,
    String directory,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool generateSyntheticPackage = false,
    String flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
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
    required PubContext context,
    String directory,
    MessageFilter filter,
    String failureMessage = 'pub failed',
    required bool retry,
    bool showTraceForErrors,
  });

  /// Runs pub in 'interactive' mode.
  ///
  /// directly piping the stdin stream of this process to that of pub, and the
  /// stdout/stderr stream of pub to the corresponding streams of this process.
  Future<void> interactively(
    List<String> arguments, {
    String directory,
    required io.Stdio stdio,
    bool touchesPackageConfig = false,
    bool generateSyntheticPackage = false,
  });
}

class _DefaultPub implements Pub {
  _DefaultPub({
    required FileSystem fileSystem,
    required Logger logger,
    required ProcessManager processManager,
    required Platform platform,
    required BotDetector botDetector,
    required Usage usage,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _platform = platform,
       _botDetector = botDetector,
       _usage = usage,
       _processUtils = ProcessUtils(
         logger: logger,
         processManager: processManager,
       ),
       _processManager = processManager;

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessUtils _processUtils;
  final Platform _platform;
  final BotDetector _botDetector;
  final Usage _usage;
  final ProcessManager _processManager;

  @override
  Future<void> get({
    required PubContext context,
    String? directory,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool generateSyntheticPackage = false,
    String? flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
  }) async {
    directory ??= _fileSystem.currentDirectory.path;
    final File packageConfigFile = _fileSystem.file(
      _fileSystem.path.join(directory, '.dart_tool', 'package_config.json'));
    final Directory generatedDirectory = _fileSystem.directory(
      _fileSystem.path.join(directory, '.dart_tool', 'flutter_gen'));
    final File lastVersion = _fileSystem.file(
      _fileSystem.path.join(directory, '.dart_tool', 'version'));
    final File currentVersion = _fileSystem.file(
      _fileSystem.path.join(Cache.flutterRoot!, 'version'));
    final File pubspecYaml = _fileSystem.file(
      _fileSystem.path.join(directory, 'pubspec.yaml'));
    final File pubLockFile = _fileSystem.file(
      _fileSystem.path.join(directory, 'pubspec.lock')
    );

    if (shouldSkipThirdPartyGenerator && packageConfigFile.existsSync()) {
      Map<String, Object?> packageConfigMap;
      try {
        packageConfigMap = jsonDecode(
          packageConfigFile.readAsStringSync(),
        ) as Map<String, Object?>;
      } on FormatException {
        packageConfigMap = <String, Object?>{};
      }

      final bool isPackageConfigGeneratedByThirdParty =
          packageConfigMap.containsKey('generator') &&
          packageConfigMap['generator'] != 'pub';

      if (isPackageConfigGeneratedByThirdParty) {
        _logger.printTrace('Skipping pub get: generated by third-party.');
        return;
      }
    }

    // If the pubspec.yaml is older than the package config file and the last
    // flutter version used is the same as the current version skip pub get.
    // This will incorrectly skip pub on the master branch if dependencies
    // are being added/removed from the flutter framework packages, but this
    // can be worked around by manually running pub.
    if (checkUpToDate &&
        packageConfigFile.existsSync() &&
        pubLockFile.existsSync() &&
        pubspecYaml.lastModifiedSync().isBefore(pubLockFile.lastModifiedSync()) &&
        pubspecYaml.lastModifiedSync().isBefore(packageConfigFile.lastModifiedSync()) &&
        lastVersion.existsSync() &&
        lastVersion.readAsStringSync() == currentVersion.readAsStringSync()) {
      _logger.printTrace('Skipping pub get: version match.');
      return;
    }

    final String command = upgrade ? 'upgrade' : 'get';
    final Status status = _logger.startProgress(
      'Running "flutter pub $command" in ${_fileSystem.path.basename(directory)}...',
    );
    final bool verbose = _logger.isVerbose;
    final List<String> args = <String>[
      if (verbose)
        '--verbose'
      else
        '--verbosity=warning',
      ...<String>[
        command,
        '--no-precompile',
      ],
      if (offline)
        '--offline',
    ];
    try {
      await batch(
        args,
        context: context,
        directory: directory,
        failureMessage: 'pub $command failed',
        retry: true,
        flutterRootOverride: flutterRootOverride,
      );
      status.stop();
    // The exception is rethrown, so don't catch only Exceptions.
    } catch (exception) { // ignore: avoid_catches_without_on_clauses
      status.cancel();
      rethrow;
    }

    if (!packageConfigFile.existsSync()) {
      throwToolExit('$directory: pub did not create .dart_tools/package_config.json file.');
    }
    lastVersion.writeAsStringSync(currentVersion.readAsStringSync());
    await _updatePackageConfig(
      packageConfigFile,
      generatedDirectory,
      generateSyntheticPackage,
    );
  }

  @override
  Future<void> batch(
    List<String> arguments, {
    required PubContext context,
    String? directory,
    MessageFilter? filter,
    String failureMessage = 'pub failed',
    required bool retry,
    bool? showTraceForErrors,
    String? flutterRootOverride,
  }) async {
    showTraceForErrors ??= await _botDetector.isRunningOnBot;

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
      code = await _processUtils.stream(
        _pubCommand(arguments),
        workingDirectory: directory,
        mapFunction: filterWrapper, // may set versionSolvingFailed, lastPubMessage
        environment: await _createPubEnvironment(context, flutterRootOverride),
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
      _logger.printStatus(
        '$failureMessage ($message) -- attempting retry $attempts in $duration '
        'second${ duration == 1 ? "" : "s"}...',
      );
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
      usage: _usage,
    ).send();

    if (code != 0) {
      throwToolExit('$failureMessage ($code; $lastPubMessage)', exitCode: code);
    }
  }

  @override
  Future<void> interactively(
    List<String> arguments, {
    String? directory,
    required io.Stdio stdio,
    bool touchesPackageConfig = false,
    bool generateSyntheticPackage = false,
  }) async {
    // Fully resolved pub or pub.bat is calculated based on current platform.
    final io.Process process = await _processUtils.start(
      _pubCommand(arguments),
      workingDirectory: directory,
      environment: await _createPubEnvironment(PubContext.interactive),
    );

    // Pipe the Flutter tool stdin to the pub stdin.
    unawaited(process.stdin.addStream(stdio.stdin)
      // If pub exits unexpectedly with an error, that will be reported below
      // by the tool exit after the exit code check.
      .catchError((dynamic err, StackTrace stack) {
        _logger.printTrace('Echoing stdin to the pub subprocess failed:');
        _logger.printTrace('$err\n$stack');
      }
    ));

    // Pipe the pub stdout and stderr to the tool stdout and stderr.
    try {
      await Future.wait<dynamic>(<Future<dynamic>>[
        stdio.addStdoutStream(process.stdout),
        stdio.addStderrStream(process.stderr),
      ]);
    } on Exception catch (err, stack) {
      _logger.printTrace('Echoing stdout or stderr from the pub subprocess failed:');
      _logger.printTrace('$err\n$stack');
    }

    // Wait for pub to exit.
    final int code = await process.exitCode;
    if (code != 0) {
      throwToolExit('pub finished with exit code $code', exitCode: code);
    }

    if (touchesPackageConfig) {
      final String targetDirectory = directory ?? _fileSystem.currentDirectory.path;
      final File packageConfigFile = _fileSystem.file(
        _fileSystem.path.join(targetDirectory, '.dart_tool', 'package_config.json'));
      final Directory generatedDirectory = _fileSystem.directory(
        _fileSystem.path.join(targetDirectory, '.dart_tool', 'flutter_gen'));
      final File lastVersion = _fileSystem.file(
        _fileSystem.path.join(targetDirectory, '.dart_tool', 'version'));
      final File currentVersion = _fileSystem.file(
        _fileSystem.path.join(Cache.flutterRoot!, 'version'));
        lastVersion.writeAsStringSync(currentVersion.readAsStringSync());
      await _updatePackageConfig(
        packageConfigFile,
        generatedDirectory,
        generateSyntheticPackage,
      );
    }
  }

  /// The command used for running pub.
  List<String> _pubCommand(List<String> arguments) {
    // TODO(zanderso): refactor to use artifacts.
    final String sdkPath = _fileSystem.path.joinAll(<String>[
      Cache.flutterRoot!,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      'dart',
    ]);
    if (!_processManager.canRun(sdkPath)) {
      throwToolExit(
        'Your Flutter SDK download may be corrupt or missing permissions to run. '
        'Try re-downloading the Flutter SDK into a directory that has read/write '
        'permissions for the current user.'
      );
    }
    return <String>[sdkPath, '__deprecated_pub', ...arguments];
  }

  // Returns the environment value that should be used when running pub.
  //
  // Includes any existing environment variable, if one exists.
  //
  // [context] provides extra information to package server requests to
  // understand usage.
  Future<String> _getPubEnvironmentValue(PubContext pubContext) async {
    // DO NOT update this function without contacting kevmoo.
    // We have server-side tooling that assumes the values are consistent.
    final String? existing = _platform.environment[_kPubEnvironmentKey];
    final List<String> values = <String>[
      if (existing != null && existing.isNotEmpty) existing,
      if (await _botDetector.isRunningOnBot) 'flutter_bot',
      'flutter_cli',
      ...pubContext._values,
    ];
    return values.join(':');
  }

  String? _getRootPubCacheIfAvailable() {
    if (_platform.environment.containsKey(_kPubCacheEnvironmentKey)) {
      return _platform.environment[_kPubCacheEnvironmentKey];
    }

    final String cachePath = _fileSystem.path.join(Cache.flutterRoot!, '.pub-cache');
    if (_fileSystem.directory(cachePath).existsSync()) {
      _logger.printTrace('Using $cachePath for the pub cache.');
      return cachePath;
    }

    // Use pub's default location by returning null.
    return null;
  }

  /// The full environment used when running pub.
  ///
  /// [context] provides extra information to package server requests to
  /// understand usage.
  Future<Map<String, String>> _createPubEnvironment(PubContext context, [ String? flutterRootOverride ]) async {
    final Map<String, String> environment = <String, String>{
      'FLUTTER_ROOT': flutterRootOverride ?? Cache.flutterRoot!,
      _kPubEnvironmentKey: await _getPubEnvironmentValue(context),
    };
    final String? pubCache = _getRootPubCacheIfAvailable();
    if (pubCache != null) {
      environment[_kPubCacheEnvironmentKey] = pubCache;
    }
    return environment;
  }

  /// Update the package configuration file.
  ///
  /// Creates a corresponding `package_config_subset` file that is used by the build
  /// system to avoid rebuilds caused by an updated pub timestamp.
  ///
  /// if [generateSyntheticPackage] is true then insert flutter_gen synthetic
  /// package into the package configuration. This is used by the l10n localization
  /// tooling to insert a new reference into the package_config file, allowing the import
  /// of a package URI that is not specified in the pubspec.yaml
  ///
  /// For more information, see:
  ///   * [generateLocalizations], `in lib/src/localizations/gen_l10n.dart`
  Future<void> _updatePackageConfig(
    File packageConfigFile,
    Directory generatedDirectory,
    bool generateSyntheticPackage,
  ) async {
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(packageConfigFile, logger: _logger);

    packageConfigFile.parent
      .childFile('package_config_subset')
      .writeAsStringSync(_computePackageConfigSubset(
        packageConfig,
        _fileSystem,
      ));

    if (!generateSyntheticPackage) {
      return;
    }
    if (packageConfig.packages.any((Package package) => package.name == 'flutter_gen')) {
      return;
    }

    // TODO(jonahwillams): Using raw json manipulation here because
    // savePackageConfig always writes to local io, and it changes absolute
    // paths to relative on round trip.
    // See: https://github.com/dart-lang/package_config/issues/99,
    // and: https://github.com/dart-lang/package_config/issues/100.

    // Because [loadPackageConfigWithLogging] succeeded [packageConfigFile]
    // we can rely on the file to exist and be correctly formatted.
    final Map<String, dynamic> jsonContents =
        json.decode(packageConfigFile.readAsStringSync()) as Map<String, dynamic>;

    (jsonContents['packages'] as List<dynamic>).add(<String, dynamic>{
      'name': 'flutter_gen',
      'rootUri': 'flutter_gen',
      'languageVersion': '2.12',
    });

    packageConfigFile.writeAsStringSync(json.encode(jsonContents));
  }

  // Subset the package config file to only the parts that are relevant for
  // rerunning the dart compiler.
  String _computePackageConfigSubset(PackageConfig packageConfig, FileSystem fileSystem) {
    final StringBuffer buffer = StringBuffer();
    for (final Package package in packageConfig.packages) {
      buffer.writeln(package.name);
      buffer.writeln(package.languageVersion);
      buffer.writeln(package.root);
      buffer.writeln(package.packageUriRoot);
    }
    buffer.writeln(packageConfig.version);
    return buffer.toString();
  }
}
