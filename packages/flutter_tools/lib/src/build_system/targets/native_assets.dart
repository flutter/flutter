// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:native_assets_builder/native_assets_builder.dart';
import 'package:package_config/package_config_types.dart';

import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../dart/package_map.dart';
import '../../isolated/native_assets/native_assets.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';
import 'common.dart';

/// Builds the right native assets for a Flutter app.
///
/// The build mode and target architecture can be changed from the
/// native build project (Xcode etc.), so only `flutter assemble` has the
/// information about build-mode and target architecture.
/// Invocations of flutter_tools other than `flutter assemble` are dry runs.
///
/// This step needs to be consistent with the dry run invocations in `flutter
/// run`s so that the kernel mapping of asset id to dylib lines up after hot
/// restart.
///
/// [KernelSnapshot] depends on this target. We produce a native_assets.yaml
/// here, and embed that mapping inside the kernel snapshot.
///
/// The build always produces a valid native_assets.yaml and a native_assets.d
/// even if there are no native assets. This way the caching logic won't try to
/// rebuild.
class NativeAssets extends Target {
  const NativeAssets({
    @visibleForTesting FlutterNativeAssetsBuildRunner? buildRunner,
  }) : _buildRunner = buildRunner;

  final FlutterNativeAssetsBuildRunner? _buildRunner;

  @override
  Future<void> build(Environment environment) async {
    final String? nativeAssetsEnvironment = environment.defines[kNativeAssets];
    final FileSystem fileSystem = environment.fileSystem;
    final Uri nativeAssetsFileUri = environment.buildDir.childFile('native_assets.yaml').uri;

    final DartBuildResult result;
    if (nativeAssetsEnvironment == 'false') {
      result = const DartBuildResult.empty();
      await writeNativeAssetsYaml(KernelAssets(), nativeAssetsFileUri, fileSystem);
    } else {
      final String? targetPlatformEnvironment = environment.defines[kTargetPlatform];
      if (targetPlatformEnvironment == null) {
        throw MissingDefineException(kTargetPlatform, name);
      }
      final TargetPlatform targetPlatform = getTargetPlatformForName(targetPlatformEnvironment);
      final Uri projectUri = environment.projectDir.uri;

      final PackageConfig packageConfig = await loadPackageConfigWithLogging(
        fileSystem.file(environment.packageConfigPath),
        logger: environment.logger,
      );
      final FlutterNativeAssetsBuildRunner buildRunner = _buildRunner ??
          FlutterNativeAssetsBuildRunnerImpl(
            projectUri,
            environment.packageConfigPath,
            packageConfig,
            fileSystem,
            environment.logger,
          );

      (result, _) = await runFlutterSpecificDartBuild(
        environmentDefines: environment.defines,
        buildRunner: buildRunner,
        targetPlatform: targetPlatform,
        projectUri: projectUri,
        nativeAssetsYamlUri : nativeAssetsFileUri,
        fileSystem: fileSystem,
      );
    }

    final Depfile depfile = Depfile(
      <File>[
        for (final Uri dependency in result.dependencies) fileSystem.file(dependency),
      ],
      <File>[
        fileSystem.file(nativeAssetsFileUri),
      ],
    );
    final File outputDepfile = environment.buildDir.childFile('native_assets.d');
    if (!outputDepfile.parent.existsSync()) {
      outputDepfile.parent.createSync(recursive: true);
    }
    environment.depFileService.writeToFile(depfile, outputDepfile);
    if (!await fileSystem.file(nativeAssetsFileUri).exists()) {
      throwToolExit("${nativeAssetsFileUri.path} doesn't exist.");
    }
    if (!await outputDepfile.exists()) {
      throwToolExit("${outputDepfile.path} doesn't exist.");
    }
  }

  @override
  List<String> get depfiles => <String>[
    'native_assets.d',
  ];

  @override
  List<Target> get dependencies => const <Target>[
    // In AOT, depends on tree-shaking information (resources.json) from compiling dart.
    KernelSnapshotProgram(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/native_assets.dart'),
    // If different packages are resolved, different native assets might need to be built.
    Source.pattern('{WORKSPACE_DIR}/.dart_tool/package_config_subset'),
    // TODO(mosuem): Should consume resources.json. https://github.com/flutter/flutter/issues/146263
  ];

  @override
  String get name => 'native_assets';

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/native_assets.yaml'),
  ];
}
