// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('upgrade', () {
    bool _match(String line) => UpgradeCommand.matchesGitLine(line);

    test('regex match', () {
      expect(_match(' .../flutter_gallery/lib/demo/buttons_demo.dart    | 10 +--'), true);
      expect(_match(' dev/benchmarks/complex_layout/lib/main.dart        |  24 +-'), true);

      expect(_match(' rename {packages/flutter/doc => dev/docs}/styles.html (92%)'), true);
      expect(_match(' delete mode 100644 doc/index.html'), true);
      expect(_match(' create mode 100644 examples/flutter_gallery/lib/gallery/demo.dart'), true);

      expect(_match('Fast-forward'), true);
    });

    test('regex doesn\'t match', () {
      expect(_match('Updating 79cfe1e..5046107'), false);
      expect(_match('229 files changed, 6179 insertions(+), 3065 deletions(-)'), false);
    });

    group('findProjectRoot', () {
      Directory temp;

      setUp(() async {
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

      testUsingContext('in project', () async {
        await createProject();

        String proj = temp.path;
        expect(findProjectRoot(proj), proj);
        expect(findProjectRoot(path.join(proj, 'lib')), proj);

        String hello = path.join(Cache.flutterRoot, 'examples', 'hello_world');
        expect(findProjectRoot(hello), hello);
        expect(findProjectRoot(path.join(hello, 'lib')), hello);
      });

      testUsingContext('outside project', () async {
        await createProject();
        expect(findProjectRoot(temp.parent.path), null);
        expect(findProjectRoot(Cache.flutterRoot), null);
      });
    });
  });
}
