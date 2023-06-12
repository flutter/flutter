// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#104231)
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:camera_android/src/type_conversion.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CameraImageData can be created', () {
    final CameraImageData cameraImage =
        cameraImageFromPlatformData(<dynamic, dynamic>{
      'format': 1,
      'height': 1,
      'width': 4,
      'lensAperture': 1.8,
      'sensorExposureTime': 9991324,
      'sensorSensitivity': 92.0,
      'planes': <dynamic>[
        <dynamic, dynamic>{
          'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
          'bytesPerPixel': 1,
          'bytesPerRow': 4,
          'height': 1,
          'width': 4
        }
      ]
    });
    expect(cameraImage.height, 1);
    expect(cameraImage.width, 4);
    expect(cameraImage.format.group, ImageFormatGroup.unknown);
    expect(cameraImage.planes.length, 1);
  });

  test('CameraImageData has ImageFormatGroup.yuv420', () {
    final CameraImageData cameraImage =
        cameraImageFromPlatformData(<dynamic, dynamic>{
      'format': 35,
      'height': 1,
      'width': 4,
      'lensAperture': 1.8,
      'sensorExposureTime': 9991324,
      'sensorSensitivity': 92.0,
      'planes': <dynamic>[
        <dynamic, dynamic>{
          'bytes': Uint8List.fromList(<int>[1, 2, 3, 4]),
          'bytesPerPixel': 1,
          'bytesPerRow': 4,
          'height': 1,
          'width': 4
        }
      ]
    });
    expect(cameraImage.format.group, ImageFormatGroup.yuv420);
  });
}
