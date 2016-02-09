// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a minimal dependency heart beat test for Observatory.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'launcher.dart';
import 'service_client.dart';

class Expect {
  static equals(dynamic actual, dynamic expected) {
    if (actual != expected) {
      throw 'Expected $actual == $expected';
    }
  }

  static contains(String needle, String haystack) {
    if (!haystack.contains(needle)) {
      throw 'Expected $haystack to contain $needle';
    }
  }

  static isTrue(bool tf) {
    if (tf != true) {
      throw 'Expected $a to be true';
    }
  }

  static isFalse(bool tf) {
    if (tf != false) {
      throw 'Expected $a to be false';
    }
  }

  static notExecuted() {
    throw 'Should not have hit';
  }

  static isNotNull(dynamic a) {
    if (a == null) {
      throw 'Expected $a to not be null';
    }
  }
}

Future<String> readResponse(HttpClientResponse response) {
  var completer = new Completer();
  var contents = new StringBuffer();
  response.transform(UTF8.decoder).listen((String data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

// Test accessing the service protocol over http.
Future testHttpProtocolRequest(Uri uri) async {
  uri = uri.replace(path: 'getVM');
  HttpClient client = new HttpClient();
  HttpClientRequest request = await client.getUrl(uri);
  HttpClientResponse response = await request.close();
  Expect.equals(response.statusCode, 200);
  Map responseAsMap = JSON.decode(await readResponse(response));
  Expect.equals(responseAsMap['jsonrpc'], "2.0");
  client.close();
}

// Test accessing the service protocol over ws.
Future testWebSocketProtocolRequest(Uri uri) async {
  uri = uri.replace(scheme: 'ws', path: 'ws');
  WebSocket webSocketClient = await WebSocket.connect(uri.toString());
  ServiceClient serviceClient = new ServiceClient(webSocketClient);
  Map response = await serviceClient.invokeRPC('getVM');
  Expect.equals(response['type'], 'VM');
  try {
    await serviceClient.invokeRPC('BART_SIMPSON');
    Expect.notExecuted();
  } catch (e) {
    // Method not found.
    Expect.equals(e['code'], -32601);
  }
}

// Test accessing an Observatory UI asset.
Future testHttpAssetRequest(Uri uri) async {
  uri = uri.replace(path: 'third_party/trace_viewer_full.html');
  HttpClient client = new HttpClient();
  HttpClientRequest request = await client.getUrl(uri);
  HttpClientResponse response = await request.close();
  Expect.equals(response.statusCode, 200);
  await response.drain();
  client.close();
}

typedef Future TestFunction(Uri uri);

final List<TestFunction> tests = [
  testHttpProtocolRequest,
  testWebSocketProtocolRequest,
  testHttpAssetRequest
];

main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart ${Platform.script} '
          '<sky_shell_executable> <main_dart> ...');
    return;
  }
  final String shellExecutablePath = args[0];
  final String mainDartPath = args[1];
  final List<String> extraArgs = args.length <= 2 ? [] : args.sublist(2);
  ShellLauncher launcher =
      new ShellLauncher(shellExecutablePath,
                        mainDartPath,
                        extraArgs);
  ShellProcess process = await launcher.launch();
  Uri uri = await process.waitForObservatory();
  try {
    for (var i = 0; i < tests.length; i++) {
      print('Executing test ${i+1}/${tests.length}');
      await tests[i](uri);
    }
  } catch (e) {
    print('Observatory test failure: $e');
    exitCode = -1;
  }
  await process.kill();
}
