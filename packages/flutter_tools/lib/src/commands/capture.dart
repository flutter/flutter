// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/signals.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../device.dart';
import '../runner/flutter_command.dart';
import '../vmservice.dart';

const String _kOut = 'out';
const String _kType = 'type';
const String _kVmServiceUrl = 'vm-service-url';
const String _kDeviceType = 'device';
const String _kSkiaType = 'skia';
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
class CaptureScreenshotCommand extends FlutterCommand {
  CaptureScreenshotCommand({
    required super.toolContext,
    @visibleForTesting this.vmServiceConnector = connectToVmService,
  }) {
    argParser.addOption(
      _kOut,
      abbr: 'o',
      valueHelp: 'path/to/file',
      help: 'Location to write the screenshot.',
    );
    argParser.addOption(
      _kVmServiceUrl,
      valueHelp: 'URI',
      help:
          'The VM Service URL to which to connect.\n'
          'This is required when "--$_kType" is "$_kSkiaType".\n'
          'To find the VM service URL, use "flutter run" and look for '
          '"A Dart VM Service ... is available at" in the output.',
    );
    argParser.addOption(
      _kType,
      valueHelp: 'type',
      help: 'The type of screenshot to retrieve.',
      allowed: const <String>[_kDeviceType, _kSkiaType],
      allowedHelp: const <String, String>{
        _kDeviceType:
            "Delegate to the device's native screenshot capabilities. This "
            'screenshots the entire screen currently being displayed (including content '
            'not rendered by Flutter, like the device status bar).',
        _kSkiaType: 'Render the Flutter app as a Skia picture. Requires "--$_kVmServiceUrl".',
      },
      defaultsTo: _kDeviceType,
    );
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
  }

  @visibleForTesting
  final VMServiceConnector vmServiceConnector;

  @override
  ToolContext get toolContext => super.toolContext!;

  FileSystem get fs => toolContext.fs;
  Logger get logger => toolContext.logger;
  FileSystemUtils get fsUtils => toolContext.fileSystemUtils;

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => argResults == null || stringArg(_kType) == _kDeviceType;

  Device? _screenshotDevice;

  Future<void> _validateScreenshotOptions() async {
    final String? screenshotType = stringArg(_kType);
    final String? vmServiceUrl = stringArg(_kVmServiceUrl);
    switch (screenshotType) {
      case _kDeviceType:
        if (vmServiceUrl != null) {
          throwToolExit('VM Service URI cannot be provided for screenshot type $screenshotType');
        }
        _screenshotDevice = await findTargetDevice(includeDevicesUnsupportedByProject: true);
        if (_screenshotDevice == null) {
          throwToolExit('Must have a connected device for screenshot type $screenshotType');
        }
        if (!_screenshotDevice!.supportsScreenshot) {
          throwToolExit('Screenshot not supported for ${_screenshotDevice!.displayName}.');
        }
      default:
        if (vmServiceUrl == null) {
          throwToolExit('VM Service URI must be specified for screenshot type $screenshotType');
        }
        if (vmServiceUrl.isEmpty || Uri.tryParse(vmServiceUrl) == null) {
          throwToolExit('VM Service URI "$vmServiceUrl" is invalid');
        }
    }
  }

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String? commandPath) async {
    await _validateScreenshotOptions();
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    File? outputFile;
    if (argResults?.wasParsed(_kOut) ?? false) {
      outputFile = fs.file(stringArg(_kOut));
    }

    var success = true;
    switch (stringArg(_kType)) {
      case _kDeviceType:
        await _runDeviceScreenshot(outputFile);
      case _kSkiaType:
        success = await _runSkiaScreenshot(outputFile);
    }

    return success ? FlutterCommandResult.success() : FlutterCommandResult.fail();
  }

  Future<void> _runDeviceScreenshot(File? outputFile) async {
    outputFile ??= fsUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'png');

    await _screenshotDevice!.takeScreenshot(outputFile);

    checkOutput(outputFile, fs);

    try {
      _showOutputFileInfo(outputFile);
    } on Exception catch (error) {
      throwToolExit(
        'Error with provided file path: "${outputFile.path}"\n'
        'Error: $error',
      );
    }
  }

  Future<bool> _runSkiaScreenshot(File? outputFile) async {
    final Uri vmServiceUrl = Uri.parse(stringArg(_kVmServiceUrl)!);
    final FlutterVmService vmService = await vmServiceConnector(vmServiceUrl, logger: logger);
    final vm_service.Response? skp = await vmService.screenshotSkp();
    if (skp == null) {
      logger.printError(
        'The Skia picture request failed, probably because the device was '
        'disconnected',
      );
      return false;
    }
    outputFile ??= fsUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'skp');
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(skp.json?['skp'] as String));
    await sink.close();
    _showOutputFileInfo(outputFile);
    return true;
  }

  void _showOutputFileInfo(File outputFile) {
    final int sizeKB = outputFile.lengthSync() ~/ 1024;
    logger.printStatus(
      'Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).',
    );
  }

  static void checkOutput(File outputFile, FileSystem fs) {
    if (!outputFile.existsSync()) {
      throwToolExit(
        'File was not created, ensure path is valid\n'
        'Path provided: "${outputFile.path}"',
      );
    }
  }
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
    usesDeviceTimeoutOption();
    usesDeviceConnectionOption();
  }

  @override
  ToolContext get toolContext => super.toolContext!;

  FileSystem get fs => toolContext.fs;
  Logger get logger => toolContext.logger;
  FileSystemUtils get fsUtils => toolContext.fileSystemUtils;

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
    final File outputFile = argResults?.wasParsed(_kOut) == true
        ? fs.file(stringArg(_kOut))
        : fsUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'mp4');

    if (_duration != null && _duration!.inSeconds > 180) {
      final TargetPlatform target = await _device!.targetPlatform;
      if (target == TargetPlatform.android ||
          target == TargetPlatform.android_arm ||
          target == TargetPlatform.android_arm64 ||
          target == TargetPlatform.android_x64) {
        logger.printWarning(
          'Android screen recording has a maximum limit of 180 seconds. '
          'Recording will be clamped to 180 seconds.',
        );
      }
    }

    if (_duration != null) {
      logger.printStatus('Recording ${_device!.displayName} for ${_duration!.inSeconds} seconds...');
    } else {
      logger.printStatus('Recording ${_device!.displayName}... Press Ctrl-C to stop.');
    }

    final Signals signals = toolContext.signals;
    final ScreenRecording recording = await _device!.startScreenRecording(
      outputFile,
      duration: _duration,
    );
    Future<void>? stopFuture;
    Future<void> stopRecording(ProcessSignal _) async {
      try {
        stopFuture ??= recording.stop();
        await stopFuture;
      } on Exception catch (error) {
        logger.printTrace('Error stopping screen recording: $error');
      }
    }
    final Object sigintToken = signals.addHandler(ProcessSignal.sigint, stopRecording);
    final Object sigtermToken = signals.addHandler(ProcessSignal.sigterm, stopRecording);
    try {
      await recording.done;
    } finally {
      await signals.removeHandler(ProcessSignal.sigint, sigintToken);
      await signals.removeHandler(ProcessSignal.sigterm, sigtermToken);
    }

    if (!outputFile.existsSync() || outputFile.lengthSync() == 0) {
      throwToolExit(
        'Recording file was not created, ensure path is valid\n'
        'Path provided: "${outputFile.path}"',
      );
    }

    logger.printStatus(
      'Recording written to ${fs.path.relative(outputFile.path)} (${getSizeAsPlatformMB(outputFile.lengthSync())}).',
    );
    return FlutterCommandResult.success();
  }
}
