// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/deferred_components_setup_validator.dart';
import 'package:flutter_tools/src/base/deferred_component.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/common.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger logger;
  Environment env;

  Environment createEnvironment() {
    final Map<String, String> defines = <String, String>{ kSplitAot: 'true' };
    final Environment result = Environment(
      outputDir: fileSystem.directory('/output'),
      buildDir: fileSystem.directory('/build'),
      projectDir: fileSystem.directory('/project'),
      defines: defines,
      inputs: <String, String>{},
      cacheDir: fileSystem.directory('/cache'),
      flutterRootDir: fileSystem.directory('/flutter_root'),
      artifacts: globals.artifacts,
      fileSystem: fileSystem,
      logger: logger,
      processManager: globals.processManager,
      engineVersion: 'invalidEngineVersion',
      generateDartPluginRegistry: false,
    );
    return result;
  }

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    env = createEnvironment();
  });

  testWithoutContext('No checks passes', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    validator.displayResults();
    validator.attemptToolExit();
    expect(logger.statusText, 'test check passed.\n');
  });

  testWithoutContext('clearTempDir passes', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText, 'test check passed.\n');
  });

  testWithoutContext('writeGolden passes', () async {
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    validator.writeGolden(
      <LoadingUnit>[
        LoadingUnit(id: 2, libraries: <String>['lib1']),
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText, 'test check passed.\n');

    final File expectedFile = env.projectDir.childFile('deferred_components_golden.yaml');

    expect(expectedFile.existsSync(), true);
    const String expectedContents =
'''
loading-units:
  - id: 2
    libraries:
      - lib1
  - id: 3
    libraries:
      - lib2
      - lib3
''';
    expect(expectedFile.readAsStringSync().contains(expectedContents), true);
  });

  testWithoutContext('loadingUnitGolden identical passes', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units:
  - id: 2
    libraries:
      - lib1
  - id: 3
    libraries:
      - lib2
      - lib3
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 2, libraries: <String>['lib1']),
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ]
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText, 'test check passed.\n');
  });

  testWithoutContext('loadingUnitGolden finds new loading units', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units:
  - id: 3
    libraries:
      - lib2
      - lib3
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 2, libraries: <String>['lib1']),
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('New loading units were found:\n\n  LoadingUnit 2\n    Libraries:\n    - lib1\n'), true);
  });

  testWithoutContext('loadingUnitGolden finds missing loading units', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units:
  - id: 2
    libraries:
      - lib1
  - id: 3
    libraries:
      - lib2
      - lib3
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Previously existing loading units no longer exist:\n\n  LoadingUnit 2\n    Libraries:\n    - lib1\n'), true);
  });

  testWithoutContext('missing golden file counts as all new loading units', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 2, libraries: <String>['lib1']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('New loading units were found:\n\n  LoadingUnit 2\n    Libraries:\n    - lib1\n'), true);
  });

  testWithoutContext('loadingUnitGolden validator detects malformed file: missing main entry', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units-spelled-wrong:
  - id: 2
    libraries:
      - lib1
  - id: 3
    libraries:
      - lib2
      - lib3
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Errors checking the following files:'), true);
    expect(logger.statusText.contains('Invalid golden yaml file, \'loading-units\' entry did not exist.'), true);

    expect(logger.statusText.contains('Previously existing loading units no longer exist:\n\n  LoadingUnit 2\n    Libraries:\n    - lib1\n'), false);
  });

  testWithoutContext('loadingUnitGolden validator detects malformed file: not a list', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units: hello
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Errors checking the following files:'), true);
    expect(logger.statusText.contains('Invalid golden yaml file, \'loading-units\' is not a list.'), true);
  });

  testWithoutContext('loadingUnitGolden validator detects malformed file: not a list', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units:
  - 2
  - 3
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Errors checking the following files:'), true);
    expect(logger.statusText.contains('Invalid golden yaml file, \'loading-units\' is not a list of maps.'), true);
  });

  testWithoutContext('loadingUnitGolden validator detects malformed file: missing id', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units:
  - id: 2
    libraries:
      - lib1
  - libraries:
      - lib2
      - lib3
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Errors checking the following files:'), true);
    expect(logger.statusText.contains('Invalid golden yaml file, all loading units must have an \'id\''), true);
  });

  testWithoutContext('loadingUnitGolden validator detects malformed file: libraries is list', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units:
  - id: 2
    libraries:
      - lib1
  - id: 3
    libraries: hello
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Errors checking the following files:'), true);
    expect(logger.statusText.contains('Invalid golden yaml file, \'libraries\' is not a list.'), true);
  });

  testWithoutContext('loadingUnitGolden validator detects malformed file: libraries is list of strings', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units:
  - id: 2
    libraries:
      - lib1
  - id: 3
    libraries:
      - blah: hello
        blah2: hello2
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Errors checking the following files:'), true);
    expect(logger.statusText.contains('Invalid golden yaml file, \'libraries\' is not a list of strings.'), true);
  });

  testWithoutContext('loadingUnitGolden validator detects malformed file: empty libraries allowed', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final File goldenFile = env.projectDir.childFile(DeferredComponentsSetupValidator.kDeferredComponentsGoldenFileName);
    if (goldenFile.existsSync()) {
      goldenFile.deleteSync();
    }
    goldenFile.createSync(recursive: true);
    goldenFile.writeAsStringSync('''
loading-units:
  - id: 2
    libraries:
      - lib1
  - id: 3
    libraries:
''', flush: true, mode: FileMode.append);
    validator.checkAgainstLoadingUnitGolden(
      <LoadingUnit>[
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Errors checking the following files:'), false);
  });

  testUsingContext('androidComponentSetup build.gradle does not exist', () async {
    final Directory templatesDir = env.flutterRootDir.childDirectory('templates').childDirectory('deferred_component');
    final File buildGradleTemplate = templatesDir.childFile('build.gradle.tmpl');
    final File androidManifestTemplate = templatesDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml.tmpl');
    if (templatesDir.existsSync()) {
      templatesDir.deleteSync(recursive: true);
    }
    buildGradleTemplate.createSync(recursive: true);
    androidManifestTemplate.createSync(recursive: true);
    buildGradleTemplate.writeAsStringSync('fake build.gradle template {{componentName}}', flush: true, mode: FileMode.append);
    androidManifestTemplate.writeAsStringSync('fake AndroidManigest.xml template {{componentName}}', flush: true, mode: FileMode.append);

    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
      templatesDir: templatesDir,
    );
    final Directory componentDir = env.projectDir.childDirectory('android').childDirectory('component1');
    final File file = componentDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    await validator.checkAndroidDynamicFeature(
      <DeferredComponent>[
        DeferredComponent(name: 'component1'),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    file.deleteSync();
    expect(logger.statusText.contains('Newly generated android files:\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/component1/build.gradle\n'), true);
  });

  testUsingContext('androidComponentSetup AndroidManifest.xml does not exist', () async {
    final Directory templatesDir = env.flutterRootDir.childDirectory('templates').childDirectory('deferred_component');
    final File buildGradleTemplate = templatesDir.childFile('build.gradle.tmpl');
    final File androidManifestTemplate = templatesDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml.tmpl');
    if (templatesDir.existsSync()) {
      templatesDir.deleteSync(recursive: true);
    }
    buildGradleTemplate.createSync(recursive: true);
    androidManifestTemplate.createSync(recursive: true);
    buildGradleTemplate.writeAsStringSync('fake build.gradle template {{componentName}}', flush: true, mode: FileMode.append);
    androidManifestTemplate.writeAsStringSync('fake AndroidManigest.xml template {{componentName}}', flush: true, mode: FileMode.append);

    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
      templatesDir: templatesDir,
    );
    final Directory componentDir = env.projectDir.childDirectory('android').childDirectory('component1');
    final File file = componentDir.childFile('build.gradle');
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    await validator.checkAndroidDynamicFeature(
      <DeferredComponent>[
        DeferredComponent(name: 'component1'),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    file.deleteSync();
    expect(logger.statusText.contains('Newly generated android files:\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/component1/src/main/AndroidManifest.xml\n'), true);
  });

  testUsingContext('androidComponentSetup all files exist passes', () async {
    final Directory templatesDir = env.flutterRootDir.childDirectory('templates').childDirectory('deferred_component');
    final File buildGradleTemplate = templatesDir.childFile('build.gradle.tmpl');
    final File androidManifestTemplate = templatesDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml.tmpl');
    if (templatesDir.existsSync()) {
      templatesDir.deleteSync(recursive: true);
    }
    buildGradleTemplate.createSync(recursive: true);
    androidManifestTemplate.createSync(recursive: true);
    buildGradleTemplate.writeAsStringSync('fake build.gradle template {{componentName}}', flush: true, mode: FileMode.append);
    androidManifestTemplate.writeAsStringSync('fake AndroidManigest.xml template {{componentName}}', flush: true, mode: FileMode.append);

    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
      templatesDir: templatesDir,
    );
    final Directory componentDir = env.projectDir.childDirectory('android').childDirectory('component1');
    final File buildGradle = componentDir.childFile('build.gradle');
    if (buildGradle.existsSync()) {
      buildGradle.deleteSync();
    }
    buildGradle.createSync(recursive: true);
    final File manifest = componentDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
    if (manifest.existsSync()) {
      manifest.deleteSync();
    }
    manifest.createSync(recursive: true);
    await validator.checkAndroidDynamicFeature(
      <DeferredComponent>[
        DeferredComponent(name: 'component1'),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    manifest.deleteSync();
    buildGradle.deleteSync();
    expect(logger.statusText, 'test check passed.\n');
  });

  testWithoutContext('androidStringMapping creates new file', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final Directory baseModuleDir = env.projectDir.childDirectory('android').childDirectory('app');
    final File stringRes = baseModuleDir.childDirectory('src').childDirectory('main').childDirectory('res').childDirectory('values').childFile('strings.xml');
    if (stringRes.existsSync()) {
      stringRes.deleteSync();
    }
    final File manifest = baseModuleDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
    if (manifest.existsSync()) {
      manifest.deleteSync();
    }
    manifest.createSync(recursive: true);
    manifest.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.splitaot">
    <application
        android:name="io.flutter.app.FlutterPlayStoreSplitApplication"
        android:label="splitaot"
        android:extractNativeLibs="false">
        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:windowSoftInputMode="adjustResize">
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
        <meta-data
            android:name="io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping"
            android:value="invalidmapping" />
    </application>
</manifest>
''', flush: true, mode: FileMode.append);
    validator.checkAppAndroidManifestComponentLoadingUnitMapping(
      <DeferredComponent>[
        DeferredComponent(name: 'component1', libraries: <String>['lib2']),
        DeferredComponent(name: 'component2', libraries: <String>['lib1', 'lib4']),
      ],
      <LoadingUnit>[
        LoadingUnit(id: 2, libraries: <String>['lib1']),
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
        LoadingUnit(id: 4, libraries: <String>['lib4', 'lib5']),
      ],
    );
    validator.checkAndroidResourcesStrings(
      <DeferredComponent>[
        DeferredComponent(name: 'component1', libraries: <String>['lib2']),
        DeferredComponent(name: 'component2', libraries: <String>['lib1', 'lib4']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Modified android files:\n'), true);
    expect(logger.statusText.contains('Newly generated android files:\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/app/src/main/AndroidManifest.xml\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/app/src/main/res/values/strings.xml\n'), true);

    final File stringsOutput = env.projectDir
      .childDirectory('build')
      .childDirectory(DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory)
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('res')
      .childDirectory('values')
      .childFile('strings.xml');
    expect(stringsOutput.existsSync(), true);
    expect(stringsOutput.readAsStringSync().contains('<string name="component1Name">component1</string>'), true);
    expect(stringsOutput.readAsStringSync().contains('<string name="component2Name">component2</string>'), true);

    final File manifestOutput = env.projectDir
      .childDirectory('build')
      .childDirectory(DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory)
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    expect(manifestOutput.existsSync(), true);
    expect(manifestOutput.readAsStringSync().contains('<meta-data android:name="io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping" android:value="3:component1,2:component2,4:component2"/>'), true);
    expect(manifestOutput.readAsStringSync().contains('android:value="invalidmapping"'), false);
    expect(manifestOutput.readAsStringSync().contains('<!-- Don\'t delete the meta-data below.'), true);
  });

  testWithoutContext('androidStringMapping modifies strings file', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final Directory baseModuleDir = env.projectDir.childDirectory('android').childDirectory('app');
    final File stringRes = baseModuleDir.childDirectory('src').childDirectory('main').childDirectory('res').childDirectory('values').childFile('strings.xml');
    if (stringRes.existsSync()) {
      stringRes.deleteSync();
    }
    stringRes.createSync(recursive: true);
    stringRes.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="component1Name">component1</string>
</resources>

''', flush: true, mode: FileMode.append);
    final File manifest = baseModuleDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
    if (manifest.existsSync()) {
      manifest.deleteSync();
    }
    manifest.createSync(recursive: true);
    manifest.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.splitaot">
    <application
        android:name="io.flutter.app.FlutterPlayStoreSplitApplication"
        android:label="splitaot"
        android:extractNativeLibs="false">
        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:windowSoftInputMode="adjustResize">
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
        <meta-data
            android:name="io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping"

            android:value="invalidmapping"

            />
    </application>
</manifest>
''', flush: true, mode: FileMode.append);
    validator.checkAppAndroidManifestComponentLoadingUnitMapping(
      <DeferredComponent>[
        DeferredComponent(name: 'component1', libraries: <String>['lib2']),
        DeferredComponent(name: 'component2', libraries: <String>['lib1', 'lib4']),
      ],
      <LoadingUnit>[
        LoadingUnit(id: 2, libraries: <String>['lib1']),
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
        LoadingUnit(id: 4, libraries: <String>['lib4', 'lib5']),
      ],
    );
    validator.checkAndroidResourcesStrings(
      <DeferredComponent>[
        DeferredComponent(name: 'component1', libraries: <String>['lib2']),
        DeferredComponent(name: 'component2', libraries: <String>['lib1', 'lib4']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Modified android files:\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/app/src/main/AndroidManifest.xml\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/app/src/main/res/values/strings.xml\n'), true);

    final File stringsOutput = env.projectDir
      .childDirectory('build')
      .childDirectory(DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory)
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('res')
      .childDirectory('values')
      .childFile('strings.xml');
    expect(stringsOutput.existsSync(), true);
    expect(stringsOutput.readAsStringSync().contains('<string name="component1Name">component1</string>'), true);
    expect(stringsOutput.readAsStringSync().contains('<string name="component2Name">component2</string>'), true);

    final File manifestOutput = env.projectDir
      .childDirectory('build')
      .childDirectory(DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory)
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    expect(manifestOutput.existsSync(), true);
    expect(manifestOutput.readAsStringSync().contains('<meta-data android:name="io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping" android:value="3:component1,2:component2,4:component2"/>'), true);
    expect(manifestOutput.readAsStringSync().contains('android:value="invalidmapping"'), false);
    expect(manifestOutput.readAsStringSync().contains('<!-- Don\'t delete the meta-data below.'), true);
  });

  testWithoutContext('androidStringMapping adds mapping when no existing mapping', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final Directory baseModuleDir = env.projectDir.childDirectory('android').childDirectory('app');
    final File stringRes = baseModuleDir.childDirectory('src').childDirectory('main').childDirectory('res').childDirectory('values').childFile('strings.xml');
    if (stringRes.existsSync()) {
      stringRes.deleteSync();
    }
    stringRes.createSync(recursive: true);
    stringRes.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="component1Name">component1</string>
</resources>

''', flush: true, mode: FileMode.append);
    final File manifest = baseModuleDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
    if (manifest.existsSync()) {
      manifest.deleteSync();
    }
    manifest.createSync(recursive: true);
    manifest.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.splitaot">
    <application
        android:name="io.flutter.app.FlutterPlayStoreSplitApplication"
        android:label="splitaot"
        android:extractNativeLibs="false">
        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:windowSoftInputMode="adjustResize">
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''', flush: true, mode: FileMode.append);
    validator.checkAppAndroidManifestComponentLoadingUnitMapping(
      <DeferredComponent>[
        DeferredComponent(name: 'component1', libraries: <String>['lib2']),
        DeferredComponent(name: 'component2', libraries: <String>['lib1', 'lib4']),
      ],
      <LoadingUnit>[
        LoadingUnit(id: 2, libraries: <String>['lib1']),
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
        LoadingUnit(id: 4, libraries: <String>['lib4', 'lib5']),
      ],
    );
    validator.checkAndroidResourcesStrings(
      <DeferredComponent>[
        DeferredComponent(name: 'component1', libraries: <String>['lib2']),
        DeferredComponent(name: 'component2', libraries: <String>['lib1', 'lib4']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Modified android files:\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/app/src/main/AndroidManifest.xml\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/app/src/main/res/values/strings.xml\n'), true);

    final File stringsOutput = env.projectDir
      .childDirectory('build')
      .childDirectory(DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory)
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('res')
      .childDirectory('values')
      .childFile('strings.xml');
    expect(stringsOutput.existsSync(), true);
    expect(stringsOutput.readAsStringSync().contains('<string name="component1Name">component1</string>'), true);
    expect(stringsOutput.readAsStringSync().contains('<string name="component2Name">component2</string>'), true);

    final File manifestOutput = env.projectDir
      .childDirectory('build')
      .childDirectory(DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory)
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    expect(manifestOutput.existsSync(), true);
    expect(manifestOutput.readAsStringSync().contains('<meta-data android:name="io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping" android:value="3:component1,2:component2,4:component2"/>'), true);
    expect(manifestOutput.readAsStringSync().contains('<!-- Don\'t delete the meta-data below.'), true);
  });

  // Tests if all of the regexp whitespace detection is working.
  testWithoutContext('androidStringMapping handles whitespace within entry', () async {
    final DeferredComponentsSetupValidator validator = DeferredComponentsSetupValidator(
      env,
      exitOnFail: false,
      title: 'test check',
    );
    final Directory baseModuleDir = env.projectDir.childDirectory('android').childDirectory('app');
    final File stringRes = baseModuleDir.childDirectory('src').childDirectory('main').childDirectory('res').childDirectory('values').childFile('strings.xml');
    if (stringRes.existsSync()) {
      stringRes.deleteSync();
    }
    stringRes.createSync(recursive: true);
    stringRes.writeAsStringSync('''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="component1Name">component1</string>
</resources>

''', flush: true, mode: FileMode.append);
    final File manifest = baseModuleDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
    if (manifest.existsSync()) {
      manifest.deleteSync();
    }
    manifest.createSync(recursive: true);
    manifest.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.splitaot">
    <application
        android:name="io.flutter.app.FlutterPlayStoreSplitApplication"
        android:label="splitaot"
        android:extractNativeLibs="false">
        <activity
            android:name=".MainActivity"
            android:launchMode="singleTop"
            android:windowSoftInputMode="adjustResize">
        </activity>
        <!-- Don't delete the meta-data below.
             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
        <meta-data

            android:name  = "io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping"

                android:value =         "invalidmapping"

            />
    </application>
</manifest>
''', flush: true, mode: FileMode.append);
    validator.checkAppAndroidManifestComponentLoadingUnitMapping(
      <DeferredComponent>[
        DeferredComponent(name: 'component1', libraries: <String>['lib2']),
        DeferredComponent(name: 'component2', libraries: <String>['lib1', 'lib4']),
      ],
      <LoadingUnit>[
        LoadingUnit(id: 2, libraries: <String>['lib1']),
        LoadingUnit(id: 3, libraries: <String>['lib2', 'lib3']),
        LoadingUnit(id: 4, libraries: <String>['lib4', 'lib5']),
      ],
    );
    validator.checkAndroidResourcesStrings(
      <DeferredComponent>[
        DeferredComponent(name: 'component1', libraries: <String>['lib2']),
        DeferredComponent(name: 'component2', libraries: <String>['lib1', 'lib4']),
      ],
    );
    validator.displayResults();
    validator.attemptToolExit();

    expect(logger.statusText.contains('Modified android files:\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/app/src/main/AndroidManifest.xml\n'), true);
    expect(logger.statusText.contains('build/${DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory}/app/src/main/res/values/strings.xml\n'), true);

    final File stringsOutput = env.projectDir
      .childDirectory('build')
      .childDirectory(DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory)
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childDirectory('res')
      .childDirectory('values')
      .childFile('strings.xml');
    expect(stringsOutput.existsSync(), true);
    expect(stringsOutput.readAsStringSync().contains('<string name="component1Name">component1</string>'), true);
    expect(stringsOutput.readAsStringSync().contains('<string name="component2Name">component2</string>'), true);

    final File manifestOutput = env.projectDir
      .childDirectory('build')
      .childDirectory(DeferredComponentsSetupValidator.kDeferredComponentsTempDirectory)
      .childDirectory('app')
      .childDirectory('src')
      .childDirectory('main')
      .childFile('AndroidManifest.xml');
    expect(manifestOutput.existsSync(), true);
    expect(manifestOutput.readAsStringSync().contains('<meta-data android:name="io.flutter.embedding.engine.deferredcomponents.DeferredComponentManager.loadingUnitMapping" android:value="3:component1,2:component2,4:component2"/>'), true);
    expect(manifestOutput.readAsStringSync().contains(RegExp(r'android:value[\s\n]*=[\s\n]*"invalidmapping"')), false);
    expect(manifestOutput.readAsStringSync().contains('<!-- Don\'t delete the meta-data below.'), true);
  });
}
