// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_DevicePreviewData _$$_DevicePreviewDataFromJson(Map<String, dynamic> json) =>
    _$_DevicePreviewData(
      isToolbarVisible: json['isToolbarVisible'] as bool? ?? true,
      isEnabled: json['isEnabled'] as bool? ?? true,
      orientation:
          $enumDecodeNullable(_$OrientationEnumMap, json['orientation']) ??
              Orientation.portrait,
      deviceIdentifier: json['deviceIdentifier'] as String?,
      locale: json['locale'] as String? ?? 'en-US',
      isFrameVisible: json['isFrameVisible'] as bool? ?? true,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      boldText: json['boldText'] as bool? ?? false,
      isVirtualKeyboardVisible:
          json['isVirtualKeyboardVisible'] as bool? ?? false,
      disableAnimations: json['disableAnimations'] as bool? ?? false,
      highContrast: json['highContrast'] as bool? ?? false,
      accessibleNavigation: json['accessibleNavigation'] as bool? ?? false,
      invertColors: json['invertColors'] as bool? ?? false,
      pluginData: (json['pluginData'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as Map<String, dynamic>),
          ) ??
          const <String, Map<String, dynamic>>{},
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      settings: json['settings'] == null
          ? null
          : DevicePreviewSettingsData.fromJson(
              json['settings'] as Map<String, dynamic>),
      customDevice: json['customDevice'] == null
          ? null
          : CustomDeviceInfoData.fromJson(
              json['customDevice'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_DevicePreviewDataToJson(
        _$_DevicePreviewData instance) =>
    <String, dynamic>{
      'isToolbarVisible': instance.isToolbarVisible,
      'isEnabled': instance.isEnabled,
      'orientation': _$OrientationEnumMap[instance.orientation],
      'deviceIdentifier': instance.deviceIdentifier,
      'locale': instance.locale,
      'isFrameVisible': instance.isFrameVisible,
      'isDarkMode': instance.isDarkMode,
      'boldText': instance.boldText,
      'isVirtualKeyboardVisible': instance.isVirtualKeyboardVisible,
      'disableAnimations': instance.disableAnimations,
      'highContrast': instance.highContrast,
      'accessibleNavigation': instance.accessibleNavigation,
      'invertColors': instance.invertColors,
      'pluginData': instance.pluginData,
      'textScaleFactor': instance.textScaleFactor,
      'settings': instance.settings,
      'customDevice': instance.customDevice,
    };

const _$OrientationEnumMap = {
  Orientation.portrait: 'portrait',
  Orientation.landscape: 'landscape',
};

_$_CustomDeviceInfoData _$$_CustomDeviceInfoDataFromJson(
        Map<String, dynamic> json) =>
    _$_CustomDeviceInfoData(
      id: json['id'] as String,
      type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
      platform: $enumDecode(_$TargetPlatformEnumMap, json['platform']),
      name: json['name'] as String,
      rotatedSafeAreas: json['rotatedSafeAreas'] == null
          ? null
          : const NullableEdgeInsetsJsonConverter()
              .fromJson(json['rotatedSafeAreas']),
      safeAreas: const EdgeInsetsJsonConverter().fromJson(json['safeAreas']),
      pixelRatio: (json['pixelRatio'] as num).toDouble(),
      screenSize: const SizeJsonConverter().fromJson(json['screenSize']),
    );

Map<String, dynamic> _$$_CustomDeviceInfoDataToJson(
        _$_CustomDeviceInfoData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$DeviceTypeEnumMap[instance.type],
      'platform': _$TargetPlatformEnumMap[instance.platform],
      'name': instance.name,
      'rotatedSafeAreas': const NullableEdgeInsetsJsonConverter()
          .toJson(instance.rotatedSafeAreas),
      'safeAreas': const EdgeInsetsJsonConverter().toJson(instance.safeAreas),
      'pixelRatio': instance.pixelRatio,
      'screenSize': const SizeJsonConverter().toJson(instance.screenSize),
    };

const _$DeviceTypeEnumMap = {
  DeviceType.unknown: 'unknown',
  DeviceType.phone: 'phone',
  DeviceType.tablet: 'tablet',
  DeviceType.tv: 'tv',
  DeviceType.desktop: 'desktop',
  DeviceType.laptop: 'laptop',
};

const _$TargetPlatformEnumMap = {
  TargetPlatform.android: 'android',
  TargetPlatform.fuchsia: 'fuchsia',
  TargetPlatform.iOS: 'iOS',
  TargetPlatform.linux: 'linux',
  TargetPlatform.macOS: 'macOS',
  TargetPlatform.windows: 'windows',
};

_$_DevicePreviewSettingsData _$$_DevicePreviewSettingsDataFromJson(
        Map<String, dynamic> json) =>
    _$_DevicePreviewSettingsData(
      toolbarPosition: $enumDecodeNullable(
              _$DevicePreviewToolBarPositionDataEnumMap,
              json['toolbarPosition']) ??
          DevicePreviewToolBarPositionData.bottom,
      toolbarTheme: $enumDecodeNullable(
              _$DevicePreviewToolBarThemeDataEnumMap, json['toolbarTheme']) ??
          DevicePreviewToolBarThemeData.dark,
      backgroundTheme: $enumDecodeNullable(
              _$DevicePreviewBackgroundThemeDataEnumMap,
              json['backgroundTheme']) ??
          DevicePreviewBackgroundThemeData.light,
    );

Map<String, dynamic> _$$_DevicePreviewSettingsDataToJson(
        _$_DevicePreviewSettingsData instance) =>
    <String, dynamic>{
      'toolbarPosition':
          _$DevicePreviewToolBarPositionDataEnumMap[instance.toolbarPosition],
      'toolbarTheme':
          _$DevicePreviewToolBarThemeDataEnumMap[instance.toolbarTheme],
      'backgroundTheme':
          _$DevicePreviewBackgroundThemeDataEnumMap[instance.backgroundTheme],
    };

const _$DevicePreviewToolBarPositionDataEnumMap = {
  DevicePreviewToolBarPositionData.bottom: 'bottom',
  DevicePreviewToolBarPositionData.top: 'top',
  DevicePreviewToolBarPositionData.left: 'left',
  DevicePreviewToolBarPositionData.right: 'right',
};

const _$DevicePreviewToolBarThemeDataEnumMap = {
  DevicePreviewToolBarThemeData.dark: 'dark',
  DevicePreviewToolBarThemeData.light: 'light',
};

const _$DevicePreviewBackgroundThemeDataEnumMap = {
  DevicePreviewBackgroundThemeData.dark: 'dark',
  DevicePreviewBackgroundThemeData.light: 'light',
};
