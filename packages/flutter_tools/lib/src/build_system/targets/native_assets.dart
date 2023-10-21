// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:native_assets_cli/native_assets_cli.dart' show Asset;
import 'package:package_config/package_config_types.dart';

import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/platform.dart';
import '../../build_info.dart';
import '../../dart/package_map.dart';
import '../../ios/native_assets.dart';
import '../../linux/native_assets.dart';
import '../../macos/native_assets.dart';
import '../../macos/xcode.dart';
import '../../native_assets.dart';
import '../../windows/native_assets.dart';
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
    @visibleForTesting NativeAssetsBuildRunner? buildRunner,
  }) : _buildRunner = buildRunner;

  final NativeAssetsBuildRunner? _buildRunner;

  @override
  Future<void> build(Environment environment) async {
    final String? targetPlatformEnvironment = environment.defines[kTargetPlatform];
    if (targetPlatformEnvironment == null) {
      throw MissingDefineException(kTargetPlatform, name);
    }
    final TargetPlatform targetPlatform = getTargetPlatformForName(targetPlatformEnvironment);

    final Uri projectUri = environment.projectDir.uri;
    final FileSystem fileSystem = environment.fileSystem;
    final File packagesFile = fileSystem
        .directory(projectUri)
        .childDirectory('.dart_tool')
        .childFile('package_config.json');
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      packagesFile,
      logger: environment.logger,
    );
    final NativeAssetsBuildRunner buildRunner = _buildRunner ??
        NativeAssetsBuildRunnerImpl(
          projectUri,
          packageConfig,
          fileSystem,
          environment.logger,
        );

    final List<Uri> dependencies;
    switch (targetPlatform) {
      case TargetPlatform.ios:
        final String? iosArchsEnvironment = environment.defines[kIosArchs];
        if (iosArchsEnvironment == null) {
          throw MissingDefineException(kIosArchs, name);
        }
        final List<DarwinArch> iosArchs = iosArchsEnvironment.split(' ').map(getDarwinArchForName).toList();
        final String? environmentBuildMode = environment.defines[kBuildMode];
        if (environmentBuildMode == null) {
          throw MissingDefineException(kBuildMode, name);
        }
        final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
        final String? sdkRoot = environment.defines[kSdkRoot];
        if (sdkRoot == null) {
          throw MissingDefineException(kSdkRoot, name);
        }
        final EnvironmentType environmentType = environmentTypeFromSdkroot(sdkRoot, environment.fileSystem)!;
        dependencies = await buildNativeAssetsIOS(
          environmentType: environmentType,
          darwinArchs: iosArchs,
          buildMode: buildMode,
          projectUri: projectUri,
          codesignIdentity: environment.defines[kCodesignIdentity],
          fileSystem: fileSystem,
          buildRunner: buildRunner,
          yamlParentDirectory: environment.buildDir.uri,
        );
      case TargetPlatform.darwin:
        final String? darwinArchsEnvironment = environment.defines[kDarwinArchs];
        if (darwinArchsEnvironment == null) {
          throw MissingDefineException(kDarwinArchs, name);
        }
        final List<DarwinArch> darwinArchs = darwinArchsEnvironment.split(' ').map(getDarwinArchForName).toList();
        final String? environmentBuildMode = environment.defines[kBuildMode];
        if (environmentBuildMode == null) {
          throw MissingDefineException(kBuildMode, name);
        }
        final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
        (_, dependencies) = await buildNativeAssetsMacOS(
          darwinArchs: darwinArchs,
          buildMode: buildMode,
          projectUri: projectUri,
          codesignIdentity: environment.defines[kCodesignIdentity],
          yamlParentDirectory: environment.buildDir.uri,
          fileSystem: fileSystem,
          buildRunner: buildRunner,
        );
      case TargetPlatform.linux_arm64:
      case TargetPlatform.linux_x64:
        final String? environmentBuildMode = environment.defines[kBuildMode];
        if (environmentBuildMode == null) {
          throw MissingDefineException(kBuildMode, name);
        }
        final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
        (_, dependencies) = await buildNativeAssetsLinux(
          targetPlatform: targetPlatform,
          buildMode: buildMode,
          projectUri: projectUri,
          yamlParentDirectory: environment.buildDir.uri,
          fileSystem: fileSystem,
          buildRunner: buildRunner,
        );
      case TargetPlatform.windows_x64:
        final String? environmentBuildMode = environment.defines[kBuildMode];
        if (environmentBuildMode == null) {
          throw MissingDefineException(kBuildMode, name);
        }
        final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
        (_, dependencies) = await buildNativeAssetsWindows(
          targetPlatform: targetPlatform,
          buildMode: buildMode,
          projectUri: projectUri,
          yamlParentDirectory: environment.buildDir.uri,
          fileSystem: fileSystem,
          buildRunner: buildRunner,
        );
      case TargetPlatform.tester:
        if (const LocalPlatform().isMacOS) {
          (_, dependencies) = await buildNativeAssetsMacOS(
            buildMode: BuildMode.debug,
            projectUri: projectUri,
            codesignIdentity: environment.defines[kCodesignIdentity],
            yamlParentDirectory: environment.buildDir.uri,
            fileSystem: fileSystem,
            buildRunner: buildRunner,
            flutterTester: true,
          );
        } else if (const LocalPlatform().isLinux) {
          (_, dependencies) = await buildNativeAssetsLinux(
            buildMode: BuildMode.debug,
            projectUri: projectUri,
            yamlParentDirectory: environment.buildDir.uri,
            fileSystem: fileSystem,
            buildRunner: buildRunner,
            flutterTester: true,
          );
        } else if (const LocalPlatform().isWindows) {
          (_, dependencies) = await buildNativeAssetsWindows(
            buildMode: BuildMode.debug,
            projectUri: projectUri,
            yamlParentDirectory: environment.buildDir.uri,
            fileSystem: fileSystem,
            buildRunner: buildRunner,
            flutterTester: true,
          );
        } else {
          // TODO(dacoharkes): Implement other OSes. https://github.com/flutter/flutter/issues/129757
          // Write the file we claim to have in the [outputs].
          await writeNativeAssetsYaml(<Asset>[], environment.buildDir.uri, fileSystem);
          dependencies = <Uri>[];
        }
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.web_javascript:
        // TODO(dacoharkes): Implement other OSes. https://github.com/flutter/flutter/issues/129757
        // Write the file we claim to have in the [outputs].
        await writeNativeAssetsYaml(<Asset>[], environment.buildDir.uri, fileSystem);
        dependencies = <Uri>[];
    }

    final File nativeAssetsFile = environment.buildDir.childFile('native_assets.yaml');
    final Depfile depfile = Depfile(
      <File>[
        for (final Uri dependency in dependencies) fileSystem.file(dependency),
      ],
      <File>[
        nativeAssetsFile,
      ],
    );
    final File outputDepfile = environment.buildDir.childFile('native_assets.d');
    if (!outputDepfile.parent.existsSync()) {
      outputDepfile.parent.createSync(recursive: true);
    }
    environment.depFileService.writeToFile(depfile, outputDepfile);
    if (!await nativeAssetsFile.exists()) {
      throwToolExit("${nativeAssetsFile.path} doesn't exist.");
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
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/native_assets.dart'),
    // If different packages are resolved, different native assets might need to be built.
    Source.pattern('{PROJECT_DIR}/.dart_tool/package_config_subset'),
  ];

  @override
  String get name => 'native_assets';

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/native_assets.yaml'),
  ];
}
