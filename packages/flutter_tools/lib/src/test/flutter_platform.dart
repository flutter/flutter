// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:path/path.dart' as path;
import 'package:stream_channel/stream_channel.dart';

import 'package:test/src/backend/test_platform.dart'; // ignore: implementation_imports
import 'package:test/src/runner/plugin/platform.dart'; // ignore: implementation_imports
import 'package:test/src/runner/plugin/hack_register_platform.dart' as hack; // ignore: implementation_imports

import '../package_map.dart';

final String _kSkyShell = Platform.environment['SKY_SHELL'];
const String _kHost = '127.0.0.1';
const String _kPath = '/runner';

String shellPath;

void installHook() {
  hack.registerPlatformPlugin(<TestPlatform>[TestPlatform.vm], () => new FlutterPlatform());
}

class _ServerInfo {
  final String url;
  final Future<WebSocket> socket;
  final HttpServer server;

  _ServerInfo(this.server, this.url, this.socket);
}

Future<_ServerInfo> _startServer() async {
  HttpServer server = await HttpServer.bind(_kHost, 0);
  Completer<WebSocket> socket = new Completer<WebSocket>();
  server.listen((HttpRequest request) {
    if (request.uri.path == _kPath)
      socket.complete(WebSocketTransformer.upgrade(request));
  });
  return new _ServerInfo(server, 'ws://$_kHost:${server.port}$_kPath', socket.future);
}

Future<Process> _startProcess(String mainPath, { String packages }) {
  assert(shellPath != null || _kSkyShell != null); // Please provide the path to the shell in the SKY_SHELL environment variable.
  return Process.start(shellPath ?? _kSkyShell, <String>[
    '--enable-checked-mode',
    '--non-interactive',
    '--packages=$packages',
    mainPath,
  ], environment: <String, String>{ 'FLUTTER_TEST': 'true' });
}

void _attachStandardStreams(Process process) {
  for (Stream<List<int>> stream in
      <Stream<List<int>>>[process.stderr, process.stdout]) {
    stream.transform(UTF8.decoder)
      .transform(const LineSplitter())
      .listen((String line) {
        if (line != null)
          print('Shell: $line');
      });
  }
}

class FlutterPlatform extends PlatformPlugin {
  @override
  StreamChannel<String> loadChannel(String mainPath, TestPlatform platform) {
    return StreamChannelCompleter.fromFuture(_startTest(mainPath));
  }

  Future<StreamChannel<String>> _startTest(String mainPath) async {
    _ServerInfo info = await _startServer();
    Directory tempDir = Directory.systemTemp.createTempSync(
        'dart_test_listener');
    File listenerFile = new File('${tempDir.path}/listener.dart');
    listenerFile.createSync();
    listenerFile.writeAsStringSync('''
import 'dart:convert';
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';
import 'package:test/src/runner/plugin/remote_platform_helpers.dart';
import 'package:test/src/runner/vm/catch_isolate_errors.dart';

import '${path.toUri(path.absolute(mainPath))}' as test;

void main() {
  String server = Uri.decodeComponent('${Uri.encodeComponent(info.url)}');
  StreamChannel channel = serializeSuite(() {
    catchIsolateErrors();
    return test.main;
  });
  WebSocket.connect(server).then((WebSocket socket) {
    socket.map(JSON.decode).pipe(channel.sink);
    socket.addStream(channel.stream.map(JSON.encode));
  });
}
''');

    Process process = await _startProcess(
      listenerFile.path, packages: PackageMap.instance.packagesPath
    );

    _attachStandardStreams(process);

    void finalize() {
      if (process != null) {
        Process processToKill = process;
        process = null;
        processToKill.kill();
      }
      if (tempDir != null) {
        Directory dirToDelete = tempDir;
        tempDir = null;
        dirToDelete.deleteSync(recursive: true);
      }
    }

    try {
      WebSocket socket = await info.socket;
      StreamChannel<String> channel = new StreamChannel<String>(socket.map(JSON.decode), socket);
      return channel.transformStream(
        new StreamTransformer<String, String>.fromHandlers(
          handleDone: (EventSink<String> sink) {
            finalize();
            sink.close();
          }
        )
      ).transformSink(new StreamSinkTransformer<String, String>.fromHandlers(
        handleData: (String data, StreamSink<String> sink) {
          sink.add(JSON.encode(data));
        },
        handleDone: (EventSink<String> sink) {
          finalize();
          sink.close();
        }
      ));
    } catch(e) {
      finalize();
      rethrow;
    }
  }
}
