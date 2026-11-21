// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:flutter_tools_extension_linux_prototype/src/build.dart';
import 'package:test/test.dart';

final class _ContextRecordingBuildTarget extends BuildTarget {
  const _ContextRecordingBuildTarget(this._onBuild)
    : super(
        description: 'Records ExtensionBuildContext.',
        outputDir: '{OUTPUT_DIR}/recorded',
        targetPlatform: 'linux-x64',
      );

  final void Function(ExtensionBuildContext context) _onBuild;

  @override
  String get name => 'custom-linux-build';

  @override
  Future<ExtensionBuildResult> build(ExtensionBuildContext context) async {
    _onBuild(context);
    return const ExtensionBuildResult(success: true);
  }
}

final class _ContextRecordingAssembleTarget extends AssembleTarget {
  const _ContextRecordingAssembleTarget(this._onAssemble)
    : super(description: 'Records ExtensionAssembleContext.', targetPlatform: 'linux-x64');

  final void Function(ExtensionAssembleContext context) _onAssemble;

  @override
  String get name => 'custom-linux-build';

  @override
  Future<ExtensionBuildResult> build(ExtensionAssembleContext context) async {
    _onAssemble(context);
    return const ExtensionBuildResult(success: true);
  }
}

final class _ContextRecordingBuildService extends BuildService {
  ExtensionBuildContext? lastBuildContext;
  ExtensionAssembleContext? lastAssembleContext;

  @override
  List<BuildTarget> get buildTargets => <BuildTarget>[
    _ContextRecordingBuildTarget((ExtensionBuildContext context) {
      lastBuildContext = context;
    }),
  ];

