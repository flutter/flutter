import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

const String _kActivityId = 'io.flutter.examples.named_isolates/com.example.view.MainActivity';
const String _kFirstIsolateName = 'first isolate name';
const String _kSecondIsolateName = 'second isolate name';

void main() {
  task(() async {
    final AndroidDevice device = await devices.workingDevice;
    await device.unlock();

    section('Compile and run the tester app');
    Completer<void> firstNameFound = Completer<void>();
    Completer<void> secondNameFound = Completer<void>();
    final Process runProcess = await _run(device: device, command: <String>['run'], stdoutListener: (String line) {
      if (line.contains(_kFirstIsolateName)) {
        firstNameFound.complete();
      } else if (line.contains(_kSecondIsolateName)) {
        secondNameFound.complete();
      }
    });

    section('Verify all the debug isolate names are set');
    runProcess.stdin.write('l');
    await Future.wait<dynamic>(<Future<dynamic>>[firstNameFound.future, secondNameFound.future])
                .timeout(const Duration(seconds: 1), onTimeout: () => throw 'Isolate names not found.');
    await _quitRunner(runProcess);

    section('Attach to the second debug isolate');
    firstNameFound = Completer<void>();
    secondNameFound = Completer<void>();
    final String currentTime = (await device.shellEval('date', <String>['"+%F %R:%S.000"'])).trim();
    await device.shellExec('am', <String>['start', '-n', _kActivityId]);
    final String observatoryLine = await device.adb(<String>['logcat', '-e', 'Observatory listening on http:', '-m', '1', '-T', currentTime]);
    print('Found observatory line: $observatoryLine');
    final String observatoryPort = RegExp(r'Observatory listening on http://.*:([0-9]+)').firstMatch(observatoryLine)[1];
    print('Extracted observatory port: $observatoryPort');
    final Process attachProcess =
      await _run(device: device, command: <String>['attach', '--debug-port', observatoryPort, '--isolate-filter', '$_kSecondIsolateName'], stdoutListener: (String line) {
        if (line.contains(_kFirstIsolateName)) {
          firstNameFound.complete();
        } else if (line.contains(_kSecondIsolateName)) {
          secondNameFound.complete();
        }
      });
    attachProcess.stdin.write('l');
    await secondNameFound.future;
    if (firstNameFound.isCompleted)
      throw '--isolate-filter failed to attach to a specific isolate';
    await _quitRunner(attachProcess);

    return TaskResult.success(null);
  });
}

Future<Process> _run({@required Device device, @required List<String> command, @required Function(String) stdoutListener}) async {
  final Directory appDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/named_isolates'));
  Process runner;
  bool observatoryConnected = false;
  await inDirectory(appDir, () async {
  runner = await startProcess(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['--suppress-analytics', '-d', device.deviceId] + command,
      isBot: false, // we just want to test the output, not have any debugging info
    );
    final StreamController<String> stdout = StreamController<String>.broadcast();

    // Mirror output to stdout, listen for ready message
    final Completer<void> appReady = Completer<void>();
    runner.stdout
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        print('run:stdout: $line');
        stdout.add(line);
        if (parseServicePort(line) != null) {
          appReady.complete();
          observatoryConnected = true;
        }
        stdoutListener(line);
      });
    runner.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) {
        stderr.writeln('run:stderr: $line');
      });

    // Wait for either the process to fail or for the run to begin.
    await Future.any<dynamic>(<Future<dynamic>>[ appReady.future, runner.exitCode ]);
    if (!observatoryConnected)
      throw 'Failed to find service port when running `${command.join(' ')}`';
  });
  return runner;
}

Future<void> _quitRunner(Process runner) async {
  runner.stdin.write('q');
  final int result = await runner.exitCode;
  if (result != 0)
    throw 'Received unexpected exit code $result when quitting process.';
}
