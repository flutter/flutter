// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/native_assets/dart_hook_result.dart';
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/targets.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import 'fake_native_assets_build_runner.dart';

void main() {
  late FakeProcessManager processManager;
  late Environment environment;
  late Artifacts artifacts;
  late FileSystem fileSystem;
  late BufferLogger logger;
  late Uri projectUri;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    environment = Environment.test(
      fileSystem.currentDirectory,
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
      projectDir: fileSystem.directory('/project'),
    );
    environment.buildDir.createSync(recursive: true);
    projectUri = environment.projectDir.uri;
  });

  testUsingContext(
    'Native assets: non-bundled libraries require no copying',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      final Uri nonFlutterTesterAssetUri = environment.buildDir.childFile('native_assets.json').uri;
      await packageConfig.parent.create();
      await packageConfig.create();

      final File directSoFile = environment.projectDir.childFile('direct.so');
      directSoFile.writeAsBytesSync(<int>[]);

      CodeAsset makeCodeAsset(String name, LinkMode linkMode, [Uri? file]) =>
          CodeAsset(package: 'bar', name: name, linkMode: linkMode, file: file);

      final environmentDefines = <String, String>{kBuildMode: BuildMode.release.cliName};
      final codeAssets = <CodeAsset>[
        makeCodeAsset('malloc', LookupInProcess()),
        makeCodeAsset('free', LookupInExecutable()),
        makeCodeAsset('draw', DynamicLoadingSystem(Uri.file('/usr/lib/skia.so'))),
      ];
      final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(codeAssets: codeAssets),
        ),
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
      );
      await installCodeAssets(
        dartHookResult: dartHookResult,
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        nativeAssetsFileUri: nonFlutterTesterAssetUri,
        targetUri: projectUri.resolve('${getBuildDirectory()}/native_assets/test/'),
      );
      expect(testLogger.traceText, isNot(contains('Copying native assets to')));
    },
  );

  testUsingContext(
    'build with assets but not enabled',
    overrides: <Type, Generator>{
      // ignore: avoid_redundant_argument_values
      FeatureFlags: () => TestFeatureFlags(isNativeAssetsEnabled: false),
      ProcessManager: () => FakeProcessManager.empty(),
    },
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();
      expect(
        () => runFlutterSpecificHooks(
          environmentDefines: <String, String>{kBuildMode: BuildMode.debug.cliName},
          targetPlatform: TargetPlatform.windows_x64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
          ),
          buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
          buildDataAssets: true,
          recordedUsesFile: null,
        ),
        throwsToolExit(message: 'Enable code assets using `flutter config --enable-native-assets`'),
      );
    },
  );

  testUsingContext(
    'build no assets',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      final Uri nonFlutterTesterAssetUri = environment.buildDir
          .childFile(InstallCodeAssets.nativeAssetsFilename)
          .uri;
      await packageConfig.parent.create();
      await packageConfig.create();

      final environmentDefines = <String, String>{kBuildMode: BuildMode.debug.cliName};
      final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
        ),
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
      );
      final Directory targetDirectory = environment.buildDir.childDirectory('native_assets');
      await installCodeAssets(
        dartHookResult: dartHookResult,
        environmentDefines: environmentDefines,
        targetPlatform: TargetPlatform.windows_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        nativeAssetsFileUri: nonFlutterTesterAssetUri,
        targetUri: targetDirectory.uri,
      );
      expect(
        await fileSystem.file(nonFlutterTesterAssetUri).readAsString(),
        isNot(contains('package:bar/bar.dart')),
      );
      expect(targetDirectory, exists);
    },
  );

  testUsingContext(
    'Native assets build error',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();
      expect(
        () => runFlutterSpecificHooks(
          environmentDefines: <String, String>{kBuildMode: BuildMode.debug.cliName},
          targetPlatform: TargetPlatform.linux_x64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
            buildResult: null,
          ),
          buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
          buildDataAssets: true,
          recordedUsesFile: null,
        ),
        throwsToolExit(message: 'Building native assets failed. See the logs for more details.'),
      );
    },
  );

  testUsingContext(
    'Native assets: no duplicate assets with linking',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();

      final File directSoFile = environment.projectDir.childFile('direct.so');
      directSoFile.writeAsBytesSync(<int>[]);
      final File linkableAFile = environment.projectDir.childFile('linkable.a');
      linkableAFile.writeAsBytesSync(<int>[]);
      final File linkedSoFile = environment.projectDir.childFile('linked.so');
      linkedSoFile.writeAsBytesSync(<int>[]);

      CodeAsset makeCodeAsset(String name, Uri file, LinkMode linkMode) =>
          CodeAsset(package: 'bar', name: name, linkMode: linkMode, file: file);

      final DartHooksResult result = await runFlutterSpecificHooks(
        environmentDefines: <String, String>{
          // Release mode means the dart build has linking enabled.
          kBuildMode: BuildMode.release.cliName,
        },
        targetPlatform: TargetPlatform.linux_x64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: FakeFlutterNativeAssetsBuildRunner(
          packagesWithNativeAssetsResult: <String>['bar'],
          buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            codeAssets: <CodeAsset>[
              makeCodeAsset('direct', directSoFile.uri, DynamicLoadingBundled()),
            ],
            codeAssetsForLinking: <String, List<CodeAsset>>{
              'package:bar': <CodeAsset>[
                makeCodeAsset('linkable', linkableAFile.uri, StaticLinking()),
              ],
            },
          ),
          linkResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
            codeAssets: <CodeAsset>[
              makeCodeAsset('linked', linkedSoFile.uri, DynamicLoadingBundled()),
            ],
          ),
        ),
        buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
        buildDataAssets: true,
        recordedUsesFile: null,
      );
      expect(
        result.codeAssets.map((FlutterCodeAsset c) => c.codeAsset.file!.toString()).toList()
          ..sort(),
        <String>[directSoFile.uri.toString(), linkedSoFile.uri.toString()],
      );
    },
  );

  testUsingContext(
    'Native assets: duplicate assets throws tool exit listing duplicate IDs',
    overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
    () async {
      final File packageConfig = environment.projectDir.childFile('.dart_tool/package_config.json');
      await packageConfig.parent.create();
      await packageConfig.create();

      final File directSoFile = environment.projectDir.childFile('direct.so');
      directSoFile.writeAsBytesSync(<int>[]);

      CodeAsset makeCodeAsset(String name, Uri file, LinkMode linkMode) =>
          CodeAsset(package: 'bar', name: name, linkMode: linkMode, file: file);

      expect(
        () => runFlutterSpecificHooks(
          environmentDefines: <String, String>{kBuildMode: BuildMode.release.cliName},
          targetPlatform: TargetPlatform.linux_x64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
            buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(
              codeAssets: <CodeAsset>[
                makeCodeAsset('direct', directSoFile.uri, DynamicLoadingBundled()),
                makeCodeAsset('direct', directSoFile.uri, DynamicLoadingBundled()),
              ],
            ),
          ),
          buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
          buildDataAssets: true,
          recordedUsesFile: null,
        ),
        throwsToolExit(message: 'Found duplicates in the code assets: [package:bar/direct]'),
      );
    },
  );

  testUsingContext(
    'unit tests does not require compiler toolchain',
    overrides: <Type, Generator>{
      ProcessManager: () {
        const Platform platform = LocalPlatform();
        return FakeProcessManager.list([
          if (platform.isMacOS) ...[
            for (final binary in <String>['clang', 'ar', 'ld'])
              FakeCommand(
                command: <Pattern>['xcrun', '--find', binary],
                exitCode: 1,
                stderr: 'not found',
              ),
            for (final binary in <String>['clang', 'ar', 'ld'])
              FakeCommand(
                command: <Pattern>['xcrun', '--find', binary],
                exitCode: 1,
                stderr: 'not found',
              ),
          ],
          if (platform.isLinux) ...[
            const FakeCommand(
              command: <Pattern>['which', 'clang++'],
              exitCode: 1,
              stderr: 'not found',
            ),
            const FakeCommand(
              command: <Pattern>['which', 'clang++'],
              exitCode: 1,
              stderr: 'not found',
            ),
          ],
        ]);
      },
    },
    () async {
      // This calls setCCompilerConfig() on a test target, which must not throw despite the
      // toolchain not being available.
      const Platform platform = LocalPlatform();
      if (!platform.isLinux && !platform.isMacOS) {
        return false;
      }

      final target = _SetCCompilerConfigTarget(
        packagesWithNativeAssetsResult: <String>['bar'],
        buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
      );

      await runFlutterSpecificHooks(
        environmentDefines: {},
        targetPlatform: TargetPlatform.tester,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: target,
        buildCodeAssets: BuildCodeAssetsOptions(
          appBuildDirectory: fileSystem.directory(projectUri),
        ),
        buildDataAssets: true,
        recordedUsesFile: null,
      );

      expect(target.didSetCCompilerConfig, isTrue);
    },
  );

  testUsingContext(
    'linux build reads compilers from CMakeCache.txt',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.empty(),
      FileSystem: () => fileSystem,
    },
    () async {
      final target = _SetCCompilerConfigTarget(
        packagesWithNativeAssetsResult: <String>['bar'],
        buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(),
      );

      await fileSystem.directory('/usr/bin/').create(recursive: true);
      await fileSystem.file('/usr/bin/ld.ldd').create();
      await fileSystem.file('/usr/bin/llvm-ar').create();
      await fileSystem.file('/usr/bin/clang').create();
      await fileSystem.file('/usr/bin/clang++').create();

      final Directory project = fileSystem.directory(projectUri);
      await project.childDirectory('build/linux/arm64/release').create(recursive: true);
      await project.childFile('build/linux/arm64/release/CMakeCache.txt').writeAsString('''
CMAKE_CXX_COMPILER:FILEPATH=/usr/bin/clang++
CMAKE_AR:FILEPATH=/usr/bin/llvm-ar
CMAKE_LINKER:FILEPATH=/usr/bin/ld.ldd
''');

      await runFlutterSpecificHooks(
        environmentDefines: {kBuildMode: 'release'},
        targetPlatform: TargetPlatform.linux_arm64,
        projectUri: projectUri,
        fileSystem: fileSystem,
        buildRunner: target,
        buildCodeAssets: BuildCodeAssetsOptions(appBuildDirectory: project.childDirectory('build')),
        buildDataAssets: false,
        recordedUsesFile: null,
      );

      expect(target.didSetCCompilerConfig, isTrue);
    },
  );

  group('installCodeAssets deletion race', () {
    testUsingContext(
      'ignores errorCode 2 and 3 when deleting entities',
      overrides: <Type, Generator>{ProcessManager: () => FakeProcessManager.empty()},
      () async {
        final File packageConfig = environment.projectDir.childFile(
          '.dart_tool/package_config.json',
        );
        await packageConfig.parent.create();
        await packageConfig.create();

        final File directSoFile = environment.projectDir.childFile('direct.so');
        directSoFile.writeAsBytesSync(<int>[]);

        CodeAsset makeCodeAsset(String name, LinkMode linkMode, [Uri? file]) =>
            CodeAsset(package: 'bar', name: name, linkMode: linkMode, file: file);

        final environmentDefines = <String, String>{kBuildMode: BuildMode.release.cliName};
        final codeAssets = <CodeAsset>[
          makeCodeAsset('malloc', DynamicLoadingBundled(), directSoFile.uri),
        ];

        final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
          environmentDefines: environmentDefines,
          targetPlatform: TargetPlatform.linux_x64,
          projectUri: projectUri,
          fileSystem: fileSystem,
          buildRunner: FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
            buildResult: FakeFlutterNativeAssetsBuilderResult.fromAssets(codeAssets: codeAssets),
          ),
          buildCodeAssets: const BuildCodeAssetsOptions(appBuildDirectory: null),
          buildDataAssets: true,
          recordedUsesFile: null,
        );

        final errorFs2 = ErrorThrowingFileSystem(fileSystem, errorCodeToThrow: 2);
        final Uri nonFlutterTesterAssetUri = environment.buildDir
            .childFile('native_assets.json')
            .uri;
        final Directory targetDirectory = environment.buildDir.childDirectory('native_assets');

        // Populate targetDirectory with a file so entity.delete gets called.
        final File existingFile = targetDirectory.childFile('existing.so');
        await existingFile.create(recursive: true);

        // Should not throw since error code is 2
        await installCodeAssets(
          dartHookResult: dartHookResult,
          environmentDefines: environmentDefines,
          targetPlatform: TargetPlatform.linux_x64,
          projectUri: projectUri,
          fileSystem: errorFs2,
          nativeAssetsFileUri: nonFlutterTesterAssetUri,
          targetUri: targetDirectory.uri,
        );

        final errorFs3 = ErrorThrowingFileSystem(fileSystem, errorCodeToThrow: 3);
        await existingFile.create(recursive: true);
        // Should not throw since error code is 3
        await installCodeAssets(
          dartHookResult: dartHookResult,
          environmentDefines: environmentDefines,
          targetPlatform: TargetPlatform.linux_x64,
          projectUri: projectUri,
          fileSystem: errorFs3,
          nativeAssetsFileUri: nonFlutterTesterAssetUri,
          targetUri: targetDirectory.uri,
        );

        final errorFs5 = ErrorThrowingFileSystem(fileSystem, errorCodeToThrow: 5);
        await existingFile.create(recursive: true);
        // Should throw since error code is 5
        expect(
          () => installCodeAssets(
            dartHookResult: dartHookResult,
            environmentDefines: environmentDefines,
            targetPlatform: TargetPlatform.linux_x64,
            projectUri: projectUri,
            fileSystem: errorFs5,
            nativeAssetsFileUri: nonFlutterTesterAssetUri,
            targetUri: targetDirectory.uri,
          ),
          throwsA(isA<FileSystemException>()),
        );
      },
    );
  });
}

