// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class CaptureCommand extends FlutterCommand {
  CaptureCommand({required FileSystem fs}) {
    addSubcommand(CaptureImageCommand(fs: fs));
    addSubcommand(CaptureVideoCommand(fs: fs));
  }

  @override
  String get name => 'capture';

  @override
  String get description => 'Capture a screenshot or screen recording from a connected device.';

  @override
  String get category => FlutterCommandCategory.tools;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

const String _kOut = 'out';

class CaptureImageCommand extends FlutterCommand {
  CaptureImageCommand({required this.fs}) {
    argParser.addOption(
      _kOut,
      abbr: 'o',
      valueHelp: 'path/to/file',
      help: 'Location to write the screenshot.',
    );
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
  }

  final FileSystem fs;

  @override
  String get name => 'image';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  Device? _device;

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String? commandPath) async {
    _device = await findTargetDevice(includeDevicesUnsupportedByProject: true);
    if (_device == null) {
      throwToolExit('No connected device found.');
    }
    if (!_device!.supportsScreenshot) {
      throwToolExit('Screenshot not supported for ${_device!.displayName}.');
    }
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final File outputFile = argResults?.wasParsed(_kOut) == true
        ? fs.file(stringArg(_kOut))
        : globals.fsUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'png');

    try {
      await _device!.takeScreenshot(outputFile);
    } on ToolExit {
      rethrow;
    } on Exception catch (error) {
      throwToolExit('Error taking screenshot: $error');
    }

    if (!fs.file(outputFile.path).existsSync()) {
      throwToolExit(
        'File was not created, ensure path is valid\n'
        'Path provided: "${outputFile.path}"',
      );
    }

    final int sizeKB = outputFile.lengthSync() ~/ 1024;
    globals.printStatus(
      'Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).',
    );
    return FlutterCommandResult.success();
  }
}

class CaptureVideoCommand extends FlutterCommand {
  CaptureVideoCommand({required this.fs}) {
    argParser.addOption(
      _kOut,
      abbr: 'o',
      valueHelp: 'path/to/file',
      help: 'Location to write the recording.',
    );
    argParser.addOption(
      'duration',
      abbr: 'd',
      valueHelp: 'seconds',
      help: 'Maximum recording duration in seconds. '
          'If not specified, recording continues until Ctrl-C is pressed.',
    );
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
  }

  final FileSystem fs;

  @override
  String get name => 'video';

  @override
  String get description => 'Record the screen of a connected device.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  Device? _device;

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String? commandPath) async {
    _device = await findTargetDevice(includeDevicesUnsupportedByProject: true);
    if (_device == null) {
      throwToolExit('No connected device found.');
    }
    if (!_device!.supportsScreenRecording) {
      throwToolExit('Screen recording not supported for ${_device!.displayName}.');
    }
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final File outputFile = argResults?.wasParsed(_kOut) == true
        ? fs.file(stringArg(_kOut))
        : globals.fsUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'mp4');

    Duration? duration;
    final String? durationStr = stringArg('duration');
    if (durationStr != null) {
      final int? seconds = int.tryParse(durationStr);
      if (seconds == null || seconds <= 0) {
        throwToolExit('Invalid duration: "$durationStr". Must be a positive integer.');
      }
      duration = Duration(seconds: seconds);
    }

    if (duration != null) {
      globals.printStatus(
        'Recording ${_device!.displayName} for ${duration.inSeconds} seconds...',
      );
    } else {
      globals.printStatus(
        'Recording ${_device!.displayName}... Press Ctrl-C to stop.',
      );
    }

    try {
      await _device!.startScreenRecording(outputFile, duration: duration);
    } on ToolExit {
      rethrow;
    } on Exception catch (error) {
      throwToolExit('Error recording screen: $error');
    }

    if (!fs.file(outputFile.path).existsSync()) {
      throwToolExit(
        'Recording file was not created, ensure path is valid\n'
        'Path provided: "${outputFile.path}"',
      );
    }

    final int sizeKB = outputFile.lengthSync() ~/ 1024;
    globals.printStatus(
      'Recording written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).',
    );
    return FlutterCommandResult.success();
  }
}
