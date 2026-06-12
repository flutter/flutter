// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:vmservice_io' show getResidentCompilerInfoFileConsideringArgsImpl;

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:dart_runtime_service_vm/dart_runtime_service_vm.dart';
import 'package:dart_runtime_service_vm/src/vm_isolate_manager.dart';

// ignore: unreachable_from_main
const entrypoint = pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'));

// The TCP IP that DDS listens on.
@entrypoint
String? _ddsIP = '';

// The TCP port that DDS listens on.
@entrypoint
int _ddsPort = 0;

// The TCP port that the HTTP server listens on.
@entrypoint
int _port = 0;

// The TCP IP that the HTTP server listens on.
@entrypoint
// ignore: unused_element
String _ip = '';

// Should the HTTP server auto start?
@entrypoint
bool _autoStart = false;

// Should the HTTP server require an auth code?
@entrypoint
bool _authCodesDisabled = false;

// Should the HTTP server run in devmode?
@entrypoint
bool _originCheckDisabled = false;

// Location of file to output VM service connection info.
@entrypoint
// ignore: unused_element
String? _serviceInfoFilename;

@entrypoint
// ignore: unused_element
bool _isWindows = false;

@entrypoint
// ignore: unused_element
bool _isFuchsia = false;

@entrypoint
Stream<ProcessSignal> Function(ProcessSignal signal)? _signalWatch;

@entrypoint
RawReceivePort boot() => DartRuntimeServiceVMBackend.isolateControlPort;

final _isolateRegistrationStreamController = StreamController<VmRunningIsolate>(sync: true);

@entrypoint
// ignore: unused_element
void _registerIsolate(int portId, SendPort sendPort, String name, bool isSystemIsolate) =>
    _isolateRegistrationStreamController.sink.add(
      VmRunningIsolate(
        id: portId,
        name: name,
        sendPort: sendPort,
        isSystemIsolate: isSystemIsolate,
      ),
    );

// ignore: unused_element
StreamSubscription<ProcessSignal>? _signalSubscription;

@entrypoint
bool _serveDevtools = true;

@entrypoint
bool _enableServicePortFallback = false;

@entrypoint
bool? _waitForDdsToAdvertiseService = false;

@entrypoint
bool _printDtd = false;

File? _residentCompilerInfoFile;

/// Sets the resident compiler info file, which is used to configure the
/// service to utilize a resident compiler.
///
/// If either `--resident-compiler-info-file` or `--resident-server-info-file`
/// was supplied on the command line, the CLI argument should be forwarded as
/// the argument to [residentCompilerInfoFilePathArgumentFromCli]. If neither
/// option was supplied, the argument to this parameter should be null.
@entrypoint
// ignore: unused_element
void _populateResidentCompilerInfoFile(String? residentCompilerInfoFilePathArgumentFromCli) {
  _residentCompilerInfoFile = getResidentCompilerInfoFileConsideringArgsImpl(
    residentCompilerInfoFilePathArgumentFromCli,
  );
}

@pragma('vm:entry-point', 'get')
Future<void> main([List<String> args = const []]) async {
  if (args case ['--help']) {
    return;
  }
  await DartRuntimeService.initialize(
    config: DartRuntimeServiceOptions(
      enableLogging: Platform.environment.containsKey('VM_SERVICE_LOGGING'),
      port: _port,
      disableAuthCodes: _authCodesDisabled,
      disableOriginCheck: _originCheckDisabled,
      autoStart: _autoStart,
      serveDevTools: _serveDevtools,
      enableServicePortFallback: _enableServicePortFallback,
      host: _ip,
    ),
    backendBuilder: (frontend) => DartRuntimeServiceVMBackend(
      frontend: frontend,
      signalWatch: _signalWatch ?? (sig) => Stream.empty(),
      runningIsolatesStream: _isolateRegistrationStreamController.stream,
      ddsManager: DartDevelopmentServiceManager(
        frontend: frontend,
        launchOnStart: _waitForDdsToAdvertiseService ?? false,
        printDtd: _printDtd,
        host: _ddsIP ?? '127.0.0.1',
        port: _ddsPort,
      ),
      residentCompilerInfoFile: _residentCompilerInfoFile,
    ),
  );
}
