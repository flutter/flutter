// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../android/setup_split_aot.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/depfile.dart';
import '../build_system/targets/android.dart';
import '../build_system/targets/assets.dart';
import '../build_system/targets/common.dart';
import '../build_system/targets/ios.dart';
import '../build_system/targets/linux.dart';
import '../build_system/targets/macos.dart';
import '../build_system/targets/web.dart';
import '../build_system/targets/windows.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';

/// All currently implemented targets.
const List<Target> _kDefaultTargets = <Target>[
  // Shared targets
  CopyAssets(),
  KernelSnapshot(),
  AotElfProfile(TargetPlatform.android_arm),
  AotElfRelease(TargetPlatform.android_arm),
  AotAssemblyProfile(),
  AotAssemblyRelease(),
  // macOS targets
  DebugMacOSFramework(),
  DebugMacOSBundleFlutterAssets(),
  ProfileMacOSBundleFlutterAssets(),
  ReleaseMacOSBundleFlutterAssets(),
  // Linux targets
  DebugBundleLinuxAssets(),
  ProfileBundleLinuxAssets(),
  ReleaseBundleLinuxAssets(),
  // Web targets
  WebServiceWorker(),
  ReleaseAndroidApplication(),
  // This is a one-off rule for bundle and aot compat.
  CopyFlutterBundle(),
  // Android targets,
  DebugAndroidApplication(),
  FastStartAndroidApplication(),
  ProfileAndroidApplication(),
  // Android ABI specific AOT rules.
  androidArmProfileBundle,
  androidArm64ProfileBundle,
  androidx64ProfileBundle,
  androidArmReleaseBundle,
  androidArm64ReleaseBundle,
  androidx64ReleaseBundle,
  // iOS targets
  DebugIosApplicationBundle(),
  ProfileIosApplicationBundle(),
  ReleaseIosApplicationBundle(),
  // Windows targets
  UnpackWindows(),
  DebugBundleWindowsAssets(),
  ProfileBundleWindowsAssets(),
  ReleaseBundleWindowsAssets(),
];

/// Assemble provides a low level API to interact with the flutter tool build
/// system.
class AssembleCommand extends FlutterCommand {
  AssembleCommand() {
    argParser.addMultiOption(
      'define',
      abbr: 'd',
      help: 'Allows passing configuration to a target with --define=target=key=value.',
    );
    argParser.addOption(
      'performance-measurement-file',
      help: 'Output individual target performance to a JSON file.'
    );
    argParser.addMultiOption(
      'input',
      abbr: 'i',
      help: 'Allows passing additional inputs with --input=key=value. Unlike '
      'defines, additional inputs do not generate a new configuration, instead '
      'they are treated as dependencies of the targets that use them.'
    );
    argParser.addOption('depfile', help: 'A file path where a depfile will be written. '
      'This contains all build inputs and outputs in a make style syntax'
    );
    argParser.addOption('build-inputs', help: 'A file path where a newline '
        'separated file containing all inputs used will be written after a build.'
        ' This file is not included as a build input or output. This file is not'
        ' written if the build fails for any reason.');
    argParser.addOption('build-outputs', help: 'A file path where a newline '
        'separated file containing all outputs used will be written after a build.'
        ' This file is not included as a build input or output. This file is not'
        ' written if the build fails for any reason.');
    argParser.addOption('output', abbr: 'o', help: 'A directory where output '
        'files will be written. Must be either absolute or relative from the '
        'root of the current Flutter project.',
    );
    argParser.addOption(kExtraGenSnapshotOptions);
    argParser.addOption(kExtraFrontEndOptions);
    argParser.addOption(kDartDefines);
    argParser.addOption(kSplitAot);
    argParser.addOption(kSetupSplitAot);
    argParser.addOption(
      'resource-pool-size',
      help: 'The maximum number of concurrent tasks the build system will run.',
    );
  }

  @override
  String get description => 'Assemble and build flutter resources.';

