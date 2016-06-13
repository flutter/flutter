// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/dart/source_graph.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('source_graph', () {
    Directory temp;

    setUp(() {
      FlutterCommandRunner.initFlutterRoot();
      temp = Directory.systemTemp.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    test('initial parse', () {
      Directory directory = new Directory('../../examples/flutter_gallery');
      SourceGraph graph = new SourceGraph(directory, 'lib/main.dart');

      graph.initialParse();
      expect(graph.sources.length, greaterThan(100));
    });

    testUsingContext('parse with changes', () async {
      await _createProject(temp);

      // initial parse
      SourceGraph graph = new SourceGraph(temp, 'lib/main.dart');
      graph.initialParse();
      expect(graph.sources.length, greaterThan(100));

      // TODO(devoncarew): touch the main file, verify incremental is correct

      // TODO(devoncarew): reparse with no changes, expect that there are no changes

      // touch the .packages file
      File packagesFile = new File('${temp.path}/.packages');
      packagesFile.writeAsStringSync(packagesFile.readAsStringSync() + '\n');
      graph.reparseSources();
      expect(graph.wasIncremental, false);
    });

    test('flush cached file contents', () {
      SourceGraph graph = new SourceGraph(Directory.current, 'test/source_graph_test.dart');
      graph.initialParse();
      expect(graph.sources.length, greaterThan(100));
      expect(graph.sources.first.hasCachedFileContents, true);

      graph.flushCachedFileContents();
      expect(graph.sources.first.hasCachedFileContents, false);
    });
  });
}

Future<Null> _createProject(Directory dir) async {
  Cache.flutterRoot = '../..';
  CreateCommand command = new CreateCommand();
  CommandRunner runner = createTestCommandRunner(command);
  int code = await runner.run(<String>['create', dir.path]);
  expect(code, 0);
}
