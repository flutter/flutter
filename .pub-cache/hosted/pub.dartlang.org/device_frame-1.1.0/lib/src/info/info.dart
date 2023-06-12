import 'package:device_frame/src/devices/generic/desktop_monitor/device.dart';
import 'package:device_frame/src/devices/generic/laptop/device.dart';
import 'package:device_frame/src/devices/generic/phone/device.dart';
import 'package:device_frame/src/devices/generic/tablet/device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'identifier.dart';

part 'info.freezed.dart';

/// Info about a device and its frame.
@freezed
abstract class DeviceInfo with _$DeviceInfo {
  /// Create a new device info.
  const factory DeviceInfo({
    /// Identifier of the device.
    required DeviceIdentifier identifier,

    /// The display name of the device.
    required String name,

    /// The safe areas when the device is in landscape orientation.
    @Default(null) EdgeInsets? rotatedSafeAreas,

    /// The safe areas when the device is in portrait orientation.
    required EdgeInsets safeAreas,

    /// A shape representing the screen.
    required Path screenPath,

    /// The screen pixel density of the device.
    required double pixelRatio,

    /// The safe areas when the device is in portrait orientation.
    required CustomPainter framePainter,

    /// The frame size in pixels.
    required Size frameSize,

    /// The size in points of the screen content.
    required Size screenSize,
  }) = _DeviceInfo;

  factory DeviceInfo.genericTablet({
    required TargetPlatform platform,
    required String id,
    required String name,
    required Size screenSize,
    EdgeInsets safeAreas = EdgeInsets.zero,
    EdgeInsets rotatedSafeAreas = EdgeInsets.zero,
    double pixelRatio = 2.0,
    GenericTabletFramePainter framePainter = const GenericTabletFramePainter(),
  }) =>
      buildGenericTabletDevice(
        platform: platform,
        id: id,
        name: name,
        screenSize: screenSize,
        safeAreas: safeAreas,
        rotatedSafeAreas: rotatedSafeAreas,
        pixelRatio: pixelRatio,
        framePainter: framePainter,
      );

  factory DeviceInfo.genericPhone({
    required TargetPlatform platform,
    required String id,
    required String name,
    required Size screenSize,
    EdgeInsets safeAreas = EdgeInsets.zero,
    EdgeInsets rotatedSafeAreas = EdgeInsets.zero,
    double pixelRatio = 2.0,
    GenericPhoneFramePainter framePainter = const GenericPhoneFramePainter(),
  }) =>
      buildGenericPhoneDevice(
        platform: platform,
        id: id,
        name: name,
        screenSize: screenSize,
        safeAreas: safeAreas,
        rotatedSafeAreas: rotatedSafeAreas,
        pixelRatio: pixelRatio,
        framePainter: framePainter,
      );

  factory DeviceInfo.genericDesktopMonitor({
    required TargetPlatform platform,
    required String id,
    required String name,
    required Size screenSize,
    required Rect windowPosition,
    EdgeInsets safeAreas = EdgeInsets.zero,
    double pixelRatio = 2.0,
    GenericDesktopMonitorFramePainter? framePainter,
  }) =>
      buildGenericDesktopMonitorDevice(
        platform: platform,
        id: id,
        name: name,
        screenSize: screenSize,
        windowPosition: windowPosition,
        safeAreas: safeAreas,
        pixelRatio: pixelRatio,
        framePainter: framePainter,
      );

  factory DeviceInfo.genericLaptop({
    required TargetPlatform platform,
    required String id,
    required String name,
    required Size screenSize,
    required Rect windowPosition,
    EdgeInsets safeAreas = EdgeInsets.zero,
    double pixelRatio = 2.0,
    GenericLaptopFramePainter? framePainter,
  }) =>
      buildGenericLaptopDevice(
        platform: platform,
        id: id,
        name: name,
        screenSize: screenSize,
        windowPosition: windowPosition,
        safeAreas: safeAreas,
        pixelRatio: pixelRatio,
        framePainter: framePainter,
      );
}

extension DeviceInfoExtension on DeviceInfo {
  /// Indicates whether the device can rotate.
  bool get canRotate => rotatedSafeAreas != null;

  /// Indicates whether the current device info should be in landscape.
  ///
  /// This is true only if the device can rotate.
  bool isLandscape(Orientation orientation) {
    return canRotate && orientation == Orientation.landscape;
  }
}