  @override
  String get name => 'assemble';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final FlutterProject futterProject = FlutterProject.current();
    if (futterProject == null) {
      return const <CustomDimensions, String>{};
    }
    try {
      final Environment localEnvironment = createEnvironment();
      return <CustomDimensions, String>{
        CustomDimensions.commandBuildBundleTargetPlatform: localEnvironment.defines['TargetPlatform'],
        CustomDimensions.commandBuildBundleIsModule: '${futterProject.isModule}',
      };
    } on Exception {
      // We've failed to send usage.
    }
    return const <CustomDimensions, String>{};
  }

  /// The target(s) we are building.
  List<Target> createTargets() {
    if (argResults.rest.isEmpty) {
      throwToolExit('missing target name for flutter assemble.');
    }
    final String name = argResults.rest.first;
    final Map<String, Target> targetMap = <String, Target>{
      for (final Target target in _kDefaultTargets)
        target.name: target
    };
    final List<Target> results = <Target>[
      for (final String targetName in argResults.rest)
        if (targetMap.containsKey(targetName))
          targetMap[targetName]
    ];
    if (results.isEmpty) {
      throwToolExit('No target named "$name" defined.');
    }
    print('assemble args.rest: ${argResults.rest}');
    print(results);
    return results;
  }

  /// The environmental configuration for a build invocation.
  Environment createEnvironment() {
    final FlutterProject flutterProject = FlutterProject.current();
    String output = stringArg('output');
    if (output == null) {
      throwToolExit('--output directory is required for assemble.');
    }
    // If path is relative, make it absolute from flutter project.
    if (globals.fs.path.isRelative(output)) {
      output = globals.fs.path.join(flutterProject.directory.path, output);
    }
    final Environment result = Environment(
      outputDir: globals.fs.directory(output),
      buildDir: flutterProject.directory
          .childDirectory('.dart_tool')
          .childDirectory('flutter_build'),
      projectDir: flutterProject.directory,
      defines: _parseDefines(stringsArg('define')),
      inputs: _parseDefines(stringsArg('input')),
      cacheDir: globals.cache.getRoot(),
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
      artifacts: globals.artifacts,
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      engineVersion: globals.artifacts.isLocalEngine
        ? null
        : globals.flutterVersion.engineRevision
    );
    return result;
  }

  Map<String, String> _parseDefines(List<String> values) {
    final Map<String, String> results = <String, String>{};
    for (final String chunk in values) {
      final int indexEquals = chunk.indexOf('=');
      if (indexEquals == -1) {
        throwToolExit('Improperly formatted define flag: $chunk');
      }
      final String key = chunk.substring(0, indexEquals);
      final String value = chunk.substring(indexEquals + 1);
      results[key] = value;
    }
    // Workaround for extraGenSnapshot formatting.
    if (argResults.wasParsed(kExtraGenSnapshotOptions)) {
      results[kExtraGenSnapshotOptions] = argResults[kExtraGenSnapshotOptions] as String;
    }
    results[kSplitAot] = 'false';
    if (argResults.wasParsed(kSplitAot)) {
      if (argResults[kSplitAot] == 'true') {
        results[kSplitAot] = 'true';
      }
    }
    results[kSetupSplitAot] = 'false';
    if (argResults.wasParsed(kSetupSplitAot)) {
      if (argResults[kSetupSplitAot] == 'true') {
        results[kSetupSplitAot] = 'true';
      }
    }
    if (argResults.wasParsed(kDartDefines)) {
      results[kDartDefines] = argResults[kDartDefines] as String;
    }
    if (argResults.wasParsed(kExtraFrontEndOptions)) {
      results[kExtraFrontEndOptions] = argResults[kExtraFrontEndOptions] as String;
    }
    return results;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<Target> targets = createTargets();
    final Target target = targets.length == 1 ? targets.single : _CompositeTarget(targets);
    Environment env = createEnvironment();
    final BuildResult result = await globals.buildSystem.build(
      target,
      env,
      buildSystemConfig: BuildSystemConfig(
        resourcePoolSize: argResults.wasParsed('resource-pool-size')
          ? int.tryParse(stringArg('resource-pool-size'))
          : null,
        ),
      );
    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        if (measurement.fatal || globals.logger.isVerbose) {
          globals.printError('Target ${measurement.target} failed: ${measurement.exception}',
            stackTrace: measurement.stackTrace
          );
        }
      }
      throwToolExit('');
    }
    globals.printTrace('build succeeded.');
    if (argResults.wasParsed('build-inputs')) {
      writeListIfChanged(result.inputFiles, stringArg('build-inputs'));
    }
    if (argResults.wasParsed('build-outputs')) {
      writeListIfChanged(result.outputFiles, stringArg('build-outputs'));
    }
    if (argResults.wasParsed('performance-measurement-file')) {
      final File outFile = globals.fs.file(argResults['performance-measurement-file']);
      writePerformanceData(result.performance.values, outFile);
    }
    if (argResults.wasParsed('depfile')) {
      final File depfileFile = globals.fs.file(stringArg('depfile'));
      final Depfile depfile = Depfile(result.inputFiles, result.outputFiles);
      final DepfileService depfileService = DepfileService(
        fileSystem: globals.fs,
        logger: globals.logger,
      );
      depfileService.writeToFile(depfile, globals.fs.file(depfileFile));
    }
    if (argResults.wasParsed(kSetupSplitAot)) {
      if (argResults[kSetupSplitAot] == 'true') {
        setupBundleGradle(env, result);
      }
    }
    return FlutterCommandResult.success();
  }

