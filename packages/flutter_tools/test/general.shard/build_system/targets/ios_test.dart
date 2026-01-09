// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/ios.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/fake_process_manager.dart';
import '../../../src/fakes.dart';
import '../../../src/package_config.dart';

final Platform macPlatform = FakePlatform(
  operatingSystem: 'macos',
  environment: <String, String>{},
);

const _kSharedConfig = <String>[
  '-dynamiclib',
  '-miphoneos-version-min=13.0',
  '-Xlinker',
  '-rpath',
  '-Xlinker',
  '@executable_path/Frameworks',
  '-Xlinker',
  '-rpath',
  '-Xlinker',
  '@loader_path/Frameworks',
  '-fapplication-extension',
  '-install_name',
  '@rpath/App.framework/App',
  '-isysroot',
  'path/to/iPhoneOS.sdk',
];

FakeCommand createPlutilFakeCommand(File infoPlist) {
  return FakeCommand(
    command: <String>['plutil', '-replace', 'MinimumOSVersion', '-string', '13.0', infoPlist.path],
  );
}

void main() {
  late Environment environment;
  late MemoryFileSystem fileSystem;
  late FakeProcessManager processManager;
  late Artifacts artifacts;
  late BufferLogger logger;
  late TestUsage usage;
  late FakeAnalytics fakeAnalytics;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    usage = TestUsage();
    fakeAnalytics = getInitializedFakeAnalyticsInstance(
      fs: fileSystem,
      fakeFlutterVersion: FakeFlutterVersion(),
    );
    environment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{kTargetPlatform: 'ios'},
      inputs: <String, String>{},
      processManager: processManager,
      artifacts: artifacts,
      logger: logger,
      fileSystem: fileSystem,
      engineVersion: '2',
      analytics: fakeAnalytics,
    );
  });

  testWithoutContext('iOS AOT targets has analyticsName', () {
    expect(const AotAssemblyRelease().analyticsName, 'ios_aot');
    expect(const AotAssemblyProfile().analyticsName, 'ios_aot');
  });

  testUsingContext(
    'DebugUniversalFramework creates simulator binary',
    () async {
      environment.defines[kIosArchs] = 'x86_64';
      environment.defines[kSdkRoot] = 'path/to/iPhoneSimulator.sdk';
      final String appFrameworkPath = environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .path;
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xcrun',
            'clang',
            '-x',
            'c',
            '-arch',
            'x86_64',
            fileSystem.path.absolute(
              fileSystem.path.join('.tmp_rand0', 'flutter_tools_stub_source.rand0', 'debug_app.cc'),
            ),
            '-dynamiclib',
            '-miphonesimulator-version-min=13.0',
            '-Xlinker',
            '-rpath',
            '-Xlinker',
            '@executable_path/Frameworks',
            '-Xlinker',
            '-rpath',
            '-Xlinker',
            '@loader_path/Frameworks',
            '-fapplication-extension',
            '-install_name',
            '@rpath/App.framework/App',
            '-isysroot',
            'path/to/iPhoneSimulator.sdk',
            '-o',
            appFrameworkPath,
          ],
        ),
        FakeCommand(
          command: <String>['xattr', '-r', '-d', 'com.apple.FinderInfo', appFrameworkPath],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            '-',
            '--timestamp=none',
            appFrameworkPath,
          ],
        ),
      ]);

      await const DebugUniversalFramework().build(environment);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  testUsingContext(
    'DebugUniversalFramework creates expected binary with arm64 only arch',
    () async {
      environment.defines[kIosArchs] = 'arm64';
      environment.defines[kSdkRoot] = 'path/to/iPhoneOS.sdk';
      final String appFrameworkPath = environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .path;
      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'xcrun',
            'clang',
            '-x',
            'c',
            // iphone only gets 64 bit arch based on kIosArchs
            '-arch',
            'arm64',
            fileSystem.path.absolute(
              fileSystem.path.join('.tmp_rand0', 'flutter_tools_stub_source.rand0', 'debug_app.cc'),
            ),
            ..._kSharedConfig,
            '-o',
            appFrameworkPath,
          ],
        ),
        FakeCommand(
          command: <String>['xattr', '-r', '-d', 'com.apple.FinderInfo', appFrameworkPath],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            '-',
            '--timestamp=none',
            appFrameworkPath,
          ],
        ),
      ]);

      await const DebugUniversalFramework().build(environment);
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  testUsingContext(
    'IosAssetBundle warns if plutil fails',
    () async {
      environment.defines[kBuildMode] = 'debug';
      environment.defines[kCodesignIdentity] = 'ABC123';

      fileSystem
          .file(artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug))
          .createSync();
      fileSystem
          .file(artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug))
          .createSync();
      fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_app');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      fileSystem
          .file(fileSystem.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
          .createSync(recursive: true);
      environment.buildDir.childFile('app.dill').createSync(recursive: true);
      environment.buildDir.childFile('native_assets.json').createSync();
      environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .createSync(recursive: true);

      final File infoPlist = environment.outputDir
          .childDirectory('App.framework')
          .childFile('Info.plist');
      final File frameworkBinary = environment.outputDir
          .childDirectory('App.framework')
          .childFile('App');

      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'plutil',
            '-replace',
            'MinimumOSVersion',
            '-string',
            '13.0',
            infoPlist.path,
          ],
          exitCode: 1,
          stderr: 'plutil: error: invalid argument',
        ),

        FakeCommand(
          command: <String>['xattr', '-r', '-d', 'com.apple.FinderInfo', frameworkBinary.path],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            'ABC123',
            '--timestamp=none',
            frameworkBinary.path,
          ],
        ),
      ]);

      await const DebugIosApplicationBundle().build(environment);

      final fakeStdio = globals.stdio as FakeStdio;
      expect(
        fakeStdio.buffer.toString(),
        contains(
          'warning: Failed to update MinimumOSVersion in ${infoPlist.path}. This may cause AppStore validation failures.',
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
      Stdio: () => FakeStdio(),
    },
  );
  testUsingContext(
    'DebugIosApplicationBundle',
    () async {
      environment.defines[kBuildMode] = 'debug';
      environment.defines[kCodesignIdentity] = 'ABC123';
      // Precompiled dart data

      fileSystem
          .file(artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug))
          .createSync();
      fileSystem
          .file(artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug))
          .createSync();
      // Project info
      fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_app');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      // Plist file
      fileSystem
          .file(fileSystem.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
          .createSync(recursive: true);
      // App kernel
      environment.buildDir.childFile('app.dill').createSync(recursive: true);
      environment.buildDir.childFile('native_assets.json').createSync();
      // Stub framework
      environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .createSync(recursive: true);

      final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
      final File frameworkDirectoryBinary = frameworkDirectory.childFile('App');
      final File infoPlist = frameworkDirectory.childFile('Info.plist');
      processManager.addCommands(<FakeCommand>[
        createPlutilFakeCommand(infoPlist),
        FakeCommand(
          command: <String>[
            'xattr',
            '-r',
            '-d',
            'com.apple.FinderInfo',
            frameworkDirectoryBinary.path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            'ABC123',
            '--timestamp=none',
            frameworkDirectoryBinary.path,
          ],
        ),
      ]);

      await const DebugIosApplicationBundle().build(environment);
      expect(processManager, hasNoRemainingExpectations);

      expect(frameworkDirectoryBinary, exists);
      expect(frameworkDirectory.childFile('Info.plist'), exists);

      final Directory assetDirectory = frameworkDirectory.childDirectory('flutter_assets');
      expect(assetDirectory.childFile('kernel_blob.bin'), exists);
      expect(assetDirectory.childFile('vm_snapshot_data'), exists);
      expect(assetDirectory.childFile('isolate_snapshot_data'), exists);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  testUsingContext(
    'DebugIosApplicationBundle with flavor',
    () async {
      environment.defines[kBuildMode] = 'debug';
      environment.defines[kCodesignIdentity] = 'ABC123';
      environment.defines[kFlavor] = 'vanilla';
      environment.defines[kXcodeConfiguration] = 'Debug-strawberry';
      fileSystem.directory('/ios/Runner.xcodeproj').createSync(recursive: true);
      fileSystem.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
  name: example
  flutter:
    assets:
      - assets/common/
      - path: assets/vanilla/
        flavors:
          - vanilla
      - path: assets/strawberry/
        flavors:
          - strawberry
  ''');

      fileSystem.file('assets/common/image.png').createSync(recursive: true);
      fileSystem.file('assets/vanilla/ice-cream.png').createSync(recursive: true);
      fileSystem.file('assets/strawberry/ice-cream.png').createSync(recursive: true);
      // Precompiled dart data
      fileSystem
          .file(artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug))
          .createSync();
      fileSystem
          .file(artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug))
          .createSync();
      // Project info
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'example');
      // Plist file
      fileSystem
          .file(fileSystem.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
          .createSync(recursive: true);
      // App kernel
      environment.buildDir.childFile('app.dill').createSync(recursive: true);
      environment.buildDir.childFile('native_assets.json').createSync();
      // Stub framework
      environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .createSync(recursive: true);

      final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
      final File frameworkDirectoryBinary = frameworkDirectory.childFile('App');
      final File infoPlist = frameworkDirectory.childFile('Info.plist');
      processManager.addCommands(<FakeCommand>[
        createPlutilFakeCommand(infoPlist),
        FakeCommand(
          command: <String>[
            'xattr',
            '-r',
            '-d',
            'com.apple.FinderInfo',
            frameworkDirectoryBinary.path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            'ABC123',
            '--timestamp=none',
            frameworkDirectoryBinary.path,
          ],
        ),
      ]);
      await const DebugIosApplicationBundle().build(environment);

      expect(
        fileSystem.file('${frameworkDirectory.path}/flutter_assets/assets/common/image.png'),
        exists,
      );
      expect(
        fileSystem.file('${frameworkDirectory.path}/flutter_assets/assets/vanilla/ice-cream.png'),
        isNot(exists),
      );
      expect(
        fileSystem.file(
          '${frameworkDirectory.path}/flutter_assets/assets/strawberry/ice-cream.png',
        ),
        exists,
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
      XcodeProjectInterpreter: () =>
          FakeXcodeProjectInterpreter(schemes: <String>['Runner', 'strawberry']),
    },
  );

  testUsingContext(
    'DebugIosApplicationBundle with impeller and shader compilation',
    () async {
      // Create impellerc to work around fallback detection logic.
      fileSystem
          .file(artifacts.getHostArtifact(HostArtifact.impellerc))
          .createSync(recursive: true);

      environment.defines[kBuildMode] = 'debug';
      environment.defines[kCodesignIdentity] = 'ABC123';
      // Precompiled dart data

      fileSystem
          .file(artifacts.getArtifactPath(Artifact.vmSnapshotData, mode: BuildMode.debug))
          .createSync();
      fileSystem
          .file(artifacts.getArtifactPath(Artifact.isolateSnapshotData, mode: BuildMode.debug))
          .createSync();
      // Project info
      fileSystem
          .file('pubspec.yaml')
          .writeAsStringSync('name: my_app\nflutter:\n  shaders:\n    - shader.glsl');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');
      // Plist file
      fileSystem
          .file(fileSystem.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
          .createSync(recursive: true);
      // Shader file
      fileSystem.file('shader.glsl').writeAsStringSync('test');
      // App kernel
      environment.buildDir.childFile('app.dill').createSync(recursive: true);
      environment.buildDir.childFile('native_assets.json').createSync();
      // Stub framework
      environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .createSync(recursive: true);

      final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
      final File frameworkDirectoryBinary = frameworkDirectory.childFile('App');
      final File infoPlist = frameworkDirectory.childFile('Info.plist');
      processManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'HostArtifact.impellerc',
            '--runtime-stage-metal',
            '--iplr',
            '--sl=/App.framework/flutter_assets/shader.glsl',
            '--spirv=/App.framework/flutter_assets/shader.glsl.spirv',
            '--input=/shader.glsl',
            '--input-type=frag',
            '--include=/',
            '--include=/./shader_lib',
          ],
        ),
        createPlutilFakeCommand(infoPlist),
        FakeCommand(
          command: <String>[
            'xattr',
            '-r',
            '-d',
            'com.apple.FinderInfo',
            frameworkDirectoryBinary.path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            'ABC123',
            '--timestamp=none',
            frameworkDirectoryBinary.path,
          ],
        ),
      ]);

      await const DebugIosApplicationBundle().build(environment);
      expect(processManager, hasNoRemainingExpectations);

      expect(frameworkDirectoryBinary, exists);
      expect(frameworkDirectory.childFile('Info.plist'), exists);

      final Directory assetDirectory = frameworkDirectory.childDirectory('flutter_assets');
      expect(assetDirectory.childFile('kernel_blob.bin'), exists);
      expect(assetDirectory.childFile('vm_snapshot_data'), exists);
      expect(assetDirectory.childFile('isolate_snapshot_data'), exists);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  testUsingContext(
    'ReleaseIosApplicationBundle build',
    () async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[kCodesignIdentity] = 'ABC123';
      environment.defines[kXcodeAction] = 'build';

      // Project info
      fileSystem.file('pubspec.yaml').writeAsStringSync('name: my_app');
      writePackageConfigFiles(directory: fileSystem.currentDirectory, mainLibName: 'my_app');

      // Plist file
      fileSystem
          .file(fileSystem.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
          .createSync(recursive: true);

      // Real framework
      environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .createSync(recursive: true);
      environment.buildDir.childFile('native_assets.json').createSync();

      // Input dSYM
      environment.buildDir
          .childDirectory('App.framework.dSYM')
          .childDirectory('Contents')
          .childDirectory('Resources')
          .childDirectory('DWARF')
          .childFile('App')
          .createSync(recursive: true);

      final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
      final File frameworkDirectoryBinary = frameworkDirectory.childFile('App');
      final File infoPlist = frameworkDirectory.childFile('Info.plist');
      processManager.addCommands(<FakeCommand>[
        createPlutilFakeCommand(infoPlist),
        FakeCommand(
          command: <String>[
            'xattr',
            '-r',
            '-d',
            'com.apple.FinderInfo',
            frameworkDirectoryBinary.path,
          ],
        ),
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            'ABC123',
            frameworkDirectoryBinary.path,
          ],
        ),
      ]);

      await const ReleaseIosApplicationBundle().build(environment);
      expect(processManager, hasNoRemainingExpectations);

      expect(frameworkDirectoryBinary, exists);
      expect(frameworkDirectory.childFile('Info.plist'), exists);
      expect(
        environment.outputDir
            .childDirectory('App.framework.dSYM')
            .childDirectory('Contents')
            .childDirectory('Resources')
            .childDirectory('DWARF')
            .childFile('App'),
        exists,
      );

      final Directory assetDirectory = frameworkDirectory.childDirectory('flutter_assets');
      expect(assetDirectory.childFile('kernel_blob.bin'), isNot(exists));
      expect(assetDirectory.childFile('vm_snapshot_data'), isNot(exists));
      expect(assetDirectory.childFile('isolate_snapshot_data'), isNot(exists));
      expect(usage.events, isEmpty);
      expect(fakeAnalytics.sentEvents, isEmpty);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  testUsingContext(
    'ReleaseIosApplicationBundle sends archive success event',
    () async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[kXcodeAction] = 'install';

      fileSystem
          .file(fileSystem.path.join('ios', 'Flutter', 'AppFrameworkInfo.plist'))
          .createSync(recursive: true);

      environment.buildDir
          .childDirectory('App.framework')
          .childFile('App')
          .createSync(recursive: true);
      environment.buildDir.childFile('native_assets.json').createSync();

      final Directory frameworkDirectory = environment.outputDir.childDirectory('App.framework');
      final File frameworkDirectoryBinary = frameworkDirectory.childFile('App');
      final File infoPlist = frameworkDirectory.childFile('Info.plist');
      processManager.addCommands(<FakeCommand>[
        createPlutilFakeCommand(infoPlist),
        FakeCommand(
          command: <String>[
            'xattr',
            '-r',
            '-d',
            'com.apple.FinderInfo',
            frameworkDirectoryBinary.path,
          ],
        ),
        FakeCommand(
          command: <String>['codesign', '--force', '--sign', '-', frameworkDirectoryBinary.path],
        ),
      ]);

      await const ReleaseIosApplicationBundle().build(environment);
      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.appleUsageEvent(workflow: 'assemble', parameter: 'ios-archive', result: 'success'),
        ),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  testUsingContext(
    'ReleaseIosApplicationBundle sends archive fail event',
    () async {
      environment.defines[kBuildMode] = 'release';
      environment.defines[kXcodeAction] = 'install';

      // Throws because the project files are not set up.
      await expectLater(
        () => const ReleaseIosApplicationBundle().build(environment),
        throwsA(const TypeMatcher<FileSystemException>()),
      );
      expect(
        fakeAnalytics.sentEvents,
        contains(
          Event.appleUsageEvent(workflow: 'assemble', parameter: 'ios-archive', result: 'fail'),
        ),
      );
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  testUsingContext(
    'AotAssemblyRelease throws exception if asked to build for simulator',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final environment = Environment.test(
        fileSystem.currentDirectory,
        defines: <String, String>{
          kTargetPlatform: 'ios',
          kSdkRoot: 'path/to/iPhoneSimulator.sdk',
          kBuildMode: 'release',
          kIosArchs: 'x86_64',
        },
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
      );

      expect(
        const AotAssemblyRelease().build(environment),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'description',
            contains('release/profile builds are only supported for physical devices.'),
          ),
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  testUsingContext(
    'AotAssemblyRelease throws exception if sdk root is missing',
    () async {
      final FileSystem fileSystem = MemoryFileSystem.test();
      final environment = Environment.test(
        fileSystem.currentDirectory,
        defines: <String, String>{kTargetPlatform: 'ios'},
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
      );
      environment.defines[kBuildMode] = 'release';
      environment.defines[kIosArchs] = 'x86_64';

      expect(
        const AotAssemblyRelease().build(environment),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'description',
            contains('required define SdkRoot but it was not provided'),
          ),
        ),
      );
      expect(processManager, hasNoRemainingExpectations);
    },
    overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => processManager,
      Platform: () => macPlatform,
    },
  );

  group('copies Flutter.framework', () {
    late Directory outputDir;
    late File binary;
    late FakeCommand copyPhysicalFrameworkCommand;
    late FakeCommand copyPhysicalFrameworkDsymCommand;
    late FakeCommand copyPhysicalFrameworkDsymCommandFailure;
    late FakeCommand lipoCommandNonFatResult;
    late FakeCommand lipoVerifyArm64Command;
    late FakeCommand xattrCommand;
    late FakeCommand adHocCodesignCommand;

    setUp(() {
      final FileSystem fileSystem = MemoryFileSystem.test();
      outputDir = fileSystem.directory('output');
      binary = outputDir.childDirectory('Flutter.framework').childFile('Flutter');

      copyPhysicalFrameworkCommand = FakeCommand(
        command: <String>[
          'rsync',
          '-av',
          '--delete',
          '--filter',
          '- .DS_Store/',
          '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
          'Artifact.flutterFramework.TargetPlatform.ios.debug.EnvironmentType.physical',
          outputDir.path,
        ],
      );

      copyPhysicalFrameworkDsymCommand = FakeCommand(
        command: <String>[
          'rsync',
          '-av',
          '--delete',
          '--filter',
          '- .DS_Store/',
          '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
          'Artifact.flutterFrameworkDsym.TargetPlatform.ios.debug.EnvironmentType.physical',
          outputDir.path,
        ],
      );

      copyPhysicalFrameworkDsymCommandFailure = FakeCommand(
        command: <String>[
          'rsync',
          '-av',
          '--delete',
          '--filter',
          '- .DS_Store/',
          '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
          'Artifact.flutterFrameworkDsym.TargetPlatform.ios.debug.EnvironmentType.physical',
          outputDir.path,
        ],
        exitCode: 1,
      );

      lipoCommandNonFatResult = FakeCommand(
        command: <String>['lipo', '-info', binary.path],
        stdout: 'Non-fat file:',
      );

      lipoVerifyArm64Command = FakeCommand(
        command: <String>['lipo', binary.path, '-verify_arch', 'arm64'],
      );

      xattrCommand = FakeCommand(
        command: <String>['xattr', '-r', '-d', 'com.apple.FinderInfo', binary.path],
      );

      adHocCodesignCommand = FakeCommand(
        command: <String>['codesign', '--force', '--sign', '-', '--timestamp=none', binary.path],
      );
    });

    testWithoutContext('iphonesimulator', () async {
      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{kIosArchs: 'x86_64', kSdkRoot: 'path/to/iPhoneSimulator.sdk'},
      );

      processManager.addCommands(<FakeCommand>[
        FakeCommand(
          command: <String>[
            'rsync',
            '-av',
            '--delete',
            '--filter',
            '- .DS_Store/',
            '--chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r',
            'Artifact.flutterFramework.TargetPlatform.ios.debug.EnvironmentType.simulator',
            outputDir.path,
          ],
          onRun: (_) => binary.createSync(recursive: true),
        ),
        lipoCommandNonFatResult,
        FakeCommand(command: <String>['lipo', binary.path, '-verify_arch', 'x86_64']),
        xattrCommand,
        adHocCodesignCommand,
      ]);
      await const DebugUnpackIOS().build(environment);

      expect(
        logger.traceText,
        contains('Skipping lipo for non-fat file output/Flutter.framework/Flutter'),
      );
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('fails when frameworks missing', () async {
      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{kIosArchs: 'arm64', kSdkRoot: 'path/to/iPhoneOS.sdk'},
      );
      processManager.addCommand(copyPhysicalFrameworkCommand);
      await expectLater(
        const DebugUnpackIOS().build(environment),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'description',
            contains('Flutter.framework/Flutter does not exist, cannot thin'),
          ),
        ),
      );
    });

    testWithoutContext('fails when framework dSYM copy fails', () async {
      binary.createSync(recursive: true);
      final Directory dSYM = fileSystem.directory(
        artifacts.getArtifactPath(
          Artifact.flutterFrameworkDsym,
          platform: TargetPlatform.ios,
          mode: BuildMode.debug,
          environmentType: EnvironmentType.physical,
        ),
      );
      dSYM.createSync(recursive: true);

      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{kIosArchs: 'arm64', kSdkRoot: 'path/to/iPhoneOS.sdk'},
      );
      processManager.addCommands(<FakeCommand>[
        copyPhysicalFrameworkCommand,
        copyPhysicalFrameworkDsymCommandFailure,
      ]);
      await expectLater(
        const DebugUnpackIOS().build(environment),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'description',
            contains('Failed to copy framework dSYM'),
          ),
        ),
      );
    });

    testWithoutContext('fails when requested archs missing from framework', () async {
      binary.createSync(recursive: true);

      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{kIosArchs: 'arm64 x86_64', kSdkRoot: 'path/to/iPhoneOS.sdk'},
      );

      processManager.addCommands(<FakeCommand>[
        copyPhysicalFrameworkCommand,
        FakeCommand(
          command: <String>['lipo', '-info', binary.path],
          stdout: 'Architectures in the fat file:',
        ),
        FakeCommand(
          command: <String>['lipo', binary.path, '-verify_arch', 'arm64', 'x86_64'],
          exitCode: 1,
        ),
      ]);

      await expectLater(
        const DebugUnpackIOS().build(environment),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'description',
            contains(
              'does not contain architectures "arm64 x86_64".\n\n'
              'lipo -info:\nArchitectures in the fat file:',
            ),
          ),
        ),
      );
    });

    testWithoutContext('fails when lipo extract fails', () async {
      binary.createSync(recursive: true);

      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{kIosArchs: 'arm64 x86_64', kSdkRoot: 'path/to/iPhoneOS.sdk'},
      );

      processManager.addCommands(<FakeCommand>[
        copyPhysicalFrameworkCommand,
        FakeCommand(
          command: <String>['lipo', '-info', binary.path],
          stdout: 'Architectures in the fat file:',
        ),
        FakeCommand(command: <String>['lipo', binary.path, '-verify_arch', 'arm64', 'x86_64']),
        FakeCommand(
          command: <String>[
            'lipo',
            '-output',
            binary.path,
            '-extract',
            'arm64',
            '-extract',
            'x86_64',
            binary.path,
          ],
          exitCode: 1,
          stderr: 'lipo error',
        ),
      ]);

      await expectLater(
        const DebugUnpackIOS().build(environment),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'description',
            contains(
              'Failed to extract architectures "arm64 x86_64" for output/Flutter.framework/Flutter.\n\n'
              'stderr:\n'
              'lipo error\n\n'
              'lipo -info:\nArchitectures in the fat file:',
            ),
          ),
        ),
      );
    });

    group('CheckForLaunchRootViewControllerAccessDeprecation', () {
      testWithoutContext('Swift Positive', () async {
        final File file = fileSystem.file('AppDelegate.swift');
        file.writeAsStringSync('''
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
  }
}
''');
        await checkForLaunchRootViewControllerAccessDeprecationSwift(logger, file);
        expect(
          logger.warningText,
          startsWith(
            'AppDelegate.swift:6: warning: Flutter deprecation: Accessing rootViewController',
          ),
        );
      });

      testWithoutContext('Swift Negative', () async {
        final File file = fileSystem.file('AppDelegate.swift');
        file.writeAsStringSync('''
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  }

  func doIt() {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
  }
}
''');
        await checkForLaunchRootViewControllerAccessDeprecationSwift(logger, file);
        expect(logger.warningText, equals(''));
      });

      testWithoutContext('Objc Positive', () async {
        final File file = fileSystem.file('AppDelegate.m');
        file.writeAsStringSync('''
