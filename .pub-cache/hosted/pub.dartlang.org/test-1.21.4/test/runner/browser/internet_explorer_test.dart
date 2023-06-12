// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
@Tags(['ie'])

import 'package:test/src/runner/browser/internet_explorer.dart';
import 'package:test/src/runner/executable_settings.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import '../../io.dart';
import '../../utils.dart';
import 'code_server.dart';

void main() {
  setUpAll(precompileTestExecutable);

  test('starts IE with the given URL', () async {
    var server = await CodeServer.start();

    server.handleJavaScript('''
var webSocket = new WebSocket(window.location.href.replace("http://", "ws://"));
webSocket.addEventListener("open", function() {
  webSocket.send("loaded!");
});
''');
    var webSocket = server.handleWebSocket();

    var ie = InternetExplorer(server.url);
    addTearDown(() => ie.close());

    expect(await (await webSocket).stream.first, equals('loaded!'));
  });

  test("a process can be killed synchronously after it's started", () async {
    var server = await CodeServer.start();

    var ie = InternetExplorer(server.url);
    await ie.close();
  });

  test('reports an error in onExit', () {
    var ie = InternetExplorer('http://dart-lang.org',
        settings: ExecutableSettings(
            linuxExecutable: '_does_not_exist',
            macOSExecutable: '_does_not_exist',
            windowsExecutable: '_does_not_exist'));
    expect(
        ie.onExit,
        throwsA(isApplicationException(startsWith(
            'Failed to run Internet Explorer: $noSuchFileMessage'))));
  });

  test('can run successful tests', () async {
    await d.file('test.dart', '''
import 'package:test/test.dart';

void main() {
  test("success", () {});
}
''').create();

    var test = await runTest(['-p', 'ie', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
    await test.shouldExit(0);
  });

  test('can run failing tests', () async {
    await d.file('test.dart', '''
import 'package:test/test.dart';

void main() {
  test("failure", () => throw TestFailure("oh no"));
}
''').create();

    var test = await runTest(['-p', 'ie', 'test.dart']);
    expect(test.stdout, emitsThrough(contains('-1: Some tests failed.')));
    await test.shouldExit(1);
  });
}
