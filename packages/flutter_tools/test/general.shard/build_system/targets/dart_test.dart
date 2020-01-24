// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/build.dart';
import 'package:flutter_tools/src/base/file_system.dart';
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
import 'package:flutter_tools/src/globals.dart' as globals;

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
      androidEnvironment = Environment.test(
        globals.fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: getNameForBuildMode(BuildMode.profile),
          kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        },
      );
      iosEnvironment = Environment.test(
        globals.fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: getNameForBuildMode(BuildMode.profile),
          kTargetPlatform: getNameForTargetPlatform(TargetPlatform.ios),
        },
      );
      HostPlatform hostPlatform;
      if (globals.platform.isWindows) {
        hostPlatform = HostPlatform.windows_x64;
      } else if (globals.platform.isLinux) {
        hostPlatform = HostPlatform.linux_x64;
      } else if (globals.platform.isMacOS) {
        hostPlatform = HostPlatform.darwin_x64;
      } else {
        assert(false);
      }
      final String skyEngineLine = globals.platform.isWindows
        ? r'sky_engine:file:///C:/bin/cache/pkg/sky_engine/lib/'
        : 'sky_engine:file:///bin/cache/pkg/sky_engine/lib/';
      globals.fs.file('.packages')
        ..createSync()
        ..writeAsStringSync('''
# Generated
$skyEngineLine
flutter_tools:lib/''');
      final String engineArtifacts = globals.fs.path.join('bin', 'cache',
          'artifacts', 'engine');
      final List<String> paths = <String>[
        globals.fs.path.join('bin', 'cache', 'pkg', 'sky_engine', 'lib', 'ui',
          'ui.dart'),
        globals.fs.path.join('bin', 'cache', 'pkg', 'sky_engine', 'sdk_ext',
            'vmservice_io.dart'),
        globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
        globals.fs.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart.exe'),
        globals.fs.path.join(engineArtifacts, getNameForHostPlatform(hostPlatform),
            'frontend_server.dart.snapshot'),
        globals.fs.path.join(engineArtifacts, 'android-arm-profile',
            getNameForHostPlatform(hostPlatform), 'gen_snapshot'),
        globals.fs.path.join(engineArtifacts, 'ios-profile', 'gen_snapshot'),
        globals.fs.path.join(engineArtifacts, 'common', 'flutter_patched_sdk',
            'platform_strong.dill'),
        globals.fs.path.join('lib', 'foo.dart'),
        globals.fs.path.join('lib', 'bar.dart'),
        globals.fs.path.join('lib', 'fizz'),
        globals.fs.path.join('packages', 'flutter_tools', 'lib', 'src', 'build_system', 'targets', 'dart.dart'),
        globals.fs.path.join('packages', 'flutter_tools', 'lib', 'src', 'build_system', 'targets', 'ios.dart'),
      ];
      for (final String path in paths) {
        globals.fs.file(path).createSync(recursive: true);
      }
    }, overrides: <Type, Generator>{
      KernelCompilerFactory: () => FakeKernelCompilerFactory(),
      GenSnapshot: () => FakeGenSnapshot(),
    });
  });

  test('kernel_snapshot Produces correct output directory', () => testbed.run(() async {
    await buildSystem.build(const KernelSnapshot(), androidEnvironment);

    expect(globals.fs.file(globals.fs.path.join(androidEnvironment.buildDir.path,'app.dill')).existsSync(), true);
  }));

  test('kernel_snapshot throws error if missing build mode', () => testbed.run(() async {
    final BuildResult result = await buildSystem.build(const KernelSnapshot(),
        androidEnvironment..defines.remove(kBuildMode));

    expect(result.exceptions.values.single.exception, isInstanceOf<MissingDefineException>());
  }));

  test('kernel_snapshot handles null result from kernel compilation', () => testbed.run(() async {
    final FakeKernelCompilerFactory fakeKernelCompilerFactory = kernelCompilerFactory as FakeKernelCompilerFactory;
    fakeKernelCompilerFactory.kernelCompiler = MockKernelCompiler();
    when(fakeKernelCompilerFactory.kernelCompiler.compile(
      sdkRoot: anyNamed('sdkRoot'),
      mainPath: anyNamed('mainPath'),
      outputFilePath: anyNamed('outputFilePath'),
      depFilePath: anyNamed('depFilePath'),
      targetModel: anyNamed('targetModel'),
      linkPlatformKernelIn: anyNamed('linkPlatformKernelIn'),
      aot: anyNamed('aot'),
      buildMode: anyNamed('buildMode'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      extraFrontEndOptions: anyNamed('extraFrontEndOptions'),
      packagesPath: anyNamed('packagesPath'),
      fileSystemRoots: anyNamed('fileSystemRoots'),
      fileSystemScheme: anyNamed('fileSystemScheme'),
      platformDill: anyNamed('platformDill'),
      initializeFromDill: anyNamed('initializeFromDill'),
      dartDefines: anyNamed('dartDefines'),
    )).thenAnswer((Invocation invocation) async {
      return null;
    });
    final BuildResult result = await buildSystem.build(const KernelSnapshot(), androidEnvironment);

    expect(result.exceptions.values.single.exception, isInstanceOf<Exception>());
  }));

  test('kernel_snapshot does not use track widget creation on profile builds', () => testbed.run(() async {
    final MockKernelCompiler mockKernelCompiler = MockKernelCompiler();
    when(kernelCompilerFactory.create(any)).thenAnswer((Invocation _) async {
      return mockKernelCompiler;
    });
    when(mockKernelCompiler.compile(
      sdkRoot: anyNamed('sdkRoot'),
      aot: anyNamed('aot'),
      buildMode: anyNamed('buildMode'),
      trackWidgetCreation: false,
      targetModel: anyNamed('targetModel'),
      outputFilePath: anyNamed('outputFilePath'),
      depFilePath: anyNamed('depFilePath'),
      packagesPath: anyNamed('packagesPath'),
      mainPath: anyNamed('mainPath'),
      extraFrontEndOptions: anyNamed('extraFrontEndOptions'),
      fileSystemRoots: anyNamed('fileSystemRoots'),
      fileSystemScheme: anyNamed('fileSystemScheme'),
      linkPlatformKernelIn: anyNamed('linkPlatformKernelIn'),
      dartDefines: anyNamed('dartDefines'),
    )).thenAnswer((Invocation _) async {
      return const CompilerOutput('example', 0, <Uri>[]);
    });

    await const KernelSnapshot().build(androidEnvironment);
  }, overrides: <Type, Generator>{
    KernelCompilerFactory: () => MockKernelCompilerFactory(),
  }));

  test('kernel_snapshot can disable track-widget-creation on debug builds', () => testbed.run(() async {
    final MockKernelCompiler mockKernelCompiler = MockKernelCompiler();
    when(kernelCompilerFactory.create(any)).thenAnswer((Invocation _) async {
      return mockKernelCompiler;
    });
    when(mockKernelCompiler.compile(
      sdkRoot: anyNamed('sdkRoot'),
      aot: anyNamed('aot'),
      buildMode: anyNamed('buildMode'),
      trackWidgetCreation: false,
      targetModel: anyNamed('targetModel'),
      outputFilePath: anyNamed('outputFilePath'),
      depFilePath: anyNamed('depFilePath'),
      packagesPath: anyNamed('packagesPath'),
      mainPath: anyNamed('mainPath'),
      extraFrontEndOptions: anyNamed('extraFrontEndOptions'),
      fileSystemRoots: anyNamed('fileSystemRoots'),
      fileSystemScheme: anyNamed('fileSystemScheme'),
      linkPlatformKernelIn: false,
      dartDefines: anyNamed('dartDefines'),
    )).thenAnswer((Invocation _) async {
      return const CompilerOutput('example', 0, <Uri>[]);
    });

    await const KernelSnapshot().build(androidEnvironment
      ..defines[kBuildMode] = 'debug'
      ..defines[kTrackWidgetCreation] = 'false');
  }, overrides: <Type, Generator>{
    KernelCompilerFactory: () => MockKernelCompilerFactory(),
  }));

  test('kernel_snapshot forces platform linking on debug for darwin target platforms', () => testbed.run(() async {
    final MockKernelCompiler mockKernelCompiler = MockKernelCompiler();
    when(kernelCompilerFactory.create(any)).thenAnswer((Invocation _) async {
      return mockKernelCompiler;
    });
    when(mockKernelCompiler.compile(
      sdkRoot: anyNamed('sdkRoot'),
      aot: anyNamed('aot'),
      buildMode: anyNamed('buildMode'),
      trackWidgetCreation: anyNamed('trackWidgetCreation'),
      targetModel: anyNamed('targetModel'),
      outputFilePath: anyNamed('outputFilePath'),
      depFilePath: anyNamed('depFilePath'),
      packagesPath: anyNamed('packagesPath'),
      mainPath: anyNamed('mainPath'),
      extraFrontEndOptions: anyNamed('extraFrontEndOptions'),
      fileSystemRoots: anyNamed('fileSystemRoots'),
      fileSystemScheme: anyNamed('fileSystemScheme'),
      linkPlatformKernelIn: true,
      dartDefines: anyNamed('dartDefines'),
    )).thenAnswer((Invocation _) async {
      return const CompilerOutput('example', 0, <Uri>[]);
    });

    await const KernelSnapshot().build(androidEnvironment
      ..defines[kTargetPlatform]  = 'darwin-x64'
      ..defines[kBuildMode] = 'debug'
      ..defines[kTrackWidgetCreation] = 'false'
    );
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
      buildMode: anyNamed('buildMode'),
      trackWidgetCreation: true,
      targetModel: anyNamed('targetModel'),
      outputFilePath: anyNamed('outputFilePath'),
      depFilePath: anyNamed('depFilePath'),
      packagesPath: anyNamed('packagesPath'),
      mainPath: anyNamed('mainPath'),
      extraFrontEndOptions: anyNamed('extraFrontEndOptions'),
      fileSystemRoots: anyNamed('fileSystemRoots'),
      fileSystemScheme: anyNamed('fileSystemScheme'),
      linkPlatformKernelIn: false,
      dartDefines: anyNamed('dartDefines'),
    )).thenAnswer((Invocation _) async {
      return const CompilerOutput('example', 0, <Uri>[]);
    });

    await const KernelSnapshot().build(Environment.test(
      globals.fs.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
      }));
  }, overrides: <Type, Generator>{
    KernelCompilerFactory: () => MockKernelCompilerFactory(),
  }));

  test('aot_elf_profile Produces correct output directory', () => testbed.run(() async {
    await buildSystem.build(const AotElfProfile(), androidEnvironment);

    expect(globals.fs.file(globals.fs.path.join(androidEnvironment.buildDir.path, 'app.dill')).existsSync(), true);
    expect(globals.fs.file(globals.fs.path.join(androidEnvironment.buildDir.path, 'app.so')).existsSync(), true);
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
      globals.fs.file(globals.fs.path.join(iosEnvironment.buildDir.path, 'App.framework', 'App'))
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
      globals.fs.file(globals.fs.path.join(iosEnvironment.buildDir.path, 'App.framework', 'App'))
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
      globals.fs.file(globals.fs.path.join(iosEnvironment.buildDir.path, 'App.framework', 'App'))
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
      globals.fs.file(globals.fs.path.join(iosEnvironment.buildDir.path, 'App.framework', 'App'))
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

  test('kExtraGenSnapshotOptions passes values to gen_snapshot', () => testbed.run(() async {
    androidEnvironment.defines[kExtraGenSnapshotOptions] = 'foo,bar,baz=2';

    when(genSnapshot.run(
      snapshotType: anyNamed('snapshotType'),
      darwinArch: anyNamed('darwinArch'),
      additionalArgs: captureAnyNamed('additionalArgs'),
    )).thenAnswer((Invocation invocation) async {
      expect(invocation.namedArguments[#additionalArgs], containsAll(<String>[
        'foo',
        'bar',
        'baz=2',
      ]));
      return 0;
    });


    await const AotElfRelease().build(androidEnvironment);
  }, overrides: <Type, Generator>{
    GenSnapshot: () => MockGenSnapshot(),
  }));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockGenSnapshot extends Mock implements GenSnapshot {}
class MockXcode extends Mock implements Xcode {}

class FakeGenSnapshot implements GenSnapshot {
  List<String> lastCallAdditionalArgs;
  @override
  Future<int> run({SnapshotType snapshotType, DarwinArch darwinArch, Iterable<String> additionalArgs = const <String>[]}) async {
    lastCallAdditionalArgs = additionalArgs.toList();
    final Directory out = globals.fs.file(lastCallAdditionalArgs.last).parent;
    if (darwinArch == null) {
      out.childFile('app.so').createSync();
      out.childFile('gen_snapshot.d').createSync();
      return 0;
    }
    out.childDirectory('App.framework').childFile('App').createSync(recursive: true);

    final String assembly = lastCallAdditionalArgs
        .firstWhere((String arg) => arg.startsWith('--assembly'))
        .substring('--assembly='.length);
    globals.fs.file(assembly).createSync();
    globals.fs.file(assembly.replaceAll('.S', '.o')).createSync();
    return 0;
  }
}

class FakeKernelCompilerFactory implements KernelCompilerFactory {
  KernelCompiler kernelCompiler = FakeKernelCompiler();

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
    BuildMode buildMode,
    bool causalAsyncStacks = true,
    bool trackWidgetCreation,
    List<String> extraFrontEndOptions,
    String packagesPath,
    List<String> fileSystemRoots,
    String fileSystemScheme,
    String platformDill,
    String initializeFromDill,
    List<String> dartDefines,
  }) async {
    globals.fs.file(outputFilePath).createSync(recursive: true);
    return CompilerOutput(outputFilePath, 0, null);
  }
}

class MockKernelCompilerFactory extends Mock implements KernelCompilerFactory {}
class MockKernelCompiler extends Mock implements KernelCompiler {}
