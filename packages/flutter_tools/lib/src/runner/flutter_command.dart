// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:quiver/strings.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/io.dart' as io;
import '../base/signals.dart';
import '../base/terminal.dart';
import '../base/time.dart';
import '../base/user_messages.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../build_system/targets/icon_tree_shaker.dart' show kIconTreeShakerEnabledDefault;
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../doctor.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import 'flutter_command_runner.dart';

export '../cache.dart' show DevelopmentArtifact;

enum ExitStatus {
  success,
  warning,
  fail,
  killed,
}

/// [FlutterCommand]s' subclasses' [FlutterCommand.runCommand] can optionally
/// provide a [FlutterCommandResult] to furnish additional information for
/// analytics.
class FlutterCommandResult {
  const FlutterCommandResult(
    this.exitStatus, {
    this.timingLabelParts,
    this.endTimeOverride,
  });

  /// A command that succeeded. It is used to log the result of a command invocation.
  factory FlutterCommandResult.success() {
    return const FlutterCommandResult(ExitStatus.success);
  }

  /// A command that exited with a warning. It is used to log the result of a command invocation.
  factory FlutterCommandResult.warning() {
    return const FlutterCommandResult(ExitStatus.warning);
  }

  /// A command that failed. It is used to log the result of a command invocation.
  factory FlutterCommandResult.fail() {
    return const FlutterCommandResult(ExitStatus.fail);
  }

  final ExitStatus exitStatus;

  /// Optional data that can be appended to the timing event.
  /// https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#timingLabel
  /// Do not add PII.
  final List<String> timingLabelParts;

  /// Optional epoch time when the command's non-interactive wait time is
  /// complete during the command's execution. Use to measure user perceivable
  /// latency without measuring user interaction time.
  ///
  /// [FlutterCommand] will automatically measure and report the command's
  /// complete time if not overridden.
  final DateTime endTimeOverride;

  @override
  String toString() {
    switch (exitStatus) {
      case ExitStatus.success:
        return 'success';
      case ExitStatus.warning:
        return 'warning';
      case ExitStatus.fail:
        return 'fail';
      case ExitStatus.killed:
        return 'killed';
      default:
        assert(false);
        return null;
    }
  }
}

/// Common flutter command line options.
class FlutterOptions {
  static const String kExtraFrontEndOptions = 'extra-front-end-options';
  static const String kExtraGenSnapshotOptions = 'extra-gen-snapshot-options';
  static const String kEnableExperiment = 'enable-experiment';
  static const String kFileSystemRoot = 'filesystem-root';
  static const String kFileSystemScheme = 'filesystem-scheme';
}

abstract class FlutterCommand extends Command<void> {
  /// The currently executing command (or sub-command).
  ///
  /// Will be `null` until the top-most command has begun execution.
  static FlutterCommand get current => context.get<FlutterCommand>();

  /// The option name for a custom observatory port.
  static const String observatoryPortOption = 'observatory-port';

  /// The flag name for whether or not to use ipv6.
  static const String ipv6Flag = 'ipv6';

  @override
  ArgParser get argParser => _argParser;
  final ArgParser _argParser = ArgParser(
    allowTrailingOptions: false,
    usageLineLength: outputPreferences.wrapText ? outputPreferences.wrapColumn : null,
  );

  @override
  FlutterCommandRunner get runner => super.runner as FlutterCommandRunner;

  bool _requiresPubspecYaml = false;

  /// Whether this command uses the 'target' option.
  bool _usesTargetOption = false;

  bool _usesPubOption = false;

  bool _usesPortOption = false;

  bool _usesIpv6Flag = false;

  bool get shouldRunPub => _usesPubOption && boolArg('pub');

  bool get shouldUpdateCache => true;

  bool _excludeDebug = false;

  BuildMode _defaultBuildMode;

  void requiresPubspecYaml() {
    _requiresPubspecYaml = true;
  }

