// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/run_hot.dart';
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  final Platform windowsPlatform = MockPlatform();
  final Platform notWindowsPlatform = MockPlatform();
  when(windowsPlatform.isWindows).thenReturn(true);
  when(notWindowsPlatform.isWindows).thenReturn(false);

  group('ProjectFileInvalidator linux/mac', () {
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
  bar:

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
    memoryFileSystem.file('new_dep/lib/new_dep.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');

    testUsingContext('No .packages, no pubspec', () async {
      // Instead of setting up multiple filesystems, passing a .packages file which does not exist.
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator('.packages-wrong', null);
      invalidator.findInvalidated();
      expect(invalidator.packageMap, isEmpty);
      expect(invalidator.updateTime, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      Platform: () => notWindowsPlatform,
    });

    testUsingContext('.packages only', () async {
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator(packagesFile.path, null);
      invalidator.findInvalidated();
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
      Platform: () => notWindowsPlatform,
    });

    testUsingContext('.packages and pubspec', () async {
      final FlutterProject flutterProject = await FlutterProject.fromDirectory(pubspecFile.parent);
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator(packagesFile.path, flutterProject);
      invalidator.findInvalidated();
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
      Platform: () => notWindowsPlatform,
    });

    testUsingContext('update to .packages adds files to invalidated', () async {
      final FlutterProject flutterProject = await FlutterProject.fromDirectory(pubspecFile.parent);
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator(packagesFile.path, flutterProject);
      invalidator.findInvalidated();
      packagesFile.writeAsStringSync(r'''
foo:file:///foo/lib/
bar:file:///.pub-cache/bar/lib/
baz:file:///baz/lib/
new_dep:file:///new_dep/lib/
test_package:file:///lib/
''');
      expect(invalidator.findInvalidated(), <String>['/new_dep/lib/new_dep.dart']);
      expect(invalidator.updateTime.containsKey('new_dep'), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      Platform: () => notWindowsPlatform,
    });
  });

  group('ProjectFileInvalidator windows', () {
    final MemoryFileSystem memoryFileSystem = MemoryFileSystem(style: FileSystemStyle.windows);
    // On windows .packages still contains file Uris, albeit ones with the Drive prefix.
    final File packagesFile = memoryFileSystem.file(r'C:\.packages')
      ..createSync()
      ..writeAsStringSync(r'''
foo:file:///C:/foo/lib/
bar:file:///C:/Pub/Cache/bar/lib/
baz:file:///C:/baz/lib/
test_package:file:///C:/lib/
''');
    memoryFileSystem.file(r'C:\pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: test_package

dependencies:
  foo: any
  bar:

dev_dependencies:
  baz: any
''');
    final File mainFile = memoryFileSystem.file(r'C:\lib\main.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(r'''
void main() {}
''');
    final File fooFile = memoryFileSystem.file(r'C:\foo\lib\foo.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    memoryFileSystem.file(r'C:\bar\lib\bar.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');
    final File bazFile = memoryFileSystem.file(r'C:\baz\lib\baz.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('');

    testUsingContext('No .packages, no pubspec', () async {
      // Instead of setting up multiple filesystems, passing a .packages file which does not exist.
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator('.packages-wrong', null);
      invalidator.findInvalidated();
      expect(invalidator.packageMap, isEmpty);
      expect(invalidator.updateTime, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      Platform: () => windowsPlatform,
    });

    testUsingContext('.packages only', () async {
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator(packagesFile.path, null);
      invalidator.findInvalidated();
      expect(invalidator.packageMap, <String, Uri>{
        'foo': Uri.file(r'C:\foo\lib\', windows: true),
        // Excluded because it is in pub cache.
        // 'bar': Uri.parse('file:///Pub/Cache/bar/lib/'),
        'baz': Uri.file(r'C:\baz\lib\', windows: true),
        'test_package': Uri.file(r'C:\lib\', windows: true),
      });
      expect(invalidator.updateTime, <String, int>{
        r'C:\baz\lib\baz.dart': bazFile.statSync().modified.millisecondsSinceEpoch,
        r'C:\lib\main.dart': mainFile.statSync().modified.millisecondsSinceEpoch,
        r'C:\foo\lib\foo.dart': fooFile.statSync().modified.millisecondsSinceEpoch,
      });
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      Platform: () => windowsPlatform,
    });

    testUsingContext('.packages and pubspec', () async {
      final FlutterProject flutterProject = await FlutterProject.fromDirectory(fs.directory(r'C:\'));
      final ProjectFileInvalidator invalidator = ProjectFileInvalidator(packagesFile.path, flutterProject);
      invalidator.findInvalidated();
      expect(invalidator.packageMap, <String, Uri>{
        'foo': Uri.file(r'C:\foo\lib\', windows: true),
        // Excluded because it is in pub cache.
        // 'bar': Uri.parse('file:///C:/Pub/Cache/bar/lib/'),
        // Excluded because it is a dev dependency/
        // 'baz': Uri.parse('file:///baz/lib/'),
        'test_package': Uri.file(r'C:\lib\', windows: true),
      });
      expect(invalidator.updateTime, <String, int>{
        r'C:\lib\main.dart': mainFile.statSync().modified.millisecondsSinceEpoch,
        r'C:\foo\lib\foo.dart': fooFile.statSync().modified.millisecondsSinceEpoch,
      });
      expect(invalidator.findInvalidated(), isEmpty);

      // Invalidate main.dart.
      mainFile.writeAsStringSync('void main() { }');
      expect(invalidator.findInvalidated(), <String>['file:///C:/lib/main.dart']);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
      Platform: () => windowsPlatform,
    });
  });
}

class MockPlatform extends Mock implements Platform {}
