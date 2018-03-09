// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:linter/src/rules/pub/package_names.dart' as package_names; // ignore: implementation_imports
import 'package:linter/src/utils.dart' as linter_utils; // ignore: implementation_imports

import '../android/android.dart' as android;
import '../android/android_sdk.dart' as android_sdk;
import '../android/gradle.dart' as gradle;
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../doctor.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../template.dart';
import '../version.dart';

class CreateCommand extends FlutterCommand {
  CreateCommand() {
    argParser.addFlag('pub',
      defaultsTo: true,
      help: 'Whether to run "flutter packages get" after the project has been created.'
    );
    argParser.addFlag('offline',
      defaultsTo: false,
      help: 'When "flutter packages get" is run by the create command, this indicates '
        'whether to run it in offline mode or not. In offline mode, it will need to '
        'have all dependencies already available in the pub cache to succeed.'
    );
    argParser.addFlag(
      'with-driver-test',
      negatable: true,
      defaultsTo: false,
      help: 'Also add a flutter_driver dependency and generate a sample \'flutter drive\' test.'
    );
    argParser.addOption(
      'template',
      abbr: 't',
      allowed: <String>['app', 'package', 'plugin'],
      help: 'Specify the type of project to create.',
      valueHelp: 'type',
      allowedHelp: <String, String>{
        'app': '(default) Generate a Flutter application.',
        'package': 'Generate a shareable Flutter project containing modular Dart code.',
        'plugin': 'Generate a shareable Flutter project containing an API in Dart code\n'
            'with a platform-specific implementation for Android, for iOS code, or for both.',
      },
      defaultsTo: 'app',
    );
    argParser.addOption(
      'description',
      defaultsTo: 'A new Flutter project.',
      help: 'The description to use for your new Flutter project. This string ends up in the pubspec.yaml file.'
    );
    argParser.addOption(
      'org',
      defaultsTo: 'com.example',
      help: 'The organization responsible for your new Flutter project, in reverse domain name notation.\n'
            'This string is used in Java package names and as prefix in the iOS bundle identifier.'
    );
    argParser.addOption(
      'ios-language',
      abbr: 'i',
      defaultsTo: 'objc',
      allowed: <String>['objc', 'swift'],
    );
    argParser.addOption(
      'android-language',
      abbr: 'a',
      defaultsTo: 'java',
      allowed: <String>['java', 'kotlin'],
    );
  }

  @override
  final String name = 'create';

  @override
  final String description = 'Create a new Flutter project.\n\n'
    'If run on a project that already exists, this will repair the project, recreating any files that are missing.';

  @override
  String get invocation => '${runner.executableName} $name <output directory>';

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

    final String template = argResults['template'];
    final bool generatePlugin = template == 'plugin';
    final bool generatePackage = template == 'package';

    final Directory projectDir = fs.directory(argResults.rest.first);
    String dirPath = fs.path.normalize(projectDir.absolute.path);
    // TODO(goderbauer): Work-around for: https://github.com/dart-lang/path/issues/24
    if (fs.path.basename(dirPath) == '.')
      dirPath = fs.path.dirname(dirPath);
    String organization = argResults['org'];
    if (!argResults.wasParsed('org')) {
      final Set<String> existingOrganizations = await new FlutterProject(projectDir).organizationNames();
      if (existingOrganizations.length == 1) {
        organization = existingOrganizations.first;
      } else if (1 < existingOrganizations.length) {
        throwToolExit(
          'Ambiguous organization in existing files: $existingOrganizations.\n'
          'The --org command line argument must be specified to recreate project.'
        );
      }
    }
    final String projectName = fs.path.basename(dirPath);

    String error =_validateProjectDir(dirPath, flutterRoot: flutterRoot);
    if (error != null)
      throwToolExit(error);

    error = _validateProjectName(projectName);
    if (error != null)
      throwToolExit(error);

