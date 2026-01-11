// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:data_assets/data_assets.dart';
import 'package:file/file.dart' show FileSystem;
import 'package:hooks/hooks.dart';

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
import 'android/native_assets.dart'
    show cCompilerConfigAndroid, getNativeAndroidArchitecture, targetAndroidNdkApi;
import 'ios/native_assets.dart' show getIOSSdk, getNativeIOSArchitecture, targetIOSVersion;
import 'linux/native_assets.dart';
import 'macos/native_assets.dart' show getNativeMacOSArchitecture, targetMacOSVersion;
import 'macos/native_assets_host.dart';
import 'native_assets.dart';
import 'windows/native_assets.dart';

/// This is a translation layer between Flutter, which knows only
/// [TargetPlatform]s, and `dart-lang/native`, which knows only asset types and
/// how to build them based on things like [OS]s and [Architecture]s.
sealed class AssetBuildTarget {
  const AssetBuildTarget({required this.supportedAssetTypes});

  /// The asset types supported by this target.
  ///
  /// For example, native code assets might not be supported on the web.
  final List<SupportedAssetTypes> supportedAssetTypes;

  /// The [ProtocolExtension]s are defined per asset type.
  List<ProtocolExtension> get extensions;

  /// A human readable string representing this target.
  String get targetString;

  List<DataAssetsExtension> get dataAssetExtensions => <DataAssetsExtension>[
    if (supportedAssetTypes.contains(SupportedAssetTypes.dataAssets)) DataAssetsExtension(),
  ];

  /// Build the list of [AssetBuildTarget]s for a given [TargetPlatform].
  ///
  /// It needs access to other parameters such as the [fileSystem] or
  /// [environmentDefines] to retrieve options for some of the targets.
  static List<AssetBuildTarget> targetsFor({
    required TargetPlatform targetPlatform,
    required Map<String, String> environmentDefines,
    required FileSystem fileSystem,
    required List<SupportedAssetTypes> supportedAssetTypes,
  }) {
    switch (targetPlatform) {
      case TargetPlatform.windows_x64:
        return _windowsTarget(supportedAssetTypes, Architecture.x64);
      case TargetPlatform.linux_x64:
        return _linuxTarget(supportedAssetTypes, Architecture.x64);
      case TargetPlatform.linux_arm64:
        return _linuxTarget(supportedAssetTypes, Architecture.arm64);
      case TargetPlatform.linux_riscv64:
        return _linuxTarget(supportedAssetTypes, Architecture.riscv64);
      case TargetPlatform.windows_arm64:
        return _windowsTarget(supportedAssetTypes, Architecture.arm64);
      case TargetPlatform.darwin:
        return _macTargets(environmentDefines, supportedAssetTypes);
      case TargetPlatform.android:
      case TargetPlatform.android_arm:
      case TargetPlatform.android_arm64:
      case TargetPlatform.android_x64:
        return _androidTargets(targetPlatform, environmentDefines, supportedAssetTypes);
      case TargetPlatform.ios:
        return _iosTargets(environmentDefines, fileSystem, supportedAssetTypes);
      case TargetPlatform.web_javascript:
        return _webTarget(supportedAssetTypes);
      case TargetPlatform.tester:
        return _flutterTesterTarget(supportedAssetTypes);
      case TargetPlatform.fuchsia_arm64:
      case TargetPlatform.fuchsia_x64:
      case TargetPlatform.unsupported:
        throwToolExit('No targets defined for target platform $targetPlatform.');
    }
  }

  static List<AssetBuildTarget> _linuxTarget(
    List<SupportedAssetTypes> supportedAssetTypes,
    Architecture architecture,
  ) {
    return <AssetBuildTarget>[
      LinuxAssetTarget(architecture: architecture, supportedAssetTypes: supportedAssetTypes),
    ];
  }

  static List<AssetBuildTarget> _windowsTarget(
    List<SupportedAssetTypes> supportedAssetTypes,
    Architecture architecture,
  ) {
    return <AssetBuildTarget>[
      WindowsAssetTarget(architecture: architecture, supportedAssetTypes: supportedAssetTypes),
    ];
  }

  static List<MacOSAssetTarget> _macTargets(
    Map<String, String> environmentDefines,
    List<SupportedAssetTypes> supportedAssetTypes,
  ) {
    return getDarwinArchsFromEnv(environmentDefines)
        .map(getNativeMacOSArchitecture)
        .map(
          (Architecture architecture) => MacOSAssetTarget(
            architecture: architecture,
            supportedAssetTypes: supportedAssetTypes,
          ),
        )
        .toList();
  }

