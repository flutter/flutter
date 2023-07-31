// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:path/path.dart' as p;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main(List<String> args) async {
  watch.start();
  if (args.isNotEmpty) {
    throw ArgumentError('No command line args are supported');
  }

  var client = await FrontendServerClient.start('org-dartlang-root:///$app',
      outputDill, p.join(sdkDir, 'lib', '_internal', 'vm_platform_strong.dill'),
      target: 'vm',
      fileSystemRoots: [p.current],
      fileSystemScheme: 'org-dartlang-root',
      verbose: true);
  _print('compiling $app');
  var result = await client.compile();
  client.accept();
  _print('done compiling $app');

  Process appProcess;
  final vmServiceCompleter = Completer<VmService>();
  appProcess = await Process.start(Platform.resolvedExecutable,
      ['--observe', '--no-pause-isolates-on-exit', result!.dillOutput]);
  appProcess.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    stdout.writeln('APP -> $line');
    if (line.startsWith('Observatory listening on')) {
      var observatoryUri =
          '${line.split(' ').last.replaceFirst('http', 'ws')}ws';
      vmServiceCompleter.complete(vmServiceConnectUri(observatoryUri));
    }
  });
  appProcess.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
    stderr.writeln('APP -> $line');
  });

  final vmService = await vmServiceCompleter.future;

  _print('editing $app');
  var appFile = File(app);
  var originalContent = await appFile.readAsString();
  var newContent = originalContent.replaceFirst('hello', 'goodbye');
  await appFile.writeAsString(newContent);

  _print('recompiling $app with edits');
  result = await client.compile([Uri.parse('org-dartlang-root:///$app')]);
  client.accept();
  _print('done recompiling $app');
  _print('reloading $app');
  var vm = await vmService.getVM();
  await vmService.reloadSources(vm.isolates!.first.id!,
      rootLibUri: result!.dillOutput);

  _print('restoring $app to original contents');
  await appFile.writeAsString(originalContent);
  _print('exiting');
  await client.shutdown().timeout(const Duration(seconds: 1), onTimeout: () {
    client.kill();
    return 1;
  });
}

void _print(String message) {
  print('${watch.elapsed}: $message');
}

final app = 'example/app/main.dart';
final outputDill = p.join('.dart_tool', 'out', 'example_app.dill');
final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));
final watch = Stopwatch();
