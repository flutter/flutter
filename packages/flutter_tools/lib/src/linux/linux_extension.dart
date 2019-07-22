// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/io.dart';
import '../cache.dart';
import '../desktop.dart';
import '../extension/app.dart';
import '../extension/build.dart';
import '../extension/device.dart';
import '../extension/doctor.dart';
import '../extension/extension.dart';
import '../protocol_discovery.dart';
import 'makefile.dart';

/// A linux tool extension.
class LinuxToolExtension extends ToolExtension {
  @override
  String get name => 'flutter-linux';

  @override
  final LinuxAppDomain appDomain = LinuxAppDomain();

  @override
  final LinuxDeviceDomain deviceDomain = LinuxDeviceDomain();

  @override
  final LinuxDoctorDomain doctorDomain = LinuxDoctorDomain();
}

/// A Linux desktop implementation of the build domain.
class LinuxBuildDomain extends BuildDomain {
  @override
  Future<BuildOutputRequest> configureOutput(BuildInfo buildInfo) async {
    return BuildOutputRequest(
      outputDirectory: fileSystem.directory(buildInfo.projectRoot)
        .childDirectory('build')
        .childDirectory('linux')
        .uri,
      ignoreCache: false,
    );
  }

  @override
  Future<ApplicationBundle> build(BuildInfo buildInfo) async {
    final String buildFlag = buildInfo.dartBuildMode == DartBuildMode.debug
      ? 'debug'
      : 'release';
    final StringBuffer buffer = StringBuffer('''
# Generated code do not commit.
export FLUTTER_ROOT=${Cache.flutterRoot}
export BUILD=$buildFlag
export FLUTTER_TARGET=${buildInfo.targetFile.toFilePath()}
export PROJECT_DIR=${buildInfo.projectRoot.toFilePath()}
''');
    fileSystem
      .directory(buildInfo.projectRoot)
      .childDirectory('linux')
      .childDirectory('fluter')
      .childFile('generated_config')
      ..createSync(recursive: true)
      ..writeAsStringSync(buffer.toString());

    final Process process = await processManager.start(<String>[
      'make',
      '-C',
      fileSystem
        .directory(buildInfo.projectRoot)
        .childDirectory('linux')
        .path,
    ], runInShell: true);
    if (await process.exitCode != 0) {
      // Notify build failure.
      throw Exception('Build failed');
    }
    final String execuable = makefileExecutableName(
      fileSystem
        .directory(buildInfo.projectRoot)
        .childDirectory('linux')
        .childFile('Makefile')
    );
    return ApplicationBundle(
      executable: execuable,
    );
  }
}

/// A linux desktop implementation of the app domain.
class LinuxAppDomain extends AppDomain {
  @override
  Future<ApplicationInstance> startApp(ApplicationBundle applicationBundle, String deviceId) async {
    final Process process = await processManager.start(<String>[
      applicationBundle.executable,
    ]);
    final DesktopLogReader logReader = DesktopLogReader()..initializeProcess(process);
    final ProtocolDiscovery observatoryDiscovery = ProtocolDiscovery.observatory(logReader);
    final Uri vmserviceUri = await observatoryDiscovery.uri;
    return ApplicationInstance(
      vmserviceUri: vmserviceUri,
      context: <String, Object>{
        'processId': process.pid,
      }
    );
  }

  @override
  Future<void> stopApp(ApplicationBundle applicationBundle) async {
    final int processId = applicationBundle.context['processId'];
    if (processId != null) {
      await processManager.run(<String>[
        'kill', processId.toString(),
      ]);
    }
  }
}

/// A Linux desktop implementation of doctor checks.
class LinuxDoctorDomain extends DoctorDomain {
  @override
  Future<ValidationResult> diagnose() async {
    return const ValidationResult(name: 'linux', messages: <ValidationMessage>[
      ValidationMessage('hello, world'),
    ]);
  }
}

/// A Linux desktop implementation of device discovery.
class LinuxDeviceDomain extends DeviceDomain {
  @override
  Future<DeviceList> listDevices() async {
    if (!platform.isLinux) {
      return const DeviceList(devices: <Device>[]);
    }
    return const DeviceList(devices: <Device>[
      Device(
        deviceCapabilities: DeviceCapabilities(
          supportsHotReload: true,
          supportsHotRestart: true,
          supportsStartPaused: true,
          supportsScreenshot: false,
        ),
        deviceId: 'linux',
        deviceName: 'linux',
        ephemeral: false,
        targetArchitecture: TargetArchitecture.x86_64,
        targetPlatform: TargetPlatform.linux,
      )
    ]);
  }
}
