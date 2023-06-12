import 'package:device_preview/device_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utilities/json_converters.dart';
import 'package:flutter/foundation.dart';

part 'state.freezed.dart';
part 'state.g.dart';

/// Represents the current state of the device preview.
@freezed
class DevicePreviewState with _$DevicePreviewState {
  /// The device preview has not been initialized yet.
  const factory DevicePreviewState.notInitialized() =
      _NotInitializedDevicePreviewState;

  /// The device preview is currently being initialized.
  const factory DevicePreviewState.initializing() =
      _InitializingDevicePreviewState;

  /// The device preview is available.
  const factory DevicePreviewState.initialized({
    /// The list of all available devices.
    required List<DeviceInfo> devices,

    /// The list of all available locales.
    required List<NamedLocale> locales,

    /// The user settings of the preview.
    required DevicePreviewData data,
  }) = _InitializedDevicePreviewState;
}

/// A [DevicePreview] configuration snapshot that can be
/// serialized to be persisted between sessions.
@freezed
class DevicePreviewData with _$DevicePreviewData {
  /// Create a new [DevicePreviewData] configuration from all
  /// properties.
  const factory DevicePreviewData({
    /// Indicate whether the toolbar is visible.
    @Default(true) bool isToolbarVisible,

    /// Indicate whether the device simulation is enabled.
    @Default(true) bool isEnabled,

    /// The current orientation of the device
    @Default(Orientation.portrait) Orientation orientation,

    /// The currently selected device.
    String? deviceIdentifier,

    /// The currently selected device locale.
    @Default('en-US') String locale,

    /// Indicate whether the frame is currently visible.
    @Default(true) bool isFrameVisible,

    /// Indicate whether the mode is currently dark.
    @Default(false) bool isDarkMode,

    /// Indicate whether texts are forced to bold.
    @Default(false) bool boldText,

    /// Indicate whether the virtual keyboard is visible.
    @Default(false) bool isVirtualKeyboardVisible,

    /// Indicate whether animations are disabled.
    @Default(false) bool disableAnimations,

    /// Indicate whether the highcontrast mode is activated.
    @Default(false) bool highContrast,

    /// Indicate whether the navigation is in accessible mode.
    @Default(false) bool accessibleNavigation,

    /// Indicate whether image colors are inverted.
    @Default(false) bool invertColors,

    /// Indicate whether image colors are inverted.
    @Default(<String, Map<String, dynamic>>{})
        Map<String, Map<String, dynamic>> pluginData,

    /// The current text scaling factor.
    @Default(1.0) double textScaleFactor,
    DevicePreviewSettingsData? settings,

    /// The custom device configuration
    @Default(null) CustomDeviceInfoData? customDevice,
  }) = _DevicePreviewData;

  factory DevicePreviewData.fromJson(Map<String, dynamic> json) =>
      _$DevicePreviewDataFromJson(json);
}

/// Info about a device and its frame.
@freezed
class CustomDeviceInfoData with _$CustomDeviceInfoData {
  /// Create a new device info.
  const factory CustomDeviceInfoData({
    /// Identifier of the device.
    required String id,

    /// The device type.
    required DeviceType type,

    /// The device operating system.
    required TargetPlatform platform,

    /// The display name of the device.
    required String name,

    /// The safe areas when the device is in landscape orientation.
    @Default(null)
    @NullableEdgeInsetsJsonConverter()
        EdgeInsets? rotatedSafeAreas,

    /// The safe areas when the device is in portrait orientation.
    @EdgeInsetsJsonConverter() required EdgeInsets safeAreas,

    /// The screen pixel density of the device.
    required double pixelRatio,

    /// The size in points of the screen content.
    @SizeJsonConverter() required Size screenSize,
  }) = _CustomDeviceInfoData;

  factory CustomDeviceInfoData.fromJson(Map<String, dynamic> json) =>
      _$CustomDeviceInfoDataFromJson(json);
}

/// Settings of device preview itself (tool bar position, background style).
@freezed
abstract class DevicePreviewSettingsData with _$DevicePreviewSettingsData {
  /// Create a new set of settings.
  const factory DevicePreviewSettingsData({
    /// The toolbar position.
    @Default(DevicePreviewToolBarPositionData.bottom)
        DevicePreviewToolBarPositionData toolbarPosition,

    /// The theme of the toolbar.
    @Default(DevicePreviewToolBarThemeData.dark)
        DevicePreviewToolBarThemeData toolbarTheme,

    /// The theme of the background.
    @Default(DevicePreviewBackgroundThemeData.light)
        DevicePreviewBackgroundThemeData backgroundTheme,
  }) = _DevicePreviewSettingsData;

  factory DevicePreviewSettingsData.fromJson(Map<String, dynamic> json) =>
      _$DevicePreviewSettingsDataFromJson(json);
}

enum DevicePreviewToolBarThemeData {
  dark,
  light,
}

enum DevicePreviewBackgroundThemeData {
  dark,
  light,
}

enum DevicePreviewToolBarPositionData {
  bottom,
  top,
  left,
  right,
}
