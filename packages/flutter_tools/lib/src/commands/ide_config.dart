// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../doctor.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../plugins.dart';
import '../runner/flutter_command.dart';
import '../template.dart';
import '../version.dart';

class IdeConfigCommand extends FlutterCommand {
  @override
  final String name = 'ide-config';

  @override
  final String description = 'Configure the IDE to use in the Flutter repo.\n\n'
    'If run on a project that already exists, this will replace the existing configuration, '
    'recreating any files that are missing, and resetting the module list and run '
    'configuration settings to their defaults.';

  @override
  String get invocation => '${runner.executableName} $name [intellij]';

  @override
  Future<Null> runCommand() async {
    if (argResults.rest.length != 1 || argResults.rest[0] != 'intellij')
      throwToolExit('Currently, the only supported IDE is IntelliJ, so you '
          'must supply "intellij" as the argument to $name.\n$usage',
          exitCode: 2);

    await Cache.instance.updateAll();

    final String flutterRoot = fs.path.absolute(Cache.flutterRoot);

    final Directory projectDir = fs.directory(
        fs.path.absolute(Cache.flutterRoot));
    String dirPath = fs.path.normalize(projectDir.absolute.path);
    // TODO(goderbauer): Work-around for: https://github.com/dart-lang/path/issues/24
    if (fs.path.basename(dirPath) == '.')
      dirPath = fs.path.dirname(dirPath);

    print("Absolute path $dirPath");
    final String error = _validateFlutterDir(dirPath, flutterRoot: flutterRoot);
    if (error != null)
      throwToolExit(error);

    printStatus(
        'Updating IntelliJ configuration for ${fs.path.relative(dirPath)}...');
    int generatedCount = 0;
    generatedCount += _renderTemplate('intellij', dirPath, <String, dynamic>{});

    printStatus('Wrote $generatedCount files.');
    printStatus('');
    printStatus(
        'Your IntelliJ configuration is now up to date. It is prudent to restart IntelliJ, if running.');
  }

  int _renderTemplate(String templateName, String dirPath, Map<String, dynamic> context) {
    final Template template = new Template.fromName(templateName);
    return template.render(fs.directory(dirPath), context, overwriteExisting: true);
  }
}

/// Return null if the project directory is legal. Return a validation message
/// if we should disallow the directory name.
String _validateFlutterDir(String dirPath, { String flutterRoot }) {
  final FileSystemEntityType type = fs.typeSync(dirPath);

  if (type != FileSystemEntityType.NOT_FOUND) {
    switch (type) {
      case FileSystemEntityType.FILE:
      // Do not overwrite files.
        return "Invalid project name: '$dirPath' - file exists.";
      case FileSystemEntityType.LINK:
      // Do not overwrite links.
        return "Invalid project name: '$dirPath' - refers to a link.";
    }
  }

  return null;
}
