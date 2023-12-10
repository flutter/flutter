// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/fuchsia/application_package.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_device.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_ffx.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_kernel_compiler.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_pm.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_sdk.dart';
import 'package:flutter_tools/src/fuchsia/pkgctl.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {
  group('Fuchsia app start and stop: ', () {
    late MemoryFileSystem memoryFileSystem;
    late FakeOperatingSystemUtils osUtils;
    late FakeFuchsiaDeviceTools fuchsiaDeviceTools;
    late FakeFuchsiaSdk fuchsiaSdk;
    late Artifacts artifacts;
    late FakeProcessManager fakeSuccessfulProcessManager;
    late FakeProcessManager fakeFailedProcessManagerForHostAddress;
    late File sshConfig;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      osUtils = FakeOperatingSystemUtils();
      fuchsiaDeviceTools = FakeFuchsiaDeviceTools();
      fuchsiaSdk = FakeFuchsiaSdk();
      sshConfig = MemoryFileSystem.test().file('ssh_config')
        ..writeAsStringSync('\n');
      artifacts = Artifacts.test();
      for (final BuildMode mode in <BuildMode>[
        BuildMode.debug,
        BuildMode.release
      ]) {
        memoryFileSystem
            .file(
              artifacts.getArtifactPath(Artifact.fuchsiaKernelCompiler,
                  platform: TargetPlatform.fuchsia_arm64, mode: mode),
            )
            .createSync();

        memoryFileSystem
            .file(
              artifacts.getArtifactPath(Artifact.platformKernelDill,
                  platform: TargetPlatform.fuchsia_arm64, mode: mode),
            )
            .createSync();

        memoryFileSystem
            .file(
              artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath,
                  platform: TargetPlatform.fuchsia_arm64, mode: mode),
            )
            .createSync();

        memoryFileSystem
            .file(
              artifacts.getArtifactPath(Artifact.fuchsiaFlutterRunner,
                  platform: TargetPlatform.fuchsia_arm64, mode: mode),
            )
            .createSync();
      }
      fakeSuccessfulProcessManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'ssh',
            '-F',
            sshConfig.absolute.path,
            '123',
            r'echo $SSH_CONNECTION'
          ],
          stdout:
              'fe80::8c6c:2fff:fe3d:c5e1%ethp0003 50666 fe80::5054:ff:fe63:5e7a%ethp0003 22',
        ),
      ]);
      fakeFailedProcessManagerForHostAddress =
          FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'ssh',
            '-F',
            sshConfig.absolute.path,
            '123',
            r'echo $SSH_CONNECTION'
          ],
          stdout:
              'fe80::8c6c:2fff:fe3d:c5e1%ethp0003 50666 fe80::5054:ff:fe63:5e7a%ethp0003 22',
          exitCode: 1,
        ),
      ]);
    });

    Future<LaunchResult> setupAndStartApp({
      required bool prebuilt,
      required BuildMode mode,
    }) async {
      const String appName = 'app_name';
      final FuchsiaDevice device = FuchsiaDeviceWithFakeDiscovery('123');
      globals.fs.directory('fuchsia').createSync(recursive: true);
      final File pubspecFile = globals.fs.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');

      FuchsiaApp? app;
      if (prebuilt) {
        final File far = globals.fs.file('app_name-0.far')..createSync();
        app = FuchsiaApp.fromPrebuiltApp(far);
      } else {
        globals.fs.file(globals.fs.path.join('fuchsia', 'meta', '$appName.cm'))
          ..createSync(recursive: true)
          ..writeAsStringSync('{}');
        globals.fs.file('.packages').createSync();
        globals.fs
            .file(globals.fs.path.join('lib', 'main.dart'))
            .createSync(recursive: true);
        app = BuildableFuchsiaApp(
            project:
                FlutterProject.fromDirectoryTest(globals.fs.currentDirectory)
                    .fuchsia);
      }

      final DebuggingOptions debuggingOptions = DebuggingOptions.disabled(
          BuildInfo(mode, null, treeShakeIcons: false));
      return device.startApp(
        app!,
        prebuiltApplication: prebuilt,
        debuggingOptions: debuggingOptions,
      );
    }

    testUsingContext(
        'start prebuilt in release mode fails without session',
        () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isFalse);
      expect(launchResult.hasVmService, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('start prebuilt in release mode with session', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isTrue);
      expect(launchResult.hasVmService, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(ffx: FakeFuchsiaFfxWithSession()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext(
        'start and stop prebuilt in release mode fails without session',
        () async {
      const String appName = 'app_name';
      final FuchsiaDevice device = FuchsiaDeviceWithFakeDiscovery('123');
      globals.fs.directory('fuchsia').createSync(recursive: true);
      final File pubspecFile = globals.fs.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');
      final File far = globals.fs.file('app_name-0.far')..createSync();

      final FuchsiaApp app = FuchsiaApp.fromPrebuiltApp(far);
      final DebuggingOptions debuggingOptions = DebuggingOptions.disabled(
          const BuildInfo(BuildMode.release, null, treeShakeIcons: false));
      final LaunchResult launchResult = await device.startApp(app,
          prebuiltApplication: true, debuggingOptions: debuggingOptions);
      expect(launchResult.started, isFalse);
      expect(launchResult.hasVmService, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('start and stop prebuilt in release mode with session',
        () async {
      const String appName = 'app_name';
      final FuchsiaDevice device = FuchsiaDeviceWithFakeDiscovery('123');
      globals.fs.directory('fuchsia').createSync(recursive: true);
      final File pubspecFile = globals.fs.file('pubspec.yaml')..createSync();
      pubspecFile.writeAsStringSync('name: $appName');
      final File far = globals.fs.file('app_name-0.far')..createSync();

      final FuchsiaApp app = FuchsiaApp.fromPrebuiltApp(far);
      final DebuggingOptions debuggingOptions = DebuggingOptions.disabled(
          const BuildInfo(BuildMode.release, null, treeShakeIcons: false));
      final LaunchResult launchResult = await device.startApp(app,
          prebuiltApplication: true, debuggingOptions: debuggingOptions);
      expect(launchResult.started, isTrue);
      expect(launchResult.hasVmService, isFalse);
      expect(await device.stopApp(app), isTrue);
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(ffx: FakeFuchsiaFfxWithSession()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext(
        'start prebuilt in debug mode fails without session',
        () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.debug);
      expect(launchResult.started, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('start prebuilt in debug mode with session', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.debug);
      expect(launchResult.started, isTrue);
      expect(launchResult.hasVmService, isTrue);
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(ffx: FakeFuchsiaFfxWithSession()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext(
        'start buildable in release mode fails without session',
        () async {
      expect(
          () async => setupAndStartApp(prebuilt: false, mode: BuildMode.release),
          throwsToolExit(
              message: 'This tool does not currently build apps for fuchsia.\n'
                  'Build the app using a supported Fuchsia workflow.\n'
                  'Then use the --use-application-binary flag.'));
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(
              command: <String>[
                'Artifact.genSnapshot.TargetPlatform.fuchsia_arm64.release',
                '--deterministic',
                '--snapshot_kind=app-aot-elf',
                '--elf=build/fuchsia/elf.aotsnapshot',
                'build/fuchsia/app_name.dil',
              ],
            ),
            FakeCommand(
              command: <String>[
                'ssh',
                '-F',
                sshConfig.absolute.path,
                '123',
                r'echo $SSH_CONNECTION'
              ],
              stdout:
                  'fe80::8c6c:2fff:fe3d:c5e1%ethp0003 50666 fe80::5054:ff:fe63:5e7a%ethp0003 22',
            ),
          ]),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext(
        'start buildable in release mode with session fails, does not build apps yet',
        () async {
      expect(
          () async => setupAndStartApp(prebuilt: false, mode: BuildMode.release),
          throwsToolExit(
              message: 'This tool does not currently build apps for fuchsia.\n'
                  'Build the app using a supported Fuchsia workflow.\n'
                  'Then use the --use-application-binary flag.'));
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
            const FakeCommand(
              command: <String>[
                'Artifact.genSnapshot.TargetPlatform.fuchsia_arm64.release',
                '--deterministic',
                '--snapshot_kind=app-aot-elf',
                '--elf=build/fuchsia/elf.aotsnapshot',
                'build/fuchsia/app_name.dil',
              ],
            ),
            FakeCommand(
              command: <String>[
                'ssh',
                '-F',
                sshConfig.absolute.path,
                '123',
                r'echo $SSH_CONNECTION'
              ],
              stdout:
                  'fe80::8c6c:2fff:fe3d:c5e1%ethp0003 50666 fe80::5054:ff:fe63:5e7a%ethp0003 22',
            ),
          ]),
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(ffx: FakeFuchsiaFfxWithSession()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext(
        'start buildable in debug mode fails without session',
        () async {
      expect(
          () async => setupAndStartApp(prebuilt: false, mode: BuildMode.debug),
          throwsToolExit(
              message: 'This tool does not currently build apps for fuchsia.\n'
                  'Build the app using a supported Fuchsia workflow.\n'
                  'Then use the --use-application-binary flag.'));
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext(
        'start buildable in debug mode with session fails, does not build apps yet',
        () async {
      expect(
          () async => setupAndStartApp(prebuilt: false, mode: BuildMode.debug),
          throwsToolExit(
              message: 'This tool does not currently build apps for fuchsia.\n'
                  'Build the app using a supported Fuchsia workflow.\n'
                  'Then use the --use-application-binary flag.'));
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(ffx: FakeFuchsiaFfxWithSession()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('fail when cant get ssh config', () async {
      expect(
          () async => setupAndStartApp(prebuilt: true, mode: BuildMode.release),
          throwsToolExit(
              message: 'Cannot interact with device. No ssh config.\n'
                  'Try setting FUCHSIA_SSH_CONFIG or FUCHSIA_BUILD_DIR.'));
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      FuchsiaArtifacts: () => FuchsiaArtifacts(),
      FuchsiaSdk: () => FakeFuchsiaSdk(ffx: FakeFuchsiaFfxWithSession()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('fail when cant get host address', () async {
      expect(() async => FuchsiaDeviceWithFakeDiscovery('123').hostAddress,
          throwsToolExit(message: 'Failed to get local address, aborting.'));
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeFailedProcessManagerForHostAddress,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      OperatingSystemUtils: () => osUtils,
      Platform: () => FakePlatform(),
    });

    testUsingContext('fail with correct LaunchResult when pm fails', () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isFalse);
      expect(launchResult.hasVmService, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => fuchsiaDeviceTools,
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => FakeFuchsiaSdk(pm: FailingPM()),
      OperatingSystemUtils: () => osUtils,
    });

    testUsingContext('fail with correct LaunchResult when pkgctl fails',
        () async {
      final LaunchResult launchResult =
          await setupAndStartApp(prebuilt: true, mode: BuildMode.release);
      expect(launchResult.started, isFalse);
      expect(launchResult.hasVmService, isFalse);
    }, overrides: <Type, Generator>{
      Artifacts: () => artifacts,
      FileSystem: () => memoryFileSystem,
      ProcessManager: () => fakeSuccessfulProcessManager,
      FuchsiaDeviceTools: () => FakeFuchsiaDeviceTools(pkgctl: FailingPkgctl()),
      FuchsiaArtifacts: () => FuchsiaArtifacts(sshConfig: sshConfig),
      FuchsiaSdk: () => fuchsiaSdk,
      OperatingSystemUtils: () => osUtils,
    });
  });
}

Process _createFakeProcess({
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
  bool persistent = false,
}) {
  final Stream<List<int>> stdoutStream =
      Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode(stdout),
  ]);
  final Stream<List<int>> stderrStream =
      Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode(stderr),
  ]);
  final Completer<int> exitCodeCompleter = Completer<int>();
  final Process process = FakeProcess(
    stdout: stdoutStream,
    stderr: stderrStream,
    exitCode:
        persistent ? exitCodeCompleter.future : Future<int>.value(exitCode),
  );
  return process;
}

class FuchsiaDeviceWithFakeDiscovery extends FuchsiaDevice {
  FuchsiaDeviceWithFakeDiscovery(super.id, {super.name = ''});

  @override
  FuchsiaIsolateDiscoveryProtocol getIsolateDiscoveryProtocol(
      String isolateName) {
    return FakeFuchsiaIsolateDiscoveryProtocol();
  }

  @override
  Future<TargetPlatform> get targetPlatform async =>
      TargetPlatform.fuchsia_arm64;
}

class FakeFuchsiaIsolateDiscoveryProtocol
    implements FuchsiaIsolateDiscoveryProtocol {
  @override
  FutureOr<Uri> get uri => Uri.parse('http://[::1]:37');

  @override
  void dispose() {}
}

class FakeFuchsiaPkgctl implements FuchsiaPkgctl {
  @override
  Future<bool> addRepo(
      FuchsiaDevice device, FuchsiaPackageServer server) async {
    return true;
  }

  @override
  Future<bool> resolve(
      FuchsiaDevice device, String serverName, String packageName) async {
    return true;
  }

  @override
  Future<bool> rmRepo(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return true;
  }
}

class FailingPkgctl implements FuchsiaPkgctl {
  @override
  Future<bool> addRepo(
      FuchsiaDevice device, FuchsiaPackageServer server) async {
    return false;
  }

  @override
  Future<bool> resolve(
      FuchsiaDevice device, String serverName, String packageName) async {
    return false;
  }

  @override
  Future<bool> rmRepo(FuchsiaDevice device, FuchsiaPackageServer server) async {
    return false;
  }
}

class FakeFuchsiaDeviceTools implements FuchsiaDeviceTools {
  FakeFuchsiaDeviceTools({
    FuchsiaPkgctl? pkgctl,
    FuchsiaFfx? ffx,
  })  : pkgctl = pkgctl ?? FakeFuchsiaPkgctl(),
        ffx = ffx ?? FakeFuchsiaFfx();

  @override
  final FuchsiaPkgctl pkgctl;

  @override
  final FuchsiaFfx ffx;
}

class FakeFuchsiaPM implements FuchsiaPM {
  String? _appName;

  @override
  Future<bool> init(String buildPath, String appName) async {
    if (!globals.fs.directory(buildPath).existsSync()) {
      return false;
    }
    globals.fs
        .file(globals.fs.path.join(buildPath, 'meta', 'package'))
        .createSync(recursive: true);
    _appName = appName;
    return true;
  }

  @override
  Future<bool> build(String buildPath, String manifestPath) async {
    if (!globals.fs
            .file(globals.fs.path.join(buildPath, 'meta', 'package'))
            .existsSync() ||
        !globals.fs.file(manifestPath).existsSync()) {
      return false;
    }
    globals.fs
        .file(globals.fs.path.join(buildPath, 'meta.far'))
        .createSync(recursive: true);
    return true;
  }

  @override
  Future<bool> archive(String buildPath, String manifestPath) async {
    if (!globals.fs
            .file(globals.fs.path.join(buildPath, 'meta', 'package'))
            .existsSync() ||
        !globals.fs.file(manifestPath).existsSync()) {
      return false;
    }
    if (_appName == null) {
      return false;
    }
    globals.fs
        .file(globals.fs.path.join(buildPath, '$_appName-0.far'))
        .createSync(recursive: true);
    return true;
  }

  @override
  Future<bool> newrepo(String repoPath) async {
    if (!globals.fs.directory(repoPath).existsSync()) {
      return false;
    }
    return true;
  }

  @override
  Future<Process> serve(String repoPath, String host, int port) async {
    return _createFakeProcess(persistent: true);
  }

  @override
  Future<bool> publish(String repoPath, String packagePath) async {
    if (!globals.fs.directory(repoPath).existsSync()) {
      return false;
    }
    if (!globals.fs.file(packagePath).existsSync()) {
      return false;
    }
    return true;
  }
}

class FailingPM implements FuchsiaPM {
  @override
  Future<bool> init(String buildPath, String appName) async {
    return false;
  }

  @override
  Future<bool> build(String buildPath, String manifestPath) async {
    return false;
  }

  @override
  Future<bool> archive(String buildPath, String manifestPath) async {
    return false;
  }

  @override
  Future<bool> newrepo(String repoPath) async {
    return false;
  }

  @override
  Future<Process> serve(String repoPath, String host, int port) async {
    return _createFakeProcess(exitCode: 6);
  }

  @override
  Future<bool> publish(String repoPath, String packagePath) async {
    return false;
  }
}

class FakeFuchsiaKernelCompiler implements FuchsiaKernelCompiler {
  @override
  Future<void> build({
    required FuchsiaProject fuchsiaProject,
    required String target, // E.g., lib/main.dart
    BuildInfo buildInfo = BuildInfo.debug,
  }) async {
    final String outDir = getFuchsiaBuildDirectory();
    final String appName = fuchsiaProject.project.manifest.appName;
    final String manifestPath =
        globals.fs.path.join(outDir, '$appName.dilpmanifest');
    globals.fs.file(manifestPath).createSync(recursive: true);
  }
}

class FakeFuchsiaFfx implements FuchsiaFfx {
  @override
  Future<List<String>> list({Duration? timeout}) async {
    return <String>['192.168.42.172 scare-cable-skip-ffx'];
  }

  @override
  Future<String> resolve(String deviceName) async {
    return '192.168.42.10';
  }

  @override
  Future<String?> sessionShow() async {
    return null;
  }

  @override
  Future<bool> sessionAdd(String url) async {
    return false;
  }
}

class FakeFuchsiaFfxWithSession implements FuchsiaFfx {
  @override
  Future<List<String>> list({Duration? timeout}) async {
    return <String>['192.168.42.172 scare-cable-skip-ffx'];
  }

  @override
  Future<String> resolve(String deviceName) async {
    return '192.168.42.10';
  }

  @override
  Future<String> sessionShow() async {
    return 'session info';
  }

  @override
  Future<bool> sessionAdd(String url) async {
    return true;
  }
}

class FakeFuchsiaSdk extends Fake implements FuchsiaSdk {
  FakeFuchsiaSdk({
    FuchsiaPM? pm,
    FuchsiaKernelCompiler? compiler,
    FuchsiaFfx? ffx,
  })  : fuchsiaPM = pm ?? FakeFuchsiaPM(),
        fuchsiaKernelCompiler = compiler ?? FakeFuchsiaKernelCompiler(),
        fuchsiaFfx = ffx ?? FakeFuchsiaFfx();

  @override
  final FuchsiaPM fuchsiaPM;

  @override
  final FuchsiaKernelCompiler fuchsiaKernelCompiler;

  @override
  final FuchsiaFfx fuchsiaFfx;
}