//   void setupBundleGradle(Environment env, String moduleName, BuildResult result) {
//     print('setup Bundle Gradle');
//     // outputDir: globals.fs.directory(output),
//     // buildDir: flutterProject.directory
//     //     .childDirectory('.dart_tool')
//     //     .childDirectory('flutter_build'),
//     // projectDir: flutterProject.directory,
//     // defines: _parseDefines(stringsArg('define')),
//     // inputs: _parseDefines(stringsArg('input')),
//     // cacheDir: globals.cache.getRoot(),
//     // flutterRootDir: globals.fs.directory(Cache.flutterRoot),
//     // artifacts: globals.artifacts,
//     // fileSystem: globals.fs,
//     // logger: globals.logger,
//     // processManager: globals.processManager,
//     // engineVersion: globals.artifacts.isLocalEngine
//     Directory androidDir = env.projectDir.childDirectory('android');
//     Directory moduleDir = androidDir.childDirectory(moduleName);

//     createDir(moduleDir);
//     setupFiles(moduleDir, androidDir, moduleName, false, result, env);
//   }

//   void createDir(Directory moduleDir) {
//     print('createDir');
//     // Directory moduleDir = Directory(path.join(modulePath));
//     if (moduleDir.existsSync()) {
//       moduleDir.deleteSync(recursive: true);
//     }
//   }

//   void setupFiles(Directory moduleDir, Directory androidDir, String moduleName, bool isBase, BuildResult result, Environment env) {
//     print('setupFiles');
//     // File(path.join(rootDir, moduleSoPath)).copySync(path.join(modulePath, 'lib', 'libflutter.so'));

//     File stringRes = androidDir.childDirectory('app').childDirectory('src').childDirectory('main').childDirectory('res').childDirectory('values').childFile('strings.xml');
//     stringRes.createSync(recursive: true);
//     stringRes.writeAsStringSync(
// '''
// <?xml version="1.0" encoding="utf-8"?>
// <resources>
//     <string name="moduleName">$moduleName</string>
// </resources>

// ''', flush: true);

//     File androidManifest = moduleDir.childDirectory('src').childDirectory('main').childFile('AndroidManifest.xml');
//     androidManifest.createSync(recursive: true);
// //    sink.write(
// // '''
// // <manifest xmlns:dist="http://schemas.android.com/apk/distribution"
// //     package="com.example.$moduleName"
// //     split="$moduleName"
// //     android:isFeatureSplit="${isBase ? false : true}">

// //     <dist:module dist:instant="false"
// //         dist:title="@string/$moduleName"
// //         <dist:fusing dist:include="true" />
// //     </dist:module>
// //     <dist:delivery>
// //         <dist:install-time>
// //             <dist:removable value="false" />
// //         </dist:install-time>
// //         <dist:on-demand/>
// //     </dist:delivery>
// //     <application android:hasCode="${isBase ? 'true' : 'false'}"${isBase ? ' tools:replace="android:hasCode"' : ''}>
// //     </application>
// // </manifest>
// // ''');
//     androidManifest.writeAsStringSync(
// '''
// <manifest xmlns:android="http://schemas.android.com/apk/res/android"
//     xmlns:dist="http://schemas.android.com/apk/distribution"
//     package="com.example.$moduleName">

//     <dist:$moduleName
//         dist:instant="false"
//         dist:title="@string/moduleName">
//         <dist:delivery>
//             <dist:on-demand />
//         </dist:delivery>
//         <dist:fusing dist:include="true" />
//     </dist:$moduleName>
// </manifest>
// ''', flush: true);

