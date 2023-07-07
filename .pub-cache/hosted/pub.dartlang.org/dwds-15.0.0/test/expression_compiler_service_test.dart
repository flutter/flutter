// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dwds/dwds.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'fixtures/logging.dart';

void main() async {
  group('expression compiler service with fake asset server', () {
    final logger = Logger('ExpressionCompilerServiceTest');
    ExpressionCompilerService service;
    HttpServer server;
    StreamController<String> output;
    Directory outputDir;

    Future<void> stop() async {
      await service?.stop();
      await server?.close();
      await output?.close();
      service = null;
      server = null;
      output = null;
    }

    setUp(() async {
      final systemTempDir = Directory.systemTemp;
      outputDir = systemTempDir.createTempSync('foo bar');
      final source = outputDir.uri.resolve('try.dart');
      final packages = outputDir.uri.resolve('package_config.json');
      final kernel = outputDir.uri.resolve('try.full.dill');
      final executable = Platform.resolvedExecutable;
      final binDir = p.dirname(executable);
      final dartdevc = p.join(binDir, 'snapshots', 'dartdevc.dart.snapshot');

      // redirect logs for testing
      output = StreamController<String>.broadcast();
      output.stream.listen(printOnFailure);

      configureLogWriter(
          customLogWriter: (level, message, {error, loggerName, stackTrace}) =>
              output.add('[$level] $loggerName: $message'));

      // start asset server
      server = await startHttpServer('localhost');
      final port = server.port;

      // start expression compilation service
      Response assetHandler(request) =>
          Response(200, body: File.fromUri(kernel).readAsBytesSync());
      service = ExpressionCompilerService('localhost', port, assetHandler,
          verbose: false);

      await service.initialize(moduleFormat: 'amd');

      // setup asset server
      serveHttpRequests(
          server, Cascade().add(service.handler).add(assetHandler).handler,
          (e, s) {
        logger.warning('Error serving requests', e, s);
      });

      // generate full dill
      File.fromUri(source)
        ..createSync()
        ..writeAsStringSync('''void main() {
          // breakpoint line
        }''');

      File.fromUri(packages)
        ..createSync()
        ..writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "try",
            "rootUri": "./",
            "packageUri": "./"
          }
        ]
      }
      ''');

      final args = [
        dartdevc,
        'try.dart',
        '-o',
        'try.js',
        '--experimental-output-compiled-kernel',
        '--multi-root',
        '${outputDir.uri}',
        '--multi-root-scheme',
        'org-dartlang-app',
        '--packages',
        packages.path,
      ];
      final process = await Process.start(executable, args,
              workingDirectory: outputDir.path)
          .then((p) {
        transformToLines(p.stdout).listen(output.add);
        transformToLines(p.stderr).listen(output.add);
        return p;
      });
      expect(await process.exitCode, 0,
          reason: 'failed running $executable with args $args');
      expect(File.fromUri(kernel).existsSync(), true,
          reason: 'failed to create full dill');
    });

    tearDown(() async {
      await stop();
      outputDir.deleteSync(recursive: true);
    });

    test('works with no errors', () async {
      expect(output.stream, neverEmits(contains('[SEVERE]')));
      expect(
          output.stream,
          emitsThrough(contains(
              '[INFO] ExpressionCompilerService: Updating dependencies...')));
      expect(
          output.stream,
          emitsThrough(contains(
              '[INFO] ExpressionCompilerService: Updated dependencies.')));
      expect(
          output.stream,
          emitsThrough(contains(
              '[FINEST] ExpressionCompilerService: Compiling "true" at')));
      expect(
          output.stream,
          emitsThrough(contains(
              '[FINEST] ExpressionCompilerService: Compiled "true" to:')));
      expect(output.stream,
          emitsThrough(contains('[INFO] ExpressionCompilerService: Stopped.')));

      final result = await service
          .updateDependencies({'try': ModuleInfo('try.full.dill', 'try.dill')});
      expect(result, true, reason: 'failed to update dependencies');

      final compilationResult = await service.compileExpressionToJs(
          '0', 'org-dartlang-app:/try.dart', 2, 1, {}, {}, 'try', 'true');

      expect(
          compilationResult,
          isA<ExpressionCompilationResult>()
              .having((r) => r.result, 'result', contains('return true;'))
              .having((r) => r.isError, 'isError', false));

      await stop();
    });
  });
}

Stream<String> transformToLines(Stream<List<int>> byteStream) {
  return byteStream
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter());
}
