// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/dart.dart';
import 'package:flutter_tools/src/build_system/targets/ios.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../../src/common.dart';
import '../../../src/mocks.dart';
import '../../../src/testbed.dart';

void main() {
  const BuildSystem buildSystem = BuildSystem();
  Testbed testbed;
  Environment androidEnvironment;
  Environment iosEnvironment;
  MockProcessManager mockProcessManager;
  MockXcode mockXcode;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    mockXcode = MockXcode();
    mockProcessManager = MockProcessManager();
    testbed = Testbed(setup: () {
      androidEnvironment = Environment(
        outputDir: fs.currentDirectory,
        projectDir: fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: getNameForBuildMode(BuildMode.profile),
          kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        }
      );
      iosEnvironment = Environment(
        outputDir: fs.currentDirectory,
        projectDir: fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: getNameForBuildMode(BuildMode.profile),
          kTargetPlatform: getNameForTargetPlatform(TargetPlatform.ios),
        }
      );
      HostPlatform hostPlatform;
      if (platform.isWindows) {
        hostPlatform = HostPlatform.windows_x64;
      } else if (platform.isLinux) {
        hostPlatform = HostPlatform.linux_x64;
      } else if (platform.isMacOS) {
          hostPlatform = HostPlatform.darwin_x64;
      } else {
        assert(false);
      }
        final String skyEngineLine = platform.isWindows
          ? r'sky_engine:file:///C:/bin/cache/pkg/sky_engine/lib/'
          : 'sky_engine:file:///bin/cache/pkg/sky_engine/lib/';
      fs.file('.packages')
        ..createSync()
        ..writeAsStringSync('''
# Generated
$skyEngineLine
flutter_tools:lib/''');
      final String engineArtifacts = fs.path.join('bin', 'cache',
          'artifacts', 'engine');
      final List<String> paths = <String>[
        fs.path.join('bin', 'cache', 'pkg', 'sky_engine', 'lib', 'ui',
          'ui.dart'),
        fs.path.join('bin', 'cache', 'pkg', 'sky_engine', 'sdk_ext',
            'vmservice_io.dart'),
        fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
        fs.path.join(engineArtifacts, getNameForHostPlatform(hostPlatform),
            'frontend_server.dart.snapshot'),
        fs.path.join(engineArtifacts, 'android-arm-profile',
            getNameForHostPlatform(hostPlatform), 'gen_snapshot'),
        fs.path.join(engineArtifacts, 'ios-profile', 'gen_snapshot'),
        fs.path.join(engineArtifacts, 'common', 'flutter_patched_sdk',
            'platform_strong.dill'),
        fs.path.join('lib', 'foo.dart'),
        fs.path.join('lib', 'bar.dart'),
        fs.path.join('lib', 'fizz'),
        fs.path.join('packages', 'flutter_tools', 'lib', 'src', 'build_system', 'targets', 'dart.dart'),
        fs.path.join('packages', 'flutter_tools', 'lib', 'src', 'build_system', 'targets', 'ios.dart'),
      ];
      for (String path in paths) {
        fs.file(path).createSync(recursive: true);
      }
    }, overrides: <Type, Generator>{
      KernelCompilerFactory: () => FakeKernelCompilerFactory(),
      GenSnapshot: () => FakeGenSnapshot(),
    });
  });

  test('kernel_snapshot Produces correct output directory', () => testbed.run(() async {
    await buildSystem.build(const KernelSnapshot(), androidEnvironment);

    expect(fs.file(fs.path.join(androidEnvironment.buildDir.path,'app.dill')).existsSync(), true);
  }));

  test('kernel_snapshot throws error if missing build mode', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(const KernelSnapshot(),
        androidEnvironment..defines.remove(kBuildMode));

    expect(result.exceptions.values.single.exception, isInstanceOf<MissingDefineException>());
  }));

  test('kernel_snapshot does not use track widget creation on profile builds', () => testbed.run(() async {
    final MockKernelCompiler mockKernelCompiler = MockKernelCompiler();
    when(kernelCompilerFactory.create(any)).thenAnswer((Invocation _) async {
      return mockKernelCompiler;
    });
    when(mockKernelCompiler.compile(
      sdkRoot: anyNamed('sdkRoot'),
      aot: anyNamed('aot'),
      trackWidgetCreation: false,
      targetModel: anyNamed('targetModel'),
      targetProductVm: anyNamed('targetProductVm'),
      outputFilePath: anyNamed('outputFilePath'),
      depFilePath: anyNamed('depFilePath'),
      packagesPath: anyNamed('packagesPath'),
      mainPath: anyNamed('mainPath')
    )).thenAnswer((Invocation _) async {
      return const CompilerOutput('example', 0, <Uri>[]);
    });

    await const KernelSnapshot().build(androidEnvironment);
  }, overrides: <Type, Generator>{
    KernelCompilerFactory: () => MockKernelCompilerFactory(),
  }));

  test('kernel_snapshot does use track widget creation on debug builds', () => testbed.run(() async {
    final MockKernelCompiler mockKernelCompiler = MockKernelCompiler();
    when(kernelCompilerFactory.create(any)).thenAnswer((Invocation _) async {
      return mockKernelCompiler;
    });
    when(mockKernelCompiler.compile(
      sdkRoot: anyNamed('sdkRoot'),
      aot: anyNamed('aot'),
      trackWidgetCreation: true,
      targetModel: anyNamed('targetModel'),
      targetProductVm: anyNamed('targetProductVm'),
      outputFilePath: anyNamed('outputFilePath'),
      depFilePath: anyNamed('depFilePath'),
      packagesPath: anyNamed('packagesPath'),
      mainPath: anyNamed('mainPath')
    )).thenAnswer((Invocation _) async {
      return const CompilerOutput('example', 0, <Uri>[]);
    });

    await const KernelSnapshot().build(Environment(
        outputDir: fs.currentDirectory,
        projectDir: fs.currentDirectory,
        defines: <String, String>{
      kBuildMode: 'debug',
      kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
    }));
  }, overrides: <Type, Generator>{
    KernelCompilerFactory: () => MockKernelCompilerFactory(),
  }));

  test('aot_elf_profile Produces correct output directory', () => testbed.run(() async {
    await buildSystem.build(const AotElfProfile(), androidEnvironment);

    expect(fs.file(fs.path.join(androidEnvironment.buildDir.path, 'app.dill')).existsSync(), true);
    expect(fs.file(fs.path.join(androidEnvironment.buildDir.path, 'app.so')).existsSync(), true);
  }));

  test('aot_elf_profile throws error if missing build mode', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(const AotElfProfile(),
        androidEnvironment..defines.remove(kBuildMode));

    expect(result.exceptions.values.single.exception, isInstanceOf<MissingDefineException>());
  }));


  test('aot_elf_profile throws error if missing target platform', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(const AotElfProfile(),
        androidEnvironment..defines.remove(kTargetPlatform));

    expect(result.exceptions.values.single.exception, isInstanceOf<MissingDefineException>());
  }));


  test('aot_assembly_profile throws error if missing build mode', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(const AotAssemblyProfile(),
        iosEnvironment..defines.remove(kBuildMode));

    expect(result.exceptions.values.single.exception, isInstanceOf<MissingDefineException>());
  }));

  test('aot_assembly_profile throws error if missing target platform', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(const AotAssemblyProfile(),
        iosEnvironment..defines.remove(kTargetPlatform));

    expect(result.exceptions.values.single.exception, isInstanceOf<MissingDefineException>());
  }));

  test('aot_assembly_profile throws error if built for non-iOS platform', () => testbed.run(() async {
    final BuildResult result = await buildSystem
        .build(const AotAssemblyProfile(), androidEnvironment);

    expect(result.exceptions.values.single.exception, isInstanceOf<Exception>());
  }));

  test('aot_assembly_profile will lipo binaries together when multiple archs are requested', () => testbed.run(() async {
    iosEnvironment.defines[kIosArchs] ='armv7,arm64';
    when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
      fs.file(fs.path.join(iosEnvironment.buildDir.path, 'App.framework', 'App'))
          .createSync(recursive: true);
      return FakeProcessResult(
        stdout: '',
        stderr: '',
      );
    });
    final BuildResult result = await buildSystem
        .build(const AotAssemblyProfile(), iosEnvironment);
    expect(result.success, true);
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
  }));

  test('aot_assembly_profile with bitcode sends correct argument to snapshotter (one arch)', () => testbed.run(() async {
    iosEnvironment.defines[kIosArchs] = 'arm64';
    iosEnvironment.defines[kBitcodeFlag] = 'true';

    final FakeProcessResult fakeProcessResult = FakeProcessResult(
      stdout: '',
      stderr: '',
    );
    final RunResult fakeRunResult = RunResult(fakeProcessResult, const <String>['foo']);
    when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
      fs.file(fs.path.join(iosEnvironment.buildDir.path, 'App.framework', 'App'))
          .createSync(recursive: true);
      return fakeProcessResult;
    });

    when(mockXcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(fakeRunResult));
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(fakeRunResult));

    final BuildResult result = await buildSystem.build(const AotAssemblyProfile(), iosEnvironment);

    expect(result.success, true);
    verify(mockXcode.cc(argThat(contains('-fembed-bitcode')))).called(1);
    verify(mockXcode.clang(argThat(contains('-fembed-bitcode')))).called(1);
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
  }));

  test('aot_assembly_profile with bitcode sends correct argument to snapshotter (mutli arch)', () => testbed.run(() async {
    iosEnvironment.defines[kIosArchs] = 'armv7,arm64';
    iosEnvironment.defines[kBitcodeFlag] = 'true';

    final FakeProcessResult fakeProcessResult = FakeProcessResult(
      stdout: '',
      stderr: '',
    );
    final RunResult fakeRunResult = RunResult(fakeProcessResult, const <String>['foo']);
    when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
      fs.file(fs.path.join(iosEnvironment.buildDir.path, 'App.framework', 'App'))
          .createSync(recursive: true);
      return fakeProcessResult;
    });

    when(mockXcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(fakeRunResult));
    when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(fakeRunResult));

    final BuildResult result = await buildSystem.build(const AotAssemblyProfile(), iosEnvironment);

    expect(result.success, true);
    verify(mockXcode.cc(argThat(contains('-fembed-bitcode')))).called(2);
    verify(mockXcode.clang(argThat(contains('-fembed-bitcode')))).called(2);
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
    Xcode: () => mockXcode,
  }));

  test('aot_assembly_profile will lipo binaries together when multiple archs are requested', () => testbed.run(() async {
    iosEnvironment.defines[kIosArchs] = 'armv7,arm64';
    when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
      fs.file(fs.path.join(iosEnvironment.buildDir.path, 'App.framework', 'App'))
          .createSync(recursive: true);
      return FakeProcessResult(
        stdout: '',
        stderr: '',
      );
    });
    final BuildResult result = await buildSystem.build(const AotAssemblyProfile(), iosEnvironment);

    expect(result.success, true);
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
  }));

  test('list dart sources handles packages without lib directories', () => testbed.run(() {
    fs.file('.packages')
      ..createSync()
      ..writeAsStringSync('''
# Generated
example:fiz/lib/''');
    fs.directory('fiz').createSync();
    expect(listDartSources(androidEnvironment), <File>[]);
  }));
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockXcode extends Mock implements Xcode {}

