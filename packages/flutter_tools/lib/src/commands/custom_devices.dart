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
import '../runner/flutter_command.dart';

class CustomDevicesCommand extends FlutterCommand {
  CustomDevicesCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required Terminal terminal,
    @required Platform platform,
    @required FileSystem fileSystem,
    @required Logger logger,
  }) {
    addSubcommand(CustomDevicesListCommand(
      customDevicesConfig: customDevicesConfig,
      logger: logger
    ));
    addSubcommand(CustomDevicesResetCommand(
      customDevicesConfig: customDevicesConfig,
      fileSystem: fileSystem,
      logger: logger,
    ));
    addSubcommand(CustomDevicesAddCommand(
      customDevicesConfig: customDevicesConfig,
      terminal: terminal,
      platform: platform,
      logger: logger,
    ));
    addSubcommand(CustomDevicesDeleteCommand(
      customDevicesConfig: customDevicesConfig,
      logger: logger,
    ));
  }

  @override
  String get description => 'List, check, add & delete custom devices.';

  @override
  String get name => 'custom-devices';

  @override
  Future<FlutterCommandResult> runCommand() {
    throw UnimplementedError();
  }
}

abstract class CustomDevicesSubCommand extends FlutterCommand {
  String getConfigBackupPath(String configPath) => '$configPath.bak';

  Future<void> backup(
    String configPath, {
    @required FileSystem fileSystem
  }) async {
    final File configFile = fileSystem.file(configPath);
    final String configPathBackup = getConfigBackupPath(configPath);
    final File configFileBackup = fileSystem.file(configPathBackup);

    if (await configFileBackup.exists()) {
      await configFileBackup.delete();
    }
    await configFile.rename(configPathBackup);
  }
}

class CustomDevicesListCommand extends CustomDevicesSubCommand {
  CustomDevicesListCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required Logger logger,
  }) : _customDevicesConfig = customDevicesConfig,
        _logger = logger;

  final CustomDevicesConfig _customDevicesConfig;
  final Logger _logger;

  @override
  String get description => '''
List the currently configured custom devices, both enabled and disabled, reachable or not.
''';

  @override
  String get name => 'list';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<CustomDeviceConfig> devices = _customDevicesConfig.devices;

    if (devices.isEmpty) {
      _logger.printStatus('No valid custom devices found.');
    } else {
      _logger.printStatus('List of valid custom devices:');
      for (final CustomDeviceConfig device in devices) {
        _logger.printStatus('id: ${device.id}, label: ${device.label}, enabled: ${!device.disabled}', indent: 2, hangingIndent: 2);
      }
    }

    return FlutterCommandResult.success();
  }
}

class CustomDevicesResetCommand extends CustomDevicesSubCommand {
  CustomDevicesResetCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required FileSystem fileSystem,
    @required Logger logger,
  }) : _customDevicesConfig = customDevicesConfig,
        _fileSystem = fileSystem,
        _logger = logger;

  final CustomDevicesConfig _customDevicesConfig;
  final FileSystem _fileSystem;
  final Logger _logger;

  @override
  String get description => '''
Reset the custom devices config file to it's default.

The current config file will be backed up. A `.bak` will be appended to the
file name of the current config file. If a file already exists with that `.bak`
file name, it will be deleted.
''';

  @override
  String get name => 'reset';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String configPath = _customDevicesConfig.configPath;

    await backup(configPath, fileSystem: _fileSystem);
    _customDevicesConfig.ensureFileExists();

    _logger.printStatus(
      'Successfully resetted the custom devices config file and created a '
      'backup at "${getConfigBackupPath(configPath)}".'
    );
    return FlutterCommandResult.success();
  }
}

