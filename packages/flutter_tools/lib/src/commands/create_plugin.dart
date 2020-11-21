// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import '../android/gradle_utils.dart' as gradle;
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/terminal.dart';
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

/// A command that creates plugin projects.
class CreatePluginCommand extends CreateBase {
  CreatePluginCommand() {
    addPlatformsOptions();
  }

  @override
  final String name = 'plugin';

  @override
  final String description = 'Create a new Flutter plugin project.\n\n'
    'If run on a project that already exists, this will repair the project, recreating any files that are missing.';

  @override
  String get invocation => '${runner.executableName} $name <output directory>';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    return <CustomDimensions, String>{
      CustomDimensions.commandCreateAndroidLanguage: stringArg('android-language'),
      CustomDimensions.commandCreateIosLanguage: stringArg('ios-language'),
    };
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

    validateOutputDirectoryArg();

    final List<String> platforms = stringsArg('platforms');
    if (platforms == null || platforms.isEmpty) {
      throwToolExit('Must specify at least one platform using --platforms',
        exitCode: 2);
    }

    final String organization = await getOrganization();

    final bool overwrite = boolArg('overwrite');
    validateProjectDir(overwrite: overwrite);

    final Map<String, dynamic> templateContext = createTemplateContext(
      organization: organization,
      projectName: projectName,
      projectDescription: stringArg('description'),
      flutterRoot: flutterRoot,
      withPluginHook: true,
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
      globals.printStatus('Recreating project $relativeDirPath...');
    }

    final Directory relativeDir = globals.fs.directory(projectDirPath);
    int generatedFileCount = 0;

    generatedFileCount += await _generatePlugin(relativeDir, templateContext, overwrite: overwrite);

    globals.printStatus('Wrote $generatedFileCount files.');
    globals.printStatus('\nAll done!');

      // Tell the user the next steps.
      final FlutterProject project = FlutterProject.fromPath(projectDirPath);
      final FlutterProject app = project.hasExampleApp ? project.example : project;
      final String relativeAppPath = globals.fs.path.normalize(globals.fs.path.relative(app.directory.path));
      final String relativeAppMain = globals.fs.path.join(relativeAppPath, 'lib', 'main.dart');
      final String relativePluginPath = globals.fs.path.normalize(globals.fs.path.relative(projectDirPath));
      final String relativePluginMain = globals.fs.path.join(relativePluginPath, 'lib', '$projectName.dart');

      // Let them know a summary of the state of their tooling.
      final List<String> generatedPlatforms = _getSupportedPlatformsFromTemplateContext(templateContext);
      final String platformsString = generatedPlatforms.join(', ');

      globals.printStatus('''
Your plugin code is in $relativePluginMain.
Your example app code is in $relativeAppMain.

Host platform code is in the $platformsString directories under $relativePluginPath.
To edit platform code in an IDE see https://flutter.dev/developing-packages/#edit-plugin-package.
''');
    return FlutterCommandResult.success();
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
