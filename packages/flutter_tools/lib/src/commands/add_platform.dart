// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:yaml/yaml.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../cache.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import 'create_mixin.dart';

class AddPlatformCommand extends FlutterCommand with CreateCommandMixin {
  AddPlatformCommand() {
    addPlatformsOptions();
    addPubFlag();
    addOfflineFlag();
    addOverwriteFlag();
    addOrgFlag();
    addIOSLanguageFlag();
    addAndroidLanguageFlag();
  }

  @override
  final String name = 'add-platform';

  @override
  final String description = 'Command to add platforms to a existing flutter plugin project';

  @override
  String get invocation => '${runner.executableName} $name <output directory>';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    return <CustomDimensions, String>{
      CustomDimensions.commandCreateAndroidLanguage:
          stringArg('android-language'),
      CustomDimensions.commandCreateIosLanguage: stringArg('ios-language'),
    };
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    doInitialValidation();
    final String flutterRoot = globals.fs.path.absolute(Cache.flutterRoot);
    final Directory projectDir = globals.fs.directory(argResults.rest.first);
    final String projectDirPath = globals.fs.path.normalize(projectDir.absolute.path);

    final FlutterProjectType template = determineTemplateType(projectDir);
    if (template != FlutterProjectType.plugin) {
          throwToolExit('The target directory is not a flutter plugin directory.',
          exitCode: 2);
    }

    final List<String> platforms = stringsArg('platform');
    if (platforms == null || platforms.isEmpty) {
      throwToolExit('Must specify at least one platform using --platforms',
          exitCode: 2);
    }

    final String organization = await getOrganization(projectDir: projectDir);

    final bool overwrite = getOverwrite(projectDirPath: projectDirPath, flutterRoot: flutterRoot);

    final String projectName = globals.fs.path.basename(projectDirPath);

    final String relativeDirPath = globals.fs.path.relative(projectDirPath);
    globals.printStatus('Creating project $relativeDirPath...');
    final String pubspecPath = globals.fs.path.join(projectDir.absolute.path, 'pubspec.yaml');
    final YamlMap pubspec = loadYaml(globals.fs.file(pubspecPath).readAsStringSync()) as YamlMap;
    final Map<String, dynamic> templateContext = createTemplateContext(
      organization: organization,
      projectName: projectName,
      projectDescription: pubspec['description'] as String,
      flutterRoot: flutterRoot,
      withPluginHook: template == FlutterProjectType.plugin,
      androidLanguage: stringArg('android-language'),
      iosLanguage: stringArg('ios-language'),
      renderDriverTest: false,
    );

    final Directory relativeDir = globals.fs.directory(projectDirPath);
    int generatedFileCount = 0;

    generatedFileCount += await _addPlatforms(
        relativeDir, templateContext, platforms, template,
        overwrite: overwrite);

    globals.printStatus('Wrote $generatedFileCount files.');
    globals.printStatus('\nAll done!');

    const String application = 'application';

    await runDoctor(application: application, platforms: platforms);

    return FlutterCommandResult.success();
  }

  Future<int> _addPlatforms(Directory directory,
      Map<String, dynamic> templateContext, final List<String> platforms, FlutterProjectType projectType,
      {bool overwrite = false}) async {

    int generatedCount = 0;
    switch (projectType) {
      case FlutterProjectType.plugin:
        generatedCount += await generatePlugin(directory, templateContext, platforms, overwrite: overwrite);
        break;
      case FlutterProjectType.app:
      case FlutterProjectType.module:
      case FlutterProjectType.package:
        throwToolExit('add-platform command must be executed in a flutter plugin directory',
          exitCode: 2);
    }
    return generatedCount;
  }
}
