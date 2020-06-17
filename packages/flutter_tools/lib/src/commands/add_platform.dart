// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:yaml/yaml.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../cache.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';
import 'dart:async';

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';


import '../base/common.dart';
import '../base/file_system.dart';
import '../cache.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';

class AddPlatformCommand extends CreateCommand {
  AddPlatformCommand() {
    // TODO(cyanglaz): remove the below ignore when https://github.com/flutter/flutter/issues/59494 is done.
    // ignore: invalid_use_of_visible_for_testing_member
    addPlatformsOptions();
    addPubFlag();
    addOfflineFlag();
    _addOverwriteFlag();
    _addOrgFlag();
    _addIOSLanguageFlag();
    _addAndroidLanguageFlag();
  }

  @override
  final String name = 'add-platform';

  @override
  final String description = 'Add platforms to a existing flutter plugin project';

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
    _doInitialValidation();
    final String flutterRoot = globals.fs.path.absolute(Cache.flutterRoot);
    final Directory projectDir = globals.fs.directory(argResults.rest.first);
    final String projectDirPath = globals.fs.path.normalize(projectDir.absolute.path);

    // TODO(cyanglaz): remove the below ignore when https://github.com/flutter/flutter/issues/59494 is done.
    // ignore: invalid_use_of_visible_for_testing_member
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

    final String organization = await _getOrganization(projectDir: projectDir);

    final bool overwrite = _getOverwrite(projectDirPath: projectDirPath, flutterRoot: flutterRoot);

    final String projectName = globals.fs.path.basename(projectDirPath);

    final String relativeDirPath = globals.fs.path.relative(projectDirPath);
    globals.printStatus('Creating project $relativeDirPath...');
    final String pubspecPath = globals.fs.path.join(projectDir.absolute.path, 'pubspec.yaml');
    final YamlMap pubspec = loadYaml(globals.fs.file(pubspecPath).readAsStringSync()) as YamlMap;
    // TODO(cyanglaz): remove the below ignore when https://github.com/flutter/flutter/issues/59494 is done.
    // ignore: invalid_use_of_visible_for_testing_member
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

    await _runDoctor(application: application, platforms: platforms);

