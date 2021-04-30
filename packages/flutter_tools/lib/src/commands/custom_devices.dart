// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';

import '../globals_null_migrated.dart' as globals;
import '../runner/flutter_command.dart';

class CustomDevicesCommand extends FlutterCommand {
  CustomDevicesCommand() {
    addSubcommand(CustomDevicesListCommand());
    addSubcommand(CustomDevicesResetCommand());
    addSubcommand(CustomDevicesAddCommand());
    addSubcommand(CustomDevicesDeleteCommand());
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

abstract class CustomDevicesSubCommand extends FlutterCommand {}

class CustomDevicesListCommand extends CustomDevicesSubCommand {
  CustomDevicesListCommand();

  @override
  String get description => 'List the currently configured custom devices, both enabled and disabled';

  @override
  String get name => 'list';

  @override
  Future<FlutterCommandResult> runCommand() {
    throw UnimplementedError();
  }
}

class CustomDevicesResetCommand extends CustomDevicesSubCommand {
  CustomDevicesResetCommand();

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
  Future<FlutterCommandResult> runCommand() {
    
  }
}

class CustomDevicesAddCommand extends CustomDevicesSubCommand {
  CustomDevicesAddCommand();

  @override
  String get description => 'Add a new device the custom devices config file.';

  @override
  String get name => 'add';

  @override
  Future<FlutterCommandResult> runCommand() {
    throw UnimplementedError();
  }
}

class CustomDevicesDeleteCommand extends CustomDevicesSubCommand {
  CustomDevicesDeleteCommand();

  @override
  String get description => 'Delete a device from the custom devices config file.';

  @override
  String get name => 'delete';

  @override
  Future<FlutterCommandResult> runCommand() {
    throw UnimplementedError();
  }
}
