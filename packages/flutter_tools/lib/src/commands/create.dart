// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../android/android.dart' as android;
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../doctor.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../template.dart';

class CreateCommand extends FlutterCommand {
  CreateCommand() {
    argParser.addFlag('pub',
      defaultsTo: true,
      help: 'Whether to run "flutter packages get" after the project has been created.'
    );
    argParser.addFlag(
      'with-driver-test',
      negatable: true,
      defaultsTo: false,
      help: 'Also add a flutter_driver dependency and generate a sample \'flutter drive\' test.'
    );
    argParser.addOption(
      'description',
      defaultsTo: 'A new flutter project.',
      help: 'The description to use for your new flutter project. This string ends up in the pubspec.yaml file.'
    );
  }

  @override
  final String name = 'create';

  @override
  final String description = 'Create a new Flutter project.\n\n'
    'If run on a project that already exists, this will repair the project, recreating any files that are missing.';

  @override
  String get invocation => "${runner.executableName} $name <output directory>";

  @override
  Future<Null> runCommand() async {
    if (argResults.rest.isEmpty)
      throwToolExit('No option specified for the output directory.\n$usage', exitCode: 2);

    if (argResults.rest.length > 1) {
      String message = 'Multiple output directories specified.';
      for (String arg in argResults.rest) {
        if (arg.startsWith('-')) {
          message += '\nTry moving $arg to be immediately following $name';
          break;
        }
      }
      throwToolExit(message, exitCode: 2);
    }

    if (Cache.flutterRoot == null)
      throwToolExit('Neither the --flutter-root command line flag nor the FLUTTER_ROOT environment\n'
        'variable was specified. Unable to find package:flutter.', exitCode: 2);

    await Cache.instance.updateAll();

    String flutterRoot = path.absolute(Cache.flutterRoot);

    String flutterPackagesDirectory = path.join(flutterRoot, 'packages');
    String flutterPackagePath = path.join(flutterPackagesDirectory, 'flutter');
    if (!fs.isFileSync(path.join(flutterPackagePath, 'pubspec.yaml')))
      throwToolExit('Unable to find package:flutter in $flutterPackagePath', exitCode: 2);

    String flutterDriverPackagePath = path.join(flutterRoot, 'packages', 'flutter_driver');
    if (!fs.isFileSync(path.join(flutterDriverPackagePath, 'pubspec.yaml')))
      throwToolExit('Unable to find package:flutter_driver in $flutterDriverPackagePath', exitCode: 2);

    Directory projectDir = fs.directory(argResults.rest.first);
    String dirPath = path.normalize(projectDir.absolute.path);
    String relativePath = path.relative(dirPath);
    String projectName = _normalizeProjectName(path.basename(dirPath));

    String error =_validateProjectDir(dirPath, flutterRoot: flutterRoot);
    if (error != null)
      throwToolExit(error);

    error = _validateProjectName(projectName);
    if (error != null)
      throwToolExit(error);

    int generatedCount = _renderTemplates(
      projectName,
      argResults['description'],
      dirPath,
      flutterPackagesDirectory,
      renderDriverTest: argResults['with-driver-test']
    );
    printStatus('Wrote $generatedCount files.');

    printStatus('');

    if (argResults['pub'])
      await pubGet(directory: dirPath);

    printStatus('');

    // Run doctor; tell the user the next steps.
    if (doctor.canLaunchAnything) {
      // Let them know a summary of the state of their tooling.
      await doctor.summary();

      printStatus('''
All done! In order to run your application, type:

  \$ cd $relativePath
  \$ flutter run

Your main program file is lib/main.dart in the $relativePath directory.
''');
    } else {
      printStatus("You'll need to install additional components before you can run "
        "your Flutter app:");
      printStatus('');

      // Give the user more detailed analysis.
      await doctor.diagnose();
      printStatus('');
      printStatus("After installing components, run 'flutter doctor' in order to "
        "re-validate your setup.");
      printStatus("When complete, type 'flutter run' from the '$relativePath' "
        "directory in order to launch your app.");
      printStatus("Your main program file is: $relativePath/lib/main.dart");
    }
  }

  int _renderTemplates(String projectName, String projectDescription, String dirPath,
      String flutterPackagesDirectory, { bool renderDriverTest: false }) {
    fs.directory(dirPath).createSync(recursive: true);

    flutterPackagesDirectory = path.normalize(flutterPackagesDirectory);
    flutterPackagesDirectory = _relativePath(from: dirPath, to: flutterPackagesDirectory);

    printStatus('Creating project ${path.relative(dirPath)}...');

    Map<String, dynamic> templateContext = <String, dynamic>{
      'projectName': projectName,
      'androidIdentifier': _createAndroidIdentifier(projectName),
      'iosIdentifier': _createUTIIdentifier(projectName),
      'description': projectDescription,
      'flutterPackagesDirectory': flutterPackagesDirectory,
      'androidMinApiLevel': android.minApiLevel
    };

    int fileCount = 0;

    templateContext['withDriverTest'] = renderDriverTest;

    Template createTemplate = new Template.fromName('create');
    fileCount += createTemplate.render(
      fs.directory(dirPath),
      templateContext, overwriteExisting: false,
      projectName: projectName
    );

    if (renderDriverTest) {
      Template driverTemplate = new Template.fromName('driver');
      fileCount += driverTemplate.render(fs.directory(path.join(dirPath, 'test_driver')),
          templateContext, overwriteExisting: false);
    }

    return fileCount;
  }
}

String _normalizeProjectName(String name) {
  name = name.replaceAll('-', '_').replaceAll(' ', '_');
  // Strip any extension (like .dart).
  if (name.contains('.'))
    name = name.substring(0, name.indexOf('.'));
  return name;
}

String _createAndroidIdentifier(String name) {
  return 'com.yourcompany.${camelCase(name)}';
}

String _createUTIIdentifier(String name) {
  // Create a UTI (https://en.wikipedia.org/wiki/Uniform_Type_Identifier) from a base name
  RegExp disallowed = new RegExp(r"[^a-zA-Z0-9\-\.\u0080-\uffff]+");
  name = camelCase(name).replaceAll(disallowed, '');
  name = name.isEmpty ? 'untitled' : name;
  return 'com.yourcompany.$name';
}

final Set<String> _packageDependencies = new Set<String>.from(<String>[
  'args',
  'async',
  'collection',
  'convert',
  'flutter',
  'html',
  'intl',
  'logging',
  'matcher',
  'mime',
  'path',
  'plugin',
  'pool',
  'test',
  'utf',
  'watcher',
  'yaml'
]);

/// Return `null` if the project name is legal. Return a validation message if
/// we should disallow the project name.
String _validateProjectName(String projectName) {
  if (_packageDependencies.contains(projectName)) {
    return "Invalid project name: '$projectName' - this will conflict with Flutter "
      "package dependencies.";
  }
  return null;
}

/// Return `null` if the project directory is legal. Return a validation message
/// if we should disallow the directory name.
String _validateProjectDir(String dirPath, { String flutterRoot }) {
  if (path.isWithin(flutterRoot, dirPath)) {
    return "Cannot create a project within the Flutter SDK.\n"
      "Target directory '$dirPath' is within the Flutter SDK at '$flutterRoot'.";
  }

  FileSystemEntityType type = fs.typeSync(dirPath);

  if (type != FileSystemEntityType.NOT_FOUND) {
    switch(type) {
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

String _relativePath({ String from, String to }) {
  String result = path.relative(to, from: from);
  // `path.relative()` doesn't always return a correct result: dart-lang/path#12.
  if (fs.isDirectorySync(path.join(from, result)))
    return result;
  return to;
}
