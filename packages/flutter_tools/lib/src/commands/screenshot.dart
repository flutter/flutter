// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart' as vm_service;

import '../base/common.dart';
import '../base/file_system.dart';
import '../convert.dart';
import '../device.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../vmservice.dart';

const String _kOut = 'out';
const String _kType = 'type';
const String _kObservatoryUri = 'observatory-uri';
const String _kDeviceType = 'device';
const String _kSkiaType = 'skia';
const String _kRasterizerType = 'rasterizer';

class ScreenshotCommand extends FlutterCommand {
  ScreenshotCommand() {
    argParser.addOption(
      _kOut,
      abbr: 'o',
      valueHelp: 'path/to/file',
      help: 'Location to write the screenshot.',
    );
    argParser.addOption(
      _kObservatoryUri,
      valueHelp: 'URI',
      help: 'The observatory URI to connect to.\n'
          'This is required when --$_kType is "$_kSkiaType" or "$_kRasterizerType".\n'
          'To find the observatory URI, use "flutter run" and look for '
          '"An Observatory ... is available at" in the output.',
    );
    argParser.addOption(
      _kType,
      valueHelp: 'type',
      help: 'The type of screenshot to retrieve.',
      allowed: const <String>[_kDeviceType, _kSkiaType, _kRasterizerType],
      allowedHelp: const <String, String>{
        _kDeviceType: "Delegate to the device's native screenshot capabilities. This "
            'screenshots the entire screen currently being displayed (including content '
            'not rendered by Flutter, like the device status bar).',
        _kSkiaType: 'Render the Flutter app as a Skia picture. Requires --$_kObservatoryUri',
        _kRasterizerType: 'Render the Flutter app using the rasterizer. Requires --$_kObservatoryUri',
      },
      defaultsTo: _kDeviceType,
    );
    usesDeviceTimeoutOption();
  }

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  final List<String> aliases = <String>['pic'];

  Device device;

  static void validateOptions(String screenshotType, Device device, String observatoryUri) {
    switch (screenshotType) {
      case _kDeviceType:
        if (device == null) {
          throwToolExit('Must have a connected device for screenshot type $screenshotType');
        }
        if (!device.supportsScreenshot) {
          throwToolExit('Screenshot not supported for ${device.name}.');
        }
        break;
      default:
        if (observatoryUri == null) {
          throwToolExit('Observatory URI must be specified for screenshot type $screenshotType');
        }
    }
  }

  @override
  Future<FlutterCommandResult> verifyThenRunCommand(String commandPath) async {
    device = await findTargetDevice();
    validateOptions(stringArg(_kType), device, stringArg(_kObservatoryUri));
    return super.verifyThenRunCommand(commandPath);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    File outputFile;
    if (argResults.wasParsed(_kOut)) {
      outputFile = globals.fs.file(stringArg(_kOut));
    }

    switch (stringArg(_kType)) {
      case _kDeviceType:
        await runScreenshot(outputFile);
        return FlutterCommandResult.success();
      case _kSkiaType:
        await runSkia(outputFile);
        return FlutterCommandResult.success();
      case _kRasterizerType:
        await runRasterizer(outputFile);
        return FlutterCommandResult.success();
    }

    return FlutterCommandResult.success();
  }

  Future<void> runScreenshot(File outputFile) async {
    outputFile ??= globals.fsUtils.getUniqueFile(
      globals.fs.currentDirectory,
      'flutter',
      'png',
    );
    try {
      await device.takeScreenshot(outputFile);
    } on Exception catch (error) {
      throwToolExit('Error taking screenshot: $error');
    }
    _showOutputFileInfo(outputFile);
  }

  Future<void> runSkia(File outputFile) async {
    final Uri observatoryUri = Uri.parse(stringArg(_kObservatoryUri));
    final vm_service.VmService vmService = await connectToVmService(observatoryUri);
    final vm_service.Response skp = await vmService.screenshotSkp();
    outputFile ??= globals.fsUtils.getUniqueFile(
      globals.fs.currentDirectory,
      'flutter',
      'skp',
    );
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(skp.json['skp'] as String));
    await sink.close();
    _showOutputFileInfo(outputFile);
    _ensureOutputIsNotJsonRpcError(outputFile);
  }

  Future<void> runRasterizer(File outputFile) async {
    final Uri observatoryUri = Uri.parse(stringArg(_kObservatoryUri));
    final vm_service.VmService vmService = await connectToVmService(observatoryUri);
    final vm_service.Response response = await vmService.screenshot();
    outputFile ??= globals.fsUtils.getUniqueFile(
      globals.fs.currentDirectory,
      'flutter',
      'png',
    );
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(response.json['screenshot'] as String));
    await sink.close();
    _showOutputFileInfo(outputFile);
    _ensureOutputIsNotJsonRpcError(outputFile);
  }

  void _ensureOutputIsNotJsonRpcError(File outputFile) {
    if (outputFile.lengthSync() >= 1000) {
      return;
    }
    final String content = outputFile.readAsStringSync(
      encoding: const AsciiCodec(allowInvalid: true),
    );
    if (content.startsWith('{"jsonrpc":"2.0", "error"')) {
      throwToolExit('It appears the output file contains an error message, not valid skia output.');
    }
  }

  void _showOutputFileInfo(File outputFile) {
    final int sizeKB = (outputFile.lengthSync()) ~/ 1024;
    globals.printStatus('Screenshot written to ${globals.fs.path.relative(outputFile.path)} (${sizeKB}kB).');
  }
}
