// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
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

/// Standalone `flutter screenshot` command, kept for backward compatibility.
class ScreenshotCommand extends FlutterCommand {
  ScreenshotCommand({
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
    registerOptionBundle(const DeviceDiscoveryOptionsBundle());
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
  bool get hidden => true;

  @override
  final aliases = const <String>['pic'];

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

    checkOutput(outputFile);

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
    final FlutterVmService vmService = await vmServiceConnector(
      vmServiceUrl,
      device: _screenshotDevice,
      flutterVersion: toolContext.flutterVersion,
      logger: logger,
    );
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
    logger.printStatus('Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).');
  }

  @visibleForTesting
  static void checkOutput(File outputFile) {
    if (!outputFile.existsSync()) {
      throwToolExit(
        'File was not created, ensure path is valid\n'
        'Path provided: "${outputFile.path}"',
      );
    }
  }
}
