// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:native_assets_builder/native_assets_builder.dart' hide NativeAssetsBuildRunner;
import 'package:package_config/package_config_types.dart';

import '../../android/gradle_utils.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../base/platform.dart';
import '../../build_info.dart';
import '../../dart/package_map.dart';
import '../../isolated/native_assets/android/native_assets.dart';
import '../../isolated/native_assets/ios/native_assets.dart';
import '../../isolated/native_assets/linux/native_assets.dart';
import '../../isolated/native_assets/macos/native_assets.dart';
import '../../isolated/native_assets/native_assets.dart';
import '../../isolated/native_assets/windows/native_assets.dart';
import '../../macos/xcode.dart';
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
    final String? nativeAssetsEnvironment = environment.defines[kNativeAssets];
    final List<Uri> dependencies;
    final FileSystem fileSystem = environment.fileSystem;
    final File nativeAssetsFile = environment.buildDir.childFile('native_assets.yaml');
    if (nativeAssetsEnvironment == 'false') {
      dependencies = <Uri>[];
      await writeNativeAssetsYaml(KernelAssets(), environment.buildDir.uri, fileSystem);
    } else {
      final String? targetPlatformEnvironment = environment.defines[kTargetPlatform];
      if (targetPlatformEnvironment == null) {
        throw MissingDefineException(kTargetPlatform, name);
      }
      final TargetPlatform targetPlatform = getTargetPlatformForName(targetPlatformEnvironment);
      final Uri projectUri = environment.projectDir.uri;
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

      switch (targetPlatform) {
        case TargetPlatform.ios:
          dependencies = await _buildIOS(
            environment,
            projectUri,
            fileSystem,
            buildRunner,
          );
        case TargetPlatform.darwin:
          dependencies = await _buildMacOS(
            environment,
            projectUri,
            fileSystem,
            buildRunner,
          );
        case TargetPlatform.linux_arm64:
        case TargetPlatform.linux_x64:
          dependencies = await _buildLinux(
            environment,
            targetPlatform,
            projectUri,
            fileSystem,
            buildRunner,
          );
        case TargetPlatform.windows_arm64:
        case TargetPlatform.windows_x64:
          dependencies = await _buildWindows(
            environment,
            targetPlatform,
            projectUri,
            fileSystem,
            buildRunner,
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
            await writeNativeAssetsYaml(KernelAssets(), environment.buildDir.uri, fileSystem);
            dependencies = <Uri>[];
          }
        case TargetPlatform.android_arm:
        case TargetPlatform.android_arm64:
        case TargetPlatform.android_x64:
        case TargetPlatform.android_x86:
        case TargetPlatform.android:
          (_, dependencies) = await _buildAndroid(
            environment,
            targetPlatform,
            projectUri,
            fileSystem,
            buildRunner,
          );
        case TargetPlatform.fuchsia_arm64:
        case TargetPlatform.fuchsia_x64:
        case TargetPlatform.web_javascript:
          // TODO(dacoharkes): Implement other OSes. https://github.com/flutter/flutter/issues/129757
          // Write the file we claim to have in the [outputs].
          await writeNativeAssetsYaml(KernelAssets(), environment.buildDir.uri, fileSystem);
          dependencies = <Uri>[];
      }
    }

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

  Future<List<Uri>> _buildWindows(
    Environment environment,
    TargetPlatform targetPlatform,
    Uri projectUri,
    FileSystem fileSystem,
    NativeAssetsBuildRunner buildRunner,
  ) async {
    final String? environmentBuildMode = environment.defines[kBuildMode];
    if (environmentBuildMode == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
    final (_, List<Uri> dependencies) = await buildNativeAssetsWindows(
      targetPlatform: targetPlatform,
      buildMode: buildMode,
      projectUri: projectUri,
      yamlParentDirectory: environment.buildDir.uri,
      fileSystem: fileSystem,
      buildRunner: buildRunner,
    );
    return dependencies;
  }

  Future<List<Uri>> _buildLinux(
    Environment environment,
    TargetPlatform targetPlatform,
    Uri projectUri,
    FileSystem fileSystem,
    NativeAssetsBuildRunner buildRunner,
  ) async {
    final String? environmentBuildMode = environment.defines[kBuildMode];
    if (environmentBuildMode == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
    final (_, List<Uri> dependencies) = await buildNativeAssetsLinux(
      targetPlatform: targetPlatform,
      buildMode: buildMode,
      projectUri: projectUri,
      yamlParentDirectory: environment.buildDir.uri,
      fileSystem: fileSystem,
      buildRunner: buildRunner,
    );
    return dependencies;
  }

  Future<List<Uri>> _buildMacOS(
    Environment environment,
    Uri projectUri,
    FileSystem fileSystem,
    NativeAssetsBuildRunner buildRunner,
  ) async {
    final List<DarwinArch> darwinArchs =
        _emptyToNull(environment.defines[kDarwinArchs])
                ?.split(' ')
                .map(getDarwinArchForName)
                .toList() ??
            <DarwinArch>[DarwinArch.x86_64, DarwinArch.arm64];
    final String? environmentBuildMode = environment.defines[kBuildMode];
    if (environmentBuildMode == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
    final (_, List<Uri> dependencies) = await buildNativeAssetsMacOS(
      darwinArchs: darwinArchs,
      buildMode: buildMode,
      projectUri: projectUri,
      codesignIdentity: environment.defines[kCodesignIdentity],
      yamlParentDirectory: environment.buildDir.uri,
      fileSystem: fileSystem,
      buildRunner: buildRunner,
    );
    return dependencies;
  }

  Future<List<Uri>> _buildIOS(
    Environment environment,
    Uri projectUri,
    FileSystem fileSystem,
    NativeAssetsBuildRunner buildRunner,
  ) {
    final List<DarwinArch> iosArchs =
        _emptyToNull(environment.defines[kIosArchs])
                ?.split(' ')
                .map(getIOSArchForName)
                .toList() ??
            <DarwinArch>[DarwinArch.arm64];
    final String? environmentBuildMode = environment.defines[kBuildMode];
    if (environmentBuildMode == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
    final String? sdkRoot = environment.defines[kSdkRoot];
    if (sdkRoot == null) {
      throw MissingDefineException(kSdkRoot, name);
    }
    final EnvironmentType environmentType =
        environmentTypeFromSdkroot(sdkRoot, environment.fileSystem)!;
    return buildNativeAssetsIOS(
      environmentType: environmentType,
      darwinArchs: iosArchs,
      buildMode: buildMode,
      projectUri: projectUri,
      codesignIdentity: environment.defines[kCodesignIdentity],
      fileSystem: fileSystem,
      buildRunner: buildRunner,
      yamlParentDirectory: environment.buildDir.uri,
    );
  }

  Future<(Uri? nativeAssetsYaml, List<Uri> dependencies)> _buildAndroid(
      Environment environment,
      TargetPlatform targetPlatform,
      Uri projectUri,
      FileSystem fileSystem,
      NativeAssetsBuildRunner buildRunner) {
    final String? androidArchsEnvironment = environment.defines[kAndroidArchs];
    final List<AndroidArch> androidArchs = _androidArchs(
      targetPlatform,
      androidArchsEnvironment,
    );
    final int targetAndroidNdkApi =
        int.parse(environment.defines[kMinSdkVersion] ?? minSdkVersion);
    final String? environmentBuildMode = environment.defines[kBuildMode];
    if (environmentBuildMode == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
    return buildNativeAssetsAndroid(
      buildMode: buildMode,
      projectUri: projectUri,
      yamlParentDirectory: environment.buildDir.uri,
      fileSystem: fileSystem,
      buildRunner: buildRunner,
      androidArchs: androidArchs,
      targetAndroidNdkApi: targetAndroidNdkApi,
    );
  }

  List<AndroidArch> _androidArchs(
    TargetPlatform targetPlatform,
    String? androidArchsEnvironment,
  ) {
    switch (targetPlatform) {
      case TargetPlatform.android_arm:
        return <AndroidArch>[AndroidArch.armeabi_v7a];
      case TargetPlatform.android_arm64:
        return <AndroidArch>[AndroidArch.arm64_v8a];
      case TargetPlatform.android_x64:
        return <AndroidArch>[AndroidArch.x86_64];
      case TargetPlatform.android_x86:
        return <AndroidArch>[AndroidArch.x86];
      case TargetPlatform.android:
        if (androidArchsEnvironment == null) {
          throw MissingDefineException(kAndroidArchs, name);
        }
        return androidArchsEnvironment
            .split(' ')
            .map(getAndroidArchForName)
            .toList();
      case TargetPlatform.darwin:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.ios:
      case TargetPlatform.linux_arm64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      case TargetPlatform.windows_x64:
      case TargetPlatform.windows_arm64:
        throwToolExit('Unsupported Android target platform: $targetPlatform.');
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
    Source.pattern('{PROJECT_DIR}/.dart_tool/package_config_subset'),
    // TODO(mosuem): Should consume resources.json. https://github.com/flutter/flutter/issues/146263
  ];

  @override
  String get name => 'native_assets';

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{BUILD_DIR}/native_assets.yaml'),
  ];
}

String? _emptyToNull(String? input) {
  if (input == null || input.isEmpty) {
    return null;
  }
  return input;
}