  @override
  List<AssembleTarget> get assembleTargets => <AssembleTarget>[
    _ContextRecordingAssembleTarget((ExtensionAssembleContext context) {
      lastAssembleContext = context;
    }),
  ];
}

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

        final Object? assembleTargetsResult = await handlers['getAssembleTargets']!(
          const <String, Object?>{},
        );
        final List<ExtensionAssembleTarget> assembleTargets = ExtensionAssembleTarget.listFromJson(
          assembleTargetsResult,
        );
        expect(assembleTargets, hasLength(1));
        expect(assembleTargets.single.name, 'custom-linux-assemble-only-debug');

        final Object? missingCmakeResultObj = await handlers['build']!(<String, Object?>{
          BuildService.buildModeParam: 'debug',
          BuildService.flutterRootParam: '/flutter',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
          BuildService.projectRootParam: '/project',
          BuildService.resolvedArtifactsParam: const <String, String>{},
          BuildService.targetNameParam: LinuxBuildService.customLinuxBuildTargetName,
          BuildService.trackWidgetCreationParam: true,
          BuildService.treeShakeIconsParam: false,
        });
        final missingCmakeResult = ExtensionBuildResult.fromJson(
          missingCmakeResultObj! as Map<String, Object?>,
        );
        expect(missingCmakeResult.success, isFalse);
        expect(missingCmakeResult.errorMessage, contains('Missing linux/CMakeLists.txt'));

        final Object? unknownBuildTargetResultObj = await handlers['build']!(<String, Object?>{
          BuildService.buildModeParam: 'debug',
          BuildService.flutterRootParam: '/flutter',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
          BuildService.projectRootParam: '/project',
          BuildService.resolvedArtifactsParam: const <String, String>{},
          BuildService.targetNameParam: 'unknown-target',
          BuildService.trackWidgetCreationParam: true,
          BuildService.treeShakeIconsParam: false,
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
            BuildService.trackWidgetCreationParam: true,
            BuildService.treeShakeIconsParam: false,
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
        ExtensionAssembleContext(
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
          trackWidgetCreation: true,
          treeShakeIcons: false,
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
        ExtensionAssembleContext(
          buildDir: tempDir.uri,
          buildMode: .debug,
          flutterRoot: tempDir.uri,
          mainPath: 'lib/main.dart',
          outputDir: tempDir.uri,
          projectRoot: tempDir.uri,
          resolvedArtifacts: const <String, String>{},
          trackWidgetCreation: true,
          treeShakeIcons: false,
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
        ExtensionAssembleContext(
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
          trackWidgetCreation: true,
          treeShakeIcons: false,
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
        BuildService.trackWidgetCreationParam: true,
        BuildService.treeShakeIconsParam: false,
      };

      final commonInvalidCases = <(String description, Map<String, Object?> overrides, String expectedMessage)>[
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
        (
          'non-directory splitDebugInfo (missing trailing slash)',
          <String, Object?>{BuildService.splitDebugInfoParam: 'file:///tmp/not_a_dir'},
          'Invalid "${BuildService.splitDebugInfoParam}": expected trailing-slash-terminated absolute file: URI.',
        ),
        (
          'relative splitDebugInfo',
          <String, Object?>{BuildService.splitDebugInfoParam: 'relative/symbols/'},
          'Invalid "${BuildService.splitDebugInfoParam}": expected trailing-slash-terminated absolute file: URI.',
        ),
        (
          'non-string dartDefines value',
          <String, Object?>{
            BuildService.dartDefinesParam: <String, Object?>{'KEY': 42},
          },
          'Invalid "KEY" value: expected String, got int.',
        ),
        (
          'non-bool dartObfuscation',
          <String, Object?>{BuildService.dartObfuscationParam: 'yes'},
          'Invalid "${BuildService.dartObfuscationParam}": expected bool, got String.',
        ),
        (
          'non-string extraFrontEndOptions element',
          <String, Object?>{
            BuildService.extraFrontEndOptionsParam: <Object?>[123],
          },
          'Invalid "${BuildService.extraFrontEndOptionsParam}" element: expected String, got int.',
        ),
        (
          'non-string extraGenSnapshotOptions element',
          <String, Object?>{
            BuildService.extraGenSnapshotOptionsParam: <Object?>[456],
          },
          'Invalid "${BuildService.extraGenSnapshotOptionsParam}" element: expected String, got int.',
        ),
        (
          'missing trackWidgetCreation',
          <String, Object?>{BuildService.trackWidgetCreationParam: null},
          'Missing required "${BuildService.trackWidgetCreationParam}" (expected bool).',
        ),
        (
          'non-bool trackWidgetCreation',
          <String, Object?>{BuildService.trackWidgetCreationParam: 'yes'},
          'Invalid "${BuildService.trackWidgetCreationParam}": expected bool, got String.',
        ),
        (
          'missing treeShakeIcons',
          <String, Object?>{BuildService.treeShakeIconsParam: null},
          'Missing required "${BuildService.treeShakeIconsParam}" (expected bool).',
        ),
        (
          'non-bool treeShakeIcons',
          <String, Object?>{BuildService.treeShakeIconsParam: 'no'},
          'Invalid "${BuildService.treeShakeIconsParam}": expected bool, got String.',
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

      test('BuildService parses BuildInfo parameters into ExtensionBuildContext and ExtensionAssembleContext', () async {
        final service = _ContextRecordingBuildService();
        final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
        final ExtensionRpcHandler buildHandler = handlers['build']!;
        final ExtensionRpcHandler assembleHandler = handlers['assemble']!;

        final fullParams = <String, Object?>{
          ...validParams,
          BuildService.buildModeParam: 'release',
          BuildService.buildNameParam: '3.2.1',
          BuildService.buildNumberParam: '77',
          BuildService.dartDefinesParam: <String, Object?>{'ENV': 'prod'},
          BuildService.dartObfuscationParam: true,
          BuildService.extraFrontEndOptionsParam: <Object?>['--fe-opt'],
          BuildService.extraGenSnapshotOptionsParam: <Object?>['--gs-opt'],
          BuildService.flavorParam: 'enterprise',
          BuildService.splitDebugInfoParam: 'file:///tmp/symbols/',
          BuildService.targetDeviceIdParam: 'device-123',
          BuildService.targetPlatformParam: 'custom-arm64',
          BuildService.trackWidgetCreationParam: true,
          BuildService.treeShakeIconsParam: false,
        };

        await buildHandler(fullParams);
        final ExtensionBuildContext buildCtx = service.lastBuildContext!;
        expect(buildCtx.buildMode, BuildMode.release);
        expect(buildCtx.buildName, '3.2.1');
        expect(buildCtx.buildNumber, '77');
        expect(buildCtx.dartDefines, const <String, String>{'ENV': 'prod'});
        expect(buildCtx.dartObfuscation, isTrue);
        expect(buildCtx.extraFrontEndOptions, const <String>['--fe-opt']);
        expect(buildCtx.extraGenSnapshotOptions, const <String>['--gs-opt']);
        expect(buildCtx.flavor, 'enterprise');
        expect(buildCtx.splitDebugInfo, Uri.parse('file:///tmp/symbols/'));
        expect(buildCtx.targetDeviceId, 'device-123');
        expect(buildCtx.targetPlatform, 'custom-arm64');
        expect(buildCtx.trackWidgetCreation, isTrue);
        expect(buildCtx.treeShakeIcons, isFalse);

        await assembleHandler(fullParams);
        final ExtensionAssembleContext assembleCtx = service.lastAssembleContext!;
        expect(assembleCtx.buildDir, Uri.parse('/build/'));
        expect(assembleCtx.buildMode, BuildMode.release);
        expect(assembleCtx.buildName, '3.2.1');
        expect(assembleCtx.buildNumber, '77');
        expect(assembleCtx.dartDefines, const <String, String>{'ENV': 'prod'});
        expect(assembleCtx.dartObfuscation, isTrue);
        expect(assembleCtx.extraFrontEndOptions, const <String>['--fe-opt']);
        expect(assembleCtx.extraGenSnapshotOptions, const <String>['--gs-opt']);
        expect(assembleCtx.flavor, 'enterprise');
        expect(assembleCtx.splitDebugInfo, Uri.parse('file:///tmp/symbols/'));
        expect(assembleCtx.targetDeviceId, 'device-123');
        expect(assembleCtx.targetPlatform, 'custom-arm64');
        expect(assembleCtx.trackWidgetCreation, isTrue);
        expect(assembleCtx.treeShakeIcons, isFalse);
      });
    });
  });
}
