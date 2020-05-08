// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../template.dart';

/// Types of IDEs that may be configured.
enum IdeType {
  intellij,
  vscode,
}

class IdeConfigCommand extends FlutterCommand {
  IdeConfigCommand({this.hidden = false}) {
    final List<String> ideNames = IdeType.values.map<String>((IdeType type) {
      return getEnumName(type);
    }).toList();
    argParser.addFlag(
      'overwrite',
      negatable: true,
      defaultsTo: false,
      help: 'When performing operations, overwrite existing files.',
    );
    argParser.addFlag(
      'update-templates',
      negatable: false,
      help: 'This is used by Flutter developers to update the templates in the '
          'template directory from the current configuration files. This is the '
          'opposite of what $name usually does. Will search the flutter tree for '
          '.iml files and copy any missing ones into the template directory. If '
          '--overwrite is also specified, it will update any out-of-date files, '
          'and remove any deleted files from the template directory.',
    );
    argParser.addFlag(
      'with-root-module',
      negatable: true,
      defaultsTo: true,
      help: 'Also create module that corresponds to the root of Flutter tree. '
          'This makes the entire Flutter tree browsable and searchable in IntelliJ. '
          'Without this flag, only the child modules will be visible in IntelliJ. '
          'Has no effect on other IDEs.',
    );
    argParser.addMultiOption(
      'ide',
      allowed: ideNames,
      defaultsTo: ideNames,
      help: 'Select which IDE is configured. The default is to produce '
          'configurations for all IDEs: ${ideNames.join(', ')}',
    );
  }

  @override
  final String name = 'ide-config';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  final String description = 'Configure the IDE for use in the Flutter tree.\n\n'
      'The IDE to configure is specified with the --ide option, which takes'
      'either "intellij" or "vscode" as an argument.\n\n'
      'If run on a Flutter tree that is already configured for an IDE, this '
      'command will add any new configurations and recreate any files that are '
      'missing. If --overwrite is specified, it will revert existing files to '
      'the template versions, reset the module list, and return configuration '
      'settings to the template versions.\n\n'
      'This command is intended for Flutter developers to help them set up the '
      "Flutter tree for development in an IDE. It doesn't affect other projects.\n\n"
      'Currently, IntelliJ and VSCode are the IDEs that may be configured.';

  @override
  final bool hidden;

  @override
  String get invocation => '${runner.executableName} $name';

