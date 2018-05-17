// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vm_service_client/vm_service_client.dart';

import 'package:flutter_devicelab/framework/utils.dart';

/// Slightly longer than task timeout that gives the task runner a chance to
/// clean-up before forcefully quitting it.
const Duration taskTimeoutWithGracePeriod = const Duration(minutes: 26);

/// Runs a task in a separate Dart VM and collects the result using the VM
/// service protocol.
///
/// [taskName] is the name of the task. The corresponding task executable is
/// expected to be found under `bin/tasks`.
///
/// Running the task in [silent] mode will suppress standard output from task
/// processes and only print standard errors.
Future<Map<String, dynamic>> runTask(String taskName, { bool silent: false }) async {
  final String taskExecutable = 'bin/tasks/$taskName.dart';

  if (!file(taskExecutable).existsSync())
    throw 'Executable Dart file not found: $taskExecutable';

  final int vmServicePort = await findAvailablePort();
  final Process runner = await startProcess(dartBin, <String>[
    '--enable-vm-service=$vmServicePort',
    '--no-pause-isolates-on-exit',
    taskExecutable,
  ]);

  bool runnerFinished = false;

  runner.exitCode.whenComplete(() {
    runnerFinished = true;
  });

  final StreamSubscription<String> stdoutSub = runner.stdout
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((String line) {
    if (!silent) {
      stdout.writeln('[$taskName] [STDOUT] $line');
    }
  });

  final StreamSubscription<String> stderrSub = runner.stderr
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((String line) {
    stderr.writeln('[$taskName] [STDERR] $line');
  });

  String waitingFor = 'connection';
  try {
    final VMIsolateRef isolate = await _connectToRunnerIsolate(vmServicePort);
    waitingFor = 'task completion';
    final Map<String, dynamic> taskResult =
        await isolate.invokeExtension('ext.cocoonRunTask').timeout(taskTimeoutWithGracePeriod);
    waitingFor = 'task process to exit';
    await runner.exitCode.timeout(const Duration(seconds: 1));
    return taskResult;
  } on TimeoutException catch (timeout) {
    runner.kill(ProcessSignal.SIGINT); // ignore: deprecated_member_use
    return <String, dynamic>{
      'success': false,
      'reason': 'Timeout waiting for $waitingFor: ${timeout.message}',
    };
  } finally {
    if (!runnerFinished)
      runner.kill(ProcessSignal.SIGKILL); // ignore: deprecated_member_use
    await stdoutSub.cancel();
    await stderrSub.cancel();
  }
}

Future<VMIsolateRef> _connectToRunnerIsolate(int vmServicePort) async {
  final String url = 'ws://localhost:$vmServicePort/ws';
  final DateTime started = new DateTime.now();

  // TODO(yjbanov): due to lack of imagination at the moment the handshake with
  //                the task process is very rudimentary and requires this small
  //                delay to let the task process open up the VM service port.
  //                Otherwise we almost always hit the non-ready case first and
  //                wait a whole 1 second, which is annoying.
  await new Future<Null>.delayed(const Duration(milliseconds: 100));

  while (true) {
    try {
      // Make sure VM server is up by successfully opening and closing a socket.
      await (await WebSocket.connect(url)).close();

      // Look up the isolate.
      final VMServiceClient client = new VMServiceClient.connect(url);
      final VM vm = await client.getVM();
      final VMIsolateRef isolate = vm.isolates.single;
      final String response = await isolate.invokeExtension('ext.cocoonRunnerReady');
      if (response != 'ready')
        throw 'not ready yet';
      return isolate;
    } catch (error) {
      const Duration connectionTimeout = const Duration(seconds: 2);
      if (new DateTime.now().difference(started) > connectionTimeout) {
        throw new TimeoutException(
          'Failed to connect to the task runner process',
          connectionTimeout,
        );
      }
      print('VM service not ready yet: $error');
      const Duration pauseBetweenRetries = const Duration(milliseconds: 200);
      print('Will retry in $pauseBetweenRetries.');
      await new Future<Null>.delayed(pauseBetweenRetries);
    }
  }
}