class CustomDevicesAddCommand extends CustomDevicesSubCommand {
  CustomDevicesAddCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required Terminal terminal,
    @required Platform platform,
    @required Logger logger,
  }) : _customDevicesConfig = customDevicesConfig,
       _terminal = terminal,
       _platform = platform,
       _logger = logger
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
  }

  static const String _kJson = 'json';
  static const List<String> _kJsonAliases = <String>['js'];
  static const String _kCheck = 'check';
  static const String _kSuccessfullyAdded = 'Successfully added custom device to config.';

  final CustomDevicesConfig _customDevicesConfig;
  final Terminal _terminal;
  final Platform _platform;
  final Logger _logger;
  StreamQueue<String> inputs;

  @override
  String get description => 'Add a new device the custom devices config file.';

  @override
  String get name => 'add';

  Future<bool> checkConfigWithLogging(CustomDeviceConfig config) async {
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
      _logger.printError('Could not decode json: $e');
      return FlutterCommandResult.fail();
    }

    CustomDeviceConfig config;
    try {
      config = CustomDeviceConfig.fromJson(json);
    } on JsonRevivalException catch (e) {
      _logger.printError('Invalid custom device config: $e');
      return FlutterCommandResult.fail();
    }

    if (shouldCheck && !await checkConfigWithLogging(config)) {
      return FlutterCommandResult.fail();
    }

    _customDevicesConfig.devices = <CustomDeviceConfig>[
      ..._customDevicesConfig.devices,
      config
    ];

    _logger.printStatus(_kSuccessfullyAdded);

    return FlutterCommandResult.success();
  }

  Future<String> askForString(
    String name, {
    String description,
    String example,
    String defaultsTo,
    Future<bool> Function(String) validator,
  }) async {
    String msg = description;

    final String exampleOrDefault = <String>[
      if (example != null) 'example: $example',
      if (defaultsTo != null) 'defaults to: $defaultsTo'
    ].join(', ');

    if (exampleOrDefault.isNotEmpty) {
      msg += ' ($exampleOrDefault)';
    }

    msg += ':';

    _logger.printStatus(msg);
    while (true) {
      final String input = await inputs.next;

      if (validator != null && !await validator(input)) {
        _logger.printStatus('Invalid $name. $name:');
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
      _logger.printStatus(msg);
      final String input = await inputs.next;

      if (input.isEmpty) {
        return defaultsTo;
      } else if (input.toLowerCase() == 'y') {
        return true;
      } else if (input.toLowerCase() == 'n') {
        return false;
      } else {
        _logger.printStatus('Invalid $name. Expected is either y or n.');
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

  Future<FlutterCommandResult> runInteractively() async {
    final bool shouldCheck = boolArg(_kCheck) ?? true;

    inputs = StreamQueue<String>(_terminal.keystrokes.map((String s) => s.trim()));

    /*
    final String id;
    final String label;
    final String sdkNameAndVersion;
    final bool disabled;
    final List<String> pingCommand;
    final RegExp? pingSuccessRegex;
    final List<String>? postBuildCommand;
    final List<String> installCommand;
    final List<String> uninstallCommand;
    final List<String> runDebugCommand;
    final List<String>? forwardPortCommand;
    final RegExp? forwardPortSuccessRegex;
    final List<String>? screenshotCommand;
    */

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

    return FlutterCommandResult.success();
  }

  @override
  Future<FlutterCommandResult> runCommand() {
    if (stringArg(_kJson) != null) {
      return runNonInteractively();
    } else {
      return runInteractively();
    }
  }
}

class CustomDevicesDeleteCommand extends CustomDevicesSubCommand {
  CustomDevicesDeleteCommand({
    @required CustomDevicesConfig customDevicesConfig,
    @required Logger logger,
  }) : _customDevicesConfig = customDevicesConfig,
        _logger = logger;

  final CustomDevicesConfig _customDevicesConfig;
  final Logger _logger;

  @override
  String get description => 'Delete a device from the custom devices config file.';

  @override
  String get name => 'delete';

  @override
  Future<FlutterCommandResult> runCommand() async {
    return FlutterCommandResult.success();
  }
}
