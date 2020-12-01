// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/project.dart';

import '../android/gradle_utils.dart' as gradle;
import '../base/common.dart';
import '../base/file_system.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import 'create_base.dart';

/// A command that creates plugin projects.
class CreatePluginCommand extends CreateBase {
  CreatePluginCommand() {
    addPlatformsOptions();
  }

  @override
  final String name = 'create-plugin';

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

    // TODO(cyanglaz): remove this when `flutter create -t plugin` is completely removed.
    templateContext['no_platforms'] = false;

    final String relativeDirPath = globals.fs.path.relative(projectDirPath);
    final bool creatingNewProject = !projectDir.existsSync() || projectDir.listSync().isEmpty;
    if (creatingNewProject) {
      globals.printStatus('Creating project $relativeDirPath...');
    } else {
      globals.printStatus('Recreating project $relativeDirPath...');
    }

    final Directory relativeDir = globals.fs.directory(projectDirPath);
    int generatedFileCount = 0;

    generatedFileCount += await _generatePlugin(relativeDir, templateContext, overwrite: overwrite);

    globals.printStatus('Wrote $generatedFileCount files.');
    globals.printStatus('\nAll done!');

    final String relativePluginPath = globals.fs.path.normalize(globals.fs.path.relative(projectDirPath));
    final List<String> requestedPlatforms = stringsArg('platforms');
    final String platformsString = requestedPlatforms.join(', ');
    printPluginDirectoryLocationMessage(relativePluginPath, projectName, platformsString);
    if (!creatingNewProject && requestedPlatforms.isNotEmpty) {
      printPluginUpdatePubspecMessage(relativePluginPath, platformsString);
    }
    return FlutterCommandResult.success();
  }

  Future<int> _generatePlugin(Directory directory, Map<String, dynamic> templateContext, { bool overwrite = false }) async {
    final List<String> platformsToAdd = stringsArg('platforms');
    assert(platformsToAdd.isNotEmpty);

    final List<String> existingPlatforms = getSupportedPlatformsInPlugin(directory);
    for (final String existingPlatform in existingPlatforms) {
      // re-generate files for existing platforms
      templateContext[existingPlatform] = true;
    }

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
}