  static List<AndroidAssetTarget> _androidTargets(
    TargetPlatform targetPlatform,
    Map<String, String> environmentDefines,
    List<SupportedAssetTypes> supportedAssetTypes,
  ) {
    return _androidArchs(targetPlatform, environmentDefines[kAndroidArchs])
        .map(getNativeAndroidArchitecture)
        .map(
          (Architecture architecture) => AndroidAssetTarget(
            architecture: architecture,
            supportedAssetTypes: supportedAssetTypes,
            environmentDefines: environmentDefines,
          ),
        )
        .toList();
  }

  static List<IOSAssetTarget> _iosTargets(
    Map<String, String> environmentDefines,
    FileSystem fileSystem,
    List<SupportedAssetTypes> supportedAssetTypes,
  ) {
    final List<DarwinArch> iosArchitectures =
        _emptyToNull(environmentDefines[kIosArchs])?.split(' ').map(getIOSArchForName).toList() ??
        <DarwinArch>[DarwinArch.arm64];
    return iosArchitectures
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
  }

  static List<AssetBuildTarget> _webTarget(List<SupportedAssetTypes> supportedAssetTypes) =>
      <AssetBuildTarget>[WebAssetTarget(supportedAssetTypes: supportedAssetTypes)];

  static List<AssetBuildTarget> _flutterTesterTarget(
    List<SupportedAssetTypes> supportedAssetTypes,
  ) {
    return <AssetBuildTarget>[FlutterTesterAssetTarget(supportedAssetTypes: supportedAssetTypes)];
  }
}

final class WebAssetTarget extends AssetBuildTarget {
  WebAssetTarget({required super.supportedAssetTypes});

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[...dataAssetExtensions];

  @override
  String get targetString => 'web';
}

sealed class CodeAssetTarget extends AssetBuildTarget {
  CodeAssetTarget({
    required super.supportedAssetTypes,
    required this.architecture,
    required this.os,
  });

  final Architecture architecture;
  final OS os;

  late final CCompilerConfig? cCompilerConfigSync;

  /// On platforms where the Flutter app is compiled with a native toolchain, configures this target
  /// to contain a [CCompilerConfig] matching that toolchain.
  ///
  /// While hooks are supposed to be able to find a toolchain on their own, we want them to use the
  /// same tools used to build the main app to make static linking easier in the future. So if we're
  /// e.g. on Linux and use `clang` to compile the app, hooks should use the same `clang` as a
  /// compiler too.
  ///
  /// If [mustMatchAppBuild] is true (the default), this should throw if the expected toolchain
  /// could not be found. For `flutter test` setups where no app is compiled, we _prefer_ to use the
  /// same toolchain but would allow not passing a [CCompilerConfig] if that fails. This allows
  /// hooks that only download code assets instead of compiling them to still function.
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true});

  List<CodeAssetExtension> get codeAssetExtensions {
    return <CodeAssetExtension>[
      if (supportedAssetTypes.contains(SupportedAssetTypes.codeAssets))
        CodeAssetExtension(
          targetArchitecture: architecture,
          linkModePreference: LinkModePreference.dynamic,
          cCompiler: cCompilerConfigSync,
          targetOS: os,
        ),
    ];
  }

  @override
  String get targetString => '${os.name}_${architecture.name}';
}

class WindowsAssetTarget extends CodeAssetTarget {
  WindowsAssetTarget({required super.supportedAssetTypes, required super.architecture})
    : super(os: OS.windows);

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    ...codeAssetExtensions,
    ...dataAssetExtensions,
  ];

  @override
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true}) async =>
      // TODO(simolus3): Respect the mustMatchAppBuild option in cCompilerConfigWindows.
      cCompilerConfigSync = await cCompilerConfigWindows();
}

final class LinuxAssetTarget extends CodeAssetTarget {
  LinuxAssetTarget({required super.supportedAssetTypes, required super.architecture})
    : super(os: OS.linux);

  @override
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true}) async =>
      cCompilerConfigSync = await cCompilerConfigLinux(throwIfNotFound: mustMatchAppBuild);

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    ...codeAssetExtensions,
    ...dataAssetExtensions,
  ];
}

final class IOSAssetTarget extends CodeAssetTarget {
  IOSAssetTarget({
    required super.supportedAssetTypes,
    required super.architecture,
    required this.environmentDefines,
    required this.fileSystem,
  }) : super(os: OS.iOS);

  final Map<String, String> environmentDefines;
  final FileSystem fileSystem;

