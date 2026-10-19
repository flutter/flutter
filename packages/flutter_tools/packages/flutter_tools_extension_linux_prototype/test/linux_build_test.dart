// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/src/build.dart';
import 'package:test/test.dart';

void main() {
  group('LinuxBuildService', () {
    test('buildTargets and assembleTargets return prototype Linux targets', () {
      final service = LinuxBuildService();
      final LinuxBuildService(
        :List<BuildTarget> buildTargets,
        :List<AssembleTarget> assembleTargets,
      ) = service;

      expect(
        buildTargets.map((BuildTarget t) => t.name),
        equals(<String>[LinuxBuildService.customLinuxBuildTargetName]),
      );
      expect(
        assembleTargets.map((AssembleTarget t) => t.name),
        equals(<String>['custom-linux-assemble-only-debug']),
      );
    });

    test(
      'initialize registers getBuildTargets, getAssembleTargets, build, and assemble RPC handlers',
      () async {
        final service = LinuxBuildService();
        expect(service.namespace, BuildService.serviceNamespace);

        final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
        expect(
          handlers.keys,
          containsAll(<String>['getBuildTargets', 'getAssembleTargets', 'build', 'assemble']),
        );

        final Object? buildTargetsResult = await handlers['getBuildTargets']!(
          const <String, Object?>{},
        );
        final List<ExtensionBuildTarget> buildTargets = ExtensionBuildTarget.listFromJson(
          buildTargetsResult,
        );
        expect(buildTargets, hasLength(1));
        expect(buildTargets.single.name, LinuxBuildService.customLinuxBuildTargetName);
        expect(
          buildTargets.single.artifacts,
          equals(const <ExtensionArtifact>{
            LinuxArtifacts.linuxHeaders,
            LinuxArtifacts.linuxDesktopPath,
            BuiltInArtifacts.icuData,
          }),
        );

        final Object? assembleTargetsResult = await handlers['getAssembleTargets']!(
          const <String, Object?>{},
        );
        final List<ExtensionAssembleTarget> assembleTargets = ExtensionAssembleTarget.listFromJson(
          assembleTargetsResult,
        );
        expect(assembleTargets, hasLength(1));
        expect(assembleTargets.single.name, 'custom-linux-assemble-only-debug');

        final Object? missingCmakeResultObj = await handlers['build']!(<String, Object?>{
          BuildService.buildDirParam: '/project/.dart_tool/flutter_build',
          BuildService.buildModeParam: 'debug',
          BuildService.flutterRootParam: '/flutter',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
          BuildService.projectRootParam: '/project',
          BuildService.resolvedArtifactsParam: const <String, String>{},
          BuildService.targetNameParam: LinuxBuildService.customLinuxBuildTargetName,
        });
        final missingCmakeResult = ExtensionBuildResult.fromJson(
          missingCmakeResultObj! as Map<String, Object?>,
        );
        expect(missingCmakeResult.success, isFalse);
        expect(missingCmakeResult.errorMessage, contains('Missing linux/CMakeLists.txt'));

        final Object? unknownBuildTargetResultObj = await handlers['build']!(<String, Object?>{
          BuildService.buildDirParam: '/project/.dart_tool/flutter_build',
          BuildService.buildModeParam: 'debug',
          BuildService.flutterRootParam: '/flutter',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
          BuildService.projectRootParam: '/project',
          BuildService.resolvedArtifactsParam: const <String, String>{},
          BuildService.targetNameParam: 'unknown-target',
        });
        final unknownBuildResult = ExtensionBuildResult.fromJson(
          unknownBuildTargetResultObj! as Map<String, Object?>,
        );
        expect(unknownBuildResult.success, isFalse);
        expect(unknownBuildResult.errorMessage, contains('Unknown build target: unknown-target'));

        final Object? unknownAssembleTargetResultObj = await handlers['assemble']!(
          <String, Object?>{
            BuildService.buildDirParam: '/project/.dart_tool/flutter_build',
            BuildService.buildModeParam: 'debug',
            BuildService.flutterRootParam: '/flutter',
            BuildService.mainPathParam: 'lib/main.dart',
            BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
            BuildService.projectRootParam: '/project',
            BuildService.resolvedArtifactsParam: const <String, String>{},
            BuildService.targetNameParam: 'unknown-assemble-target',
          },
        );
        final unknownAssembleResult = ExtensionBuildResult.fromJson(
          unknownAssembleTargetResultObj! as Map<String, Object?>,
        );
        expect(unknownAssembleResult.success, isFalse);
        expect(
          unknownAssembleResult.errorMessage,
          contains('Unknown assemble target: unknown-assemble-target'),
        );

        await service.shutdown();
      },
    );

    test('CustomLinuxAssembleOnlyDebug copies artifacts and application binary', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_build_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final buildDir = Directory('${tempDir.path}/build_dir')..createSync(recursive: true);
      final outputDir = Directory('${tempDir.path}/output_dir')..createSync(recursive: true);
      final desktopDir = Directory('${tempDir.path}/desktop')..createSync(recursive: true);
      File('${desktopDir.path}/libflutter_linux_gtk.so').writeAsStringSync('gtk');
      final icuFile = File('${tempDir.path}/icudtl.dat')..writeAsStringSync('icu');
      File('${buildDir.path}/app.dill').writeAsStringSync('dill');
      final assetsDir = Directory('${buildDir.path}/flutter_assets')..createSync(recursive: true);
      File('${assetsDir.path}/AssetManifest.bin').writeAsStringSync('manifest');

      const target = CustomLinuxAssembleOnlyDebug();
      final ExtensionBuildResult result = await target.build(
        ExtensionBuildContext(
          buildDir: buildDir.uri,
          buildMode: .debug,
          flutterRoot: tempDir.uri,
          mainPath: 'lib/main.dart',
          outputDir: outputDir.uri,
          projectRoot: tempDir.uri,
          resolvedArtifacts: <String, String>{
            LinuxArtifacts.linuxDesktopPath.name: desktopDir.path,
            BuiltInArtifacts.icuData.name: icuFile.path,
          },
        ),
      );

      expect(result.success, isTrue);
      expect(File('${outputDir.path}/bundle/lib/libflutter_linux_gtk.so').existsSync(), isTrue);
      expect(File('${outputDir.path}/bundle/data/icudtl.dat').existsSync(), isTrue);
      expect(
        File('${outputDir.path}/bundle/data/flutter_assets/kernel_blob.bin').existsSync(),
        isTrue,
      );
      expect(
        File('${outputDir.path}/bundle/data/flutter_assets/AssetManifest.bin').existsSync(),
        isTrue,
      );
    });

    test('CustomLinuxAssembleOnlyDebug fails when required artifacts are missing', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_build_test_missing.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      const target = CustomLinuxAssembleOnlyDebug();
      final ExtensionBuildResult result = await target.build(
        ExtensionBuildContext(
          buildDir: tempDir.uri,
          buildMode: .debug,
          flutterRoot: tempDir.uri,
          mainPath: 'lib/main.dart',
          outputDir: tempDir.uri,
          projectRoot: tempDir.uri,
          resolvedArtifacts: const <String, String>{},
        ),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Missing linuxDesktopPath artifact.'));
    });

    test('_copyDirectory preserves symbolic links', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync('linux_build_symlink_test.');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final targetFile = File('${tempDir.path}/target.txt')..writeAsStringSync('target content');

      final buildDir = Directory('${tempDir.path}/build_dir')..createSync(recursive: true);
      final assetsDir = Directory('${buildDir.path}/flutter_assets')..createSync(recursive: true);
      File('${assetsDir.path}/AssetManifest.bin').writeAsStringSync('manifest');
      Link('${assetsDir.path}/symlink_asset.bin').createSync(targetFile.path);

      final desktopDir = Directory('${tempDir.path}/desktop')..createSync(recursive: true);
      File('${desktopDir.path}/libflutter_linux_gtk.so').writeAsStringSync('gtk');
      final icuFile = File('${tempDir.path}/icudtl.dat')..writeAsStringSync('icu');
      File('${buildDir.path}/app.dill').writeAsStringSync('dill');

      final outputDir = Directory('${tempDir.path}/output_dir')..createSync(recursive: true);

      const target = CustomLinuxAssembleOnlyDebug();
      final ExtensionBuildResult result = await target.build(
        ExtensionBuildContext(
          buildDir: buildDir.uri,
          buildMode: .debug,
          flutterRoot: tempDir.uri,
          mainPath: 'lib/main.dart',
          outputDir: outputDir.uri,
          projectRoot: tempDir.uri,
          resolvedArtifacts: <String, String>{
            LinuxArtifacts.linuxDesktopPath.name: desktopDir.path,
            BuiltInArtifacts.icuData.name: icuFile.path,
          },
        ),
      );

      expect(result.success, isTrue);
      final copiedLink = Link('${outputDir.path}/bundle/data/flutter_assets/symlink_asset.bin');
      expect(copiedLink.existsSync(), isTrue);
      expect(copiedLink.targetSync(), equals(targetFile.path));
    });

    group('build RPC parameter validation', () {
      const validParams = <String, Object?>{
        BuildService.targetNameParam: 'custom-linux-build',
        BuildService.projectRootParam: '/project',
        BuildService.mainPathParam: 'lib/main.dart',
        BuildService.buildModeParam: 'debug',
        BuildService.flutterRootParam: '/flutter',
        BuildService.outputDirParam: '/out',
        BuildService.buildDirParam: '/build',
        BuildService.resolvedArtifactsParam: <String, String>{},
      };

      final invalidCases =
          <(String description, Map<String, Object?> overrides, String expectedParam)>[
            (
              'missing targetName',
              <String, Object?>{BuildService.targetNameParam: null},
              BuildService.targetNameParam,
            ),
            (
              'missing projectRoot',
              <String, Object?>{BuildService.projectRootParam: null},
              BuildService.projectRootParam,
            ),
            (
              'relative projectRoot',
              <String, Object?>{BuildService.projectRootParam: 'relative/path'},
              BuildService.projectRootParam,
            ),
            (
              'missing flutterRoot',
              <String, Object?>{BuildService.flutterRootParam: null},
              BuildService.flutterRootParam,
            ),
            (
              'relative flutterRoot',
              <String, Object?>{BuildService.flutterRootParam: 'relative/flutter'},
              BuildService.flutterRootParam,
            ),
            (
              'missing mainPath',
              <String, Object?>{BuildService.mainPathParam: null},
              BuildService.mainPathParam,
            ),
            (
              'missing buildMode',
              <String, Object?>{BuildService.buildModeParam: null},
              BuildService.buildModeParam,
            ),
            (
              'invalid buildMode',
              <String, Object?>{BuildService.buildModeParam: 'invalid_mode'},
              BuildService.buildModeParam,
            ),
            (
              'missing outputDir',
              <String, Object?>{BuildService.outputDirParam: null},
              BuildService.outputDirParam,
            ),
            (
              'relative outputDir',
              <String, Object?>{BuildService.outputDirParam: 'relative/output'},
              BuildService.outputDirParam,
            ),
            (
              'missing buildDir',
              <String, Object?>{BuildService.buildDirParam: null},
              BuildService.buildDirParam,
            ),
            (
              'relative buildDir',
              <String, Object?>{BuildService.buildDirParam: 'relative/build'},
              BuildService.buildDirParam,
            ),
            (
              'missing resolvedArtifacts',
              <String, Object?>{BuildService.resolvedArtifactsParam: null},
              BuildService.resolvedArtifactsParam,
            ),
            (
              'non-string resolvedArtifacts value',
              <String, Object?>{
                BuildService.resolvedArtifactsParam: <String, Object?>{'genSnapshot': 123},
              },
              BuildService.resolvedArtifactsParam,
            ),
          ];

      for (final (String description, Map<String, Object?> overrides, String expectedParam)
          in invalidCases) {
        test('throws RpcException on $description for build and assemble', () async {
          final service = LinuxBuildService();
          final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
          final ExtensionRpcHandler buildHandler = handlers['build']!;
          final ExtensionRpcHandler assembleHandler = handlers['assemble']!;

          for (final handler in <ExtensionRpcHandler>[buildHandler, assembleHandler]) {
            await expectLater(
              () => handler(<String, Object?>{...validParams, ...overrides}),
              throwsA(
                isA<Exception>().having(
                  (Exception e) => e.toString(),
                  'toString',
                  allOf(
                    contains('-32602'),
                    contains('Missing or invalid "$expectedParam" parameter.'),
                  ),
                ),
              ),
            );
          }
        });
      }
    });
  });
}
