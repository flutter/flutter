// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is a minimal dependency heart beat test for Observatory.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'launcher.dart';
import 'service_client.dart';

class Expect {
  static void equals(dynamic actual, dynamic expected) {
    if (actual != expected) {
      throw 'Expected $actual == $expected';
    }
  }

  static void contains(String needle, String haystack) {
    if (!haystack.contains(needle)) {
      throw 'Expected $haystack to contain $needle';
    }
  }

  static void isTrue(bool tf) {
    if (tf != true) {
      throw 'Expected $tf to be true';
    }
  }

  static void isFalse(bool tf) {
    if (tf != false) {
      throw 'Expected $tf to be false';
    }
  }

  static void notExecuted() {
    throw 'Should not have hit';
  }

  static void isNotNull(dynamic a) {
    if (a == null) {
      throw 'Expected $a to not be null';
    }
  }
}

Future<String> readResponse(HttpClientResponse response) {
  final Completer<String> completer = Completer<String>();
  final StringBuffer contents = StringBuffer();
  response.transform(utf8.decoder).listen((String data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

// Test accessing the service protocol over http.
Future<Null> testHttpProtocolRequest(Uri uri) async {
  uri = uri.replace(path: 'getVM');
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(uri);
  final HttpClientResponse response = await request.close();
  Expect.equals(response.statusCode, 200);
  final Map<String, dynamic> responseAsMap = json.decode(await readResponse(response));
  Expect.equals(responseAsMap['jsonrpc'], '2.0');
  client.close();
}

// Test accessing the service protocol over ws.
Future<Null> testWebSocketProtocolRequest(Uri uri) async {
  uri = uri.replace(scheme: 'ws', path: 'ws');
  final WebSocket webSocketClient = await WebSocket.connect(uri.toString());
  final ServiceClient serviceClient = ServiceClient(webSocketClient);
  final Map<String, dynamic> response = await serviceClient.invokeRPC('getVM');
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
Future<Null> testHttpAssetRequest(Uri uri) async {
  uri = uri.replace(path: 'third_party/trace_viewer_full.html');
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(uri);
  final HttpClientResponse response = await request.close();
  Expect.equals(response.statusCode, 200);
  await response.drain<List<int>>();
  client.close();
}

Future<Null> testStartPaused(Uri uri) async {
  uri = uri.replace(scheme: 'ws', path: 'ws');
  final WebSocket webSocketClient = await WebSocket.connect(uri.toString());
  final Completer<dynamic> isolateStartedId = Completer<dynamic>();
  final Completer<dynamic> isolatePausedId = Completer<dynamic>();
  final Completer<dynamic> isolateResumeId = Completer<dynamic>();
  final ServiceClient serviceClient = ServiceClient(webSocketClient,
      isolateStartedId: isolateStartedId,
      isolatePausedId: isolatePausedId,
      isolateResumeId: isolateResumeId);
  await serviceClient.invokeRPC('streamListen', <String, String>{ 'streamId': 'Isolate'});
  await serviceClient.invokeRPC('streamListen', <String, String>{ 'streamId': 'Debug'});

  final Map<String, dynamic> response = await serviceClient.invokeRPC('getVM');
  Expect.equals(response['type'], 'VM');
  String isolateId;
  if (response['isolates'].length > 0) {
    isolateId = response['isolates'][0]['id'];
  } else {
    // Wait until isolate starts.
    isolateId = await isolateStartedId.future;
  }

  // Grab the isolate.
  Map<String, dynamic> isolate = await serviceClient.invokeRPC('getIsolate', <String, String>{
      'isolateId': isolateId,
  });
  Expect.equals(isolate['type'], 'Isolate');
  Expect.isNotNull(isolate['pauseEvent']);
  // If it is not runnable, wait until it becomes runnable.
  if (isolate['pauseEvent']['kind'] == 'None') {
    await isolatePausedId.future;
    isolate = await serviceClient.invokeRPC('getIsolate', <String, String>{
      'isolateId': isolateId,
    });
   }
  // Verify that it is paused at start.
  Expect.equals(isolate['pauseEvent']['kind'], 'PauseStart');

  // Resume the isolate.
  await serviceClient.invokeRPC('resume', <String, String>{
    'isolateId': isolateId,
  });
  // Wait until the isolate has resumed.
  await isolateResumeId.future;
  final Map<String, dynamic> resumedResponse = await serviceClient.invokeRPC(
      'getIsolate', <String, String>{'isolateId': isolateId});
  Expect.equals(resumedResponse['type'], 'Isolate');
  Expect.isNotNull(resumedResponse['pauseEvent']);
  Expect.equals(resumedResponse['pauseEvent']['kind'], 'Resume');
}

typedef TestFunction = Future<Null> Function(Uri uri);

final List<TestFunction> basicTests = <TestFunction>[
  testHttpProtocolRequest,
  testWebSocketProtocolRequest,
  testHttpAssetRequest
];

final List<TestFunction> startPausedTests = <TestFunction>[
  // TODO(engine): Investigate difference in lifecycle events.
  // testStartPaused,
];

Future<bool> runTests(ShellLauncher launcher, List<TestFunction> tests) async {
  final ShellProcess process = await launcher.launch();
  final Uri uri = await process.waitForObservatory();
  try {
    for (int i = 0; i < tests.length; i++) {
      print('Executing test ${i+1}/${tests.length}');
      await tests[i](uri);
    }
  } catch (e) {
    print('Observatory test failure: $e');
    exitCode = -1;
  }
  await process.kill();
  return exitCode == 0;
}

Future<Null> main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart ${Platform.script} '
          '<sky_shell_executable> <main_dart> ...');
    return;
  }
  final String shellExecutablePath = args[0];
  final String mainDartPath = args[1];
  final List<String> extraArgs = args.length <= 2 ? <String>[] : args.sublist(2);

  final ShellLauncher launcher =
      ShellLauncher(shellExecutablePath,
                        mainDartPath,
                        false,
                        extraArgs);

  final ShellLauncher startPausedlauncher =
      ShellLauncher(shellExecutablePath,
                        mainDartPath,
                        true,
                        extraArgs);

  await runTests(launcher, basicTests);
  await runTests(startPausedlauncher, startPausedTests);
}
