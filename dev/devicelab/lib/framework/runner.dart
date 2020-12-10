// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vm_service_client/vm_service_client.dart';

import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/framework/adb.dart';

import 'task_result.dart';

/// Runs a task in a separate Dart VM and collects the result using the VM
/// service protocol.
///
/// [taskName] is the name of the task. The corresponding task executable is
/// expected to be found under `bin/tasks`.
///
/// Running the task in [silent] mode will suppress standard output from task
/// processes and only print standard errors.
Future<TaskResult> runTask(
  String taskName, {
  bool silent = false,
  String localEngine,
  String localEngineSrcPath,
  String deviceId,
}) async {
  final String taskExecutable = 'bin/tasks/$taskName.dart';

  if (!file(taskExecutable).existsSync())
    throw 'Executable Dart file not found: $taskExecutable';

  final Process runner = await startProcess(
    dartBin,
    <String>[
      '--disable-dart-dev',
      '--enable-vm-service=0', // zero causes the system to choose a free port
      '--no-pause-isolates-on-exit',
      if (localEngine != null) '-DlocalEngine=$localEngine',
      if (localEngineSrcPath != null) '-DlocalEngineSrcPath=$localEngineSrcPath',
      taskExecutable,
    ],
    environment: <String, String>{
      if (deviceId != null)
        DeviceIdEnvName: deviceId,
    },
  );

  bool runnerFinished = false;

  runner.exitCode.whenComplete(() {
    runnerFinished = true;
  });

  final Completer<Uri> uri = Completer<Uri>();

  final StreamSubscription<String> stdoutSub = runner.stdout
      .transform<String>(const Utf8Decoder())
      .transform<String>(const LineSplitter())
      .listen((String line) {
    if (!uri.isCompleted) {
      final Uri serviceUri = parseServiceUri(line, prefix: 'Observatory listening on ');
      if (serviceUri != null)
        uri.complete(serviceUri);
    }
    if (!silent) {
      stdout.writeln('[$taskName] [STDOUT] $line');
    }
  });

  final StreamSubscription<String> stderrSub = runner.stderr
      .transform<String>(const Utf8Decoder())
      .transform<String>(const LineSplitter())
      .listen((String line) {
    stderr.writeln('[$taskName] [STDERR] $line');
  });

  try {
    final VMIsolateRef isolate = await _connectToRunnerIsolate(await uri.future);
    final Map<String, dynamic> taskResultJson = await isolate.invokeExtension('ext.cocoonRunTask') as Map<String, dynamic>;
    final TaskResult taskResult = TaskResult.fromJson(taskResultJson);
    await runner.exitCode;
    return taskResult;
  } finally {
    if (!runnerFinished)
      runner.kill(ProcessSignal.sigkill);
    await stdoutSub.cancel();
    await stderrSub.cancel();
  }
}

Future<VMIsolateRef> _connectToRunnerIsolate(Uri vmServiceUri) async {
  final List<String> pathSegments = <String>[
    // Add authentication code.
    if (vmServiceUri.pathSegments.isNotEmpty) vmServiceUri.pathSegments[0],
    'ws',
  ];
  final String url = vmServiceUri.replace(scheme: 'ws', pathSegments:
      pathSegments).toString();
  final Stopwatch stopwatch = Stopwatch()..start();

  while (true) {
    try {
      // Make sure VM server is up by successfully opening and closing a socket.
      await (await WebSocket.connect(url)).close();

      // Look up the isolate.
      final VMServiceClient client = VMServiceClient.connect(url);
      final VM vm = await client.getVM();
      final VMIsolateRef isolate = vm.isolates.single;
      final String response = await isolate.invokeExtension('ext.cocoonRunnerReady') as String;
      if (response != 'ready')
        throw 'not ready yet';
      return isolate;
    } catch (error) {
      if (stopwatch.elapsed > const Duration(seconds: 10))
        print('VM service still not ready after ${stopwatch.elapsed}: $error\nContinuing to retry...');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}
