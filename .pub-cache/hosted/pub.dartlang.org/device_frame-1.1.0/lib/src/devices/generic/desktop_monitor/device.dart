import 'package:device_frame/src/devices/generic/base/draw_extensions.dart';
import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:flutter/material.dart';

part 'frame.dart';

/// Creates a generic desktop monitor device definition for the given [name], target
/// [platform] and [screenSize]. The [windowPosition] defines the position of a virtual
/// window with a window frame adapted for the given platform.
DeviceInfo buildGenericDesktopMonitorDevice({
  required TargetPlatform platform,
  required String id,
  required String name,
  required Size screenSize,
  required Rect windowPosition,
  EdgeInsets safeAreas = EdgeInsets.zero,
  double pixelRatio = 2.0,
  EdgeInsets? rotatedSafeAreas,
  GenericDesktopMonitorFramePainter? framePainter,
}) {
  final effectivePainter = framePainter ??
      GenericDesktopMonitorFramePainter(
        platform: platform,
        windowPosition: windowPosition,
      );
  return DeviceInfo(
    identifier: DeviceIdentifier(
      platform,
      DeviceType.desktop,
      id,
    ),
    name: name,
    pixelRatio: pixelRatio,
    frameSize: effectivePainter.calculateFrameSize(screenSize),
    screenSize: effectivePainter.effectiveWindowSize,
    safeAreas: safeAreas,
    rotatedSafeAreas: rotatedSafeAreas,
    framePainter: effectivePainter,
    screenPath: effectivePainter.createScreenPath(screenSize),
  );
}
