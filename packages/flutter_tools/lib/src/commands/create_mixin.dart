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
import '../base/file_system.dart';
import '../base/utils.dart';
import '../cache.dart';
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