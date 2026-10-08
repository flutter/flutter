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
    test('targets returns prototype Linux targets', () {
      final service = LinuxBuildService();
      final List<ExtensionTarget> targets = service.targets;

      expect(targets, hasLength(6));
      expect(targets[0].name, LinuxBuildService.customLinuxBuildTargetName);
      expect(targets[0].targetPlatform, 'linux-x64');
      expect(targets[0].isTopLevel, isTrue);
      expect(targets[1].name, 'custom-linux-assemble-only-debug');
      expect(targets[1].isTopLevel, isFalse);
      expect(targets[2].name, 'custom-linux-aot-elf-profile');
      expect(targets[2].isTopLevel, isFalse);
      expect(targets[3].name, 'custom-linux-assemble-only-profile');
      expect(targets[3].isTopLevel, isFalse);
      expect(targets[4].name, 'custom-linux-aot-elf-release');
      expect(targets[4].isTopLevel, isFalse);
      expect(targets[5].name, 'custom-linux-assemble-only-release');
      expect(targets[5].isTopLevel, isFalse);
    });

    test('initialize registers getBuildTargets and build RPC handlers', () async {
      final service = LinuxBuildService();
      expect(service.namespace, BuildService.serviceNamespace);

      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
      expect(handlers.keys, containsAll(<String>['getBuildTargets', 'build']));

      final Object? targetsResult = await handlers['getBuildTargets']!(const <String, Object?>{});
      final List<ExtensionBuildTarget> targets = ExtensionBuildTarget.listFromJson(targetsResult);
      expect(targets, hasLength(6));
      expect(targets.first.name, LinuxBuildService.customLinuxBuildTargetName);

      final Object? buildResultObj = await handlers['build']!(<String, Object?>{
        BuildService.buildDirParam: '/project/.dart_tool/flutter_build',
        BuildService.buildModeParam: 'debug',
        BuildService.mainPathParam: 'lib/main.dart',
        BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
        BuildService.projectRootParam: '/project',
        BuildService.resolvedArtifactsParam: const <String, String>{},
        BuildService.targetNameParam: LinuxBuildService.customLinuxBuildTargetName,
      });
      expect(buildResultObj, isA<Map<String, Object?>>());
      final buildResult = ExtensionBuildResult.fromJson(buildResultObj! as Map<String, Object?>);
      expect(buildResult.success, isTrue);

      final Object? unknownTargetResultObj = await handlers['build']!(<String, Object?>{
        BuildService.buildDirParam: '/project/.dart_tool/flutter_build',
        BuildService.buildModeParam: 'debug',
        BuildService.mainPathParam: 'lib/main.dart',
        BuildService.outputDirParam: '/project/build/linux_extension/x64/debug',
        BuildService.projectRootParam: '/project',
        BuildService.resolvedArtifactsParam: const <String, String>{},
        BuildService.targetNameParam: 'unknown-target',
      });
      final unknownResult = ExtensionBuildResult.fromJson(
        unknownTargetResultObj! as Map<String, Object?>,
      );
      expect(unknownResult.success, isFalse);
      expect(unknownResult.errorMessage, contains('Unknown build target: unknown-target'));

      await service.shutdown();
    });

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
        ExtensionBuildContext(
          buildDir: buildDir.uri,
          buildMode: .debug,
          mainPath: 'lib/main.dart',
          outputDir: outputDir.uri,
          projectRoot: tempDir.uri,
          resolvedArtifacts: <String, String>{
            LinuxArtifacts.linuxDesktopPath.name: desktopDir.path,
            BuiltInArtifacts.icuData.name: icuFile.path,
          },
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

    test('build RPC handler throws on missing or invalid parameters', () async {
      final service = LinuxBuildService();
      final Map<String, ExtensionRpcHandler> handlers = await service.initialize();
      final ExtensionRpcHandler buildHandler = handlers['build']!;

      await expectLater(
        () => buildHandler(const <String, Object?>{}),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.targetNameParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{BuildService.targetNameParam: 'custom-linux-build'}),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.projectRootParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.mainPathParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.buildModeParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.outputDirParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
          BuildService.outputDirParam: '/out',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.buildDirParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
          BuildService.outputDirParam: '/out',
          BuildService.buildDirParam: '/build',
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.resolvedArtifactsParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: 'relative/path',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
          BuildService.outputDirParam: '/out',
          BuildService.buildDirParam: '/build',
          BuildService.resolvedArtifactsParam: const <String, String>{},
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.projectRootParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
          BuildService.outputDirParam: 'relative/output',
          BuildService.buildDirParam: '/build',
          BuildService.resolvedArtifactsParam: const <String, String>{},
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.outputDirParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
          BuildService.outputDirParam: '/out',
          BuildService.buildDirParam: 'relative/build',
          BuildService.resolvedArtifactsParam: const <String, String>{},
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.buildDirParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'debug',
          BuildService.outputDirParam: '/out',
          BuildService.buildDirParam: '/build',
          BuildService.resolvedArtifactsParam: <Object?, Object?>{'genSnapshot': 123},
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.resolvedArtifactsParam}" parameter.'),
          ),
        ),
      );

      await expectLater(
        () => buildHandler(<String, Object?>{
          BuildService.targetNameParam: 'custom-linux-build',
          BuildService.projectRootParam: '/project',
          BuildService.mainPathParam: 'lib/main.dart',
          BuildService.buildModeParam: 'invalid_mode',
          BuildService.outputDirParam: '/out',
          BuildService.buildDirParam: '/build',
          BuildService.resolvedArtifactsParam: const <String, String>{},
        }),
        throwsA(
          isA<Object>().having(
            (Object e) => e.toString(),
            'toString',
            contains('Missing or invalid "${BuildService.buildModeParam}" parameter.'),
          ),
        ),
      );
    });
  });
}