    final Map<String, dynamic> templateContext = _templateContext(
      organization: organization,
      projectName: projectName,
      projectDescription: argResults['description'],
      dirPath: dirPath,
      flutterRoot: flutterRoot,
      renderDriverTest: argResults['with-driver-test'],
      withPluginHook: generatePlugin,
      androidLanguage: argResults['android-language'],
      iosLanguage: argResults['ios-language'],
    );

    printStatus('Creating project ${fs.path.relative(dirPath)}...');
    int generatedCount = 0;
    if (generatePackage) {
      final String description = argResults.wasParsed('description')
          ? argResults['description']
          : 'A new flutter package project.';
      templateContext['description'] = description;
      generatedCount += _renderTemplate('package', dirPath, templateContext);

      if (argResults['pub'])
        await pubGet(
          context: PubContext.createPackage,
          directory: dirPath,
          offline: argResults['offline'],
        );

      final String relativePath = fs.path.relative(dirPath);
      printStatus('Wrote $generatedCount files.');
      printStatus('');
      printStatus('Your package code is in lib/$projectName.dart in the $relativePath directory.');
      return;
    }

    String appPath = dirPath;
    if (generatePlugin) {
      final String description = argResults.wasParsed('description')
          ? argResults['description']
          : 'A new flutter plugin project.';
      templateContext['description'] = description;
      generatedCount += _renderTemplate('plugin', dirPath, templateContext);

      if (argResults['pub'])
        await pubGet(
          context: PubContext.createPlugin,
          directory: dirPath,
          offline: argResults['offline'],
        );

      if (android_sdk.androidSdk != null)
        gradle.updateLocalProperties(projectPath: dirPath);

      appPath = fs.path.join(dirPath, 'example');
      final String androidPluginIdentifier = templateContext['androidIdentifier'];
      final String exampleProjectName = projectName + '_example';
      templateContext['projectName'] = exampleProjectName;
      templateContext['androidIdentifier'] = _createAndroidIdentifier(organization, exampleProjectName);
      templateContext['iosIdentifier'] = _createUTIIdentifier(organization, exampleProjectName);
      templateContext['description'] = 'Demonstrates how to use the $projectName plugin.';
      templateContext['pluginProjectName'] = projectName;
      templateContext['androidPluginIdentifier'] = androidPluginIdentifier;
    }

    generatedCount += _renderTemplate('create', appPath, templateContext);
    generatedCount += _injectGradleWrapper(appPath);
    if (argResults['with-driver-test']) {
      final String testPath = fs.path.join(appPath, 'test_driver');
      generatedCount += _renderTemplate('driver', testPath, templateContext);
    }

    printStatus('Wrote $generatedCount files.');
    printStatus('');

