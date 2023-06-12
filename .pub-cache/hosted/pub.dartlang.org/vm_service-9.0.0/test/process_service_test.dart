// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

Future setupProcesses() async {
  final dir = await io.Directory.systemTemp.createTemp('file_service');

  final args = [
    ...io.Platform.executableArguments,
    '--pause_isolates_on_start',
    io.Platform.script.toFilePath(),
  ];
  io.Process? process1;
  io.Process? process2;
  io.Process? process3;

  void closeDown() {
    if (process1 != null) {
      process1!.kill();
    }
    if (process2 != null) {
      process2!.kill();
    }
    if (process3 != null) {
      process3!.kill();
    }
    dir.deleteSync(recursive: true);
  }

  Future<ServiceExtensionResponse> cleanup(ignored_a, ignored_b) {
    closeDown();
    final result = jsonEncode({'type': 'foobar'});
    return Future.value(ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> setup(ignored_a, ignored_b) async {
    try {
      process1 = await io.Process.start(io.Platform.resolvedExecutable, args);
      process2 = await io.Process.start(
        io.Platform.resolvedExecutable,
        args..add('foobar'),
      );
      final codeFilePath = dir.path + io.Platform.pathSeparator + "other_file";
      final codeFile = io.File(codeFilePath);
      await codeFile.writeAsString('''
          import "dart:io";

          void main() async {
            await stdin.drain();
          }
          ''');
      process3 = await io.Process.start(
        io.Platform.resolvedExecutable,
        [
          ...io.Platform.executableArguments,
          codeFilePath,
        ],
      );
    } catch (_) {
      closeDown();
      rethrow;
    }

    final result = jsonEncode({
      'type': 'foobar',
      'pids': [process1!.pid, process2!.pid, process3!.pid]
    });
    return Future.value(ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> closeStdin(ignored_a, ignored_b) {
    process3!.stdin.close();
    return process3!.exitCode.then<ServiceExtensionResponse>((int exit) {
      final result = jsonEncode({'type': 'foobar'});
      return ServiceExtensionResponse.result(result);
    });
  }

  registerExtension('ext.dart.io.cleanup', cleanup);
  registerExtension('ext.dart.io.setup', setup);
  registerExtension('ext.dart.io.closeStdin', closeStdin);
}

final processTests = <IsolateTest>[
  // Initial.
  (VmService service, IsolateRef isolate) async {
    final isolateId = isolate.id!;
    final setup = await service.callServiceExtension(
      'ext.dart.io.setup',
      isolateId: isolateId,
    );
    try {
      SpawnedProcessList all = await service.getSpawnedProcesses(isolateId);
      expect(all.processes.length, equals(3));

      final first = await service.getSpawnedProcessById(
        isolateId,
        all.processes[0].id,
      );

      expect(io.Platform.resolvedExecutable, contains(first.name.trim()));
      expect(first.pid, equals(setup.json!['pids']![0]));
      expect(first.arguments.contains('foobar'), isFalse);
      expect(first.startedAt, greaterThan(0));

      final second = await service.getSpawnedProcessById(
        isolateId,
        all.processes[1].id,
      );

      expect(io.Platform.resolvedExecutable, contains(second.name.trim()));
      expect(second.pid, equals(setup.json!['pids']![1]));
      expect(second.arguments.contains('foobar'), isTrue);
      expect(second.pid != first.pid, isTrue);
      expect(second.startedAt, greaterThan(0));
      expect(second.startedAt, greaterThanOrEqualTo(first.startedAt));

      final third = await service.getSpawnedProcessById(
        isolateId,
        all.processes[2].id,
      );

      expect(io.Platform.resolvedExecutable, contains(third.name.trim()));
      expect(third.pid, equals(setup.json!['pids']![2]));
      expect(third.pid != first.pid, isTrue);
      expect(third.pid != second.pid, isTrue);
      expect(third.startedAt, greaterThanOrEqualTo(second.startedAt));

      await service.callServiceExtension(
        'ext.dart.io.closeStdin',
        isolateId: isolateId,
      );
      all = await service.getSpawnedProcesses(isolateId);
      expect(all.processes.length, equals(2));
    } finally {
      await service.callServiceExtension(
        'ext.dart.io.cleanup',
        isolateId: isolateId,
      );
    }
  },
];

main([args = const <String>[]]) async => runIsolateTests(
      args,
      processTests,
      'process_service_test.dart',
      testeeBefore: setupProcesses,
    );
