// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(jonahwilliams): refactor the extension to not depend on parts of the
// flutter tool.
import 'package:file/file.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../base/io.dart';
import '../base/version.dart' show Version;
import '../build_info.dart' show getLinuxBuildDirectory;
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
  LinuxToolExtension({
    FileSystem fileSystem,
    ProcessManager processManager,
    Platform platform,
  }) : _platform = platform,
        _processManager = processManager,
        _fileSystem = fileSystem;

  // Overrides for testing.
  final Platform _platform;
  final ProcessManager _processManager;
  final FileSystem _fileSystem;

  @override
  Platform get platform => _platform ?? super.platform;

  @override
  ProcessManager get processManager => _processManager ?? super.processManager;

  @override
  FileSystem get fileSystem => _fileSystem ?? super.fileSystem;

  @override
  String get name => 'flutter-linux';

  @override
  final LinuxAppDomain appDomain = LinuxAppDomain();

  @override
  final LinuxDeviceDomain deviceDomain = LinuxDeviceDomain();

  @override
  final LinuxDoctorDomain doctorDomain = LinuxDoctorDomain();

  @override
  final LinuxBuildDomain buildDomain = LinuxBuildDomain();
}

/// A Linux desktop implementation of the build domain.
class LinuxBuildDomain extends BuildDomain {
  @override
  Future<ApplicationBundle> buildApp(BuildInfo buildInfo) async {
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
      .childDirectory('flutter')
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
    final String binaryName = makefileExecutableName(
      fileSystem
        .directory(buildInfo.projectRoot)
        .childDirectory('linux')
        .childFile('Makefile')
    );
    String executable;
    if (buildInfo.dartBuildMode == DartBuildMode.debug) {
      executable = fileSystem.path.join(getLinuxBuildDirectory(), 'debug', binaryName);
    } else {
      executable = fileSystem.path.join(getLinuxBuildDirectory(), 'release', binaryName);
    }
    return ApplicationBundle(
      executable: executable,
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
      processManager.killPid(processId);
    }
  }
}

/// A Linux desktop implementation of doctor checks.
///
/// This validator verifies that clang is at a minimum version and that make
/// is available.
class LinuxDoctorDomain extends DoctorDomain {
  /// The minimum version of clang supported.
  final Version minimumClangVersion = Version(3, 4, 0);

  @override
  Future<ValidationResult> diagnose() async {
    ValidationType validationType = ValidationType.installed;
    final List<ValidationMessage> messages = <ValidationMessage>[];
    /// Check for a minimum version of Clang.
    ProcessResult clangResult;
    try {
      clangResult = await processManager.run(const <String>[
        'clang++',
        '--version',
      ]);
    } on ArgumentError {
      // ignore error.
    }
    if (clangResult == null || clangResult.exitCode != 0) {
      validationType = ValidationType.missing;
      messages.add(const ValidationMessage('clang++ is not installed', type: ValidationMessageType.error));
    } else {
      final String firstLine = clangResult.stdout.split('\n').first.trim();
      final String versionString = RegExp(r'[0-9]+\.[0-9]+\.[0-9]+').firstMatch(firstLine).group(0);
      final Version version = Version.parse(versionString);
      if (version >= minimumClangVersion) {
        messages.add(ValidationMessage('clang++ $version'));
      } else {
        validationType = ValidationType.partial;
        messages.add(ValidationMessage('clang++ $version is below minimum version of $minimumClangVersion', type: ValidationMessageType.error));
      }
    }

    /// Check for make.
    // TODO(jonahwilliams): tighten this check to include a version when we have
    // a better idea about what is supported.
    ProcessResult makeResult;
    try {
      makeResult = await processManager.run(const <String>[
        'make',
        '--version',
      ]);
    } on ArgumentError {
      // ignore error.
    }
    if (makeResult == null || makeResult.exitCode != 0) {
      validationType = ValidationType.missing;
      messages.add(const ValidationMessage('make is not installed', type: ValidationMessageType.error));
    } else {
      final String firstLine = makeResult.stdout.split('\n').first.trim();
      messages.add(ValidationMessage(firstLine));
    }
    return ValidationResult(
      name: 'Linux toolchain - develop for Linux desktop',
      type: validationType,
      messages: messages
    );
  }
}

/// A Linux desktop implementation of device discovery.
///
/// This device is only supported on Linux hosts.
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
        deviceName: 'Linux',
        ephemeral: false,
        targetArchitecture: TargetArchitecture.x86_64,
        targetPlatform: TargetPlatform.linux,
        sdkNameAndVersion: 'Linux',
        category: Category.desktop,
      )
    ]);
  }
}