  Directory _templateDirectory(IdeType type) {
    return globals.fs.directory(globals.fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      'ide_templates',
      getEnumName(type),
    ));
  }

  Directory get _createTemplatesDirectory {
    return globals.fs.directory(globals.fs.path.join(
      Cache.flutterRoot,
      'packages',
      'flutter_tools',
      'templates',
    ));
  }

  Directory get _flutterRoot => globals.fs.directory(globals.fs.path.absolute(Cache.flutterRoot));

  // Returns true if any entire path element is equal to dir.
  bool _hasDirectoryInPath(FileSystemEntity entity, String dir) {
    String path = entity.absolute.path;
    while (path.isNotEmpty && globals.fs.path.dirname(path) != path) {
      if (globals.fs.path.basename(path) == dir) {
        return true;
      }
      path = globals.fs.path.dirname(path);
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

  // Discovers and syncs with existing IntelliJ and VSCode configuration files
  // in the Flutter tree.
  void _syncFiles(IdeType type) {
    if (!_flutterRoot.existsSync()) {
      return;
    }

    String configDir;
    RegExp matching;
    switch (type) {
      case IdeType.intellij:
        configDir = '.idea';
        matching = RegExp(r'(\.name|modules.xml|vcs.xml)$');
        break;
      case IdeType.vscode:
        configDir = '.vscode';
        matching = RegExp(r'\blaunch.json$');
        break;
    }

    final Set<String> manifest = <String>{};
    final Iterable<File> flutterFiles = _flutterRoot.listSync(recursive: true).whereType<File>();
    for (final File srcFile in flutterFiles) {
      final String relativePath =
          globals.fs.path.relative(srcFile.path, from: _flutterRoot.absolute.path);

      // Skip template files in both the ide_templates and templates
      // directories to avoid copying onto themselves.
      if (_isChildDirectoryOf(_templateDirectory(type), srcFile) ||
          _isChildDirectoryOf(_createTemplatesDirectory, srcFile)) {
        continue;
      }

      switch (type) {
        case IdeType.intellij:
          final bool isATrackedIdeaFile = _hasDirectoryInPath(srcFile, configDir) &&
              (matching.hasMatch(relativePath) ||
                  _hasDirectoryInPath(srcFile, 'runConfigurations'));
          final bool isAnImlOutsideIdea = !isATrackedIdeaFile && srcFile.path.endsWith('.iml');
          if (!isATrackedIdeaFile && !isAnImlOutsideIdea) {
            continue;
          }
          break;
        case IdeType.vscode:
          if (!_hasDirectoryInPath(srcFile, configDir) && matching.hasMatch(relativePath)) {
            continue;
          }
          break;
      }

      final File finalDestinationFile = globals.fs.file(globals.fs.path.absolute(
          _templateDirectory(type).absolute.path,
          '$relativePath${Template.copyTemplateExtension}'));
      final String relativeDestination =
          globals.fs.path.relative(finalDestinationFile.path, from: _flutterRoot.absolute.path);
      if (finalDestinationFile.existsSync()) {
        if (_fileIsIdentical(srcFile, finalDestinationFile)) {
          globals.printTrace('  $relativeDestination (identical)');
          manifest.add('$relativePath${Template.copyTemplateExtension}');
          continue;
        }
        if (boolArg('overwrite')) {
          finalDestinationFile.deleteSync();
          globals.printStatus('  $relativeDestination (overwritten)');
        } else {
          globals.printTrace('  $relativeDestination (existing - skipped)');
          manifest.add('$relativePath${Template.copyTemplateExtension}');
          continue;
        }
      } else {
        globals.printStatus('  $relativeDestination (added)');
      }
      final Directory finalDestinationDir = globals.fs.directory(finalDestinationFile.dirname);
      if (!finalDestinationDir.existsSync()) {
        globals.printTrace("  ${finalDestinationDir.path} doesn't exist, creating.");
        finalDestinationDir.createSync(recursive: true);
      }
      srcFile.copySync(finalDestinationFile.path);
      manifest.add('$relativePath${Template.copyTemplateExtension}');
    }

    // If we're not overwriting, then we're not going to remove missing items either.
    if (!boolArg('overwrite')) {
      return;
    }

    // Look for any files under the template dir that don't exist in the manifest and remove
    // them.
    final Iterable<File> templateFiles =
        _templateDirectory(type).listSync(recursive: true).whereType<File>();
    for (final File templateFile in templateFiles) {
      final String relativePath = globals.fs.path.relative(
        templateFile.absolute.path,
        from: _templateDirectory(type).absolute.path,
      );
      if (!manifest.contains(relativePath)) {
        templateFile.deleteSync();
        final String relativeDestination =
            globals.fs.path.relative(templateFile.path, from: _flutterRoot.absolute.path);
        globals.printStatus('  $relativeDestination (removed)');
      }
      // If the directory is now empty, then remove it, and do the same for its parent,
      // until we escape to the template directory.
      Directory parentDir = globals.fs.directory(templateFile.dirname);
      while (parentDir.listSync().isEmpty) {
        parentDir.deleteSync();
        globals.printTrace(
            '  ${globals.fs.path.relative(parentDir.absolute.path)} (empty directory - removed)');
        parentDir = globals.fs.directory(parentDir.dirname);
        if (globals.fs.path
            .isWithin(_templateDirectory(type).absolute.path, parentDir.absolute.path)) {
          break;
        }
      }
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults.rest.isNotEmpty) {
      throwToolExit('This command takes no extra arguments.\n$usage', exitCode: 2);
    }

    for (final String ideName in stringsArg('ide')) {
      IdeType type;
      String templateDirName;
      switch (ideName) {
        case 'intellij':
          type = IdeType.intellij;
          templateDirName = ideName;
          break;
        case 'vscode':
          type = IdeType.vscode;
          templateDirName = ideName;
          break;
        default:
          throwToolExit('Unknown IDE type $ideName.\n$usage', exitCode: 2);
          break;
      }
      if (boolArg('update-templates')) {
        _syncFiles(type);
        return FlutterCommandResult.success();
      }

      final String flutterRoot = globals.fs.path.absolute(Cache.flutterRoot);
      final String dirPath = globals.fs.path.normalize(
        globals.fs.directory(globals.fs.path.absolute(Cache.flutterRoot)).absolute.path,
      );

      final String error = _validateFlutterDir(dirPath, flutterRoot: flutterRoot);
      if (error != null) {
        throwToolExit(error);
      }

      globals.printStatus('Updating IDE configuration for Flutter tree at $dirPath...');
      int generatedCount = 0;
      generatedCount += _renderTemplate(
        templateName: templateDirName,
        dirPath: dirPath,
        context: <String, dynamic>{
          'withRootModule': type != IdeType.intellij || boolArg('with-root-module'),
        },
        type: type,
      );

      globals.printStatus('Wrote $generatedCount files.');
      globals.printStatus('');
      switch (type) {
        case IdeType.intellij:
          globals.printStatus('Your IntelliJ configuration is now up to date. It is prudent to '
              'restart IntelliJ, if running.');
          break;
        case IdeType.vscode:
          globals.printStatus('Your VS Code configuration is now up to date.');
          break;
      }
    }

    return FlutterCommandResult.success();
  }

  int _renderTemplate({
    String templateName,
    String dirPath,
    Map<String, dynamic> context,
    IdeType type,
  }) {
    final Template template =
        Template(_templateDirectory(type), _templateDirectory(type), null, fileSystem: globals.fs);
    return template.render(
      globals.fs.directory(dirPath),
      context,
      overwriteExisting: boolArg('overwrite'),
    );
  }
}

/// Return null if the flutter root directory is a valid destination. Return a
/// validation message if we should disallow the directory.
String _validateFlutterDir(String dirPath, {String flutterRoot}) {
  final FileSystemEntityType type = globals.fs.typeSync(dirPath);

  if (type != FileSystemEntityType.notFound) {
    switch (type) {
      case FileSystemEntityType.link:
        // Do not overwrite links.
        return "Invalid project root dir: '$dirPath' - refers to a link.";
    }
  }

  return null;
}
