// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/convert.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_utils.dart';

Future<int> getFreePort() async {
  int port = 0;
  final ServerSocket serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  port = serverSocket.port;
  await serverSocket.close();
  return port;
}

Future<void> waitForObservatoryMessage(Process process, int port) async {
  final Completer<void> completer = Completer<void>();
  process.stdout
    .transform(utf8.decoder)
    .listen((String line) {
      printOnFailure(line);
      if (line.contains('An Observatory debugger and profiler on Flutter test device is available at')) {
        if (line.contains('http://127.0.0.1:$port')) {
          completer.complete();
        } else {
          completer.completeError(Exception('Did not forward to provided port $port, instead found $line'));
        }
      }
    });
  process.stderr
    .transform(utf8.decoder)
    .listen(printOnFailure);
  return completer.future;
}

void main() {
  late Directory tempDir;
  final BasicProject project = BasicProject();

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    await project.setUpIn(tempDir);
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext('flutter run --observatory-port', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final int port = await getFreePort();
    // If only --observatory-port is provided, --observatory-port will be used by DDS
    // and the VM service will bind to a random port.
    final Process process = await processManager.start(<String>[
      flutterBin,
      'run',
      '--show-test-device',
      '--observatory-port=$port',
      '-d',
      'flutter-tester',
    ], workingDirectory: tempDir.path);
    await waitForObservatoryMessage(process, port);
    process.kill();
    await process.exitCode;
  });

  testWithoutContext('flutter run --dds-port --observatory-port', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final int observatoryPort = await getFreePort();
    int ddsPort = await getFreePort();
    while(ddsPort == observatoryPort) {
      ddsPort = await getFreePort();
    }
    // If both --dds-port and --observatory-port are provided, --dds-port will be used by
    // DDS and --observatory-port will be used by the VM service.
    final Process process = await processManager.start(<String>[
      flutterBin,
      'run',
      '--show-test-device',
      '--observatory-port=$observatoryPort',
      '--dds-port=$ddsPort',
      '-d',
      'flutter-tester',
    ], workingDirectory: tempDir.path);
    await waitForObservatoryMessage(process, ddsPort);
    process.kill();
    await process.exitCode;
  });

  testWithoutContext('flutter run --dds-port', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final int ddsPort = await getFreePort();
    // If only --dds-port is provided, --dds-port will be used by DDS and the VM service
    // will bind to a random port.
    final Process process = await processManager.start(<String>[
      flutterBin,
      'run',
      '--show-test-device',
      '--dds-port=$ddsPort',
      '-d',
      'flutter-tester',
    ], workingDirectory: tempDir.path);
    await waitForObservatoryMessage(process, ddsPort);
    process.kill();
    await process.exitCode;
  });

}
