// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:data_assets/data_assets.dart';
import 'package:hooks/hooks.dart';

import '../../base/common.dart' show throwToolExit;
import '../../base/file_system.dart' show Directory, File, FileSystem;
import '../../build_info.dart'
    show
        BuildMode,
        CpuArch,
        EnvironmentType,
        TargetPlatform,
        getCpuArchForName,
        getCpuArchsFromEnv,
        kAndroidArchs,
        kExtensionCCompilerAr,
        kExtensionCCompilerCc,
        kExtensionCCompilerEnvScript,
        kExtensionCCompilerEnvScriptArgs,
        kExtensionCCompilerLd,
        kExtensionTargetArch,
        kExtensionTargetOs,
        kIosArchs,
        kSdkRoot;
import '../../build_system/exceptions.dart' show MissingDefineException;
import '../../convert.dart' show json;
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
  ///
  /// When building for Linux, [buildDirectory] should point to the build
  /// directory of the app (e.g. `build/`). It is used to infer configured
  /// compilers by reading `CMakeCache.txt`.
  static List<AssetBuildTarget> targetsFor({
    required TargetPlatform targetPlatform,
    required BuildMode buildMode,
    required Map<String, String> environmentDefines,
    required FileSystem fileSystem,
    required List<SupportedAssetTypes> supportedAssetTypes,
    required Directory? buildDirectory,
  }) {
    final (OS os, Architecture architecture)? customTarget = resolveCustomNativeTarget(
      environmentDefines,
    );
    if (customTarget != null) {
      final (OS os, Architecture architecture) = customTarget;
      return <AssetBuildTarget>[
        CustomCodeAssetTarget(
          architecture: architecture,
          environmentDefines: environmentDefines,
          fileSystem: fileSystem,
          os: os,
          supportedAssetTypes: supportedAssetTypes,
        ),
      ];
    }

    switch (targetPlatform) {
      case TargetPlatform.windows_x64:
        return _windowsTarget(supportedAssetTypes, Architecture.x64);
      case TargetPlatform.linux_x64:
        return _linuxTarget(supportedAssetTypes, Architecture.x64, buildMode, buildDirectory);
      case TargetPlatform.linux_arm64:
        return _linuxTarget(supportedAssetTypes, Architecture.arm64, buildMode, buildDirectory);
      case TargetPlatform.linux_riscv64:
        return _linuxTarget(supportedAssetTypes, Architecture.riscv64, buildMode, buildDirectory);
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
    BuildMode buildMode,
    Directory? buildDirectory,
  ) {
    Directory? cmakeBuildDirectory;
    if (buildDirectory != null) {
      cmakeBuildDirectory = buildDirectory
          .childDirectory('linux')
          .childDirectory(architecture.name)
          .childDirectory(buildMode.cliName);
    }

    return <AssetBuildTarget>[
      LinuxAssetTarget(
        architecture: architecture,
        cmakeBuildDirectory: cmakeBuildDirectory,
        supportedAssetTypes: supportedAssetTypes,
      ),
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
    return getCpuArchsFromEnv(environmentDefines)
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
    final List<CpuArch> cpuArchs =
        _emptyToNull(environmentDefines[kIosArchs])?.split(' ').map(getCpuArchForName).toList() ??
        <CpuArch>[CpuArch.arm64];
    return cpuArchs
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
    required this.architecture,
    required this.os,
    required super.supportedAssetTypes,
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

/// [CodeAssetTarget] for extension build targets configured via
/// [kExtensionTargetOs] and [kExtensionTargetArch].
final class CustomCodeAssetTarget extends CodeAssetTarget {
  CustomCodeAssetTarget({
    required super.architecture,
    required this.environmentDefines,
    required this.fileSystem,
    required super.os,
    required super.supportedAssetTypes,
  });

  final Map<String, String> environmentDefines;
  final FileSystem fileSystem;

  @override
  List<ProtocolExtension> get extensions => <ProtocolExtension>[
    ...codeAssetExtensions,
    ...dataAssetExtensions,
  ];

  @override
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true}) async {
    cCompilerConfigSync =
        cCompilerConfigFromDefines(environmentDefines) ??
        _cCompilerConfigForCustomTarget(
          environmentDefines: environmentDefines,
          fileSystem: fileSystem,
        );
  }
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
      cCompilerConfigSync = await cCompilerConfigWindows(throwIfNotFound: mustMatchAppBuild);
}

final class LinuxAssetTarget extends CodeAssetTarget {
  LinuxAssetTarget({
    required super.supportedAssetTypes,
    required super.architecture,
    required this.cmakeBuildDirectory,
  }) : super(os: OS.linux);

  /// Null if this target is used for widget tests where we run code assets
  /// without an app to build.
  final Directory? cmakeBuildDirectory;

  @override
  Future<void> setCCompilerConfig({bool mustMatchAppBuild = true}) async {
    final bool isNativeAppBuild = cmakeBuildDirectory != null && cmakeBuildDirectory!.existsSync();

    cCompilerConfigSync = await cCompilerConfigLinux(
      cmakeDirectory: isNativeAppBuild ? cmakeBuildDirectory : null,
      throwIfNotFound: mustMatchAppBuild,
    );
  }

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
    final EnvironmentType environmentType = xcode.environmentTypeFromSdkroot(sdkRoot, fileSystem);
    return IOSCodeConfig(targetVersion: targetIOSVersion, targetSdk: getIOSSdk(environmentType));
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
        cmakeBuildDirectory: null,
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

List<CpuArch> _androidArchs(TargetPlatform targetPlatform, String? androidArchsEnvironment) {
  switch (targetPlatform) {
    case TargetPlatform.android_arm:
      return <CpuArch>[CpuArch.armv7];
    case TargetPlatform.android_arm64:
      return <CpuArch>[CpuArch.arm64];
    case TargetPlatform.android_x64:
      return <CpuArch>[CpuArch.x64];
    case TargetPlatform.android:
      if (androidArchsEnvironment == null) {
        throw MissingDefineException(kAndroidArchs, 'native_assets');
      }
      return androidArchsEnvironment.split(' ').map(getCpuArchForName).toList();
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

/// Parses a native [OS] from a target OS string (such as `linux`, `android`,
/// or a custom extension OS identifier).
///
/// Built-in operating systems map to the corresponding [OS] constants, while
/// custom extension operating systems are constructed via [OS.fromString] so
/// Dart build and link hooks receive the custom target OS identifier in
/// `HookConfig.code.targetOS`.
OS parseNativeOS(String rawOs) {
  final String normalized = rawOs.trim().toLowerCase();
  if (normalized.isEmpty) {
    throwToolExit('Unsupported native assets target OS "$rawOs".');
  }
  if (normalized == 'darwin') {
    return OS.macOS;
  }
  for (final OS builtinOs in OS.values) {
    if (builtinOs.name == normalized) {
      return builtinOs;
    }
  }
  return OS.fromString(normalized);
}

/// Parses a native [Architecture] from a target architecture string (such as
/// `x64` or `arm64`).
///
/// Common architecture aliases (`armv7`, `aarch64`, `x86`, `x86_64`, `amd64`)
/// are normalized to their canonical `package:code_assets` [Architecture]
/// constants, while custom architecture identifiers are constructed via
/// [Architecture.fromString].
Architecture parseNativeArchitecture(String rawArch) {
  final String normalized = rawArch.trim().toLowerCase();
  if (normalized.isEmpty) {
    throwToolExit('Unsupported native assets target architecture "$rawArch".');
  }
  return switch (normalized) {
    'arm' || 'armv7' => Architecture.arm,
    'arm64' || 'aarch64' => Architecture.arm64,
    'arm64e' => Architecture.arm64e,
    'ia32' || 'x86' => Architecture.ia32,
    'riscv32' => Architecture.riscv32,
    'riscv64' => Architecture.riscv64,
    'x64' || 'x86_64' || 'amd64' => Architecture.x64,
    _ => Architecture.fromString(normalized),
  };
}

/// Resolves the target [OS] and [Architecture] for an extension build target
/// from [environmentDefines].
///
/// Returns `null` unless both [kExtensionTargetOs] and [kExtensionTargetArch]
/// are explicitly defined.
(OS, Architecture)? resolveCustomNativeTarget(Map<String, String> environmentDefines) {
  final String? extensionTargetOs = _emptyToNull(environmentDefines[kExtensionTargetOs]);
  final String? extensionTargetArch = _emptyToNull(environmentDefines[kExtensionTargetArch]);
  if (extensionTargetOs == null || extensionTargetArch == null) {
    return null;
  }
  return (parseNativeOS(extensionTargetOs), parseNativeArchitecture(extensionTargetArch));
}

/// Resolves a [CCompilerConfig] from explicit `kExtensionCCompiler*` defines in
/// [environmentDefines], or returns `null` if compiler defines are not all provided.
CCompilerConfig? cCompilerConfigFromDefines(Map<String, String> environmentDefines) {
  final String? cc = _emptyToNull(environmentDefines[kExtensionCCompilerCc]);
  final String? ar = _emptyToNull(environmentDefines[kExtensionCCompilerAr]);
  final String? ld = _emptyToNull(environmentDefines[kExtensionCCompilerLd]);
  if (cc == null || ar == null || ld == null) {
    return null;
  }
  final String? envScript = _emptyToNull(environmentDefines[kExtensionCCompilerEnvScript]);
  final List<String> envScriptArgs = _parseEnvScriptArgs(
    environmentDefines[kExtensionCCompilerEnvScriptArgs],
  );
  return CCompilerConfig(
    archiver: Uri.file(ar),
    compiler: Uri.file(cc),
    linker: Uri.file(ld),
    windows: envScript == null
        ? null
        : WindowsCCompilerConfig(
            developerCommandPrompt: DeveloperCommandPrompt(
              script: Uri.file(envScript),
              arguments: envScriptArgs,
            ),
          ),
  );
}

List<String> _parseEnvScriptArgs(String? rawArgs) {
  if (rawArgs == null || rawArgs.isEmpty) {
    return const <String>[];
  }
  try {
    final Object? decoded = json.decode(rawArgs);
    if (decoded case final List<Object?> list) {
      return <String>[
        for (final Object? item in list)
          if (item is String)
            item
          else
            throwToolExit(
              'Invalid "$kExtensionCCompilerEnvScriptArgs" define: expected a JSON-encoded list of strings.',
            ),
      ];
    }
  } on FormatException {
    // Handled by throwToolExit below.
  }
  throwToolExit(
    'Invalid "$kExtensionCCompilerEnvScriptArgs" define: expected a JSON-encoded list of strings.',
  );
}

CCompilerConfig? _cCompilerConfigForCustomTarget({
  required Map<String, String> environmentDefines,
  required FileSystem fileSystem,
}) {
  final String? explicitCc = _emptyToNull(environmentDefines[kExtensionCCompilerCc]);
  if (explicitCc == null) {
    return null;
  }
  final compiler = Uri.file(explicitCc);
  final String compilerParentDir = fileSystem.file(compiler).parent.path;
  final Uri? archiver = _resolveSiblingExecutable(
    const <String>['llvm-ar', 'ar'],
    explicitPath: _emptyToNull(environmentDefines[kExtensionCCompilerAr]),
    fileSystem: fileSystem,
    siblingDir: compilerParentDir,
  );
  final Uri? linker = _resolveSiblingExecutable(
    const <String>['ld.lld', 'ld'],
    explicitPath: _emptyToNull(environmentDefines[kExtensionCCompilerLd]),
    fileSystem: fileSystem,
    siblingDir: compilerParentDir,
  );
  if (archiver == null || linker == null) {
    return null;
  }
  final String? envScript = _emptyToNull(environmentDefines[kExtensionCCompilerEnvScript]);
  final List<String> envScriptArgs = _parseEnvScriptArgs(
    environmentDefines[kExtensionCCompilerEnvScriptArgs],
  );
  return CCompilerConfig(
    archiver: archiver,
    compiler: compiler,
    linker: linker,
    windows: envScript == null
        ? null
        : WindowsCCompilerConfig(
            developerCommandPrompt: DeveloperCommandPrompt(
              script: Uri.file(envScript),
              arguments: envScriptArgs,
            ),
          ),
  );
}

Uri? _resolveSiblingExecutable(
  List<String> candidates, {
  required String? explicitPath,
  required FileSystem fileSystem,
  required String siblingDir,
}) {
  if (explicitPath != null) {
    return Uri.file(explicitPath);
  }
  for (final candidate in candidates) {
    final File candidateFile = fileSystem.file(fileSystem.path.join(siblingDir, candidate));
    if (candidateFile.existsSync()) {
      return candidateFile.uri;
    }
  }
  return null;
}
