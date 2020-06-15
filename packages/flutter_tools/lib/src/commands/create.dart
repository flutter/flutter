// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/net.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/pub.dart';
import '../features.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import 'create_mixin.dart';

class CreateCommand extends FlutterCommand with CreateCommandMixin{
  CreateCommand() {
    addPubFlag();
    addOfflineFlag();
    addWithDriverTestFlag();
    _addSampleFlag();
    _addListSamplesFlag();
    addOverwriteFlag();
    addDescriptionFlag();
    addOrgFlag();
    addProjectNameFlag();
    addIOSLanguageFlag();
    addAndroidLanguageFlag();
    argParser.addOption(
      'template',
      abbr: 't',
      allowed: FlutterProjectType.values.map<String>((FlutterProjectType type) => type.name),
      help: 'Specify the type of project to create.',
      valueHelp: 'type',
      allowedHelp: <String, String>{
        FlutterProjectType.app.name: '(default) Generate a Flutter application.',
        FlutterProjectType.package.name: 'Generate a shareable Flutter project containing modular '
            'Dart code.',
        FlutterProjectType.plugin.name: 'Generate a shareable Flutter project containing an API '
            'in Dart code with a platform-specific implementation for Android, for iOS code, or '
            'for both.',
        FlutterProjectType.module.name: 'Generate a project to add a Flutter module to an '
            'existing Android or iOS application.',
      },
      defaultsTo: null,
    );
    // TODO(egarciad): Remove this flag. https://github.com/flutter/flutter/issues/52363
    argParser.addFlag(
      'androidx',
      hide: true,
      negatable: true,
      help: 'Deprecated. Setting this flag has no effect.',
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
  Future<Map<CustomDimensions, String>> get usageValues async {
    return <CustomDimensions, String>{
      CustomDimensions.commandCreateProjectType: stringArg('template'),
      CustomDimensions.commandCreateAndroidLanguage: stringArg('android-language'),
      CustomDimensions.commandCreateIosLanguage: stringArg('ios-language'),
    };
  }

  // Lazy-initialize the net utilities with values from the context.
  Net _cachedNet;
  Net get _net => _cachedNet ??= Net(
    httpClientFactory: context.get<HttpClientFactory>() ?? () => HttpClient(),
    logger: globals.logger,
    platform: globals.platform,
  );

  /// The hostname for the Flutter docs for the current channel.
  String get _snippetsHost => globals.flutterVersion.channel == 'stable'
        ? 'docs.flutter.io'
        : 'master-docs.flutter.io';

  Future<String> _fetchSampleFromServer(String sampleId) async {
    // Sanity check the sampleId
    if (sampleId.contains(RegExp(r'[^-\w\.]'))) {
      throwToolExit('Sample ID "$sampleId" contains invalid characters. Check the ID in the '
        'documentation and try again.');
    }

    final Uri snippetsUri = Uri.https(_snippetsHost, 'snippets/$sampleId.dart');
    final List<int> data = await _net.fetchUrl(snippetsUri);
    if (data == null || data.isEmpty) {
      return null;
    }
    return utf8.decode(data);
  }

  /// Fetches the samples index file from the Flutter docs website.
  Future<String> _fetchSamplesIndexFromServer() async {
    final Uri snippetsUri = Uri.https(_snippetsHost, 'snippets/index.json');
    final List<int> data = await _net.fetchUrl(snippetsUri, maxAttempts: 2);
    if (data == null || data.isEmpty) {
      return null;
    }
    return utf8.decode(data);
  }

  /// Fetches the samples index file from the server and writes it to
  /// [outputFilePath].
  Future<void> _writeSamplesJson(String outputFilePath) async {
    try {
      final File outputFile = globals.fs.file(outputFilePath);
      if (outputFile.existsSync()) {
        throwToolExit('File "$outputFilePath" already exists', exitCode: 1);
      }
      final String samplesJson = await _fetchSamplesIndexFromServer();
      if (samplesJson == null) {
        throwToolExit('Unable to download samples', exitCode: 2);
      } else {
        outputFile.writeAsStringSync(samplesJson);
        globals.printStatus('Wrote samples JSON to "$outputFilePath"');
      }
    } on Exception catch (e) {
      throwToolExit('Failed to write samples JSON to "$outputFilePath": $e', exitCode: 2);
    }
  }

  FlutterProjectType _getProjectType(Directory projectDir) {
    FlutterProjectType template;
    FlutterProjectType detectedProjectType;
    final bool metadataExists = projectDir.absolute.childFile('.metadata').existsSync();
    if (argResults['template'] != null) {
      template = stringToProjectType(stringArg('template'));
    } else {
      // If the project directory exists and isn't empty, then try to determine the template
      // type from the project directory.
      if (projectDir.existsSync() && projectDir.listSync().isNotEmpty) {
        detectedProjectType = determineTemplateType(projectDir);
        if (detectedProjectType == null && metadataExists) {
          // We can only be definitive that this is the wrong type if the .metadata file
          // exists and contains a type that we don't understand, or doesn't contain a type.
          throwToolExit('Sorry, unable to detect the type of project to recreate. '
              'Try creating a fresh project and migrating your existing code to '
              'the new project manually.');
        }
      }
    }
    template ??= detectedProjectType ?? FlutterProjectType.app;
    if (detectedProjectType != null && template != detectedProjectType && metadataExists) {
      // We can only be definitive that this is the wrong type if the .metadata file
      // exists and contains a type that doesn't match.
      throwToolExit("The requested template type '${template.name}' doesn't match the "
          "existing template type of '${detectedProjectType.name}'.");
    }
    return template;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults['list-samples'] != null) {
      // _writeSamplesJson can potentially be long-lived.
      await _writeSamplesJson(stringArg('list-samples'));
      return FlutterCommandResult.success();
    }

    doInitialValidation();
    final String flutterRoot = globals.fs.path.absolute(Cache.flutterRoot);
    final Directory projectDir = globals.fs.directory(argResults.rest.first);
    final String projectDirPath = globals.fs.path.normalize(projectDir.absolute.path);

    final String sampleCode = await _fetchSampleCode();

    final FlutterProjectType template = _getProjectType(projectDir);
    final bool generateModule = template == FlutterProjectType.module;
    final bool shouldGeneratePlugin = template == FlutterProjectType.plugin;
    final bool generatePackage = template == FlutterProjectType.package;

    final String organization = await getOrganization(projectDir: projectDir);

    final bool overwrite = getOverwrite(projectDirPath: projectDirPath, flutterRoot: flutterRoot);

    final String projectName = getProjectName(projectDirPath: projectDirPath);

    final Map<String, dynamic> templateContext = createTemplateContext(
      organization: organization,
      projectName: projectName,
      projectDescription: stringArg('description'),
      flutterRoot: flutterRoot,
      renderDriverTest: boolArg('with-driver-test'),
      withPluginHook: shouldGeneratePlugin,
      androidLanguage: stringArg('android-language'),
      iosLanguage: stringArg('ios-language'),
    );

    final String relativeDirPath = globals.fs.path.relative(projectDirPath);
    if (!projectDir.existsSync() || projectDir.listSync().isEmpty) {
      globals.printStatus('Creating project $relativeDirPath...');
    } else {
      if (sampleCode != null && !overwrite) {
        throwToolExit('Will not overwrite existing project in $relativeDirPath: '
          'must specify --overwrite for samples to overwrite.');
      }
      globals.printStatus('Recreating project $relativeDirPath...');
    }

    final Directory relativeDir = globals.fs.directory(projectDirPath);
    int generatedFileCount = 0;
    switch (template) {
      case FlutterProjectType.app:
        generatedFileCount += await generateApp(relativeDir, templateContext, <String>['ios', 'android'], overwrite: overwrite);
        break;
      case FlutterProjectType.module:
        generatedFileCount += await _generateModule(relativeDir, templateContext, overwrite: overwrite);
        break;
      case FlutterProjectType.package:
        generatedFileCount += await _generatePackage(relativeDir, templateContext, overwrite: overwrite);
        break;
      case FlutterProjectType.plugin:
        generatedFileCount += await generatePlugin(relativeDir, templateContext, <String>['ios', 'android'], overwrite: overwrite);
        break;
    }
    if (sampleCode != null) {
      generatedFileCount += _applySample(relativeDir, sampleCode);
    }
    globals.printStatus('Wrote $generatedFileCount files.');
    globals.printStatus('\nAll done!');
    final String application = sampleCode != null ? 'sample application' : 'application';
    if (generatePackage) {
      final String relativeMainPath = globals.fs.path.normalize(globals.fs.path.join(
        relativeDirPath,
        'lib',
        '$projectName.dart',
      ));
      globals.printStatus('Your package code is in $relativeMainPath');
    } else if (generateModule) {
      final String relativeMainPath = globals.fs.path.normalize(globals.fs.path.join(
          relativeDirPath,
          'lib',
          'main.dart',
      ));
      globals.printStatus('Your module code is in $relativeMainPath.');
    } else {
      // Run doctor; tell the user the next steps.
      final FlutterProject project = FlutterProject.fromPath(projectDirPath);
      final FlutterProject app = project.hasExampleApp ? project.example : project;
      final String relativeAppPath = globals.fs.path.normalize(globals.fs.path.relative(app.directory.path));
      final String relativeAppMain = globals.fs.path.join(relativeAppPath, 'lib', 'main.dart');
      final String relativePluginPath = globals.fs.path.normalize(globals.fs.path.relative(projectDirPath));
      final String relativePluginMain = globals.fs.path.join(relativePluginPath, 'lib', '$projectName.dart');
      if (globals.doctor.canLaunchAnything) {
        // Let them know a summary of the state of their tooling.
        await globals.doctor.summary();

        globals.printStatus('''
In order to run your $application, type:

  \$ cd $relativeAppPath
  \$ flutter run

Your $application code is in $relativeAppMain.
''');
        if (shouldGeneratePlugin) {
          globals.printStatus('''
Your plugin code is in $relativePluginMain.

Host platform code is in the "android" and "ios" directories under $relativePluginPath.
To edit platform code in an IDE see https://flutter.dev/developing-packages/#edit-plugin-package.
''');
        }
      } else {
        globals.printStatus("You'll need to install additional components before you can run "
            'your Flutter app:');
        globals.printStatus('');

        // Give the user more detailed analysis.
        await globals.doctor.diagnose();
        globals.printStatus('');
        globals.printStatus("After installing components, run 'flutter doctor' in order to "
            're-validate your setup.');
        globals.printStatus("When complete, type 'flutter run' from the '$relativeAppPath' "
            'directory in order to launch your app.');
        globals.printStatus('Your $application code is in $relativeAppMain');
      }

      // Warn about unstable templates. This shuold be last so that it's not
      // lost among the other output.
      if (featureFlags.isLinuxEnabled) {
        globals.printStatus('');
        globals.printStatus('WARNING: The Linux tooling and APIs are not yet stable. '
            'You will likely need to re-create the "linux" directory after future '
            'Flutter updates.');
      }
      if (featureFlags.isWindowsEnabled) {
        globals.printStatus('');
        globals.printStatus('WARNING: The Windows tooling and APIs are not yet stable. '
            'You will likely need to re-create the "windows" directory after future '
            'Flutter updates.');
      }
    }
    return FlutterCommandResult.success();
  }

  Future<int> _generateModule(Directory directory, Map<String, dynamic> templateContext, { bool overwrite = false }) async {
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? stringArg('description')
        : 'A new flutter module project.';
    templateContext['description'] = description;
    generatedCount += await renderTemplate(globals.fs.path.join('module', 'common'), directory, templateContext, overwrite: overwrite);
    if (boolArg('pub')) {
      await pub.get(
        context: PubContext.create,
        directory: directory.path,
        offline: boolArg('offline'),
      );
      final FlutterProject project = FlutterProject.fromDirectory(directory);
      await project.ensureReadyForPlatformSpecificTooling(checkProjects: false);
    }
    return generatedCount;
  }

  Future<int> _generatePackage(Directory directory, Map<String, dynamic> templateContext, { bool overwrite = false }) async {
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? stringArg('description')
        : 'A new Flutter package project.';
    templateContext['description'] = description;
    generatedCount += await renderTemplate('package', directory, templateContext, overwrite: overwrite);
    if (boolArg('pub')) {
      await pub.get(
        context: PubContext.createPackage,
        directory: directory.path,
        offline: boolArg('offline'),
      );
    }
    return generatedCount;
  }

  Future<String> _fetchSampleCode() async {
    if (argResults['sample'] != null) {
      if (argResults['template'] != null &&
        stringToProjectType(stringArg('template') ?? 'app') != FlutterProjectType.app) {
        throwToolExit('Cannot specify --sample with a project type other than '
          '"${FlutterProjectType.app.name}"');
      }
      // Fetch the sample from the server.
      return await _fetchSampleFromServer(stringArg('sample'));
    }
    return null;
  }

  // Takes an application template and replaces the main.dart with one from the
  // documentation website in sampleCode.  Returns the difference in the number
  // of files after applying the sample, since it also deletes the application's
  // test directory (since the template's test doesn't apply to the sample).
  int _applySample(Directory directory, String sampleCode) {
    final File mainDartFile = directory.childDirectory('lib').childFile('main.dart');
    mainDartFile.createSync(recursive: true);
    mainDartFile.writeAsStringSync(sampleCode);
    final Directory testDir = directory.childDirectory('test');
    final List<FileSystemEntity> files = testDir.listSync(recursive: true);
    testDir.deleteSync(recursive: true);
    return -files.length;
  }

  // Adds the `argument` flag to the command.
  //
  // The abbr of the argument is `s`.
  //
  // See also: [_fetchSampleCode] to fetch the sample based on this flag.
  void _addSampleFlag() {
    argParser.addOption(
      'sample',
      abbr: 's',
      help: 'Specifies the Flutter code sample to use as the main.dart for an application. Implies '
        '--template=app. The value should be the sample ID of the desired sample from the API '
        'documentation website (http://docs.flutter.dev). An example can be found at '
        'https://master-api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html',
      defaultsTo: null,
      valueHelp: 'id',
    );
  }

  // Adds the `list-samples` flag to the command.
  //
  // If this flag is parsed, the project should provide a JSON output file for a listing of Flutter
  // code samples that can be created with the `sample` flag.
  //
  // See also: [addSampleFlag] to add the `sample` flag.
  void _addListSamplesFlag() {
    argParser.addOption(
      'list-samples',
      help: 'Specifies a JSON output file for a listing of Flutter code samples '
        'that can be created with --sample.',
      valueHelp: 'path',
    );
  }
}
