// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../vmservice.dart';

const String _kOut = 'out';
const String _kType = 'type';
const String _kObservatoryPort = 'observatory-port';
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
      _kObservatoryPort,
      valueHelp: 'port',
      help: 'The observatory port to connect to.\n'
          'This is required when --$_kType is "$_kSkiaType" or "$_kRasterizerType".\n'
          'To find the observatory port number, use "flutter run --verbose" '
          'and look for "Forwarded host port ... for Observatory" in the output.',
    );
    argParser.addOption(
      _kType,
      valueHelp: 'type',
      help: 'The type of screenshot to retrieve.',
      allowed: const <String>[_kDeviceType, _kSkiaType, _kRasterizerType],
      allowedHelp: const <String, String>{
        _kDeviceType: 'Delegate to the device\'s native screenshot capabilities. This '
            'screenshots the entire screen currently being displayed (including content '
            'not rendered by Flutter, like the device status bar).',
        _kSkiaType: 'Render the Flutter app as a Skia picture. Requires --$_kObservatoryPort',
        _kRasterizerType: 'Render the Flutter app using the rasterizer. Requires --$_kObservatoryPort',
      },
      defaultsTo: _kDeviceType,
    );
  }

  @override
  String get name => 'screenshot';

  @override
  String get description => 'Take a screenshot from a connected device.';

  @override
  final List<String> aliases = <String>['pic'];

  Device device;

  @override
  Future<FlutterCommandResult> verifyThenRunCommand() async {
    device = await findTargetDevice();
    if (device == null)
      throwToolExit('Must have a connected device');
    if (argResults[_kType] == _kDeviceType && !device.supportsScreenshot)
      throwToolExit('Screenshot not supported for ${device.name}.');
    if (argResults[_kType] != _kDeviceType && argResults[_kObservatoryPort] == null)
      throwToolExit('Observatory port must be specified for screenshot type ${argResults[_kType]}');
    return super.verifyThenRunCommand();
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    File outputFile;
    if (argResults.wasParsed(_kOut))
      outputFile = fs.file(argResults[_kOut]);

    switch (argResults[_kType]) {
      case _kDeviceType:
        await runScreenshot(outputFile);
        return null;
      case _kSkiaType:
        await runSkia(outputFile);
        return null;
      case _kRasterizerType:
        await runRasterizer(outputFile);
        return null;
    }

    return null;
  }

  Future<void> runScreenshot(File outputFile) async {
    outputFile ??= getUniqueFile(fs.currentDirectory, 'flutter', 'png');
    try {
      await device.takeScreenshot(outputFile);
    } catch (error) {
      throwToolExit('Error taking screenshot: $error');
    }
    await showOutputFileInfo(outputFile);
  }

  Future<void> runSkia(File outputFile) async {
    final Map<String, dynamic> skp = await _invokeVmServiceRpc('_flutter.screenshotSkp');
    outputFile ??= getUniqueFile(fs.currentDirectory, 'flutter', 'skp');
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(skp['skp']));
    await sink.close();
    await showOutputFileInfo(outputFile);
    await _ensureOutputIsNotJsonRpcError(outputFile);
  }

  Future<void> runRasterizer(File outputFile) async {
    final Map<String, dynamic> response = await _invokeVmServiceRpc('_flutter.screenshot');
    outputFile ??= getUniqueFile(fs.currentDirectory, 'flutter', 'png');
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(response['screenshot']));
    await sink.close();
    await showOutputFileInfo(outputFile);
    await _ensureOutputIsNotJsonRpcError(outputFile);
  }

  Future<Map<String, dynamic>> _invokeVmServiceRpc(String method) async {
    final Uri observatoryUri = Uri(scheme: 'http', host: '127.0.0.1',
        port: int.parse(argResults[_kObservatoryPort]));
    final VMService vmService = await VMService.connect(observatoryUri);
    return await vmService.vm.invokeRpcRaw(method);
  }

  Future<void> _ensureOutputIsNotJsonRpcError(File outputFile) async {
    if (await outputFile.length() < 1000) {
      final String content = await outputFile.readAsString(
        encoding: const AsciiCodec(allowInvalid: true),
      );
      if (content.startsWith('{"jsonrpc":"2.0", "error"'))
        throwToolExit('\nIt appears the output file contains an error message, not valid skia output.');
    }
  }

  Future<void> showOutputFileInfo(File outputFile) async {
    final int sizeKB = (await outputFile.length()) ~/ 1024;
    printStatus('Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).');
  }
}
