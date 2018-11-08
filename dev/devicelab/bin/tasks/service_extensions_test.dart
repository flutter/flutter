// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:vm_service_client/vm_service_client.dart';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

void main() {
  task(() async {
    int vmServicePort;

    final Device device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    await inDirectory(appDir, () async {
      final Completer<void> ready = Completer<void>();
      bool ok;
      print('run: starting...');
      final Process run = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>['run', '--verbose', '-d', device.deviceId, 'lib/main.dart'],
      );
      run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
        print('run:stdout: $line');
        if (vmServicePort == null) {
          vmServicePort = parseServicePort(line);
          if (vmServicePort != null) {
            print('service protocol connection available at port $vmServicePort');
            print('run: ready!');
            ready.complete();
            ok ??= true;
          }
        }
      });
      run.stderr
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
        stderr.writeln('run:stderr: $line');
      });
      run.exitCode.then<void>((int exitCode) { ok = false; });
      await Future.any<dynamic>(<Future<dynamic>>[ ready.future, run.exitCode ]);
      if (!ok)
        throw 'Failed to run test app.';

      final VMServiceClient client = VMServiceClient.connect('ws://localhost:$vmServicePort/ws');
      final VM vm = await client.getVM();
      final VMIsolateRef isolate = vm.isolates.first;
      final Stream<VMExtensionEvent> frameEvents = isolate.onExtensionEvent.where(
              (VMExtensionEvent e) => e.kind == 'Flutter.Frame');
      final Stream<VMExtensionEvent> navigationEvents = isolate.onExtensionEvent.where(
              (VMExtensionEvent e) => e.kind == 'Flutter.Navigation');

      print('reassembling app...');
      final Future<VMExtensionEvent> frameFuture = frameEvents.first;
      await isolate.invokeExtension('ext.flutter.reassemble');

      // ensure we get an event
      final VMExtensionEvent event = await frameFuture;
      print('${event.kind}: ${event.data}');

      // validate the fields
      // {number: 8, startTime: 0, elapsed: 1437}
      expect(event.data['number'] is int);
      expect(event.data['number'] >= 0);
      expect(event.data['startTime'] is int);
      expect(event.data['startTime'] >= 0);
      expect(event.data['elapsed'] is int);
      expect(event.data['elapsed'] >= 0);

      final Future<VMExtensionEvent> navigationFuture = navigationEvents.first;
      // This tap triggers a navigation event.
      device.tap(100, 100);
      final VMExtensionEvent navigationEvent = await navigationFuture;
      // Validate that there are not any fields.
      expect(navigationEvent.data.isEmpty);

      run.stdin.write('q');
      final int result = await run.exitCode;
      if (result != 0)
        throw 'Received unexpected exit code $result from run process.';
    });
    return TaskResult.success(null);
  });
}

void expect(bool value) {
  if (!value)
    throw 'failed assertion in service extensions test';
}
