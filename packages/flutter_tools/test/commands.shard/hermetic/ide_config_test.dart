// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/ide_config.dart';
import 'package:flutter_tools/src/template.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('ide_config', () {
    late MemoryFileSystem fs;
    late FakeToolContext toolContext;
    late Directory tempDir;
    late Directory templateDir;
    late Directory intellijDir;
    late Directory toolsDir;

    Map<String, String> getFilesystemContents([Directory? root]) {
      final String tempPath = tempDir.absolute.path;
      final List<String> paths = (root ?? tempDir).listSync(recursive: true).map((
        FileSystemEntity entity,
      ) {
        final String relativePath = fs.path.relative(entity.path, from: tempPath);
        return relativePath;
      }).toList();
      final contents = <String, String>{};
      for (final path in paths) {
        final String absPath = fs.path.join(tempPath, path);
        if (fs.isDirectorySync(absPath)) {
          contents[path] = 'dir';
        } else if (fs.isFileSync(absPath)) {
          contents[path] = fs.file(absPath).readAsStringSync();
        }
      }
      return contents;
    }

    Map<String, String> getManifest(Directory base, String marker, {bool isTemplate = false}) {
      final String basePath = fs.path.relative(base.path, from: tempDir.absolute.path);
      final String suffix = isTemplate ? Template.copyTemplateExtension : '';
      return <String, String>{
        fs.path.join(basePath, '.idea'): 'dir',
        fs.path.join(basePath, '.idea', 'modules.xml$suffix'): 'modules $marker',
        fs.path.join(basePath, '.idea', 'vcs.xml$suffix'): 'vcs $marker',
        fs.path.join(basePath, '.idea', '.name$suffix'): 'codeStyleSettings $marker',
        fs.path.join(basePath, '.idea', 'runConfigurations'): 'dir',
        fs.path.join(basePath, '.idea', 'runConfigurations', 'hello_world.xml$suffix'):
            'hello_world $marker',
        fs.path.join(basePath, 'flutter.iml$suffix'): 'flutter $marker',
        fs.path.join(basePath, 'packages', 'new', 'deep.iml$suffix'): 'deep $marker',
        fs.path.join(basePath, 'example', 'gallery', 'android.iml$suffix'): 'android $marker',
      };
    }

    void populateDir(Map<String, String> manifest) {
      for (final String key in manifest.keys) {
        if (manifest[key] == 'dir') {
          tempDir.childDirectory(key).createSync(recursive: true);
        }
      }
      for (final String key in manifest.keys) {
        if (manifest[key] != 'dir') {
          tempDir.childFile(key)
            ..createSync(recursive: true)
            ..writeAsStringSync(manifest[key]!);
        }
      }
    }

    bool fileOrDirectoryExists(String path) {
      final String absPath = fs.path.join(tempDir.absolute.path, path);
      return fs.file(absPath).existsSync() || fs.directory(absPath).existsSync();
    }

    Future<void> updateIdeConfig({
      Directory? dir,
      List<String> args = const <String>[],
      Map<String, String> expectedContents = const <String, String>{},
      List<String> unexpectedPaths = const <String>[],
    }) async {
      dir ??= tempDir;
      Cache.flutterRoot = tempDir.absolute.path;
      final command = IdeConfigCommand(toolContext: toolContext);
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['ide-config', ...args]);

      for (final String path in expectedContents.keys) {
        final String absPath = fs.path.join(tempDir.absolute.path, path);
        expect(
          fileOrDirectoryExists(fs.path.join(dir.path, path)),
          true,
          reason: "$path doesn't exist",
        );
        if (fs.file(absPath).existsSync()) {
          expect(
            fs.file(absPath).readAsStringSync(),
            equals(expectedContents[path]),
            reason: "$path contents don't match",
          );
        }
      }
      for (final path in unexpectedPaths) {
        expect(fileOrDirectoryExists(fs.path.join(dir.path, path)), false, reason: '$path exists');
      }
    }

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      fs = MemoryFileSystem.test();
      toolContext = FakeToolContext(fs: fs);
      tempDir = fs.systemTempDirectory.createTempSync('flutter_tools_ide_config_test.');
      final Directory packagesDir = tempDir.childDirectory('packages')..createSync(recursive: true);
      toolsDir = packagesDir.childDirectory('flutter_tools')..createSync();
      templateDir = toolsDir.childDirectory('ide_templates')..createSync();
      intellijDir = templateDir.childDirectory('intellij')..createSync();
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    testWithoutContext("doesn't touch existing files without --overwrite", () async {
      final Map<String, String> templateManifest = getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      final Map<String, String> flutterManifest = getManifest(tempDir, 'existing');
      populateDir(templateManifest);
      populateDir(flutterManifest);
      final Map<String, String> expectedContents = getFilesystemContents();
      return updateIdeConfig(expectedContents: expectedContents);
    });

    testWithoutContext('creates non-existent files', () async {
      final Map<String, String> templateManifest = getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      final Map<String, String> flutterManifest = getManifest(tempDir, 'template');
      populateDir(templateManifest);
      final expectedContents = <String, String>{...templateManifest, ...flutterManifest};
      return updateIdeConfig(expectedContents: expectedContents);
    });

    testWithoutContext('overwrites existing files with --overwrite', () async {
      final Map<String, String> templateManifest = getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      final Map<String, String> flutterManifest = getManifest(tempDir, 'existing');
      populateDir(templateManifest);
      populateDir(flutterManifest);
      final Map<String, String> overwrittenManifest = getManifest(tempDir, 'template');
      final expectedContents = <String, String>{...templateManifest, ...overwrittenManifest};
      return updateIdeConfig(args: <String>['--overwrite'], expectedContents: expectedContents);
    });

    testWithoutContext('only adds new templates without --overwrite', () async {
      final Map<String, String> templateManifest = getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      final String flutterIml = fs.path.join(
        'packages',
        'flutter_tools',
        'ide_templates',
        'intellij',
        'flutter.iml${Template.copyTemplateExtension}',
      );
      templateManifest.remove(flutterIml);
      populateDir(templateManifest);
      templateManifest[flutterIml] = 'flutter existing';
      final Map<String, String> flutterManifest = getManifest(tempDir, 'existing');
      populateDir(flutterManifest);
      final expectedContents = <String, String>{...flutterManifest, ...templateManifest};
      return updateIdeConfig(
        args: <String>['--update-templates'],
        expectedContents: expectedContents,
      );
    });

    testWithoutContext('update all templates with --overwrite', () async {
      final Map<String, String> templateManifest = getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      populateDir(templateManifest);
      final Map<String, String> flutterManifest = getManifest(tempDir, 'existing');
      populateDir(flutterManifest);
      final Map<String, String> updatedTemplates = getManifest(
        intellijDir,
        'existing',
        isTemplate: true,
      );
      final expectedContents = <String, String>{...flutterManifest, ...updatedTemplates};
      return updateIdeConfig(
        args: <String>['--update-templates', '--overwrite'],
        expectedContents: expectedContents,
      );
    });

    testWithoutContext('removes deleted imls with --overwrite', () async {
      final Map<String, String> templateManifest = getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      populateDir(templateManifest);
      final Map<String, String> flutterManifest = getManifest(tempDir, 'existing');
      flutterManifest.remove('flutter.iml');
      populateDir(flutterManifest);
      final Map<String, String> updatedTemplates = getManifest(
        intellijDir,
        'existing',
        isTemplate: true,
      );
      final String flutterIml = fs.path.join(
        'packages',
        'flutter_tools',
        'ide_templates',
        'intellij',
        'flutter.iml${Template.copyTemplateExtension}',
      );
      updatedTemplates.remove(flutterIml);
      final expectedContents = <String, String>{...flutterManifest, ...updatedTemplates};
      return updateIdeConfig(
        args: <String>['--update-templates', '--overwrite'],
        expectedContents: expectedContents,
      );
    });

    testWithoutContext(
      'removes deleted imls with --overwrite, including empty parent dirs',
      () async {
        final Map<String, String> templateManifest = getManifest(
          intellijDir,
          'template',
          isTemplate: true,
        );
        populateDir(templateManifest);
        final Map<String, String> flutterManifest = getManifest(tempDir, 'existing');
        flutterManifest.remove(fs.path.join('packages', 'new', 'deep.iml'));
        populateDir(flutterManifest);
        final Map<String, String> updatedTemplates = getManifest(
          intellijDir,
          'existing',
          isTemplate: true,
        );
        String deepIml = fs.path.join('packages', 'flutter_tools', 'ide_templates', 'intellij');
        // Remove the all the dir entries too.
        updatedTemplates.remove(deepIml);
        deepIml = fs.path.join(deepIml, 'packages');
        updatedTemplates.remove(deepIml);
        deepIml = fs.path.join(deepIml, 'new');
        updatedTemplates.remove(deepIml);
        deepIml = fs.path.join(deepIml, 'deep.iml');
        updatedTemplates.remove(deepIml);
        final expectedContents = <String, String>{...flutterManifest, ...updatedTemplates};
        return updateIdeConfig(
          args: <String>['--update-templates', '--overwrite'],
          expectedContents: expectedContents,
        );
      },
    );
  });
}
