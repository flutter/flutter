// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/macos.dart';
import 'package:flutter_tools/src/convert.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_process_manager.dart';

void main() {
  Environment environment;
  FileSystem fileSystem;
  Artifacts artifacts;
  FakeProcessManager processManager;
  File binary;
  BufferLogger logger;
  FakeCommand copyFrameworkCommand;
  FakeCommand lipoInfoNonFatCommand;
  FakeCommand lipoInfoFatCommand;
  FakeCommand lipoVerifyX86_64Command;

  setUp(() {
    processManager = FakeProcessManager.empty();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: 'debug',
        kTargetPlatform: 'darwin',
        kDarwinArchs: 'x86_64',
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      engineVersion: '2'
    );

    binary = environment.outputDir
      .childDirectory('FlutterMacOS.framework')
      .childDirectory('Versions')
      .childDirectory('A')
      .childFile('FlutterMacOS');

    copyFrameworkCommand = FakeCommand(
      command: <String>[
        'rsync',
        '-av',
        '--delete',
        '--filter',
        '- .DS_Store/',
        'Artifact.flutterMacOSFramework.debug',
        environment.outputDir.path,
      ],
    );

    lipoInfoNonFatCommand = FakeCommand(command: <String>[
      'lipo',
      '-info',
      binary.path,
    ], stdout: 'Non-fat file:');

    lipoInfoFatCommand = FakeCommand(command: <String>[
      'lipo',
      '-info',
      binary.path,
    ], stdout: 'Architectures in the fat file:');

    lipoVerifyX86_64Command = FakeCommand(command: <String>[
      'lipo',
      binary.path,
      '-verify_arch',
      'x86_64',
    ]);
  });

  testUsingContext('Copies files to correct cache directory', () async {
    binary.createSync(recursive: true);
    processManager.addCommands(<FakeCommand>[
      copyFrameworkCommand,
      lipoInfoNonFatCommand,
      lipoVerifyX86_64Command,
    ]);

    await const DebugUnpackMacOS().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('thinning fails when framework missing', () async {
    processManager.addCommand(copyFrameworkCommand);
    await expectLater(
      const DebugUnpackMacOS().build(environment),
      throwsA(isException.having(
        (Exception exception) => exception.toString(),
        'description',
        contains('FlutterMacOS.framework/Versions/A/FlutterMacOS does not exist, cannot thin'),
      )),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('lipo fails when arch missing from framework', () async {
    environment.defines[kDarwinArchs] = 'arm64 x86_64';
    binary.createSync(recursive: true);
    processManager.addCommands(<FakeCommand>[
      copyFrameworkCommand,
      lipoInfoFatCommand,
      FakeCommand(command: <String>[
        'lipo',
        binary.path,
        '-verify_arch',
        'arm64',
        'x86_64',
      ], exitCode: 1),
    ]);

    await expectLater(
      const DebugUnpackMacOS().build(environment),
      throwsA(isException.having(
        (Exception exception) => exception.toString(),
        'description',
        contains('does not contain arm64 x86_64. Running lipo -info:\nArchitectures in the fat file:'),
      )),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('skips thins framework', () async {
    binary.createSync(recursive: true);
    processManager.addCommands(<FakeCommand>[
      copyFrameworkCommand,
      lipoInfoNonFatCommand,
      lipoVerifyX86_64Command,
    ]);

    await const DebugUnpackMacOS().build(environment);

    expect(logger.traceText, contains('Skipping lipo for non-fat file /FlutterMacOS.framework/Versions/A/FlutterMacOS'));
  });

  testUsingContext('thins fat framework', () async {
    binary.createSync(recursive: true);
    processManager.addCommands(<FakeCommand>[
      copyFrameworkCommand,
      lipoInfoFatCommand,
      lipoVerifyX86_64Command,
      FakeCommand(command: <String>[
          'lipo',
          '-output',
          binary.path,
          '-extract',
          'x86_64',
          binary.path,
      ]),
    ]);

    await const DebugUnpackMacOS().build(environment);

    expect(processManager, hasNoRemainingExpectations);
  });

  testUsingContext('debug macOS application fails if App.framework missing', () async {
    fileSystem.directory(
      artifacts.getArtifactPath(
        Artifact.flutterMacOSFramework,
        mode: BuildMode.debug,
      ))
      .createSync();
    final String inputKernel = fileSystem.path.join(environment.buildDir.path, 'app.dill');
    fileSystem.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    expect(() async => const DebugMacOSBundleFlutterAssets().build(environment),
        throwsException);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('debug macOS application creates correctly structured framework', () async {
    fileSystem.directory(
      artifacts.getArtifactPath(
        Artifact.flutterMacOSFramework,
        mode: BuildMode.debug,
      ))
      .createSync();
    environment.defines[kBundleSkSLPath] = 'bundle.sksl';
    fileSystem.file(
      artifacts.getArtifactPath(
        Artifact.vmSnapshotData,
        platform: TargetPlatform.darwin,
        mode: BuildMode.debug,
      )).createSync(recursive: true);
    fileSystem.file(
      artifacts.getArtifactPath(
        Artifact.isolateSnapshotData,
        platform: TargetPlatform.darwin,
        mode: BuildMode.debug,
      )).createSync(recursive: true);
    fileSystem.file('${environment.buildDir.path}/App.framework/App')
      .createSync(recursive: true);
    // sksl bundle
    fileSystem.file('bundle.sksl').writeAsStringSync(json.encode(
      <String, Object>{
        'engineRevision': '2',
        'platform': 'ios',
        'data': <String, Object>{
          'A': 'B',
        }
      }
    ));

    final String inputKernel = '${environment.buildDir.path}/app.dill';
    fileSystem.file(inputKernel)
      ..createSync(recursive: true)
      ..writeAsStringSync('testing');

    await const DebugMacOSBundleFlutterAssets().build(environment);

    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/kernel_blob.bin').readAsStringSync(),
      'testing',
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/Info.plist').readAsStringSync(),
      contains('io.flutter.flutter.app'),
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/vm_snapshot_data'),
      exists,
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/isolate_snapshot_data'),
      exists,
    );

    final File skslFile = fileSystem.file('App.framework/Versions/A/Resources/flutter_assets/io.flutter.shaders.json');

    expect(skslFile, exists);
    expect(skslFile.readAsStringSync(), '{"data":{"A":"B"}}');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('release/profile macOS application has no blob or precompiled runtime', () async {
    fileSystem.file('bin/cache/artifacts/engine/darwin-x64/vm_isolate_snapshot.bin')
      .createSync(recursive: true);
    fileSystem.file('bin/cache/artifacts/engine/darwin-x64/isolate_snapshot.bin')
      .createSync(recursive: true);
    fileSystem.file('${environment.buildDir.path}/App.framework/App')
      .createSync(recursive: true);

    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');

    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/kernel_blob.bin'),
      isNot(exists),
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/vm_snapshot_data'),
      isNot(exists),
    );
    expect(fileSystem.file(
      'App.framework/Versions/A/Resources/flutter_assets/isolate_snapshot_data'),
      isNot(exists),
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('release/profile macOS application updates when App.framework updates', () async {
    fileSystem.file('bin/cache/artifacts/engine/darwin-x64/vm_isolate_snapshot.bin')
      .createSync(recursive: true);
    fileSystem.file('bin/cache/artifacts/engine/darwin-x64/isolate_snapshot.bin')
      .createSync(recursive: true);
    final File inputFramework = fileSystem.file(fileSystem.path.join(environment.buildDir.path, 'App.framework', 'App'))
      ..createSync(recursive: true)
      ..writeAsStringSync('ABC');

    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');
    final File outputFramework = fileSystem.file(fileSystem.path.join(environment.outputDir.path, 'App.framework', 'App'));

    expect(outputFramework.readAsStringSync(), 'ABC');

    inputFramework.writeAsStringSync('DEF');
    await const ProfileMacOSBundleFlutterAssets().build(environment..defines[kBuildMode] = 'profile');

    expect(outputFramework.readAsStringSync(), 'DEF');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('DebugMacOSFramework creates expected binary with arm64 only arch', () async {
    environment.defines[kDarwinArchs] = 'arm64';
    processManager.addCommand(
      FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-x',
        'c',
        environment.buildDir.childFile('debug_app.cc').path,
        '-arch',
        'arm64',
        '-dynamiclib',
        '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
        '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
        '-install_name', '@rpath/App.framework/App',
        '-o',
        environment.buildDir
            .childDirectory('App.framework')
            .childFile('App')
            .path,
      ]),
    );

    await const DebugMacOSFramework().build(environment);
    expect(processManager.hasRemainingExpectations, isFalse);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('DebugMacOSFramework creates universal binary', () async {
    environment.defines[kDarwinArchs] = 'arm64 x86_64';
    processManager.addCommand(
      FakeCommand(command: <String>[
        'xcrun',
        'clang',
        '-x',
        'c',
        environment.buildDir.childFile('debug_app.cc').path,
        '-arch',
        'arm64',
        '-arch',
        'x86_64',
        '-dynamiclib',
        '-Xlinker', '-rpath', '-Xlinker', '@executable_path/Frameworks',
        '-Xlinker', '-rpath', '-Xlinker', '@loader_path/Frameworks',
        '-install_name', '@rpath/App.framework/App',
        '-o',
        environment.buildDir
            .childDirectory('App.framework')
            .childFile('App')
            .path,
      ]),
    );

    await const DebugMacOSFramework().build(environment);
    expect(processManager.hasRemainingExpectations, isFalse);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('CompileMacOSFramework creates universal binary', () async {
    environment.defines[kDarwinArchs] = 'arm64 x86_64';
    environment.defines[kBuildMode] = 'release';

    processManager.addCommands(<FakeCommand>[
      FakeCommand(command: <String>[
        'Artifact.genSnapshot.TargetPlatform.darwin.release_arm64',
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${environment.buildDir.childFile('arm64/snapshot_assembly.S').path}',
        '--strip',
        environment.buildDir.childFile('app.dill').path
      ]),
      FakeCommand(command: <String>[
        'Artifact.genSnapshot.TargetPlatform.darwin.release_x64',
        '--deterministic',
        '--snapshot_kind=app-aot-assembly',
        '--assembly=${environment.buildDir.childFile('x86_64/snapshot_assembly.S').path}',
        '--strip',
        environment.buildDir.childFile('app.dill').path
      ]),
      FakeCommand(command: <String>[
        'xcrun', 'cc',  '-arch', 'arm64',
        '-c', environment.buildDir.childFile('arm64/snapshot_assembly.S').path,
        '-o', environment.buildDir.childFile('arm64/snapshot_assembly.o').path
      ]),
      FakeCommand(command: <String>[
        'xcrun', 'cc',  '-arch', 'x86_64',
        '-c', environment.buildDir.childFile('x86_64/snapshot_assembly.S').path,
        '-o', environment.buildDir.childFile('x86_64/snapshot_assembly.o').path
      ]),
      FakeCommand(command: <String>[
        'xcrun', 'clang', '-arch', 'arm64', '-dynamiclib', '-Xlinker', '-rpath',
        '-Xlinker', '@executable_path/Frameworks', '-Xlinker', '-rpath',
        '-Xlinker', '@loader_path/Frameworks',
        '-install_name', '@rpath/App.framework/App',
        '-o', environment.buildDir.childFile('arm64/App.framework/App').path,
        environment.buildDir.childFile('arm64/snapshot_assembly.o').path
      ]),
      FakeCommand(command: <String>[
        'xcrun', 'clang', '-arch', 'x86_64', '-dynamiclib', '-Xlinker', '-rpath',
        '-Xlinker', '@executable_path/Frameworks', '-Xlinker', '-rpath',
        '-Xlinker', '@loader_path/Frameworks',
        '-install_name', '@rpath/App.framework/App',
        '-o', environment.buildDir.childFile('x86_64/App.framework/App').path,
        environment.buildDir.childFile('x86_64/snapshot_assembly.o').path
      ]),
      FakeCommand(command: <String>[
        'lipo',
        environment.buildDir.childFile('arm64/App.framework/App').path,
        environment.buildDir.childFile('x86_64/App.framework/App').path,
        '-create',
        '-output',
        environment.buildDir.childFile('App.framework/App').path,
      ]),
    ]);

    await const CompileMacOSFramework().build(environment);
    expect(processManager.hasRemainingExpectations, isFalse);

  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });
}