  void usesWebOptions({ bool hide = true }) {
    argParser.addOption('web-hostname',
      defaultsTo: 'localhost',
      help: 'The hostname to serve web application on.',
      hide: hide,
    );
    argParser.addOption('web-port',
      defaultsTo: null,
      help: 'The host port to serve the web application from. If not provided, the tool '
        'will select a random open port on the host.',
      hide: hide,
    );
    argParser.addFlag('web-allow-expose-url',
      defaultsTo: false,
      help: 'Enables daemon-to-editor requests (app.exposeUrl) for exposing URLs '
        'when running on remote machines.',
      hide: hide,
    );
  }

  void usesTargetOption() {
    argParser.addOption('target',
      abbr: 't',
      defaultsTo: bundle.defaultMainPath,
      help: 'The main entry-point file of the application, as run on the device.\n'
            'If the --target option is omitted, but a file name is provided on '
            'the command line, then that is used instead.',
      valueHelp: 'path');
    _usesTargetOption = true;
  }

  String get targetFile {
    if (argResults.wasParsed('target')) {
      return stringArg('target');
    }
    if (argResults.rest.isNotEmpty) {
      return argResults.rest.first;
    }
    return bundle.defaultMainPath;
  }

  void usesPubOption({bool hide = false}) {
    argParser.addFlag('pub',
      defaultsTo: true,
      hide: hide,
      help: 'Whether to run "flutter pub get" before executing this command.');
    _usesPubOption = true;
  }

  /// Adds flags for using a specific filesystem root and scheme.
  ///
  /// [hide] indicates whether or not to hide these options when the user asks
  /// for help.
  void usesFilesystemOptions({ @required bool hide }) {
    argParser
      ..addOption('output-dill',
        hide: hide,
        help: 'Specify the path to frontend server output kernel file.',
      )
      ..addMultiOption(FlutterOptions.kFileSystemRoot,
        hide: hide,
        help: 'Specify the path, that is used as root in a virtual file system\n'
            'for compilation. Input file name should be specified as Uri in\n'
            'filesystem-scheme scheme. Use only in Dart 2 mode.\n'
            'Requires --output-dill option to be explicitly specified.\n',
      )
      ..addOption(FlutterOptions.kFileSystemScheme,
        defaultsTo: 'org-dartlang-root',
        hide: hide,
        help: 'Specify the scheme that is used for virtual file system used in\n'
            'compilation. See more details on filesystem-root option.\n',
      );
  }

  /// Adds options for connecting to the Dart VM observatory port.
  void usesPortOptions() {
    argParser.addOption(observatoryPortOption,
        help: '(deprecated use host-vmservice-port instead) '
              'Listen to the given port for an observatory debugger connection.\n'
              'Specifying port 0 (the default) will find a random free port.',
    );
    argParser.addOption('device-vmservice-port',
      help: 'Look for vmservice connections only from the specified port.\n'
            'Specifying port 0 (the default) will accept the first vmservice '
            'discovered.',
    );
    argParser.addOption('host-vmservice-port',
      help: 'When a device-side vmservice port is forwarded to a host-side '
            'port, use this value as the host port.\nSpecifying port 0 '
            '(the default) will find a random free host port.'
    );
    _usesPortOption = true;
  }

  /// Gets the vmservice port provided to in the 'observatory-port' or
  /// 'host-vmservice-port option.
  ///
  /// Only one of "host-vmservice-port" and "observatory-port" may be
  /// specified.
  ///
  /// If no port is set, returns null.
  int get hostVmservicePort {
    if (!_usesPortOption ||
        (argResults['observatory-port'] == null &&
      argResults['host-vmservice-port'] == null)) {
      return null;
    }
    if (argResults.wasParsed('observatory-port') &&
        argResults.wasParsed('host-vmservice-port')) {
      throwToolExit('Only one of "--observatory-port" and '
        '"--host-vmservice-port" may be specified.');
    }
    try {
      return int.parse(stringArg('observatory-port') ?? stringArg('host-vmservice-port'));
    } on FormatException catch (error) {
      throwToolExit('Invalid port for `--observatory-port/--host-vmservice-port`: $error');
    }
    return null;
  }

