// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:quiver/strings.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/time.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../bundle.dart' as bundle;
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../doctor.dart';
import '../globals.dart';
import '../project.dart';
import '../usage.dart';
import 'flutter_command_runner.dart';

enum ExitStatus {
  success,
  warning,
  fail,
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
}

/// Common flutter command line options.
class FlutterOptions {
  static const String kExtraFrontEndOptions = 'extra-front-end-options';
  static const String kExtraGenSnapshotOptions = 'extra-gen-snapshot-options';
  static const String kFileSystemRoot = 'filesystem-root';
  static const String kFileSystemScheme = 'filesystem-scheme';
}

abstract class FlutterCommand extends Command<void> {
  /// The currently executing command (or sub-command).
  ///
  /// Will be `null` until the top-most command has begun execution.
  static FlutterCommand get current => context[FlutterCommand];

  @override
  ArgParser get argParser => _argParser;
  final ArgParser _argParser = ArgParser(allowTrailingOptions: false);

  @override
  FlutterCommandRunner get runner => super.runner;

  bool _requiresPubspecYaml = false;

  /// Whether this command uses the 'target' option.
  bool _usesTargetOption = false;

  bool _usesPubOption = false;

  bool get shouldRunPub => _usesPubOption && argResults['pub'];

  bool get shouldUpdateCache => true;

  BuildMode _defaultBuildMode;

  void requiresPubspecYaml() {
    _requiresPubspecYaml = true;
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
    if (argResults.wasParsed('target'))
      return argResults['target'];
    else if (argResults.rest.isNotEmpty)
      return argResults.rest.first;
    else
      return bundle.defaultMainPath;
  }

  void usesPubOption() {
    argParser.addFlag('pub',
      defaultsTo: true,
      help: 'Whether to run "flutter packages get" before executing this command.');
    _usesPubOption = true;
  }

