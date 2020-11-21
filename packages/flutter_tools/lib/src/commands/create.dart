// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import '../android/gradle_utils.dart' as gradle;
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/net.dart';
import '../base/terminal.dart';
import '../convert.dart';
import '../dart/pub.dart';
import '../features.dart';
import '../flutter_manifest.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../plugins.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import 'create_base.dart';

const String _kNoPlatformsErrorMessage = '''
The plugin project was generated without specifying the `--platforms` flag, no new platforms are added.
To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
directory. You can also find detailed instructions on how to add platforms in the `pubspec.yaml`
at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.
''';

class CreateCommand extends CreateBase {
  CreateCommand() {
    addPlatformsOptions(customHelp: 'The platforms supported by this project. '
        'This argument only works when the --template is set to app or plugin. '
        'Platform folders (e.g. android/) will be generated in the target project. '
        'When adding platforms to a plugin project, the pubspec.yaml will be updated with the requested platform. '
        'Adding desktop platforms requires the corresponding desktop config setting to be enabled.');
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
    argParser.addOption(
      'list-samples',
      help: 'Specifies a JSON output file for a listing of Flutter code samples '
        'that can be created with --sample.',
      valueHelp: 'path',
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
        detectedProjectType = determineTemplateType();
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

    validateOutputDirectoryArg();

    String sampleCode;
    if (argResults['sample'] != null) {
      if (argResults['template'] != null &&
        stringToProjectType(stringArg('template') ?? 'app') != FlutterProjectType.app) {
        throwToolExit('Cannot specify --sample with a project type other than '
          '"${FlutterProjectType.app.name}"');
      }
      // Fetch the sample from the server.
      sampleCode = await _fetchSampleFromServer(stringArg('sample'));
    }

    final FlutterProjectType template = _getProjectType(projectDir);
    final bool generateModule = template == FlutterProjectType.module;
    final bool generatePlugin = template == FlutterProjectType.plugin;
    final bool generatePackage = template == FlutterProjectType.package;

    final List<String> platforms = stringsArg('platforms');
    // `--platforms` does not support module or package.
    if (argResults.wasParsed('platforms') && (generateModule || generatePackage)) {
      final String template = generateModule ? 'module' : 'package';
      throwToolExit(
        'The "--platforms" argument is not supported in $template template.',
        exitCode: 2
      );
    } else if (platforms == null || platforms.isEmpty) {
      throwToolExit('Must specify at least one platform using --platforms',
        exitCode: 2);
    }

    final String organization = await getOrganization();

    final bool overwrite = boolArg('overwrite');
    validateProjectDir(overwrite: overwrite);

    if (boolArg('with-driver-test')) {
      globals.printError(
        '--with-driver-test has been deprecated and will no longer add a flutter '
        'driver template. Instead, learn how to use package:integration_test by '
        'visiting https://pub.dev/packages/integration_test .'
      );
    }

    final Map<String, dynamic> templateContext = createTemplateContext(
      organization: organization,
      projectName: projectName,
      projectDescription: stringArg('description'),
      flutterRoot: flutterRoot,
      withPluginHook: generatePlugin,
      androidLanguage: stringArg('android-language'),
      iosLanguage: stringArg('ios-language'),
      ios: platforms.contains('ios'),
      android: platforms.contains('android'),
      web: featureFlags.isWebEnabled && platforms.contains('web'),
      linux: featureFlags.isLinuxEnabled && platforms.contains('linux'),
      macos: featureFlags.isMacOSEnabled && platforms.contains('macos'),
      windows: featureFlags.isWindowsEnabled && platforms.contains('windows'),
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
        generatedFileCount += await generateApp(relativeDir, templateContext, overwrite: overwrite);
        break;
      case FlutterProjectType.module:
        generatedFileCount += await _generateModule(relativeDir, templateContext, overwrite: overwrite);
        break;
      case FlutterProjectType.package:
        generatedFileCount += await _generatePackage(relativeDir, templateContext, overwrite: overwrite);
        break;
      case FlutterProjectType.plugin:
        generatedFileCount += await _generatePlugin(relativeDir, templateContext, overwrite: overwrite);
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
        '${templateContext['projectName']}.dart',
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
      // Tell the user the next steps.
      final FlutterProject project = FlutterProject.fromPath(projectDirPath);
      final FlutterProject app = project.hasExampleApp ? project.example : project;
      final String relativeAppPath = globals.fs.path.normalize(globals.fs.path.relative(app.directory.path));
      final String relativeAppMain = globals.fs.path.join(relativeAppPath, 'lib', 'main.dart');
      final String relativePluginPath = globals.fs.path.normalize(globals.fs.path.relative(projectDirPath));
      final String relativePluginMain = globals.fs.path.join(relativePluginPath, 'lib', '$projectName.dart');

      // Let them know a summary of the state of their tooling.
      final List<String> platforms = _getSupportedPlatformsFromTemplateContext(templateContext);
      final String platformsString = platforms.join(', ');
      globals.printStatus('''
In order to run your $application, type:

  \$ cd $relativeAppPath
  \$ flutter run

Your $application code is in $relativeAppMain.
''');
        if (generatePlugin) {
          globals.printStatus('''
Your plugin code is in $relativePluginMain.

Host platform code is in the $platformsString directories under $relativePluginPath.
To edit platform code in an IDE see https://flutter.dev/developing-packages/#edit-plugin-package.
''');
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
        generateSyntheticPackage: false,
      );
      final FlutterProject project = FlutterProject.fromDirectory(directory);
      await project.ensureReadyForPlatformSpecificTooling(
        androidPlatform: true,
        iosPlatform: true,
      );
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
        generateSyntheticPackage: false,
      );
    }
    return generatedCount;
  }

