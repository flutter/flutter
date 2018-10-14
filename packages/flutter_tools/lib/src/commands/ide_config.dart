// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../cache.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../template.dart';

class IdeConfigCommand extends FlutterCommand {
  IdeConfigCommand({this.hidden = false}) {
    argParser.addFlag(
      'overwrite',
      negatable: true,
      defaultsTo: false,
      help: 'When performing operations, overwrite existing files.',
    );
    argParser.addFlag(
      'update-templates',
      negatable: false,
      help: 'Update the templates in the template directory from the current '
          'configuration files. This is the opposite of what $name usually does. '
          'Will search the flutter tree for .iml files and copy any missing ones '
          'into the template directory. If --overwrite is also specified, it will '
          'update any out-of-date files, and remove any deleted files from the '
          'template directory.',
    );
    argParser.addFlag(
      'with-root-module',
      negatable: true,
      defaultsTo: true,
      help: 'Also create module that corresponds to the root of Flutter tree. '
          'This makes the entire Flutter tree browsable and searchable in IDE. '
          'Without this flag, only the child modules will be visible in IDE.',
    );
  }

  @override
  final String name = 'ide-config';

  @override
  final String description = 'Configure the IDE for use in the Flutter tree.\n\n'
      'If run on a Flutter tree that is already configured for the IDE, this '
      'command will add any new configurations, recreate any files that are '
      'missing. If --overwrite is specified, will revert existing files to '
      'the template versions, reset the module list, and return configuration '
      'settings to the template versions.\n\n'
      'This command is intended for Flutter developers to help them set up the'
      "Flutter tree for development in an IDE. It doesn't affect other projects.\n\n"
      'Currently, IntelliJ is the default (and only) IDE that may be configured.';

  @override
  final bool hidden;

  @override
  String get invocation => '${runner.executableName} $name';