  /// Adds flags for using a specific filesystem root and scheme.
  ///
  /// [hide] indicates whether or not to hide these options when the user asks
  /// for help.
  void usesFilesystemOptions({@required bool hide}) {
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

  void usesBuildNumberOption() {
    argParser.addOption('build-number',
        help: 'An integer used as an internal version number.\n'
              'Each build must have a unique number to differentiate it from previous builds.\n'
              'It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.\n'
              'On Android it is used as \'versionCode\'.\n'
              'On Xcode builds it is used as \'CFBundleVersion\'',
        valueHelp: 'int');
  }

  void usesBuildNameOption() {
    argParser.addOption('build-name',
        help: 'A "x.y.z" string used as the version number shown to users.\n'
              'For each new version of your app, you will provide a version number to differentiate it from previous versions.\n'
              'On Android it is used as \'versionName\'.\n'
              'On Xcode builds it is used as \'CFBundleShortVersionString\'',
        valueHelp: 'x.y.z');
  }

  void usesIsolateFilterOption({@required bool hide}) {
    argParser.addOption('isolate-filter',
      defaultsTo: null,
      hide: hide,
      help: 'Restricts commands to a subset of the available isolates (running instances of Flutter).\n'
            'Normally there\'s only one, but when adding Flutter to a pre-existing app it\'s possible to create multiple.');
  }

  void addBuildModeFlags({bool defaultToRelease = true, bool verboseHelp = false}) {
    defaultBuildMode = defaultToRelease ? BuildMode.release : BuildMode.debug;

    argParser.addFlag('debug',
      negatable: false,
      help: 'Build a debug version of your app${defaultToRelease ? '' : ' (default mode)'}.');
    argParser.addFlag('profile',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.');
    argParser.addFlag('release',
      negatable: false,
      help: 'Build a release version of your app${defaultToRelease ? ' (default mode)' : ''}.');
    argParser.addFlag('dynamic',
      hide: !verboseHelp,
      negatable: false,
      help: 'Enable dynamic code. This flag is intended for use with\n'
            '--release or --profile; --debug always has this enabled.');
  }

  void usesFuchsiaOptions({bool hide = false}) {
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
    final List<bool> modeFlags = <bool>[argResults['debug'], argResults['profile'], argResults['release']];
    if (modeFlags.where((bool flag) => flag).length > 1)
      throw UsageException('Only one of --debug, --profile, or --release can be specified.', null);
    final bool dynamicFlag = argParser.options.containsKey('dynamic')
        ? argResults['dynamic']
        : false;
    if (argResults['debug'])
      return BuildMode.debug;
    if (argResults['profile'])
      return dynamicFlag ? BuildMode.dynamicProfile : BuildMode.profile;
    if (argResults['release'])
      return dynamicFlag ? BuildMode.dynamicRelease : BuildMode.release;
    return _defaultBuildMode;
  }

  void usesFlavorOption() {
    argParser.addOption(
      'flavor',
      help: 'Build a custom app flavor as defined by platform-specific build setup.\n'
        'Supports the use of product flavors in Android Gradle scripts.\n'
        'Supports the use of custom Xcode schemes.'
    );
  }

  BuildInfo getBuildInfo() {
    TargetPlatform targetPlatform;
    if (argParser.options.containsKey('target-platform') &&
        argResults['target-platform'] != 'default') {
      targetPlatform = getTargetPlatformForName(argResults['target-platform']);
    }

    final bool trackWidgetCreation = argParser.options.containsKey('track-widget-creation')
        ? argResults['track-widget-creation']
        : false;

    int buildNumber;
    try {
      buildNumber = argParser.options.containsKey('build-number') && argResults['build-number'] != null
          ? int.parse(argResults['build-number'])
          : null;
    } catch (e) {
      throw UsageException(
          '--build-number (${argResults['build-number']}) must be an int.', null);
    }

    return BuildInfo(getBuildMode(),
      argParser.options.containsKey('flavor')
        ? argResults['flavor']
        : null,
      trackWidgetCreation: trackWidgetCreation,
      compilationTraceFilePath: argParser.options.containsKey('precompile')
          ? argResults['precompile']
          : null,
      buildHotUpdate: argParser.options.containsKey('hotupdate')
          ? argResults['hotupdate']
          : false,
      extraFrontEndOptions: argParser.options.containsKey(FlutterOptions.kExtraFrontEndOptions)
          ? argResults[FlutterOptions.kExtraFrontEndOptions]
          : null,
      extraGenSnapshotOptions: argParser.options.containsKey(FlutterOptions.kExtraGenSnapshotOptions)
          ? argResults[FlutterOptions.kExtraGenSnapshotOptions]
          : null,
      buildSharedLibrary: argParser.options.containsKey('build-shared-library')
        ? argResults['build-shared-library']
        : false,
      targetPlatform: targetPlatform,
      fileSystemRoots: argParser.options.containsKey(FlutterOptions.kFileSystemRoot)
          ? argResults[FlutterOptions.kFileSystemRoot] : null,
      fileSystemScheme: argParser.options.containsKey(FlutterOptions.kFileSystemScheme)
          ? argResults[FlutterOptions.kFileSystemScheme] : null,
      buildNumber: buildNumber,
      buildName: argParser.options.containsKey('build-name')
          ? argResults['build-name']
          : null,
    );
  }

  void setupApplicationPackages() {
    applicationPackages ??= ApplicationPackageStore();
  }

  /// The path to send to Google Analytics. Return null here to disable
  /// tracking of the command.
  Future<String> get usagePath async {
    if (parent is FlutterCommand) {
      final FlutterCommand commandParent = parent;
      final String path = await commandParent.usagePath;
      // Don't report for parents that return null for usagePath.
      return path == null ? null : '$path/$name';
    } else {
      return name;
    }
  }

  /// Additional usage values to be sent with the usage ping.
  Future<Map<String, String>> get usageValues async => const <String, String>{};

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
        if (flutterUsage.isFirstRun)
          flutterUsage.printWelcome();

        FlutterCommandResult commandResult;
        try {
          commandResult = await verifyThenRunCommand();
        } on ToolExit {
          commandResult = const FlutterCommandResult(ExitStatus.fail);
          rethrow;
        } finally {
          final DateTime endTime = systemClock.now();
          printTrace('"flutter $name" took ${getElapsedAsMilliseconds(endTime.difference(startTime))}.');
          // This is checking the result of the call to 'usagePath'
          // (a Future<String>), and not the result of evaluating the Future.
          if (usagePath != null) {
            final List<String> labels = <String>[];
            if (commandResult?.exitStatus != null)
              labels.add(getEnumName(commandResult.exitStatus));
            if (commandResult?.timingLabelParts?.isNotEmpty ?? false)
              labels.addAll(commandResult.timingLabelParts);

            final String label = labels
                .where((String label) => !isBlank(label))
                .join('-');
            flutterUsage.sendTiming(
              'flutter',
              name,
              // If the command provides its own end time, use it. Otherwise report
              // the duration of the entire execution.
              (commandResult?.endTimeOverride ?? endTime).difference(startTime),
              // Report in the form of `success-[parameter1-parameter2]`, all of which
              // can be null if the command doesn't provide a FlutterCommandResult.
              label: label == '' ? null : label,
            );
          }
        }
      },
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
  Future<FlutterCommandResult> verifyThenRunCommand() async {
    await validateCommand();

    // Populate the cache. We call this before pub get below so that the sky_engine
    // package is available in the flutter cache for pub to find.
    if (shouldUpdateCache)
      await cache.updateAll();

    if (shouldRunPub) {
      await pubGet(context: PubContext.getVerifyContext(name));
      final FlutterProject project = await FlutterProject.current();
      await project.ensureReadyForPlatformSpecificTooling();
    }

    setupApplicationPackages();

    final String commandPath = await usagePath;

    if (commandPath != null) {
      final Map<String, String> additionalUsageValues = await usageValues;
      flutterUsage.sendCommand(commandPath, parameters: additionalUsageValues);
    }

    return await runCommand();
  }

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
      printError("Unable to locate a development device; please run 'flutter doctor' "
          'for information about installing additional components.');
      return null;
    }

