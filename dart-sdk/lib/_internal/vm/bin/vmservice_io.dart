// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_io;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:_vmservice';

part 'vmservice_server.dart';

// The TCP ip/port that dds listens on.
@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
int _ddsPort = 0;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
String _ddsIP = '';

// The TCP ip/port that the HTTP server listens on.
@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
int _port = 0;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
String _ip = '';

// Should the HTTP server auto start?
@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _autoStart = false;

// Should the HTTP server require an auth code?
@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _authCodesDisabled = false;

// Should the HTTP server run in devmode?
@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _originCheckDisabled = false;

// Location of file to output VM service connection info.
@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
String? _serviceInfoFilename;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _isWindows = false;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _isFuchsia = false;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
Stream<ProcessSignal> Function(ProcessSignal signal)? _signalWatch;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
StreamSubscription<ProcessSignal>? _signalSubscription;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _serveDevtools = true;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _enableServicePortFallback = false;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _waitForDdsToAdvertiseService = false;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _serveObservatory = false;

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
bool _printDtd = false;

// HTTP server.
Server? server;
Future<Server>? serverFuture;
_DebuggingSession? ddsInstance;

Server _lazyServerBoot() {
  var localServer = server;
  if (localServer != null) {
    return localServer;
  }
  // Lazily create service.
  final service = VMService();
  // Lazily create server.
  localServer = Server(service, _ip, _port, _originCheckDisabled,
      _authCodesDisabled, _serviceInfoFilename, _enableServicePortFallback);
  server = localServer;
  return localServer;
}

/// Responsible for launching a DevTools instance when the service is started
/// via SIGQUIT.
class _DebuggingSession {
  Future<bool> start(
    String host,
    String port,
    bool disableServiceAuthCodes,
    bool enableDevTools,
  ) async {
    final dartDir = File(Platform.resolvedExecutable).parent.path;
    final executable = [
      dartDir,
      'dart${Platform.isWindows ? '.exe' : ''}',
    ].join(Platform.pathSeparator);
    _process = await Process.start(
      executable,
      [
        'development-service',
        '--vm-service-uri=${server!.serverAddress!}',
        '--bind-address=$host',
        '--bind-port=$port',
        if (disableServiceAuthCodes) '--disable-service-auth-codes',
        if (enableDevTools) '--serve-devtools',
        if (_enableServicePortFallback) '--enable-service-port-fallback',
      ],
      mode: ProcessStartMode.detachedWithStdio,
    );

    // DDS will close stderr once it's finished launching.
    final launchResult = await _process!.stderr.transform(utf8.decoder).join();

    void printError(String details) => stderr.writeln(
          'Could not start the VM service:\n$details',
        );

    try {
      final result = json.decode(launchResult) as Map<String, dynamic>;
      if (result
          case {
            'state': 'started',
          }) {
        if (result case {'devToolsUri': String devToolsUri}) {
          // NOTE: update pkg/dartdev/lib/src/commands/run.dart if this message
          // is changed to ensure consistency.
          const devToolsMessagePrefix =
              'The Dart DevTools debugger and profiler is available at:';
          print('$devToolsMessagePrefix $devToolsUri');
        }
        if (result
            case {
              'dtd': {
                'uri': String dtdUri,
              }
            } when _printDtd) {
          print('The Dart Tooling Daemon (DTD) is available at: $dtdUri');
        }
      } else {
        printError(result['error'] ?? result);
        return false;
      }
    } catch (_) {
      // Malformed JSON was likely encountered, so output the entirety of
      // stderr in the error message.
      printError(launchResult);
      return false;
    }
    return true;
  }

  void shutdown() => _process!.kill();

  Process? _process;
}

