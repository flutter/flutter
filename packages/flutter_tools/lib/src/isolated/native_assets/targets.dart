import 'package:file/file.dart' show FileSystem;
import 'package:native_assets_cli/code_assets_builder.dart';
import '../../base/common.dart' show throwToolExit;
import '../../build_info.dart';
import '../../build_system/exceptions.dart' show MissingDefineException;
import '../../macos/xcode.dart' as xcode show environmentTypeFromSdkroot;
import 'android/native_assets.dart' show getNativeAndroidArchitecture, targetAndroidNdkApi;
import 'ios/native_assets.dart' show getIOSSdk, getNativeIOSArchitecture, targetIOSVersion;
import 'macos/native_assets.dart' show getNativeMacOSArchitecture, targetMacOSVersion;
import 'native_assets.dart' show FlutterNativeAssetsBuildRunner, getNativeOSFromTargetPlatform;

sealed class TargetCls {
  TargetCls({required this.platform});

  final TargetPlatform platform;

  BuildInputBuilder buildInputCreator();
  LinkInputBuilder linkInputCreator();
  List<String> buildAssetTypes(List<String> supportedAssetTypes) => supportedAssetTypes;
}

final class WebTargetCls extends TargetCls {
  WebTargetCls({required super.platform});

  @override
  BuildInputBuilder buildInputCreator() => BuildInputBuilder();
  @override
  LinkInputBuilder linkInputCreator() => LinkInputBuilder();

  @override
  List<String> buildAssetTypes(List<String> supportedAssetTypes) =>
      supportedAssetTypes.where((String element) => element != CodeAsset.type).toList();
}

final class CodeTargetCls extends TargetCls {
  CodeTargetCls({required super.platform, required this.architecture});
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
    final BuildInputBuilder buildInputBuilder = BuildInputBuilder();
    setupCode(buildInputBuilder.config, architecture);
    return buildInputBuilder;
  }

  @override
  LinkInputBuilder linkInputCreator() {
    final LinkInputBuilder linkInputBuilder = LinkInputBuilder();
    setupCode(linkInputBuilder.config, architecture);
    return linkInputBuilder;
  }
}

List<TargetCls> targetsForPlatform(
  TargetPlatform targetPlatform,
  Map<String, String> environmentDefines,
  FileSystem fileSystem,
) {
  switch (targetPlatform) {
    case TargetPlatform.linux_x64:
    case TargetPlatform.linux_arm64:
    case TargetPlatform.windows_x64:
    case TargetPlatform.windows_arm64:
      return <TargetCls>[
        CodeTargetCls(
          platform: targetPlatform,
          architecture: _getNativeArchitecture(targetPlatform),
        ),
      ];
    case TargetPlatform.darwin:
      return getDarwinArchsFromEnv(environmentDefines)
          .map(getNativeMacOSArchitecture)
          .map((Architecture arch) => MacOSTargetCls(platform: targetPlatform, architecture: arch))
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
          .map((Architecture e) => CodeTargetCls(platform: targetPlatform, architecture: e))
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
              platform: targetPlatform,
              architecture: arch,
            ),
          )
          .toList();
    case TargetPlatform.web_javascript:
      return <TargetCls>[WebTargetCls(platform: targetPlatform)];
    case TargetPlatform.tester:
      return <TargetCls>[
        CodeTargetCls(platform: targetPlatform, architecture: Architecture.current),
      ];
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
      throw UnsupportedError('');
  }
}

final class IOSTargetCls extends CodeTargetCls {
  IOSTargetCls({
    required this.environmentDefines,
    required this.fileSystem,
    required super.platform,
    required super.architecture,
  });

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
  MacOSTargetCls({required super.platform, required super.architecture});

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

Architecture _getNativeArchitecture(TargetPlatform targetPlatform) {
  switch (targetPlatform) {
    case TargetPlatform.linux_x64:
    case TargetPlatform.windows_x64:
      return Architecture.x64;
    case TargetPlatform.linux_arm64:
    case TargetPlatform.windows_arm64:
      return Architecture.arm64;
    case TargetPlatform.android:
    case TargetPlatform.ios:
    case TargetPlatform.darwin:
    case TargetPlatform.fuchsia_arm64:
    case TargetPlatform.fuchsia_x64:
    case TargetPlatform.tester:
    case TargetPlatform.web_javascript:
    case TargetPlatform.android_arm:
    case TargetPlatform.android_arm64:
    case TargetPlatform.android_x64:
    case TargetPlatform.android_x86:
      throw Exception('Unknown targetPlatform: $targetPlatform.');
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
