// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/isolated/native_assets/dart_hook_result.dart';
import 'package:flutter_tools/src/isolated/native_assets/macos/native_assets_host.dart'
    show cCompilerConfigMacOS;
import 'package:flutter_tools/src/isolated/native_assets/native_assets.dart';
import 'package:hooks/hooks.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../fake_native_assets_build_runner.dart';

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
    );
    environment.buildDir.createSync(recursive: true);
    projectUri = environment.projectDir.uri;
  });

  for (final flutterTester in <bool>[false, true]) {
    final isArm64 = Architecture.current == Architecture.arm64;

    var testName = '';
    if (flutterTester) {
      testName += ' flutter tester';
    }
    final String dylibPathBar;
    final String signPathBar;
    final String dylibPathBuz;
    final String signPathBuz;

    if (flutterTester) {
      // Just the dylib.
      dylibPathBar = '/build/native_assets/macos/libbar.dylib';
      signPathBar = '/build/native_assets/macos/libbar.dylib';
      dylibPathBuz = '/build/native_assets/macos/libbuz.dylib';
      signPathBuz = '/build/native_assets/macos/libbuz.dylib';
    } else {
      // Packaged in framework.
      dylibPathBar = '/build/native_assets/macos/bar.framework/Versions/A/bar';
      signPathBar = '/build/native_assets/macos/bar.framework';
      dylibPathBuz = '/build/native_assets/macos/buz.framework/Versions/A/buz';
      signPathBuz = '/build/native_assets/macos/buz.framework';
    }
    for (final buildMode in <BuildMode>[BuildMode.debug, if (!flutterTester) BuildMode.release]) {
      testUsingContext(
        'build with assets $buildMode$testName',
        overrides: <Type, Generator>{
          ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
            if (flutterTester) ...<FakeCommand>[
              FakeCommand(
                command: <Pattern>[
                  'lipo',
                  '-create',
                  '-output',
                  dylibPathBar,
                  '${isArm64 ? 'arm64' : 'x64'}/libbar.dylib',
                ],
              ),
              FakeCommand(
                command: <Pattern>['otool', '-D', dylibPathBar],
                stdout: <String>[
                  '$dylibPathBar (architecture x86_64):',
                  '@rpath/libbar.dylib',
                  '$dylibPathBar (architecture arm64):',
                  '@rpath/libbar.dylib',
                ].join('\n'),
              ),
              FakeCommand(
                command: <Pattern>[
                  'lipo',
                  '-create',
                  '-output',
                  dylibPathBuz,
                  '${isArm64 ? 'arm64' : 'x64'}/libbuz.dylib',
                ],
              ),
              FakeCommand(
                command: <Pattern>['otool', '-D', dylibPathBuz],
                stdout: <String>[
                  '$dylibPathBuz (architecture ${isArm64 ? 'arm64' : 'x86_64'}):',
                  '@rpath/libbuz.dylib',
                ].join('\n'),
              ),
              FakeCommand(
                command: <Pattern>[
                  'install_name_tool',
                  '-id',
                  dylibPathBar,
                  '-change',
                  '@rpath/libbar.dylib',
                  dylibPathBar,
                  '-change',
                  '@rpath/libbuz.dylib',
                  dylibPathBuz,
                  dylibPathBar,
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'codesign',
                  '--force',
                  '--sign',
                  '-',
                  if (buildMode == BuildMode.debug) '--timestamp=none',
                  signPathBar,
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'install_name_tool',
                  '-id',
                  dylibPathBuz,
                  '-change',
                  '@rpath/libbar.dylib',
                  dylibPathBar,
                  '-change',
                  '@rpath/libbuz.dylib',
                  signPathBuz,
                  signPathBuz,
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'codesign',
                  '--force',
                  '--sign',
                  '-',
                  if (buildMode == BuildMode.debug) '--timestamp=none',
                  signPathBuz,
                ],
              ),
            ] else ...<FakeCommand>[
              FakeCommand(
                command: <Pattern>[
                  'lipo',
                  '-create',
                  '-output',
                  dylibPathBar,
                  'arm64/libbar.dylib',
                  'x64/libbar.dylib',
                ],
              ),
              FakeCommand(
                command: <Pattern>['otool', '-D', dylibPathBar],
                stdout: <String>[
                  '$dylibPathBar (architecture x86_64):',
                  '@rpath/libbar.dylib',
                  '$dylibPathBar (architecture arm64):',
                  '@rpath/libbar.dylib',
                ].join('\n'),
              ),
              FakeCommand(
                command: <Pattern>[
                  'lipo',
                  '-create',
                  '-output',
                  dylibPathBuz,
                  'arm64/libbuz.dylib',
                  'x64/libbuz.dylib',
                ],
              ),
              FakeCommand(
                command: <Pattern>['otool', '-D', dylibPathBuz],
                stdout: <String>[
                  '$dylibPathBuz (architecture x86_64):',
                  '@rpath/libbuz.dylib',
                  '$dylibPathBuz (architecture arm64):',
                  '@rpath/libbuz.dylib',
                ].join('\n'),
              ),
              FakeCommand(
                command: <Pattern>[
                  'install_name_tool',
                  '-id',
                  '@rpath/bar.framework/bar',
                  '-change',
                  '@rpath/libbar.dylib',
                  '@rpath/bar.framework/bar',
                  '-change',
                  '@rpath/libbuz.dylib',
                  '@rpath/buz.framework/buz',
                  dylibPathBar,
                ],
              ),
              FakeCommand(
                command: <Pattern>[
                  'install_name_tool',
                  '-id',
                  '@rpath/buz.framework/buz',
                  '-change',
                  '@rpath/libbar.dylib',
                  '@rpath/bar.framework/bar',
                  '-change',
                  '@rpath/libbuz.dylib',
                  '@rpath/buz.framework/buz',
                  dylibPathBuz,
                ],
              ),
            ],
          ]),
        },
        () async {
          if (const LocalPlatform().isWindows) {
            return; // Backslashes in commands, but we will never run these commands on Windows.
          }
          if (flutterTester && !const LocalPlatform().isMacOS) {
            // The [runFlutterSpecificDartBuild] will - when given
            // `TargetPlatform.tester` - enable `flutter test` mode. That means if
            // this test is run on linux, it's going to do a linux build.
            // Though this test is mac-specific, so we skip that.
            //
            // Running the test in `!flutterTester` mode still works on linux as
            // we explicitly tell it to do a mac build (instead of letting it
            // choose the local build).
            return;
          }
          final File packageConfig = environment.projectDir.childFile(
            '.dart_tool/package_config.json',
          );
          final Uri nonFlutterTesterAssetUri = environment.buildDir
              .childFile(InstallCodeAssets.nativeAssetsFilename)
              .uri;
          await packageConfig.parent.create();
          await packageConfig.create();

          List<CodeAsset> codeAssets(OS targetOS, CodeConfig codeConfig) => <CodeAsset>[
            CodeAsset(
              package: 'bar',
              name: 'bar.dart',
              linkMode: DynamicLoadingBundled(),
              file: Uri.file('${codeConfig.targetArchitecture}/libbar.dylib'),
            ),
            CodeAsset(
              package: 'buz',
              name: 'buz.dart',
              linkMode: DynamicLoadingBundled(),
              file: Uri.file('${codeConfig.targetArchitecture}/libbuz.dylib'),
            ),
          ];
          final buildRunner = FakeFlutterNativeAssetsBuildRunner(
            packagesWithNativeAssetsResult: <String>['bar'],
            onBuild: (BuildInput input) => FakeFlutterNativeAssetsBuilderResult.fromAssets(
              codeAssets: buildMode == BuildMode.debug
                  ? codeAssets(input.config.code.targetOS, input.config.code)
                  : <CodeAsset>[],
            ),
            onLink: (LinkInput input) => buildMode == BuildMode.debug
                ? null
                : FakeFlutterNativeAssetsBuilderResult.fromAssets(
                    codeAssets: codeAssets(input.config.code.targetOS, input.config.code),
                  ),
          );
          final environmentDefines = <String, String>{
            kBuildMode: buildMode.cliName,
            kDarwinArchs: 'arm64 x86_64',
          };
          final TargetPlatform targetPlatform = flutterTester
              ? TargetPlatform.tester
              : TargetPlatform.darwin;
          final DartHooksResult dartHookResult = await runFlutterSpecificHooks(
            environmentDefines: environmentDefines,
            targetPlatform: targetPlatform,
            projectUri: projectUri,
            fileSystem: fileSystem,
            buildRunner: buildRunner,
          );
          final Uri nativeAssetsFileUri = flutterTester
              ? projectUri.resolve(
                  'build/native_assets/macos/${InstallCodeAssets.nativeAssetsFilename}',
                )
              : nonFlutterTesterAssetUri;

          await installCodeAssets(
            dartHookResult: dartHookResult,
            environmentDefines: environmentDefines,
            targetPlatform: targetPlatform,
            projectUri: projectUri,
            fileSystem: fileSystem,
            nativeAssetsFileUri: nativeAssetsFileUri,
          );
          final expectedArchsBeingBuilt = flutterTester
              ? (isArm64 ? 'macos_arm64' : 'macos_x64')
              : 'macos_arm64, macos_x64';
          expect(
            (globals.logger as BufferLogger).traceText,
            stringContainsInOrder(<String>[
              'Building native assets for $expectedArchsBeingBuilt.',
              'Building native assets for $expectedArchsBeingBuilt done.',
            ]),
          );
          final String nativeAssetsFileContent = await fileSystem
              .file(nativeAssetsFileUri)
              .readAsString();
          expect(
            nativeAssetsFileContent,
            stringContainsInOrder(<String>[
              'package:bar/bar.dart',
              if (flutterTester)
                // Tests run on host system, so the have the full path on the system.
                projectUri.resolve('build/native_assets/macos/libbar.dylib').toFilePath()
              else
                // Apps are a bundle with the dylibs on their dlopen path.
                'bar.framework/bar',
            ]),
          );
          expect(
            nativeAssetsFileContent,
            stringContainsInOrder(<String>[
              'package:buz/buz.dart',
              if (flutterTester)
                // Tests run on host system, so the have the full path on the system.
                projectUri.resolve('build/native_assets/macos/libbuz.dylib').toFilePath()
              else
                // Apps are a bundle with the dylibs on their dlopen path.
                'buz.framework/buz',
            ]),
          );
          // Multi arch.
          expect(buildRunner.buildInvocations, flutterTester ? 1 : 2);
          expect(buildRunner.linkInvocations, buildMode == BuildMode.release ? 2 : 0);
        },
      );
    }
  }

  // This logic is mocked in the other tests to avoid having test order
  // randomization causing issues with what processes are invoked.
  // Exercise the parsing of the process output in this separate test.
  testUsingContext(
    'NativeAssetsBuildRunnerImpl.cCompilerConfig normal installation',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        for (final binary in <String>['clang', 'ar', 'ld'])
          FakeCommand(
            command: <Pattern>['xcrun', '--find', binary],
            stdout:
                '''
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/$binary
''', // NOTE: explicitly test needing to trim new line
          ),
      ]),
    },
    () async {
      if (!const LocalPlatform().isMacOS) {
        return;
      }

      final CCompilerConfig result = await cCompilerConfigMacOS();
      expect(
        result.compiler,
        Uri.file(
          '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang',
        ),
      );
      expect(
        result.archiver,
        Uri.file(
          '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar',
        ),
      );
      expect(
        result.linker,
        Uri.file(
          '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld',
        ),
      );
    },
  );

  testUsingContext(
    'NativeAssetsBuildRunnerImpl.cCompilerConfig Nix installation',
    overrides: <Type, Generator>{
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
        for (final binary in <String>['clang', 'ar', 'ld'])
          FakeCommand(
            command: <Pattern>['xcrun', '--find', binary],
            stdout: '/nix/store/random-path-to-clang-wrapper/bin/$binary',
          ),
      ]),
    },
    () async {
      if (!const LocalPlatform().isMacOS) {
        return;
      }

      final CCompilerConfig result = await cCompilerConfigMacOS();
      expect(result.compiler, Uri.file('/nix/store/random-path-to-clang-wrapper/bin/clang'));
      expect(result.archiver, Uri.file('/nix/store/random-path-to-clang-wrapper/bin/ar'));
      expect(result.linker, Uri.file('/nix/store/random-path-to-clang-wrapper/bin/ld'));
    },
  );
}
