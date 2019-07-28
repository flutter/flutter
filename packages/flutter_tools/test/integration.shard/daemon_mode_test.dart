// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Integration tests which invoke flutter instead of unit testing the code
// will not produce meaningful coverage information - we can measure coverage
// from the isolate running the test, but not from the isolate started via
// the command line process.
@Tags(<String>['no_coverage'])
import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import 'test_data/basic_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  group('daemon_mode', () {
    Directory tempDir;
    final BasicProject _project = BasicProject();
    Process process;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('daemon_mode_test.');
      await _project.setUpIn(tempDir);
    });

    tearDown(() async {
      tryToDelete(tempDir);
      process?.kill();
    });

    test('device.getDevices', () async {
      final String flutterBin =
          fs.path.join(getFlutterRoot(), 'bin', 'flutter');

      const ProcessManager processManager = LocalProcessManager();
      process = await processManager.start(
          <String>[flutterBin, '--show-test-device', 'daemon'],
          workingDirectory: tempDir.path);

      final StreamController<String> stdout =
          StreamController<String>.broadcast();

      transformToLines(process.stdout)
          .listen((String line) => stdout.add(line));

      final Stream<Map<String, dynamic>> stream =
        stdout.stream.where((String line) {
          final Map<String, dynamic> response = parseFlutterResponse(line);
          // ignore 'Starting device daemon...'
          if (response == null) {
            return false;
          }
          // TODO(devoncarew): Remove this after #25440 lands.
          if (response['event'] == 'daemon.showMessage') {
            return false;
          }
          return true;
        }).map(parseFlutterResponse);

      Map<String, dynamic> response = await stream.first;
      expect(response['event'], 'daemon.connected');

      // start listening for devices
      process.stdin.writeln('[${jsonEncode(<String, dynamic>{
        'id': 1,
        'method': 'device.enable',
      })}]');
      response = await stream.first;
      expect(response['id'], 1);
      expect(response['error'], isNull);

      // [{"event":"device.added","params":{"id":"flutter-tester","name":
      //   "Flutter test device","platform":"flutter-tester","emulator":false}}]
      response = await stream.first;
      expect(response['event'], 'device.added');

      // get the list of all devices
      process.stdin.writeln('[${jsonEncode(<String, dynamic>{
        'id': 2,
        'method': 'device.getDevices',
      })}]');
      response = await stream.first;
      expect(response['id'], 2);
      expect(response['error'], isNull);

      final dynamic result = response['result'];
      expect(result, isList);
      expect(result, isNotEmpty);
    });
  }, timeout: const Timeout.factor(10), tags: <String>['integration']); // This test uses the `flutter` tool, which could be blocked behind the startup lock for a long time.
}