    List<Device> devices = await deviceManager.getDevices().toList();

    if (devices.isEmpty && deviceManager.hasSpecifiedDeviceId) {
      printStatus('No devices found with name or id '
          "matching '${deviceManager.specifiedDeviceId}'");
      return null;
    } else if (devices.isEmpty && deviceManager.hasSpecifiedAllDevices) {
      printStatus('No devices found');
      return null;
    } else if (devices.isEmpty) {
      printNoConnectedDevices();
      return null;
    }

    devices = devices.where((Device device) => device.isSupported()).toList();

    if (devices.isEmpty) {
      printStatus('No supported devices connected.');
      return null;
    } else if (devices.length > 1 && !deviceManager.hasSpecifiedAllDevices) {
      if (deviceManager.hasSpecifiedDeviceId) {
        printStatus('Found ${devices.length} devices with name or id matching '
            "'${deviceManager.specifiedDeviceId}':");
      } else {
        printStatus('More than one device connected; please specify a device with '
            "the '-d <deviceId>' flag, or use '-d all' to act on all devices.");
        devices = await deviceManager.getAllConnectedDevices().toList();
      }
      printStatus('');
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
    if (deviceList == null)
      return null;
    if (deviceList.length > 1) {
      printStatus('More than one device connected; please specify a device with '
        "the '-d <deviceId>' flag.");
      deviceList = await deviceManager.getAllConnectedDevices().toList();
      printStatus('');
      await Device.printDevices(deviceList);
      return null;
    }
    return deviceList.single;
  }

  void printNoConnectedDevices() {
    printStatus('No connected devices.');
  }

  @protected
  @mustCallSuper
  Future<void> validateCommand() async {
    if (_requiresPubspecYaml && !PackageMap.isUsingCustomPackagesPath) {
      // Don't expect a pubspec.yaml file if the user passed in an explicit .packages file path.
      if (!fs.isFileSync('pubspec.yaml')) {
        throw ToolExit(
          'Error: No pubspec.yaml file found.\n'
          'This command should be run from the root of your Flutter project.\n'
          'Do not run this command from the root of your git clone of Flutter.'
        );
      }

      if (fs.isFileSync('flutter.yaml')) {
        throw ToolExit(
          'Please merge your flutter.yaml into your pubspec.yaml.\n\n'
          'We have changed from having separate flutter.yaml and pubspec.yaml\n'
          'files to having just one pubspec.yaml file. Transitioning is simple:\n'
          'add a line that just says "flutter:" to your pubspec.yaml file, and\n'
          'move everything from your current flutter.yaml file into the\n'
          'pubspec.yaml file, below that line, with everything indented by two\n'
          'extra spaces compared to how it was in the flutter.yaml file. Then, if\n'
          'you had a "name:" line, move that to the top of your "pubspec.yaml"\n'
          'file (you may already have one there), so that there is only one\n'
          '"name:" line. Finally, delete the flutter.yaml file.\n\n'
          'For an example of what a new-style pubspec.yaml file might look like,\n'
          'check out the Flutter Gallery pubspec.yaml:\n'
          'https://github.com/flutter/flutter/blob/master/examples/flutter_gallery/pubspec.yaml\n'
        );
      }

      // Validate the current package map only if we will not be running "pub get" later.
      if (parent?.name != 'packages' && !(_usesPubOption && argResults['pub'])) {
        final String error = PackageMap(PackageMap.globalPackagesPath).checkValid();
        if (error != null)
          throw ToolExit(error);
      }
    }

    if (_usesTargetOption) {
      final String targetPath = targetFile;
      if (!fs.isFileSync(targetPath))
        throw ToolExit('Target file "$targetPath" not found.');
    }

    final bool dynamicFlag = argParser.options.containsKey('dynamic')
        ? argResults['dynamic'] : false;
    final String compilationTraceFilePath = argParser.options.containsKey('precompile')
        ? argResults['precompile'] : null;
    final bool buildHotUpdate = argParser.options.containsKey('hotupdate')
        ? argResults['hotupdate'] : false;

    if (compilationTraceFilePath != null && getBuildMode() == BuildMode.debug)
      throw ToolExit('Error: --precompile is not allowed when --debug is specified.');
    if (compilationTraceFilePath != null && !dynamicFlag)
      throw ToolExit('Error: --precompile is allowed only when --dynamic is specified.');
    if (buildHotUpdate && compilationTraceFilePath == null)
      throw ToolExit('Error: --hotupdate is allowed only when --precompile is specified.');
  }

  ApplicationPackageStore applicationPackages;
}
