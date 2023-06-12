import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart' as yaml;
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path;

import 'constants.dart' as constants;
import 'custom_exceptions.dart';
import 'utils.dart' as utils;

part 'flutter_launcher_icons_config.g.dart';

/// A Config parsed from flutter_launcher_config.yaml
@JsonSerializable(
  anyMap: true,
  checked: true,
)
class FlutterLauncherIconsConfig {
  /// Generic imagepath
  @JsonKey(name: 'image_path')
  final String? imagePath;

  /// Returns true or path if android config is enabled
  final dynamic android; // path or bool

  /// Returns true or path if ios config is enabled
  final dynamic ios; // path or bool

  /// Image path specific to android
  @JsonKey(name: 'image_path_android')
  final String? imagePathAndroid;

  /// Image path specific to ios
  @JsonKey(name: 'image_path_ios')
  final String? imagePathIOS;

  /// android adaptive icon foreground image
  @JsonKey(name: 'adaptive_icon_foreground')
  final String? adaptiveIconForeground;

  /// android adaptive_icon_background image
  @JsonKey(name: 'adaptive_icon_background')
  final String? adaptiveIconBackground;

  /// Android min_sdk_android
  @JsonKey(name: 'min_sdk_android')
  final int minSdkAndroid;

  /// IOS remove_alpha_ios
  @JsonKey(name: 'remove_alpha_ios')
  final bool removeAlphaIOS;

  /// Web platform config
  @JsonKey(name: 'web')
  final WebConfig? webConfig;

  /// Windows platform config
  @JsonKey(name: 'windows')
  final WindowsConfig? windowsConfig;

  /// MacOS platform config
  @JsonKey(name: 'macos')
  final MacOSConfig? macOSConfig;

  /// Creates an instance of [FlutterLauncherIconsConfig]
  const FlutterLauncherIconsConfig({
    this.imagePath,
    this.android = false,
    this.ios = false,
    this.imagePathAndroid,
    this.imagePathIOS,
    this.adaptiveIconForeground,
    this.adaptiveIconBackground,
    this.minSdkAndroid = constants.androidDefaultAndroidMinSDK,
    this.removeAlphaIOS = false,
    this.webConfig,
    this.windowsConfig,
    this.macOSConfig,
  });

  /// Creates [FlutterLauncherIconsConfig] icons from [json]
  factory FlutterLauncherIconsConfig.fromJson(Map json) =>
      _$FlutterLauncherIconsConfigFromJson(json);

  bool get hasAndroidAdaptiveConfig =>
      isNeedingNewAndroidIcon &&
      adaptiveIconForeground != null &&
      adaptiveIconBackground != null;

  /// Checks if contains any platform config
  bool get hasPlatformConfig {
    return ios != false ||
        android != false ||
        webConfig != null ||
        windowsConfig != null ||
        macOSConfig != null;
  }

  /// Check to see if specified Android config is a string or bool
  /// String - Generate new launcher icon with the string specified
  /// bool - override the default flutter project icon
  bool get isCustomAndroidFile => android is String;

  bool get isNeedingNewAndroidIcon => android != false;

  bool get isNeedingNewIOSIcon => ios != false;

  /// Method for the retrieval of the Android icon path
  /// If image_path_android is found, this will be prioritised over the image_path
  /// value.
  String? getImagePathAndroid() => imagePathAndroid ?? imagePath;
  // todo: refactor after Android & iOS configs will be refactored to the new schema
  // https://github.com/fluttercommunity/flutter_launcher_icons/issues/394
  String? getImagePathIOS() => imagePathIOS ?? imagePath;

  /// Converts config to [Map]
  Map<String, dynamic> toJson() => _$FlutterLauncherIconsConfigToJson(this);

  @override
  String toString() => 'FlutterLauncherIconsConfig: ${toJson()}';

  /// Creates [FlutterLauncherIconsConfig] for given [flavor] and [prefixPath]
  static FlutterLauncherIconsConfig? loadConfigFromFlavor(
    String flavor,
    String prefixPath,
  ) {
    return FlutterLauncherIconsConfig.loadConfigFromPath(
      utils.flavorConfigFile(flavor),
      prefixPath,
    );
  }

