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
    'samsung-galaxy-note20',
  ),
  name: 'Samsung Galaxy Note 20',
  pixelRatio: 2.625,
  safeAreas: const EdgeInsets.only(
    left: 0.0,
    top: 48.0,
    right: 0.0,
    bottom: 32.0,
  ),
  rotatedSafeAreas: const EdgeInsets.only(
    left: 48.0,
    top: 24.0,
    right: 48.0,
    bottom: 0.0,
  ),
  framePainter: const _FramePainter(),
  screenPath: _screenPath,
  frameSize: const Size(834, 1788.93),
  screenSize: const Size(412.0, 916.0),
);
