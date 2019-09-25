// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

final List<String> flutterAssets = <String>[
  'assets/flutter_assets/AssetManifest.json',
  'assets/flutter_assets/LICENSE',
  'assets/flutter_assets/fonts/MaterialIcons-Regular.ttf',
  'assets/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
];

/// Runs the given [testFunction] on a freshly generated Flutter project.
Future<void> runProjectTest(Future<void> testFunction(FlutterProject project)) async {
  final Directory tempDir = Directory.systemTemp.createTempSync('flutter_devicelab_gradle_plugin_test.');
  final FlutterProject project = await FlutterProject.create(tempDir, 'hello');

  try {
    await testFunction(project);
  } finally {
    rmTree(tempDir);
  }
}

/// Runs the given [testFunction] on a freshly generated Flutter plugin project.
Future<void> runPluginProjectTest(Future<void> testFunction(FlutterPluginProject pluginProject)) async {
  final Directory tempDir = Directory.systemTemp.createTempSync('flutter_devicelab_gradle_plugin_test.');
  final FlutterPluginProject pluginProject = await FlutterPluginProject.create(tempDir, 'aaa');

  try {
    await testFunction(pluginProject);
  } finally {
    rmTree(tempDir);
  }
}

/// Returns the list of files inside an Android Package Kit.
Future<Iterable<String>> getFilesInApk(String apk) async {
  if (!File(apk).existsSync())
    throw TaskResult.failure(
        'Gradle did not produce an output artifact file at: $apk');

  final Process unzip = await startProcess(
    'unzip',
    <String>['-v', apk],
    isBot: false, // we just want to test the output, not have any debugging info
  );
  return unzip.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map((String line) => line.split(' ').last)
      .toList();
}
/// Returns the list of files inside an Android App Bundle.
Future<Iterable<String>> getFilesInAppBundle(String bundle) {
  return getFilesInApk(bundle);
}

/// Returns the list of files inside an Android Archive.
Future<Iterable<String>> getFilesInAar(String aar) {
  return getFilesInApk(aar);
}

void checkItContains<T>(Iterable<T> values, Iterable<T> collection) {
  for (T value in values) {
    if (!collection.contains(value)) {
      throw TaskResult.failure('Expected to find `$value` in `$collection`.');
    }
  }
}

void checkItDoesNotContain<T>(Iterable<T> values, Iterable<T> collection) {
  for (T value in values) {
    if (collection.contains(value)) {
      throw TaskResult.failure('Did not expect to find `$value` in `$collection`.');
    }
  }
}

TaskResult failure(String message, ProcessResult result) {
  print('Unexpected process result:');
  print('Exit code: ${result.exitCode}');
  print('Std out  :\n${result.stdout}');
  print('Std err  :\n${result.stderr}');
  return TaskResult.failure(message);
}

bool hasMultipleOccurrences(String text, Pattern pattern) {
  return text.indexOf(pattern) != text.lastIndexOf(pattern);
}

/// The Android home directory.
String get _androidHome {
  final String androidHome = Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (androidHome == null || androidHome.isEmpty) {
    throw Exception('Unset env flag: `ANDROID_HOME` or `ANDROID_SDK_ROOT`.');
  }
  return androidHome;
}

/// Utility class to analyze the content inside an APK using dexdump,
/// which is provided by the Android SDK.
/// https://android.googlesource.com/platform/art/+/master/dexdump/dexdump.cc
class ApkExtractor {
  ApkExtractor(this.apkFile);

  /// The APK.
  final File apkFile;

  bool _extracted = false;

  Directory _outputDir;

  Future<void> _extractApk() async {
    if (_extracted) {
      return;
    }
    _outputDir = apkFile.parent.createTempSync('apk');
    if (Platform.isWindows) {
      await eval('7za', <String>['x', apkFile.path], workingDirectory: _outputDir.path);
    } else {
      await eval('unzip', <String>[apkFile.path], workingDirectory: _outputDir.path);
    }
    _extracted = true;
  }

  /// Returns the full path to the [dexdump] tool.
  Future<String> _findDexDump() async {
    String dexdumps;
    if (Platform.isWindows) {
      dexdumps = await eval('dir', <String>['/s/b', 'dexdump.exe'],
          workingDirectory: _androidHome);
    } else {
      dexdumps = await eval('find', <String>[_androidHome, '-name', 'dexdump']);
    }
    if (dexdumps.isEmpty) {
      throw Exception('Couldn\'t find a dexdump executable.');
    }
    return dexdumps.split('\n').first;
  }