class FakeGenSnapshot implements GenSnapshot {
  List<String> lastCallAdditionalArgs;
  @override
  Future<int> run({SnapshotType snapshotType, DarwinArch darwinArch, Iterable<String> additionalArgs = const <String>[]}) async {
    lastCallAdditionalArgs = additionalArgs.toList();
    final Directory out = fs.file(lastCallAdditionalArgs.last).parent;
    if (darwinArch == null) {
      out.childFile('app.so').createSync();
      out.childFile('gen_snapshot.d').createSync();
      return 0;
    }
    out.childDirectory('App.framework').childFile('App').createSync(recursive: true);

    final String assembly = lastCallAdditionalArgs
        .firstWhere((String arg) => arg.startsWith('--assembly'))
        .substring('--assembly='.length);
    fs.file(assembly).createSync();
    fs.file(assembly.replaceAll('.S', '.o')).createSync();
    return 0;
  }
}

class FakeKernelCompilerFactory implements KernelCompilerFactory {
  FakeKernelCompiler kernelCompiler = FakeKernelCompiler();

  @override
  Future<KernelCompiler> create(FlutterProject flutterProject) async {
    return kernelCompiler;
  }
}

class FakeKernelCompiler implements KernelCompiler {
  @override
  Future<CompilerOutput> compile({
    String sdkRoot,
    String mainPath,
    String outputFilePath,
    String depFilePath,
    TargetModel targetModel = TargetModel.flutter,
    bool linkPlatformKernelIn = false,
    bool aot = false,
    bool trackWidgetCreation,
    List<String> extraFrontEndOptions,
    String incrementalCompilerByteStorePath,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    bool targetProductVm = false,
    String platformDill,
    String initializeFromDill}) async {
      fs.file(outputFilePath).createSync(recursive: true);
      return CompilerOutput(outputFilePath, 0, null);
  }
}

class MockKernelCompilerFactory extends Mock implements KernelCompilerFactory {}
class MockKernelCompiler extends Mock implements KernelCompiler {}
