// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dds/dds.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service_io.dart';
import 'common/test_helper.dart';

void main() {
  group('DDS', () {
    late Process process;
    late DartDevelopmentService dds;

    setUp(() async {
      process =
          await spawnDartProcess('external_compilation_service_script.dart');
    });

    tearDown(() async {
      await dds.shutdown();
      process.kill();
    });

    test('evaluate invokes client provided compileExpression RPC', () async {
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);
      final service = await vmServiceConnectUri(dds.wsUri.toString());
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
      dds = await DartDevelopmentService.startDartDevelopmentService(
        remoteVmServiceUri,
      );
      expect(dds.isRunning, true);
      final service = await vmServiceConnectUri(dds.wsUri.toString());
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
      await service.resume(isolate.id!);
      try {
        await service.evaluateInFrame(isolate.id!, 0, '1 + 1');
      } catch (e, st) {
        print(e);
        print(st);
        // ignore error
      }
      expect(invokedCompileExpression, true);
    });
  });
}
