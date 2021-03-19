// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import 'adb.dart';
import 'cocoon.dart';
import 'task_result.dart';
import 'utils.dart';

Future<void> runTasks(
  List<String> taskNames, {
  bool exitOnFirstTestFailure = false,
  bool silent = false,
  String deviceId,
  String gitBranch,
  String localEngine,
  String localEngineSrcPath,
  String luciBuilder,
  String resultsPath,
  List<String> taskArgs,
}) async {
  for (final String taskName in taskNames) {
    section('Running task "$taskName"');
    final TaskResult result = await runTask(
      taskName,
      deviceId: deviceId,
      localEngine: localEngine,
      localEngineSrcPath: localEngineSrcPath,
      silent: silent,
      taskArgs: taskArgs,
    );

    print('Task result:');
    print(const JsonEncoder.withIndent('  ').convert(result));
    section('Finished task "$taskName"');

    if (resultsPath != null) {
      final Cocoon cocoon = Cocoon();
      await cocoon.writeTaskResultToFile(
        builderName: luciBuilder,
        gitBranch: gitBranch,
        result: result,
        resultsPath: resultsPath,
      );
    }

    if (!result.succeeded) {
      exitCode = 1;
      if (exitOnFirstTestFailure) {
        return;
      }
    }
  }
}

/// Runs a task in a separate Dart VM and collects the result using the VM
/// service protocol.
///
/// [taskName] is the name of the task. The corresponding task executable is
/// expected to be found under `bin/tasks`.
///
/// Running the task in [silent] mode will suppress standard output from task
/// processes and only print standard errors.
///
/// [taskArgs] are passed to the task executable for additional configuration.
Future<TaskResult> runTask(
  String taskName, {
  bool silent = false,
  String localEngine,
  String localEngineSrcPath,
  String deviceId,
  List<String> taskArgs,
  @visibleForTesting Map<String, String> isolateParams,
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
      ...?taskArgs,
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
    final ConnectionResult result = await _connectToRunnerIsolate(await uri.future);
    final Map<String, dynamic> taskResultJson = (await result.vmService.callServiceExtension(
      'ext.cocoonRunTask',
      args: isolateParams,
      isolateId: result.isolate.id,
    )).json;
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

Future<ConnectionResult> _connectToRunnerIsolate(Uri vmServiceUri) async {
  final List<String> pathSegments = <String>[
    // Add authentication code.
    if (vmServiceUri.pathSegments.isNotEmpty) vmServiceUri.pathSegments[0],
    'ws',
  ];
  final String url = vmServiceUri.replace(scheme: 'ws', pathSegments: pathSegments).toString();
  final Stopwatch stopwatch = Stopwatch()..start();

  while (true) {
    try {
      // Make sure VM server is up by successfully opening and closing a socket.
      await (await WebSocket.connect(url)).close();

      // Look up the isolate.
      final VmService client = await vmServiceConnectUri(url);
      VM vm = await client.getVM();
      while (vm.isolates.isEmpty) {
        await Future<void>.delayed(const Duration(seconds: 1));
        vm = await client.getVM();
      }
      final IsolateRef isolate = vm.isolates.first;
      final Response response = await client.callServiceExtension('ext.cocoonRunnerReady', isolateId: isolate.id);
      if (response.json['response'] != 'ready')
        throw 'not ready yet';
      return ConnectionResult(client, isolate);
    } catch (error) {
      if (stopwatch.elapsed > const Duration(seconds: 10))
        print('VM service still not ready after ${stopwatch.elapsed}: $error\nContinuing to retry...');
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }
}

class ConnectionResult {
  ConnectionResult(this.vmService, this.isolate);

  final VmService vmService;
  final IsolateRef isolate;
}

/// The cocoon client sends an invalid VM service response, we need to intercept it.
Future<VmService> vmServiceConnectUri(String wsUri, {Log log}) async {
  final WebSocket socket = await WebSocket.connect(wsUri);
  final StreamController<dynamic> controller = StreamController<dynamic>();
  final Completer<dynamic> streamClosedCompleter = Completer<dynamic>();
  socket.listen(
    (dynamic data) {
      final Map<String, dynamic> rawData = json.decode(data as String) as Map<String, dynamic> ;
      if (rawData['result'] == 'ready') {
        rawData['result'] = <String, dynamic>{'response': 'ready'};
        controller.add(json.encode(rawData));
      } else {
        controller.add(data);
      }
    },
    onError: (dynamic err, StackTrace stackTrace) => controller.addError(err, stackTrace),
    onDone: () => streamClosedCompleter.complete(),
  );

  return VmService(
    controller.stream,
    (String message) => socket.add(message),
    log: log,
    disposeHandler: () => socket.close(),
    streamClosed: streamClosedCompleter.future,
  );
}
