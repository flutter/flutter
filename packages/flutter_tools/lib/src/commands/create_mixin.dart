// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

import '../android/android.dart' as android_common;
import '../android/android_sdk.dart' as android_sdk;
import '../android/gradle_utils.dart' as gradle;
import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/net.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../convert.dart';
import '../dart/pub.dart';
import '../features.dart';
import '../flutter_project_metadata.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../template.dart';

/// A [FlutterCommand] mixin can be implemented by any commands that tries to create or update
/// a Flutter project.
/// An example usage can be found in [CreateCommand]
mixin CreateCommandMixin on FlutterCommand {

  /// Adds a `platform` argument to the command.
  ///
  /// The type of the argument is [List]. The valid options are: `ios`, `android`, `windows`, `linux`, `macos`, `web`.
  ///
  /// These platforms should indicate what platforms the project will support after running the command.
  /// The result can be used in generate methods such as [generateApp] and [generatePlugin].
  ///
  /// Adding argument is optional if the command does not require the user to explicitly state what platforms the project supports.
  void addPlatformsOptions() {
    argParser.addMultiOption('platform',
        help: 'the platforms supported by this plugin.',
        allowed: <String>[
          'ios',
          'android',
          'windows',
          'linux',
          'macos',
          'web'
        ]);
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
  void addOverwriteFlag() {
    argParser.addFlag(
      'overwrite',
      negatable: true,
      defaultsTo: false,
      help: 'When performing operations, overwrite existing files.',
    );
  }

  /// Add the `description` argument to the command.
  ///
  /// The type of the argument is [String] and it defaults to `A new Flutter project.`.
  void addDescriptionFlag() {
    argParser.addOption(
      'description',
      defaultsTo: 'A new Flutter project.',
      help: 'The description to use for your new Flutter project. This string ends up in the pubspec.yaml file.',
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
  void addIOSLanguageFlag() {
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
  void addAndroidLanguageFlag() {
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
  void addOrgFlag() {
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
  void doInitialValidation() {
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
  Future<String> getOrganization({@required Directory projectDir}) async {
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
  bool getOverwrite({@required String projectDirPath, @required String flutterRoot}) {
    final bool overwrite = boolArg('overwrite');
    final String error = _validateProjectDir(projectDirPath, flutterRoot: flutterRoot, overwrite: overwrite);
    if (error != null) {
      throwToolExit(error);
    }
    return overwrite;
  }

  /// Extract the project name.
  ///
  /// If `project-name` argument is added to the command via [addProjectNameFlag], the value of the argument is returned.
  /// Otherwise, the directory's name is returned.
  ///
  /// Throws an error if the project name is not valid.
  String getProjectName({@required String projectDirPath}) {
    String projectName;
    if (argResults['project-name'] != null) {
      projectName = stringArg('project-name');
    } else {
      projectName = globals.fs.path.basename(projectDirPath);
    }
    final String error = _validateProjectName(projectName);
    if (error != null) {
      throwToolExit(error);
    }
    return projectName;
  }

  /// Creates the templateContext based on the parameters and returns the template context map.
  ///
  /// The returned map contains a default set of key value pairs used to render templates via [Template.render].
  ///
  /// Besides the parameters, some other default values are generated into the returning map,
  /// including:
  ///   * `dartSdk`: '$flutterRoot/bin/cache/dart-sdk'.
  ///   * `useAndroidEmbeddingV2`: based on if the feature is enabled
  ///   * `androidMinApiLevel`: the minApiLevel.
  ///   * `androidSdkVersion`: the minimumAndroidSdkVersion.
  ///   * `pluginClass`: the Pascal case of `projectName` + 'Plugin', or the Pascal case of `projectName` if it ends with 'Plugin'.
  ///   * `pluginDartClass`: The Pascal case of `projectName`.
  ///   * `pluginCppHeaderGuard`: the `projectName` in upper case.
  ///   * `pluginProjectUUID`: Randomly generated UUID in upper case.
  ///   * `flutterRevision`: global flutter framework revision.
  ///   * `flutterChannel`: global flutter version.
  ///   * `ios`: false,
  ///   * `android`: false,
  ///   * `web`: featureFlags.isWebEnabled,
  ///   * `linux`: featureFlags.isLinuxEnabled,
  ///   * `macos`': featureFlags.isMacOSEnabled,
  ///   * `windows`: featureFlags.isWindowsEnabled,
  ///   * `year`: the current year.
  ///   * `androidIdentifier`: generated with [createAndroidIdentifier].
  ///   * `iosIdentifier`: generated with [createUTIIdentifier].
  ///   * `macosIdentifier`: generated with [createUTIIdentifier].
  Map<String, dynamic> createTemplateContext({
    String organization,
    String projectName,
    String projectDescription,
    String androidLanguage,
    String iosLanguage,
    String flutterRoot,
    bool withPluginHook,
    bool renderDriverTest,
  }) {

    final String pluginDartClass = _createPluginClassName(projectName);
    final String pluginClass = pluginDartClass.endsWith('Plugin')
        ? pluginDartClass
        : pluginDartClass + 'Plugin';

    return <String, dynamic>{
      'organization': organization,
      'projectName': projectName,
      'description': projectDescription,
      'dartSdk': '$flutterRoot/bin/cache/dart-sdk',
      'useAndroidEmbeddingV2': featureFlags.isAndroidEmbeddingV2Enabled,
      'androidMinApiLevel': android_common.minApiLevel,
      'androidSdkVersion': android_sdk.minimumAndroidSdkVersion,
      'withDriverTest': renderDriverTest,
      'pluginClass': pluginClass,
      'pluginDartClass': pluginDartClass,
      'pluginCppHeaderGuard': projectName.toUpperCase(),
      'pluginProjectUUID': Uuid().v4().toUpperCase(),
      'withPluginHook': withPluginHook,
      'androidLanguage': androidLanguage,
      'iosLanguage': iosLanguage,
      'flutterRevision': globals.flutterVersion.frameworkRevision,
      'flutterChannel': globals.flutterVersion.channel,
      'ios': false,
      'android': false,
      'web': featureFlags.isWebEnabled,
      'linux': featureFlags.isLinuxEnabled,
      'macos': featureFlags.isMacOSEnabled,
      'windows': featureFlags.isWindowsEnabled,
      'year': DateTime.now().year,
      'androidIdentifier': createAndroidIdentifier(organization, projectName),
      'iosIdentifier': createUTIIdentifier(organization, projectName),
      'macosIdentifier': createUTIIdentifier(organization, projectName)
    };
  }

  /// Generates an App project or update the existing App project with new `platforms`.
  ///
  /// The `directory` parameter indicates the directory where the project is in.
  /// The `templateContext` parameter is the context used to update the project.
  /// The `platforms` parameter indicates what platform sub folders should be generated.
  /// The `overwrite` parameter indicates if the existing files in the `directory` should be overwritten, defaults to false.
  ///
  /// If the `pub` flag is specified, this method also runs `flutter pub get` after generating the project files.
  ///
  /// If the `directory` is not empty or does not contain a valid Flutter App project, it throws an error unless the `overwrite` is true.
  ///
  /// Returns an [int] indicates how many files have been generated.
  ///
  /// See also:
  ///   * [createTemplateContext] to create a default template context.
  ///   * [addPlatformsOptions] to allow users to specify the platforms.
  ///   * [addOverwriteFlag] to allow users to specify the `overwrite` flag.
  Future<int> generateApp(
      Directory directory, Map<String, dynamic> templateContext, final List<String> platforms,
      {bool overwrite = false}) async {
    int generatedCount = 0;
    _updateTemplateContextWithPlatforms(templateContext, platforms);
    generatedCount += await renderTemplate('app', directory, templateContext,
        overwrite: overwrite);
    final FlutterProject project = FlutterProject.fromDirectory(directory);
    if (platforms.contains('android')) {
      generatedCount += _injectGradleWrapper(project);
    }

    if (argResults.arguments.contains('with-driver-test') && boolArg('with-driver-test')) {
      final Directory testDirectory = directory.childDirectory('test_driver');
      generatedCount += await renderTemplate(
          'driver', testDirectory, templateContext,
          overwrite: overwrite);
    }

    if (boolArg('pub')) {
      await pub.get(
          context: PubContext.create,
          directory: directory.path,
          offline: boolArg('offline'));
      await project.ensureReadyForPlatformSpecificTooling(checkProjects: false);
    }
    if (platforms.contains('android')) {
      gradle.updateLocalProperties(project: project, requireAndroidSdk: false);
    }
    return generatedCount;
  }

  /// Generates a Plugin project or update the existing Plugin project with new `platforms`.
  ///
  /// The `directory` parameter indicates the directory where the project is in.
  /// The `templateContext` parameter is the context used to update the project.
  /// The `platforms` parameter indicates what platform sub folders should be generated.
  /// The `overwrite` parameter indicates if the existing files in the `directory` should be overwritten, defaults to false.
  ///
  /// If the `pub` flag is specified, this method also runs `flutter pub get` after generating the project files.
  ///
  /// If the `directory` is not empty or does not contain a valid Flutter Plugin project, it throws an error unless the `overwrite` is true.
  ///
  /// Returns an [int] indicates how many files have been generated.
  ///
  /// See also:
  ///   * [createTemplateContext] to create a default template context.
  ///   * [addPlatformsOptions] to allow users to specify the platforms.
  ///   * [addOverwriteFlag] to allow users to specify the `overwrite` flag.
  Future<int> generatePlugin(Directory directory,
      Map<String, dynamic> templateContext, final List<String> platforms,
      {bool overwrite = false}) async {
    int generatedCount = 0;
    _updateTemplateContextWithPlatforms(templateContext, platforms);
    // Add files to the plugin.
    generatedCount += await renderTemplate('plugin', directory, templateContext,
        overwrite: overwrite);

    await _updatePubspec(directory.path, platforms, templateContext['pluginClass'] as String, templateContext['androidPluginIdentifer'] as String);

    if (boolArg('pub')) {
      await pub.get(
        context: PubContext.createPlugin,
        directory: directory.path,
        offline: boolArg('offline'),
      );
    }

    // Add files to example app.
    final FlutterProject project = FlutterProject.fromDirectory(directory);

    final bool isAndroid = platforms.contains('android');
    if (isAndroid) {
        gradle.updateLocalProperties(
            project: project, requireAndroidSdk: false);
        templateContext['androidPluginIdentifer'] =
            templateContext['androidIdentifier'] as String;
    }

    final String organization = templateContext['organization'] as String;
    final String projectName = project.manifest.appName;
    final String exampleProjectName = projectName + '_example';

    templateContext['androidIdentifier'] = createAndroidIdentifier(organization, exampleProjectName);
    templateContext['iosIdentifier'] = createUTIIdentifier(organization, exampleProjectName);
    templateContext['macosIdentifier'] = createUTIIdentifier(organization, exampleProjectName);

    templateContext['projectName'] = exampleProjectName;
    templateContext['description'] = 'Demonstrates how to use the $projectName plugin.';
    templateContext['pluginProjectName'] = projectName;
    generatedCount += await generateApp(
        project.example.directory, templateContext, platforms,
        overwrite: overwrite);

    return generatedCount;
  }

  /// Render the `context` using [Template.fromName].
  ///
  /// The `templateName` is passed down to [Template.fromName].
  ///
  /// The `directory` is the relative directory of the project directory.
  /// It is usually generated via `globals.fs.directory(projectDirPath);`.
  /// The `overwrite` is passed down to [Template.render], defaults to `false`.
  Future<int> renderTemplate(
      String templateName, Directory directory, Map<String, dynamic> context,
      {bool overwrite = false}) async {
    final Template template =
        await Template.fromName(templateName, fileSystem: globals.fs);
    return template.render(directory, context, overwriteExisting: overwrite);
  }

  /// If it has a .metadata file with the project_type in it, use that.
  /// If it has an android dir and an android/app dir, it's a legacy app
  /// If it has an ios dir and an ios/Flutter dir, it's a legacy app
  /// Otherwise, we don't presume to know what type of project it could be, since
  /// many of the files could be missing, and we can't really tell definitively.
  FlutterProjectType determineTemplateType(Directory projectDir) {
    final File metadataFile = globals.fs.file(globals.fs.path.join(projectDir.absolute.path, '.metadata'));
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, globals.logger);
    if (projectMetadata.projectType != null) {
      return projectMetadata.projectType;
    }

    bool exists(List<String> path) {
      return globals.fs.directory(globals.fs.path.joinAll(<String>[projectDir.absolute.path, ...path])).existsSync();
    }

    // There either wasn't any metadata, or it didn't contain the project type,
    // so try and figure out what type of project it is from the existing
    // directory structure.
    if (exists(<String>['android', 'app'])
        || exists(<String>['ios', 'Runner'])
        || exists(<String>['ios', 'Flutter'])) {
      return FlutterProjectType.app;
    }
    // Since we can't really be definitive on nearly-empty directories, err on
    // the side of prudence and just say we don't know.
    return null;
  }

  /// Generates the android identifier to use for android platform.
  ///
  /// The generated identifier is "`organization`.`projectName`", while removing all the disallowed symbols.
  String createAndroidIdentifier(String organization, String projectName) {
    // Android application ID is specified in: https://developer.android.com/studio/build/application-id
    // All characters must be alphanumeric or an underscore [a-zA-Z0-9_].
    String tmpIdentifier = '$organization.$projectName';
    final RegExp disallowed = RegExp(r'[^\w\.]');
    tmpIdentifier = tmpIdentifier.replaceAll(disallowed, '');

    // It must have at least two segments (one or more dots).
    final List<String> segments = tmpIdentifier
        .split('.')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    while (segments.length < 2) {
      segments.add('untitled');
    }

    // Each segment must start with a letter.
    final RegExp segmentPatternRegex = RegExp(r'^[a-zA-Z][\w]*$');
    final List<String> prefixedSegments = segments.map((String segment) {
      if (!segmentPatternRegex.hasMatch(segment)) {
        return 'u' + segment;
      }
      return segment;
    }).toList();
    return prefixedSegments.join('.');
  }

  /// Generates the UTI identifier to use for ios or macos platforms.
  ///
  /// The generated identifier is "`organization`.`projectName`", while removing all the disallowed symbols.
  String createUTIIdentifier(String organization, String projectName) {
    // Create a UTI (https://en.wikipedia.org/wiki/Uniform_Type_Identifier) from a base name
    projectName = camelCase(projectName);
    String tmpIdentifier = '$organization.$projectName';
    final RegExp disallowed = RegExp(r'[^a-zA-Z0-9\-\.\u0080-\uffff]+');
    tmpIdentifier = tmpIdentifier.replaceAll(disallowed, '');

    // It must have at least two segments (one or more dots).
    final List<String> segments = tmpIdentifier
        .split('.')
        .where((String segment) => segment.isNotEmpty)
        .toList();
    while (segments.length < 2) {
      segments.add('untitled');
    }
    return segments.join('.');
  }

  /// Run doctor; tell the user the next steps.
  Future<void> runDoctor({String application, List<String> platforms}) async {
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

  String _createPluginClassName(String name) {
    final String camelizedName = camelCase(name);
    return camelizedName[0].toUpperCase() + camelizedName.substring(1);
  }

  /// Return null if the project name is legal. Return a validation message if
  /// we should disallow the project name.
  String _validateProjectName(String projectName) {
    if (!isValidPackageName(projectName)) {
      return '"$projectName" is not a valid Dart package name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.';
    }
    if (_packageDependencies.contains(projectName)) {
      return "Invalid project name: '$projectName' - this will conflict with Flutter "
          'package dependencies.';
    }
    return null;
  }

  /// Return null if the project directory is legal. Return a validation message
  /// if we should disallow the directory name.
  String _validateProjectDir(String dirPath,
      {String flutterRoot, bool overwrite = false}) {
    if (globals.fs.path.isWithin(flutterRoot, dirPath)) {
      return 'Cannot create a project within the Flutter SDK. '
          "Target directory '$dirPath' is within the Flutter SDK at '$flutterRoot'.";
    }

    // If the destination directory is actually a file, then we refuse to
    // overwrite, on the theory that the user probably didn't expect it to exist.
    if (globals.fs.isFileSync(dirPath)) {
      final String message =
          "Invalid project name: '$dirPath' - refers to an existing file.";
      return overwrite
          ? '$message Refusing to overwrite a file with a directory.'
          : message;
    }

    if (overwrite) {
      return null;
    }

    final FileSystemEntityType type = globals.fs.typeSync(dirPath);

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

  int _injectGradleWrapper(FlutterProject project) {
    int filesCreated = 0;
    globals.fsUtils.copyDirectorySync(
      globals.cache.getArtifactDirectory('gradle_wrapper'),
      project.android.hostAppGradleRoot,
      onFileCopied: (File sourceFile, File destinationFile) {
        filesCreated++;
        final String modes = sourceFile.statSync().modeString();
        if (modes != null && modes.contains('x')) {
          globals.os.makeExecutable(destinationFile);
        }
      },
    );
    return filesCreated;
  }

  void _updateTemplateContextWithPlatforms(Map<String, dynamic> context, List<String> platforms) {
    for (final String platform in platforms) {
      switch (platform) {
        case 'ios':
          context['ios'] = true;
          break;
        case 'android':
          context['android'] = true;
          break;
        case 'web':
          context['web'] = true;
          break;
        case 'linux':
          context['linux'] = true;
          break;
        case 'macos':
          context['macos'] = true;
          break;
        case 'windows':
          context['windows'] = true;
          break;
      }
    }
  }

  Future<void> _updatePubspec(String projectDir, final List<String> platforms, String pluginClass, String androidIdentifier) async {
    final String pubspecPath = globals.fs.path.join(projectDir, 'pubspec.yaml');
    final YamlMap pubspec = loadYaml(globals.fs.file(pubspecPath).readAsStringSync()) as YamlMap;
    final bool isPubspecValid = _validatePubspec(pubspec);
    if (!isPubspecValid) {
      throwToolExit('Invalid flutter plugin `pubspec.yaml` file.',
          exitCode: 2);
    }
    try {
      // The format of the updated pubspec might not be preserved.
      final List<String> existingPlatforms = _getExistingPlatforms(pubspec);
      final List<String> platformsToAdd = List<String>.from(platforms);
      platformsToAdd.removeWhere((String platform) => existingPlatforms.contains(platform));
      if (platformsToAdd.isEmpty) {
        return;
      }
      final File pubspecFile = globals.fs.file(pubspecPath);
      final List<String> fileContents = pubspecFile.readAsLinesSync();
      int index;
      String frontSpaces;
      for (int i = 0; i < fileContents.length; i ++) {
        // Find the line of `platforms:`
        final String line = fileContents[i];
        if (line.contains('platforms:')) {
          final String lastLine = fileContents[i-1];
          if (!lastLine.contains('plugin:')) {
            continue;
          }
          // Find how many spaces are in front of the `platforms`.
          frontSpaces = line.split('platforms:').first;
          index = i + 1;
          break;
        }
      }
      for (final String platform in platformsToAdd) {
        fileContents.insert(index, frontSpaces + '  $platform:');
        index ++;
        fileContents.insert(index, frontSpaces + '    pluginClass: $pluginClass');
        index ++;
        if (platform == 'android') {
          fileContents.insert(index, frontSpaces + '    package: $androidIdentifier');
        }
      }
      final String writeString = fileContents.join('\n');
      pubspecFile.writeAsStringSync(writeString);
    } on FileSystemException catch (e) {
      throwToolExit(e.message, exitCode: 2);
    }
  }

  bool _validatePubspec(YamlMap pubspec) {
    return _getPlatformsYamlMap(pubspec) != null;
  }

  List<String> _getExistingPlatforms(YamlMap pubspec) {
    final YamlMap platformsMap = _getPlatformsYamlMap(pubspec);
    return platformsMap.keys.cast<String>().toList();
  }

  YamlMap _getPlatformsYamlMap(YamlMap pubspec) {
    if (pubspec == null) {
       return null;
    }
    final YamlMap flutterConfig = pubspec['flutter'] as YamlMap;
    if (flutterConfig == null) {
      return null;
    }
    final YamlMap pluginConfig = flutterConfig['plugin'] as YamlMap;
    if (pluginConfig == null) {
      return null;
    }
    if (pluginConfig['platforms'] == null) {
      throwToolExit('''
      The `platforms` key is not found in the pubspec.yaml.
      If your plugin still uses the old "plugin" format in the pubspec.yaml,
      please migrate to the new format with the instruction here:
      https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms
      ''', exitCode: 2);
    }

    return pluginConfig['platforms'] as YamlMap;
  }

  final Set<String> _packageDependencies = <String>{
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
    'yaml',
  };
}

// A valid Dart identifier.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-zA-Z_][a-zA-Z0-9_]*');

// non-contextual dart keywords.
//' https://dart.dev/guides/language/language-tour#keywords
final Set<String> _keywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'inout',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'native',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'out',
  'part',
  'patch',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'source',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};

/// Whether [name] is a valid Pub package.
@visibleForTesting
bool isValidPackageName(String name) {
  final Match match = _identifierRegExp.matchAsPrefix(name);
  return match != null &&
      match.end == name.length &&
      !_keywords.contains(name);
}