//     File settingsGradle = androidDir.childFile('settings.gradle');
//     File settingsGradleTemp = androidDir.childFile('settings.gradle.temp');
//     List<String> lines = settingsGradle.readAsLinesSync();
//     for (String line in lines) {
//       if (line.length >= 7 && line.substring(0, 7) == 'include') {
//         List<String> elements = line.substring(7).split(', ');
//         bool moduleFound = false;
//         for (int i = 1; i < elements.length; i++) {
//           if (elements[i] == '\':$moduleName\'') {
//             moduleFound = true;
//             break;
//           }
//         }
//         if (!moduleFound) {
//           line += ', \':$moduleName\'';
//         }
//       }
//       settingsGradleTemp.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
//     }
//     settingsGradleTemp.copySync(settingsGradle.path);
//     settingsGradleTemp.deleteSync();

//     File moduleBuildGradle = moduleDir.childFile('build.gradle');
//     moduleBuildGradle.createSync(recursive: true);
//     moduleBuildGradle.writeAsStringSync(
// '''
// apply plugin: "com.android.dynamic-feature"

// android {
//     compileSdkVersion 28

//     defaultConfig {
//         minSdkVersion 16
//         targetSdkVersion 28
//         versionCode 1
//         versionName "1.0"

//         testInstrumentationRunner "android.support.test.runner.AndroidJUnitRunner"
//     }
//     compileOptions {
//         sourceCompatibility 1.8
//         targetCompatibility 1.8
//     }
// }

// dependencies {
//     implementation fileTree(dir: "libs", include: ["*.jar"])
//     implementation project(":app")
//     testImplementation 'junit:junit:4.12'
//     androidTestImplementation 'com.android.support.test:runner:1.0.2'
//     androidTestImplementation 'com.android.support.test.espresso:espresso-core:3.0.2'
//     androidTestImplementation 'com.android.support:support-annotations:28.0.0'
// }

// ''', flush: true);

//     Directory jniLibsDir = moduleDir.childDirectory('src').childDirectory('main').childDirectory('jniLibs');
//     jniLibsDir.createSync(recursive: true);
//     List<FileSystemEntity> files = env.outputDir.listSync(recursive: true);
//     while (files.length != 0) {
//       FileSystemEntity file = files.last;
//       if (file is File) {
//         String subPath = file.path;
//         if (!subPath.contains('part.so')) {
//           files.removeLast();
//           continue;
//         }
//         subPath = subPath.substring(subPath.lastIndexOf('release/') + 8);
//         print(jniLibsDir.childFile(subPath).path);
//         jniLibsDir.childFile(subPath).createSync(recursive: true);
//         (file as File).copySync(jniLibsDir.childFile(subPath).path);
//       }
//       print(file.path);
//       files.removeLast();
//     }

//   }
}


@visibleForTesting
void writeListIfChanged(List<File> files, String path) {
  final File file = globals.fs.file(path);
  final StringBuffer buffer = StringBuffer();
  // These files are already sorted.
  for (final File file in files) {
    buffer.writeln(file.path);
  }
  final String newContents = buffer.toString();
  if (!file.existsSync()) {
    file.writeAsStringSync(newContents);
  }
  final String currentContents = file.readAsStringSync();
  if (currentContents != newContents) {
    file.writeAsStringSync(newContents);
  }
}

/// Output performance measurement data in [outFile].
@visibleForTesting
void writePerformanceData(Iterable<PerformanceMeasurement> measurements, File outFile) {
  final Map<String, Object> jsonData = <String, Object>{
    'targets': <Object>[
      for (final PerformanceMeasurement measurement in measurements)
        <String, Object>{
          'name': measurement.analyicsName,
          'skipped': measurement.skipped,
          'succeeded': measurement.succeeded,
          'elapsedMilliseconds': measurement.elapsedMilliseconds,
        }
    ]
  };
  if (!outFile.parent.existsSync()) {
    outFile.parent.createSync(recursive: true);
  }
  outFile.writeAsStringSync(json.encode(jsonData));
}

class _CompositeTarget extends Target {
  _CompositeTarget(this.dependencies);

  @override
  final List<Target> dependencies;

  @override
  String get name => '_composite';

  @override
  Future<void> build(Environment environment) async { }

  @override
  List<Source> get inputs => <Source>[];

  @override
  List<Source> get outputs => <Source>[];
}