  // Removes any temporary directory.
  void dispose() {
    if (!_extracted) {
      return;
    }
    rmTree(_outputDir);
    _extracted = true;
  }

  /// Returns true if the APK contains a given class.
  Future<bool> containsClass(String className) async {
    await _extractApk();

    final String dexDump = await _findDexDump();
    final String classesDex = path.join(_outputDir.path, 'classes.dex');

    if (!File(classesDex).existsSync()) {
      throw Exception('Couldn\'t find classes.dex in the APK.');
    }
    final String classDescriptors = await eval(dexDump,
        <String>[classesDex], printStdout: false);

    if (classDescriptors.isEmpty) {
      throw Exception('No descriptors found in classes.dex.');
    }
    return classDescriptors.contains(className.replaceAll('.', '/'));
  }
}

/// Gets the content of the `AndroidManifest.xml`.
Future<String> getAndroidManifest(String apk) {
  final String apkAnalyzer = path.join(_androidHome, 'tools', 'bin', 'apkanalyzer');
  return eval(apkAnalyzer, <String>['manifest', 'print', apk],
      workingDirectory: _androidHome);
}

 /// Checks that the classes are contained in the APK, throws otherwise.
Future<void> checkApkContainsClasses(File apk, List<String> classes) async {
  final ApkExtractor extractor = ApkExtractor(apk);
  for (String className in classes) {
    if (!(await extractor.containsClass(className))) {
      throw Exception('APK doesn\'t contain class `$className`.');
    }
  }
  extractor.dispose();
}

class FlutterProject {
  FlutterProject(this.parent, this.name);

  final Directory parent;
  final String name;

  static Future<FlutterProject> create(Directory directory, String name) async {
    await inDirectory(directory, () async {
      await flutter('create', options: <String>['--template=app', name]);
    });
    return FlutterProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get androidPath => path.join(rootPath, 'android');

  Future<void> addCustomBuildType(String name, {String initWith}) async {
    final File buildScript = File(
      path.join(androidPath, 'app', 'build.gradle'),
    );

    buildScript.openWrite(mode: FileMode.append).write('''

android {
    buildTypes {
        $name {
            initWith $initWith
        }
    }
}
    ''');
  }

  Future<void> addGlobalBuildType(String name, {String initWith}) async {
    final File buildScript = File(
      path.join(androidPath, 'build.gradle'),
    );

    buildScript.openWrite(mode: FileMode.append).write('''
subprojects {
  afterEvaluate {
    android {
        buildTypes {
            $name {
                initWith $initWith
            }
        }
    }
  }
}
    ''');
  }

  Future<void> addPlugin(String plugin) async {
    final File pubspec = File(path.join(rootPath, 'pubspec.yaml'));
    String content = await pubspec.readAsString();
    content = content.replaceFirst(
      '\ndependencies:\n',
      '\ndependencies:\n  $plugin:\n',
    );
    await pubspec.writeAsString(content, flush: true);
  }

  Future<void> getPackages() async {
    await inDirectory(Directory(rootPath), () async {
      await flutter('pub', options: <String>['get']);
    });
  }

  Future<void> addProductFlavors(Iterable<String> flavors) async {
    final File buildScript = File(
      path.join(androidPath, 'app', 'build.gradle'),
    );

    final String flavorConfig = flavors.map((String name) {
      return '''
$name {
    applicationIdSuffix ".$name"
    versionNameSuffix "-$name"
}
      ''';
    }).join('\n');

    buildScript.openWrite(mode: FileMode.append).write('''
android {
    flavorDimensions "mode"
    productFlavors {
        $flavorConfig
    }
}
    ''');
  }

  Future<void> introduceError() async {
    final File buildScript = File(
      path.join(androidPath, 'app', 'build.gradle'),
    );
    await buildScript.writeAsString((await buildScript.readAsString()).replaceAll('buildTypes', 'builTypes'));
  }

  Future<void> runGradleTask(String task, {List<String> options}) async {
    return _runGradleTask(workingDirectory: androidPath, task: task, options: options);
  }

  Future<ProcessResult> resultOfGradleTask(String task, {List<String> options}) {
    return _resultOfGradleTask(workingDirectory: androidPath, task: task, options: options);
  }

  Future<ProcessResult> resultOfFlutterCommand(String command, List<String> options) {
    return Process.run(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>[command, ...options],
      workingDirectory: rootPath,
    );
  }
}

class FlutterPluginProject {
  FlutterPluginProject(this.parent, this.name);

