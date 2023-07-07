// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CameraImageData can be created', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final CameraImageData cameraImage = CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.jpeg, raw: 42),
      height: 100,
      width: 200,
      lensAperture: 1.8,
      sensorExposureTime: 11,
      sensorSensitivity: 92.0,
      planes: <CameraImagePlane>[
        CameraImagePlane(
            bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
            bytesPerRow: 4,
            bytesPerPixel: 2,
            height: 100,
            width: 200)
      ],
    );
    expect(cameraImage.format.group, ImageFormatGroup.jpeg);
    expect(cameraImage.lensAperture, 1.8);
    expect(cameraImage.sensorExposureTime, 11);
    expect(cameraImage.sensorSensitivity, 92.0);
    expect(cameraImage.height, 100);
    expect(cameraImage.width, 200);
    expect(cameraImage.planes.length, 1);
  });
}