  /// Gets the vmservice port provided to in the 'device-vmservice-port' option.
  ///
  /// If no port is set, returns null.
  int get deviceVmservicePort {
    if (!_usesPortOption || argResults['device-vmservice-port'] == null) {
      return null;
    }
    try {
      return int.parse(stringArg('device-vmservice-port'));
    } on FormatException catch (error) {
      throwToolExit('Invalid port for `--device-vmservice-port`: $error');
    }
    return null;
  }

  void usesIpv6Flag() {
    argParser.addFlag(ipv6Flag,
      hide: true,
      negatable: false,
      help: 'Binds to IPv6 localhost instead of IPv4 when the flutter tool '
            'forwards the host port to a device port. Not used when the '
            '--debug-port flag is not set.',
    );
    _usesIpv6Flag = true;
  }

  bool get ipv6 => _usesIpv6Flag ? boolArg('ipv6') : null;

  void usesBuildNumberOption() {
    argParser.addOption('build-number',
        help: 'An identifier used as an internal version number.\n'
              'Each build must have a unique identifier to differentiate it from previous builds.\n'
              'It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.\n'
              'On Android it is used as \'versionCode\'.\n'
              'On Xcode builds it is used as \'CFBundleVersion\'',
    );
  }

  void usesBuildNameOption() {
    argParser.addOption('build-name',
        help: 'A "x.y.z" string used as the version number shown to users.\n'
              'For each new version of your app, you will provide a version number to differentiate it from previous versions.\n'
              'On Android it is used as \'versionName\'.\n'
              'On Xcode builds it is used as \'CFBundleShortVersionString\'',
        valueHelp: 'x.y.z');
  }

  void usesDartDefines() {
    argParser.addMultiOption(
      'dart-define',
      help: 'Passed to the Dart compiler building this application as a -D flag.\n'
            'Values supported by this option are compiler implementation specific.\n'
            'Multiple defines can be passed by repeating --dart-define multiple times.',
      valueHelp: 'FOO=bar',
      hide: true,
    );
  }

  /// The values passed via the `--dart-define` option.
  List<String> get dartDefines => stringsArg('dart-define');

  void usesIsolateFilterOption({ @required bool hide }) {
    argParser.addOption('isolate-filter',
      defaultsTo: null,
      hide: hide,
      help: 'Restricts commands to a subset of the available isolates (running instances of Flutter).\n'
            'Normally there\'s only one, but when adding Flutter to a pre-existing app it\'s possible to create multiple.');
  }

