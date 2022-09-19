// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import '../base/bot_detector.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart' as io;
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/package_map.dart';
import '../project.dart';
import '../reporting/reporting.dart';

/// The [Pub] instance.
Pub get pub => context.get<Pub>()!;

/// The console environment key used by the pub tool.
const String _kPubEnvironmentKey = 'PUB_ENVIRONMENT';

/// The console environment key used by the pub tool to find the cache directory.
const String _kPubCacheEnvironmentKey = 'PUB_CACHE';

/// The UNAVAILABLE exit code returned by the pub tool.
/// (see https://github.com/dart-lang/pub/blob/master/lib/src/exit_codes.dart)
const int _kPubExitCodeUnavailable = 69;

typedef MessageFilter = String? Function(String message);

/// globalCachePath is the directory in which the content of the localCachePath will be moved in
void joinCaches({
  required FileSystem fileSystem,
  required Directory globalCacheDirectory,
  required Directory dependencyDirectory,
}) {
  for (final FileSystemEntity entity in dependencyDirectory.listSync()) {
    final String newPath = fileSystem.path.join(globalCacheDirectory.path, entity.basename);
    if (entity is File) {
      if (!fileSystem.file(newPath).existsSync()) {
        entity.copySync(newPath);
      }
    } else if (entity is Directory) {
      if (!globalCacheDirectory.childDirectory(entity.basename).existsSync()) {
        final Directory newDirectory = globalCacheDirectory.childDirectory(entity.basename);
        newDirectory.createSync();
        joinCaches(
          fileSystem: fileSystem,
          globalCacheDirectory: newDirectory,
          dependencyDirectory: entity,
        );
      }
    }
  }
}

Directory createDependencyDirectory(Directory pubGlobalDirectory, String dependencyName) {
  final Directory newDirectory = pubGlobalDirectory.childDirectory(dependencyName);
  newDirectory.createSync();
  return newDirectory;
}

bool tryDelete(Directory directory, Logger logger) {
  try {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  } on FileSystemException {
    logger.printWarning('Failed to delete directory at: ${directory.path}');
    return false;
  }
  return true;
}

