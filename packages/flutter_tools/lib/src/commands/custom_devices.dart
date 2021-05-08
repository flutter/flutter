// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8


import 'dart:async';

import 'package:async/async.dart';
import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/io.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../convert.dart';
import '../custom_devices/custom_device_config.dart';
import '../custom_devices/custom_devices_config.dart';
import '../features.dart';
import '../runner/flutter_command.dart';

class CustomDevicesCommand extends FlutterCommand {
  CustomDevicesCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required Terminal terminal,
    @required Platform platform,
    @required FileSystem fileSystem,
    @required Logger logger,
    @required FeatureFlags featureFlags
  }) : configPath = customDevicesConfig?.configPath,
       assert(terminal != null),
       assert(platform != null),
       assert(fileSystem != null),
       assert(logger != null),
       assert(featureFlags != null) {
    addSubcommand(CustomDevicesListCommand(
      customDevicesConfig: customDevicesConfig,
      featureFlags: featureFlags,
      logger: logger,
    ));
    addSubcommand(CustomDevicesResetCommand(
      customDevicesConfig: customDevicesConfig,
      featureFlags: featureFlags,
      fileSystem: fileSystem,
      logger: logger,
    ));
    addSubcommand(CustomDevicesAddCommand(
      customDevicesConfig: customDevicesConfig,
      terminal: terminal,
      platform: platform,
      featureFlags: featureFlags,
      fileSystem: fileSystem,
      logger: logger,
    ));
    addSubcommand(CustomDevicesDeleteCommand(
      customDevicesConfig: customDevicesConfig,
      featureFlags: featureFlags,
      fileSystem: fileSystem,
      logger: logger,
    ));
  }

  final String configPath;

  @override
  String get description => '''
List, reset, add and delete custom devices${configPath != null? ' from the config at "$configPath"' : ''}.

This is just a collection of commonly used shorthands for things like adding
ssh devices, resetting (with backup) and checking the config file. For advanced
configuration or more complete documentation, edit the config file with an
editor that supports JSON schemas like VS Code.

Requires the custom devices feature to be enabled. You can enable it using `flutter config --enable-custom-devices`.
''';

  @override
  String get name => 'custom-devices';

  @override
  Future<FlutterCommandResult> runCommand() async => null;
}

/// This class is meant to provide some commonly used utility functions
/// to the subcommands, like backing up the config file & checking if the
/// feature is enabled.
abstract class CustomDevicesSubCommand extends FlutterCommand {
  CustomDevicesSubCommand({
    @required this.customDevicesConfig,
    @required this.featureFlags,
    @required this.fileSystem,
    @required this.logger,
  }) : assert(featureFlags != null),
       assert(logger != null);

  @protected final CustomDevicesConfig customDevicesConfig;
  @protected final FeatureFlags featureFlags;
  @protected final FileSystem fileSystem;
  @protected final Logger logger;

  /// The path to the (potentially non-existing) backup of the config file.
  @protected
  String get configBackupPath => '${customDevicesConfig.configPath}.bak';

  /// Copies the current config file to [configBackupPath], overwriting it
  /// if necessary.
  @protected
  Future<void> backup() async
    => fileSystem.file(customDevicesConfig.configPath).copy(configBackupPath);

  /// Checks if the custom devices feature is enabled and returns true/false
  /// accordingly. Additionally, logs an error if it's not enabled with a hint
  /// on how to enable it.
  @protected
  bool checkFeatureEnabled() {
    if (featureFlags.areCustomDevicesEnabled) {
      logger.printError(
        'Custom devices feature must be enabled. '
        'Enable using `flutter config --enable-custom-devices`.'
      );
      return false;
    }

    return true;
  }
}

