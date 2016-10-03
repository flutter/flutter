// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../globals.dart';
import '../runner/flutter_command.dart';

class SkiaCommand extends FlutterCommand {
  SkiaCommand() {
    argParser.addOption('output-file', help: 'Write the Skia picture file to this path.');
    argParser.addOption('skiaserve', help: 'Post the picture to a skiaserve debugger at this URL.');
    argParser.addOption('diagnostic-port',
        help: 'Local port where the diagnostic server is listening.');
  }

  @override
  final String name = 'skia';

  @override
  final String description = 'Retrieve the last frame rendered by a Flutter app as a Skia picture.';

  @override
  Future<int> verifyThenRunCommand() async {
    if (!commandValidator())
      return 1;
    return super.verifyThenRunCommand();
  }

  @override
  Future<int> runCommand() async {
    File outputFile;
    Uri skiaserveUri;
    if (argResults['output-file'] != null) {
      outputFile = new File(argResults['output-file']);
    } else if (argResults['skiaserve'] != null) {
      skiaserveUri = Uri.parse(argResults['skiaserve']);
    } else {
      printError('Must provide --output-file or --skiaserve');
      return 1;
    }
    if (argResults['diagnostic-port'] == null) {
      printError('Must provide --diagnostic-port');
      return 1;
    }

    Uri skpUri = new Uri(scheme: 'http', host: '127.0.0.1',
        port: int.parse(argResults['diagnostic-port']),
        path: '/skp');

    http.Request skpRequest = new http.Request('GET', skpUri);
    http.StreamedResponse skpResponse = await skpRequest.send();
    if (skpResponse.statusCode != HttpStatus.OK) {
      String error = await skpResponse.stream.toStringStream().join();
      printError('Error: $error');
      return 1;
    }

    if (outputFile != null) {
      IOSink sink = outputFile.openWrite();
      await sink.addStream(skpResponse.stream);
      await sink.close();
    } else if (skiaserveUri != null) {
      Uri postUri = new Uri.http(skiaserveUri.authority, '/new');
      http.MultipartRequest postRequest = new http.MultipartRequest('POST', postUri);
      postRequest.files.add(new http.MultipartFile(
          'file', skpResponse.stream, skpResponse.contentLength));

      http.StreamedResponse postResponse = await postRequest.send();
      if (postResponse.statusCode != HttpStatus.OK) {
        printError('Failed to post Skia picture to skiaserve');
        return 1;
      }
    }

    return 0;
  }
}
