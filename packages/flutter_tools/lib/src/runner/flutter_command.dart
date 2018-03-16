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
import '../base/utils.dart';
import '../build_info.dart';
import '../dart/package_map.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../doctor.dart';
import '../flx.dart' as flx;
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
}

abstract class FlutterCommand extends Command<Null> {
  /// The currently executing command (or sub-command).
  ///
  /// Will be `null` until the top-most command has begun execution.
  static FlutterCommand get current => context[FlutterCommand];

  @override
  ArgParser get argParser => _argParser;
  final ArgParser _argParser = new ArgParser(allowTrailingOptions: false);

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
      defaultsTo: flx.defaultMainPath,
      help: 'The main entry-point file of the application, as run on the device.\n'
            'If the --target option is omitted, but a file name is provided on\n'
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
      return flx.defaultMainPath;
  }

  void usesPubOption() {
    argParser.addFlag('pub',
      defaultsTo: true,
      help: 'Whether to run "flutter packages get" before executing this command.');
    _usesPubOption = true;
  }

  void addBuildModeFlags({ bool defaultToRelease: true }) {
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
  }

  set defaultBuildMode(BuildMode value) {
    _defaultBuildMode = value;
  }

  BuildMode getBuildMode() {
    final List<bool> modeFlags = <bool>[argResults['debug'], argResults['profile'], argResults['release']];
    if (modeFlags.where((bool flag) => flag).length > 1)
      throw new UsageException('Only one of --debug, --profile, or --release can be specified.', null);
    if (argResults['debug'])
      return BuildMode.debug;
    if (argResults['profile'])
      return BuildMode.profile;
    if (argResults['release'])
      return BuildMode.release;
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
    final bool previewDart2 = argParser.options.containsKey('preview-dart-2')
        ? argResults['preview-dart-2']
        : false;

    TargetPlatform targetPlatform;
    if (argParser.options.containsKey('target-platform') &&
        argResults['target-platform'] != 'default') {
      targetPlatform = getTargetPlatformForName(argResults['target-platform']);
    }

    final bool trackWidgetCreation = argParser.options.containsKey('track-widget-creation')
        ? argResults['track-widget-creation']
        : false;
    if (trackWidgetCreation == true && previewDart2 == false) {
      throw new UsageException(
          '--track-widget-creation is valid only when --preview-dart-2 is specified.', null);
    }

    return new BuildInfo(getBuildMode(),
      argParser.options.containsKey('flavor')
        ? argResults['flavor']
        : null,
      previewDart2: previewDart2,
      trackWidgetCreation: trackWidgetCreation,
      extraFrontEndOptions: argParser.options.containsKey(FlutterOptions.kExtraFrontEndOptions)
          ? argResults[FlutterOptions.kExtraFrontEndOptions]
          : null,
      extraGenSnapshotOptions: argParser.options.containsKey(FlutterOptions.kExtraGenSnapshotOptions)
          ? argResults[FlutterOptions.kExtraGenSnapshotOptions]
          : null,
      preferSharedLibrary: argParser.options.containsKey('prefer-shared-library')
        ? argResults['prefer-shared-library']
        : false,
      targetPlatform: targetPlatform);
  }

  void setupApplicationPackages() {
    applicationPackages ??= new ApplicationPackageStore();
  }

  /// The path to send to Google Analytics. Return null here to disable
  /// tracking of the command.
  Future<String> get usagePath async => name;

  /// Additional usage values to be sent with the usage ping.
  Future<Map<String, String>> get usageValues async => const <String, String>{};

  /// Runs this command.
  ///
  /// Rather than overriding this method, subclasses should override
  /// [verifyThenRunCommand] to perform any verification
  /// and [runCommand] to execute the command
  /// so that this method can record and report the overall time to analytics.
  @override
  Future<Null> run() async {
    final DateTime startTime = clock.now();

    context.setVariable(FlutterCommand, this);

    if (flutterUsage.isFirstRun)
      flutterUsage.printWelcome();

    FlutterCommandResult commandResult;
    try {
      commandResult = await verifyThenRunCommand();
    } on ToolExit {
      commandResult = const FlutterCommandResult(ExitStatus.fail);
      rethrow;
    } finally {
      final DateTime endTime = clock.now();
      printTrace('"flutter $name" took ${getElapsedAsMilliseconds(endTime.difference(startTime))}.');
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
      new FlutterProject(fs.currentDirectory).ensureReadyForPlatformSpecificTooling();
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
  Future<Null> validateCommand() async {
    if (_requiresPubspecYaml && !PackageMap.isUsingCustomPackagesPath) {
      // Don't expect a pubspec.yaml file if the user passed in an explicit .packages file path.
      if (!fs.isFileSync('pubspec.yaml')) {
        throw new ToolExit(
          'Error: No pubspec.yaml file found.\n'
          'This command should be run from the root of your Flutter project.\n'
          'Do not run this command from the root of your git clone of Flutter.'
        );
      }

      if (fs.isFileSync('flutter.yaml')) {
        throw new ToolExit(
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
        final String error = new PackageMap(PackageMap.globalPackagesPath).checkValid();
        if (error != null)
          throw new ToolExit(error);
      }
    }

    if (_usesTargetOption) {
      final String targetPath = targetFile;
      if (!fs.isFileSync(targetPath))
        throw new ToolExit('Target file "$targetPath" not found.');
    }
  }

  ApplicationPackageStore applicationPackages;
}