  static const String _ideName = 'intellij';
  Directory get _templateDirectory {
    return fs.directory(fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      'ide_templates',
      _ideName,
    ));
  }

  Directory get _createTemplatesDirectory {
    return fs.directory(fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      'templates',
    ));
  }

  Directory get _flutterRoot => fs.directory(fs.path.absolute(Cache.flutterRoot));

  // Returns true if any entire path element is equal to dir.
  bool _hasDirectoryInPath(FileSystemEntity entity, String dir) {
    String path = entity.absolute.path;
    while (path.isNotEmpty && fs.path.dirname(path) != path) {
      if (fs.path.basename(path) == dir) {
        return true;
      }
      path = fs.path.dirname(path);
    }
    return false;
  }

  // Returns true if child is anywhere underneath parent.
  bool _isChildDirectoryOf(FileSystemEntity parent, FileSystemEntity child) {
    return child.absolute.path.startsWith(parent.absolute.path);
  }

  // Checks the contents of the two files to see if they have changes.
  bool _fileIsIdentical(File src, File dest) {
    if (src.lengthSync() != dest.lengthSync()) {
      return false;
    }

    // Test byte by byte. We're assuming that these are small files.
    final List<int> srcBytes = src.readAsBytesSync();
    final List<int> destBytes = dest.readAsBytesSync();
    for (int i = 0; i < srcBytes.length; ++i) {
      if (srcBytes[i] != destBytes[i]) {
        return false;
      }
    }
    return true;
  }

  // Discovers and syncs with existing configuration files in the Flutter tree.
  void _handleTemplateUpdate() {
    if (!_flutterRoot.existsSync()) {
      return;
    }

    final Set<String> manifest = Set<String>();
    final List<FileSystemEntity> flutterFiles = _flutterRoot.listSync(recursive: true);
    for (FileSystemEntity entity in flutterFiles) {
      final String relativePath = fs.path.relative(entity.path, from: _flutterRoot.absolute.path);
      if (entity is! File) {
        continue;
      }

      final File srcFile = entity;

      // Skip template files in both the ide_templates and templates
      // directories to avoid copying onto themselves.
      if (_isChildDirectoryOf(_templateDirectory, srcFile) ||
          _isChildDirectoryOf(_createTemplatesDirectory, srcFile)) {
        continue;
      }

      // Skip files we aren't interested in.
      final RegExp _trackedIdeaFileRegExp = RegExp(
        r'(\.name|modules.xml|vcs.xml)$',
      );
      final bool isATrackedIdeaFile = _hasDirectoryInPath(srcFile, '.idea') &&
          (_trackedIdeaFileRegExp.hasMatch(relativePath) ||
              _hasDirectoryInPath(srcFile, 'runConfigurations'));
      final bool isAnImlOutsideIdea = !isATrackedIdeaFile && srcFile.path.endsWith('.iml');
      if (!isATrackedIdeaFile && !isAnImlOutsideIdea) {
        continue;
      }

      final File finalDestinationFile = fs.file(fs.path.absolute(
          _templateDirectory.absolute.path, '$relativePath${Template.copyTemplateExtension}'));
      final String relativeDestination =
          fs.path.relative(finalDestinationFile.path, from: _flutterRoot.absolute.path);
      if (finalDestinationFile.existsSync()) {
        if (_fileIsIdentical(srcFile, finalDestinationFile)) {
          printTrace('  $relativeDestination (identical)');
          manifest.add('$relativePath${Template.copyTemplateExtension}');
          continue;
        }
        if (argResults['overwrite']) {
          finalDestinationFile.deleteSync();
          printStatus('  $relativeDestination (overwritten)');
        } else {
          printTrace('  $relativeDestination (existing - skipped)');
          manifest.add('$relativePath${Template.copyTemplateExtension}');
          continue;
        }
      } else {
        printStatus('  $relativeDestination (added)');
      }
      final Directory finalDestinationDir = fs.directory(finalDestinationFile.dirname);
      if (!finalDestinationDir.existsSync()) {
        printTrace("  ${finalDestinationDir.path} doesn't exist, creating.");
        finalDestinationDir.createSync(recursive: true);
      }
      srcFile.copySync(finalDestinationFile.path);
      manifest.add('$relativePath${Template.copyTemplateExtension}');
    }

    // If we're not overwriting, then we're not going to remove missing items either.
    if (!argResults['overwrite']) {
      return;
    }

    // Look for any files under the template dir that don't exist in the manifest and remove
    // them.
    final List<FileSystemEntity> templateFiles = _templateDirectory.listSync(recursive: true);
    for (FileSystemEntity entity in templateFiles) {
      if (entity is! File) {
        continue;
      }
      final File templateFile = entity;
      final String relativePath = fs.path.relative(
        templateFile.absolute.path,
        from: _templateDirectory.absolute.path,
      );
      if (!manifest.contains(relativePath)) {
        templateFile.deleteSync();
        final String relativeDestination =
            fs.path.relative(templateFile.path, from: _flutterRoot.absolute.path);
        printStatus('  $relativeDestination (removed)');
      }
      // If the directory is now empty, then remove it, and do the same for its parent,
      // until we escape to the template directory.
      Directory parentDir = fs.directory(templateFile.dirname);
      while (parentDir.listSync().isEmpty) {
        parentDir.deleteSync();
        printTrace('  ${fs.path.relative(parentDir.absolute.path)} (empty directory - removed)');
        parentDir = fs.directory(parentDir.dirname);
        if (fs.path.isWithin(_templateDirectory.absolute.path, parentDir.absolute.path)) {
          break;
        }
      }
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults.rest.isNotEmpty) {
      throwToolExit('Currently, the only supported IDE is IntelliJ\n$usage', exitCode: 2);
    }

    await Cache.instance.updateAll();

    if (argResults['update-templates']) {
      _handleTemplateUpdate();
      return null;
    }

    final String flutterRoot = fs.path.absolute(Cache.flutterRoot);
    final String dirPath = fs.path.normalize(
      fs.directory(fs.path.absolute(Cache.flutterRoot)).absolute.path,
    );

    final String error = _validateFlutterDir(dirPath, flutterRoot: flutterRoot);
    if (error != null) {
      throwToolExit(error);
    }

    printStatus('Updating IDE configuration for Flutter tree at $dirPath...');
    int generatedCount = 0;
    generatedCount += _renderTemplate(_ideName, dirPath, <String, dynamic>{
      'withRootModule': argResults['with-root-module'],
    });

    printStatus('Wrote $generatedCount files.');
    printStatus('');
    printStatus('Your IntelliJ configuration is now up to date. It is prudent to '
        'restart IntelliJ, if running.');

    return null;
  }

  int _renderTemplate(String templateName, String dirPath, Map<String, dynamic> context) {
    final Template template = Template(_templateDirectory, _templateDirectory);
    return template.render(
      fs.directory(dirPath),
      context,
      overwriteExisting: argResults['overwrite'],
    );
  }
}

/// Return null if the flutter root directory is a valid destination. Return a
/// validation message if we should disallow the directory.
String _validateFlutterDir(String dirPath, {String flutterRoot}) {
  final FileSystemEntityType type = fs.typeSync(dirPath);

  if (type != FileSystemEntityType.notFound) {
    switch (type) {
      case FileSystemEntityType.link:
        // Do not overwrite links.
        return "Invalid project root dir: '$dirPath' - refers to a link.";
    }
  }

  return null;
}
