import 'dart:ui' as ui;

import 'package:device_frame/src/info/device_type.dart';
import 'package:device_frame/src/info/identifier.dart';
import 'package:device_frame/src/info/info.dart';
import 'package:device_frame/src/devices/generic/base/draw_extensions.dart';
import 'package:flutter/material.dart';

part 'frame.dart';

final info = () {
  const windowSize = Size(1800, 1000);
  const screenBounds = Rect.fromLTWH(346.68, 98.2, 2298.82, 1437.32);
  final windowContentSize = Size(windowSize.width, windowSize.height - 30);
  return DeviceInfo(
    identifier: const DeviceIdentifier(
      TargetPlatform.macOS,
      DeviceType.laptop,
      'macbook-pro',
    ),
    name: 'MacBook Pro',
    pixelRatio: 2.0,
    framePainter: const _FramePainter(
      windowSize: windowSize,
    ),
    screenPath: Path()
      ..addRect(
        screenBounds.center -
                Offset(
                  windowSize.width * 0.5,
                  -30 + windowSize.height * 0.5,
                ) &
            windowContentSize,
      ),
    frameSize: const Size(2992.19, 1723.0),
    screenSize: windowContentSize,
    safeAreas: EdgeInsets.zero,
  );
}();