  final Directory parent;
  final String name;

  static Future<FlutterPluginProject> create(Directory directory, String name) async {
    await inDirectory(directory, () async {
      await flutter('create', options: <String>['--template=plugin', name]);
    });
    return FlutterPluginProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get examplePath => path.join(rootPath, 'example');
  String get exampleAndroidPath => path.join(examplePath, 'android');
  String get debugApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'debug', 'app-debug.apk');
  String get releaseApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'release', 'app-release.apk');
  String get releaseArmApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'release', 'app-armeabi-v7a-release.apk');
  String get releaseArm64ApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'apk', 'release', 'app-arm64-v8a-release.apk');
  String get releaseBundlePath => path.join(examplePath, 'build', 'app', 'outputs', 'bundle', 'release', 'app.aab');

  Future<void> runGradleTask(String task, {List<String> options}) async {
    return _runGradleTask(workingDirectory: exampleAndroidPath, task: task, options: options);
  }
}

Future<void> _runGradleTask({String workingDirectory, String task, List<String> options}) async {
  final ProcessResult result = await _resultOfGradleTask(
      workingDirectory: workingDirectory,
      task: task,
      options: options);
  if (result.exitCode != 0) {
    print('stdout:');
    print(result.stdout);
    print('stderr:');
    print(result.stderr);
  }
  if (result.exitCode != 0)
    throw 'Gradle exited with error';
}

Future<ProcessResult> _resultOfGradleTask({String workingDirectory, String task,
    List<String> options}) async {
  section('Find Java');
  final String javaHome = await findJavaHome();

  if (javaHome == null)
    throw TaskResult.failure('Could not find Java');

  print('\nUsing JAVA_HOME=$javaHome');

  final List<String> args = <String>[
    'app:$task',
    ...?options,
  ];
  final String gradle = path.join(workingDirectory, Platform.isWindows ? 'gradlew.bat' : './gradlew');
  print('┌── $gradle');
  print('│ ' + File(path.join(workingDirectory, gradle)).readAsLinesSync().join('\n│ '));
  print('└─────────────────────────────────────────────────────────────────────────────────────');
  print(
    'Running Gradle:\n'
    '  Executable: $gradle\n'
    '  Arguments: ${args.join(' ')}\n'
    '  Working directory: $workingDirectory\n'
    '  JAVA_HOME: $javaHome\n'
    ''
  );
  return Process.run(
    gradle,
    args,
    workingDirectory: workingDirectory,
    environment: <String, String>{ 'JAVA_HOME': javaHome },
  );
}

class _Dependencies {
  _Dependencies(String depfilePath) {
    final RegExp _separatorExpr = RegExp(r'([^\\]) ');
    final RegExp _escapeExpr = RegExp(r'\\(.)');

    // Depfile format:
    // outfile1 outfile2 : file1.dart file2.dart file3.dart file\ 4.dart
    final String contents = File(depfilePath).readAsStringSync();
    final List<String> colonSeparated = contents.split(': ');
    target = colonSeparated[0].trim();
    dependencies = colonSeparated[1]
        // Put every file on right-hand side on the separate line
        .replaceAllMapped(_separatorExpr, (Match match) => '${match.group(1)}\n')
        .split('\n')
        // Expand escape sequences, so that '\ ', for example,ß becomes ' '
        .map<String>((String path) => path.replaceAllMapped(_escapeExpr, (Match match) => match.group(1)).trim())
        .where((String path) => path.isNotEmpty)
        .toSet();
  }

  String target;
  Set<String> dependencies;
}

/// Returns [null] if target matches [expectedTarget], otherwise returns an error message.
String validateSnapshotDependency(FlutterProject project, String expectedTarget) {
  final _Dependencies deps = _Dependencies(
      path.join(project.rootPath, 'build', 'app', 'intermediates',
          'flutter', 'debug', 'android-arm', 'snapshot_blob.bin.d'));
  return deps.target == expectedTarget ? null :
    'Dependency file should have $expectedTarget as target. Instead has ${deps.target}';
}