@implementation AppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  FlutterViewController* controller =
      (FlutterViewController*)self.window.rootViewController;
}

@end
''');
        await checkForLaunchRootViewControllerAccessDeprecationObjc(logger, file);
        expect(
          logger.warningText,
          startsWith('AppDelegate.m:6: warning: Flutter deprecation: Accessing rootViewController'),
        );
      });

      testWithoutContext('Objc Negative', () async {
        final File file = fileSystem.file('AppDelegate.m');
        file.writeAsStringSync('''
@implementation AppDelegate

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
}

- (void)doIt {
 FlutterViewController* controller =
      (FlutterViewController*)self.window.rootViewController;
}

@end
''');
        await checkForLaunchRootViewControllerAccessDeprecationObjc(logger, file);
        expect(logger.warningText, equals(''));
      });
    });

    testWithoutContext('skips thin framework', () async {
      binary.createSync(recursive: true);

      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{kIosArchs: 'arm64', kSdkRoot: 'path/to/iPhoneOS.sdk'},
      );

      processManager.addCommands(<FakeCommand>[
        copyPhysicalFrameworkCommand,
        lipoCommandNonFatResult,
        lipoVerifyArm64Command,
        xattrCommand,
        adHocCodesignCommand,
      ]);
      await const DebugUnpackIOS().build(environment);

      expect(
        logger.traceText,
        contains('Skipping lipo for non-fat file output/Flutter.framework/Flutter'),
      );

      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('thins fat framework', () async {
      binary.createSync(recursive: true);

      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{kIosArchs: 'arm64 x86_64', kSdkRoot: 'path/to/iPhoneOS.sdk'},
      );

      processManager.addCommands(<FakeCommand>[
        copyPhysicalFrameworkCommand,
        FakeCommand(
          command: <String>['lipo', '-info', binary.path],
          stdout: 'Architectures in the fat file:',
        ),
        FakeCommand(command: <String>['lipo', binary.path, '-verify_arch', 'arm64', 'x86_64']),
        FakeCommand(
          command: <String>[
            'lipo',
            '-output',
            binary.path,
            '-extract',
            'arm64',
            '-extract',
            'x86_64',
            binary.path,
          ],
        ),
        xattrCommand,
        adHocCodesignCommand,
      ]);

      await const DebugUnpackIOS().build(environment);
      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('strips framework', () async {
      binary.createSync(recursive: true);

      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{kIosArchs: 'arm64', kSdkRoot: 'path/to/iPhoneOS.sdk'},
      );

      processManager.addCommands(<FakeCommand>[
        copyPhysicalFrameworkCommand,
        lipoCommandNonFatResult,
        lipoVerifyArm64Command,
        xattrCommand,
        adHocCodesignCommand,
      ]);
      await const DebugUnpackIOS().build(environment);

      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('fails when codesign fails', () async {
      binary.createSync(recursive: true);

      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{
          kIosArchs: 'arm64',
          kSdkRoot: 'path/to/iPhoneOS.sdk',
          kCodesignIdentity: 'ABC123',
        },
      );

      processManager.addCommands(<FakeCommand>[
        copyPhysicalFrameworkCommand,
        lipoCommandNonFatResult,
        lipoVerifyArm64Command,
        xattrCommand,
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            'ABC123',
            '--timestamp=none',
            binary.path,
          ],
          exitCode: 1,
          stderr: 'codesign error',
          stdout: 'codesign info',
        ),
      ]);

      await expectLater(
        const DebugUnpackIOS().build(environment),
        throwsA(
          isException.having(
            (Exception exception) => exception.toString(),
            'description',
            contains(
              'Failed to codesign output/Flutter.framework/Flutter with identity ABC123.\ncodesign info\ncodesign error',
            ),
          ),
        ),
      );

      expect(processManager, hasNoRemainingExpectations);
    });

    testWithoutContext('codesigns framework', () async {
      binary.createSync(recursive: true);
      final Directory dSYM = fileSystem.directory(
        artifacts.getArtifactPath(
          Artifact.flutterFrameworkDsym,
          platform: TargetPlatform.ios,
          mode: BuildMode.debug,
          environmentType: EnvironmentType.physical,
        ),
      );
      dSYM.createSync(recursive: true);

      final environment = Environment.test(
        fileSystem.currentDirectory,
        processManager: processManager,
        artifacts: artifacts,
        logger: logger,
        fileSystem: fileSystem,
        outputDir: outputDir,
        defines: <String, String>{
          kIosArchs: 'arm64',
          kSdkRoot: 'path/to/iPhoneOS.sdk',
          kCodesignIdentity: 'ABC123',
        },
      );

      processManager.addCommands(<FakeCommand>[
        copyPhysicalFrameworkCommand,
        copyPhysicalFrameworkDsymCommand,
        lipoCommandNonFatResult,
        lipoVerifyArm64Command,
        xattrCommand,
        FakeCommand(
          command: <String>[
            'codesign',
            '--force',
            '--sign',
            'ABC123',
            '--timestamp=none',
            binary.path,
          ],
        ),
      ]);
      await const DebugUnpackIOS().build(environment);

      expect(processManager, hasNoRemainingExpectations);
    });
  });

  group('DebugIosLLDBInit', () {
    late FakeStdio fakeStdio;
    late MemoryFileSystem testFileSystem;

    setUp(() {
      fakeStdio = FakeStdio();
      testFileSystem = MemoryFileSystem.test();
    });

    testUsingContext(
      'prints warning if missing LLDB Init File in all schemes',
      () async {
        const projectPath = 'path/to/project';
        testFileSystem.directory(projectPath).createSync(recursive: true);
        final Directory projectDirectory = testFileSystem.directory(projectPath);
        projectDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  module:
    iosBundleIdentifier: com.example.my_module
''');
        final testEnvironment = Environment.test(
          testFileSystem.currentDirectory,
          defines: <String, String>{kTargetPlatform: 'ios'},
          processManager: processManager,
          artifacts: artifacts,
          logger: logger,
          fileSystem: testFileSystem,
          projectDir: projectDirectory,
        );
        testEnvironment.defines
          ..[kIosArchs] = 'arm64'
          ..[kSdkRoot] = 'path/to/iPhoneOS.sdk'
          ..[kBuildMode] = 'debug'
          ..[kSrcRoot] = projectPath
          ..[kTargetDeviceOSVersion] = '26.0.0';

        await const DebugIosLLDBInit().build(testEnvironment);

        expect(
          fakeStdio.buffer.toString(),
          contains('warning: Debugging Flutter on new iOS versions requires an LLDB Init File.'),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => processManager,
        Platform: () => macPlatform,
        Stdio: () => fakeStdio,
      },
    );

    testUsingContext(
      'skips if not a module',
      () async {
        const projectPath = 'path/to/project';
        testFileSystem.directory(projectPath).createSync(recursive: true);
        final Directory projectDirectory = testFileSystem.directory(projectPath);
        final testEnvironment = Environment.test(
          testFileSystem.currentDirectory,
          defines: <String, String>{kTargetPlatform: 'ios'},
          processManager: processManager,
          artifacts: artifacts,
          logger: logger,
          fileSystem: testFileSystem,
          projectDir: projectDirectory,
        );
        testEnvironment.defines
          ..[kIosArchs] = 'arm64'
          ..[kSdkRoot] = 'path/to/iPhoneOS.sdk'
          ..[kBuildMode] = 'debug'
          ..[kSrcRoot] = projectPath
          ..[kTargetDeviceOSVersion] = '26.0.0';

        await const DebugIosLLDBInit().build(testEnvironment);

        expect(
          fakeStdio.buffer.toString(),
          isNot(
            contains('warning: Debugging Flutter on new iOS versions requires an LLDB Init File.'),
          ),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => processManager,
        Platform: () => macPlatform,
        Stdio: () => fakeStdio,
      },
    );

    testUsingContext(
      'skips if targetting simulator',
      () async {
        const projectPath = 'path/to/project';
        testFileSystem.directory(projectPath).createSync(recursive: true);
        final Directory projectDirectory = testFileSystem.directory(projectPath);
        projectDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  module:
    iosBundleIdentifier: com.example.my_module
''');
        final testEnvironment = Environment.test(
          testFileSystem.currentDirectory,
          defines: <String, String>{kTargetPlatform: 'ios'},
          processManager: processManager,
          artifacts: artifacts,
          logger: logger,
          fileSystem: testFileSystem,
          projectDir: projectDirectory,
        );
        testEnvironment.defines
          ..[kIosArchs] = 'arm64'
          ..[kSdkRoot] = 'path/to/iPhoneSimulator.sdk'
          ..[kBuildMode] = 'debug'
          ..[kSrcRoot] = projectPath
          ..[kTargetDeviceOSVersion] = '26.0.0';

        await const DebugIosLLDBInit().build(testEnvironment);
        expect(
          fakeStdio.buffer.toString(),
          isNot(
            contains('warning: Debugging Flutter on new iOS versions requires an LLDB Init File.'),
          ),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => processManager,
        Platform: () => macPlatform,
      },
    );

    testUsingContext(
      'skips if iOS version is less than 26.0',
      () async {
        const projectPath = 'path/to/project';
        testFileSystem.directory(projectPath).createSync(recursive: true);
        final Directory projectDirectory = testFileSystem.directory(projectPath);
        projectDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  module:
    iosBundleIdentifier: com.example.my_module
''');
        final testEnvironment = Environment.test(
          testFileSystem.currentDirectory,
          defines: <String, String>{kTargetPlatform: 'ios'},
          processManager: processManager,
          artifacts: artifacts,
          logger: logger,
          fileSystem: testFileSystem,
          projectDir: projectDirectory,
        );
        testEnvironment.defines
          ..[kIosArchs] = 'arm64'
          ..[kSdkRoot] = 'path/to/iPhoneOS.sdk'
          ..[kBuildMode] = 'debug'
          ..[kSrcRoot] = projectPath
          ..[kTargetDeviceOSVersion] = '18.3.1';

        await const DebugIosLLDBInit().build(testEnvironment);
        expect(
          fakeStdio.buffer.toString(),
          isNot(
            contains('warning: Debugging Flutter on new iOS versions requires an LLDB Init File.'),
          ),
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => processManager,
        Platform: () => macPlatform,
      },
    );

    testUsingContext(
      'does not throw error if there is an LLDB Init File in any scheme',
      () async {
        const projectPath = 'path/to/project';
        testFileSystem.directory(projectPath).createSync(recursive: true);
        testFileSystem
            .directory(projectPath)
            .childDirectory('MyProject.xcodeproj')
            .childDirectory('xcshareddata')
            .childDirectory('xcschemes')
            .childFile('MyProject.xcscheme')
          ..createSync(recursive: true)
          ..writeAsStringSync(r'customLLDBInitFile = "some/path/.lldbinit"');
        final Directory projectDirectory = testFileSystem.directory(projectPath);
        projectDirectory.childFile('pubspec.yaml').writeAsStringSync('''
flutter:
  module:
    iosBundleIdentifier: com.example.my_module
''');
        final testEnvironment = Environment.test(
          testFileSystem.currentDirectory,
          defines: <String, String>{kTargetPlatform: 'ios'},
          processManager: processManager,
          artifacts: artifacts,
          logger: logger,
          fileSystem: testFileSystem,
          projectDir: projectDirectory,
        );
        testEnvironment.defines
          ..[kIosArchs] = 'arm64'
          ..[kSdkRoot] = 'path/to/iPhoneOS.sdk'
          ..[kBuildMode] = 'debug'
          ..[kSrcRoot] = projectPath
          ..[kTargetDeviceOSVersion] = '26.0.0';

        await const DebugIosLLDBInit().build(testEnvironment);
      },
      overrides: <Type, Generator>{
        FileSystem: () => testFileSystem,
        ProcessManager: () => processManager,
        Platform: () => macPlatform,
      },
    );
  });
}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  FakeXcodeProjectInterpreter({this.isInstalled = true, this.schemes = const <String>['Runner']});

  @override
  final bool isInstalled;

  List<String> schemes;

  @override
  Future<XcodeProjectInfo?> getInfo(String projectPath, {String? projectFilename}) async {
    return XcodeProjectInfo(<String>[], <String>[], schemes, BufferLogger.test());
  }
}

class FakeStdio extends Fake implements Stdio {
  final buffer = StringBuffer();

  @override
  void stderrWrite(String message, {void Function(String, dynamic, StackTrace)? fallback}) {
    buffer.writeln(message);
  }
}