  void addBuildModeFlags({ bool defaultToRelease = true, bool verboseHelp = false, bool excludeDebug = false }) {
    // A release build must be the default if a debug build is not possible.
    assert(defaultToRelease || !excludeDebug);
    _excludeDebug = excludeDebug;
    defaultBuildMode = defaultToRelease ? BuildMode.release : BuildMode.debug;

    if (!excludeDebug) {
      argParser.addFlag('debug',
        negatable: false,
        help: 'Build a debug version of your app${defaultToRelease ? '' : ' (default mode)'}.');
    }
    argParser.addFlag('profile',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.');
    argParser.addFlag('release',
      negatable: false,
      help: 'Build a release version of your app${defaultToRelease ? ' (default mode)' : ''}.');
    argParser.addFlag('jit-release',
      negatable: false,
      hide: !verboseHelp,
      help: 'Build a JIT release version of your app${defaultToRelease ? ' (default mode)' : ''}.');
  }

  void addTreeShakeIconsFlag() {
    argParser.addFlag('tree-shake-icons',
      negatable: true,
      defaultsTo: kIconTreeShakerEnabledDefault,
      help: 'Tree shake icon fonts so that only glyphs used by the application remain.',
    );
  }

  void addShrinkingFlag() {
    argParser.addFlag('shrink',
      negatable: true,
      defaultsTo: true,
      help: 'Whether to enable code shrinking on release mode. '
            'When enabling shrinking, you also benefit from obfuscation, '
            'which shortens the names of your app’s classes and members, '
            'and optimization, which applies more aggressive strategies to '
            'further reduce the size of your app. '
            'To learn more, see: https://developer.android.com/studio/build/shrink-code',
      );
  }

  void usesFuchsiaOptions({ bool hide = false }) {
    argParser.addOption(
      'target-model',
      help: 'Target model that determines what core libraries are available',
      defaultsTo: 'flutter',
      hide: hide,
      allowed: const <String>['flutter', 'flutter_runner'],
    );
    argParser.addOption(
      'module',
      abbr: 'm',
      hide: hide,
      help: 'The name of the module (required if attaching to a fuchsia device)',
      valueHelp: 'module-name',
    );
  }

  set defaultBuildMode(BuildMode value) {
    _defaultBuildMode = value;
  }

  BuildMode getBuildMode() {
    // No debug when _excludeDebug is true.
    // If debug is not excluded, then take the command line flag.
    final bool debugResult = !_excludeDebug && boolArg('debug');
    final List<bool> modeFlags = <bool>[
      debugResult,
      boolArg('jit-release'),
      boolArg('profile'),
      boolArg('release'),
    ];
    if (modeFlags.where((bool flag) => flag).length > 1) {
      throw UsageException('Only one of --debug, --profile, --jit-release, '
                           'or --release can be specified.', null);
    }
    if (debugResult) {
      return BuildMode.debug;
    }
    if (boolArg('profile')) {
      return BuildMode.profile;
    }
    if (boolArg('release')) {
      return BuildMode.release;
    }
    if (boolArg('jit-release')) {
      return BuildMode.jitRelease;
    }
    return _defaultBuildMode;
  }

  void usesFlavorOption() {
    argParser.addOption(
      'flavor',
      help: 'Build a custom app flavor as defined by platform-specific build setup.\n'
            'Supports the use of product flavors in Android Gradle scripts, and '
            'the use of custom Xcode schemes.',
    );
  }

  void usesTrackWidgetCreation({ bool hasEffect = true, @required bool verboseHelp }) {
    argParser.addFlag(
      'track-widget-creation',
      hide: !hasEffect && !verboseHelp,
      defaultsTo: true,
      help: 'Track widget creation locations. This enables features such as the widget inspector. '
            'This parameter is only functional in debug mode (i.e. when compiling JIT, not AOT).',
    );
  }

  BuildInfo getBuildInfo() {
    final bool trackWidgetCreation = argParser.options.containsKey('track-widget-creation') &&
      boolArg('track-widget-creation');

    final String buildNumber = argParser.options.containsKey('build-number')
        ? stringArg('build-number')
        : null;

    String extraFrontEndOptions =
        argParser.options.containsKey(FlutterOptions.kExtraFrontEndOptions)
            ? stringArg(FlutterOptions.kExtraFrontEndOptions)
            : null;
    if (argParser.options.containsKey(FlutterOptions.kEnableExperiment) &&
        argResults[FlutterOptions.kEnableExperiment] != null) {
      for (final String expFlag in stringsArg(FlutterOptions.kEnableExperiment)) {
        final String flag = '--enable-experiment=' + expFlag;
        if (extraFrontEndOptions != null) {
          extraFrontEndOptions += ',' + flag;
        } else {
          extraFrontEndOptions = flag;
        }
      }
    }

    return BuildInfo(getBuildMode(),
      argParser.options.containsKey('flavor')
        ? stringArg('flavor')
        : null,
      trackWidgetCreation: trackWidgetCreation,
      extraFrontEndOptions: extraFrontEndOptions,
      extraGenSnapshotOptions: argParser.options.containsKey(FlutterOptions.kExtraGenSnapshotOptions)
          ? stringArg(FlutterOptions.kExtraGenSnapshotOptions)
          : null,
      fileSystemRoots: argParser.options.containsKey(FlutterOptions.kFileSystemRoot)
          ? stringsArg(FlutterOptions.kFileSystemRoot)
          : null,
      fileSystemScheme: argParser.options.containsKey(FlutterOptions.kFileSystemScheme)
          ? stringArg(FlutterOptions.kFileSystemScheme)
          : null,
      buildNumber: buildNumber,
      buildName: argParser.options.containsKey('build-name')
          ? stringArg('build-name')
          : null,
      treeShakeIcons: argParser.options.containsKey('tree-shake-icons')
          ? boolArg('tree-shake-icons')
          : kIconTreeShakerEnabledDefault,
    );
  }

  void setupApplicationPackages() {
    applicationPackages ??= ApplicationPackageStore();
  }

  /// The path to send to Google Analytics. Return null here to disable
  /// tracking of the command.
  Future<String> get usagePath async {
    if (parent is FlutterCommand) {
      final FlutterCommand commandParent = parent as FlutterCommand;
      final String path = await commandParent.usagePath;
      // Don't report for parents that return null for usagePath.
      return path == null ? null : '$path/$name';
    } else {
      return name;
    }
  }

  /// Additional usage values to be sent with the usage ping.
  Future<Map<CustomDimensions, String>> get usageValues async =>
      const <CustomDimensions, String>{};

  /// Runs this command.
  ///
  /// Rather than overriding this method, subclasses should override
  /// [verifyThenRunCommand] to perform any verification
  /// and [runCommand] to execute the command
  /// so that this method can record and report the overall time to analytics.
  @override
  Future<void> run() {
    final DateTime startTime = systemClock.now();

    return context.run<void>(
      name: 'command',
      overrides: <Type, Generator>{FlutterCommand: () => this},
      body: () async {
        // Prints the welcome message if needed.
        flutterUsage.printWelcome();
        final String commandPath = await usagePath;
        _registerSignalHandlers(commandPath, startTime);
        FlutterCommandResult commandResult = FlutterCommandResult.fail();
        try {
          commandResult = await verifyThenRunCommand(commandPath);
        } finally {
          final DateTime endTime = systemClock.now();
          globals.printTrace(userMessages.flutterElapsedTime(name, getElapsedAsMilliseconds(endTime.difference(startTime))));
          _sendPostUsage(commandPath, commandResult, startTime, endTime);
        }
      },
    );
  }

  void _registerSignalHandlers(String commandPath, DateTime startTime) {
    final SignalHandler handler = (io.ProcessSignal s) {
      _sendPostUsage(
        commandPath,
        const FlutterCommandResult(ExitStatus.killed),
        startTime,
        systemClock.now(),
      );
    };
    signals.addHandler(io.ProcessSignal.SIGTERM, handler);
    signals.addHandler(io.ProcessSignal.SIGINT, handler);
  }

  /// Logs data about this command.
  ///
  /// For example, the command path (e.g. `build/apk`) and the result,
  /// as well as the time spent running it.
  void _sendPostUsage(
    String commandPath,
    FlutterCommandResult commandResult,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (commandPath == null) {
      return;
    }
    assert(commandResult != null);
    // Send command result.
    CommandResultEvent(commandPath, commandResult).send();

    // Send timing.
    final List<String> labels = <String>[
      if (commandResult.exitStatus != null)
        getEnumName(commandResult.exitStatus),
      if (commandResult.timingLabelParts?.isNotEmpty ?? false)
        ...commandResult.timingLabelParts,
    ];

    final String label = labels
        .where((String label) => !isBlank(label))
        .join('-');
    flutterUsage.sendTiming(
      'flutter',
      name,
      // If the command provides its own end time, use it. Otherwise report
      // the duration of the entire execution.
      (commandResult.endTimeOverride ?? endTime).difference(startTime),
      // Report in the form of `success-[parameter1-parameter2]`, all of which
      // can be null if the command doesn't provide a FlutterCommandResult.
      label: label == '' ? null : label,
    );
  }

  /// Perform validation then call [runCommand] to execute the command.
  /// Return a [Future] that completes with an exit code
  /// indicating whether execution was successful.
  ///
  /// Subclasses should override this method to perform verification
  /// then call this method to execute the command
  /// rather than calling [runCommand] directly.
  @mustCallSuper
  Future<FlutterCommandResult> verifyThenRunCommand(String commandPath) async {
    // Populate the cache. We call this before pub get below so that the
    // sky_engine package is available in the flutter cache for pub to find.
    if (shouldUpdateCache) {
      // First always update universal artifacts, as some of these (e.g.
      // idevice_id on macOS) are required to determine `requiredArtifacts`.
      await globals.cache.updateAll(<DevelopmentArtifact>{DevelopmentArtifact.universal});

      await globals.cache.updateAll(await requiredArtifacts);
    }

    await validateCommand();

    if (shouldRunPub) {
      await pub.get(context: PubContext.getVerifyContext(name));
      final FlutterProject project = FlutterProject.current();
      await project.ensureReadyForPlatformSpecificTooling(checkProjects: true);
    }

    setupApplicationPackages();

    if (commandPath != null) {
      final Map<CustomDimensions, String> additionalUsageValues =
        <CustomDimensions, String>{
          ...?await usageValues,
          CustomDimensions.commandHasTerminal:
            globals.stdio.hasTerminal ? 'true' : 'false',
        };
      Usage.command(commandPath, parameters: additionalUsageValues);
    }

    return await runCommand();
  }

  /// The set of development artifacts required for this command.
  ///
  /// Defaults to an empty set. Including [DevelopmentArtifact.universal] is
  /// not required as it is always updated.
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  /// Subclasses must implement this to execute the command.
  /// Optionally provide a [FlutterCommandResult] to send more details about the
  /// execution for analytics.
  Future<FlutterCommandResult> runCommand();

  /// Find and return all target [Device]s based upon currently connected
  /// devices and criteria entered by the user on the command line.
  /// If no device can be found that meets specified criteria,
  /// then print an error message and return null.
  Future<List<Device>> findAllTargetDevices() async {
    if (!doctor.canLaunchAnything) {
      globals.printError(userMessages.flutterNoDevelopmentDevice);
      return null;
    }

    List<Device> devices = await deviceManager.findTargetDevices(FlutterProject.current());

    if (devices.isEmpty && deviceManager.hasSpecifiedDeviceId) {
      globals.printStatus(userMessages.flutterNoMatchingDevice(deviceManager.specifiedDeviceId));
      return null;
    } else if (devices.isEmpty && deviceManager.hasSpecifiedAllDevices) {
      globals.printStatus(userMessages.flutterNoDevicesFound);
      return null;
    } else if (devices.isEmpty) {
      globals.printStatus(userMessages.flutterNoSupportedDevices);
      return null;
    } else if (devices.length > 1 && !deviceManager.hasSpecifiedAllDevices) {
      if (deviceManager.hasSpecifiedDeviceId) {
       globals.printStatus(userMessages.flutterFoundSpecifiedDevices(devices.length, deviceManager.specifiedDeviceId));
      } else {
        globals.printStatus(userMessages.flutterSpecifyDeviceWithAllOption);
        devices = await deviceManager.getAllConnectedDevices().toList();
      }
      globals.printStatus('');
      await Device.printDevices(devices);
      return null;
    }
    return devices;
  }

  /// Find and return the target [Device] based upon currently connected
  /// devices and criteria entered by the user on the command line.
  /// If a device cannot be found that meets specified criteria,
  /// then print an error message and return null.
  Future<Device> findTargetDevice() async {
    List<Device> deviceList = await findAllTargetDevices();
    if (deviceList == null) {
      return null;
    }
    if (deviceList.length > 1) {
      globals.printStatus(userMessages.flutterSpecifyDevice);
      deviceList = await deviceManager.getAllConnectedDevices().toList();
      globals.printStatus('');
      await Device.printDevices(deviceList);
      return null;
    }
    return deviceList.single;
  }

  @protected
  @mustCallSuper
  Future<void> validateCommand() async {
    if (_requiresPubspecYaml && !PackageMap.isUsingCustomPackagesPath) {
      // Don't expect a pubspec.yaml file if the user passed in an explicit .packages file path.

      // If there is no pubspec in the current directory, look in the parent
      // until one can be found.
      bool changedDirectory = false;
      while (!globals.fs.isFileSync('pubspec.yaml')) {
        final Directory nextCurrent = globals.fs.currentDirectory.parent;
        if (nextCurrent == null || nextCurrent.path == globals.fs.currentDirectory.path) {
          throw ToolExit(userMessages.flutterNoPubspec);
        }
        globals.fs.currentDirectory = nextCurrent;
        changedDirectory = true;
      }
      if (changedDirectory) {
        globals.printStatus('Changing current working directory to: ${globals.fs.currentDirectory.path}');
      }

      // Validate the current package map only if we will not be running "pub get" later.
      if (parent?.name != 'pub' && !(_usesPubOption && boolArg('pub'))) {
        final String error = PackageMap(PackageMap.globalPackagesPath).checkValid();
        if (error != null) {
          throw ToolExit(error);
        }
      }
    }

    if (_usesTargetOption) {
      final String targetPath = targetFile;
      if (!globals.fs.isFileSync(targetPath)) {
        throw ToolExit(userMessages.flutterTargetFileMissing(targetPath));
      }
    }
  }

  ApplicationPackageStore applicationPackages;

  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => argResults[name] as bool;

  /// Gets the parsed command-line option named [name] as `String`.
  String stringArg(String name) => argResults[name] as String;

  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String> stringsArg(String name) => argResults[name] as List<String>;
}

/// A mixin which applies an implementation of [requiredArtifacts] that only
/// downloads artifacts corresponding to an attached device.
mixin DeviceBasedDevelopmentArtifacts on FlutterCommand {
  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    // If there are no attached devices, use the default configuration.
    // Otherwise, only add development artifacts which correspond to a
    // connected device.
    final List<Device> devices = await deviceManager.getDevices().toList();
    if (devices.isEmpty) {
      return super.requiredArtifacts;
    }
    final Set<DevelopmentArtifact> artifacts = <DevelopmentArtifact>{
      DevelopmentArtifact.universal,
    };
    for (final Device device in devices) {
      final TargetPlatform targetPlatform = await device.targetPlatform;
      final DevelopmentArtifact developmentArtifact = _artifactFromTargetPlatform(targetPlatform);
      if (developmentArtifact != null) {
        artifacts.add(developmentArtifact);
      }
    }
    return artifacts;
  }
}

