// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/android.dart' as android;
import '../android/android_sdk.dart' as android_sdk;
import '../android/gradle.dart' as gradle;
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../doctor.dart';
import '../flx.dart' as flx;
import '../globals.dart';
import '../ios/xcodeproj.dart';
import '../plugins.dart';
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
    argParser.addFlag(
      'plugin',
      negatable: true,
      defaultsTo: false,
      help: 'Generate a new Flutter Plugin project.'
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

    final String flutterRoot = fs.path.absolute(Cache.flutterRoot);

    final String flutterPackagesDirectory = fs.path.join(flutterRoot, 'packages');
    final String flutterPackagePath = fs.path.join(flutterPackagesDirectory, 'flutter');
    if (!fs.isFileSync(fs.path.join(flutterPackagePath, 'pubspec.yaml')))
      throwToolExit('Unable to find package:flutter in $flutterPackagePath', exitCode: 2);

    final String flutterDriverPackagePath = fs.path.join(flutterRoot, 'packages', 'flutter_driver');
    if (!fs.isFileSync(fs.path.join(flutterDriverPackagePath, 'pubspec.yaml')))
      throwToolExit('Unable to find package:flutter_driver in $flutterDriverPackagePath', exitCode: 2);

    final bool generatePlugin = argResults['plugin'];

    final Directory projectDir = fs.directory(argResults.rest.first);
    String dirPath = fs.path.normalize(projectDir.absolute.path);
    // TODO(goderbauer): Work-around for: https://github.com/dart-lang/path/issues/24
    if (fs.path.basename(dirPath) == '.')
      dirPath = fs.path.dirname(dirPath);
    final String projectName = _normalizeProjectName(fs.path.basename(dirPath));

    String error =_validateProjectDir(dirPath, flutterRoot: flutterRoot);
    if (error != null)
      throwToolExit(error);

    error = _validateProjectName(projectName);
    if (error != null)
      throwToolExit(error);

    final Map<String, dynamic> templateContext = _templateContext(
        projectName, argResults['description'], dirPath,
        flutterRoot, renderDriverTest: argResults['with-driver-test'],
        withPluginHook: generatePlugin,
    );

    printStatus('Creating project ${fs.path.relative(dirPath)}...');
    int generatedCount = 0;
    String appPath = dirPath;
    if (generatePlugin) {
      final String description = argResults.wasParsed('description')
          ? argResults['description']
          : 'A new flutter plugin project.';
      templateContext['description'] = description;
      generatedCount += _renderTemplate('plugin', dirPath, templateContext);

      if (argResults['pub'])
        await pubGet(directory: dirPath);

      if (android_sdk.androidSdk != null)
        gradle.updateLocalProperties(projectPath: dirPath);

      appPath = fs.path.join(dirPath, 'example');
      final String androidPluginIdentifier = templateContext['androidIdentifier'];
      final String exampleProjectName = projectName + '_example';
      templateContext['projectName'] = exampleProjectName;
      templateContext['androidIdentifier'] = _createAndroidIdentifier(exampleProjectName);
      templateContext['iosIdentifier'] = _createUTIIdentifier(exampleProjectName);
      templateContext['description'] = 'Demonstrates how to use the $projectName plugin.';
      templateContext['pluginProjectName'] = projectName;
      templateContext['androidPluginIdentifier'] = androidPluginIdentifier;
    }

    generatedCount += _renderTemplate('create', appPath, templateContext);
    if (argResults['with-driver-test']) {
      final String testPath = fs.path.join(appPath, 'test_driver');
      generatedCount += _renderTemplate('driver', testPath, templateContext);
    }

    printStatus('Wrote $generatedCount files.');
    printStatus('');

    updateXcodeGeneratedProperties(
      projectPath: appPath,
      mode: BuildMode.debug,
      target: flx.defaultMainPath,
      hasPlugins: generatePlugin,
    );

    if (argResults['pub']) {
      await pubGet(directory: appPath);
      injectPlugins(directory: appPath);
    }

    if (android_sdk.androidSdk != null)
      gradle.updateLocalProperties(projectPath: appPath);

    printStatus('');

    // Run doctor; tell the user the next steps.
    final String relativeAppPath = fs.path.relative(appPath);
    final String relativePluginPath = fs.path.relative(dirPath);
    if (doctor.canLaunchAnything) {
      // Let them know a summary of the state of their tooling.
      await doctor.summary();

      printStatus('''
All done! In order to run your application, type:

  \$ cd $relativeAppPath
  \$ flutter run

Your main program file is lib/main.dart in the $relativeAppPath directory.
''');
      if (generatePlugin) {
        printStatus('''
Your plugin code is in lib/$projectName.dart in the $relativePluginPath directory.

Host platform code is in the android/ and ios/ directories under $relativePluginPath.
''');
      }
    } else {
      printStatus("You'll need to install additional components before you can run "
        "your Flutter app:");
      printStatus('');

      // Give the user more detailed analysis.
      await doctor.diagnose();
      printStatus('');
      printStatus("After installing components, run 'flutter doctor' in order to "
        "re-validate your setup.");
      printStatus("When complete, type 'flutter run' from the '$relativeAppPath' "
        "directory in order to launch your app.");
      printStatus("Your main program file is: $relativeAppPath/lib/main.dart");
    }
  }

  Map<String, dynamic> _templateContext(String projectName,
      String projectDescription, String dirPath, String flutterRoot,
      { bool renderDriverTest: false, bool withPluginHook: false }) {
    flutterRoot = fs.path.normalize(flutterRoot);

    final String pluginDartClass = _createPluginClassName(projectName);
    final String pluginClass = pluginDartClass.endsWith('Plugin')
        ? pluginDartClass
        : pluginDartClass + 'Plugin';

    return <String, dynamic>{
      'projectName': projectName,
      'androidIdentifier': _createAndroidIdentifier(projectName),
      'iosIdentifier': _createUTIIdentifier(projectName),
      'description': projectDescription,
      'dartSdk': '$flutterRoot/bin/cache/dart-sdk',
      'androidMinApiLevel': android.minApiLevel,
      'androidSdkVersion': android_sdk.minimumAndroidSdkVersion,
      'androidFlutterJar': "$flutterRoot/bin/cache/artifacts/engine/android-arm/flutter.jar",
      'withDriverTest': renderDriverTest,
      'pluginClass': pluginClass,
      'pluginDartClass': pluginDartClass,
      'withPluginHook': withPluginHook,
    };
  }

  int _renderTemplate(String templateName, String dirPath, Map<String, dynamic> context) {
    final Template template = new Template.fromName(templateName);
    return template.render(fs.directory(dirPath), context, overwriteExisting: false);
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
  return 'com.yourcompany.$name';
}

String _createPluginClassName(String name) {
  final String camelizedName = camelCase(name);
  return camelizedName[0].toUpperCase() + camelizedName.substring(1);
}

String _createUTIIdentifier(String name) {
  // Create a UTI (https://en.wikipedia.org/wiki/Uniform_Type_Identifier) from a base name
  final RegExp disallowed = new RegExp(r"[^a-zA-Z0-9\-\.\u0080-\uffff]+");
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
  if (fs.path.isWithin(flutterRoot, dirPath)) {
    return "Cannot create a project within the Flutter SDK.\n"
      "Target directory '$dirPath' is within the Flutter SDK at '$flutterRoot'.";
  }

  final FileSystemEntityType type = fs.typeSync(dirPath);

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
