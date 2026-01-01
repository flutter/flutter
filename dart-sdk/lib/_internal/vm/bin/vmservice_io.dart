// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_io;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:_vmservice';

part 'resident_compiler_utils.dart';
part 'vmservice_server.dart';

// The TCP ip/port that dds listens on.
@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
int _ddsPort = 0;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
String _ddsIP = '';

// The TCP ip/port that the HTTP server listens on.
@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
int _port = 0;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
String _ip = '';

// Should the HTTP server auto start?
@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _autoStart = false;

// Should the HTTP server require an auth code?
@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _authCodesDisabled = false;

// Should the HTTP server run in devmode?
@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _originCheckDisabled = false;

// Location of file to output VM service connection info.
@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
String? _serviceInfoFilename;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _isWindows = false;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _isFuchsia = false;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
Stream<ProcessSignal> Function(ProcessSignal signal)? _signalWatch;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
StreamSubscription<ProcessSignal>? _signalSubscription;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _serveDevtools = true;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _enableServicePortFallback = false;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _waitForDdsToAdvertiseService = false;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
bool _printDtd = false;

File? _residentCompilerInfoFile = null;

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
void _populateResidentCompilerInfoFile(
  /// If either `--resident-compiler-info-file` or `--resident-server-info-file`
  /// was supplied on the command line, the CLI argument should be forwarded as
  /// the argument to this parameter. If neither option was supplied, the
  /// argument to this parameter should be [null].
  final String? residentCompilerInfoFilePathArgumentFromCli,
) {
  _residentCompilerInfoFile = getResidentCompilerInfoFileConsideringArgsImpl(
    residentCompilerInfoFilePathArgumentFromCli,
  );
}

File? _getResidentCompilerInfoFile() => _residentCompilerInfoFile;

// HTTP server.
late final Server server;

Future<void> cleanupCallback() async {
  // Cancel the sigquit subscription.
  await _signalSubscription?.cancel();
  _signalSubscription = null;
  try {
    await server.shutdown(true);
  } catch (e, st) {
    print('Error in vm-service shutdown: $e\n$st\n');
  }
  // Call out to embedder's shutdown callback.
  _shutdown();
}

Future<void> ddsConnectedCallback() async {
  final serviceAddress = server!.serverAddress.toString();
  _notifyServerState(serviceAddress);
  onServerAddressChange(serviceAddress);
  if (_waitForDdsToAdvertiseService) {
    await server.outputConnectionInformation();
  }
}

Future<void> ddsDisconnectedCallback() async {
  final serviceAddress = server.serverAddress.toString();
  _notifyServerState(serviceAddress);
  onServerAddressChange(serviceAddress);
}

Future<Uri> createTempDirCallback(String base) async {
  final temp = await Directory.systemTemp.createTemp(base);
  // Underneath the temporary directory, create a directory with the
  // same name as the DevFS name [base].
  final fsUri = temp.uri.resolveUri(Uri.directory(base));
  await Directory.fromUri(fsUri).create();
  return fsUri;
}

Future<void> deleteDirCallback(Uri path) async =>
    await Directory.fromUri(path).delete(recursive: true);

class PendingWrite {
  PendingWrite(this.uri, this.bytes);
  final completer = Completer<void>();
  final Uri uri;
  final List<int> bytes;

  Future<void> write() async {
    final file = File.fromUri(uri);
    final parent_directory = file.parent;
    await parent_directory.create(recursive: true);
    if (await file.exists()) {
      await file.delete();
    }
    await file.writeAsBytes(bytes);
    completer.complete();
    WriteLimiter._writeCompleted();
  }
}

class WriteLimiter {
  static final pendingWrites = <PendingWrite>[];

  // non-rooted Android devices have a very low limit for the number of
  // open files. Artificially cap ourselves to 16.
  static const kMaxOpenWrites = 16;
  static int openWrites = 0;

  static Future<void> scheduleWrite(Uri path, List<int> bytes) async {
    // Create a new pending write.
    final pw = PendingWrite(path, bytes);
    pendingWrites.add(pw);
    _maybeWriteFiles();
    return pw.completer.future;
  }

  static void _maybeWriteFiles() {
    while (openWrites < kMaxOpenWrites) {
      if (pendingWrites.length > 0) {
        final pw = pendingWrites.removeLast();
        pw.write();
        openWrites++;
      } else {
        break;
      }
    }
  }

