// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// For `android` directory in the repo, this script generates:
//     1. The top-level build.gradle (android/build.gradle).
//     2. The top level settings.gradle (android/settings.gradle).
//     3. The gradle wrapper file (android/gradle/wrapper/gradle-wrapper.properties).
// Then it generate the lockfiles for each Gradle project.
// To regenerate these files, run `dart dev/tools/bin/generate_gradle_lockfiles.dart`.

import 'dart:collection';
import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) {
  const String usageMessage =
      "If you don't wish to re-generate the "
      'settings.gradle, build.gradle, and gradle-wrapper.properties files,\n'
      'add the flag `--no-gradle-generation`.\n'
      'This tool automatically excludes a set of android subdirectories, '
      'defined at dev/tools/bin/config/lockfile_exclusion.yaml.\n'
      'To disable this behavior, run with `--no-exclusion`.\n';

  final ArgParser argParser = ArgParser()
    ..addFlag(
      'gradle-generation',
      help: 'Re-generate gradle files in each processed directory.',
      defaultsTo: true,
    )
    ..addFlag(
      'exclusion',
      help:
          'Run the script using the config file at ./configs/lockfile_exclusion.yaml to skip the specified subdirectories.',
      defaultsTo: true,
    );

  ArgResults args;
  try {
    args = argParser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln('${error.message}\n');
    stderr.writeln(usageMessage);
    exit(1);
  }

  print(usageMessage);

  /// Re-generate gradle files in each processed directory.
  final bool gradleGeneration = (args['gradle-generation'] as bool?) ?? true;

  // Skip android subdirectories specified in the ./config/lockfile_exclusion.yaml file.
  final bool useExclusion = (args['exclusion'] as bool?) ?? true;

  const FileSystem fileSystem = LocalFileSystem();

  final Directory repoRoot = (() {
    final String repoRootPath = exec('git', const <String>['rev-parse', '--show-toplevel']).trim();
    final Directory repoRoot = fileSystem.directory(repoRootPath);
    if (!repoRoot.existsSync()) {
      throw StateError("Expected $repoRoot to exist but it didn't!");
    }
    return repoRoot;
  })();

  final Iterable<Directory> androidDirectories = discoverAndroidDirectories(repoRoot);

  final File exclusionFile = repoRoot
      .childDirectory('dev')
      .childDirectory('tools')
      .childDirectory('bin')
      .childDirectory('config')
      .childFile('lockfile_exclusion.yaml');

  // Load the exclusion set, or make an empty exclusion set.
  final Set<String> exclusionSet;
  if (useExclusion) {
    exclusionSet = HashSet<String>.from(
      ((loadYaml(exclusionFile.readAsStringSync()) ?? YamlList()) as YamlList)
          .toList()
          .cast<String>()
          .map((String s) => '${repoRoot.path}/$s'),
    );
    print('Loaded exclusion file from ${exclusionFile.path}.');
  } else {
    exclusionSet = <String>{};
    print('Running without exclusion.');
  }

  for (final Directory androidDirectory in androidDirectories) {
    if (!androidDirectory.existsSync()) {
      throw '$androidDirectory does not exist';
    }

    if (exclusionSet.contains(androidDirectory.path)) {
      print(
        '${androidDirectory.path} is included in the exclusion config file at ${exclusionFile.path} - skipping',
      );
      continue;
    }

    late File rootBuildGradle;
    if (androidDirectory.childFile('build.gradle').existsSync()) {
      rootBuildGradle = androidDirectory.childFile('build.gradle');
    } else if (androidDirectory.childFile('build.gradle.kts').existsSync()) {
      rootBuildGradle = androidDirectory.childFile('build.gradle.kts');
    } else {
      print('${androidDirectory.childFile('build.gradle').path}(.kts) does not exist - skipping');
      continue;
    }

    late File settingsGradle;
    if (androidDirectory.childFile('settings.gradle').existsSync()) {
      settingsGradle = androidDirectory.childFile('settings.gradle');
    } else if (androidDirectory.childFile('settings.gradle.kts').existsSync()) {
      settingsGradle = androidDirectory.childFile('settings.gradle.kts');
    } else {
      print(
        '${androidDirectory.childFile('settings.gradle').path}(.kts) does not exist - skipping',
      );
      continue;
    }

    final File wrapperGradle = androidDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties');
    if (!wrapperGradle.existsSync()) {
      print('${wrapperGradle.path} does not exist - skipping');
      continue;
    }

    if (settingsGradle.readAsStringSync().contains('include_flutter.groovy')) {
      print('${settingsGradle.path} add to app - skipping');
      continue;
    }

    if (!androidDirectory.childDirectory('app').existsSync()) {
      print('${rootBuildGradle.path} is not an app - skipping');
      continue;
    }

    if (!androidDirectory.parent.childFile('pubspec.yaml').existsSync()) {
      print('${rootBuildGradle.path} no pubspec.yaml in parent directory - skipping');
      continue;
    }

    if (androidDirectory.parent
        .childFile('pubspec.yaml')
        .readAsStringSync()
        .contains('deferred-components')) {
      print('${rootBuildGradle.path} uses deferred components - skipping');
      continue;
    }

    if (!androidDirectory.parent.childDirectory('lib').childFile('main.dart').existsSync()) {
      print('${rootBuildGradle.path} no main.dart under lib - skipping');
      continue;
    }

    print('Processing ${androidDirectory.path}');

    try {
      androidDirectory.childFile('buildscript-gradle.lockfile').deleteSync();
    } on FileSystemException {
      // noop
    }

    if (gradleGeneration) {
      // Write file content corresponding to original file language.
      if (rootBuildGradle.basename.endsWith('.kts')) {
        rootBuildGradle.writeAsStringSync(rootGradleKtsFileContent);
      } else {
        rootBuildGradle.writeAsStringSync(rootGradleFileContent);
      }

      if (settingsGradle.basename.endsWith('.kts')) {
        settingsGradle.writeAsStringSync(settingsGradleKtsFileContent);
      } else {
        settingsGradle.writeAsStringSync(settingGradleFileContent);
      }

      wrapperGradle.writeAsStringSync(wrapperGradleFileContent);
    }

    final String appDirectory = androidDirectory.parent.absolute.path;

    // Fetch pub dependencies.
    final String flutterPath = repoRoot.childDirectory('bin').childFile('flutter').path;
    exec(flutterPath, <String>['pub', 'get'], workingDirectory: appDirectory);

    // Verify that the Gradlew wrapper exists.
    final File gradleWrapper = androidDirectory.childFile('gradlew');
    // Generate Gradle wrapper if it doesn't exist.
    if (!gradleWrapper.existsSync()) {
      exec(flutterPath, <String>['build', 'apk', '--config-only'], workingDirectory: appDirectory);
    }

    final Directory localEngineRepo = _getLocalEngineRepo(engineOutPath: '/Users/boetger/src/flutter/engine/src/out/android_debug_unopt_arm64', fileSystem: fileSystem);

    // Generate lock files.
    exec(gradleWrapper.absolute.path, <String>[
      ':generateLockfiles',
      '-Plocal-engine-build-mode=debug',
      '-Plocal-engine-out=/Users/boetger/src/flutter/engine/src/out/android_debug_unopt_arm64',
      '-Plocal-engine-host-out=/Users/boetger/src/flutter/engine/src/out/host_debug_unopt_arm64',
      '-Plocal-engine-repo=${localEngineRepo.path}',
    ], workingDirectory: androidDirectory.absolute.path);

    // Generate lock files.
    /*exec(gradleWrapper.absolute.path, <String>[
      ':generateLockfiles',
    ], workingDirectory: androidDirectory.absolute.path);*/

    print('Processed');
  }
}

