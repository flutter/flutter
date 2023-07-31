// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_packages_handler/shelf_packages_handler.dart';
import 'package:shelf_static/shelf_static.dart';

void main(List<String> args) async {
  watch.start();
  if (args.isNotEmpty) {
    throw ArgumentError('No command line args are supported');
  }

  var client = await DartDevcFrontendServerClient.start(
      'org-dartlang-root:///$app', outputDill,
      fileSystemRoots: [p.current],
      fileSystemScheme: 'org-dartlang-root',
      verbose: true);

  _print('compiling $app');
  await client.compile([]);
  client.accept();
  _print('done compiling $app');

  _print('starting shelf server');
  var cascade = Cascade()
      .add(_clientHandler(client))
      .add(createStaticHandler(p.current))
      .add(createFileHandler(
          p.join(sdkDir, 'lib', 'dev_compiler', 'kernel', 'amd', 'dart_sdk.js'),
          url: 'example/app/dart_sdk.js'))
      .add(createFileHandler(
          p.join(sdkDir, 'lib', 'dev_compiler', 'web',
              'dart_stack_trace_mapper.js'),
          url: 'example/app/dart_stack_trace_mapper.js'))
      .add(createFileHandler(
          p.join(sdkDir, 'lib', 'dev_compiler', 'kernel', 'amd', 'require.js'),
          url: 'example/app/require.js'))
      .add(packagesDirHandler());
  final server = await shelf_io.serve(cascade.handler, 'localhost', 8080);
  _print('server ready');

  // The file we will be editing in the repl
  var appFile = File(app);
  var originalContent = await appFile.readAsString();
  var appLines = const LineSplitter().convert(originalContent);
  var getterText = 'String get message =>';
  var messageLine = appLines.indexWhere((line) => line.startsWith(getterText));

  var stdinQueue = StreamQueue(
      stdin.transform(utf8.decoder).transform(const LineSplitter()));
  _prompt();
  while (await stdinQueue.hasNext) {
    var newMessage = await stdinQueue.next;
    if (newMessage == 'quit') {
      await server.close();
      await stdinQueue.cancel();
      break;
    } else if (newMessage == 'reset') {
      print('resetting');
      client.reset();
      _print('restoring $app');
      await appFile.writeAsString(originalContent);
    } else {
      _print('editing $app');
      appLines[messageLine] = '$getterText "$newMessage";';
      var newContent = appLines.join('\n');
      await appFile.writeAsString(newContent);

      _print('recompiling $app with edits');
      var result =
          await client.compile([Uri.parse('org-dartlang-root:///$app')]);
      if (result.errorCount > 0) {
        print('Compile errors: \n${result.compilerOutputLines.join('\n')}');
        await client.reject();
      } else {
        _print('Recompile succeeded for $app');
        client.accept();
        // TODO: support hot restart
        print('reload app to see the new message');
      }
    }

    _prompt();
  }

  _print('restoring $app');
  await appFile.writeAsString(originalContent);
  _print('exiting');
  await client.shutdown();
}

Handler _clientHandler(DartDevcFrontendServerClient client) {
  return (Request request) {
    var assetBytes = client.assetBytes(request.requestedUri.path);
    if (assetBytes == null) return Response.notFound('path not found');
    return Response.ok(assetBytes,
        headers: {HttpHeaders.contentTypeHeader: 'application/javascript'});
  };
}

void _print(String message) {
  print('${watch.elapsed}: $message');
}

void _prompt() => stdout.write(
    'Enter a new message to print and recompile, or type `quit` to exit:');

final app = 'example/app/main.dart';
final outputDill = p.join('.dart_tool', 'out', 'example_app.dill');
final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));
final watch = Stopwatch();
