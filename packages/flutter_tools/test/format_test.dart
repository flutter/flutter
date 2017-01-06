// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/commands/format.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('format', () {
    Directory temp;

    setUp(() {
      Cache.disableLocking();
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    Future<Null> createProject() async {
      CreateCommand command = new CreateCommand();
      CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', temp.path]);
    }

    testUsingContext('a file', () async {
      await createProject();

      File srcFile = fs.file(path.join(temp.path, 'lib', 'main.dart'));
      String original = srcFile.readAsStringSync();
      srcFile.writeAsStringSync(original.replaceFirst('main()', 'main(  )'));

      FormatCommand command = new FormatCommand();
      CommandRunner<Null> runner = createTestCommandRunner(command);
      await runner.run(<String>['format', srcFile.path]);

      String formatted = srcFile.readAsStringSync();
      expect(formatted, original);
    });
  });
}