String exec(String cmd, List<String> args, {String? workingDirectory}) {
  final ProcessResult result = Process.runSync(cmd, args, workingDirectory: workingDirectory);
  if (result.exitCode != 0) {
    throw ProcessException(cmd, args, '${result.stdout}${result.stderr}', result.exitCode);
  }
  return result.stdout as String;
}

const String rootGradleFileContent = r'''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto generated.
// To update all the build.gradle files in the Flutter repo,
// See dev/tools/bin/generate_gradle_lockfiles.dart.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir("../../build").get())

subprojects {
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir(project.name).get())
}
subprojects {
    project.evaluationDependsOn(':app')
    dependencyLocking {
        ignoredDependencies.add('io.flutter:*')
        lockFile = file("${rootProject.projectDir}/project-${project.name}.lockfile")
        if (!project.hasProperty('local-engine-repo')) {
          lockAllConfigurations()
        }
    }
}

tasks.register("clean", Delete) {
    delete rootProject.layout.buildDirectory
}
''';

const String settingGradleFileContent = r'''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto generated.
// To update all the settings.gradle files in the Flutter repo,
// See dev/tools/bin/generate_gradle_lockfiles.dart.

pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }
    settings.ext.flutterSdkPath = flutterSdkPath()

    includeBuild("${settings.ext.flutterSdkPath}/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

buildscript {
    dependencyLocking {
        lockFile = file("${rootProject.projectDir}/buildscript-gradle.lockfile")
        lockAllConfigurations()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.11.0" apply false
    id "org.jetbrains.kotlin.android" version "2.2.0" apply false
}

include ":app"
''';

// Consider updating this file to reflect the latest updates to app templates
// when performing batch updates (this file is modeled after
// root_app/android/build.gradle.kts).
// After modification verify formatting with ktlint.
const String rootGradleKtsFileContent = r'''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto generated.
// To update all the settings.gradle files in the Flutter repo,
// See dev/tools/bin/generate_gradle_lockfiles.dart.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
)

subprojects {
    project.layout.buildDirectory.value(
        rootProject.layout.buildDirectory
            .dir(project.name)
            .get()
    )
}
subprojects {
    project.evaluationDependsOn(":app")
    dependencyLocking {
        ignoredDependencies.add("io.flutter:*")
        lockFile = file("${rootProject.projectDir}/project-${project.name}.lockfile")
        if (!project.hasProperty("local-engine-repo")) {
            lockAllConfigurations()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
''';

