// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:vm_service_client/vm_service_client.dart';

import 'package:flutter_devicelab/framework/utils.dart';

/// Slightly longer than task timeout that gives the task runner a chance to
/// clean-up before forcefully quitting it.
const Duration taskTimeoutWithGracePeriod = Duration(minutes: 26);

/// Runs a task in a separate Dart VM and collects the result using the VM
/// service protocol.
///
/// [taskName] is the name of the task. The corresponding task executable is
/// expected to be found under `bin/tasks`.
///
/// Running the task in [silent] mode will suppress standard output from task
/// processes and only print standard errors.
Future<Map<String, dynamic>> runTask(String taskName, { bool silent = false }) async {
  final String taskExecutable = 'bin/tasks/$taskName.dart';

  if (!file(taskExecutable).existsSync())
    throw 'Executable Dart file not found: $taskExecutable';

  final Process runner = await startProcess(dartBin, <String>[
    '--enable-vm-service=0', // zero causes the system to choose a free port
    '--no-pause-isolates-on-exit',
    taskExecutable,
  ]);

  bool runnerFinished = false;

  runner.exitCode.whenComplete(() {
    runnerFinished = true;
  });

  final Completer<int> port = Completer<int>();

  final StreamSubscription<String> stdoutSub = runner.stdout
      .transform<String>(const Utf8Decoder())
      .transform<String>(const LineSplitter())
      .listen((String line) {
    if (!port.isCompleted) {
      final int portValue = parseServicePort(line, prefix: 'Observatory listening on ');
      if (portValue != null)
        port.complete(portValue);
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

  String waitingFor = 'connection';
  try {
    final VMIsolateRef isolate = await _connectToRunnerIsolate(await port.future);
    waitingFor = 'task completion';
    final Map<String, dynamic> taskResult =
        await isolate.invokeExtension('ext.cocoonRunTask').timeout(taskTimeoutWithGracePeriod);
    waitingFor = 'task process to exit';
    await runner.exitCode.timeout(const Duration(seconds: 60));
    return taskResult;
  } on TimeoutException catch (timeout) {
    runner.kill(ProcessSignal.sigint);
    return <String, dynamic>{
      'success': false,
      'reason': 'Timeout in runner.dart waiting for $waitingFor: ${timeout.message}',
    };
  } finally {
    if (!runnerFinished)
      runner.kill(ProcessSignal.sigkill);
    await cleanupSystem();
    await stdoutSub.cancel();
    await stderrSub.cancel();
  }
}

Future<VMIsolateRef> _connectToRunnerIsolate(int vmServicePort) async {
  final String url = 'ws://localhost:$vmServicePort/ws';
  final DateTime started = DateTime.now();

  // TODO(yjbanov): due to lack of imagination at the moment the handshake with
  //                the task process is very rudimentary and requires this small
  //                delay to let the task process open up the VM service port.
  //                Otherwise we almost always hit the non-ready case first and
  //                wait a whole 1 second, which is annoying.
  await Future<void>.delayed(const Duration(milliseconds: 100));

  while (true) {
    try {
      // Make sure VM server is up by successfully opening and closing a socket.
      await (await WebSocket.connect(url)).close();

      // Look up the isolate.
      final VMServiceClient client = VMServiceClient.connect(url);
      final VM vm = await client.getVM();
      final VMIsolateRef isolate = vm.isolates.single;
      final String response = await isolate.invokeExtension('ext.cocoonRunnerReady');
      if (response != 'ready')
        throw 'not ready yet';
      return isolate;
    } catch (error) {
      const Duration connectionTimeout = Duration(seconds: 10);
      if (DateTime.now().difference(started) > connectionTimeout) {
        throw TimeoutException(
          'Failed to connect to the task runner process',
          connectionTimeout,
        );
      }
      print('VM service not ready yet: $error');
      const Duration pauseBetweenRetries = Duration(milliseconds: 200);
      print('Will retry in $pauseBetweenRetries.');
      await Future<void>.delayed(pauseBetweenRetries);
    }
  }
}

Future<void> cleanupSystem() async {
  print('\n\nCleaning up system after task...');
  final String javaHome = await findJavaHome();
  if (javaHome != null) {
    // To shut gradle down, we have to call "gradlew --stop".
    // To call gradlew, we need to have a gradle-wrapper.properties file along
    // with a shell script, a .jar file, etc. We get these from various places
    // as you see in the code below, and we save them all into a temporary dir
    // which we can then delete after.
    // All the steps below are somewhat tolerant of errors, because it doesn't
    // really matter if this succeeds every time or not.
    print('\nTelling Gradle to shut down (JAVA_HOME=$javaHome)');
    final String gradlewBinaryName = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_devicelab_shutdown_gradle.');
    recursiveCopy(Directory(path.join(flutterDirectory.path, 'bin', 'cache', 'artifacts', 'gradle_wrapper')), tempDir);
    copy(File(path.join(path.join(flutterDirectory.path, 'packages', 'flutter_tools'), 'templates', 'app', 'android.tmpl', 'gradle', 'wrapper', 'gradle-wrapper.properties')), Directory(path.join(tempDir.path, 'gradle', 'wrapper')));
    if (!Platform.isWindows) {
      await exec(
        'chmod',
        <String>['a+x', path.join(tempDir.path, gradlewBinaryName)],
        canFail: true,
      );
    }
    await exec(
      path.join(tempDir.path, gradlewBinaryName),
      <String>['--stop'],
      environment: <String, String>{ 'JAVA_HOME': javaHome },
      workingDirectory: tempDir.path,
      canFail: true,
    );
    rmTree(tempDir);
    print('\n');
  } else {
    print('Could not determine JAVA_HOME; not shutting down Gradle.');
  }
}