Future<void> cleanupCallback() async {
  // Cancel the sigquit subscription.
  final signalSubscription = _signalSubscription;
  if (signalSubscription != null) {
    await signalSubscription.cancel();
    _signalSubscription = null;
  }
  final localServer = server;
  if (localServer != null) {
    try {
      await localServer.cleanup(true);
    } catch (e, st) {
      print('Error in vm-service shutdown: $e\n$st\n');
    }
  }
  final timer = _registerSignalHandlerTimer;
  if (timer != null) {
    timer.cancel();
    _registerSignalHandlerTimer = null;
  }
  // Call out to embedder's shutdown callback.
  _shutdown();
}

Future<void> ddsConnectedCallback() async {
  final serviceAddress = server!.serverAddress.toString();
  _notifyServerState(serviceAddress);
  onServerAddressChange(serviceAddress);
  if (_waitForDdsToAdvertiseService) {
    await server!.outputConnectionInformation();
  }
}

Future<void> ddsDisconnectedCallback() async {
  final serviceAddress = server!.serverAddress.toString();
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

void serveObservatoryCallback() => _serveObservatory = true;

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

Uri? serverInformationCallback() => _lazyServerBoot().serverAddress;

Future<Uri?> webServerControlCallback(bool enable, bool? silenceOutput) async {
  if (silenceOutput != null) {
    silentObservatory = silenceOutput;
  }
  final _server = _lazyServerBoot();
  if (_server.running != enable) {
    if (enable) {
      await _server.startup();
      // TODO: if dds is enabled a dds instance needs to be started.
    } else {
      await _server.shutdown(true);
    }
  }
  return _server.serverAddress;
}

void webServerAcceptNewWebSocketConnections(bool enable) {
  final _server = _lazyServerBoot();
  _server.acceptNewWebSocketConnections = enable;
}

_onSignal(ProcessSignal signal) async {
  if (serverFuture != null) {
    // Still waiting.
    return;
  }
  final _server = _lazyServerBoot();
  // Toggle HTTP server.
  if (_server.running) {
    _server.shutdown(true).then((_) async {
      ddsInstance?.shutdown();
      await VMService().clearState();
      serverFuture = null;
    });
  } else {
    _server.startup().then((_) {
      if (_waitForDdsToAdvertiseService) {
        ddsInstance = _DebuggingSession()
          ..start(
            _ddsIP,
            _ddsPort.toString(),
            _authCodesDisabled,
            _serveDevtools,
          );
      }
    });
  }
}

Timer? _registerSignalHandlerTimer;

void _registerSignalHandler() {
  if (VMService().isExiting) {
    // If the VM started shutting down we don't want to register this signal
    // handler, otherwise we'll cause the VM to hang after killing the service
    // isolate.
    return;
  }
  _registerSignalHandlerTimer = null;
  final signalWatch = _signalWatch;
  if (signalWatch == null) {
    // Cannot register for signals.
    return;
  }
  if (_isWindows || _isFuchsia) {
    // Cannot register for signals on Windows or Fuchsia.
    return;
  }
  _signalSubscription = signalWatch(ProcessSignal.sigquit).listen(_onSignal);
}

@pragma('vm:entry-point', !const bool.fromEnvironment('dart.vm.product'))
main() {
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
  VMServiceEmbedderHooks.serveObservatory = serveObservatoryCallback;
  // Always instantiate the vmservice object so that the exit message
  // can be delivered and waiting loaders can be cancelled.
  VMService();
  if (_autoStart) {
    final _server = _lazyServerBoot();
    _server.startup().then((_) {
      if (_waitForDdsToAdvertiseService) {
        ddsInstance = _DebuggingSession()
          ..start(
            _ddsIP,
            _ddsPort.toString(),
            _authCodesDisabled,
            _serveDevtools,
          );
      }
    });
    // It's just here to push an event on the event loop so that we invoke the
    // scheduled microtasks.
    Timer.run(() {});
  }
  // Register signal handler after a small delay to avoid stalling main
  // isolate startup.
  _registerSignalHandlerTimer = Timer(shortDelay, _registerSignalHandler);
}

@pragma("vm:external-name", "VMServiceIO_Shutdown")
external _shutdown();
