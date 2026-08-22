// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../vmservice.dart';

const String _kOut = 'out';
const String _kType = 'type';
const String _kVmServiceUrl = 'vm-service-url';
const String _kDeviceType = 'device';
const String _kSkiaType = 'skia';

/// Shared screenshot logic used by [ScreenshotCommand], [CaptureCommand] (bare
/// invocation), and [CaptureScreenshotCommand].
mixin ScreenshotMixin on FlutterCommand {
  FileSystem get fs;

  void addScreenshotOptions() {
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

  Device? screenshotDevice;

  Future<void> validateScreenshotOptions() async {
    final String? screenshotType = stringArg(_kType);
    final String? vmServiceUrl = stringArg(_kVmServiceUrl);
    switch (screenshotType) {
      case _kDeviceType:
        if (vmServiceUrl != null) {
          throwToolExit('VM Service URI cannot be provided for screenshot type $screenshotType');
        }
        screenshotDevice = await findTargetDevice(includeDevicesUnsupportedByProject: true);
        if (screenshotDevice == null) {
          throwToolExit('Must have a connected device for screenshot type $screenshotType');
        }
        if (!screenshotDevice!.supportsScreenshot) {
          throwToolExit('Screenshot not supported for ${screenshotDevice!.displayName}.');
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

  Future<FlutterCommandResult> runScreenshot() async {
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
    outputFile ??= globals.fsUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'png');

    try {
      await screenshotDevice!.takeScreenshot(outputFile);
    } on ToolExit {
      rethrow;
    } on Exception catch (error) {
      throwToolExit('Error taking screenshot: $error');
    }

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
    final FlutterVmService vmService = await connectToVmService(
      vmServiceUrl,
      logger: globals.logger,
    );
    final vm_service.Response? skp = await vmService.screenshotSkp();
    if (skp == null) {
      globals.printError(
        'The Skia picture request failed, probably because the device was '
        'disconnected',
      );
      return false;
    }
    outputFile ??= globals.fsUtils.getUniqueFile(fs.currentDirectory, 'flutter', 'skp');
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(skp.json?['skp'] as String));
    await sink.close();
    _showOutputFileInfo(outputFile);
    ensureOutputIsNotJsonRpcError(outputFile);
    return true;
  }

  void _showOutputFileInfo(File outputFile) {
    final int sizeKB = (outputFile.lengthSync()) ~/ 1024;
    globals.printStatus(
      'Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).',
    );
  }

  static void checkOutput(File outputFile, FileSystem fs) {
    if (!fs.file(outputFile.path).existsSync()) {
      throwToolExit(
        'File was not created, ensure path is valid\n'
        'Path provided: "${outputFile.path}"',
      );
    }
  }

  @visibleForTesting
  static void ensureOutputIsNotJsonRpcError(File outputFile) {
    if (outputFile.lengthSync() >= 1000) {
      return;
    }
    final String content = outputFile.readAsStringSync(
      encoding: const AsciiCodec(allowInvalid: true),
    );
    if (content.startsWith('{"jsonrpc":"2.0", "error"')) {
      throwToolExit('It appears the output file contains an error message, not valid output.');
    }
  }
}

/// Standalone `flutter screenshot` command, kept for backward compatibility.
///
/// Shares screenshot logic with [CaptureScreenshotCommand] via [ScreenshotMixin].
class ScreenshotCommand extends FlutterCommand with ScreenshotMixin {
  ScreenshotCommand({required this.fs}) {
    addScreenshotOptions();
  }

  @override
  final FileSystem fs;

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  @override
  final List<String> aliases = const <String>['pic'];

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String? commandPath) async {
    await validateScreenshotOptions();
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() => runScreenshot();
}

class CaptureCommand extends FlutterCommand {
  CaptureCommand({required FileSystem fs}) {
    addSubcommand(CaptureScreenshotCommand(fs: fs));
    addSubcommand(CaptureRecordingCommand(fs: fs));
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

class CaptureScreenshotCommand extends FlutterCommand with ScreenshotMixin {
  CaptureScreenshotCommand({required this.fs}) {
    addScreenshotOptions();
  }

  @override
  final FileSystem fs;

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  final String category = FlutterCommandCategory.tools;

  @override
  bool get refreshWirelessDevices => true;

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String? commandPath) async {
    await validateScreenshotOptions();
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() => runScreenshot();
}

class CaptureRecordingCommand extends FlutterCommand {
  CaptureRecordingCommand({required this.fs}) {
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
  String get name => 'recording';

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

    StreamSubscription<ProcessSignal>? sigintSubscription;
    if (duration == null) {
      sigintSubscription = ProcessSignal.sigint.watch().listen((ProcessSignal signal) {});
    }
    try {
      await _device!.startScreenRecording(outputFile, duration: duration);
    } on ToolExit {
      rethrow;
    } on Exception catch (error) {
      throwToolExit('Error recording screen: $error');
    } finally {
      await sigintSubscription?.cancel();
    }

    if (!outputFile.existsSync()) {
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