// Consider updating this file to reflect the latest updates to app templates
// when performing batch updates (this file is modeled after
// root_app/android/settings.gradle.kts).
const String settingsGradleKtsFileContent = r'''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is auto generated.
// To update all the settings.gradle files in the Flutter repo,
// See dev/tools/bin/generate_gradle_lockfiles.dart.

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

buildscript {
    dependencyLocking {
        lockFile = file("${rootProject.projectDir}/buildscript-gradle.lockfile")
        lockAllConfigurations()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.0" apply false
}

include(":app")
''';

const String wrapperGradleFileContent = r'''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.13-all.zip
''';

Iterable<Directory> discoverAndroidDirectories(Directory repoRoot) {
  return repoRoot
      .listSync()
      .whereType<Directory>()
      // Exclude the top-level "engine/" directory, which is not covered by the the tool.
      .where((Directory directory) => directory.basename != 'engine')
      // ... and then recurse into every directory (other than the excluded directory).
      .expand((Directory directory) => directory.listSync(recursive: true))
      .whereType<Directory>()
      // These directories are build artifacts which are not part of source control.
      .where(
        (Directory directory) =>
            !directory.path.contains('/build/') && !directory.path.contains('.symlinks'),
      )
      // ... where the directory ultimately is named "android".
      .where((FileSystemEntity entity) => entity.basename == 'android');
}

/// Returns the local Maven repository for a local engine build.
/// For example, if the engine is built locally at `<home>/engine/src/out/android_debug_unopt_unopt`.
/// This method generates symlinks in the temp directory to the engine artifacts
/// following the convention specified on https://maven.apache.org/pom.html#Repositories.
Directory _getLocalEngineRepo({
  required String engineOutPath,
  required FileSystem fileSystem,
}) {
  final String abi = _getAbiByLocalEnginePath(engineOutPath);
  final Directory localEngineRepo = fileSystem.systemTempDirectory.createTempSync(
    'flutter_tool_local_engine_repo.',
  );
  const String buildMode = 'debug'; // change if needed
  final String artifactVersion = _getLocalArtifactVersion(
    fileSystem.path.join(engineOutPath, 'flutter_embedding_$buildMode.pom'),
    fileSystem,
  );
  for (final artifact in const <String>['pom', 'jar']) {
    // The Android embedding artifacts.
    _createSymlink(
      fileSystem.path.join(engineOutPath, 'flutter_embedding_$buildMode.$artifact'),
      fileSystem.path.join(
        localEngineRepo.path,
        'io',
        'flutter',
        'flutter_embedding_$buildMode',
        artifactVersion,
        'flutter_embedding_$buildMode-$artifactVersion.$artifact',
      ),
      fileSystem,
    );
    // The engine artifacts (libflutter.so).
    _createSymlink(
      fileSystem.path.join(engineOutPath, '${abi}_$buildMode.$artifact'),
      fileSystem.path.join(
        localEngineRepo.path,
        'io',
        'flutter',
        '${abi}_$buildMode',
        artifactVersion,
        '${abi}_$buildMode-$artifactVersion.$artifact',
      ),
      fileSystem,
    );
  }
  for (final artifact in <String>['flutter_embedding_$buildMode', '${abi}_$buildMode']) {
    _createSymlink(
      fileSystem.path.join(engineOutPath, '$artifact.maven-metadata.xml'),
      fileSystem.path.join(localEngineRepo.path, 'io', 'flutter', artifact, 'maven-metadata.xml'),
      fileSystem,
    );
  }
  return localEngineRepo;
}

String _getAbiByLocalEnginePath(String engineOutPath) {
  var result = 'armeabi_v7a';
  if (engineOutPath.contains('x64')) {
    result = 'x86_64';
  } else if (engineOutPath.contains('arm64')) {
    result = 'arm64_v8a';
  }
  return result;
}

void _createSymlink(String targetPath, String linkPath, FileSystem fileSystem) {
  final File targetFile = fileSystem.file(targetPath);
  if (!targetFile.existsSync()) {
    throw Error(); // oh well
  }
  final File linkFile = fileSystem.file(linkPath);
  final Link symlink = linkFile.parent.childLink(linkFile.basename);
  try {
    symlink.createSync(targetPath, recursive: true);
  } on FileSystemException catch (exception) {
    throw Error(); // oh well
  }
}

String _getLocalArtifactVersion(String pomPath, FileSystem fileSystem) {
  final File pomFile = fileSystem.file(pomPath);
  if (!pomFile.existsSync()) {
    throw Error();
  }
  XmlDocument document;
  try {
    document = XmlDocument.parse(pomFile.readAsStringSync());
  } on XmlException {
    // oh well
    throw Error();
  } on FileSystemException {
    // oh well
    throw Error();
  }
  final Iterable<XmlElement> project = document.findElements('project');
  assert(project.isNotEmpty);
  for (final XmlElement versionElement in document.findAllElements('version')) {
    if (versionElement.parent == project.first) {
      return versionElement.innerText;
    }
  }
  throw Error(); // oh well
}
