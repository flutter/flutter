// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sky_tools/src/test/json_socket.dart';
import 'package:sky_tools/src/test/remote_test.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/src/backend/group.dart';
import 'package:test/src/backend/group_entry.dart';
import 'package:test/src/backend/metadata.dart';
import 'package:test/src/backend/test_platform.dart';
import 'package:test/src/runner/configuration.dart';
import 'package:test/src/runner/hack_load_vm_file_hook.dart' as hack;
import 'package:test/src/runner/load_exception.dart';
import 'package:test/src/runner/runner_suite.dart';
import 'package:test/src/runner/vm/environment.dart';
import 'package:test/src/util/io.dart';
import 'package:test/src/util/remote_exception.dart';

void installHook() {
  hack.loadVMFileHook = _loadVMFile;
}

final String _kSkyShell = Platform.environment['SKY_SHELL'];
const String _kHost = '127.0.0.1';
const String _kPath = '/runner';

class _ServerInfo {
  final String url;
  final Future<WebSocket> socket;
  final HttpServer server;

  _ServerInfo(this.server, this.url, this.socket);
}

Future<_ServerInfo> _createServer() async {
  HttpServer server = await HttpServer.bind(_kHost, 0);
  Completer<WebSocket> socket = new Completer<WebSocket>();
  server.listen((HttpRequest request) {
    if (request.uri.path == _kPath)
      socket.complete(WebSocketTransformer.upgrade(request));
  });
  return new _ServerInfo(server, 'ws://$_kHost:${server.port}$_kPath', socket.future);
}

Future<Process> _startProcess(String path, { String packageRoot }) {
  assert(_kSkyShell != null); // Please provide the path to the shell in the SKY_SHELL environment variable.
  return Process.start(_kSkyShell, [
    '--enable-checked-mode',
    '--non-interactive',
    '--package-root=$packageRoot',
    path,
  ]);
}

Future<RunnerSuite> _loadVMFile(String path,
                                Metadata metadata,
                                Configuration config) async {
  String encodedMetadata = Uri.encodeComponent(JSON.encode(
      metadata.serialize()));
  _ServerInfo info = await _createServer();
  Directory tempDir = await Directory.systemTemp.createTemp(
      'dart_test_listener');
  File listenerFile = new File('${tempDir.path}/listener.dart');
  await listenerFile.create();
  await listenerFile.writeAsString('''
import 'dart:convert';

import 'package:test/src/backend/metadata.dart';
import 'package:sky_tools/src/test/remote_listener.dart';

import '${p.toUri(p.absolute(path))}' as test;

void main() {
  String server = Uri.decodeComponent('${Uri.encodeComponent(info.url)}');
  Metadata metadata = new Metadata.deserialize(
      JSON.decode(Uri.decodeComponent('$encodedMetadata')));
  RemoteListener.start(server, metadata, () => test.main);
}
''');

  Completer<Iterable<GroupEntry>> completer = new Completer<Iterable<GroupEntry>>();

  Process process = await _startProcess(listenerFile.path,
      packageRoot: p.absolute(config.packageRoot));

  Future cleanupTempDirectory() async {
    if (tempDir == null)
      return;
    Directory dirToDelete = tempDir;
    tempDir = null;
    await dirToDelete.delete(recursive: true);
  }

  process.exitCode.then((int exitCode) async {
    info.server.close(force: true);
    await cleanupTempDirectory();
    if (!completer.isCompleted) {
      String error = await process.stderr.transform(UTF8.decoder).first;
      completer.completeError(
        new LoadException(path, error), new Trace.current());
    }
  });

  JSONSocket socket = new JSONSocket(await info.socket);

  await cleanupTempDirectory();

  StreamSubscription subscription;
  subscription = socket.stream.listen((response) {
    if (response["type"] == "print") {
      print(response["line"]);
    } else if (response["type"] == "loadException") {
      process.kill();
      completer.completeError(
          new LoadException(path, response["message"]),
          new Trace.current());
    } else if (response["type"] == "error") {
      process.kill();
      AsyncError asyncError = RemoteException.deserialize(response["error"]);
      completer.completeError(
          new LoadException(path, asyncError.error),
          asyncError.stackTrace);
    } else {
      assert(response["type"] == "success");
      subscription.cancel();
      completer.complete(response["tests"].map((test) {
        var testMetadata = new Metadata.deserialize(test['metadata']);
        return new RemoteTest(test['name'], testMetadata, socket, test['index']);
      }));        
    }
  });

  Iterable<GroupEntry> entries = await completer.future;

  return new RunnerSuite(
    const VMEnvironment(),
    new Group.root(entries, metadata: metadata),
    path: path,
    platform: TestPlatform.vm,
    os: currentOS,
    onClose: process.kill
  );
}
