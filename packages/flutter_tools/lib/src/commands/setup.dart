// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io';

import '../base/common.dart';
import '../base/io.dart';
import '../globals_null_migrated.dart' as globals;
import '../runner/flutter_command.dart';
import '../web/chrome.dart';

const String kIndexHtml = r'''
<!doctype html>
<html>
  <head>
    <title>Flutter Installer</title>
  </head>
  <body>
    <div>
      <button id="foo">Click To Install Flutter</button>
    </div>
        <script>
document.getElementById("foo").onclick = function() {
 fetch('/finish');
 window.close();
}
    </script>
  </body>
</html>
''';

class SetupCommand extends FlutterCommand {
  @override
  String get description => 'setup the flutter SDK installation';

  @override
  String get name => 'setup';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final int port = await globals.os.findFreePort();
    final HttpServer server = await HttpServer.bind('localhost', port);
    final Completer<void> completer = Completer<void>();
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/') {
        request.response.headers.add(HttpHeaders.contentTypeHeader, 'text/html');
        request.response.write(kIndexHtml);
        await request.response.close();
        return;
      }
      if (request.uri.path == '/finish') {
        if (!completer.isCompleted) {
          completer.complete();
        }
        await request.response.close();
        return;
      }
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    });

    // Launch the browser to the local install server.
    final String chrome = findChromeExecutable(globals.platform, globals.fs);
    final String edge = findEdgeExecutable(globals.platform, globals.fs);
    if (globals.processManager.canRun(chrome)) {
      await globals.processManager.run(<String>[chrome, 'http://localhost:$port']);
    } else if (globals.processManager.canRun(edge)) {
      await globals.processManager.run(<String>[edge, 'http://localhost:$port']);
    } else {
      throwToolExit('Could not find supported browser');
    }
    await completer.future;
    return FlutterCommandResult.success();
  }
}
