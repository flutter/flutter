// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart' show FileSystem;
import 'package:native_assets_cli/code_assets_builder.dart'
    show
        AndroidCodeConfig,
        Architecture,
        CCompilerConfig,
        CodeAssetExtension,
        IOSCodeConfig,
        LinkModePreference,
        MacOSCodeConfig,
        OS,
        ProtocolExtension;
import 'package:native_assets_cli/data_assets_builder.dart';

import '../../base/common.dart' show throwToolExit;
import '../../build_info.dart'
    show
        AndroidArch,
        DarwinArch,
        EnvironmentType,
        TargetPlatform,
        getAndroidArchForName,
        getDarwinArchsFromEnv,
        getIOSArchForName,
        kAndroidArchs,
        kIosArchs,
        kSdkRoot;
import '../../build_system/exceptions.dart' show MissingDefineException;
import '../../macos/xcode.dart' as xcode show environmentTypeFromSdkroot;
import 'android/native_assets.dart' show getNativeAndroidArchitecture, targetAndroidNdkApi;
import 'ios/native_assets.dart' show getIOSSdk, getNativeIOSArchitecture, targetIOSVersion;
import 'macos/native_assets.dart' show getNativeMacOSArchitecture, targetMacOSVersion;
import 'native_assets.dart' show FlutterNativeAssetsBuildRunner;

/// This is a translation layer between Flutter, which knows only
/// [TargetPlatform]s, and `dart-lang/native`, which knows only asset types and
/// how to build them based on things like [OS]s and [Architecture]s.
sealed class AssetBuildTarget {
  const AssetBuildTarget({required this.platform, required this.supportedAssetTypes});

  final TargetPlatform platform;
  final List<String> supportedAssetTypes;

  List<ProtocolExtension> get extensions;

  /// Build the list of [AssetBuildTarget]s for a given [TargetPlatform].
  ///
  /// It needs access to other parameters such as the [fileSystem] or
  /// [environmentDefines] to retrieve options for some of the targets.
  static List<AssetBuildTarget> targetsFor(
    TargetPlatform targetPlatform,
    Map<String, String> environmentDefines,
    FileSystem fileSystem,
    List<String> supportedAssetTypes,
  ) {
    switch (targetPlatform) {
      case TargetPlatform.windows_x64:
        return <AssetBuildTarget>[
          WindowsAssetTarget(
            platform: targetPlatform,
            architecture: Architecture.x64,
            supportedAssetTypes: supportedAssetTypes,
          ),
        ];
      case TargetPlatform.linux_x64:
        return <AssetBuildTarget>[
          LinuxAssetTarget(
            platform: targetPlatform,
            architecture: Architecture.x64,
            supportedAssetTypes: supportedAssetTypes,
          ),
        ];
      case TargetPlatform.linux_arm64:
        return <AssetBuildTarget>[
          LinuxAssetTarget(
            platform: targetPlatform,
            architecture: Architecture.arm64,
            supportedAssetTypes: supportedAssetTypes,
          ),
        ];
      case TargetPlatform.windows_arm64:
        return <AssetBuildTarget>[
          WindowsAssetTarget(
            platform: targetPlatform,
            architecture: Architecture.arm64,
            supportedAssetTypes: supportedAssetTypes,
          ),
        ];
      case TargetPlatform.darwin:
        return getDarwinArchsFromEnv(environmentDefines)
            .map(getNativeMacOSArchitecture)
            .map(
              (Architecture architecture) => MacOSAssetTarget(
                architecture: architecture,
                supportedAssetTypes: supportedAssetTypes,
              ),
            )
            .toList();
      case TargetPlatform.android:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
      case TargetPlatform.android_x86:
        final String? androidArchsEnvironment = environmentDefines[kAndroidArchs];
        final List<AndroidArch> androidArchs = _androidArchs(
          targetPlatform,
          androidArchsEnvironment,
        );
        return androidArchs
            .map(getNativeAndroidArchitecture)
            .map(
              (Architecture architecture) => AndroidAssetTarget(
                platform: targetPlatform,
                architecture: architecture,
                supportedAssetTypes: supportedAssetTypes,
                environmentDefines: environmentDefines,
              ),
            )
            .toList();
      case TargetPlatform.ios:
        final List<DarwinArch> iosArchs =
            _emptyToNull(
              environmentDefines[kIosArchs],
            )?.split(' ').map(getIOSArchForName).toList() ??
            <DarwinArch>[DarwinArch.arm64];
        return iosArchs
            .map(getNativeIOSArchitecture)
            .map(
              (Architecture architecture) => IOSAssetTarget(
                environmentDefines: environmentDefines,
                fileSystem: fileSystem,
                architecture: architecture,
                supportedAssetTypes: supportedAssetTypes,
              ),
            )
            .toList();
      case TargetPlatform.web_javascript:
        return <AssetBuildTarget>[WebAssetTarget(supportedAssetTypes: supportedAssetTypes)];
      case TargetPlatform.tester:
        return <AssetBuildTarget>[
          FlutterTesterAssetTarget(supportedAssetTypes: supportedAssetTypes),
        ];
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
        throw UnsupportedError('No targets defined for target platform $targetPlatform.');
    }
  }
}