class _SetCCompilerConfigTarget extends FakeFlutterNativeAssetsBuildRunner {
  _SetCCompilerConfigTarget({super.buildResult, super.packagesWithNativeAssetsResult});

  bool didSetCCompilerConfig = false;

  @override
  Future<void> setCCompilerConfig(CodeAssetTarget target) async {
    await target.setCCompilerConfig();
    didSetCCompilerConfig = true;
  }
}

class ErrorThrowingFileSystem extends ForwardingFileSystem {
  ErrorThrowingFileSystem(super.delegate, {required this.errorCodeToThrow});

  final int errorCodeToThrow;

  @override
  Directory directory(dynamic path) {
    return ErrorThrowingDirectory(
      this,
      delegate.directory(path),
      errorCodeToThrow: errorCodeToThrow,
    );
  }
}

class ErrorThrowingDirectory extends ForwardingFileSystemEntity<Directory, io.Directory>
    with ForwardingDirectory<Directory> {
  ErrorThrowingDirectory(this._fileSystem, this.delegate, {required this.errorCodeToThrow});

  final ErrorThrowingFileSystem _fileSystem;

  @override
  final io.Directory delegate;

  final int errorCodeToThrow;

  @override
  FileSystem get fileSystem => _fileSystem;

  @override
  Directory childDirectory(String basename) {
    return fileSystem.directory(fileSystem.path.join(path, basename));
  }

  @override
  File childFile(String basename) {
    return fileSystem.file(fileSystem.path.join(path, basename));
  }

  @override
  Link childLink(String basename) {
    return fileSystem.link(fileSystem.path.join(path, basename));
  }

  @override
  Directory wrapDirectory(io.Directory delegate) =>
      ErrorThrowingDirectory(_fileSystem, delegate, errorCodeToThrow: errorCodeToThrow);

  @override
  File wrapFile(io.File delegate) =>
      ErrorThrowingFile(_fileSystem, delegate, errorCodeToThrow: errorCodeToThrow);

  @override
  Link wrapLink(io.Link delegate) => delegate as Link;

  @override
  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) {
    return delegate.list(recursive: recursive, followLinks: followLinks).map((
      io.FileSystemEntity entity,
    ) {
      if (entity is io.File) {
        return ErrorThrowingFile(_fileSystem, entity, errorCodeToThrow: errorCodeToThrow);
      }
      if (entity is io.Directory) {
        return ErrorThrowingDirectory(_fileSystem, entity, errorCodeToThrow: errorCodeToThrow);
      }
      throw UnimplementedError('Link not supported');
    });
  }
}

class ErrorThrowingFile extends ForwardingFileSystemEntity<File, io.File> with ForwardingFile {
  ErrorThrowingFile(this._fileSystem, this.delegate, {required this.errorCodeToThrow});

  final ErrorThrowingFileSystem _fileSystem;

  @override
  final io.File delegate;

  final int errorCodeToThrow;

  @override
  FileSystem get fileSystem => _fileSystem;

  @override
  File wrapFile(io.File delegate) =>
      ErrorThrowingFile(_fileSystem, delegate, errorCodeToThrow: errorCodeToThrow);

  @override
  Directory wrapDirectory(io.Directory delegate) => delegate as Directory;

  @override
  Link wrapLink(io.Link delegate) => delegate as Link;

  @override
  Future<File> delete({bool recursive = false}) async {
    throw FileSystemException(
      'Mock deletion error',
      path,
      io.OSError('Mock OS Error', errorCodeToThrow),
    );
  }
}
