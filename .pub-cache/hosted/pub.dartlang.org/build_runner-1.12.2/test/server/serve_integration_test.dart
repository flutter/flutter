// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['integration'])

import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner/src/generate/watch_impl.dart' as watch_impl;

import 'package:_test_common/common.dart';
import 'package:_test_common/package_graphs.dart';

void main() {
  FutureOr<Response> Function(Request) handler;
  InMemoryRunnerAssetReader reader;
  InMemoryRunnerAssetWriter writer;
  StreamSubscription subscription;
  Completer<BuildResult> nextBuild;
  StreamController terminateController;

  final path = p.absolute('example');

  setUp(() async {
    final graph = buildPackageGraph({rootPackage('example', path: path): []});
    writer = InMemoryRunnerAssetWriter();
    reader = InMemoryRunnerAssetReader.shareAssetCache(writer.assets,
        rootPackage: 'example')
      ..cacheStringAsset(AssetId('example', 'web/initial.txt'), 'initial')
      ..cacheStringAsset(
          AssetId('example', '.packages'),
          '# Fake packages file\n'
          'example:file://fake/pkg/path')
      ..cacheStringAsset(
          makeAssetId('example|.dart_tool/package_config.json'),
          jsonEncode({
            'configVersion': 2,
            'packages': [
              {
                'name': 'example',
                'rootUri': 'file://fake/pkg/path',
                'packageUri': 'lib/'
              },
            ],
          }));

    terminateController = StreamController();
    final server = await watch_impl.watch(
      [applyToRoot(const UppercaseBuilder())],
      packageGraph: graph,
      reader: reader,
      writer: writer,
      logLevel: Level.OFF,
      directoryWatcherFactory: (path) => FakeWatcher(path),
      terminateEventStream: terminateController.stream,
      skipBuildScriptCheck: true,
    );
    handler = server.handlerFor('web');

    nextBuild = Completer<BuildResult>();
    subscription = server.buildResults.listen((result) {
      nextBuild.complete(result);
      nextBuild = Completer<BuildResult>();
    });
    await nextBuild.future;
  });

  tearDown(() async {
    await subscription.cancel();
    terminateController.add(null);
    await terminateController.close();
  });

  test('should serve original files', () async {
    final getHello = Uri.parse('http://localhost/initial.txt');
    final response = await handler(Request('GET', getHello));
    expect(await response.readAsString(), 'initial');
  });

  test('should serve built files', () async {
    final getHello = Uri.parse('http://localhost/initial.g.txt');
    reader.cacheStringAsset(AssetId('example', 'web/initial.g.txt'), 'INITIAL');
    final response = await handler(Request('GET', getHello));
    expect(await response.readAsString(), 'INITIAL');
  });

  test('should 404 on missing files', () async {
    final get404 = Uri.parse('http://localhost/404.txt');
    final response = await handler(Request('GET', get404));
    expect(await response.readAsString(), 'Not Found');
  });

  test('should serve newly added files', () async {
    final getNew = Uri.parse('http://localhost/new.txt');
    reader.cacheStringAsset(AssetId('example', 'web/new.txt'), 'New');
    await Future<void>.value();
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.ADD, '$path/web/new.txt'),
    );
    await nextBuild.future;
    final response = await handler(Request('GET', getNew));
    expect(await response.readAsString(), 'New');
  });

  test('should serve built newly added files', () async {
    final getNew = Uri.parse('http://localhost/new.g.txt');
    reader.cacheStringAsset(AssetId('example', 'web/new.txt'), 'New');
    await Future<void>.value();
    FakeWatcher.notifyWatchers(
      WatchEvent(ChangeType.ADD, '$path/web/new.txt'),
    );
    await nextBuild.future;
    final response = await handler(Request('GET', getNew));
    expect(await response.readAsString(), 'NEW');
  });

  group(r'/$graph', () {
    FutureOr<Response> requestGraphPath(String path) =>
        handler(Request('GET', Uri.parse('http://localhost/\$graph$path')));

    for (var slashOrNot in ['', '/']) {
      test('/\$graph$slashOrNot should (try to) send the HTML page', () async {
        expect(
            requestGraphPath(slashOrNot),
            throwsA(isA<AssetNotFoundException>().having(
                (e) => e.assetId,
                'assetId',
                AssetId.parse('build_runner|lib/src/server/graph_viz.html'))));
      });
    }

    void test404(String testName, String path, String expected) {
      test(testName, () async {
        var response = await requestGraphPath(path);

        expect(response.statusCode, 404);
        expect(await response.readAsString(), expected);
      });
    }

    test404('404s on an unsupported URL', '/bob', 'Bad request: "bob".');
    test404('404s on an unsupported URL', '/bob/?q=bob',
        'Bad request: "bob/?q=bob".');
    test404('empty query causes 404', '?=', 'Bad request: "?=".');
    test404('bad asset query', '?q=bob|bob',
        'Could not find asset in build graph: bob|bob');
    test404(
        'bad path query',
        '?q=bob/bob',
        'Could not find asset for path "bob/bob". Tried:\n'
            '- example|bob/bob\n'
            '- example|web/bob/bob');
    test404(
        'valid path, 2nd try',
        '?q=bob/initial.txt',
        'Could not find asset for path "bob/initial.txt". Tried:\n'
            '- example|bob/initial.txt\n'
            '- example|web/bob/initial.txt');

    void testSuccess(String testName, String path, String expectedId) {
      test(testName, () async {
        var response = await requestGraphPath(path);

        var output = await response.readAsString();
        expect(response.statusCode, 200, reason: output);
        var json = jsonDecode(output) as Map<String, dynamic>;

        expect(json, containsPair('primary', containsPair('id', expectedId)));
      });
    }

    testSuccess('valid path', '?q=web/initial.txt', 'example|web/initial.txt');
    testSuccess('valid path, leading slash', '?q=/web/initial.txt',
        'example|web/initial.txt');
    testSuccess('valid path, assuming root', '?q=initial.txt',
        'example|web/initial.txt');
    testSuccess('valid path, assuming root, leading slash', '?q=/initial.txt',
        'example|web/initial.txt');
    testSuccess('valid AssetId', '?q=example|web/initial.txt',
        'example|web/initial.txt');
  });
}

class UppercaseBuilder implements Builder {
  const UppercaseBuilder();

  @override
  Future<void> build(BuildStep buildStep) async {
    final content = await buildStep.readAsString(buildStep.inputId);
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.g.txt'),
      content.toUpperCase(),
    );
  }

  @override
  final buildExtensions = const {
    'txt': ['g.txt']
  };
}