final class WebAssetTarget extends AssetBuildTarget {
  WebAssetTarget({required super.supportedAssetTypes})
    : super(platform: TargetPlatform.web_javascript);

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[DataAssetsExtension()];
}

sealed class CodeAssetTarget extends AssetBuildTarget {
  CodeAssetTarget({
    required super.platform,
    required super.supportedAssetTypes,
    required this.architecture,
  });

  final Architecture architecture;

  late final CCompilerConfig? cCompilerConfigSync;

  Future<void> setCCompilerConfig(FlutterNativeAssetsBuildRunner buildRunner) async =>
      cCompilerConfigSync = await buildRunner.cCompilerConfig;

  CodeAssetExtension codeAssetExtensionFor(OS os) => CodeAssetExtension(
    targetArchitecture: architecture,
    linkModePreference: LinkModePreference.dynamic,
    cCompiler: cCompilerConfigSync,
    targetOS: os,
  );
}

class WindowsAssetTarget extends CodeAssetTarget {
  WindowsAssetTarget({
    required super.platform,
    required super.supportedAssetTypes,
    required super.architecture,
  });

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    codeAssetExtensionFor(OS.windows),
    DataAssetsExtension(),
  ];
}

final class LinuxAssetTarget extends CodeAssetTarget {
  LinuxAssetTarget({
    required super.platform,
    required super.supportedAssetTypes,
    required super.architecture,
  });

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    codeAssetExtensionFor(OS.linux),
    DataAssetsExtension(),
  ];
}

final class IOSAssetTarget extends CodeAssetTarget {
  IOSAssetTarget({
    required super.supportedAssetTypes,
    required super.architecture,
    required this.environmentDefines,
    required this.fileSystem,
  }) : super(platform: TargetPlatform.ios);

  final Map<String, String> environmentDefines;
  final FileSystem fileSystem;

  IOSCodeConfig _getIOSConfig(Map<String, String> environmentDefines, FileSystem fileSystem) {
    final String? sdkRoot = environmentDefines[kSdkRoot];
    if (sdkRoot == null) {
      throw MissingDefineException(kSdkRoot, 'native_assets');
    }
    final EnvironmentType? environmentType = xcode.environmentTypeFromSdkroot(sdkRoot, fileSystem);
    return IOSCodeConfig(targetVersion: targetIOSVersion, targetSdk: getIOSSdk(environmentType!));
  }

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    CodeAssetExtension(
      targetArchitecture: architecture,
      linkModePreference: LinkModePreference.dynamic,
      cCompiler: cCompilerConfigSync,
      targetOS: OS.iOS,
      iOS: _getIOSConfig(environmentDefines, fileSystem),
    ),
    DataAssetsExtension(),
  ];
}

final class MacOSAssetTarget extends CodeAssetTarget {
  MacOSAssetTarget({required super.supportedAssetTypes, required super.architecture})
    : super(platform: TargetPlatform.darwin);

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    CodeAssetExtension(
      targetArchitecture: architecture,
      linkModePreference: LinkModePreference.dynamic,
      cCompiler: cCompilerConfigSync,
      targetOS: OS.macOS,
      macOS: MacOSCodeConfig(targetVersion: targetMacOSVersion),
    ),
    DataAssetsExtension(),
  ];
}

final class AndroidAssetTarget extends CodeAssetTarget {
  AndroidAssetTarget({
    required super.platform,
    required super.architecture,
    required Map<String, String> environmentDefines,
    required super.supportedAssetTypes,
  }) : _androidCodeConfig = AndroidCodeConfig(
         targetNdkApi: targetAndroidNdkApi(environmentDefines),
       );

  final AndroidCodeConfig? _androidCodeConfig;

  @override
  Future<void> setCCompilerConfig(FlutterNativeAssetsBuildRunner buildRunner) async =>
      cCompilerConfigSync = await buildRunner.ndkCCompilerConfig;

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    CodeAssetExtension(
      targetArchitecture: architecture,
      linkModePreference: LinkModePreference.dynamic,
      cCompiler: cCompilerConfigSync,
      targetOS: OS.android,
      android: _androidCodeConfig,
    ),
    DataAssetsExtension(),
  ];
}

final class FlutterTesterAssetTarget extends CodeAssetTarget {
  FlutterTesterAssetTarget({required super.supportedAssetTypes})
    : super(architecture: Architecture.current, platform: TargetPlatform.tester);

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    codeAssetExtensionFor(OS.current),
    DataAssetsExtension(),
  ];
}

List<AndroidArch> _androidArchs(TargetPlatform targetPlatform, String? androidArchsEnvironment) {
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
        throw MissingDefineException(kAndroidArchs, 'native_assets');
      }
      return androidArchsEnvironment.split(' ').map(getAndroidArchForName).toList();
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

String? _emptyToNull(String? input) {
  if (input == null || input.isEmpty) {
    return null;
  }
  return input;
}
