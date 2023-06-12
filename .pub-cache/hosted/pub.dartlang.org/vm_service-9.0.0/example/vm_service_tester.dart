// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_tester;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

final String host = 'localhost';
final int port = 7575;

late VmService serviceClient;

void main() {
  Process? process;

  tearDown(() {
    process?.kill();
  });

  test('integration', () async {
    String sdk = path.dirname(path.dirname(Platform.resolvedExecutable));

    print('Using sdk at ${sdk}.');

    // pause_isolates_on_start, pause_isolates_on_exit
    process = await Process.start('${sdk}/bin/dart', [
      '--pause_isolates_on_start',
      '--enable-vm-service=${port}',
      '--disable-service-auth-codes',
      'example/sample_main.dart'
    ]);

    print('dart process started');

    // ignore: unawaited_futures
    process!.exitCode.then((code) => print('vm exited: ${code}'));
    process!.stdout.transform(utf8.decoder).listen(print);
    process!.stderr.transform(utf8.decoder).listen(print);

    await Future.delayed(Duration(milliseconds: 500));

    // ignore: deprecated_member_use_from_same_package
    serviceClient = await vmServiceConnect(host, port, log: StdoutLog());

    print('socket connected');

    serviceClient.onSend.listen((str) => print('--> ${str}'));

    // The next listener will bail out if you toggle this to false, which we need
    // to do for some things like the custom service registration tests.
    var checkResponseJsonCompatibility = true;
    serviceClient.onReceive.listen((str) {
      print('<-- ${str}');

      if (!checkResponseJsonCompatibility) return;

      // For each received event, check that we can deserialize it and
      // reserialize it back to the same exact representation (minus private
      // fields).
      var json = jsonDecode(str);
      var originalJson = json['result'] as Map<String, dynamic>?;
      if (originalJson == null && json['method'] == 'streamNotify') {
        originalJson = json['params']['event'];
      }
      expect(originalJson, isNotNull, reason: 'Unrecognized event type! $json');

      var instance =
          createServiceObject(originalJson, const ['Event', 'Success']);
      expect(instance, isNotNull,
          reason: 'failed to deserialize object $originalJson!');

      var reserializedJson = (instance as dynamic).toJson();

      forEachNestedMap(originalJson!, (obj) {
        // Private fields that we don't reproduce
        obj.removeWhere((k, v) => k.startsWith('_'));
        // Extra fields that aren't specified and we don't reproduce
        obj.remove('isExport');
      });

      forEachNestedMap(reserializedJson, (obj) {
        // We provide explicit defaults for these, need to remove them.
        obj.remove('valueAsStringIsTruncated');
      });

      expect(reserializedJson, equals(originalJson));
    });

    serviceClient.onIsolateEvent.listen((e) => print('onIsolateEvent: ${e}'));
    serviceClient.onDebugEvent.listen((e) => print('onDebugEvent: ${e}'));
    serviceClient.onGCEvent.listen((e) => print('onGCEvent: ${e}'));
    serviceClient.onStdoutEvent.listen((e) => print('onStdoutEvent: ${e}'));
    serviceClient.onStderrEvent.listen((e) => print('onStderrEvent: ${e}'));

    unawaited(serviceClient.streamListen(EventStreams.kIsolate));
    unawaited(serviceClient.streamListen(EventStreams.kDebug));
    unawaited(serviceClient.streamListen(EventStreams.kStdout));

    VM vm = await serviceClient.getVM();
    print('hostCPU=${vm.hostCPU}');
    print(await serviceClient.getVersion());
    List<IsolateRef> isolates = vm.isolates!;
    print(isolates);

    // Disable the json reserialization checks since custom services are not
    // supported.
    checkResponseJsonCompatibility = false;
    await testServiceRegistration();
    checkResponseJsonCompatibility = true;

    await testScriptParse(vm.isolates!.first);
    await testSourceReport(vm.isolates!.first);

    IsolateRef isolateRef = isolates.first;
    print(await serviceClient.resume(isolateRef.id!));

    print('waiting for client to shut down...');
    await serviceClient.dispose();

    await serviceClient.onDone;
    print('service client shut down');
  });
}

// Deeply traverses a map and calls [cb] with each nested map and the
// parent map.
void forEachNestedMap(Map input, Function(Map) cb) {
  var queue = Queue.from([input]);
  while (queue.isNotEmpty) {
    var next = queue.removeFirst();
    if (next is Map) {
      cb(next);
      queue.addAll(next.values);
    } else if (next is List) {
      queue.addAll(next);
    }
  }
}

Future testServiceRegistration() async {
  const String serviceName = 'serviceName';
  const String serviceAlias = 'serviceAlias';
  const String movedValue = 'movedValue';
  serviceClient.registerServiceCallback(serviceName,
      (Map<String, dynamic> params) async {
    assert(params['input'] == movedValue);
    return <String, dynamic>{
      'result': {'output': params['input']}
    };
  });
  await serviceClient.registerService(serviceName, serviceAlias);
  VmService otherClient =
      // ignore: deprecated_member_use_from_same_package
      await vmServiceConnect(host, port, log: StdoutLog());
  Completer completer = Completer();
  otherClient.onEvent('Service').listen((e) async {
    if (e.service == serviceName && e.kind == EventKind.kServiceRegistered) {
      assert(e.alias == serviceAlias);
      Response? response = await serviceClient.callMethod(
        e.method!,
        args: <String, dynamic>{'input': movedValue},
      );
      assert(response.json!['output'] == movedValue);
      completer.complete();
    }
  });
  await otherClient.streamListen('Service');
  await completer.future;
  await otherClient.dispose();
}

Future testScriptParse(IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final Isolate isolate = await serviceClient.getIsolate(isolateId);
  final Library rootLibrary =
      await serviceClient.getObject(isolateId, isolate.rootLib!.id!) as Library;
  final ScriptRef scriptRef = rootLibrary.scripts!.first;

  final Script script =
      await serviceClient.getObject(isolateId, scriptRef.id!) as Script;
  print(script);
  print(script.uri);
  print(script.library);
  print(script.source!.length);
  print(script.tokenPosTable!.length);
}

Future testSourceReport(IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final Isolate isolate = await serviceClient.getIsolate(isolateId);
  final Library rootLibrary =
      await serviceClient.getObject(isolateId, isolate.rootLib!.id!) as Library;
  final ScriptRef scriptRef = rootLibrary.scripts!.first;

  // make sure some code has run
  await serviceClient.resume(isolateId);
  await Future.delayed(const Duration(milliseconds: 25));

  final SourceReport sourceReport = await serviceClient.getSourceReport(
      isolateId, [SourceReportKind.kCoverage],
      scriptId: scriptRef.id);
  for (SourceReportRange range in sourceReport.ranges!) {
    print('  $range');
    if (range.coverage != null) {
      print('  ${range.coverage}');
    }
  }
  print(sourceReport);
}

class StdoutLog extends Log {
  void warning(String message) => print(message);

  void severe(String message) => print(message);
}
