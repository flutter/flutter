import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:flutter/material.dart';

part 'frame.g.dart';

part 'screen.g.dart';

final info = DeviceInfo(
  identifier: const DeviceIdentifier(
    TargetPlatform.iOS,
    DeviceType.tablet,
    'ipad-pro-12inches-gen4',
  ),
  name: 'iPad Pro (12" gen 4)',
  pixelRatio: 2.0,
  frameSize: const Size(1849.0, 2424.0),
  screenSize: const Size(1024, 1366.0),
  safeAreas: const EdgeInsets.only(
    left: 0.0,
    top: 24.0,
    right: 0.0,
    bottom: 20.0,
  ),
  rotatedSafeAreas: const EdgeInsets.only(
    left: 0.0,
    top: 24.0,
    right: 0.0,
    bottom: 20.0,
  ),
  framePainter: const _FramePainter(),
  screenPath: _screenPath,
);
