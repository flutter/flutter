// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:linter/src/rules/pub/package_names.dart' as package_names; // ignore: implementation_imports
import 'package:linter/src/utils.dart' as linter_utils; // ignore: implementation_imports
import 'package:yaml/yaml.dart' as yaml;

import '../android/android.dart' as android;
import '../android/android_sdk.dart' as android_sdk;
import '../android/gradle.dart' as gradle;
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/net.dart';
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

enum _ProjectType {
  /// This is the default project with the user-managed host code.
  /// It is different than the "module" template in that it exposes and doesn't
  /// manage the platform code.
  app,
  /// The is a project that has managed platform host code. It is an application with
  /// ephemeral .ios and .android directories that can be updated automatically.
  module,
  /// This is a Flutter Dart package project. It doesn't have any native
  /// components, only Dart.
  package,
  /// This is a native plugin project.
  plugin,
}

_ProjectType _stringToProjectType(String value) {
  _ProjectType result;
  for (_ProjectType type in _ProjectType.values) {
    if (value == getEnumName(type)) {
      result = type;
      break;
    }
  }
  return result;
}

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
      help: "Also add a flutter_driver dependency and generate a sample 'flutter drive' test."
    );
    argParser.addOption(
      'template',
      abbr: 't',
      allowed: _ProjectType.values.map<String>((_ProjectType type) => getEnumName(type)),
      help: 'Specify the type of project to create.',
      valueHelp: 'type',
      allowedHelp: <String, String>{
        getEnumName(_ProjectType.app): '(default) Generate a Flutter application.',
        getEnumName(_ProjectType.package): 'Generate a shareable Flutter project containing modular '
            'Dart code.',
        getEnumName(_ProjectType.plugin): 'Generate a shareable Flutter project containing an API '
            'in Dart code with a platform-specific implementation for Android, for iOS code, or '
            'for both.',
      },
      defaultsTo: null,
    );
    argParser.addOption(
      'sample',
      abbr: 's',
      help: 'Specifies the Flutter code sample to use as the main.dart for an application. Implies '
        '--template=app.',
      defaultsTo: null,
      valueHelp: 'the sample ID of the desired sample from the API documentation website (http://docs.flutter.io)'
    );
    argParser.addFlag(
      'overwrite',
      negatable: true,
      defaultsTo: false,
      help: 'When performing operations, overwrite existing files.',
    );
    argParser.addOption(
      'description',
      defaultsTo: 'A new Flutter project.',
      help: 'The description to use for your new Flutter project. This string ends up in the pubspec.yaml file.'
    );
    argParser.addOption(
      'org',
      defaultsTo: 'com.example',
      help: 'The organization responsible for your new Flutter project, in reverse domain name notation. '
            'This string is used in Java package names and as prefix in the iOS bundle identifier.'
    );
    argParser.addOption(
      'project-name',
      defaultsTo: null,
      help: 'The project name for this new Flutter project. This must be a valid dart package name.'
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

  // If it has a .metadata file with the project_type in it, use that.
  // If it has an android dir and an android/app dir, it's a legacy app
  // If it has an ios dir and an ios/Flutter dir, it's a legacy app
  // Otherwise, we don't presume to know what type of project it could be, since
  // many of the files could be missing, and we can't really tell definitively.
  _ProjectType _determineTemplateType(Directory projectDir) {
    yaml.YamlMap loadMetadata(Directory projectDir) {
      if (!projectDir.existsSync())
        return null;
      final File metadataFile = fs.file(fs.path.join(projectDir.absolute.path, '.metadata'));
      if (!metadataFile.existsSync())
        return null;
      return yaml.loadYaml(metadataFile.readAsStringSync());
    }

    bool exists(List<String> path) {
      return fs.directory(fs.path.joinAll(<String>[projectDir.absolute.path] + path)).existsSync();
    }

    // If it exists, the project type in the metadata is definitive.
    final yaml.YamlMap metadata = loadMetadata(projectDir);
    if (metadata != null && metadata['project_type'] != null) {
      return _stringToProjectType(metadata['project_type']);
    }

    // There either wasn't any metadata, or it didn't contain the project type,
    // so try and figure out what type of project it is from the existing
    // directory structure.
    if (exists(<String>['android', 'app'])
        || exists(<String>['ios', 'Runner'])
        || exists(<String>['ios', 'Flutter'])) {
      return _ProjectType.app;
    }
    // Since we can't really be definitive on nearly-empty directories, err on
    // the side of prudence and just say we don't know.
    return null;
  }

  Future<String> _fetchSampleFromServer(String sampleId) async {
    // Sanity check the sampleId
    if (sampleId.contains(RegExp(r'[^-\w\.]'))) {
      throwToolExit('Sample ID "$sampleId" contains invalid characters. Check the ID in the '
        'documentation and try again.');
    }

    final String host = FlutterVersion.instance.channel == 'stable'
        ? 'docs.flutter.io'
        : 'master-docs-flutter-io.firebaseapp.com';
    return utf8.decode(await fetchUrl(Uri.https(host, 'snippets/$sampleId.dart')));
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
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
      throwToolExit('Neither the --flutter-root command line flag nor the FLUTTER_ROOT environment '
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

    final Directory projectDir = fs.directory(argResults.rest.first);
    final String projectDirPath = fs.path.normalize(projectDir.absolute.path);

    String sampleCode;
    if (argResults['sample'] != null) {
      if (argResults['template'] != null &&
        _stringToProjectType(argResults['template'] ?? 'app') != _ProjectType.app) {
        throwToolExit('Cannot specify --sample with a project type other than '
          '"${getEnumName(_ProjectType.app)}"');
      }
      // Fetch the sample from the server.
      sampleCode = await _fetchSampleFromServer(argResults['sample']);
    }

    _ProjectType template;
    _ProjectType detectedProjectType;
    final bool metadataExists = projectDir.absolute.childFile('.metadata').existsSync();
    if (argResults['template'] != null) {
      template = _stringToProjectType(argResults['template']);
    } else {
      if (projectDir.existsSync() && projectDir.listSync().isNotEmpty) {
        detectedProjectType = _determineTemplateType(projectDir);
        if (detectedProjectType == null && metadataExists) {
          // We can only be definitive that this is the wrong type if the .metadata file
          // exists and contains a type that we don't understand, or doesn't contain a type.
          throwToolExit('Sorry, unable to detect the type of project to recreate. '
              'Try creating a fresh project and migrating your existing code to '
              'the new project manually.');
        }
      }
    }
    template ??= detectedProjectType ?? _ProjectType.app;
    if (detectedProjectType != null && template != detectedProjectType && metadataExists) {
      // We can only be definitive that this is the wrong type if the .metadata file
      // exists and contains a type that doesn't match.
      throwToolExit("The requested template type '${getEnumName(template)}' doesn't match the "
          "existing template type of '${getEnumName(detectedProjectType)}'.");
    }

    final bool generateModule = template == _ProjectType.module;
    final bool generatePlugin = template == _ProjectType.plugin;
    final bool generatePackage = template == _ProjectType.package;

    String organization = argResults['org'];
    if (!argResults.wasParsed('org')) {
      final FlutterProject project = await FlutterProject.fromDirectory(projectDir);
      final Set<String> existingOrganizations = project.organizationNames;
      if (existingOrganizations.length == 1) {
        organization = existingOrganizations.first;
      } else if (1 < existingOrganizations.length) {
        throwToolExit(
          'Ambiguous organization in existing files: $existingOrganizations. '
          'The --org command line argument must be specified to recreate project.'
        );
      }
    }

    String error = _validateProjectDir(projectDirPath, flutterRoot: flutterRoot, overwrite: argResults['overwrite']);
    if (error != null)
      throwToolExit(error);

    final String projectName = argResults['project-name'] ?? fs.path.basename(projectDirPath);
    error = _validateProjectName(projectName);
    if (error != null)
      throwToolExit(error);

    final Map<String, dynamic> templateContext = _templateContext(
      organization: organization,
      projectName: projectName,
      projectDescription: argResults['description'],
      flutterRoot: flutterRoot,
      renderDriverTest: argResults['with-driver-test'],
      withPluginHook: generatePlugin,
      androidLanguage: argResults['android-language'],
      iosLanguage: argResults['ios-language'],
    );

    final String relativeDirPath = fs.path.relative(projectDirPath);
    if (!projectDir.existsSync() || projectDir.listSync().isEmpty) {
      printStatus('Creating project $relativeDirPath...');
    } else {
      if (sampleCode != null && !argResults['overwrite']) {
        throwToolExit('Will not overwrite existing project in $relativeDirPath: '
          'must specify --overwrite for samples to overwrite.');
      }
      printStatus('Recreating project $relativeDirPath...');
    }

    final Directory relativeDir = fs.directory(projectDirPath);
    int generatedFileCount = 0;
    switch (template) {
      case _ProjectType.app:
        generatedFileCount += await _generateApp(relativeDir, templateContext, overwrite: argResults['overwrite']);
        break;
      case _ProjectType.module:
        generatedFileCount += await _generateModule(relativeDir, templateContext, overwrite: argResults['overwrite']);
        break;
      case _ProjectType.package:
        generatedFileCount += await _generatePackage(relativeDir, templateContext, overwrite: argResults['overwrite']);
        break;
      case _ProjectType.plugin:
        generatedFileCount += await _generatePlugin(relativeDir, templateContext, overwrite: argResults['overwrite']);
        break;
    }
    if (sampleCode != null) {
      generatedFileCount += await _applySample(relativeDir, sampleCode);
    }
    printStatus('Wrote $generatedFileCount files.');
    printStatus('\nAll done!');
    final String application = sampleCode != null ? 'sample application' : 'application';
    if (generatePackage) {
      final String relativeMainPath = fs.path.normalize(fs.path.join(
        relativeDirPath,
        'lib',
        '${templateContext['projectName']}.dart',
      ));
      printStatus('Your package code is in $relativeMainPath');
    } else if (generateModule) {
      final String relativeMainPath = fs.path.normalize(fs.path.join(
          relativeDirPath,
          'lib',
          'main.dart',
      ));
      printStatus('Your module code is in $relativeMainPath.');
    } else {
      // Run doctor; tell the user the next steps.
      final FlutterProject project = await FlutterProject.fromPath(projectDirPath);
      final FlutterProject app = project.hasExampleApp ? project.example : project;
      final String relativeAppPath = fs.path.normalize(fs.path.relative(app.directory.path));
      final String relativeAppMain = fs.path.join(relativeAppPath, 'lib', 'main.dart');
      final String relativePluginPath = fs.path.normalize(fs.path.relative(projectDirPath));
      final String relativePluginMain = fs.path.join(relativePluginPath, 'lib', '$projectName.dart');
      if (doctor.canLaunchAnything) {
        // Let them know a summary of the state of their tooling.
        await doctor.summary();

        printStatus('''
In order to run your $application, type:

  \$ cd $relativeAppPath
  \$ flutter run

Your $application code is in $relativeAppMain.
''');
        if (generatePlugin) {
          printStatus('''
Your plugin code is in $relativePluginMain.

Host platform code is in the "android" and "ios" directories under $relativePluginPath.
To edit platform code in an IDE see https://flutter.io/developing-packages/#edit-plugin-package.
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
        printStatus('Your $application code is in $relativeAppMain');
      }
    }

    return null;
  }

  Future<int> _generateModule(Directory directory, Map<String, dynamic> templateContext, {bool overwrite = false}) async {
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? argResults['description']
        : 'A new flutter module project.';
    templateContext['description'] = description;
    generatedCount += _renderTemplate(fs.path.join('module', 'common'), directory, templateContext, overwrite: overwrite);
    if (argResults['pub']) {
      await pubGet(
        context: PubContext.create,
        directory: directory.path,
        offline: argResults['offline'],
      );
      final FlutterProject project = await FlutterProject.fromDirectory(directory);
      await project.ensureReadyForPlatformSpecificTooling();
    }
    return generatedCount;
  }

  Future<int> _generatePackage(Directory directory, Map<String, dynamic> templateContext, {bool overwrite = false}) async {
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? argResults['description']
        : 'A new Flutter package project.';
    templateContext['description'] = description;
    generatedCount += _renderTemplate('package', directory, templateContext, overwrite: overwrite);
    if (argResults['pub']) {
      await pubGet(
        context: PubContext.createPackage,
        directory: directory.path,
        offline: argResults['offline'],
      );
    }
    return generatedCount;
  }

  Future<int> _generatePlugin(Directory directory, Map<String, dynamic> templateContext, {bool overwrite = false}) async {
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? argResults['description']
        : 'A new flutter plugin project.';
    templateContext['description'] = description;
    generatedCount += _renderTemplate('plugin', directory, templateContext, overwrite: overwrite);
    if (argResults['pub']) {
      await pubGet(
        context: PubContext.createPlugin,
        directory: directory.path,
        offline: argResults['offline'],
      );
    }
    final FlutterProject project = await FlutterProject.fromDirectory(directory);
    gradle.updateLocalProperties(project: project, requireAndroidSdk: false);

    final String projectName = templateContext['projectName'];
    final String organization = templateContext['organization'];
    final String androidPluginIdentifier = templateContext['androidIdentifier'];
    final String exampleProjectName = projectName + '_example';
    templateContext['projectName'] = exampleProjectName;
    templateContext['androidIdentifier'] = _createAndroidIdentifier(organization, exampleProjectName);
    templateContext['iosIdentifier'] = _createUTIIdentifier(organization, exampleProjectName);
    templateContext['description'] = 'Demonstrates how to use the $projectName plugin.';
    templateContext['pluginProjectName'] = projectName;
    templateContext['androidPluginIdentifier'] = androidPluginIdentifier;

    generatedCount += await _generateApp(project.example.directory, templateContext, overwrite: overwrite);
    return generatedCount;
  }

  Future<int> _generateApp(Directory directory, Map<String, dynamic> templateContext, {bool overwrite = false}) async {
    int generatedCount = 0;
    generatedCount += _renderTemplate('app', directory, templateContext, overwrite: overwrite);
    final FlutterProject project = await FlutterProject.fromDirectory(directory);
    generatedCount += _injectGradleWrapper(project);

    if (argResults['with-driver-test']) {
      final Directory testDirectory = directory.childDirectory('test_driver');
      generatedCount += _renderTemplate('driver', testDirectory, templateContext, overwrite: overwrite);
    }

    if (argResults['pub']) {
      await pubGet(context: PubContext.create, directory: directory.path, offline: argResults['offline']);
      await project.ensureReadyForPlatformSpecificTooling();
    }

    gradle.updateLocalProperties(project: project, requireAndroidSdk: false);

    return generatedCount;
  }

  // Takes an application template and replaces the main.dart with one from the
  // documentation website in sampleCode.  Returns the difference in the number
  // of files after applying the sample, since it also deletes the application's
  // test directory (since the template's test doesn't apply to the sample).
  Future<int> _applySample(Directory directory, String sampleCode) async {
    final File mainDartFile = directory.childDirectory('lib').childFile('main.dart');
    await mainDartFile.create(recursive: true);
    await mainDartFile.writeAsString(sampleCode);
    final Directory testDir = directory.childDirectory('test');
    final List<FileSystemEntity> files = testDir.listSync(recursive: true);
    await testDir.delete(recursive: true);
    return -files.length;
  }

  Map<String, dynamic> _templateContext({
    String organization,
    String projectName,
    String projectDescription,
    String androidLanguage,
    String iosLanguage,
    String flutterRoot,
    bool renderDriverTest = false,
    bool withPluginHook = false,
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

  int _renderTemplate(String templateName, Directory directory, Map<String, dynamic> context, {bool overwrite = false}) {
    final Template template = Template.fromName(templateName);
    return template.render(directory, context, overwriteExisting: overwrite);
  }

  int _injectGradleWrapper(FlutterProject project) {
    int filesCreated = 0;
    copyDirectorySync(
      cache.getArtifactDirectory('gradle_wrapper'),
      project.android.hostAppGradleRoot,
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
  final RegExp disallowed = RegExp(r'[^a-zA-Z0-9\-\.\u0080-\uffff]+');
  name = camelCase(name).replaceAll(disallowed, '');
  name = name.isEmpty ? 'untitled' : name;
  return '$organization.$name';
}

final Set<String> _packageDependencies = Set<String>.from(<String>[
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
    final String packageNameDetails = package_names.PubPackageNames().details;
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
String _validateProjectDir(String dirPath, { String flutterRoot, bool overwrite = false }) {
  if (fs.path.isWithin(flutterRoot, dirPath)) {
    return 'Cannot create a project within the Flutter SDK. '
      "Target directory '$dirPath' is within the Flutter SDK at '$flutterRoot'.";
  }

  // If the destination directory is actually a file, then we refuse to
  // overwrite, on the theory that the user probably didn't expect it to exist.
  if (fs.isFileSync(dirPath)) {
    return "Invalid project name: '$dirPath' - refers to an existing file."
        '${overwrite ? ' Refusing to overwrite a file with a directory.' : ''}';
  }

  if (overwrite)
    return null;

  final FileSystemEntityType type = fs.typeSync(dirPath);

  if (type != FileSystemEntityType.notFound) {
    switch (type) {
      case FileSystemEntityType.file:
        // Do not overwrite files.
        return "Invalid project name: '$dirPath' - file exists.";
      case FileSystemEntityType.link:
        // Do not overwrite links.
        return "Invalid project name: '$dirPath' - refers to a link.";
    }
  }

  return null;
}
