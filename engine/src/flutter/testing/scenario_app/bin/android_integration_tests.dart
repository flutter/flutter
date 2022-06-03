// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process/process.dart';

import 'utils/logs.dart';
import 'utils/process_manager_extension.dart';

const int tcpPort = 3001;

void main(List<String> args) async {
  const ProcessManager pm = LocalProcessManager();
  final ArgParser parser = ArgParser()
    ..addOption('adb', help: 'absolute path to the adb tool', mandatory: true)
    ..addOption('out-dir', help: 'out directory', mandatory: true);

  final ArgResults results = parser.parse(args);
  final Directory outDir = Directory(results['out-dir']);
  final File adb = File(results['adb']);

  if (!outDir.existsSync()) {
    panic(<String>['out-dir does not exist: $outDir', 'make sure to build the selected engine variant']);
  }

  if (!adb.existsSync()) {
    panic(<String>['cannot find adb: $adb', 'make sure to run gclient sync']);
  }

  final String apkOut = join(outDir.path, 'scenario_app', 'app', 'outputs', 'apk');
  final File testApk = File(join(apkOut, 'androidTest', 'debug', 'app-debug-androidTest.apk'));
  final File appApk = File(join(apkOut, 'debug', 'app-debug.apk'));

  if (!testApk.existsSync()) {
    panic(<String>['test apk does not exist: ${testApk.path}', 'make sure to build the selected engine variant']);
  }

  if (!appApk.existsSync()) {
    panic(<String>['app apk does not exist: ${appApk.path}', 'make sure to build the selected engine variant']);
  }

  // Start a TCP socket in the host, and forward it to the device that runs the tests.
  // This allows the test process to start a connection with the host, and write the bytes
  // for the screenshots.
  // On LUCI, the host uploads the screenshots to Skia Gold.
  late  ServerSocket server;
  await step('Starting server...', () async {
    server = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
    stdout.writeln('listening on host ${server.address.address}:${server.port}');
    server.listen((Socket client) {
      stdout.writeln('client connected ${client.remoteAddress.address}:${client.remotePort}');

      client.listen((Uint8List data) {
        final int fnameLen = data.buffer.asByteData().getInt32(0);
        final String fileName = utf8.decode(data.buffer.asUint8List(4, fnameLen));
        final Uint8List fileContent = data.buffer.asUint8List(4 + fnameLen);
        log('host received ${fileContent.lengthInBytes} bytes for screenshot `$fileName`');
      });
    });
  });

  late Process logcatProcess;
  final StringBuffer logcat = StringBuffer();
  try {
    await step('Starting logcat...', () async {
      logcatProcess = await pm.start(<String>[adb.path, 'logcat', '*:E', '-T', '1']);
      unawaited(pipeProcessStreams(logcatProcess, out: logcat));
    });

    await step('Reverse port...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'reverse', 'tcp:3000', 'tcp:$tcpPort']);
      if (exitCode != 0) {
        panic(<String>['could not forward port']);
      }
    });

    await step('Installing app APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'install', appApk.path]);
      if (exitCode != 0) {
        panic(<String>['could not install app apk']);
      }
    });

    await step('Installing test APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'install', testApk.path]);
      if (exitCode != 0) {
        panic(<String>['could not install test apk']);
      }
    });

    await step('Running instrumented tests...', () async {
      final int exitCode = await pm.runAndForward(<String>[
        adb.path,
        'shell',
        'am',
        'instrument',
        '-w', 'dev.flutter.scenarios.test/dev.flutter.TestRunner',
      ]);
      if (exitCode != 0) {
        panic(<String>['could not install test apk']);
      }
    });
  } finally {
    await server.close();

    await step('Remove reverse port...', () async {
      final int exitCode = await pm.runAndForward(<String>[
        adb.path,
        'reverse',
        '--remove', 'tcp:3000',
      ]);
      if (exitCode != 0) {
        panic(<String>['could not unforward port']);
      }
    });

    await step('Uinstalling app APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'uninstall', 'dev.flutter.scenarios']);
      if (exitCode != 0) {
        panic(<String>['could not uninstall app apk']);
      }
    });

    await step('Uinstalling test APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'uninstall', 'dev.flutter.scenarios.test']);
      if (exitCode != 0) {
        panic(<String>['could not uninstall app apk']);
      }
    });

    await step('Killing logcat process...', () async {
      logcatProcess.kill();
    });

    await step('Dumping logcat (Errors only)...', () async {
      stdout.write(logcat);
    });
  }
}
