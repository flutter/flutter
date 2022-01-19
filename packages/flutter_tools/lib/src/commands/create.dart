// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../android/gradle_utils.dart' as gradle;
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/net.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../convert.dart';
import '../dart/pub.dart';
import '../features.dart';
import '../flutter_manifest.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../ios/code_signing.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import 'create_base.dart';

const String kPlatformHelp =
  'The platforms supported by this project. '
  'Platform folders (e.g. android/) will be generated in the target project. '
  'This argument only works when "--template" is set to app or plugin. '
  'When adding platforms to a plugin project, the pubspec.yaml will be updated with the requested platform. '
  'Adding desktop platforms requires the corresponding desktop config setting to be enabled.';

class CreateCommand extends CreateBase {
  CreateCommand({
    bool verboseHelp = false,
  }) : super(verboseHelp: verboseHelp) {
    addPlatformsOptions(customHelp: kPlatformHelp);
    argParser.addOption(
      'template',
      abbr: 't',
      allowed: FlutterProjectType.values.map<String>(flutterProjectTypeToString),
      help: 'Specify the type of project to create.',
      valueHelp: 'type',
      allowedHelp: <String, String>{
        flutterProjectTypeToString(FlutterProjectType.app): '(default) Generate a Flutter application.',
        flutterProjectTypeToString(FlutterProjectType.skeleton): 'Generate a List View / Detail View Flutter '
            'application that follows community best practices.',
        flutterProjectTypeToString(FlutterProjectType.package): 'Generate a shareable Flutter project containing modular '
            'Dart code.',
        flutterProjectTypeToString(FlutterProjectType.plugin): 'Generate a shareable Flutter project containing an API '
            'in Dart code with a platform-specific implementation for Android, for iOS code, or '
            'for both.',
        flutterProjectTypeToString(FlutterProjectType.module): 'Generate a project to add a Flutter module to an '
            'existing Android or iOS application.',
      },
      defaultsTo: null,
    );
    argParser.addOption(
      'sample',
      abbr: 's',
      help: 'Specifies the Flutter code sample to use as the "main.dart" for an application. Implies '
        '"--template=app". The value should be the sample ID of the desired sample from the API '
        'documentation website (http://docs.flutter.dev/). An example can be found at: '
        'https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html',
      defaultsTo: null,
      valueHelp: 'id',
    );
    argParser.addOption(
      'list-samples',
      help: 'Specifies a JSON output file for a listing of Flutter code samples '
        'that can be created with "--sample".',
      valueHelp: 'path',
    );
  }

  @override
  final String name = 'create';

  @override
  final String description = 'Create a new Flutter project.\n\n'
    'If run on a project that already exists, this will repair the project, recreating any files that are missing.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  String get invocation => '${runner.executableName} $name <output directory>';

  @override
  Future<CustomDimensions> get usageValues async {
    return CustomDimensions(
      commandCreateProjectType: stringArg('template'),
      commandCreateAndroidLanguage: stringArg('android-language'),
      commandCreateIosLanguage: stringArg('ios-language'),
    );
  }

  // Lazy-initialize the net utilities with values from the context.
  Net _cachedNet;
  Net get _net => _cachedNet ??= Net(
    httpClientFactory: context.get<HttpClientFactory>(),
    logger: globals.logger,
    platform: globals.platform,
  );

