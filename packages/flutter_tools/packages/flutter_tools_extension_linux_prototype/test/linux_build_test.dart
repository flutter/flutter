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
          buildTargets.single.outputDir,
          '${BuiltInPlaceholders.outputDir}/linux_extension/x64/${BuiltInPlaceholders.buildMode}',
        );
        expect(
          buildTargets.single.artifacts,
          equals(const <ExtensionArtifact>{
            LinuxArtifacts.linuxHeaders,
            LinuxArtifacts.linuxDesktopPath,
            BuiltInArtifacts.icuData,
          }),
        );
        expect(
          buildTargets.single.flags.map((ExtensionFlag f) => f.name),
          contains(CustomLinuxBuildTarget.bundleMetadataFlag),
        );
        expect(
          buildTargets.single.options.map((ExtensionOption o) => o.name),
          contains(CustomLinuxBuildTarget.bundleLabelOption),
        );
        expect(buildTargets.single.targetPlatforms, equals(const <String>{'linux-x64'}));

        final Object? assembleTargetsResult = await handlers['getAssembleTargets']!(
          const <String, Object?>{},
        );
        final List<ExtensionAssembleTarget> assembleTargets = ExtensionAssembleTarget.listFromJson(
          assembleTargetsResult,
        );
        expect(assembleTargets, hasLength(1));
        expect(assembleTargets.single.name, 'custom-linux-assemble-only-debug');

        await expectLater(
          () => handlers['build']!(<String, Object?>{
            BuildService.buildModeParam: 'debug',
            BuildService.dartObfuscationParam: false,
            BuildService.flutterRootParam: '/flutter',
            BuildService.mainPathParam: '/project/lib/main.dart',
            BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
            BuildService.projectRootParam: '/project',
            BuildService.resolvedArtifactsParam: const <String, String>{},
            BuildService.targetNameParam: LinuxBuildService.customLinuxBuildTargetName,
            BuildService.trackWidgetCreationParam: true,
            BuildService.treeShakeIconsParam: false,
          }),
          throwsA(
            isA<ToolExtensionException>().having(
              (ToolExtensionException e) => e.message,
              'message',
              contains('Missing linux/CMakeLists.txt'),
            ),
          ),
        );

        await expectLater(
          () => handlers['build']!(<String, Object?>{
            BuildService.buildModeParam: 'debug',
            BuildService.dartObfuscationParam: false,
            BuildService.flutterRootParam: '/flutter',
            BuildService.mainPathParam: '/project/lib/main.dart',
            BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
            BuildService.projectRootParam: '/project',
            BuildService.resolvedArtifactsParam: const <String, String>{},
            BuildService.targetNameParam: 'unknown-target',
            BuildService.trackWidgetCreationParam: true,
            BuildService.treeShakeIconsParam: false,
          }),
          throwsA(
            isA<ToolExtensionException>().having(
              (ToolExtensionException e) => e.message,
              'message',
              contains('Unknown build target: unknown-target'),
            ),
          ),
        );

        await expectLater(
          () => handlers['assemble']!(<String, Object?>{
            BuildService.buildDirParam: '/project/.dart_tool/flutter_build',
            BuildService.buildModeParam: 'debug',
            BuildService.dartObfuscationParam: false,
            BuildService.flutterRootParam: '/flutter',
            BuildService.mainPathParam: '/project/lib/main.dart',
            BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
            BuildService.projectRootParam: '/project',
            BuildService.resolvedArtifactsParam: const <String, String>{},
            BuildService.targetNameParam: 'unknown-assemble-target',
            BuildService.trackWidgetCreationParam: true,
            BuildService.treeShakeIconsParam: false,
          }),
          throwsA(
            isA<ToolExtensionException>().having(
              (ToolExtensionException e) => e.message,
              'message',
              contains('Unknown assemble target: unknown-assemble-target'),
            ),
          ),
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
      await target.build(
        ExtensionAssembleContext(
          buildDir: buildDir.uri,
          buildMode: .debug,
          flutterRoot: tempDir.uri,
          mainPath: '${tempDir.path}/lib/main.dart',
          outputDir: outputDir.uri,
          projectRoot: tempDir.uri,
          resolvedArtifacts: <String, String>{
            LinuxArtifacts.linuxDesktopPath.name: desktopDir.path,
            BuiltInArtifacts.icuData.name: icuFile.path,
          },
          trackWidgetCreation: true,
          treeShakeIcons: false,
        ),
      );

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
      await expectLater(
        () => target.build(
          ExtensionAssembleContext(
            buildDir: tempDir.uri,
            buildMode: .debug,
            flutterRoot: tempDir.uri,
            mainPath: '${tempDir.path}/lib/main.dart',
            outputDir: tempDir.uri,
            projectRoot: tempDir.uri,
            resolvedArtifacts: const <String, String>{},
            trackWidgetCreation: true,
            treeShakeIcons: false,
          ),
        ),
        throwsA(
          isA<ToolExtensionException>().having(
            (ToolExtensionException e) => e.message,
            'message',
            contains('Missing linuxDesktopPath artifact.'),
          ),
        ),
      );
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
      await target.build(
        ExtensionAssembleContext(
          buildDir: buildDir.uri,
          buildMode: .debug,
          flutterRoot: tempDir.uri,
          mainPath: '${tempDir.path}/lib/main.dart',
          outputDir: outputDir.uri,
          projectRoot: tempDir.uri,
          resolvedArtifacts: <String, String>{
            LinuxArtifacts.linuxDesktopPath.name: desktopDir.path,
            BuiltInArtifacts.icuData.name: icuFile.path,
          },
          trackWidgetCreation: true,
          treeShakeIcons: false,
        ),
      );

      final copiedLink = Link('${outputDir.path}/bundle/data/flutter_assets/symlink_asset.bin');
      expect(copiedLink.existsSync(), isTrue);
      expect(copiedLink.targetSync(), equals(targetFile.path));
    });

    group('build RPC parameter validation', () {
      const validParams = <String, Object?>{
        BuildService.targetNameParam: 'custom-linux-build',
        BuildService.projectRootParam: '/project',
        BuildService.mainPathParam: '/project/lib/main.dart',
        BuildService.buildModeParam: 'debug',
        BuildService.dartObfuscationParam: false,
        BuildService.flutterRootParam: '/flutter',
        BuildService.outputDirParam: '/out',
        BuildService.buildDirParam: '/build',
        BuildService.resolvedArtifactsParam: <String, String>{},
        BuildService.trackWidgetCreationParam: true,
        BuildService.treeShakeIconsParam: false,
      };

      final commonInvalidCases = <(String description, Map<String, Object?> overrides, String expectedMessage)>[
        (
          'invalid codeSizeDirectory URI',
          <String, Object?>{
            BuildService.codeSizeDirectoryParam: 'file:///project/code_size_no_slash',
          },
          'Invalid "${BuildService.codeSizeDirectoryParam}": expected trailing-slash-terminated absolute file: URI',
        ),
        (
          'invalid splitDebugInfo URI',
          <String, Object?>{BuildService.splitDebugInfoParam: 'relative/symbols/'},
          'Invalid "${BuildService.splitDebugInfoParam}": expected trailing-slash-terminated absolute file: URI',
        ),
        (
          'missing targetName',
          <String, Object?>{BuildService.targetNameParam: null},
          'Missing required "${BuildService.targetNameParam}" (expected String).',
        ),
        (
          'missing projectRoot',
          <String, Object?>{BuildService.projectRootParam: null},
          'Missing required "${BuildService.projectRootParam}" (expected String).',
        ),
        (
          'relative projectRoot',
          <String, Object?>{BuildService.projectRootParam: 'relative/path'},
          'Missing or invalid "${BuildService.projectRootParam}" parameter.',
        ),
        (
          'missing flutterRoot',
          <String, Object?>{BuildService.flutterRootParam: null},
          'Missing required "${BuildService.flutterRootParam}" (expected String).',
        ),
        (
          'relative flutterRoot',
          <String, Object?>{BuildService.flutterRootParam: 'relative/flutter'},
          'Missing or invalid "${BuildService.flutterRootParam}" parameter.',
        ),
        (
          'missing mainPath',
          <String, Object?>{BuildService.mainPathParam: null},
          'Missing required "${BuildService.mainPathParam}" (expected String).',
        ),
        (
          'missing buildMode',
          <String, Object?>{BuildService.buildModeParam: null},
          'Missing required "${BuildService.buildModeParam}" (expected String).',
        ),
        (
          'invalid buildMode',
          <String, Object?>{BuildService.buildModeParam: 'invalid_mode'},
          'Missing or invalid "${BuildService.buildModeParam}" parameter.',
        ),
        (
          'missing outputDir',
          <String, Object?>{BuildService.outputDirParam: null},
          'Missing required "${BuildService.outputDirParam}" (expected String).',
        ),
        (
          'relative outputDir',
          <String, Object?>{BuildService.outputDirParam: 'relative/output'},
          'Missing or invalid "${BuildService.outputDirParam}" parameter.',
        ),
        (
          'missing resolvedArtifacts',
          <String, Object?>{BuildService.resolvedArtifactsParam: null},
          'Missing required "${BuildService.resolvedArtifactsParam}" (expected Map<String, Object?>).',
        ),
        (
          'non-string resolvedArtifacts value',
          <String, Object?>{
            BuildService.resolvedArtifactsParam: <String, Object?>{'genSnapshot': 123},
          },
          'Invalid "${BuildService.resolvedArtifactsParam}" parameter: Invalid "genSnapshot": expected String, got int.',
        ),
      ];

      for (final (String description, Map<String, Object?> overrides, String expectedMessage)
          in commonInvalidCases) {
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
                  allOf(contains('-32602'), contains(expectedMessage)),
                ),
              ),
            );
          }
        });
      }

      final assembleOnlyInvalidCases =
          <(String description, Map<String, Object?> overrides, String expectedMessage)>[
            (
              'missing buildDir',
              <String, Object?>{BuildService.buildDirParam: null},
              'Missing required "${BuildService.buildDirParam}" (expected String).',
            ),
            (
              'relative buildDir',
              <String, Object?>{BuildService.buildDirParam: 'relative/build'},
              'Missing or invalid "${BuildService.buildDirParam}" parameter.',
            ),
          ];

      for (final (String description, Map<String, Object?> overrides, String expectedMessage)
          in assembleOnlyInvalidCases) {
        test('throws RpcException on $description for assemble', () async {
          final service = LinuxBuildService();
          final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
          final ExtensionRpcHandler assembleHandler = handlers['assemble']!;

          await expectLater(
            () => assembleHandler(<String, Object?>{...validParams, ...overrides}),
            throwsA(
              isA<Exception>().having(
                (Exception e) => e.toString(),
                'toString',
                allOf(contains('-32602'), contains(expectedMessage)),
              ),
            ),
          );
        });
      }
    });
  });
}
