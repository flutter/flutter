// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart' as vms;
import 'package:vm_service/vm_service_io.dart' show vmServiceConnectUri;

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
        <String>['run', '--verbose', '--no-fast-start', '--disable-service-auth-codes', '-d', device.deviceId, 'lib/main.dart'],
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

      final vms.VmService client = await vmServiceConnectUri('ws://localhost:$vmServicePort/ws');
      final vms.VM vm = await client.getVM();
      final vms.IsolateRef isolate = vm.isolates.first;

      final Completer<vms.Event> frameEventCompleter = Completer<vms.Event>();
      final Completer<vms.Event> navigationEventCompleter = Completer<vms.Event>();
      await client.streamListen(vms.EventStreams.kExtension);
      client.onExtensionEvent.listen((vms.Event event) {
        if (event.extensionKind == 'Flutter.Frame' && !frameEventCompleter.isCompleted) {
          frameEventCompleter.complete(event);
        } else if (event.extensionKind == 'Flutter.Navigation' && !navigationEventCompleter.isCompleted) {
          navigationEventCompleter.complete(event);
        }
      });

      print('reassembling app...');
      await client.callServiceExtension('ext.flutter.reassemble', isolateId: isolate.id);

      // ensure we get an event
      final vms.Event event = await frameEventCompleter.future;
      print('${event.extensionKind}: ${event.extensionData.data}');

      // validate the fields
      // {number: 8, startTime: 0, elapsed: 1437, build: 600, raster: 800}
      expect(event.extensionData.data['number'] is int);
      expect((event.extensionData.data['number'] as int) >= 0);
      expect(event.extensionData.data['startTime'] is int);
      expect((event.extensionData.data['startTime'] as int) >= 0);
      expect(event.extensionData.data['elapsed'] is int);
      expect((event.extensionData.data['elapsed'] as int) >= 0);
      expect(event.extensionData.data['build'] is int);
      expect((event.extensionData.data['build'] as int) >= 0);
      expect(event.extensionData.data['raster'] is int);
      expect((event.extensionData.data['raster'] as int) >= 0);

      device.tap(100, 200);

      final vms.Event navigationEvent = await navigationEventCompleter.future;
      // validate the fields
      expect(navigationEvent.extensionData.data['route'] is Map<dynamic, dynamic>);
      final Map<dynamic, dynamic> route = navigationEvent.extensionData.data['route'] as Map<dynamic, dynamic>;
      expect(route['description'] is String);
      expect(route['settings'] is Map<dynamic, dynamic>);
      final Map<dynamic, dynamic> settings = route['settings'] as Map<dynamic, dynamic>;
      expect(settings.containsKey('name'));

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
