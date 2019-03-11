// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/run_hot.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group(ProjectFileInvalidator, () {
    final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
    final File packagesFile = memoryFileSystem.file('.packages')
      ..createSync()
      ..writeAsStringSync(r'''
foo:file:///foo/lib/
bar:file:///.pub-cache/bar/lib/
baz:file:///baz/lib/
test_package:file:///lib/
''');
    final File pubspecFile = memoryFileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: test_package

dependencies:
  foo: any
  bar: any

dev_dependencies:
  baz: any
''');
    final File mainFile = memoryFileSystem.file('lib/main.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
void main() {}
''');
    final File fooFile = memoryFileSystem.file('foo/lib/foo.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    memoryFileSystem.file('bar/lib/bar.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    final File bazFile = memoryFileSystem.file('baz/lib/baz.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');

    testUsingContext('No .packages, no pubspec', () async {
      // Instead of setting up multiple filesystems, passing a .packages file which does not exist.
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator('.packages-wrong', null);
      invalidator.initialize();
      expect(invalidator.packageMap, isEmpty);
      expect(invalidator.updateTime, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('.packages only', () async {
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator(packagesFile.path, null);
      invalidator.initialize();
      expect(invalidator.packageMap, <String, Uri>{
        'foo': Uri.parse('file:///foo/lib/'),
        // Excluded because it is in pub cache.
        // 'bar': Uri.parse('file:///.pub-cache/bar/lib/'),
        'baz': Uri.parse('file:///baz/lib/'),
        'test_package': Uri.parse('file:///lib/'),
      });
      expect(invalidator.updateTime, <String, int>{
        '/baz/lib/baz.dart': bazFile.statSync().modified.millisecondsSinceEpoch,
        '/lib/main.dart': mainFile.statSync().modified.millisecondsSinceEpoch,
        '/foo/lib/foo.dart': fooFile.statSync().modified.millisecondsSinceEpoch,
      });
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('.packages and pubspec', () async {
      final FlutterProject flutterProject = await FlutterProject.fromDirectory(pubspecFile.parent);
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator(packagesFile.path, flutterProject);
      invalidator.initialize();
      expect(invalidator.packageMap, <String, Uri>{
        'foo': Uri.parse('file:///foo/lib/'),
        // Excluded because it is in pub cache.
        // 'bar': Uri.parse('file:///.pub-cache/bar/lib/'),
        // Excluded because it is a dev dependency/
        // 'baz': Uri.parse('file:///baz/lib/'),
        'test_package': Uri.parse('file:///lib/'),
      });
      expect(invalidator.updateTime, <String, int>{
        '/foo/lib/foo.dart': fooFile.statSync().modified.millisecondsSinceEpoch,
        '/lib/main.dart':mainFile.statSync().modified.millisecondsSinceEpoch,
      });
      expect(invalidator.findInvalidated(), isEmpty);

      // Invalidate main.dart.
      mainFile.writeAsStringSync('void main() { }');
      expect(invalidator.findInvalidated(), <String>['/lib/main.dart']);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
    });
  });
}
