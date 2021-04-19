// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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
  String get description => 'Reset the config file to its default.';

  @override
  String get name => 'reset';

  @override
  Future<FlutterCommandResult> runCommand() {
    throw UnimplementedError();
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