  /// The hostname for the Flutter docs for the current channel.
  String get _snippetsHost => globals.flutterVersion.channel == 'stable'
        ? 'api.flutter.dev'
        : 'master-api.flutter.dev';

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
      throwToolExit("The requested template type '${flutterProjectTypeToString(template)}' doesn't match the "
          "existing template type of '${flutterProjectTypeToString(detectedProjectType)}'.");
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
          '"${flutterProjectTypeToString(FlutterProjectType.app)}"');
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
      globals.printWarning(
        'The "--with-driver-test" argument has been deprecated and will no longer add a flutter '
        'driver template. Instead, learn how to use package:integration_test by '
        'visiting https://pub.dev/packages/integration_test .'
      );
    }

    final String dartSdk = globals.cache.dartSdkBuild;
    final bool includeIos = featureFlags.isIOSEnabled && platforms.contains('ios');
    String developmentTeam;
    if (includeIos) {
      developmentTeam = await getCodeSigningIdentityDevelopmentTeam(
        processManager: globals.processManager,
        platform: globals.platform,
        logger: globals.logger,
        config: globals.config,
        terminal: globals.terminal,
      );
    }

    // The dart project_name is in snake_case, this variable is the Title Case of the Project Name.
    final String titleCaseProjectName = snakeCaseToTitleCase(projectName);

    final Map<String, Object> templateContext = createTemplateContext(
      organization: organization,
      projectName: projectName,
      titleCaseProjectName: titleCaseProjectName,
      projectDescription: stringArg('description'),
      flutterRoot: flutterRoot,
      withPluginHook: generatePlugin,
      androidLanguage: stringArg('android-language'),
      iosLanguage: stringArg('ios-language'),
      iosDevelopmentTeam: developmentTeam,
      ios: includeIos,
      android: featureFlags.isAndroidEnabled && platforms.contains('android'),
      web: featureFlags.isWebEnabled && platforms.contains('web'),
      linux: featureFlags.isLinuxEnabled && platforms.contains('linux'),
      macos: featureFlags.isMacOSEnabled && platforms.contains('macos'),
      windows: featureFlags.isWindowsEnabled && platforms.contains('windows'),
      windowsUwp: featureFlags.isWindowsUwpEnabled && platforms.contains('winuwp'),
      // Enable null safety everywhere.
      dartSdkVersionBounds: '">=$dartSdk <3.0.0"',
      implementationTests: boolArg('implementation-tests'),
      agpVersion: gradle.templateAndroidGradlePluginVersion,
      kotlinVersion: gradle.templateKotlinGradlePluginVersion,
      gradleVersion: gradle.templateDefaultGradleVersion,
    );

    final String relativeDirPath = globals.fs.path.relative(projectDirPath);
    final bool creatingNewProject = !projectDir.existsSync() || projectDir.listSync().isEmpty;
    if (creatingNewProject) {
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
        generatedFileCount += await generateApp(
          'app',
          relativeDir,
          templateContext,
          overwrite: overwrite,
          printStatusWhenWriting: !creatingNewProject,
        );
        break;
      case FlutterProjectType.skeleton:
        generatedFileCount += await generateApp(
          'skeleton',
          relativeDir,
          templateContext,
          overwrite: overwrite,
          printStatusWhenWriting: !creatingNewProject,
        );
        break;
      case FlutterProjectType.module:
        generatedFileCount += await _generateModule(
          relativeDir,
          templateContext,
          overwrite: overwrite,
          printStatusWhenWriting: !creatingNewProject,
        );
        break;
      case FlutterProjectType.package:
        generatedFileCount += await _generatePackage(
          relativeDir,
          templateContext,
          overwrite: overwrite,
          printStatusWhenWriting: !creatingNewProject,
        );
        break;
      case FlutterProjectType.plugin:
        generatedFileCount += await _generatePlugin(
          relativeDir,
          templateContext,
          overwrite: overwrite,
          printStatusWhenWriting: !creatingNewProject,
        );
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
    } else if (generatePlugin) {
      final String relativePluginPath = globals.fs.path.normalize(globals.fs.path.relative(projectDirPath));
      final List<String> requestedPlatforms = _getUserRequestedPlatforms();
      final String platformsString = requestedPlatforms.join(', ');
      _printPluginDirectoryLocationMessage(relativePluginPath, projectName, platformsString);
      if (!creatingNewProject && requestedPlatforms.isNotEmpty) {
        _printPluginUpdatePubspecMessage(relativePluginPath, platformsString);
      } else if (_getSupportedPlatformsInPlugin(projectDir).isEmpty) {
        _printNoPluginMessage();
      }

      final List<String> platformsToWarn = _getPlatformWarningList(requestedPlatforms);
      if (platformsToWarn.isNotEmpty) {
        _printWarningDisabledPlatform(platformsToWarn);
      }
      _printPluginAddPlatformMessage(relativePluginPath);
    } else  {
      // Tell the user the next steps.
      final FlutterProject project = FlutterProject.fromDirectory(globals.fs.directory(projectDirPath));
      final FlutterProject app = project.hasExampleApp ? project.example : project;
      final String relativeAppPath = globals.fs.path.normalize(globals.fs.path.relative(app.directory.path));
      final String relativeAppMain = globals.fs.path.join(relativeAppPath, 'lib', 'main.dart');
      final List<String> requestedPlatforms = _getUserRequestedPlatforms();

      // Let them know a summary of the state of their tooling.
      globals.printStatus('''
In order to run your $application, type:

  \$ cd $relativeAppPath
  \$ flutter run

Your $application code is in $relativeAppMain.
''');
      // Show warning if any selected platform is not enabled
      final List<String> platformsToWarn = _getPlatformWarningList(requestedPlatforms);
      if (platformsToWarn.isNotEmpty) {
        _printWarningDisabledPlatform(platformsToWarn);
      }
    }

    return FlutterCommandResult.success();
  }

  Future<int> _generateModule(
    Directory directory,
    Map<String, dynamic> templateContext, {
    bool overwrite = false,
    bool printStatusWhenWriting = true,
  }) async {
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? stringArg('description')
        : 'A new flutter module project.';
    templateContext['description'] = description;
    generatedCount += await renderTemplate(
      globals.fs.path.join('module', 'common'),
      directory,
      templateContext,
      overwrite: overwrite,
      printStatusWhenWriting: printStatusWhenWriting,
    );
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

  Future<int> _generatePackage(
    Directory directory,
    Map<String, dynamic> templateContext, {
    bool overwrite = false,
    bool printStatusWhenWriting = true,
  }) async {
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? stringArg('description')
        : 'A new Flutter package project.';
    templateContext['description'] = description;
    generatedCount += await renderTemplate(
      'package',
      directory,
      templateContext,
      overwrite: overwrite,
      printStatusWhenWriting: printStatusWhenWriting,
    );
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

  Future<int> _generatePlugin(
    Directory directory,
    Map<String, dynamic> templateContext, {
    bool overwrite = false,
    bool printStatusWhenWriting = true,
  }) async {
    // Plugins only add a platform if it was requested explicitly by the user.
    if (!argResults.wasParsed('platforms')) {
      for (final String platform in kAllCreatePlatforms) {
        templateContext[platform] = false;
      }
    }
    final List<String> platformsToAdd = _getSupportedPlatformsFromTemplateContext(templateContext);

    final List<String> existingPlatforms = _getSupportedPlatformsInPlugin(directory);
    for (final String existingPlatform in existingPlatforms) {
      // re-generate files for existing platforms
      templateContext[existingPlatform] = true;
    }

    final bool willAddPlatforms = platformsToAdd.isNotEmpty;
    templateContext['no_platforms'] = !willAddPlatforms;
    int generatedCount = 0;
    final String description = argResults.wasParsed('description')
        ? stringArg('description')
        : 'A new flutter plugin project.';
    templateContext['description'] = description;
    generatedCount += await renderTemplate(
      'plugin',
      directory,
      templateContext,
      overwrite: overwrite,
      printStatusWhenWriting: printStatusWhenWriting,
    );

    if (boolArg('pub')) {
      await pub.get(
        context: PubContext.createPlugin,
        directory: directory.path,
        offline: boolArg('offline'),
        generateSyntheticPackage: false,
      );
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
    final String exampleProjectName = '${projectName}_example';
    templateContext['projectName'] = exampleProjectName;
    templateContext['androidIdentifier'] = CreateBase.createAndroidIdentifier(organization, exampleProjectName);
    templateContext['iosIdentifier'] = CreateBase.createUTIIdentifier(organization, exampleProjectName);
    templateContext['macosIdentifier'] = CreateBase.createUTIIdentifier(organization, exampleProjectName);
    templateContext['windowsIdentifier'] = CreateBase.createWindowsIdentifier(organization, exampleProjectName);
    templateContext['description'] = 'Demonstrates how to use the $projectName plugin.';
    templateContext['pluginProjectName'] = projectName;
    templateContext['androidPluginIdentifier'] = androidPluginIdentifier;

    generatedCount += await generateApp(
      'app',
      project.example.directory,
      templateContext,
      overwrite: overwrite,
      pluginExampleApp: true,
      printStatusWhenWriting: printStatusWhenWriting,
    );
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
      for (String platform in kAllCreatePlatforms)
        if (templateContext[platform] == true) platform
    ];
  }

  // Returns a list of platforms that are explicitly requested by user via `--platforms`.
  List<String> _getUserRequestedPlatforms() {
    if (!argResults.wasParsed('platforms')) {
      return <String>[];
    }
    return stringsArg('platforms');
  }
}


// Determine what platforms are supported based on generated files.
List<String> _getSupportedPlatformsInPlugin(Directory projectDir) {
  final String pubspecPath = globals.fs.path.join(projectDir.absolute.path, 'pubspec.yaml');
  final FlutterManifest manifest = FlutterManifest.createFromPath(pubspecPath, fileSystem: globals.fs, logger: globals.logger);
  final List<String> platforms = manifest.validSupportedPlatforms == null
    ? <String>[]
    : manifest.validSupportedPlatforms.keys.toList();
  return platforms;
}

void _printPluginDirectoryLocationMessage(String pluginPath, String projectName, String platformsString) {
  final String relativePluginMain = globals.fs.path.join(pluginPath, 'lib', '$projectName.dart');
  final String relativeExampleMain = globals.fs.path.join(pluginPath, 'example', 'lib', 'main.dart');
  globals.printStatus('''

Your plugin code is in $relativePluginMain.

Your example app code is in $relativeExampleMain.

''');
  if (platformsString != null && platformsString.isNotEmpty) {
    globals.printStatus('''
Host platform code is in the $platformsString directories under $pluginPath.
To edit platform code in an IDE see https://flutter.dev/developing-packages/#edit-plugin-package.

    ''');
  }
}

void _printPluginUpdatePubspecMessage(String pluginPath, String platformsString) {
  globals.printStatus('''
You need to update $pluginPath/pubspec.yaml to support $platformsString.
''', emphasis: true, color: TerminalColor.red);
}

void _printNoPluginMessage() {
    globals.printError('''
You've created a plugin project that doesn't yet support any platforms.
''');
}

void _printPluginAddPlatformMessage(String pluginPath) {
  globals.printStatus('''
To add platforms, run `flutter create -t plugin --platforms <platforms> .` under $pluginPath.
For more information, see https://flutter.dev/go/plugin-platforms.

''');
}

// returns a list disabled, but requested platforms
List<String> _getPlatformWarningList(List<String> requestedPlatforms) {
  final List<String> platformsToWarn = <String>[
  if (requestedPlatforms.contains('web') && !featureFlags.isWebEnabled)
    'web',
  if (requestedPlatforms.contains('macos') && !featureFlags.isMacOSEnabled)
    'macos',
  if (requestedPlatforms.contains('windows') && !featureFlags.isWindowsEnabled)
    'windows',
  if (requestedPlatforms.contains('linux') && !featureFlags.isLinuxEnabled)
    'linux',
  ];

  return platformsToWarn;
}

void _printWarningDisabledPlatform(List<String> platforms) {
  final List<String> desktop = <String>[];
  final List<String> web = <String>[];

  for (final String platform in platforms) {
    if (platform == 'web') {
      web.add(platform);
    } else if (platform == 'macos' || platform == 'windows' || platform == 'linux') {
      desktop.add(platform);
    }
  }

  if (desktop.isNotEmpty) {
    final String platforms = desktop.length > 1 ? 'platforms' : 'platform';
    final String verb = desktop.length > 1 ? 'are' : 'is';

    globals.printStatus('''
The desktop $platforms: ${desktop.join(', ')} $verb currently not supported on your local environment.
For more details, see: https://flutter.dev/desktop
''');
  }
  if (web.isNotEmpty) {
    globals.printStatus('''
The web is currently not supported on your local environment.
For more details, see: https://flutter.dev/docs/get-started/web
''');
  }
}
