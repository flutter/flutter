// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

late Uri remoteVmServiceUri;

Future<Process> spawnDartProcess(String script) async {
  final executable = Platform.executable;
  final tmpDir = await Directory.systemTemp.createTemp('dart_service');
  final serviceInfoUri = tmpDir.uri.resolve('service_info.json');
  final serviceInfoFile = await File.fromUri(serviceInfoUri).create();

  final arguments = [
    '--disable-dart-dev',
    '--observe=0',
    '--disable-service-auth-codes',
    '--write-service-info=$serviceInfoUri',
    ...Platform.executableArguments,
    Platform.script.resolve(script).toString(),
  ];
  final process = await Process.start(executable, arguments);
  process.stdout
      .transform(utf8.decoder)
      .listen((line) => print('TESTEE OUT: $line'));
  process.stderr
      .transform(utf8.decoder)
      .listen((line) => print('TESTEE ERR: $line'));
  while ((await serviceInfoFile.length()) <= 5) {
    await Future.delayed(const Duration(milliseconds: 50));
  }
  final content = await serviceInfoFile.readAsString();
  final infoJson = json.decode(content);
  remoteVmServiceUri =
      Uri.parse(infoJson['uri']).replace(scheme: 'ws', path: 'ws');
  return process;
}

Future<void> waitForRunnableIsolate(VmService service, Isolate isolate) async {
  bool runnable = isolate.runnable!;
  while (!runnable) {
    await Future.delayed(const Duration(milliseconds: 100));
    runnable = (await service.getIsolate(isolate.id!)).runnable!;
  }
}

void main() {
  group('VM Service', () {
    late Process process;

    setUp(() async {
      process =
          await spawnDartProcess('external_compilation_service_script.dart');
    });

    tearDown(() async {
      process.kill();
    });

    test('evaluate invokes client provided compileExpression RPC', () async {
      final service = await vmServiceConnectUri(remoteVmServiceUri.toString());
      await service.registerService(
        'compileExpression',
        'Custom Expression Compilation',
      );
      bool invokedCompileExpression = false;
      service.registerServiceCallback('compileExpression', (params) async {
        invokedCompileExpression = true;
        throw 'error';
      });
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates!.first.id!);
      await waitForRunnableIsolate(service, isolate);
      try {
        await service.evaluate(
            isolate.id!, isolate.libraries!.first.id!, '1 + 1');
      } catch (_) {
        // ignore error
      }
      expect(invokedCompileExpression, true);
    });

    test('evaluateInFrame invokes client provided compileExpression RPC',
        () async {
      final service = await vmServiceConnectUri(remoteVmServiceUri.toString());
      await service.registerService(
        'compileExpression',
        'Custom Expression Compilation',
      );
      bool invokedCompileExpression = false;
      service.registerServiceCallback('compileExpression', (params) async {
        invokedCompileExpression = true;
        throw 'error';
      });
      final vm = await service.getVM();
      final isolate = await service.getIsolate(vm.isolates!.first.id!);
      await waitForRunnableIsolate(service, isolate);
      try {
        await service.evaluateInFrame(isolate.id!, 0, '1 + 1');
      } catch (e) {
        // ignore error
      }
      expect(invokedCompileExpression, true);
    });
  });
}
