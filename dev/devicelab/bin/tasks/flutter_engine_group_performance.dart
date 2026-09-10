// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart' as utils;
import 'package:flutter_devicelab/tasks/perf_tests.dart' show ListStatistics;
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

const String _bundleName = 'dev.flutter.multipleflutters';
const String _activityName = 'MainActivity';
const int _numberOfIterations = 10;

Future<void> _withApkInstall(
  String apkPath,
  String bundleName,
  Future<void> Function(AndroidDevice) body,
) async {
  final devices = DeviceDiscovery();
  final device = await devices.workingDevice as AndroidDevice;
  await device.unlock();
  await device.adb(<String>['uninstall', bundleName], canFail: true);
  await device.adb(<String>['install', '-r', apkPath]);
  try {
    await body(device);
  } finally {
    await device.adb(<String>['uninstall', bundleName]);
  }
}

/// Since we don't check the gradle wrapper in with the android host project we
/// yank the gradle wrapper from the module (which is added by the Flutter tool).
void _copyGradleFromModule(String source, String destination) {
  print('copying gradle from module $source to $destination');
  final String wrapperPath = path.join(source, '.android', 'gradlew');
  final String windowsWrapperPath = path.join(source, '.android', 'gradlew.bat');
  final String wrapperDestinationPath = path.join(destination, 'gradlew');
  final String windowsWrapperDestinationPath = path.join(destination, 'gradlew.bat');
  File(wrapperPath).copySync(wrapperDestinationPath);
  File(windowsWrapperPath).copySync(windowsWrapperDestinationPath);
  final gradleDestinationDirectory = Directory(path.join(destination, 'gradle', 'wrapper'));
  if (!gradleDestinationDirectory.existsSync()) {
    gradleDestinationDirectory.createSync(recursive: true);
  }
  final String gradleDestinationPath = path.join(
    gradleDestinationDirectory.path,
    'gradle-wrapper.jar',
  );
  final String gradlePath = path.join(
    source,
    '.android',
    'gradle',
    'wrapper',
    'gradle-wrapper.jar',
  );
  File(gradlePath).copySync(gradleDestinationPath);
}

Directory _setupLocalEngineRepo(String engineOutPath, String buildMode) {
  final pomFile = File(path.join(engineOutPath, 'flutter_embedding_$buildMode.pom'));
  if (!pomFile.existsSync()) {
    throw Exception('Could not find POM file at ${pomFile.path}');
  }
  final doc = XmlDocument.parse(pomFile.readAsStringSync());
  final Iterable<XmlElement> project = doc.findElements('project');
  String? version;
  if (project.isNotEmpty) {
    for (final XmlElement elem in project.first.findElements('version')) {
      version = elem.innerText.trim();
      break;
    }
  }
  if (version == null || version.isEmpty) {
    throw Exception('Could not extract version from ${pomFile.path}');
  }

  var abi = 'armeabi_v7a';
  if (engineOutPath.contains('x64')) {
    abi = 'x86_64';
  } else if (engineOutPath.contains('x86')) {
    abi = 'x86';
  } else if (engineOutPath.contains('arm64')) {
    abi = 'arm64_v8a';
  }

  final Directory tempRepo = Directory.systemTemp.createTempSync('devicelab_local_engine_repo.');
  try {
    final artifacts = <String>['flutter_embedding_$buildMode', '${abi}_$buildMode'];
    for (final artifact in artifacts) {
      final targetDir = Directory(path.join(tempRepo.path, 'io', 'flutter', artifact, version));
      targetDir.createSync(recursive: true);
      for (final ext in const <String>['pom', 'jar']) {
        final src = File(path.join(engineOutPath, '$artifact.$ext'));
        if (src.existsSync()) {
          final dst = File(path.join(targetDir.path, '$artifact-$version.$ext'));
          if (Platform.isWindows) {
            src.copySync(dst.path);
          } else {
            Link(dst.path).createSync(src.path);
          }
        }
      }
      final metaSrc = File(path.join(engineOutPath, '$artifact.maven-metadata.xml'));
      if (metaSrc.existsSync()) {
        final metaDst = File(
          path.join(tempRepo.path, 'io', 'flutter', artifact, 'maven-metadata.xml'),
        );
        if (Platform.isWindows) {
          metaSrc.copySync(metaDst.path);
        } else {
          Link(metaDst.path).createSync(metaSrc.path);
        }
      }
    }
    return tempRepo;
  } catch (_) {
    if (tempRepo.existsSync()) {
      tempRepo.deleteSync(recursive: true);
    }
    rethrow;
  }
}

