// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:vm_service_client/vm_service_client.dart';

import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/framework/adb.dart' show DeviceIdEnvName;

/// Runs a task in a separate Dart VM and collects the result using the VM
/// service protocol.
///
/// [taskName] is the name of the task. The corresponding task executable is
/// expected to be found under `bin/tasks`.
///
/// Running the task in [silent] mode will suppress standard output from task
/// processes and only print standard errors.
Future<Map<String, dynamic>> runTask(
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
    final Map<String, dynamic> taskResult = await isolate.invokeExtension('ext.cocoonRunTask') as Map<String, dynamic>;
    await runner.exitCode;
    return taskResult;
  } finally {
    if (!runnerFinished)
      runner.kill(ProcessSignal.sigkill);
    await cleanupSystem();
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
  // Removes the .gradle directory because sometimes gradle fails in downloading
  // a new version and leaves a corrupted zip archive, which could cause the
  // next devicelab task to fail.
  // https://github.com/flutter/flutter/issues/65277
  rmTree(dir('${Platform.environment['HOME']}/.gradle'));
}