/// A mixin which applies an implementation of [requiredArtifacts] that only
/// downloads artifacts corresponding to a target device.
mixin TargetPlatformBasedDevelopmentArtifacts on FlutterCommand {
  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    // If there is no specified target device, fallback to the default
    // confiugration.
    final String rawTargetPlatform = stringArg('target-platform');
    final TargetPlatform targetPlatform = getTargetPlatformForName(rawTargetPlatform);
    if (targetPlatform == null) {
      return super.requiredArtifacts;
    }

    final Set<DevelopmentArtifact> artifacts = <DevelopmentArtifact>{};
    final DevelopmentArtifact developmentArtifact = _artifactFromTargetPlatform(targetPlatform);
    if (developmentArtifact != null) {
      artifacts.add(developmentArtifact);
    }
    return artifacts;
  }
}

// Returns the development artifact for the target platform, or null
// if none is supported
DevelopmentArtifact _artifactFromTargetPlatform(TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      return DevelopmentArtifact.androidGenSnapshot;
    case TargetPlatform.web_javascript:
      return DevelopmentArtifact.web;
    case TargetPlatform.ios:
      return DevelopmentArtifact.iOS;
    case TargetPlatform.darwin_x64:
      if (featureFlags.isMacOSEnabled) {
        return DevelopmentArtifact.macOS;
      }
      return null;
    case TargetPlatform.windows_x64:
      if (featureFlags.isWindowsEnabled) {
        return DevelopmentArtifact.windows;
      }
      return null;
    case TargetPlatform.linux_x64:
      if (featureFlags.isLinuxEnabled) {
        return DevelopmentArtifact.linux;
      }
      return null;
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.tester:
      // No artifacts currently supported.
      return null;
  }
  return null;
}

/// A command which runs less analytics and checks to speed up startup time.
abstract class FastFlutterCommand extends FlutterCommand {
  @override
  Future<void> run() {
    return context.run<void>(
      name: 'command',
      overrides: <Type, Generator>{FlutterCommand: () => this},
      body: runCommand,
    );
  }
}
