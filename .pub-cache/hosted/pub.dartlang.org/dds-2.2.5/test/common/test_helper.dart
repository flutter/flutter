// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart';

late Uri remoteVmServiceUri;

Future<Process> spawnDartProcess(
  String script, {
  bool pauseOnStart = true,
  bool disableServiceAuthCodes = false,
}) async {
  final executable = Platform.executable;
  final tmpDir = await Directory.systemTemp.createTemp('dart_service');
  final serviceInfoUri = tmpDir.uri.resolve('service_info.json');
  final serviceInfoFile = await File.fromUri(serviceInfoUri).create();

  final arguments = [
    '--disable-dart-dev',
    '--observe=0',
    if (pauseOnStart) '--pause-isolates-on-start',
    if (disableServiceAuthCodes) '--disable-service-auth-codes',
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
  remoteVmServiceUri = Uri.parse(infoJson['uri']);
  return process;
}

Future<void> executeUntilNextPause(VmService service) async {
  final vm = await service.getVM();
  final isolate = await service.getIsolate(vm.isolates!.first.id!);

  final completer = Completer<void>();
  late StreamSubscription sub;
  sub = service.onDebugEvent.listen((event) async {
    if (event.kind == EventKind.kPauseBreakpoint) {
      completer.complete();
      await sub.cancel();
    }
  });
  await service.streamListen(EventStreams.kDebug);
  await service.resume(isolate.id!);
  await completer.future;
}

/// Returns the resolved URI to the pre-built devtools app.
///
/// The method caller is responsible for providing the relative [prefix] that
/// will resolve to the sdk/ directory (e.g. '../../../').
Uri devtoolsAppUri({required String prefix}) {
  const pathFromSdkDirectory = 'third_party/devtools/web';
  return Platform.script.resolve('$prefix$pathFromSdkDirectory');
}