  static void _writeCompleted() {
    openWrites--;
    assert(openWrites >= 0);
    _maybeWriteFiles();
  }
}

Future<void> writeFileCallback(Uri path, List<int> bytes) async =>
    WriteLimiter.scheduleWrite(path, bytes);

Future<void> writeStreamFileCallback(Uri path, Stream<List<int>> bytes) async {
  final file = File.fromUri(path);
  final parent_directory = file.parent;
  await parent_directory.create(recursive: true);
  if (await file.exists()) {
    await file.delete();
  }
  final sink = await file.openWrite();
  await sink.addStream(bytes);
  await sink.close();
}

Future<List<int>> readFileCallback(Uri path) async =>
    await File.fromUri(path).readAsBytes();

Future<List<Map<String, dynamic>>> listFilesCallback(Uri dirPath) async {
  final dir = Directory.fromUri(dirPath);
  final dirPathStr = dirPath.path;
  final stream = dir.list(recursive: true);
  final result = <Map<String, dynamic>>[];
  await for (var fileEntity in stream) {
    final filePath = Uri.file(fileEntity.path).path;
    final stat = await fileEntity.stat();
    if (stat.type == FileSystemEntityType.file &&
        filePath.startsWith(dirPathStr)) {
      final map = <String, dynamic>{};
      map['name'] = '/' + filePath.substring(dirPathStr.length);
      map['size'] = stat.size;
      map['modified'] = stat.modified.millisecondsSinceEpoch;
      result.add(map);
    }
  }
  return result;
}

Uri? serverInformationCallback() => server.serverAddress;

Future<void> _toggleWebServer() async {
  // Toggle HTTP server.
  if (server.running) {
    await server.shutdown(true);
    await VMService().clearState();
  } else {
    await server.startup();
  }
}

Future<Uri?> webServerControlCallback(bool enable, bool? silenceOutput) async {
  if (silenceOutput != null) {
    silentVMService = silenceOutput;
  }
  if (server.running != enable) {
    await _toggleWebServer();
  }
  return server.serverAddress;
}

void webServerAcceptNewWebSocketConnections(bool enable) {
  server.acceptNewWebSocketConnections = enable;
}

void _registerSignalHandler() {
  if (VMService().isExiting) {
    // If the VM started shutting down we don't want to register this signal
    // handler, otherwise we'll cause the VM to hang after killing the service
    // isolate.
    return;
  }
  final signalWatch = _signalWatch;
  if (signalWatch == null) {
    // Cannot register for signals.
    return;
  }
  if (_isWindows || _isFuchsia) {
    // Cannot register for signals on Windows or Fuchsia.
    return;
  }
  _signalSubscription = signalWatch(
    ProcessSignal.sigquit,
  ).listen((_) => _toggleWebServer());
}

@pragma('vm:entry-point', !bool.fromEnvironment('dart.vm.product'))
void main() {
  // Set embedder hooks.
  VMServiceEmbedderHooks.cleanup = cleanupCallback;
  VMServiceEmbedderHooks.createTempDir = createTempDirCallback;
  VMServiceEmbedderHooks.ddsConnected = ddsConnectedCallback;
  VMServiceEmbedderHooks.ddsDisconnected = ddsDisconnectedCallback;
  VMServiceEmbedderHooks.deleteDir = deleteDirCallback;
  VMServiceEmbedderHooks.writeFile = writeFileCallback;
  VMServiceEmbedderHooks.writeStreamFile = writeStreamFileCallback;
  VMServiceEmbedderHooks.readFile = readFileCallback;
  VMServiceEmbedderHooks.listFiles = listFilesCallback;
  VMServiceEmbedderHooks.serverInformation = serverInformationCallback;
  VMServiceEmbedderHooks.webServerControl = webServerControlCallback;
  VMServiceEmbedderHooks.acceptNewWebSocketConnections =
      webServerAcceptNewWebSocketConnections;
  VMServiceEmbedderHooks.getResidentCompilerInfoFile =
      _getResidentCompilerInfoFile;

  server = Server(
    // Always instantiate the vmservice object so that the exit message
    // can be delivered and waiting loaders can be cancelled.
    VMService(),
    _ip,
    _port,
    _originCheckDisabled,
    _authCodesDisabled,
    _serviceInfoFilename,
    _enableServicePortFallback,
  );

  if (_autoStart) {
    _toggleWebServer();
  }
  _registerSignalHandler();
}

@pragma("vm:external-name", "VMServiceIO_Shutdown")
external void _shutdown();
