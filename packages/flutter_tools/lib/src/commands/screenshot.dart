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
const String _kSkia = 'skia';

class ScreenshotCommand extends FlutterCommand {
  ScreenshotCommand() {
    argParser.addOption(
      _kOut,
      abbr: 'o',
      help: 'Location to write the screenshot.',
    );
    argParser.addOption(
      _kSkia,
      valueHelp: 'port',
      help: 'Retrieve the last frame rendered by a Flutter app as a Skia picture\n'
        'using the specified observatory port.\n'
        'To find the observatory port number, use "flutter run --verbose"\n'
        'and look for "Forwarded host port ... for Observatory" in the output.'
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
  Future<Null> verifyThenRunCommand() async {
    device = await findTargetDevice();
    if (device == null)
      throwToolExit('Must have a connected device');
    if (!device.supportsScreenshot && argResults[_kSkia] == null)
      throwToolExit('Screenshot not supported for ${device.name}.');
    return super.verifyThenRunCommand();
  }

  @override
  Future<Null> runCommand() async {
    File outputFile;
    if (argResults.wasParsed(_kOut))
      outputFile = fs.file(argResults[_kOut]);

    if (argResults[_kSkia] != null) {
      return runSkia(outputFile);
    } else {
      return runScreenshot(outputFile);
    }
  }

  Future<Null> runScreenshot(File outputFile) async {
    outputFile ??= getUniqueFile(fs.currentDirectory, 'flutter', 'png');
    try {
      await device.takeScreenshot(outputFile);
    } catch (error) {
      throwToolExit('Error taking screenshot: $error');
    }
    await showOutputFileInfo(outputFile);
  }

  Future<Null> runSkia(File outputFile) async {
    final Uri observatoryUri = new Uri(scheme: 'http', host: '127.0.0.1',
        port: int.parse(argResults[_kSkia]));
    final VMService vmService = await VMService.connect(observatoryUri);
    final Map<String, dynamic> skp = await vmService.vm.invokeRpcRaw('_flutter.screenshotSkp');

    outputFile ??= getUniqueFile(fs.currentDirectory, 'flutter', 'skp');
    final IOSink sink = outputFile.openWrite();
    sink.add(base64.decode(skp['skp']));
    await sink.close();
    await showOutputFileInfo(outputFile);
    if (await outputFile.length() < 1000) {
      final String content = await outputFile.readAsString(
        encoding: const AsciiCodec(allowInvalid: true),
      );
      if (content.startsWith('{"jsonrpc":"2.0", "error"'))
        throwToolExit('\nIt appears the output file contains an error message, not valid skia output.');
    }
  }

  Future<Null> showOutputFileInfo(File outputFile) async {
    final int sizeKB = (await outputFile.length()) ~/ 1024;
    printStatus('Screenshot written to ${fs.path.relative(outputFile.path)} (${sizeKB}kB).');
  }
}
