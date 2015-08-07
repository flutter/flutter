// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:sky_tools/src/init.dart';
import 'package:test/test.dart';

main() => defineTests();

defineTests() {
  group('', () {
    Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('sky_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // Verify that we create a project that os well-formed.
    test('init sky-simple', () async {
      InitCommandHandler handler = new InitCommandHandler();
      _MockArgResults results = new _MockArgResults();
      results.values['help'] = false;
      results.values['pub'] = true;
      results.values['out'] = temp.path;
      await handler.processArgResults(results);
      String path = p.join(temp.path, 'lib/main.dart');
      print(path);
      expect(new File(path).existsSync(), true);
      ProcessResult exec = Process.runSync('dartanalyzer', [path],
          workingDirectory: temp.path);
      expect(exec.exitCode, 0);
    });
  });
}

class _MockArgResults implements ArgResults {
  Map values = {};
  operator [](String name) => values[name];
  List<String> get arguments => null;
  ArgResults get command => null;
  String get name => null;
  Iterable<String> get options => values.keys;
  List<String> get rest => null;
  bool wasParsed(String name) => values.containsKey(name);
}
