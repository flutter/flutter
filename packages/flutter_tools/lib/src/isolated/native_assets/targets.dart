import 'package:file/file.dart' show FileSystem;
import 'package:native_assets_cli/code_assets_builder.dart'
    show
        AndroidCodeConfig,
        Architecture,
        BuildInputBuilder,
        CCompilerConfig,
        CodeAsset,
        CodeAssetBuildInputBuilder,
        HookConfigBuilder,
        IOSCodeConfig,
        LinkInputBuilder,
        LinkModePreference,
        MacOSCodeConfig,
        OS;
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
import 'native_assets.dart' show FlutterNativeAssetsBuildRunner, getNativeOSFromTargetPlatform;

sealed class TargetCls {
  const TargetCls({required this.platform, required this.supportedAssetTypes});

  final TargetPlatform platform;
  final List<String> supportedAssetTypes;

  BuildInputBuilder buildInputCreator() => BuildInputBuilder();
  LinkInputBuilder linkInputCreator() => LinkInputBuilder();

  List<String> get buildAssetTypes => supportedAssetTypes;
}

final class WebTargetCls extends TargetCls {
  WebTargetCls({required super.supportedAssetTypes})
    : super(platform: TargetPlatform.web_javascript);

  @override
  List<String> get buildAssetTypes =>
      supportedAssetTypes.where((String element) => element != CodeAsset.type).toList();
}

final class CodeTargetCls extends TargetCls {
  CodeTargetCls({
    required super.platform,
    required super.supportedAssetTypes,
    required this.architecture,
  });

  final Architecture architecture;

  late final CCompilerConfig? cCompilerConfigSync;

  Future<void> setCCompilerConfig(FlutterNativeAssetsBuildRunner buildRunner) async =>
      cCompilerConfigSync = await buildRunner.cCompilerConfig;

  void setupCode(HookConfigBuilder builder, Architecture architecture) {
    builder.setupCode(
      targetArchitecture: architecture,
      linkModePreference: LinkModePreference.dynamic,
      cCompiler: cCompilerConfigSync,
      targetOS: getNativeOSFromTargetPlatform(platform),
    );
  }

  @override
  BuildInputBuilder buildInputCreator() {
    final BuildInputBuilder buildInputBuilder = super.buildInputCreator();
    setupCode(buildInputBuilder.config, architecture);
    return buildInputBuilder;
  }

  @override
  LinkInputBuilder linkInputCreator() {
    final LinkInputBuilder linkInputBuilder = super.linkInputCreator();
    setupCode(linkInputBuilder.config, architecture);
    return linkInputBuilder;
  }
}

final class IOSTargetCls extends CodeTargetCls {
  IOSTargetCls({
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
  void setupCode(HookConfigBuilder builder, Architecture architecture) {
    builder.setupCode(
      targetArchitecture: architecture,
      linkModePreference: LinkModePreference.dynamic,
      cCompiler: cCompilerConfigSync,
      targetOS: OS.iOS,
      iOS: _getIOSConfig(environmentDefines, fileSystem),
    );
  }
}

final class MacOSTargetCls extends CodeTargetCls {
  MacOSTargetCls({required super.supportedAssetTypes, required super.architecture})
    : super(platform: TargetPlatform.darwin);

  @override
  void setupCode(HookConfigBuilder builder, Architecture architecture) {
    builder.setupCode(
      targetArchitecture: architecture,
      linkModePreference: LinkModePreference.dynamic,
      cCompiler: cCompilerConfigSync,
      targetOS: OS.macOS,
      macOS: MacOSCodeConfig(targetVersion: targetMacOSVersion),
    );
  }
}

final class AndroidTargetCls extends CodeTargetCls {
  AndroidTargetCls({
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
  void setupCode(HookConfigBuilder builder, Architecture architecture) {
    builder.setupCode(
      targetArchitecture: architecture,
      linkModePreference: LinkModePreference.dynamic,
      cCompiler: cCompilerConfigSync,
      targetOS: OS.android,
      android: _androidCodeConfig,
    );
  }
}

final class TesterTargetCls extends CodeTargetCls {
  TesterTargetCls({required super.supportedAssetTypes})
    : super(architecture: Architecture.current, platform: TargetPlatform.tester);
}

List<TargetCls> targetsForPlatform(
  TargetPlatform targetPlatform,
  Map<String, String> environmentDefines,
  FileSystem fileSystem,
  List<String> supportedAssetTypes,
) {
  switch (targetPlatform) {
    case TargetPlatform.linux_x64:
    case TargetPlatform.windows_x64:
      return <TargetCls>[
        CodeTargetCls(
          platform: targetPlatform,
          architecture: Architecture.x64,
          supportedAssetTypes: supportedAssetTypes,
        ),
      ];
    case TargetPlatform.linux_arm64:
    case TargetPlatform.windows_arm64:
      return <TargetCls>[
        CodeTargetCls(
          platform: targetPlatform,
          architecture: Architecture.arm64,
          supportedAssetTypes: supportedAssetTypes,
        ),
      ];
    case TargetPlatform.darwin:
      return getDarwinArchsFromEnv(environmentDefines)
          .map(getNativeMacOSArchitecture)
          .map(
            (Architecture arch) =>
                MacOSTargetCls(architecture: arch, supportedAssetTypes: supportedAssetTypes),
          )
          .toList();
    case TargetPlatform.android:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      final String? androidArchsEnvironment = environmentDefines[kAndroidArchs];
      final List<AndroidArch> androidArchs = _androidArchs(targetPlatform, androidArchsEnvironment);
      return androidArchs
          .map(getNativeAndroidArchitecture)
          .map(
            (Architecture e) => CodeTargetCls(
              platform: targetPlatform,
              architecture: e,
              supportedAssetTypes: supportedAssetTypes,
            ),
          )
          .toList();
    case TargetPlatform.ios:
      final List<DarwinArch> iosArchs =
          _emptyToNull(environmentDefines[kIosArchs])?.split(' ').map(getIOSArchForName).toList() ??
          <DarwinArch>[DarwinArch.arm64];
      return iosArchs
          .map(getNativeIOSArchitecture)
          .map(
            (Architecture arch) => IOSTargetCls(
              environmentDefines: environmentDefines,
              fileSystem: fileSystem,
              architecture: arch,
              supportedAssetTypes: supportedAssetTypes,
            ),
          )
          .toList();
    case TargetPlatform.web_javascript:
      return <TargetCls>[WebTargetCls(supportedAssetTypes: supportedAssetTypes)];
    case TargetPlatform.tester:
      return <TargetCls>[TesterTargetCls(supportedAssetTypes: supportedAssetTypes)];
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
      throw UnsupportedError('No targets defined for target platform $targetPlatform.');
  }
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