  Future<int> _generatePlugin(Directory directory, Map<String, dynamic> templateContext, { bool overwrite = false }) async {
    // Plugin doesn't create any platform by default
    if (!argResults.wasParsed('platforms')) {
      // If the user didn't explicitly declare the platforms, we don't generate any platforms.
      templateContext['ios'] = false;
      templateContext['android'] = false;
      templateContext['web'] = false;
      templateContext['linux'] = false;
      templateContext['macos'] = false;
      templateContext['windows'] = false;
      globals.printError(_kNoPlatformsErrorMessage);
    }
    final List<String> platformsToAdd = _getSupportedPlatformsFromTemplateContext(templateContext);

    final String pubspecPath = globals.fs.path.join(directory.absolute.path, 'pubspec.yaml');
    final FlutterManifest manifest = FlutterManifest.createFromPath(pubspecPath, fileSystem: globals.fs, logger: globals.logger);
    List<String> existingPlatforms = <String>[];
    if (manifest.supportedPlatforms != null) {
      existingPlatforms = manifest.supportedPlatforms.keys.toList();
      for (final String existingPlatform in existingPlatforms) {
        // re-generate files for existing platforms
        templateContext[existingPlatform] = true;
      }
    }

    final bool willAddPlatforms = platformsToAdd.isNotEmpty;
    templateContext['no_platforms'] = !willAddPlatforms;
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? stringArg('description')
        : 'A new flutter plugin project.';
    templateContext['description'] = description;
    generatedCount += await renderTemplate('plugin', directory, templateContext, overwrite: overwrite);

    if (boolArg('pub')) {
      await pub.get(
        context: PubContext.createPlugin,
        directory: directory.path,
        offline: boolArg('offline'),
        generateSyntheticPackage: false,
      );
    }

    final bool addPlatformsToExistingPlugin = willAddPlatforms && existingPlatforms.isNotEmpty;

    if (addPlatformsToExistingPlugin) {
      // If adding new platforms to an existing plugin project, prints
      // a help message containing the platforms maps need to be added to the `platforms` key in the pubspec.
      platformsToAdd.removeWhere(existingPlatforms.contains);
      final YamlMap platformsMapToPrint = Plugin.createPlatformsYamlMap(platformsToAdd, templateContext['pluginClass'] as String, templateContext['androidIdentifier'] as String);
      if (platformsMapToPrint.isNotEmpty) {
        String prettyYaml = '';
        for (final String platform in platformsMapToPrint.keys.toList().cast<String>()) {
          prettyYaml += '$platform:\n';
          for (final String key in (platformsMapToPrint[platform] as YamlMap).keys.toList().cast<String>()) {
            prettyYaml += ' $key: ${platformsMapToPrint[platform][key] as String}\n';
          }
        }
        globals.printStatus('''
The `pubspec.yaml` under the project directory must be updated to support ${platformsToAdd.join(', ')},
Add below lines to under the `platform:` key:
''', emphasis: true);
      globals.printStatus(prettyYaml, emphasis: true, color: TerminalColor.blue);
      globals.printStatus('''
If the `platforms` key does not exist in the `pubspec.yaml`, it might because that the plugin project does not
use the multi-platforms plugin format. We highly recommend a migration to the multi-platforms plugin format.
For detailed instructions on how to format the pubspec.yaml to support platforms using the multi-platforms format, see:
https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms
''', emphasis: true);
      }
    }

    final FlutterProject project = FlutterProject.fromDirectory(directory);
    final bool generateAndroid = templateContext['android'] == true;
    if (generateAndroid) {
      gradle.updateLocalProperties(
        project: project, requireAndroidSdk: false);
    }

    final String projectName = templateContext['projectName'] as String;
    final String organization = templateContext['organization'] as String;
    final String androidPluginIdentifier = templateContext['androidIdentifier'] as String;
    final String exampleProjectName = projectName + '_example';
    templateContext['projectName'] = exampleProjectName;
    templateContext['androidIdentifier'] = createAndroidIdentifier(organization, exampleProjectName);
    templateContext['iosIdentifier'] = createUTIIdentifier(organization, exampleProjectName);
    templateContext['macosIdentifier'] = createUTIIdentifier(organization, exampleProjectName);
    templateContext['description'] = 'Demonstrates how to use the $projectName plugin.';
    templateContext['pluginProjectName'] = projectName;
    templateContext['androidPluginIdentifier'] = androidPluginIdentifier;

    generatedCount += await generateApp(project.example.directory, templateContext, overwrite: overwrite, pluginExampleApp: true);
    return generatedCount;
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

  List<String> _getSupportedPlatformsFromTemplateContext(Map<String, dynamic> templateContext) {
    return <String>[
      if (templateContext['ios'] == true)
        'ios',
      if (templateContext['android'] == true)
        'android',
      if (templateContext['web'] == true)
        'web',
      if (templateContext['linux'] == true)
        'linux',
      if (templateContext['windows'] == true)
        'windows',
      if (templateContext['macos'] == true)
        'macos',
    ];
  }
}
