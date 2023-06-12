// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flutter_launcher_icons_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlutterLauncherIconsConfig _$FlutterLauncherIconsConfigFromJson(Map json) =>
    $checkedCreate(
      'FlutterLauncherIconsConfig',
      json,
      ($checkedConvert) {
        final val = FlutterLauncherIconsConfig(
          imagePath: $checkedConvert('image_path', (v) => v as String?),
          android: $checkedConvert('android', (v) => v ?? false),
          ios: $checkedConvert('ios', (v) => v ?? false),
          imagePathAndroid:
              $checkedConvert('image_path_android', (v) => v as String?),
          imagePathIOS: $checkedConvert('image_path_ios', (v) => v as String?),
          adaptiveIconForeground:
              $checkedConvert('adaptive_icon_foreground', (v) => v as String?),
          adaptiveIconBackground:
              $checkedConvert('adaptive_icon_background', (v) => v as String?),
          minSdkAndroid: $checkedConvert('min_sdk_android',
              (v) => v as int? ?? constants.androidDefaultAndroidMinSDK),
          removeAlphaIOS:
              $checkedConvert('remove_alpha_ios', (v) => v as bool? ?? false),
          webConfig: $checkedConvert(
              'web', (v) => v == null ? null : WebConfig.fromJson(v as Map)),
          windowsConfig: $checkedConvert('windows',
              (v) => v == null ? null : WindowsConfig.fromJson(v as Map)),
          macOSConfig: $checkedConvert('macos',
              (v) => v == null ? null : MacOSConfig.fromJson(v as Map)),
        );
        return val;
      },
      fieldKeyMap: const {
        'imagePath': 'image_path',
        'imagePathAndroid': 'image_path_android',
        'imagePathIOS': 'image_path_ios',
        'adaptiveIconForeground': 'adaptive_icon_foreground',
        'adaptiveIconBackground': 'adaptive_icon_background',
        'minSdkAndroid': 'min_sdk_android',
        'removeAlphaIOS': 'remove_alpha_ios',
        'webConfig': 'web',
        'windowsConfig': 'windows',
        'macOSConfig': 'macos'
      },
    );

Map<String, dynamic> _$FlutterLauncherIconsConfigToJson(
        FlutterLauncherIconsConfig instance) =>
    <String, dynamic>{
      'image_path': instance.imagePath,
      'android': instance.android,
      'ios': instance.ios,
      'image_path_android': instance.imagePathAndroid,
      'image_path_ios': instance.imagePathIOS,
      'adaptive_icon_foreground': instance.adaptiveIconForeground,
      'adaptive_icon_background': instance.adaptiveIconBackground,
      'min_sdk_android': instance.minSdkAndroid,
      'remove_alpha_ios': instance.removeAlphaIOS,
      'web': instance.webConfig,
      'windows': instance.windowsConfig,
      'macos': instance.macOSConfig,
    };

MacOSConfig _$MacOSConfigFromJson(Map json) => $checkedCreate(
      'MacOSConfig',
      json,
      ($checkedConvert) {
        final val = MacOSConfig(
          generate: $checkedConvert('generate', (v) => v as bool? ?? false),
          imagePath: $checkedConvert('image_path', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'imagePath': 'image_path'},
    );

Map<String, dynamic> _$MacOSConfigToJson(MacOSConfig instance) =>
    <String, dynamic>{
      'generate': instance.generate,
      'image_path': instance.imagePath,
    };

WebConfig _$WebConfigFromJson(Map json) => $checkedCreate(
      'WebConfig',
      json,
      ($checkedConvert) {
        final val = WebConfig(
          generate: $checkedConvert('generate', (v) => v as bool? ?? false),
          imagePath: $checkedConvert('image_path', (v) => v as String?),
          backgroundColor:
              $checkedConvert('background_color', (v) => v as String?),
          themeColor: $checkedConvert('theme_color', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'imagePath': 'image_path',
        'backgroundColor': 'background_color',
        'themeColor': 'theme_color'
      },
    );

Map<String, dynamic> _$WebConfigToJson(WebConfig instance) => <String, dynamic>{
      'generate': instance.generate,
      'image_path': instance.imagePath,
      'background_color': instance.backgroundColor,
      'theme_color': instance.themeColor,
    };

WindowsConfig _$WindowsConfigFromJson(Map json) => $checkedCreate(
      'WindowsConfig',
      json,
      ($checkedConvert) {
        final val = WindowsConfig(
          generate: $checkedConvert('generate', (v) => v as bool? ?? false),
          imagePath: $checkedConvert('image_path', (v) => v as String?),
          iconSize: $checkedConvert('icon_size', (v) => v as int?),
        );
        return val;
      },
      fieldKeyMap: const {'imagePath': 'image_path', 'iconSize': 'icon_size'},
    );

Map<String, dynamic> _$WindowsConfigToJson(WindowsConfig instance) =>
    <String, dynamic>{
      'generate': instance.generate,
      'image_path': instance.imagePath,
      'icon_size': instance.iconSize,
    };
