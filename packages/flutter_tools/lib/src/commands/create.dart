// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../template.dart';

class CreateCommand extends Command {
  final String name = 'create';
  final String description = 'Create a new Flutter project.';
  final List<String> aliases = <String>['init'];

  CreateCommand() {
    argParser.addOption('out',
      abbr: 'o',
      hide: true,
      help: 'The output directory.'
    );
    argParser.addFlag('pub',
      defaultsTo: true,
      help: 'Whether to run "pub get" after the project has been created.'
    );
    argParser.addFlag(
      'with-driver-test',
      negatable: true,
      defaultsTo: false,
      help: 'Also add Flutter Driver dependencies and generate a sample driver test.'
    );
  }

  String get invocation => "${runner.executableName} $name <output directory>";

  @override
  Future<int> run() async {
    if (!argResults.wasParsed('out') && argResults.rest.isEmpty) {
      printStatus('No option specified for the output directory.');
      printStatus(usage);
      return 2;
    }

    if (ArtifactStore.flutterRoot == null) {
      printError('Neither the --flutter-root command line flag nor the FLUTTER_ROOT environment');
      printError('variable was specified. Unable to find package:flutter.');
      return 2;
    }

    String flutterRoot = path.absolute(ArtifactStore.flutterRoot);

    String flutterPackagesDirectory = path.join(flutterRoot, 'packages');
    String flutterPackagePath = path.join(flutterPackagesDirectory, 'flutter');
    if (!FileSystemEntity.isFileSync(path.join(flutterPackagePath, 'pubspec.yaml'))) {
      printError('Unable to find package:flutter in $flutterPackagePath');
      return 2;
    }

    String flutterDriverPackagePath = path.join(flutterRoot, 'packages', 'flutter_driver');
    if (!FileSystemEntity.isFileSync(path.join(flutterDriverPackagePath, 'pubspec.yaml'))) {
      printError('Unable to find package:flutter_driver in $flutterDriverPackagePath');
      return 2;
    }

    Directory projectDir;

    if (argResults.wasParsed('out')) {
      projectDir = new Directory(argResults['out']);
    } else {
      projectDir = new Directory(argResults.rest.first);
    }

    _renderTemplates(projectDir, flutterPackagesDirectory,
        renderDriverTest: argResults['with-driver-test']);

    if (argResults['pub']) {
      int code = await pubGet(directory: projectDir.path);
      if (code != 0)
        return code;
    }

    printStatus('');

    // Run doctor; tell the user the next steps.
    if (doctor.canLaunchAnything) {
      // Let them know a summary of the state of their tooling.
      doctor.summary();

      printStatus('''
All done! In order to run your application, type:

  \$ cd ${projectDir.path}
  \$ flutter run
''');
    } else {
      printStatus("You'll need to install additional components before you can run "
        "your Flutter app:");
      printStatus('');

      // Give the user more detailed analysis.
      doctor.diagnose();
      printStatus('');
      printStatus("After installing components, run 'flutter doctor' in order to "
        "re-validate your setup.");
      printStatus("When complete, type 'flutter run' from the '${projectDir.path}' "
        "directory in order to launch your app.");
    }

    return 0;
  }

  void _renderTemplates(Directory projectDir, String flutterPackagesDirectory,
      { bool renderDriverTest: false }) {
    String dirPath = path.normalize(projectDir.absolute.path);
    String projectName = _normalizeProjectName(path.basename(dirPath));
    String projectIdentifier = _createProjectIdentifier(path.basename(dirPath));
    String relativeFlutterPackagesDirectory = path.relative(flutterPackagesDirectory, from: dirPath);

    printStatus('Creating project ${path.basename(projectName)}:');

    projectDir.createSync(recursive: true);

    Map templateContext = <String, dynamic>{
      'projectName': projectName,
      'projectIdentifier': projectIdentifier,
      'description': description,
      'flutterPackagesDirectory': relativeFlutterPackagesDirectory,
    };

    if (renderDriverTest)
      templateContext['withDriverTest?'] = <String, dynamic>{};

    Template createTemplate = new Template.fromName('create');
    createTemplate.render(new Directory(dirPath), templateContext,
        overwriteExisting: false);

    if (renderDriverTest) {
      Template driverTemplate = new Template.fromName('driver');
      driverTemplate.render(new Directory(path.join(dirPath, 'test_driver')),
          templateContext, overwriteExisting: false);
    }
  }
}

String _normalizeProjectName(String name) {
  name = name.replaceAll('-', '_').replaceAll(' ', '_');
  // Strip any extension (like .dart).
  if (name.contains('.'))
    name = name.substring(0, name.indexOf('.'));
  return name;
}

String _createProjectIdentifier(String name) {
  // Create a UTI (https://en.wikipedia.org/wiki/Uniform_Type_Identifier) from a base name
  RegExp disallowed = new RegExp(r"[^a-zA-Z0-9\-.\u0080-\uffff]+");
  name = name.replaceAll(disallowed, '');
  name = name.length == 0 ? 'untitled' : name;
  return 'com.yourcompany.$name';
}
