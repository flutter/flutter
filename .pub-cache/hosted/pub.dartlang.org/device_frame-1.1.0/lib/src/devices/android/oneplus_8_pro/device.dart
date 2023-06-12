import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:flutter/material.dart';

part 'frame.g.dart';
part 'screen.g.dart';

final info = DeviceInfo(
  identifier: const DeviceIdentifier(
    TargetPlatform.android,
    DeviceType.phone,
    'oneplus-8-pro',
  ),
  name: 'OnePlus 8 Pro',
  pixelRatio: 4.0,
  safeAreas: const EdgeInsets.only(
    left: 0.0,
    top: 40.0,
    right: 0.0,
    bottom: 20.0,
  ),
  rotatedSafeAreas: const EdgeInsets.only(
    left: 40.0,
    top: 24.0,
    right: 40.0,
    bottom: 0.0,
  ),
  framePainter: const _FramePainter(),
  screenPath: _screenPath,
  frameSize: const Size(852, 1865.0),
  screenSize: const Size(360.0, 800.0),
);
