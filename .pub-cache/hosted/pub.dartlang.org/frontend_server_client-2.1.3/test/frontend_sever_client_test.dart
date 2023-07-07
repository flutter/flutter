// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

void main() async {
  late FrontendServerClient client;
  late PackageConfig packageConfig;
  late String packageRoot;

  setUp(() async {
    await d.dir('a', [
      d.file('pubspec.yaml', '''
name: a
dependencies:
  path: ^1.0.0

environment:
  sdk: '>=2.12.0-0 <3.0.0'
      '''),
      d.dir('bin', [
        d.file('main.dart', '''
// @dart = 2.8
import 'package:path/path.dart' as p;

void main() async {
  print(message);
  /// Runs in a loop until it is hot reloaded with a new message.
  while (!message.contains('goodbye')) {
    await Future.delayed(const Duration(seconds: 1));
  }
  print(message);
}

String get message => p.join('hello', 'world');

''')
      ]),
    ]).create();
    packageRoot = p.join(d.sandbox, 'a');
    await Process.run(Platform.resolvedExecutable, ['pub', 'get'],
        workingDirectory: packageRoot);
    packageConfig = (await findPackageConfig(Directory(packageRoot)))!;
  });

  tearDown(() async {
    await client.shutdown();
  });

  test('can compile, recompile, and hot reload a vm app', () async {
    var entrypoint = p.join(packageRoot, 'bin', 'main.dart');
    client = await FrontendServerClient.start(
        entrypoint, p.join(packageRoot, 'out.dill'), vmPlatformDill);
    var result = await client.compile();
    if (result == null) {
      fail('Expected compilation to be non-null');
    }
    client.accept();
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(
        result.newSources,
        containsAll([
          File(entrypoint).uri,
          packageConfig.resolve(Uri.parse('package:path/path.dart')),
        ]));
    expect(result.removedSources, isEmpty);
    expect(File(result.dillOutput).existsSync(), true);
    var process = await Process.start(Platform.resolvedExecutable, [
      '--observe',
      '--no-pause-isolates-on-exit',
      '--pause-isolates-on-start',
      result.dillOutput
    ]);
    addTearDown(process.kill);
    var stdoutLines = StreamQueue(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()));

    var observatoryLine = await stdoutLines.next;
    var observatoryUri =
        '${observatoryLine.split(' ').last.replaceFirst('http', 'ws')}ws';
    var vmService = await vmServiceConnectUri(observatoryUri);
    var isolate = await waitForIsolatesAndResume(vmService);

    await expectLater(stdoutLines, emitsThrough(p.join('hello', 'world')));

    var appFile = File(entrypoint);
    var originalContent = await appFile.readAsString();
    var newContent = originalContent.replaceFirst('hello', 'goodbye');
    await appFile.writeAsString(newContent);

    result = await client.compile([File(entrypoint).uri]);
    if (result == null) {
      fail('Expected compilation to be non-null');
    }

    client.accept();
    expect(result.newSources, isEmpty);
    expect(result.removedSources, isEmpty);
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(result.dillOutput, endsWith('.incremental.dill'));

    await vmService.reloadSources(isolate.id!, rootLibUri: result.dillOutput);

    expect(await stdoutLines.next, p.join('goodbye', 'world'));
    expect(await process.exitCode, 0);
  });

  test('can handle compile errors and reload fixes', () async {
    var entrypoint = p.join(packageRoot, 'bin', 'main.dart');
    var entrypointFile = File(entrypoint);
    var originalContent = await entrypointFile.readAsString();
    // append two compile errors to the bottom
    await entrypointFile
        .writeAsString('$originalContent\nint foo = 1.0;\nString bar = 4;');

    client = await FrontendServerClient.start(
        entrypoint, p.join(packageRoot, 'out.dill'), vmPlatformDill);
    var result = await client.compile();
    if (result == null) {
      fail('Expected compilation to be non-null');
    }

    client.accept();
    expect(result.errorCount, 2);
    expect(result.compilerOutputLines,
        allOf(contains('int foo = 1.0;'), contains('String bar = 4;')));
    expect(
        result.newSources,
        containsAll([
          File(entrypoint).uri,
          packageConfig.resolve(Uri.parse('package:path/path.dart')),
        ]));
    expect(result.removedSources, isEmpty);
    expect(File(result.dillOutput).existsSync(), true);

    var process = await Process.start(Platform.resolvedExecutable, [
      '--observe',
      '--no-pause-isolates-on-exit',
      '--pause-isolates-on-start',
      result.dillOutput
    ]);
    addTearDown(process.kill);
    var stdoutLines = StreamQueue(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()));

    var observatoryLine = await stdoutLines.next;
    var observatoryUri =
        '${observatoryLine.split(' ').last.replaceFirst('http', 'ws')}ws';
    var vmService = await vmServiceConnectUri(observatoryUri);
    var isolate = await waitForIsolatesAndResume(vmService);

    // The program actually runs regardless of the errors, as they don't affect
    // the runtime behavior.
    await expectLater(stdoutLines, emitsThrough(p.join('hello', 'world')));

    await entrypointFile
        .writeAsString(originalContent.replaceFirst('hello', 'goodbye'));
    result = await client.compile([entrypointFile.uri]);
    if (result == null) {
      fail('Expected compilation to be non-null');
    }
    client.accept();
    expect(result.errorCount, 0);
    expect(result.compilerOutputLines, isEmpty);
    expect(result.newSources, isEmpty);
    expect(result.removedSources, isEmpty);
    expect(File(result.dillOutput).existsSync(), true);

    await vmService.reloadSources(isolate.id!, rootLibUri: result.dillOutput);

    expect(await stdoutLines.next, p.join('goodbye', 'world'));
    expect(await process.exitCode, 0);
  });

  test('can compile and recompile a dartdevc app', () async {
    var entrypoint =
        p.toUri(p.join(packageRoot, 'bin', 'main.dart')).toString();
    var dartDevcClient = client = await DartDevcFrontendServerClient.start(
        entrypoint, p.join(packageRoot, 'out.dill'));
    var result = await client.compile();
    if (result == null) {
      fail('Expected compilation to be non-null');
    }
    client.accept();

    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(
        result.newSources,
        containsAll([
          Uri.parse(entrypoint),
          packageConfig.resolve(Uri.parse('package:path/path.dart')),
        ]));
    expect(result.removedSources, isEmpty);

    expect(File(result.jsManifestOutput).existsSync(), true);
    expect(File(result.jsSourcesOutput).existsSync(), true);
    expect(File(result.jsSourceMapsOutput).existsSync(), true);

    var entrypointUri = Uri.parse(entrypoint);
    expect(
        utf8.decode(dartDevcClient.assetBytes('${entrypointUri.path}.lib.js')!),
        contains('hello'));

    var appFile = File(entrypointUri.toFilePath());
    var originalContent = await appFile.readAsString();
    var newContent = originalContent.replaceFirst('hello', 'goodbye');
    await appFile.writeAsString(newContent);

    result = await client.compile([entrypointUri]);
    if (result == null) {
      fail('Expected compilation to be non-null');
    }
    client.accept();
    expect(result.newSources, isEmpty);
    expect(result.removedSources, isEmpty);
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(result.jsManifestOutput, endsWith('.incremental.dill.json'));

    expect(
        utf8.decode(dartDevcClient.assetBytes('${entrypointUri.path}.lib.js')!),
        contains('goodbye'));
  });

  test('can enable experiments', () async {
    await d.dir('a', [
      d.dir('bin', [
        d.file('nnbd.dart', '''
// @dart=2.10

// Compile time error if nnbd is enabled
int x;

void main() {
  print(x);
}
''')
      ])
    ]).create();
    var entrypoint = p.join(packageRoot, 'bin', 'nnbd.dart');
    client = await FrontendServerClient.start(
        entrypoint, p.join(packageRoot, 'out.dill'), vmPlatformDill,
        enabledExperiments: ['non-nullable']);
    var result = await client.compile();
    if (result == null) {
      fail('Expected compilation to be non-null');
    }
    client.accept();
    expect(result.errorCount, 1);
    expect(result.compilerOutputLines, contains(contains('int x;')));
  });

  test('can compile and recompile filenames with spaces', () async {
    await d.dir('a', [
      d.dir('bin', [
        d.file('main with spaces.dart', '''
void main() {
  print('hello world');
}
''')
      ]),
    ]).create();

    var entrypoint = p.join(packageRoot, 'bin', 'main with spaces.dart');
    client = await FrontendServerClient.start(entrypoint,
        p.join(packageRoot, 'out with spaces.dill'), vmPlatformDill);
    var result = await client.compile();
    if (result == null) {
      fail('Expected compilation to be non-null');
    }
    client.accept();
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(
        result.newSources,
        containsAll([
          File(entrypoint).uri,
        ]));
    expect(result.removedSources, isEmpty);
    expect(File(result.dillOutput).existsSync(), true);
    var processResult =
        await Process.run(Platform.resolvedExecutable, [result.dillOutput]);

    expect(processResult.stdout, startsWith('hello world'));
    expect(processResult.exitCode, 0);

    var appFile = File(entrypoint);
    var originalContent = await appFile.readAsString();
    var newContent = originalContent.replaceFirst('hello', 'goodbye');
    await appFile.writeAsString(newContent);
    result = await client.compile([appFile.uri]);
    if (result == null) {
      fail('Expected compilation to be non-null');
    }
    expect(result.compilerOutputLines, isEmpty);
    expect(result.errorCount, 0);
    expect(result.newSources, isEmpty);
    expect(result.removedSources, isEmpty);

    processResult =
        await Process.run(Platform.resolvedExecutable, [result.dillOutput]);
    expect(processResult.stdout, startsWith('goodbye world'));
    expect(processResult.exitCode, 0);
  });
}

Future<Isolate> waitForIsolatesAndResume(VmService vmService) async {
  var vm = await vmService.getVM();
  var isolates = vm.isolates;
  while (isolates == null || isolates.isEmpty) {
    await Future.delayed(const Duration(milliseconds: 100));
    vm = await vmService.getVM();
    isolates = vm.isolates;
  }
  var isolateRef = isolates.first;
  var isolate = await vmService.getIsolate(isolateRef.id!);
  while (isolate.pauseEvent?.kind != EventKind.kPauseStart) {
    await Future.delayed(const Duration(milliseconds: 100));
    isolate = await vmService.getIsolate(isolateRef.id!);
  }
  await vmService.resume(isolate.id!);
  return isolate;
}

final vmPlatformDill = p
    .toUri(p.join(sdkDir, 'lib', '_internal', 'vm_platform_strong.dill'))
    .toString();
final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));