    if (argResults['pub']) {
      await pubGet(context: PubContext.create, directory: appPath, offline: argResults['offline']);
      new FlutterProject(fs.directory(appPath)).ensureReadyForPlatformSpecificTooling();
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
To edit platform code in an IDE see https://flutter.io/platform-plugins/#edit-code.
''');
      }
    } else {
      printStatus("You'll need to install additional components before you can run "
        'your Flutter app:');
      printStatus('');

      // Give the user more detailed analysis.
      await doctor.diagnose();
      printStatus('');
      printStatus("After installing components, run 'flutter doctor' in order to "
        're-validate your setup.');
      printStatus("When complete, type 'flutter run' from the '$relativeAppPath' "
        'directory in order to launch your app.');
      printStatus('Your main program file is: $relativeAppPath/lib/main.dart');
    }
  }

  Map<String, dynamic> _templateContext({
    String organization,
    String projectName,
    String projectDescription,
    String androidLanguage,
    String iosLanguage,
    String dirPath,
    String flutterRoot,
    bool renderDriverTest: false,
    bool withPluginHook: false,
  }) {
    flutterRoot = fs.path.normalize(flutterRoot);

    final String pluginDartClass = _createPluginClassName(projectName);
    final String pluginClass = pluginDartClass.endsWith('Plugin')
        ? pluginDartClass
        : pluginDartClass + 'Plugin';

    return <String, dynamic>{
      'organization': organization,
      'projectName': projectName,
      'androidIdentifier': _createAndroidIdentifier(organization, projectName),
      'iosIdentifier': _createUTIIdentifier(organization, projectName),
      'description': projectDescription,
      'dartSdk': '$flutterRoot/bin/cache/dart-sdk',
      'androidMinApiLevel': android.minApiLevel,
      'androidSdkVersion': android_sdk.minimumAndroidSdkVersion,
      'androidFlutterJar': '$flutterRoot/bin/cache/artifacts/engine/android-arm/flutter.jar',
      'withDriverTest': renderDriverTest,
      'pluginClass': pluginClass,
      'pluginDartClass': pluginDartClass,
      'withPluginHook': withPluginHook,
      'androidLanguage': androidLanguage,
      'iosLanguage': iosLanguage,
      'flutterRevision': FlutterVersion.instance.frameworkRevision,
      'flutterChannel': FlutterVersion.instance.channel,
    };
  }

  int _renderTemplate(String templateName, String dirPath, Map<String, dynamic> context) {
    final Template template = new Template.fromName(templateName);
    return template.render(fs.directory(dirPath), context, overwriteExisting: false);
  }

  int _injectGradleWrapper(String projectDir) {
    int filesCreated = 0;
    copyDirectorySync(
      cache.getArtifactDirectory('gradle_wrapper'),
      fs.directory(fs.path.join(projectDir, 'android')),
      (File sourceFile, File destinationFile) {
        filesCreated++;
        final String modes = sourceFile.statSync().modeString();
        if (modes != null && modes.contains('x')) {
          os.makeExecutable(destinationFile);
        }
      },
    );
    return filesCreated;
  }
}

String _createAndroidIdentifier(String organization, String name) {
  return '$organization.$name'.replaceAll('_', '');
}

String _createPluginClassName(String name) {
  final String camelizedName = camelCase(name);
  return camelizedName[0].toUpperCase() + camelizedName.substring(1);
}

String _createUTIIdentifier(String organization, String name) {
  // Create a UTI (https://en.wikipedia.org/wiki/Uniform_Type_Identifier) from a base name
  final RegExp disallowed = new RegExp(r'[^a-zA-Z0-9\-\.\u0080-\uffff]+');
  name = camelCase(name).replaceAll(disallowed, '');
  name = name.isEmpty ? 'untitled' : name;
  return '$organization.$name';
}

final Set<String> _packageDependencies = new Set<String>.from(<String>[
  'analyzer',
  'args',
  'async',
  'collection',
  'convert',
  'crypto',
  'flutter',
  'flutter_test',
  'front_end',
  'html',
  'http',
  'intl',
  'io',
  'isolate',
  'kernel',
  'logging',
  'matcher',
  'meta',
  'mime',
  'path',
  'plugin',
  'pool',
  'test',
  'utf',
  'watcher',
  'yaml'
]);

/// Return null if the project name is legal. Return a validation message if
/// we should disallow the project name.
String _validateProjectName(String projectName) {
  if (!linter_utils.isValidPackageName(projectName)) {
    final String packageNameDetails = new package_names.PubPackageNames().details;
    return '"$projectName" is not a valid Dart package name.\n\n$packageNameDetails';
  }
  if (_packageDependencies.contains(projectName)) {
    return "Invalid project name: '$projectName' - this will conflict with Flutter "
      'package dependencies.';
  }
  return null;
}

/// Return null if the project directory is legal. Return a validation message
/// if we should disallow the directory name.
String _validateProjectDir(String dirPath, { String flutterRoot }) {
  if (fs.path.isWithin(flutterRoot, dirPath)) {
    return 'Cannot create a project within the Flutter SDK.\n'
      "Target directory '$dirPath' is within the Flutter SDK at '$flutterRoot'.";
  }

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