class CustomDevicesListCommand extends CustomDevicesSubCommand {
  CustomDevicesListCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required FeatureFlags featureFlags,
    @required Logger logger,
  }) : super(
         customDevicesConfig: customDevicesConfig,
         featureFlags: featureFlags,
         fileSystem: null,
         logger: logger
       );

  @override
  String get description => '''
List the currently configured custom devices, both enabled and disabled, reachable or not.
''';

  @override
  String get name => 'list';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!checkFeatureEnabled()) {
      return FlutterCommandResult.fail();
    }

    List<CustomDeviceConfig> devices;
    try {
      devices = customDevicesConfig.devices;
    } on Exception catch (_) {
      return FlutterCommandResult.fail();
    }

    if (devices.isEmpty) {
      logger.printStatus('No custom devices found in "${customDevicesConfig.configPath}"');
    } else {
      logger.printStatus('List of custom devices in "${customDevicesConfig.configPath}":');
      for (final CustomDeviceConfig device in devices) {
        logger.printStatus('id: ${device.id}, label: ${device.label}, enabled: ${!device.disabled}', indent: 2, hangingIndent: 2);
      }
    }

    return FlutterCommandResult.success();
  }
}

class CustomDevicesResetCommand extends CustomDevicesSubCommand {
  CustomDevicesResetCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required FeatureFlags featureFlags,
    @required FileSystem fileSystem,
    @required Logger logger,
  }) : super(
         customDevicesConfig: customDevicesConfig,
         featureFlags: featureFlags,
         fileSystem: fileSystem,
         logger: logger
       );

  @override
  String get description => '''
Reset the custom devices config file to its default.

The current config file will be backed up. A `.bak` will be appended to the
file name of the current config file. If a file already exists with that `.bak`
file name, it will be deleted.
''';

  @override
  String get name => 'reset';

  @override
  Future<FlutterCommandResult> runCommand() async {
    await backup();

    await fileSystem.file(customDevicesConfig.configPath).delete();
    customDevicesConfig.ensureFileExists();

    logger.printStatus(
      'Successfully resetted the custom devices config file and created a '
      'backup at "$configBackupPath".'
    );
    return FlutterCommandResult.success();
  }
}

