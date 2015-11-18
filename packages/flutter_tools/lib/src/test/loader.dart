// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_tools/src/test/json_socket.dart';
import 'package:flutter_tools/src/test/remote_test.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/src/backend/group.dart';
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

String shellPath;

// Right now a bunch of our tests crash or assert after the tests have finished running.
// Mostly this is just because the test puts the framework in an inconsistent state with
// a scheduled microtask that verifies that state. Eventually we should fix all these
// problems but for now we'll just paper over them.
const bool kExpectAllTestsToCloseCleanly = false;

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

Future<Process> _startProcess(String mainPath, { String packageRoot }) {
  assert(shellPath != null || _kSkyShell != null); // Please provide the path to the shell in the SKY_SHELL environment variable.
  return Process.start(shellPath ?? _kSkyShell, [
    '--enable-checked-mode',
    '--non-interactive',
    '--package-root=$packageRoot',
    mainPath,
  ]);
}

Future<RunnerSuite> _loadVMFile(String mainPath,
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
import 'package:flutter_tools/src/test/remote_listener.dart';

import '${path.toUri(path.absolute(mainPath))}' as test;

void main() {
  String server = Uri.decodeComponent('${Uri.encodeComponent(info.url)}');
  Metadata metadata = new Metadata.deserialize(
      JSON.decode(Uri.decodeComponent('$encodedMetadata')));
  RemoteListener.start(server, metadata, () => test.main);
}
''');

  Completer<Iterable<RemoteTest>> completer = new Completer<Iterable<RemoteTest>>();
  Completer<String> deathCompleter = new Completer();

  Process process = await _startProcess(
    listenerFile.path,
    packageRoot: path.absolute(config.packageRoot)
  );

  Future cleanupTempDirectory() async {
    if (tempDir == null)
      return;
    Directory dirToDelete = tempDir;
    tempDir = null;
    await dirToDelete.delete(recursive: true);
  }

  process.exitCode.then((int exitCode) async {
    try {
      info.server.close(force: true);
      await cleanupTempDirectory();
      String output = '';
      if (exitCode < 0) {
        // Abnormal termination (high bit of signed 8-bit exitCode is set)
        switch (exitCode) {
          case -0x0f: // ProcessSignal.SIGTERM
            break; // we probably killed it ourselves
          case -0x0b: // ProcessSignal.SIGSEGV
            output += 'Segmentation fault in subprocess for: $mainPath\n';
            break;
          case -0x06: // ProcessSignal.SIGABRT
            output += 'Aborted while running: $mainPath\n';
            break;
          default:
            output += 'Unexpected exit code $exitCode from subprocess for: $mainPath\n';
        }
      }
      String stdout = await process.stdout.transform(UTF8.decoder).join('\n');
      String stderr = await process.stderr.transform(UTF8.decoder).join('\n');
      if (stdout != '')
         output += '\nstdout:\n$stdout';
      if (stderr != '')
         output += '\nstderr:\n$stderr';
      if (!completer.isCompleted) {
        if (output == '')
          output = 'No output.';
        completer.completeError(
          new LoadException(mainPath, output),
          new Trace.current()
        );
      } else {
        if (kExpectAllTestsToCloseCleanly && output != '')
          print('Unexpected failure after test claimed to pass:\n$output');
      }
      deathCompleter.complete(output);
    } catch (e) {
      // Throwing inside this block causes all kinds of hard-to-debug issues
      // like stack overflows and hangs. So catch everything just in case.
      print("exception while handling subprocess termination: $e");
    }
  });

  JSONSocket socket = new JSONSocket(await info.socket, deathCompleter.future);

  await cleanupTempDirectory();

  StreamSubscription subscription;
  subscription = socket.stream.listen((response) {
    if (response["type"] == "print") {
      print(response["line"]);
    } else if (response["type"] == "loadException") {
      process.kill(ProcessSignal.SIGTERM);
      completer.completeError(
          new LoadException(mainPath, response["message"]),
          new Trace.current());
    } else if (response["type"] == "error") {
      process.kill(ProcessSignal.SIGTERM);
      AsyncError asyncError = RemoteException.deserialize(response["error"]);
      completer.completeError(
          new LoadException(mainPath, asyncError.error),
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

  Iterable<RemoteTest> entries = await completer.future;

  return new RunnerSuite(
    const VMEnvironment(),
    new Group.root(entries, metadata: metadata),
    path: mainPath,
    platform: TestPlatform.vm,
    os: currentOS,
    onClose: () { process.kill(ProcessSignal.SIGTERM); }
  );
}
