// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../globals.dart' as globals;
import '../../ios/native_assets.dart';
import '../../macos/native_assets.dart';
import '../../macos/xcode.dart';
import '../build_system.dart';
import '../exceptions.dart';
import 'common.dart';

/// Builds the right native assets for a Flutter app.
///
/// Because the build mode and target architecture can be changed from the
/// native build project (xcode etc.), we can only build the native assets
/// inside `flutter assemble` when we have all the information.
///
/// All the other invocations for native assets should be dry runs.
///
/// This step needs to be consisent with the other invocations so that the
/// kernel mapping of asset id to dylib lines up after hot restart, and so
/// that the dylibs are bundled by the native build.
///
/// We don't have [NativeAssets] as a dependency of [KernelSnapshot], because
/// it would cause rebuilds of the kernel snapshot due to native assets being
/// rebuilt. The native assets build caching is inside
/// `package:native_assets_builder` and not visible to the flutter targets.
/// This means we don't produce a native_assets.yaml here, and instead rely on
/// the file being pointed to in the native build properties file which is set
/// by build_macos.dart and friends.
class NativeAssets extends Target {
  const NativeAssets();

  @override
  Future<void> build(Environment environment) async {
    final String? targetPlatformEnvironment =
        environment.defines[kTargetPlatform];
    if (targetPlatformEnvironment == null) {
      throw MissingDefineException(kTargetPlatform, name);
    }
    final TargetPlatform targetPlatform =
        getTargetPlatformForName(targetPlatformEnvironment);

    final Uri projectUri = environment.projectDir.uri;
    final FileSystem fileSystem = globals.fs;

    switch (targetPlatform) {
      case TargetPlatform.ios:
        final String? kIosArchsEnvironment = environment.defines[kIosArchs];
        if (kIosArchsEnvironment == null) {
          throw MissingDefineException(kIosArchs, name);
        }
        final List<DarwinArch> iosArchs =
            kIosArchsEnvironment
            .split(' ')
            .map(getDarwinArchForName)
            .toList();
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
        await buildNativeAssetsiOS(
          environmentType: environmentType,
          darwinArchs: iosArchs,
          buildMode: buildMode,
          projectUri: projectUri,
          codesignIdentity: environment.defines[kCodesignIdentity],
          fileSystem: fileSystem,
        );
      case TargetPlatform.darwin:
        final String? darwinArchsEnvironment =
            environment.defines[kDarwinArchs];
        if (darwinArchsEnvironment == null) {
          throw MissingDefineException(kDarwinArchs, name);
        }
        final List<DarwinArch> darwinArchs = darwinArchsEnvironment
            .split(' ')
            .map(getDarwinArchForName)
            .toList();
        final String? environmentBuildMode = environment.defines[kBuildMode];
        if (environmentBuildMode == null) {
          throw MissingDefineException(kBuildMode, name);
        }
        final BuildMode buildMode = BuildMode.fromCliName(environmentBuildMode);
        await buildNativeAssetsMacOS(
          darwinArchs: darwinArchs,
          buildMode: buildMode,
          projectUri: projectUri,
          codesignIdentity: environment.defines[kCodesignIdentity],
          writeYamlFile: false,
          fileSystem: fileSystem,
        );
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.linux_arm64:
      case TargetPlatform.linux_x64:
      case TargetPlatform.tester:
      case TargetPlatform.web_javascript:
      case TargetPlatform.windows_x64:
        // The NativeAssets Target should not be in any other OS.
        throw UnimplementedError();
    }
  }

  @override
  List<Target> get dependencies => <Target>[];

  @override
  List<Source> get inputs => <Source>[];

  @override
  String get name => 'native_assets';

  @override
  List<Source> get outputs => <Source>[];
}
