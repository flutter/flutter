// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/signals.dart';
import '../base/utils.dart';
import '../context/tool_context.dart';
import '../device.dart';
import '../runner/flutter_command.dart';
import 'screenshot.dart';

const String _kOut = 'out';
const String _kDuration = 'duration';

/// The `flutter capture` command, which allows capturing screenshots and screen
/// recordings from connected devices.
class CaptureCommand extends FlutterCommand {
  CaptureCommand({required super.toolContext}) {
    addSubcommand(CaptureScreenshotCommand(toolContext: toolContext));
    addSubcommand(CaptureRecordingCommand(toolContext: toolContext));
  }

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  String get name => 'capture';

  @override
  String get description => 'Capture a screenshot or screen recording from a connected device.';

  @override
  String get category => FlutterCommandCategory.tools;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

/// The `flutter capture screenshot` command, which captures a screenshot from a
/// connected device or VM Service.
class CaptureScreenshotCommand extends ScreenshotCommand {
  CaptureScreenshotCommand({required super.toolContext, super.vmServiceConnector});

  @override
  bool get hidden => false;

  @override
  List<String> get aliases => const <String>[];
}

/// The `flutter capture recording` command, which records the screen of a
/// connected device.
class CaptureRecordingCommand extends FlutterCommand {
  CaptureRecordingCommand({required super.toolContext}) {
    argParser.addOption(
      _kOut,
      abbr: 'o',
      valueHelp: 'path/to/file',
      help: 'Location to write the recording.',
    );
    argParser.addOption(
      _kDuration,
      valueHelp: 'seconds',
      help:
          'Maximum recording duration in seconds. '
          'If not specified, recording continues until Ctrl-C is pressed. '
          'On Android, duration is limited to a maximum of 180 seconds. '
          'On macOS, the entire screen is recorded.',
    );
    registerOptionBundle(const DeviceDiscoveryOptionsBundle());
  }

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  String get name => 'recording';

  @override
  String get description => 'Record the screen of a connected device.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  Device? _device;
  Duration? _duration;

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String? commandPath) async {
    final String? durationStr = stringArg(_kDuration);
    if (durationStr != null) {
      final int? seconds = int.tryParse(durationStr);
      if (seconds == null || seconds <= 0) {
        throwToolExit('Invalid duration: "$durationStr". Must be a positive integer.');
      }
      _duration = Duration(seconds: seconds);
    }
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<void> validateCommand() async {
    await super.validateCommand();
    _device = await findTargetDevice(includeDevicesUnsupportedByProject: true);
    if (_device == null) {
      throwToolExit('No connected device found.');
    }
    if (!_device!.supportsScreenRecording) {
      throwToolExit('Screen recording not supported for ${_device!.displayName}.');
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final ToolContext(
      :FileSystem fs,
      :Logger logger,
      :FileSystemUtils fileSystemUtils,
      :Signals signals,
    ) = toolContext;

    final File outputFile = argResults?.wasParsed(_kOut) == true
        ? fs.file(stringArg(_kOut))
        : fileSystemUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'mp4');

    if (_duration != null) {
      logger.printStatus(
        'Recording ${_device!.displayName} for ${_duration!.inSeconds} seconds...',
      );
    } else {
      logger.printStatus('Recording ${_device!.displayName}... Press Ctrl-C to stop.');
    }

    final ScreenRecording recording = await _device!.startScreenRecording(
      outputFile,
      duration: _duration,
    );
    final commandComplete = Completer<void>();
    Future<void>? stopFuture;
    Future<void> stopRecording(ProcessSignal _) async {
      try {
        stopFuture ??= recording.stop();
        await stopFuture;
        await commandComplete.future;
      } on Exception catch (error) {
        logger.printTrace('Error stopping screen recording: $error');
      }
    }

    final Object sigintToken = signals.addHandler(ProcessSignal.sigint, stopRecording);
    final Object sigtermToken = signals.addHandler(ProcessSignal.sigterm, stopRecording);
    try {
      await recording.done;
      if (!outputFile.existsSync() || outputFile.lengthSync() == 0) {
        throwToolExit(
          'Recording file was not created, ensure path is valid\n'
          'Path provided: "${outputFile.path}"',
        );
      }
      logger.printStatus(
        'Recording written to ${fs.path.relative(outputFile.path)} (${getSizeAsPlatformMB(outputFile.lengthSync())}).',
      );
    } finally {
      commandComplete.complete();
      await signals.removeHandler(ProcessSignal.sigint, sigintToken);
      await signals.removeHandler(ProcessSignal.sigterm, sigtermToken);
    }

    return FlutterCommandResult.success();
  }
}
