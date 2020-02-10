// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
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
import '../../../src/fake_process_manager.dart';
import '../../../src/mocks.dart';
import '../../../src/testbed.dart';

const String kBoundaryKey = '4d2d9609-c662-4571-afde-31410f96caa6';

void main() {
  const BuildSystem buildSystem = BuildSystem();
  Testbed testbed;
  FakeProcessManager processManager;
  Environment androidEnvironment;
  Environment iosEnvironment;
  MockProcessManager mockProcessManager;
  // MockXcode mockXcode;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    // mockXcode = MockXcode();
    mockProcessManager = MockProcessManager();
    testbed = Testbed(setup: () {
      androidEnvironment = Environment.test(
        globals.fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: getNameForBuildMode(BuildMode.profile),
          kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
        },
      );
      androidEnvironment.buildDir.createSync(recursive: true);
      iosEnvironment = Environment.test(
        globals.fs.currentDirectory,
        defines: <String, String>{
          kBuildMode: getNameForBuildMode(BuildMode.profile),
          kTargetPlatform: getNameForTargetPlatform(TargetPlatform.ios),
        },
      );
      iosEnvironment.buildDir.createSync(recursive: true);
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

      final String engineArtifacts = globals.fs.path.join('bin', 'cache',
          'artifacts', 'engine');
      final List<String> paths = <String>[
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
      //KernelCompilerFactory: () => FakeKernelCompilerFactory(),
      ProcessManager: () => processManager,
    });
  });

  test('kernel_snapshot Produces correct output directory', () => testbed.run(() async {
    await const KernelSnapshot().build(androidEnvironment);

    expect(globals.fs.file(globals.fs.path.join(androidEnvironment.buildDir.path,'app.dill')), exists);
  }));

  test('kernel_snapshot throws error if missing build mode', () => testbed.run(() async {
    androidEnvironment.defines.remove(kBuildMode);
    expect(
      const KernelSnapshot().build(androidEnvironment),
      throwsA(isInstanceOf<MissingDefineException>()));
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

    expect(result.exceptions.values.single.exception, isA<Exception>());
  }));

  test('KernelSnapshot does not use track widget creation on profile builds', () => testbed.run(() async {
    globals.fs.file('.packages').writeAsStringSync('\n');
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'bin/cache/dart-sdk/bin/dart',
        'bin/cache/artifacts/engine/darwin-x64/frontend_server.dart.snapshot',
        '--sdk-root',
        'bin/cache/artifacts/engine/common/flutter_patched_sdk/',
        '--target=flutter',
        '-Ddart.developer.causal_async_stacks=false',
        '-Ddart.vm.profile=true',
        '-Ddart.vm.product=false',
        '--bytecode-options=source-positions',
        '--aot',
        '--tfa',
        '--packages',
        '/.packages',
        '--output-dill',
        '/build/377c3d43109b17e450b7030253976f40/app.dill',
        '--depfile',
        '/build/377c3d43109b17e450b7030253976f40/kernel_snapshot.d',
        '/lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey /build/377c3d43109b17e450b7030253976f40/app.dill 0\n'),
    ]);

    await const KernelSnapshot().build(androidEnvironment);
  }));

  test('KernelSnapshot can disable track-widget-creation on debug builds', () => testbed.run(() async {
    globals.fs.file('.packages').writeAsStringSync('\n');
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'bin/cache/dart-sdk/bin/dart',
        'bin/cache/artifacts/engine/darwin-x64/frontend_server.dart.snapshot',
        '--sdk-root',
        'bin/cache/artifacts/engine/common/flutter_patched_sdk/',
        '--target=flutter',
        '-Ddart.developer.causal_async_stacks=true',
        '-Ddart.vm.profile=false',
        '-Ddart.vm.product=false',
        '--bytecode-options=source-positions,local-var-info,debugger-stops,instance-field-initializers,keep-unreachable-code,avoid-closure-call-instructions',
        '--enable-asserts',
        '--no-link-platform',
        '--packages',
        '/.packages',
        '--output-dill',
        '/build/377c3d43109b17e450b7030253976f40/app.dill',
        '--depfile',
        '/build/377c3d43109b17e450b7030253976f40/kernel_snapshot.d',
        '/lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey /build/377c3d43109b17e450b7030253976f40/app.dill 0\n'),
    ]);

    await const KernelSnapshot().build(androidEnvironment
      ..defines[kBuildMode] = 'debug'
      ..defines[kTrackWidgetCreation] = 'false');
  }));

  test('KernelSnapshot forces platform linking on debug for darwin target platforms', () => testbed.run(() async {
    globals.fs.file('.packages').writeAsStringSync('\n');
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'bin/cache/dart-sdk/bin/dart',
        'bin/cache/artifacts/engine/darwin-x64/frontend_server.dart.snapshot',
        '--sdk-root',
        'bin/cache/artifacts/engine/common/flutter_patched_sdk/',
        '--target=flutter',
        '-Ddart.developer.causal_async_stacks=true',
        '-Ddart.vm.profile=false',
        '-Ddart.vm.product=false',
        '--bytecode-options=source-positions,local-var-info,debugger-stops,instance-field-initializers,keep-unreachable-code,avoid-closure-call-instructions',
        '--enable-asserts',
        '--packages',
        '/.packages',
        '--output-dill',
        '/build/377c3d43109b17e450b7030253976f40/app.dill',
        '--depfile',
        '/build/377c3d43109b17e450b7030253976f40/kernel_snapshot.d',
        '/lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey /build/377c3d43109b17e450b7030253976f40/app.dill 0\n'),
    ]);

    await const KernelSnapshot().build(androidEnvironment
      ..defines[kTargetPlatform]  = 'darwin-x64'
      ..defines[kBuildMode] = 'debug'
      ..defines[kTrackWidgetCreation] = 'false'
    );
  }));

  test('KernelSnapshot does use track widget creation on debug builds', () => testbed.run(() async {
    globals.fs.file('.packages').writeAsStringSync('\n');
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'bin/cache/dart-sdk/bin/dart',
        'bin/cache/artifacts/engine/darwin-x64/frontend_server.dart.snapshot',
        '--sdk-root',
        'bin/cache/artifacts/engine/common/flutter_patched_sdk/',
        '--target=flutter',
        '-Ddart.developer.causal_async_stacks=true',
        '-Ddart.vm.profile=false',
        '-Ddart.vm.product=false',
        '--bytecode-options=source-positions,local-var-info,debugger-stops,instance-field-initializers,keep-unreachable-code,avoid-closure-call-instructions',
        '--enable-asserts',
        '--track-widget-creation',
        '--no-link-platform',
        '--packages',
        '/.packages',
        '--output-dill',
        '/build/653e11a8e6908714056a57cd6b4f602a/app.dill',
        '--depfile',
        '/build/653e11a8e6908714056a57cd6b4f602a/kernel_snapshot.d',
        '/lib/main.dart',
      ], stdout: 'result $kBoundaryKey\n$kBoundaryKey\n$kBoundaryKey /build/653e11a8e6908714056a57cd6b4f602a/app.dill 0\n'),
    ]);

    await const KernelSnapshot().build(Environment.test(
      globals.fs.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: getNameForTargetPlatform(TargetPlatform.android_arm),
      }));
  }));

  test('AotElfProfile Produces correct output directory', () => testbed.run(() async {
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'bin/cache/artifacts/engine/android-arm-profile/darwin-x64/gen_snapshot',
        '--deterministic',
        '--snapshot_kind=app-aot-elf',
        '--elf=/build/377c3d43109b17e450b7030253976f40/app.so',
        '--strip',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        '--no-causal-async-stacks',
        '--lazy-async-stacks',
        '/build/377c3d43109b17e450b7030253976f40/app.dill',
      ])
    ]);
    androidEnvironment.buildDir.childFile('app.dill').createSync(recursive: true);

    await const AotElfProfile().build(androidEnvironment);
  }));

  test('AotElfProfile throws error if missing build mode', () => testbed.run(() async {
    androidEnvironment..defines.remove(kBuildMode);

    expect(const AotElfProfile().build(androidEnvironment),
      throwsA(isInstanceOf<MissingDefineException>()));
  }));

  test('AotElfProfile throws error if missing target platform', () => testbed.run(() async {
    androidEnvironment..defines.remove(kTargetPlatform);

    expect(const AotElfProfile().build(androidEnvironment),
      throwsA(isInstanceOf<MissingDefineException>()));
  }));

  test('AotAssemblyProfile throws error if missing build mode', () => testbed.run(() async {
    iosEnvironment..defines.remove(kBuildMode);

    expect(const AotAssemblyProfile().build(iosEnvironment),
      throwsA(isInstanceOf<MissingDefineException>()));
  }));

  test('AotAssemblyProfile throws error if missing target platform', () => testbed.run(() async {
    iosEnvironment..defines.remove(kTargetPlatform);

    expect(const AotAssemblyProfile().build(iosEnvironment),
      throwsA(isInstanceOf<MissingDefineException>()));
  }));

  test('AotAssemblyProfile throws error if built for non-iOS platform', () => testbed.run(() async {
    expect(const AotAssemblyProfile().build(androidEnvironment),
      throwsA(isInstanceOf<Exception>()));
  }));

  test('AotAssemblyProfile generates multiple arches and lipos together', () => testbed.run(() async {
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'bin/cache/artifacts/engine/ios-profile/gen_snapshot_armv7',
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=/build/1fc762188e2b37f8bbd50d8f6297043a/armv7/snapshot_assembly.S',
        '--strip',
        '--no-sim-use-hardfp',
        '--no-use-integer-division',
        '--no-causal-async-stacks',
        '--lazy-async-stacks',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/app.dill',
      ]),
      const FakeCommand(command: <String>[
        'bin/cache/artifacts/engine/ios-profile/gen_snapshot_arm64',
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/snapshot_assembly.S',
        '--strip',
        '--no-causal-async-stacks',
        '--lazy-async-stacks',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/app.dill',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        '--sdk',
        'iphoneos',
        '--show-sdk-path',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        '--sdk',
        'iphoneos',
        '--show-sdk-path',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        'cc',
        '-arch',
        'armv7',
        '-isysroot',
        '',
        '-c',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/armv7/snapshot_assembly.S',
        '-o',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/armv7/snapshot_assembly.o',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        'cc',
        '-arch',
        'arm64',
        '-isysroot',
        '',
        '-c',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/snapshot_assembly.S',
        '-o',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/snapshot_assembly.o',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-arch',
        'armv7',
        '-miphoneos-version-min=8.0',
        '-dynamiclib',
        '-Xlinker',
        '-rpath',
        '-Xlinker',
        '@executable_path/Frameworks',
        '-Xlinker',
        '-rpath',
        '-Xlinker',
        '@loader_path/Frameworks',
        '-install_name',
        '@rpath/App.framework/App',
        '-isysroot',
        '',
        '-o',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/armv7/App.framework/App',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/armv7/snapshot_assembly.o',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-arch',
        'arm64',
        '-miphoneos-version-min=8.0',
        '-dynamiclib',
        '-Xlinker',
        '-rpath',
        '-Xlinker',
        '@executable_path/Frameworks',
        '-Xlinker',
        '-rpath',
        '-Xlinker',
        '@loader_path/Frameworks',
        '-install_name',
        '@rpath/App.framework/App',
        '-isysroot',
        '',
        '-o',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/App.framework/App',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/snapshot_assembly.o',
      ]),
      const FakeCommand(command: <String>[
        'lipo',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/armv7/App.framework/App',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/App.framework/App',
        '-create',
        '-output',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/App.framework/App',
      ]),
    ]);
    iosEnvironment.defines[kIosArchs] ='armv7 arm64';

    await const AotAssemblyProfile().build(iosEnvironment);
  }));

  test('AotAssemblyProfile with bitcode sends correct argument to snapshotter (one arch)', () => testbed.run(() async {
    iosEnvironment.defines[kIosArchs] = 'arm64';
    iosEnvironment.defines[kBitcodeFlag] = 'true';
    processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(command: <String>[
        'bin/cache/artifacts/engine/ios-profile/gen_snapshot_arm64',
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/snapshot_assembly.S',
        '--strip',
        '--no-causal-async-stacks',
        '--lazy-async-stacks',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/app.dill',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        '--sdk',
        'iphoneos',
        '--show-sdk-path',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        'cc',
        '-arch',
        'arm64',
        '-isysroot',
        '',
        // Contains bitcode flag.
        '-fembed-bitcode',
        '-c',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/snapshot_assembly.S',
        '-o',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/snapshot_assembly.o',
      ]),
      const FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-arch',
        'arm64',
        '-miphoneos-version-min=8.0',
        '-dynamiclib',
        '-Xlinker',
        '-rpath',
        '-Xlinker',
        '@executable_path/Frameworks',
        '-Xlinker',
        '-rpath',
        '-Xlinker',
        '@loader_path/Frameworks',
        '-install_name',
        '@rpath/App.framework/App',
        // Contains bitcode flag.
        '-fembed-bitcode',
        '-isysroot',
        '',
        '-o',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/App.framework/App',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/snapshot_assembly.o',
      ]),
      const FakeCommand(command: <String>[
        'lipo',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/arm64/App.framework/App',
        '-create',
        '-output',
        '/build/1fc762188e2b37f8bbd50d8f6297043a/App.framework/App',
      ]),
    ]);

    await const AotAssemblyProfile().build(iosEnvironment);
  }));

  test('aot_assembly_profile with bitcode sends correct argument to snapshotter (mutli arch)', () => testbed.run(() async {
    iosEnvironment.defines[kIosArchs] = 'armv7 arm64';
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

    // when(mockXcode.cc(any)).thenAnswer((_) => Future<RunResult>.value(fakeRunResult));
    // when(mockXcode.clang(any)).thenAnswer((_) => Future<RunResult>.value(fakeRunResult));

    await const AotAssemblyProfile().build(iosEnvironment);

    // verify(mockXcode.cc(argThat(contains('-fembed-bitcode')))).called(2);
    // verify(mockXcode.clang(argThat(contains('-fembed-bitcode')))).called(2);
  }, overrides: <Type, Generator>{
    ProcessManager: () => mockProcessManager,
   // Xcode: () => mockXcode,
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
    // GenSnapshot: () => MockGenSnapshot(),
  }));
}

// class MockProcessManager extends Mock implements ProcessManager {}
// class MockGenSnapshot extends Mock implements GenSnapshot {}
// class MockXcode extends Mock implements Xcode {}

// class FakeGenSnapshot implements GenSnapshot {
//   List<String> lastCallAdditionalArgs;
//   @override
//   Future<int> run({SnapshotType snapshotType, DarwinArch darwinArch, Iterable<String> additionalArgs = const <String>[]}) async {
//     lastCallAdditionalArgs = additionalArgs.toList();
//     final Directory out = globals.fs.file(lastCallAdditionalArgs.last).parent;
//     if (darwinArch == null) {
//       out.childFile('app.so').createSync();
//       out.childFile('gen_snapshot.d').createSync();
//       return 0;
//     }
//     out.childDirectory('App.framework').childFile('App').createSync(recursive: true);

//     final String assembly = lastCallAdditionalArgs
//         .firstWhere((String arg) => arg.startsWith('--assembly'))
//         .substring('--assembly='.length);
//     globals.fs.file(assembly).createSync();
//     globals.fs.file(assembly.replaceAll('.S', '.o')).createSync();
//     return 0;
//   }
// }

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