Future<TaskResult> _doTest() async {
  try {
    final String flutterDirectory = utils.flutterDirectory.path;
    final String multipleFluttersPath = path.join(
      flutterDirectory,
      'dev',
      'benchmarks',
      'multiple_flutters',
    );
    final String modulePath = path.join(multipleFluttersPath, 'module');
    final String androidPath = path.join(multipleFluttersPath, 'android');

    final gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
    final gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';
    await utils.flutter('precache', options: <String>['--android'], workingDirectory: modulePath);
    await utils.flutter('pub', options: <String>['get'], workingDirectory: modulePath);
    _copyGradleFromModule(modulePath, androidPath);

    final String? javaHome = await utils.findJavaHome();
    final String? envJavaHome = Platform.environment['JAVA_HOME'];
    final String? effectiveJavaHome = (envJavaHome != null && Directory(envJavaHome).existsSync())
        ? path.canonicalize(envJavaHome)
        : (javaHome != null ? path.canonicalize(javaHome) : null);

    Directory? localEngineRepoDir;
    final gradleArgs = <String>['assembleRelease'];
    final String? localEngine = utils.localEngineFromEnv;
    final String? localEngineHost = utils.localEngineHostFromEnv;
    final String? localEngineSrcPath = utils.localEngineSrcPathFromEnv;

    if (localEngine != null && localEngineSrcPath != null) {
      final String candidate = localEngine
          .replaceFirst('debug_unopt', 'release')
          .replaceFirst('debug', 'release')
          .replaceFirst('profile', 'release');
      final String engineOutPath = path.join(localEngineSrcPath, 'out', candidate);
      if (!Directory(engineOutPath).existsSync()) {
        throw Exception(
          'Local engine was specified ($localEngine), but required release engine out directory '
          'was not found at $engineOutPath. Please build $candidate before running this benchmark.',
        );
      }
      localEngineRepoDir = _setupLocalEngineRepo(engineOutPath, 'release');

      String? effectiveHostOut;
      if (localEngineHost != null) {
        final String candidateHost = path.join(localEngineSrcPath, 'out', localEngineHost);
        if (Directory(candidateHost).existsSync()) {
          effectiveHostOut = candidateHost;
        }
      }
      if (effectiveHostOut == null) {
        const hostCandidates = <String>[
          'host_release',
          'host_release_arm64',
          'host_profile',
          'host_profile_arm64',
          'host_debug_unopt_arm64',
          'host_debug_unopt',
          'host_debug',
        ];
        for (final hostCandidate in hostCandidates) {
          final String hostPath = path.join(localEngineSrcPath, 'out', hostCandidate);
          if (Directory(hostPath).existsSync()) {
            effectiveHostOut = hostPath;
            break;
          }
        }
      }
      if (effectiveHostOut == null) {
        throw Exception(
          'Could not resolve local engine host out directory in ${path.join(localEngineSrcPath, 'out')}. '
          'Ensure a host engine build exists or specify --local-engine-host.',
        );
      }

      var targetPlatform = 'android-arm';
      if (candidate.contains('x64')) {
        targetPlatform = 'android-x64';
      } else if (candidate.contains('x86')) {
        targetPlatform = 'android-x86';
      } else if (candidate.contains('arm64')) {
        targetPlatform = 'android-arm64';
      }

      gradleArgs.addAll(<String>[
        '-Plocal-engine-repo=${localEngineRepoDir.path}',
        '-Plocal-engine-out=$engineOutPath',
        '-Plocal-engine-host-out=$effectiveHostOut',
        '-Plocal-engine-build-mode=release',
        '-Ptarget-platform=$targetPlatform',
      ]);
    }

    try {
      await utils.eval(
        gradlewExecutable,
        gradleArgs,
        workingDirectory: androidPath,
        environment: <String, String>{
          if (effectiveJavaHome != null) 'JAVA_HOME': effectiveJavaHome,
        },
      );
      final String apkPath = path.join(
        multipleFluttersPath,
        'android',
        'app',
        'build',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      );

      TaskResult? result;
      await _withApkInstall(apkPath, _bundleName, (AndroidDevice device) async {
        final totalMemorySamples = <int>[];
        for (var i = 0; i < _numberOfIterations; ++i) {
          await device.adb(<String>[
            'shell',
            'am',
            'start',
            '-n',
            '$_bundleName/$_bundleName.$_activityName',
          ]);
          await Future<void>.delayed(const Duration(seconds: 10));
          final Map<String, dynamic> memoryStats = await device.getMemoryStats(_bundleName);
          final totalMemory = memoryStats['total_kb'] as int;
          totalMemorySamples.add(totalMemory);
          await device.stop(_bundleName);
        }
        final totalMemoryStatistics = ListStatistics(totalMemorySamples);

        final results = <String, dynamic>{...totalMemoryStatistics.asMap('totalMemory')};
        result = TaskResult.success(results, benchmarkScoreKeys: results.keys.toList());
      });

      return result ?? TaskResult.failure('no results found');
    } finally {
      if (localEngineRepoDir != null && localEngineRepoDir.existsSync()) {
        localEngineRepoDir.deleteSync(recursive: true);
      }
    }
  } catch (ex, stackTrace) {
    print('Task exception stack trace:\n$stackTrace');
    return TaskResult.failure(ex.toString());
  }
}

Future<void> main() async {
  await task(_doTest);
}