  @override
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true}) async =>
      cCompilerConfigSync = await cCompilerConfigMacOS(throwIfNotFound: mustMatchAppBuild);

  IOSCodeConfig _getIOSConfig(Map<String, String> environmentDefines, FileSystem fileSystem) {
    final String? sdkRoot = environmentDefines[kSdkRoot];
    if (sdkRoot == null) {
      throw MissingDefineException(kSdkRoot, 'native_assets');
    }
    final EnvironmentType? environmentType = xcode.environmentTypeFromSdkroot(sdkRoot, fileSystem);
    return IOSCodeConfig(targetVersion: targetIOSVersion, targetSdk: getIOSSdk(environmentType!));
  }

  @override
  List<ProtocolExtension> get extensions {
    return <ProtocolExtension>[
      if (supportedAssetTypes.contains(SupportedAssetTypes.codeAssets))
        CodeAssetExtension(
          targetArchitecture: architecture,
          linkModePreference: LinkModePreference.dynamic,
          cCompiler: cCompilerConfigSync,
          targetOS: OS.iOS,
          iOS: _getIOSConfig(environmentDefines, fileSystem),
        ),
      ...dataAssetExtensions,
    ];
  }
}

final class MacOSAssetTarget extends CodeAssetTarget {
  MacOSAssetTarget({required super.supportedAssetTypes, required super.architecture})
    : super(os: OS.macOS);

  @override
  List<ProtocolExtension> get extensions {
    return <ProtocolExtension>[
      if (supportedAssetTypes.contains(SupportedAssetTypes.codeAssets))
        CodeAssetExtension(
          targetArchitecture: architecture,
          linkModePreference: LinkModePreference.dynamic,
          cCompiler: cCompilerConfigSync,
          targetOS: OS.macOS,
          macOS: MacOSCodeConfig(targetVersion: targetMacOSVersion),
        ),
      ...dataAssetExtensions,
    ];
  }

  @override
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true}) async =>
      cCompilerConfigSync = await cCompilerConfigMacOS(throwIfNotFound: mustMatchAppBuild);
}

final class AndroidAssetTarget extends CodeAssetTarget {
  AndroidAssetTarget({
    required super.architecture,
    required Map<String, String> environmentDefines,
    required super.supportedAssetTypes,
  }) : _androidCodeConfig = AndroidCodeConfig(
         targetNdkApi: targetAndroidNdkApi(environmentDefines),
       ),
       super(os: OS.android);

  final AndroidCodeConfig? _androidCodeConfig;

  @override
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true}) async =>
      cCompilerConfigSync = await cCompilerConfigAndroid();

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    if (supportedAssetTypes.contains(SupportedAssetTypes.codeAssets))
      CodeAssetExtension(
        targetArchitecture: architecture,
        linkModePreference: LinkModePreference.dynamic,
        cCompiler: cCompilerConfigSync,
        targetOS: OS.android,
        android: _androidCodeConfig,
      ),
    ...dataAssetExtensions,
  ];
}

final class FlutterTesterAssetTarget extends CodeAssetTarget {
  FlutterTesterAssetTarget({required super.supportedAssetTypes})
    : super(architecture: Architecture.current, os: OS.current) {
    subtarget = switch (os) {
      OS.linux => LinuxAssetTarget(
        supportedAssetTypes: supportedAssetTypes,
        architecture: architecture,
      ),
      OS.windows => WindowsAssetTarget(
        supportedAssetTypes: supportedAssetTypes,
        architecture: architecture,
      ),
      OS.macOS => MacOSAssetTarget(
        supportedAssetTypes: supportedAssetTypes,
        architecture: architecture,
      ),
      OS() => throw UnsupportedError('Flutter tester supports only Linux, Windows and MacOS.'),
    };
  }

  /// The Flutter tester is a headless Flutter, but can run on different targets
  /// itself. The subtarget thus captures the target OS, architecture, etc.
  late final CodeAssetTarget subtarget;

  @override
  List<ProtocolExtension> get extensions => subtarget.extensions;

  @override
  CCompilerConfig? get cCompilerConfigSync => subtarget.cCompilerConfigSync;

  @override
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true}) =>
      subtarget.setCCompilerConfig(mustMatchAppBuild: false);
}

List<AndroidArch> _androidArchs(TargetPlatform targetPlatform, String? androidArchsEnvironment) {
  switch (targetPlatform) {
    case TargetPlatform.android_arm:
      return <AndroidArch>[AndroidArch.armeabi_v7a];
    case TargetPlatform.android_arm64:
      return <AndroidArch>[AndroidArch.arm64_v8a];
    case TargetPlatform.android_x64:
      return <AndroidArch>[AndroidArch.x86_64];
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
    case TargetPlatform.linux_riscv64:
    case TargetPlatform.linux_x64:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
    case TargetPlatform.windows_x64:
    case TargetPlatform.windows_arm64:
    case TargetPlatform.unsupported:
      throwToolExit('Unsupported Android target platform: $targetPlatform.');
  }
}

String? _emptyToNull(String? input) {
  if (input == null || input.isEmpty) {
    return null;
  }
  return input;
}