  /// Loads flutter launcher icons configs from given [filePath]
  static FlutterLauncherIconsConfig? loadConfigFromPath(
    String filePath,
    String prefixPath,
  ) {
    final configFile = File(path.join(prefixPath, filePath));
    if (!configFile.existsSync()) {
      return null;
    }
    final configContent = configFile.readAsStringSync();
    try {
      return yaml.checkedYamlDecode<FlutterLauncherIconsConfig?>(
        configContent,
        (json) {
          // todo: add support for new scheme https://github.com/fluttercommunity/flutter_launcher_icons/issues/373
          return json == null || json['flutter_icons'] == null
              ? null
              : FlutterLauncherIconsConfig.fromJson(json['flutter_icons']);
        },
        allowNull: true,
      );
    } on yaml.ParsedYamlException catch (e) {
      throw InvalidConfigException(e.formattedMessage);
    } catch (e) {
      rethrow;
    }
  }

  /// Loads flutter launcher icons config from `pubspec.yaml` file
  static FlutterLauncherIconsConfig? loadConfigFromPubSpec(String prefix) {
    try {
      final pubspecFile = File(path.join(prefix, constants.pubspecFilePath));
      if (!pubspecFile.existsSync()) {
        return null;
      }
      final pubspecContent = pubspecFile.readAsStringSync();
      return yaml.checkedYamlDecode<FlutterLauncherIconsConfig?>(
        pubspecContent,
        (json) {
          // todo: add support for new scheme https://github.com/fluttercommunity/flutter_launcher_icons/issues/373
          return json == null || json['flutter_icons'] == null
              ? null
              : FlutterLauncherIconsConfig.fromJson(json['flutter_icons']);
        },
        allowNull: true,
      );
    } on yaml.ParsedYamlException catch (e) {
      throw InvalidConfigException(e.formattedMessage);
    } catch (e) {
      rethrow;
    }
  }
}

/// A Configs for Windows
@JsonSerializable(
  anyMap: true,
  checked: true,
)
class MacOSConfig {
  /// Specifies weather to generate icons for macos
  @JsonKey()
  final bool generate;

  /// Image path for macos
  @JsonKey(name: 'image_path')
  final String? imagePath;

  /// Creates a instance of [MacOSConfig]
  const MacOSConfig({
    this.generate = false,
    this.imagePath,
  });

  /// Creates [WebConfig] from [json]
  factory MacOSConfig.fromJson(Map json) => _$MacOSConfigFromJson(json);

  /// Creates [Map] from [WebConfig]
  Map<String, dynamic> toJson() => _$MacOSConfigToJson(this);

  @override
  String toString() => '$runtimeType: ${toJson()}';
}

/// Parse `web` config from `flutter_launcher_icons.yaml`
@JsonSerializable(
  anyMap: true,
  checked: true,
)
class WebConfig {
  /// Specifies weather to generate icons for web
  final bool generate;

  /// Image path for web
  @JsonKey(name: 'image_path')
  final String? imagePath;

  /// manifest.json's background_color
  @JsonKey(name: 'background_color')
  final String? backgroundColor;

  /// manifest.json's theme_color
  @JsonKey(name: 'theme_color')
  final String? themeColor;

  /// Creates an instance of [WebConfig]
  const WebConfig({
    this.generate = false,
    this.imagePath,
    this.backgroundColor,
    this.themeColor,
  });

  /// Creates [WebConfig] from [json]
  factory WebConfig.fromJson(Map json) => _$WebConfigFromJson(json);

  /// Creates [Map] from [WebConfig]
  Map<String, dynamic> toJson() => _$WebConfigToJson(this);

  @override
  String toString() => 'WebConfig: ${toJson()}';
}

/// A Configs for Windows
@JsonSerializable(
  anyMap: true,
  checked: true,
)
class WindowsConfig {
  /// Specifies weather to generate icons for web
  final bool generate;

  /// Image path for web
  @JsonKey(name: 'image_path')
  final String? imagePath;

  /// Size of the icon to generate
  @JsonKey(name: 'icon_size')
  final int? iconSize;

  /// Creates a instance of [WindowsConfig]
  const WindowsConfig({
    this.generate = false,
    this.imagePath,
    this.iconSize,
  });

  /// Creates [WindowsConfig] from [json]
  factory WindowsConfig.fromJson(Map json) => _$WindowsConfigFromJson(json);

  /// Creates [Map] from [WindowsConfig]
  Map toJson() => _$WindowsConfigToJson(this);

  @override
  String toString() => 'WindowsConfig: ${toJson()}';
}
