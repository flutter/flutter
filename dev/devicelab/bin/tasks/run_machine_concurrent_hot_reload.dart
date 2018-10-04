// Copyright (c) 2018 The Chromium Authors. All rights reserved.
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
  Map<String, dynamic> parseFlutterResponse(String line) {
    if (line.startsWith('[') && line.endsWith(']')) {
      try {
        return json.decode(line)[0];
      } catch (e) {
        // Not valid JSON, so likely some other output that was surrounded by [brackets]
        return null;
      }
    }
    return null;
  }

  Stream<String> transformToLines(Stream<List<int>> byteStream) {
    return byteStream.transform<String>(utf8.decoder).transform<String>(const LineSplitter());
  }

  task(() async {
    int vmServicePort;
    String appId;

    final Device device = await devices.workingDevice;
    await device.unlock();
    final Directory appDir =
        dir(path.join(flutterDirectory.path, 'dev/integration_tests/ui'));
    await inDirectory(appDir, () async {
      final Completer<void> ready = Completer<void>();
      bool ok;
      print('run: starting...');
      final Process run = await startProcess(
        path.join(flutterDirectory.path, 'bin', 'flutter'),
        <String>[
          'run',
          '--machine',
          '--verbose',
          '-d',
          device.deviceId,
          'lib/commands.dart'
        ],
      );
      final StreamController<String> stdout =
          StreamController<String>.broadcast();
      transformToLines(run.stdout).listen((String line) {
        print('run:stdout: $line');
        stdout.add(line);
        final dynamic json = parseFlutterResponse(line);
        if (json != null && json['event'] == 'app.debugPort') {
          vmServicePort = Uri.parse(json['params']['wsUri']).port;
          print('service protocol connection available at port $vmServicePort');
        } else if (json != null && json['event'] == 'app.started') {
          appId = json['params']['appId'];
        }
        if (vmServicePort != null && appId != null && !ready.isCompleted) {
          print('run: ready!');
          ready.complete();
          ok ??= true;
        }
      });
      transformToLines(run.stderr).listen((String line) {
        stderr.writeln('run:stderr: $line');
      });
      run.exitCode.then<void>((int exitCode) {
        ok = false;
      });
      await Future.any<dynamic>(<Future<dynamic>>[ready.future, run.exitCode]);
      if (!ok)
        throw 'Failed to run test app.';

      final VMServiceClient client =
          VMServiceClient.connect('ws://localhost:$vmServicePort/ws');

      int id = 1;
      Future<Map<String, dynamic>> sendRequest(
          String method, dynamic params) async {
        final int requestId = id++;
        final Completer<Map<String, dynamic>> response =
            Completer<Map<String, dynamic>>();
        final StreamSubscription<String> responseSubscription =
            stdout.stream.listen((String line) {
          final Map<String, dynamic> json = parseFlutterResponse(line);
          if (json != null && json['id'] == requestId)
            response.complete(json);
        });
        final Map<String, dynamic> req = <String, dynamic>{
          'id': requestId,
          'method': method,
          'params': params
        };
        final String jsonEncoded = json.encode(<Map<String, dynamic>>[req]);
        print('run:stdin: $jsonEncoded');
        run.stdin.writeln(jsonEncoded);
        final Map<String, dynamic> result = await response.future;
        responseSubscription.cancel();
        return result;
      }

      print('test: sending two hot reloads...');
      final Future<dynamic> hotReload1 = sendRequest('app.restart',
          <String, dynamic>{'appId': appId, 'fullRestart': false});
      final Future<dynamic> hotReload2 = sendRequest('app.restart',
          <String, dynamic>{'appId': appId, 'fullRestart': false});
      final Future<List<dynamic>> reloadRequests =
          Future.wait<dynamic>(<Future<dynamic>>[hotReload1, hotReload2]);
      final dynamic results = await Future
          .any<dynamic>(<Future<dynamic>>[run.exitCode, reloadRequests]);

      if (!ok)
        throw 'App crashed during hot reloads.';

      final List<dynamic> responses = results;
      final List<dynamic> errorResponses =
          responses.where((dynamic r) => r['error'] != null).toList();
      final List<dynamic> successResponses = responses
          .where((dynamic r) =>
              r['error'] == null &&
              r['result'] != null &&
              r['result']['code'] == 0)
          .toList();

      if (errorResponses.length != 1)
        throw 'Did not receive the expected (exactly one) hot reload error response.';
      final String errorMessage = errorResponses.first['error'];
      if (!errorMessage.contains('in progress'))
        throw 'Error response was not that hot reload was in progress.';
      if (successResponses.length != 1)
        throw 'Did not receive the expected (exactly one) successful hot reload response.';

      final dynamic hotReload3 = await sendRequest('app.restart',
          <String, dynamic>{'appId': appId, 'fullRestart': false});
      if (hotReload3['error'] != null)
        throw 'Received an error response from a hot reload after all other hot reloads had completed.';

      sendRequest('app.stop', <String, dynamic>{'appId': appId});
      final int result = await run.exitCode;
      if (result != 0)
        throw 'Received unexpected exit code $result from run process.';
      print('test: validating that the app has in fact closed...');
      await client.done.timeout(const Duration(seconds: 5));
    });
    return TaskResult.success(null);
  });
}
