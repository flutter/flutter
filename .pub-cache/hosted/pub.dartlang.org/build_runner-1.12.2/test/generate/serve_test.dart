// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:pedantic/pedantic.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:build_runner/src/server/server.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:build_runner/src/generate/watch_impl.dart' as watch_impl;
import 'package:build_test/build_test.dart';

import 'package:_test_common/common.dart';
import 'package:_test_common/package_graphs.dart';

void main() {
  group('ServeHandler', () {
    InMemoryRunnerAssetWriter writer;

    setUp(() async {
      _terminateServeController = StreamController();
      writer = InMemoryRunnerAssetWriter();
      await writer.writeAsString(makeAssetId('a|.packages'), '''
# Fake packages file
a:file://fake/pkg/path
''');
      await writer.writeAsString(
          makeAssetId('a|.dart_tool/package_config.json'),
          jsonEncode({
            'configVersion': 2,
            'packages': [
              {
                'name': 'a',
                'rootUri': 'file://fake/pkg/path',
                'packageUri': 'lib/'
              },
            ],
          }));
    });

    tearDown(() async {
      FakeWatcher.watchers.clear();
      await terminateServe();
    });

    test('does basic builds', () async {
      var handler = await createHandler(
          [applyToRoot(TestBuilder())], {'a|web/a.txt': 'a'}, writer);
      var results = StreamQueue(handler.buildResults);
      var result = await results.next;
      checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

      await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');

      result = await results.next;
      checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);
    });

    test('blocks serving files until the build is done', () async {
      var buildBlocker1 = Completer<void>();
      var nextBuildBlocker = buildBlocker1.future;

      var handler = await createHandler(
          [applyToRoot(TestBuilder(extraWork: (_, __) => nextBuildBlocker))],
          {'a|web/a.txt': 'a'},
          writer);
      var webHandler = handler.handlerFor('web');
      var results = StreamQueue(handler.buildResults);
      // Give the build enough time to get started.
      await wait(100);

      var request = Request('GET', Uri.parse('http://localhost:8000/a.txt'));
      unawaited((webHandler(request) as Future<Response>)
          .then(expectAsync1((Response response) {
        expect(buildBlocker1.isCompleted, isTrue,
            reason: 'Server shouldn\'t respond until builds are done.');
      })));
      await wait(250);
      buildBlocker1.complete();
      var result = await results.next;
      checkBuild(result, outputs: {'a|web/a.txt.copy': 'a'}, writer: writer);

      /// Next request completes right away.
      var buildBlocker2 = Completer<void>();
      unawaited((webHandler(request) as Future<Response>)
          .then(expectAsync1((response) {
        expect(buildBlocker1.isCompleted, isTrue);
        expect(buildBlocker2.isCompleted, isFalse);
      })));

      /// Make an edit to force another build, and we should block again.
      nextBuildBlocker = buildBlocker2.future;
      await writer.writeAsString(makeAssetId('a|web/a.txt'), 'b');
      // Give the build enough time to get started.
      await wait(500);
      var done = Completer<void>();
      unawaited((webHandler(request) as Future<Response>)
          .then(expectAsync1((response) {
        expect(buildBlocker1.isCompleted, isTrue);
        expect(buildBlocker2.isCompleted, isTrue);
        done.complete();
      })));
      await wait(250);
      buildBlocker2.complete();
      result = await results.next;
      checkBuild(result, outputs: {'a|web/a.txt.copy': 'b'}, writer: writer);

      /// Make sure we actually see the final request finish.
      return done.future;
    });
  });
}

final _debounceDelay = Duration(milliseconds: 10);
StreamController _terminateServeController;

/// Start serving files and running builds.
Future<ServeHandler> createHandler(List<BuilderApplication> builders,
    Map<String, String> inputs, InMemoryRunnerAssetWriter writer) async {
  await Future.wait(inputs.keys.map((serializedId) async {
    await writer.writeAsString(makeAssetId(serializedId), inputs[serializedId]);
  }));
  final packageGraph =
      buildPackageGraph({rootPackage('a', path: path.absolute('a')): []});
  final reader = InMemoryRunnerAssetReader.shareAssetCache(writer.assets,
      rootPackage: packageGraph.root.name);
  final watcherFactory = (String path) => FakeWatcher(path);

  return watch_impl.watch(builders,
      deleteFilesByDefault: true,
      debounceDelay: _debounceDelay,
      directoryWatcherFactory: watcherFactory,
      reader: reader,
      writer: writer,
      packageGraph: packageGraph,
      terminateEventStream: _terminateServeController.stream,
      logLevel: Level.OFF,
      skipBuildScriptCheck: true);
}

/// Tells the program to terminate.
Future terminateServe() {
  assert(_terminateServeController != null);

  /// Can add any type of event.
  _terminateServeController.add(null);
  return _terminateServeController.close();
}