/// When local cache (flutter_root/.pub-cache) and global cache (HOME/.pub-cache) are present a
/// merge needs to be done leaving only the global
///
/// Valid pubCache should look like this ./localCachePath/.pub-cache/hosted/pub.dartlang.org
bool needsToJoinCache({
  required FileSystem fileSystem,
  required String localCachePath,
  required Directory? globalDirectory,
}) {
  if (globalDirectory == null) {
    return false;
  }
  final Directory localDirectory = fileSystem.directory(localCachePath);

  return globalDirectory.childDirectory('hosted').childDirectory('pub.dartlang.org').existsSync() &&
    localDirectory.childDirectory('hosted').childDirectory('pub.dartlang.org').existsSync();
}

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
    required Stdio stdio,
  }) = _DefaultPub;

  /// Runs `pub get` or `pub upgrade` for [project].
  ///
  /// [context] provides extra information to package server requests to
  /// understand usage.
  ///
  /// If [shouldSkipThirdPartyGenerator] is true, the overall pub get will be
  /// skipped if the package config file has a "generator" other than "pub".
  /// Defaults to true.
  /// Will also resolve dependencies in the example folder if present.
  Future<void> get({
    required PubContext context,
    required FlutterProject project,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    String? flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
    bool printProgress = true,
  });

  /// Runs pub in 'batch' mode.
  ///
  /// forwarding complete lines written by pub to its stdout/stderr streams to
  /// the corresponding stream of this process, optionally applying filtering.
  /// The pub process will not receive anything on its stdin stream.
  ///
  /// The `--trace` argument is passed to `pub` when `showTraceForErrors`
  /// `isRunningOnBot` is true.
  ///
  /// [context] provides extra information to package server requests to
  /// understand usage.
  Future<void> batch(
    List<String> arguments, {
    required PubContext context,
    String? directory,
    MessageFilter? filter,
    String failureMessage = 'pub failed',
  });

  /// Runs pub in 'interactive' mode.
  ///
  /// directly piping the stdin stream of this process to that of pub, and the
  /// stdout/stderr stream of pub to the corresponding streams of this process.
  Future<void> interactively(
    List<String> arguments, {
    String? directory,
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
    required Stdio stdio,
  }) : _fileSystem = fileSystem,
       _logger = logger,
       _platform = platform,
       _botDetector = botDetector,
       _usage = usage,
       _processUtils = ProcessUtils(
         logger: logger,
         processManager: processManager,
       ),
       _processManager = processManager,
       _stdio = stdio;

  final FileSystem _fileSystem;
  final Logger _logger;
  final ProcessUtils _processUtils;
  final Platform _platform;
  final BotDetector _botDetector;
  final Usage _usage;
  final ProcessManager _processManager;
  final Stdio _stdio;

  @override
  Future<void> get({
    required PubContext context,
    required FlutterProject project,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool generateSyntheticPackage = false,
    bool generateSyntheticPackageForExample = false,
    String? flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
    bool printProgress = true,
  }) async {
    final String directory = project.directory.path;
    final File packageConfigFile = project.packageConfigFile;
    final Directory generatedDirectory = _fileSystem.directory(
      _fileSystem.path.join(directory, '.dart_tool', 'flutter_gen'));
    final File lastVersion = _fileSystem.file(
      _fileSystem.path.join(directory, '.dart_tool', 'version'));
    final File currentVersion = _fileSystem.file(
      _fileSystem.path.join(Cache.flutterRoot!, 'version'));
    final File pubspecYaml = project.pubspecFile;
    final File pubLockFile = _fileSystem.file(
      _fileSystem.path.join(directory, 'pubspec.lock')
    );

    if (shouldSkipThirdPartyGenerator && project.packageConfigFile.existsSync()) {
      Map<String, Object?> packageConfigMap;
      try {
        packageConfigMap = jsonDecode(
          project.packageConfigFile.readAsStringSync(),
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
    final bool verbose = _logger.isVerbose;
    final List<String> args = <String>[
      if (_logger.supportsColor)
        '--color',
      if (verbose)
        '--verbose',
      '--directory',
      _fileSystem.path.relative(directory),
      ...<String>[
        command,
      ],
      if (offline)
        '--offline',
      '--example',
    ];
    await _runWithRetries(
      args,
      command: command,
      context: context,
      directory: directory,
      failureMessage: 'pub $command failed',
      retry: !offline,
      flutterRootOverride: flutterRootOverride,
      printProgress: printProgress
    );

    if (!packageConfigFile.existsSync()) {
      throwToolExit('$directory: pub did not create .dart_tools/package_config.json file.');
    }
    lastVersion.writeAsStringSync(currentVersion.readAsStringSync());
    await _updatePackageConfig(
      packageConfigFile,
      generatedDirectory,
      project.manifest.generateSyntheticPackage,
    );
    if (project.hasExampleApp && project.example.pubspecFile.existsSync()) {
      final Directory exampleGeneratedDirectory = _fileSystem.directory(
        _fileSystem.path.join(project.example.directory.path, '.dart_tool', 'flutter_gen'));
      await _updatePackageConfig(
        project.example.packageConfigFile,
        exampleGeneratedDirectory,
        project.example.manifest.generateSyntheticPackage,
      );
    }
  }

  /// Runs pub with [arguments].
  ///
  /// Retries the command as long as the exit code is
  /// `_kPubExitCodeUnavailable`.
  ///
  /// Prints the stderr and stdout of the last run.
  ///
  /// Sends an analytics event
  Future<void> _runWithRetries(
    List<String> arguments, {
    required String command,
    required bool printProgress,
    required PubContext context,
    required bool retry,
    required String directory,
    String failureMessage = 'pub failed',
    String? flutterRootOverride,
  }) async {
    int exitCode;
    int attempts = 0;
    int duration = 1;

    List<_OutputLine>? output;
    StreamSubscription<String> recordLines(Stream<List<int>> stream, _OutputStream streamName) {
      return stream
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen((String line) => output!.add(_OutputLine(line, streamName)));
    }

    final Status? status = printProgress
      ? _logger.startProgress('Running "flutter pub $command" in ${_fileSystem.path.basename(directory)}...',)
      : null;
    final List<String> pubCommand = _pubCommand(arguments);
    final Map<String, String> pubEnvironment = await _createPubEnvironment(context, flutterRootOverride);
    try {
      do {
        output = <_OutputLine>[];
        attempts += 1;
        final io.Process process = await _processUtils.start(
          pubCommand,
          workingDirectory: _fileSystem.path.current,
          environment: pubEnvironment,
        );
        final StreamSubscription<String> stdoutSubscription =
          recordLines(process.stdout, _OutputStream.stdout);
        final StreamSubscription<String> stderrSubscription =
          recordLines(process.stderr, _OutputStream.stderr);

        exitCode = await process.exitCode;
        unawaited(stdoutSubscription.cancel());
        unawaited(stderrSubscription.cancel());

        if (retry && exitCode == _kPubExitCodeUnavailable) {
          _logger.printStatus(
            '$failureMessage (server unavailable) -- attempting retry $attempts in $duration '
            'second${ duration == 1 ? "" : "s"}...',
          );
          await Future<void>.delayed(Duration(seconds: duration));
          if (duration < 64) {
            duration *= 2;
          }
          // This will cause a retry.
          output = null;
        }
      } while (output == null);
      status?.stop();
    // The exception is rethrown, so don't catch only Exceptions.
    } catch (exception) { // ignore: avoid_catches_without_on_clauses
      status?.cancel();
      if (exception is io.ProcessException) {
        final StringBuffer buffer = StringBuffer('${exception.message}\n');
        buffer.writeln('Working directory: "$directory"');
        final Map<String, String> env = await _createPubEnvironment(context, flutterRootOverride);
        buffer.write(_stringifyPubEnv(env));
        throw io.ProcessException(
          exception.executable,
          exception.arguments,
          buffer.toString(),
          exception.errorCode,
        );
      }
      rethrow;
    }

    if (printProgress) {
      // Show the output of the last run.
      for (final _OutputLine line in output) {
        switch (line.stream) {
          case _OutputStream.stdout:
            _stdio.stdoutWrite('${line.line}\n');
            break;
          case _OutputStream.stderr:
            _stdio.stderrWrite('${line.line}\n');
            break;
        }
      }
    }

    final int code = exitCode;
    String result = 'success';
    if (output.any((_OutputLine line) => line.line.contains('version solving failed'))) {
      result = 'version-solving-failed';
    } else if (code != 0) {
      result = 'failure';
    }
    PubResultEvent(
      context: context.toAnalyticsString(),
      result: result,
      usage: _usage,
    ).send();
    final String lastPubMessage = output.isEmpty ? 'no message' : output.last.line;

    if (code != 0) {
      final StringBuffer buffer = StringBuffer('$failureMessage\n');
      buffer.writeln('command: "${pubCommand.join(' ')}"');
      buffer.write(_stringifyPubEnv(pubEnvironment));
      buffer.writeln('exit code: $code');
      buffer.writeln('last line of pub output: "${lastPubMessage.trim()}"');
      throwToolExit(
        buffer.toString(),
        exitCode: code,
      );
    }
  }

  // For surfacing pub env in crash reporting
  String _stringifyPubEnv(Map<String, String> map, {String prefix = 'pub env'}) {
    if (map.isEmpty) {
      return '';
    }
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('$prefix: {');
    for (final MapEntry<String, String> entry in map.entries) {
      buffer.writeln('  "${entry.key}": "${entry.value}",');
    }
    buffer.writeln('}');
    return buffer.toString();
  }

  @override
  Future<void> batch(
    List<String> arguments, {
    required PubContext context,
    String? directory,
    MessageFilter? filter,
    String failureMessage = 'pub failed',
    String? flutterRootOverride,
  }) async {
    final bool showTraceForErrors = await _botDetector.isRunningOnBot;

    String lastPubMessage = 'no message';
    String? filterWrapper(String line) {
      lastPubMessage = line;
      if (filter == null) {
        return line;
      }
      return filter(line);
    }

    if (showTraceForErrors) {
      arguments.insert(0, '--trace');
    }
    final Map<String, String> pubEnvironment = await _createPubEnvironment(context, flutterRootOverride);
    final List<String> pubCommand = _pubCommand(arguments);
    final int code = await _processUtils.stream(
        pubCommand,
        workingDirectory: directory,
        mapFunction: filterWrapper, // may set versionSolvingFailed, lastPubMessage
        environment: pubEnvironment,
      );

    String result = 'success';
    if (code != 0) {
      result = 'failure';
    }
    PubResultEvent(
      context: context.toAnalyticsString(),
      result: result,
      usage: _usage,
    ).send();

    if (code != 0) {
      final StringBuffer buffer = StringBuffer('$failureMessage\n');
      buffer.writeln('command: "${pubCommand.join(' ')}"');
      buffer.write(_stringifyPubEnv(pubEnvironment));
      buffer.writeln('exit code: $code');
      buffer.writeln('last line of pub output: "${lastPubMessage.trim()}"');
      throwToolExit(
        buffer.toString(),
        exitCode: code,
      );
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
      _pubCommand(<String>[
          if (_logger.supportsColor) '--color',
          ...arguments,
      ]),
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

  /// There are 3 ways to get the pub cache location
  ///
  /// 1) Provide the _kPubCacheEnvironmentKey.
  /// 2) There is a local cache (in the Flutter SDK) but not a global one (in the user's home directory).
  /// 3) If both local and global are available then merge the local into global and return the global.
  String? _getPubCacheIfAvailable() {
    if (_platform.environment.containsKey(_kPubCacheEnvironmentKey)) {
      return _platform.environment[_kPubCacheEnvironmentKey];
    }

    final String localCachePath = _fileSystem.path.join(Cache.flutterRoot!, '.pub-cache');
    final Directory? globalDirectory;
    if (_platform.isWindows) {
      globalDirectory = _getWindowsGlobalDirectory;
    }
    else {
      if (_platform.environment['HOME'] == null) {
        globalDirectory = null;
      } else {
        final String homeDirectoryPath = _platform.environment['HOME']!;
        globalDirectory = _fileSystem.directory(_fileSystem.path.join(homeDirectoryPath, '.pub-cache'));
      }
    }

    if (needsToJoinCache(
      fileSystem: _fileSystem,
      localCachePath: localCachePath,
      globalDirectory: globalDirectory,
    )) {
      final Directory localDirectoryPub = _fileSystem.directory(
        _fileSystem.path.join(localCachePath, 'hosted', 'pub.dartlang.org')
      );
      final Directory globalDirectoryPub = _fileSystem.directory(
        _fileSystem.path.join(globalDirectory!.path, 'hosted', 'pub.dartlang.org')
      );
      for (final FileSystemEntity entity in localDirectoryPub.listSync()) {
        if (entity is Directory && !globalDirectoryPub.childDirectory(entity.basename).existsSync()){
          try {
            final Directory newDirectory = createDependencyDirectory(globalDirectoryPub, entity.basename);
            joinCaches(
              fileSystem: _fileSystem,
              globalCacheDirectory: newDirectory,
              dependencyDirectory: entity,
            );
          } on FileSystemException {
            if (!tryDelete(globalDirectoryPub.childDirectory(entity.basename), _logger)) {
              _logger.printWarning('The join of pub-caches failed');
              _logger.printStatus('Running "dart pub cache repair"');
              _processManager.runSync(<String>['dart', 'pub', 'cache', 'repair']);
            }
          }
        }
      }
      tryDelete(_fileSystem.directory(localCachePath), _logger);
      return globalDirectory.path;
    } else if (globalDirectory != null && globalDirectory.existsSync()) {
      return globalDirectory.path;
    } else if (_fileSystem.directory(localCachePath).existsSync()) {
      return localCachePath;
    }
    // Use pub's default location by returning null.
    return null;
  }

  Directory? get _getWindowsGlobalDirectory {
    // %LOCALAPPDATA% is preferred as the cache location over %APPDATA%, because the latter is synchronised between
    // devices when the user roams between them, whereas the former is not.
    // The default cache dir used to be in %APPDATA%, so to avoid breaking old installs,
    // we use the old dir in %APPDATA% if it exists. Else, we use the new default location
    // in %LOCALAPPDATA%.
    for (final String envVariable in <String>['APPDATA', 'LOCALAPPDATA']) {
      if (_platform.environment[envVariable] != null) {
        final String homePath = _platform.environment[envVariable]!;
        final Directory globalDirectory = _fileSystem.directory(_fileSystem.path.join(homePath, 'Pub', 'Cache'));
        if (globalDirectory.existsSync()) {
          return globalDirectory;
        }
      }
    }
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
    final String? pubCache = _getPubCacheIfAvailable();
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

class _OutputLine {
  _OutputLine(this.line, this.stream);
  final String line;
  final _OutputStream stream;
}

enum _OutputStream {
  stdout,
  stderr,
}
