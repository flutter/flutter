// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:flutter_tools/src/commands/ide_config.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('ide_config', () {
    Directory temp;
    Directory templateDir;
    Directory intellijDir;
    Directory toolsDir;

    Map<String, String> _getFilesystemContents([Directory root]) {
      final String tempPath = temp.absolute.path;
      final List<String> paths =
          (root ?? temp).listSync(recursive: true).map((FileSystemEntity entity) {
        final String relativePath = fs.path.relative(entity.path, from: tempPath);
        return relativePath;
      }).toList();
      final Map<String, String> contents = <String, String>{};
      for (String path in paths) {
        final String absPath = fs.path.join(tempPath, path);
        if (fs.isDirectorySync(absPath)) {
          contents[path] = 'dir';
        } else if (fs.isFileSync(absPath)) {
          contents[path] = fs.file(absPath).readAsStringSync();
        }
      }
      return contents;
    }

    Map<String, String> _getManifest(Directory base, String marker, {bool isTemplate: false}) {
      final String basePath = fs.path.relative(base.path, from: temp.absolute.path);
      final String suffix = isTemplate ? Template.copyTemplateExtension : '';
      return <String, String>{
        fs.path.join(basePath, '.idea'): 'dir',
        fs.path.join(basePath, '.idea', 'modules.xml$suffix'): 'modules $marker',
        fs.path.join(basePath, '.idea', 'vcs.xml$suffix'): 'vcs $marker',
        fs.path.join(basePath, '.idea', '.name$suffix'):
            'codeStyleSettings $marker',
        fs.path.join(basePath, '.idea', 'runConfigurations'): 'dir',
        fs.path.join(basePath, '.idea', 'runConfigurations', 'hello_world.xml$suffix'):
            'hello_world $marker',
        fs.path.join(basePath, 'flutter.iml$suffix'): 'flutter $marker',
        fs.path.join(basePath, 'packages', 'new', 'deep.iml$suffix'): 'deep $marker',
      };
    }

    void _populateDir(Map<String, String> manifest) {
      for (String key in manifest.keys) {
        if (manifest[key] == 'dir') {
          temp.childDirectory(key)..createSync(recursive: true);
        }
      }
      for (String key in manifest.keys) {
        if (manifest[key] != 'dir') {
          temp.childFile(key)
            ..createSync(recursive: true)
            ..writeAsStringSync(manifest[key]);
        }
      }
    }

    bool _fileOrDirectoryExists(String path) {
      final String absPath = fs.path.join(temp.absolute.path, path);
      return fs.file(absPath).existsSync() || fs.directory(absPath).existsSync();
    }

    Future<Null> _updateIdeConfig({
      Directory dir,
      List<String> args = const <String>[],
      Map<String, String> expectedContents = const <String, String>{},
      List<String> unexpectedPaths = const <String>[],
    }) async {
      dir ??= temp;
      final IdeConfigCommand command = new IdeConfigCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      final List<String> finalArgs = <String>['--flutter-root=${temp.absolute.path}', 'ide-config'];
      finalArgs.addAll(args);
      await runner.run(finalArgs);

      for (String path in expectedContents.keys) {
        final String absPath = fs.path.join(temp.absolute.path, path);
        expect(_fileOrDirectoryExists(fs.path.join(dir.path, path)), true,
            reason: "$path doesn't exist");
        if (fs.file(absPath).existsSync()) {
          expect(fs.file(absPath).readAsStringSync(), equals(expectedContents[path]),
              reason: "$path contents don't match");
        }
      }
      for (String path in unexpectedPaths) {
        expect(_fileOrDirectoryExists(fs.path.join(dir.path, path)), false, reason: '$path exists');
      }
    }

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_tools_');
      final Directory packagesDir = temp.childDirectory('packages')..createSync(recursive: true);
      toolsDir = packagesDir.childDirectory('flutter_tools')..createSync();
      templateDir = toolsDir.childDirectory('ide_templates')..createSync();
      intellijDir = templateDir.childDirectory('intellij')..createSync();
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    testUsingContext("doesn't touch existing files without --overwrite", () async {
      final Map<String, String> templateManifest = _getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      final Map<String, String> flutterManifest = _getManifest(
        temp,
        'existing',
      );
      _populateDir(templateManifest);
      _populateDir(flutterManifest);
      final Map<String, String> expectedContents = _getFilesystemContents();
      return _updateIdeConfig(
        expectedContents: expectedContents,
      );
    }, timeout: const Timeout.factor(2.0));

    testUsingContext('creates non-existent files', () async {
      final Map<String, String> templateManifest = _getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      final Map<String, String> flutterManifest = _getManifest(
        temp,
        'template',
      );
      _populateDir(templateManifest);
      final Map<String, String> expectedContents = templateManifest;
      expectedContents.addAll(flutterManifest);
      return _updateIdeConfig(
        expectedContents: expectedContents,
      );
    }, timeout: const Timeout.factor(2.0));

    testUsingContext('overwrites existing files with --overwrite', () async {
      final Map<String, String> templateManifest = _getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      final Map<String, String> flutterManifest = _getManifest(
        temp,
        'existing',
      );
      _populateDir(templateManifest);
      _populateDir(flutterManifest);
      final Map<String, String> overwrittenManifest = _getManifest(
        temp,
        'template',
      );
      final Map<String, String> expectedContents = templateManifest;
      expectedContents.addAll(overwrittenManifest);
      return _updateIdeConfig(
        args: <String>['--overwrite'],
        expectedContents: expectedContents,
      );
    }, timeout: const Timeout.factor(2.0));

    testUsingContext('only adds new templates without --overwrite', () async {
      final Map<String, String> templateManifest = _getManifest(
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
      _populateDir(templateManifest);
      templateManifest[flutterIml] = 'flutter existing';
      final Map<String, String> flutterManifest = _getManifest(
        temp,
        'existing',
      );
      _populateDir(flutterManifest);
      final Map<String, String> expectedContents = flutterManifest;
      expectedContents.addAll(templateManifest);
      return _updateIdeConfig(
        args: <String>['--update-templates'],
        expectedContents: expectedContents,
      );
    }, timeout: const Timeout.factor(2.0));

    testUsingContext('update all templates with --overwrite', () async {
      final Map<String, String> templateManifest = _getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      _populateDir(templateManifest);
      final Map<String, String> flutterManifest = _getManifest(
        temp,
        'existing',
      );
      _populateDir(flutterManifest);
      final Map<String, String> updatedTemplates = _getManifest(
        intellijDir,
        'existing',
        isTemplate: true,
      );
      final Map<String, String> expectedContents = flutterManifest;
      expectedContents.addAll(updatedTemplates);
      return _updateIdeConfig(
        args: <String>['--update-templates', '--overwrite'],
        expectedContents: expectedContents,
      );
    }, timeout: const Timeout.factor(2.0));

    testUsingContext('removes deleted imls with --overwrite', () async {
      final Map<String, String> templateManifest = _getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      _populateDir(templateManifest);
      final Map<String, String> flutterManifest = _getManifest(
        temp,
        'existing',
      );
      flutterManifest.remove('flutter.iml');
      _populateDir(flutterManifest);
      final Map<String, String> updatedTemplates = _getManifest(
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
      final Map<String, String> expectedContents = flutterManifest;
      expectedContents.addAll(updatedTemplates);
      return _updateIdeConfig(
        args: <String>['--update-templates', '--overwrite'],
        expectedContents: expectedContents,
      );
    }, timeout: const Timeout.factor(2.0));

    testUsingContext('removes deleted imls with --overwrite, including empty parent dirs', () async {
      final Map<String, String> templateManifest = _getManifest(
        intellijDir,
        'template',
        isTemplate: true,
      );
      _populateDir(templateManifest);
      final Map<String, String> flutterManifest = _getManifest(
        temp,
        'existing',
      );
      flutterManifest.remove(fs.path.join('packages', 'new', 'deep.iml'));
      _populateDir(flutterManifest);
      final Map<String, String> updatedTemplates = _getManifest(
        intellijDir,
        'existing',
        isTemplate: true,
      );
      String deepIml = fs.path.join(
        'packages',
        'flutter_tools',
        'ide_templates',
        'intellij');
      // Remove the all the dir entries too.
      updatedTemplates.remove(deepIml);
      deepIml = fs.path.join(deepIml, 'packages');
      updatedTemplates.remove(deepIml);
      deepIml = fs.path.join(deepIml, 'new');
      updatedTemplates.remove(deepIml);
      deepIml = fs.path.join(deepIml, 'deep.iml');
      updatedTemplates.remove(deepIml);
      final Map<String, String> expectedContents = flutterManifest;
      expectedContents.addAll(updatedTemplates);
      return _updateIdeConfig(
        args: <String>['--update-templates', '--overwrite'],
        expectedContents: expectedContents,
      );
    }, timeout: const Timeout.factor(2.0));

  });
}
