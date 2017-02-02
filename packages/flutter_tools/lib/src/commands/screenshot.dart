// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart' hide IOSink;
import '../base/utils.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

const String _kOut = 'out';
const String _kSkia = 'skia';
const String _kSkiaServe = 'skiaserve';

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
        'using the specified diagnostic server port.\n'
        'To find the diagnostic server port number, use "flutter run --verbose"\n'
        'and look for "Diagnostic server listening on" in the output.'
    );
    argParser.addOption(
      _kSkiaServe,
      valueHelp: 'url',
      help: 'Post the picture to a skiaserve debugger at this URL.',
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
    if (argResults[_kSkia] != null) {
      if (argResults[_kOut] != null && argResults[_kSkiaServe] != null)
        throwToolExit('Cannot specify both --$_kOut and --$_kSkiaServe');
    } else {
      if (argResults[_kSkiaServe] != null)
        throwToolExit('Must specify --$_kSkia with --$_kSkiaServe');
      device = await findTargetDevice();
      if (device == null)
        throwToolExit('Must specify --$_kSkia or have a connected device');
      if (!device.supportsScreenshot && argResults[_kSkia] == null)
        throwToolExit('Screenshot not supported for ${device.name}.');
    }
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
    Uri skpUri = new Uri(scheme: 'http', host: '127.0.0.1',
        port: int.parse(argResults[_kSkia]),
        path: '/skp');

    const String errorHelpText =
        'Be sure the --$_kSkia= option specifies the diagnostic server port, not the observatory port.\n'
        'To find the diagnostic server port number, use "flutter run --verbose"\n'
        'and look for "Diagnostic server listening on" in the output.';

    http.StreamedResponse skpResponse;
    try {
      skpResponse = await new http.Request('GET', skpUri).send();
    } on SocketException catch (e) {
      throwToolExit('Skia screenshot failed: $skpUri\n$e\n\n$errorHelpText');
    }
    if (skpResponse.statusCode != HttpStatus.OK) {
      String error = await skpResponse.stream.toStringStream().join();
      throwToolExit('Error: $error\n\n$errorHelpText');
    }

    if (argResults[_kSkiaServe] != null) {
      Uri skiaserveUri = Uri.parse(argResults[_kSkiaServe]);
      Uri postUri = new Uri.http(skiaserveUri.authority, '/new');
      http.MultipartRequest postRequest = new http.MultipartRequest('POST', postUri);
      postRequest.files.add(new http.MultipartFile(
          'file', skpResponse.stream, skpResponse.contentLength));

      http.StreamedResponse postResponse = await postRequest.send();
      if (postResponse.statusCode != HttpStatus.OK)
        throwToolExit('Failed to post Skia picture to skiaserve.\n\n$errorHelpText');
    } else {
      outputFile ??= getUniqueFile(fs.currentDirectory, 'flutter', 'skp');
      IOSink sink = outputFile.openWrite();
      await sink.addStream(skpResponse.stream);
      await sink.close();
      await showOutputFileInfo(outputFile);
      if (await outputFile.length() < 1000) {
        String content = await outputFile.readAsString();
        if (content.startsWith('{"jsonrpc":"2.0", "error"'))
          throwToolExit('\nIt appears the output file contains an error message, not valid skia output.\n\n$errorHelpText');
      }
    }
  }

  Future<Null> showOutputFileInfo(File outputFile) async {
    int sizeKB = (await outputFile.length()) ~/ 1024;
    printStatus('Screenshot written to ${path.relative(outputFile.path)} (${sizeKB}kB).');
  }
}