    return FlutterCommandResult.success();
  }

  Future<int> _addPlatforms(Directory directory,
      Map<String, dynamic> templateContext, final List<String> platforms, FlutterProjectType projectType,
      {bool overwrite = false}) async {

    int generatedCount = 0;
    switch (projectType) {
      case FlutterProjectType.plugin:
        // TODO(cyanglaz): remove the below ignore when https://github.com/flutter/flutter/issues/59494 is done.
        // ignore: invalid_use_of_visible_for_testing_member
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

  /// Adds the `with-driver-test` argument to the command
  ///
  /// The type of the argument is [bool] and defaults to `false`. It is also `negatable`.
  ///
  /// The [generateApp] method will read this flag and determine if a driver test should be generated for the
  /// app. If the flag is not added or the value is `false`, no driver tests are generated.
  ///
  /// See also: [ArgParser.addFlag] for informations on `negatable`.
  void addWithDriverTestFlag() {
    argParser.addFlag(
      'with-driver-test',
      negatable: true,
      defaultsTo: false,
      help: "Also add a flutter_driver dependency and generate a sample 'flutter drive' test.",
    );
  }

  /// Adds the `project-name` argument to the command.
  ///
  /// The type of the argument is [String] and it defaults to `null`.
  ///
  /// See also: [getProjectName] to get the value.
  void addProjectNameFlag() {
    argParser.addOption(
      'project-name',
      defaultsTo: null,
      help: 'The project name for this new Flutter project. This must be a valid dart package name.',
    );
  }

  /// Adds the `pub` argument to the command.
  ///
  /// The type of the argument is [bool] and it defaults to `true`
  ///
  /// Generate methods such as [generateApp] and [generatePlugin] will run `flutter pub get`
  /// after the project has been updated.
  void addPubFlag() {
    argParser.addFlag(
      'pub',
      defaultsTo: true,
      help:
          'Whether to run "flutter pub get" after the project has been updated.',
    );
  }

  /// Adds the `offline` argument to the command.
  ///
  /// The type of the argument is [bool] and it defaults to `false`.
  ///
  /// When the `flutter pub get` runs based on the `pub` flag, this flag determines
  /// if the command runs in offline mode.
  ///
  /// See also: [addPubFlag] to add the `pub` flag.
  void addOfflineFlag() {
    argParser.addFlag(
      'offline',
      defaultsTo: false,
      help:
          'When "flutter pub get" is run by the plugin command, this indicates '
          'whether to run it in offline mode or not. In offline mode, it will need to '
          'have all dependencies already available in the pub cache to succeed.',
    );
  }

  /// Add the `overwrite` argument to the command.
  ///
  /// The type of the argument is [bool] and it defaults to `false`. It is also `negatable`.
  ///
  /// When the `flutter pub get` runs based on the `pub` flag, this flag determines
  /// if the command runs in offline mode.
  ///
  /// See also:
  ///   * [addPubFlag] to add the `pub` flag.
  ///   * [ArgParser.addFlag] for informations on `negatable`.
  ///   * [getOverwrite] to get the value of this argument.
  void _addOverwriteFlag() {
    argParser.addFlag(
      'overwrite',
      negatable: true,
      defaultsTo: false,
      help: 'When performing operations, overwrite existing files.',
    );
  }

  /// Add the `ios-language` argument to the command.
  ///
  /// The abbr of the argument is `i`.
  ///
  /// The type of the argument is [List]. The valid options are `objc`, `swift`. Defaults to `swift`.
  ///
  /// This should only be added if the project contains platform specific code such as
  /// a Flutter App project or a Flutter plugin project.
  ///
  /// See also:
  ///   * [addAndroidLanguageFlag] to add `android-language` flag.
  ///   * [addPlatformsOptions] to allow user to specify the supported platforms including ios.
  void _addIOSLanguageFlag() {
    argParser.addOption(
      'ios-language',
      abbr: 'i',
      defaultsTo: 'swift',
      allowed: <String>['objc', 'swift'],
    );
  }

  /// Add the `android-language` argument to the command.
  ///
  /// The abbr of the argument is `a`.
  ///
  /// The type of the argument is [List]. The valid options are `kotlin`, `java`. Defaults to `kotlin`.
  ///
  /// This should only be added if the project contains platform specific code such as
  /// a Flutter App project or a Flutter plugin project.
  ///
  /// See also:
  ///   * [addIOSLanguageFlag] to add `ios-language` flag.
  ///   * [addPlatformsOptions] to allow user to specify the supported platforms including android.
  void _addAndroidLanguageFlag() {
    argParser.addOption(
      'android-language',
      abbr: 'a',
      defaultsTo: 'kotlin',
      allowed: <String>['java', 'kotlin'],
    );
  }

  /// Adds an `org` argument to the command.
  ///
  /// Defaults to `com.example`.
  ///
  /// See also: [getOrganization] for getting the value.
  void _addOrgFlag() {
    argParser.addOption(
      'org',
      defaultsTo: 'com.example',
      help: 'The organization responsible for your \ Flutter project, in reverse domain name notation. '
            'This string is used in Java package names and as prefix in the iOS bundle identifier.',
    );
  }


  /// Perform an initial validation of the environment and args.
  ///
  /// Should be called as early as possible in [FlutterCommand.runCommand].
  void _doInitialValidation() {
    if (argResults.rest.isEmpty) {
      throwToolExit('No option specified for the output directory.\n$usage', exitCode: 2);
    }

    if (argResults.rest.length > 1) {
      String message = 'Multiple output directories specified.';
      for (final String arg in argResults.rest) {
        if (arg.startsWith('-')) {
          message += '\nTry moving $arg to be immediately following $name';
          break;
        }
      }
      throwToolExit(message, exitCode: 2);
    }

    if (Cache.flutterRoot == null) {
      throwToolExit('Neither the --flutter-root command line flag nor the FLUTTER_ROOT environment '
        'variable was specified. Unable to find package:flutter.', exitCode: 2);
    }

    final String flutterRoot = globals.fs.path.absolute(Cache.flutterRoot);

    final String flutterPackagesDirectory = globals.fs.path.join(flutterRoot, 'packages');
    final String flutterPackagePath = globals.fs.path.join(flutterPackagesDirectory, 'flutter');
    if (!globals.fs.isFileSync(globals.fs.path.join(flutterPackagePath, 'pubspec.yaml'))) {
      throwToolExit('Unable to find package:flutter in $flutterPackagePath', exitCode: 2);
    }

    final String flutterDriverPackagePath = globals.fs.path.join(flutterRoot, 'packages', 'flutter_driver');
    if (!globals.fs.isFileSync(globals.fs.path.join(flutterDriverPackagePath, 'pubspec.yaml'))) {
      throwToolExit('Unable to find package:flutter_driver in $flutterDriverPackagePath', exitCode: 2);
    }
  }

  /// Extract the organization.
  ///
  /// If the user explicitly specifies the organization in the `org` argument. The value will be returned.
  /// If the user does not specify the organization, the organization in existing project will be returned.
  /// Else the default value will be returned.
  ///
  /// Throws an error if the existing project contains multiple organizations, and the current running command
  /// did not specify an organization.
  ///
  /// See also [addOrgFlag] for adding the `org` argument.
  Future<String> _getOrganization({@required Directory projectDir}) async {
    String organization = stringArg('org');
    if (!argResults.wasParsed('org')) {
      final FlutterProject project = FlutterProject.fromDirectory(projectDir);
      final Set<String> existingOrganizations = await project.organizationNames;
      if (existingOrganizations.length == 1) {
        organization = existingOrganizations.first;
      } else if (existingOrganizations.length > 1) {
        throwToolExit(
          'Ambiguous organization in existing files: $existingOrganizations. '
          'The --org command line argument must be specified to recreate project.'
        );
      }
    }
    return organization;
  }

  /// Extract the `overwrite` argument from the command.
  ///
  /// Throws an error if the directory is not a valid Flutter project directory.
  bool _getOverwrite({@required String projectDirPath, @required String flutterRoot}) {
    final bool overwrite = boolArg('overwrite');
    // TODO(cyanglaz): remove the below ignore when https://github.com/flutter/flutter/issues/59494 is done.
    // ignore: invalid_use_of_visible_for_testing_member
    final String error = validateProjectDir(projectDirPath, flutterRoot: flutterRoot, overwrite: overwrite);
    if (error != null) {
      throwToolExit(error);
    }
    return overwrite;
  }

    /// Run doctor; tell the user the next steps.
  Future<void> _runDoctor({String application, List<String> platforms}) async {
    final Directory projectDir = globals.fs.directory(argResults.rest.first);
    final String projectDirPath = globals.fs.path.normalize(projectDir.absolute.path);
    final FlutterProject project = FlutterProject.fromDirectory(projectDir);
    final FlutterProject app =
        project.hasExampleApp ? project.example : project;
    final String relativeAppPath =
        globals.fs.path.normalize(globals.fs.path.relative(app.directory.path));
    final String relativeAppMain =
        globals.fs.path.join(relativeAppPath, 'lib', 'main.dart');
    final String relativePluginPath =
        globals.fs.path.normalize(globals.fs.path.relative(projectDirPath));
    final String relativePluginMain = globals.fs.path
        .join(relativePluginPath, 'lib', '${project.manifest.appName}.dart');
    String platformsString = '';
    for (int i = 0; i < platforms.length; i ++) {
      platformsString += platforms[i];
      if (i  != 0 ) {
        platformsString += ', ';
      }
    }
    if (globals.doctor.canLaunchAnything) {
      // Let them know a summary of the state of their tooling.
      await globals.doctor.summary();

      globals.printStatus('''
In order to run your $application, type:

\$ cd $relativeAppPath
\$ flutter run

Your $application code is in $relativeAppMain.
''');
      globals.printStatus('''
Your plugin code is in $relativePluginMain.

Host platform code is in the $platformsString directories under $relativePluginPath.
To edit platform code in an IDE see https://flutter.dev/developing-packages/#edit-plugin-package.
''');
      // Warn about unstable templates. This should be last so that it's not
      // lost among the other output.
      if (platforms.contains('linux')) {
        globals.printStatus('');
        globals.printStatus(
            'WARNING: The Linux tooling and APIs are not yet stable. '
            'You will likely need to re-create the "linux" directory after future '
            'Flutter updates.');
      }
      if (platforms.contains('windows')) {
        globals.printStatus('');
        globals.printStatus(
            'WARNING: The Windows tooling and APIs are not yet stable. '
            'You will likely need to re-create the "windows" directory after future '
            'Flutter updates.');
      }
    }
  }
}
