// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';

final List<String> flutterAssets = <String>[
  'assets/flutter_assets/AssetManifest.json',
  'assets/flutter_assets/NOTICES',
  'assets/flutter_assets/fonts/MaterialIcons-Regular.otf',
  'assets/flutter_assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
];

final List<String> debugAssets = <String>[
  'assets/flutter_assets/isolate_snapshot_data',
  'assets/flutter_assets/kernel_blob.bin',
  'assets/flutter_assets/vm_snapshot_data',
];

final List<String> baseApkFiles = <String> [
  'classes.dex',
  'AndroidManifest.xml',
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

/// Runs the given [testFunction] on a freshly generated Flutter module project.
Future<void> runModuleProjectTest(Future<void> testFunction(FlutterModuleProject moduleProject)) async {
  final Directory tempDir = Directory.systemTemp.createTempSync('flutter_devicelab_gradle_module_test.');
  final FlutterModuleProject moduleProject = await FlutterModuleProject.create(tempDir, 'hello_module');

  try {
    await testFunction(moduleProject);
  } finally {
    rmTree(tempDir);
  }
}

/// Returns the list of files inside an Android Package Kit.
Future<Iterable<String>> getFilesInApk(String apk) async {
  if (!File(apk).existsSync()) {
    throw TaskResult.failure(
        'Gradle did not produce an output artifact file at: $apk');
  }
  final String files = await _evalApkAnalyzer(
    <String>[
      'files',
      'list',
      apk,
    ]
  );
  return files.split('\n').map((String file) => file.substring(1).trim());
}
/// Returns the list of files inside an Android App Bundle.
Future<Iterable<String>> getFilesInAppBundle(String bundle) {
  return getFilesInApk(bundle);
}

/// Returns the list of files inside an Android Archive.
Future<Iterable<String>> getFilesInAar(String aar) {
  return getFilesInApk(aar);
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
    throw Exception('Environment variable `ANDROID_SDK_ROOT` is not set.');
  }
  return androidHome;
}

/// Executes an APK analyzer subcommand.
Future<String> _evalApkAnalyzer(
  List<String> args, {
  bool printStdout = true,
  String workingDirectory,
}) async {
  final String javaHome = await findJavaHome();
  final String javaBinary = path.join(javaHome, 'bin', 'java');
  assert(canRun(javaBinary));

  final String androidTools = path.join(_androidHome, 'tools');
  final String libs = path.join(androidTools, 'lib');
  assert(Directory(libs).existsSync());

  final String classSeparator =  Platform.isWindows ? ';' : ':';
  return eval(
    javaBinary,
    <String>[
      '-Dcom.android.sdklib.toolsdir=$androidTools',
      '-classpath',
      '.$classSeparator$libs${Platform.pathSeparator}*',
      'com.android.tools.apk.analyzer.ApkAnalyzerCli',
      ...args,
    ],
    printStdout: printStdout,
    workingDirectory: workingDirectory,
  );
}

/// Utility class to analyze the content inside an APK using the APK analyzer.
class ApkExtractor {
  ApkExtractor(this.apkFile);

  /// The APK.
  final File apkFile;

  bool _extracted = false;

  Set<String> _classes = const <String>{};

  Future<void> _extractDex() async {
    if (_extracted) {
      return;
    }
    final String packages = await _evalApkAnalyzer(
      <String>[
        'dex',
        'packages',
        apkFile.path,
      ],
    );
    _classes = Set<String>.from(
      packages
        .split('\n')
        .where((String line) => line.startsWith('C'))
        .map<String>((String line) => line.split('\t').last),
    );
    assert(_classes.isNotEmpty);
    _extracted = true;
  }

  // Removes any temporary directory.
  void dispose() {
    if (!_extracted) {
      return;
    }
    _classes = const <String>{};
    _extracted = true;
  }

  /// Returns true if the APK contains a given class.
  Future<bool> containsClass(String className) async {
    await _extractDex();
    return _classes.contains(className);
  }
}

/// Gets the content of the `AndroidManifest.xml`.
Future<String> getAndroidManifest(String apk) async {
  return await _evalApkAnalyzer(
    <String>[
      'manifest',
      'print',
      apk,
    ],
    workingDirectory: _androidHome,
  );
}

 /// Checks that the classes are contained in the APK, throws otherwise.
Future<void> checkApkContainsClasses(File apk, List<String> classes) async {
  final ApkExtractor extractor = ApkExtractor(apk);
  for (final String className in classes) {
    if (!(await extractor.containsClass(className))) {
      throw Exception("APK doesn't contain class `$className`.");
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
  String get iosPath => path.join(rootPath, 'ios');

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

  Future<void> introducePubspecError() async {
    final File pubspec = File(
      path.join(parent.path, 'hello', 'pubspec.yaml')
    );
    final String contents = pubspec.readAsStringSync();
    final String newContents = contents.replaceFirst('# The following section is specific to Flutter.\nflutter:\n', '''
flutter:
  assets:
    - lib/gallery/example_code.dart

''');
    pubspec.writeAsStringSync(newContents);
  }

  Future<void> runGradleTask(String task, {List<String> options}) async {
    return _runGradleTask(workingDirectory: androidPath, task: task, options: options);
  }

  Future<ProcessResult> resultOfGradleTask(String task, {List<String> options}) {
    return _resultOfGradleTask(workingDirectory: androidPath, task: task, options: options);
  }

  Future<ProcessResult> resultOfFlutterCommand(String command, List<String> options) {
    return Process.run(
      path.join(flutterDirectory.path, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter'),
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
      await flutter('create', options: <String>['--template=plugin', '--platforms=ios,android', name]);
    });
    return FlutterPluginProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
  String get examplePath => path.join(rootPath, 'example');
  String get exampleAndroidPath => path.join(examplePath, 'android');
  String get debugApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk');
  String get releaseApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  String get releaseArmApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'flutter-apk','app-armeabi-v7a-release.apk');
  String get releaseArm64ApkPath => path.join(examplePath, 'build', 'app', 'outputs', 'flutter-apk', 'app-arm64-v8a-release.apk');
  String get releaseBundlePath => path.join(examplePath, 'build', 'app', 'outputs', 'bundle', 'release', 'app.aab');

  Future<void> runGradleTask(String task, {List<String> options}) async {
    return _runGradleTask(workingDirectory: exampleAndroidPath, task: task, options: options);
  }
}

class FlutterModuleProject {
  FlutterModuleProject(this.parent, this.name);

  final Directory parent;
  final String name;

  static Future<FlutterModuleProject> create(Directory directory, String name) async {
    await inDirectory(directory, () async {
      await flutter('create', options: <String>['--template=module', name]);
    });
    return FlutterModuleProject(directory, name);
  }

  String get rootPath => path.join(parent.path, name);
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

/// Returns [null] if target matches [expectedTarget], otherwise returns an error message.
String validateSnapshotDependency(FlutterProject project, String expectedTarget) {
  final File snapshotBlob = File(
      path.join(project.rootPath, 'build', 'app', 'intermediates',
          'flutter', 'debug', 'flutter_build.d'));

  assert(snapshotBlob.existsSync());
  final String contentSnapshot = snapshotBlob.readAsStringSync();
  return contentSnapshot.contains('$expectedTarget ')
    ? null : 'Dependency file should have $expectedTarget as target. Instead found $contentSnapshot';
}