class CustomDevicesAddCommand extends CustomDevicesSubCommand {
  CustomDevicesAddCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required Terminal terminal,
    @required Platform platform,
    @required FeatureFlags featureFlags,
    @required FileSystem fileSystem,
    @required Logger logger,
  }) : _terminal = terminal,
       _platform = platform,
       super(
         customDevicesConfig: customDevicesConfig,
         featureFlags: featureFlags,
         fileSystem: fileSystem,
         logger: logger
       )
  {
    argParser.addFlag(
        _kCheck,
        help: '''
Make sure the config actually works. This will execute some of the commands in
the config (if necessary with dummy arguments). This flag is enabled by default
when `--json` is not specified. If `--json` is given, it is disabled by default.
''',
        defaultsTo: null
    );

    argParser.addOption(
      _kJson,
      help: '''
Add the custom device described by this JSON-encoded string to the list of
custom-devices instead of using the normal, interactive way of configuring.
Useful if you want to use the `flutter custom-devices add` command from a
script, or use it non-interactively for some other reason.

By default, this won't check whether the passed in config actually works (only
if it is valid). To make sure the config works use the `--check` option.
''',
      valueHelp: 'JSON config',
      aliases: _kJsonAliases
    );

    argParser.addFlag(
      _kSsh,
      help: '''
Add a ssh-device. This will automatically fill out some of the config options
for you with good defaults, and in other cases save you some typing. So you'll
only need to enter some things like hostname and username of the remote device
instead of entering each individual command.

Defaults to on.
''',
      defaultsTo: true,
      negatable: false
    );
  }

  static const String _kJson = 'json';
  static const List<String> _kJsonAliases = <String>['js'];
  static const String _kCheck = 'check';
  static const String _kSsh = 'ssh';

  final Terminal _terminal;
  final Platform _platform;
  StreamQueue<String> inputs;

  @override
  String get description => 'Add a new device the custom devices config file.';

  @override
  String get name => 'add';

  Future<bool> checkConfigWithLogging(CustomDeviceConfig config) async {
    // ignore: flutter_style_todos
    /// TODO: Implement
    return true;
  }

  Future<FlutterCommandResult> runNonInteractively() async {
    final String jsonStr = stringArg(_kJson);
    final bool shouldCheck = boolArg(_kCheck) ?? false;

    dynamic json;
    try {
      json = jsonDecode(jsonStr);
    } on FormatException catch (e) {
      logger.printError('Could not decode json: $e');
      return FlutterCommandResult.fail();
    }

    CustomDeviceConfig config;
    try {
      config = CustomDeviceConfig.fromJson(json);
    } on JsonRevivalException catch (e) {
      logger.printError('Invalid custom device config: $e');
      return FlutterCommandResult.fail();
    }

    if (shouldCheck && !await checkConfigWithLogging(config)) {
      return FlutterCommandResult.fail();
    }

    customDevicesConfig.add(config);
    printSuccessfullyAdded();

    return FlutterCommandResult.success();
  }

  void printSuccessfullyAdded() {
    logger.printStatus('Successfully added custom device to config file at "${customDevicesConfig.configPath}".');
  }

  Future<String> askForString(
    String name, {
    String description,
    String example,
    String defaultsTo,
    Future<bool> Function(String) validator,
  }) async {
    String msg = description ?? name;

    final String exampleOrDefault = <String>[
      if (example != null) 'example: $example',
      if (defaultsTo != null) 'defaults to: $defaultsTo'
    ].join(', ');

    if (exampleOrDefault.isNotEmpty) {
      msg += ' ($exampleOrDefault)';
    }

    msg += ':';

    logger.printStatus(msg);
    while (true) {
      final String input = await inputs.next;

      if (validator != null && !await validator(input)) {
        logger.printStatus('Invalid $name. $name:');
      } else {
        return input;
      }
    }
  }

  Future<bool> askForBool(
    String name, {
    String description,
    bool defaultsTo = true,
  }) async {
    String msg = '$name, $description: ';
    if (defaultsTo == true) {
      msg += '[Y/n]';
    } else {
      msg += '[y/N]';
    }

    while (true) {
      logger.printStatus(msg);
      final String input = await inputs.next;

      if (input.isEmpty) {
        return defaultsTo;
      } else if (input.toLowerCase() == 'y') {
        return true;
      } else if (input.toLowerCase() == 'n') {
        return false;
      } else {
        logger.printStatus('Invalid $name. Expected is either y or n.');
      }
    }
  }

  Future<List<String>> askForCommand(
    String name, {
    String description,
    bool allowEmpty = false,
    List<String> defaultsTo,
    Future<bool> Function(String) verifier
  }) async {
    return <String>[];
  }

  Future<FlutterCommandResult> runInteractivelySsh() async {
    final bool shouldCheck = boolArg(_kCheck) ?? true;

    // listen to the keystrokes stream as late as possible, since it's a
    // single-subscription stream apparently
    inputs = StreamQueue<String>(_terminal.keystrokes.map((String s) => s.trim()));

    final String id = await askForString(
      'id',
      description: 'A unique, short identification string for the device.',
      example: 'pi',
      validator: (String s) async => s.isNotEmpty
    );

    final String label = await askForString(
      'label',
      description: 'A slightly more verbose label for the device.',
      example: 'Raspberry Pi'
    );

    final String sdkNameAndVersion = await askForString(
      'SDK name and version',
      example: 'Raspberry Pi 4 Model B+'
    );

    final bool enabled = await askForBool(
      'enabled',
      description: 'Should the device be enabled?',
      defaultsTo: true
    );

    final String target = await askForString(
      'target',
      description: 'The hostname or IPv4/v6 address of the device.',
      example: 'raspberrypi',
    );

    final String username = await askForString(
      'username',
      description: 'The username used for ssh\'ing into the remote device.',
      example: 'pi'
    );

    final String remoteRunDebugCommand = await askForString(
      'run command',
      description: r'The command executed on the remote device for starting the app. /tmp/${appName} is the path to the asset bundle.'
    );

    final InternetAddress ip = InternetAddress.tryParse(target);

    bool usePortForwarding = true;
    if (ip != null) {
      usePortForwarding = await askForBool(
        'use port forwarding',
        description: 'Whether to use port forwarding. '
          'Using port forwarding has the best compatibility, however if your '
          'remote device has a static IP address and you have a way of '
          'specifying the --observatory-host=<ip> engine option, you might prefer '
          'not using port forwarding.'
      );
    }

    final String screenshotCommand = await askForString(
      'screenshot command',
      description: 'The command executed on the remote device for taking a screenshot.',
      example: r"fbgrab /tmp/screenshot.png && cat /tmp/screenshot.png | base64 | tr -d ' \n\t'"
    );

    final String sshTarget = '${username != null ? username + '@' : ''}$target';

    final CustomDeviceConfig config = CustomDeviceConfig(
      id: id,
      label: label,
      sdkNameAndVersion: sdkNameAndVersion,
      disabled: !enabled,
      pingCommand: <String>['ping', '-n', '1', '-w', '500', target],
      pingSuccessRegex: _platform.isWindows ? RegExp(r'[<=]\d+ms') : null,
      postBuildCommand: null,
      installCommand: <String>['scp', '-r', r'${localPath}', '$sshTarget:/tmp/\${appName}'],
      uninstallCommand: <String>['ssh', sshTarget, r'rm -rf "/tmp/${appName}"'],
      runDebugCommand: <String>['ssh', sshTarget, remoteRunDebugCommand],
      forwardPortCommand: usePortForwarding ? <String>['ssh', '-o', 'ExitOnForwardFailure=yes', '-L', r'127.0.0.1:${hostPort}:127.0.0.1:${devicePort}', sshTarget] : null,
      forwardPortSuccessRegex: usePortForwarding ? RegExp('Linux') : null,
      screenshotCommand: <String>['ssh', sshTarget, screenshotCommand]
    );

    if (shouldCheck && !await checkConfigWithLogging(config)) {
      return FlutterCommandResult.fail();
    }

    customDevicesConfig.add(config);
    printSuccessfullyAdded();
    return FlutterCommandResult.success();
  }

  Future<FlutterCommandResult> runInteractively() async {
    // ignore: flutter_style_todos
    /// TODO: Implement
    return FlutterCommandResult.fail();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (checkFeatureEnabled()) {
      return FlutterCommandResult.fail();
    }

    if (stringArg(_kJson) != null) {
      return runNonInteractively();
    } else if (boolArg(_kSsh) == true) {
      return runInteractivelySsh();
    } else {
      return runInteractively();
    }
  }
}

class CustomDevicesDeleteCommand extends CustomDevicesSubCommand {
  CustomDevicesDeleteCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required FeatureFlags featureFlags,
    @required FileSystem fileSystem,
    @required Logger logger,
  }) : super(
         customDevicesConfig: customDevicesConfig,
         featureFlags: featureFlags,
         fileSystem: fileSystem,
         logger: logger
       )
  {
    argParser.addOption(
      'id',
      abbr: 'i',
      help: 'The id of the custom device to be deleted.',
      valueHelp: 'device id',
      mandatory: true,
    );
  }

  @override
  String get description => '''
Delete a device from the custom devices config file.
''';

  @override
  String get name => 'delete';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!checkFeatureEnabled()) {
      return FlutterCommandResult.fail();
    }

    final String id = stringArg('id');
    await backup();
    if (!customDevicesConfig.remove(id)) {
      logger.printError('Couldn\'t find device with id "$id" in config at "${customDevicesConfig.configPath}"');
    } else {
      logger.printStatus('Successfully removed device with id "$id" from config at "${customDevicesConfig.configPath}"');
    }

    return FlutterCommandResult.success();
  }
}
